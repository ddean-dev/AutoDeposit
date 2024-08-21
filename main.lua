--Frame
NibTweaks = CreateFrame("Frame")
NibTweaks.SettingsCategory = Settings.RegisterVerticalLayoutCategory("NibTweaks")

--Saved Variables
NibTweaksSettings = {}
NibTweaksCharacterSettings = {}

local GOLD_TARGET = 1000 * 10000

--Events
local ADDON_LOADED = "ADDON_LOADED"
local MERCHANT_SHOW = "MERCHANT_SHOW"
local BANKFRAME_OPENED = "BANKFRAME_OPENED"
local SPELL_PUSHED_TO_ACTIONBAR = "SPELL_PUSHED_TO_ACTIONBAR"

function NibTweaks:OnEvent(event, arg1, arg2)
	if event == ADDON_LOADED and arg1 == "NibTweaks" then
		self:Init()
	elseif event == MERCHANT_SHOW then
		self:CleanupInventory()
	elseif event == SPELL_PUSHED_TO_ACTIONBAR then
		self:ClearSlot(arg2)
	elseif event == BANKFRAME_OPENED then
		NibTweaks:NormalizeGold()
	end
end

function NibTweaks:Init()
	print(NibTweaksCharacterSettings)

	--Set tooltip to cursor
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(s, p)
		s:SetOwner(p, "ANCHOR_CURSOR")
	end)

	--Disable Spell Push
	IconIntroTracker.RegisterEvent = function() end
	IconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")

	--Initialize settings
	local sellJunk = Settings.RegisterAddOnSetting(
		NibTweaks.SettingsCategory,
		"NibTweaks_SellJunk",
		"sellJunk",
		NibTweaksSettings,
		"boolean",
		"Sell Junk",
		true
	)
	Settings.CreateCheckbox(
		NibTweaks.SettingsCategory,
		sellJunk,
		"Automatically sell junk when interacting with vendors."
	)
	local repair = Settings.RegisterAddOnSetting(
		NibTweaks.SettingsCategory,
		"NibTweaks_Repair",
		"repair",
		NibTweaksSettings,
		"boolean",
		"Repair",
		true
	)
	Settings.CreateCheckbox(
		NibTweaks.SettingsCategory,
		repair,
		"Automatically repair items when interacting with vendors."
	)
	local normalizeGold = Settings.RegisterAddOnSetting(
		NibTweaks.SettingsCategory,
		"NibTweaks_NormalizeGold",
		"normalizeGold",
		NibTweaksSettings,
		"boolean",
		"Normalize Gold",
		true
	)
	Settings.CreateCheckbox(
		NibTweaks.SettingsCategory,
		normalizeGold,
		"Automatically transfers gold too and from the Warband bank when opening the bank to maintain a target quantity of gold in the character inventory."
	)
end

function NibTweaks:CleanupInventory()
	--Sell Junk
	if
		NibTweaksSettings["sellJunk"]
		and C_MerchantFrame.IsSellAllJunkEnabled()
		and not C_Container.GetBackpackSellJunkDisabled()
	then
		local qty = C_MerchantFrame.GetNumJunkItems()
		if qty > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("Selling " .. tostring(qty) .. " junk items")
			C_MerchantFrame.SellAllJunkItems()
		end
	end
	--Repair
	if NibTweaksSettings["repair"] and CanMerchantRepair() then
		local cost, needed = GetRepairAllCost()
		if needed then
			DEFAULT_CHAT_FRAME:AddMessage("Repairing all items for " .. GetCoinTextureString(cost))
			RepairAllItems(false)
		end
	end
end

function NibTweaks:NormalizeGold()
	if NibTweaksSettings["normalizeGold"] and C_Bank.CanDepositMoney(2) then
		local bank = C_Bank.FetchDepositedMoney(2)
		local diff = GOLD_TARGET - GetMoney()
		if diff > 0 and bank > diff then
			C_Bank.WithdrawMoney(2, diff)
		elseif diff > 0 then
			C_Bank.WithdrawMoney(2, bank)
		elseif diff < 0 then
			C_Bank.DepositMoney(2, -diff)
		end
	end
end

function NibTweaks:ClearSlot(slotIndex)
	if not InCombatLockdown() then
		ClearCursor()
		PickupAction(slotIndex)
		ClearCursor()
	end
end

function NibTweaks:OnSettingChanged(setting, value) end

NibTweaks:RegisterEvent(ADDON_LOADED)
NibTweaks:RegisterEvent(MERCHANT_SHOW)
NibTweaks:RegisterEvent(BANKFRAME_OPENED)
NibTweaks:RegisterEvent(SPELL_PUSHED_TO_ACTIONBAR)
Settings.RegisterAddOnCategory(NibTweaks.SettingsCategory)
NibTweaks:SetScript("OnEvent", NibTweaks.OnEvent)
