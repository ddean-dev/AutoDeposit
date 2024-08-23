--Frame
NibTweaks = CreateFrame("Frame")
NibTweaks.SettingsCategory = Settings.RegisterVerticalLayoutCategory("NibTweaks")

--Saved Variables
NibTweaksSettings = {}
NibTweaksCharacterSettings = {}

--API Events
local ADDON_LOADED = "ADDON_LOADED"
local MERCHANT_SHOW = "MERCHANT_SHOW"
local BANKFRAME_OPENED = "BANKFRAME_OPENED"
local SPELL_PUSHED_TO_ACTIONBAR = "SPELL_PUSHED_TO_ACTIONBAR"

--Settings
local TARGET_GOLD = "TargetGold"
local DEPOSIT_GOLD = "DepositGold"
local WITHDRAW_GOLD = "WithdrawGold"
local SELL_JUNK = "SellJunk"
local REPAIR_ALL = "RepairAll"
local REPAIR_GUILD = "RepairGuild"

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

function NibTweaks:AddBooleanSetting(setting_id, text, tooltip, global, default)
	local setting
	if global then
		setting = Settings.RegisterAddOnSetting(
			NibTweaks.SettingsCategory,
			"NibTweaks_" .. setting_id,
			setting_id,
			NibTweaksSettings,
			"boolean",
			text,
			default or false
		)
		Settings.CreateCheckbox(NibTweaks.SettingsCategory, setting, tooltip)
	else
		setting = Settings.RegisterAddOnSetting(
			NibTweaks.SettingsCategory,
			"NibTweaks_Character_" .. setting_id,
			setting_id,
			NibTweaksCharacterSettings,
			"number",
			text,
			0
		)
		local function trinary()
			local container = Settings.CreateControlTextContainer()
			container:Add(0, "Default")
			container:Add(1, "Enabled")
			container:Add(2, "Disabled")
			return container:GetData()
		end
		Settings.CreateDropdown(NibTweaks.SettingsCategory, setting, trinary, tooltip)
	end
	return setting
end

function NibTweaks:GetBooleanSetting(id)
	if NibTweaksCharacterSettings[id] == 1 then
		return true
	elseif NibTweaksCharacterSettings[id] == 2 then
		return false
	end
	return NibTweaksSettings[id] or false
end

function NibTweaks:GetGoldTarget()
	if NibTweaksCharacterSettings[TARGET_GOLD] == -1 then
		return NibTweaksSettings[TARGET_GOLD]
	end
	return NibTweaksCharacterSettings[TARGET_GOLD]
end

function NibTweaks:Init()
	--Set tooltip to cursor
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(s, p)
		s:SetOwner(p, "ANCHOR_CURSOR")
	end)

	--Disable Spell Push
	IconIntroTracker.RegisterEvent = function() end
	IconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")

	--Account Settings
	local targetGold = Settings.RegisterAddOnSetting(
		NibTweaks.SettingsCategory,
		"NibTweaks_" .. TARGET_GOLD,
		TARGET_GOLD,
		NibTweaksSettings,
		"number",
		"Target Gold",
		1000
	)
	local function targetGoldOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, C_CurrencyInfo.GetCoinTextureString(0))
		container:Add(1, C_CurrencyInfo.GetCoinTextureString(10000))
		container:Add(10, C_CurrencyInfo.GetCoinTextureString(100000))
		container:Add(100, C_CurrencyInfo.GetCoinTextureString(1000000))
		container:Add(1000, C_CurrencyInfo.GetCoinTextureString(10000000))
		container:Add(10000, C_CurrencyInfo.GetCoinTextureString(100000000))
		container:Add(100000, C_CurrencyInfo.GetCoinTextureString(1000000000))
		container:Add(1000000, C_CurrencyInfo.GetCoinTextureString(10000000000))
		container:Add(10000000, C_CurrencyInfo.GetCoinTextureString(100000000000))
		return container:GetData()
	end
	Settings.CreateDropdown(
		NibTweaks.SettingsCategory,
		targetGold,
		targetGoldOptions,
		"How much gold to leave in the character bag when automatically depositing to and withdrawing from the Warband Bank"
	)
	NibTweaks:AddBooleanSetting(
		DEPOSIT_GOLD,
		"Automatically Deposit Gold",
		"Automatically attempts to deposit character gold in excess of the 'Target Gold' into the Warband Bank.",
		true
	)
	NibTweaks:AddBooleanSetting(
		WITHDRAW_GOLD,
		"Automatically Withdraw Gold",
		"Automatically attempts to withdraw gold from the Warband Bank to reach the set 'Target Gold'.",
		true
	)
	NibTweaks:AddBooleanSetting(
		REPAIR_ALL,
		"Automatically Repair All Items",
		"Automatically repair all items when interacting with vendors with repair capability.",
		true
	)
	NibTweaks:AddBooleanSetting(
		REPAIR_GUILD,
		"Guild Repair",
		"Use funds from the guild bank when automatically repairing.",
		true
	)
	NibTweaks:AddBooleanSetting(
		SELL_JUNK,
		"Automatically Sell Junk",
		"Automatically sells all junk when interacting with vendors.",
		true
	)

	--Character Settings
	local characterTargetGold = Settings.RegisterAddOnSetting(
		NibTweaks.SettingsCategory,
		"NibTweaks_Character_" .. TARGET_GOLD,
		TARGET_GOLD,
		NibTweaksCharacterSettings,
		"number",
		"Character Gold Target",
		-1
	)
	local function characterTargetGoldOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(-1, "Default")
		container:Add(0, C_CurrencyInfo.GetCoinTextureString(0))
		container:Add(1, C_CurrencyInfo.GetCoinTextureString(10000))
		container:Add(10, C_CurrencyInfo.GetCoinTextureString(100000))
		container:Add(100, C_CurrencyInfo.GetCoinTextureString(1000000))
		container:Add(1000, C_CurrencyInfo.GetCoinTextureString(10000000))
		container:Add(10000, C_CurrencyInfo.GetCoinTextureString(100000000))
		container:Add(100000, C_CurrencyInfo.GetCoinTextureString(1000000000))
		container:Add(1000000, C_CurrencyInfo.GetCoinTextureString(10000000000))
		container:Add(10000000, C_CurrencyInfo.GetCoinTextureString(100000000000))
		return container:GetData()
	end
	Settings.CreateDropdown(
		NibTweaks.SettingsCategory,
		characterTargetGold,
		characterTargetGoldOptions,
		"A character specific override for the 'Gold Target' setting."
	)
	NibTweaks:AddBooleanSetting(
		DEPOSIT_GOLD,
		"Character Deposit Gold",
		"A character specific override for the 'Automatically Deposit Gold' setting.",
		false
	)
	NibTweaks:AddBooleanSetting(
		WITHDRAW_GOLD,
		"Character Withdraw Gold",
		"A character specific override for the 'Automatically Withdraw Gold' setting.",
		false
	)
	NibTweaks:AddBooleanSetting(
		REPAIR_ALL,
		"Character Repair All Items",
		"A character specific override for the 'Repair All Items' setting.",
		false
	)
	NibTweaks:AddBooleanSetting(
		REPAIR_GUILD,
		"Character Guild Repair",
		"A character specific override for the 'Guild Repair' setting.",
		false
	)
	NibTweaks:AddBooleanSetting(
		SELL_JUNK,
		"Character Sell Junk",
		"A character specific override for the 'Automatically Sell Junk' setting.",
		false
	)
end

function NibTweaks:CleanupInventory()
	--Sell Junk
	if
		NibTweaks:GetBooleanSetting(SELL_JUNK)
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
	if NibTweaks:GetBooleanSetting(REPAIR_ALL) and CanMerchantRepair() then
		local cost, needed = GetRepairAllCost()
		if needed then
			DEFAULT_CHAT_FRAME:AddMessage("Repairing all items for " .. C_CurrencyInfo.GetCoinTextureString(cost))
			RepairAllItems(NibTweaks:GetBooleanSetting(REPAIR_GUILD) and CanGuildBankRepair())
		end
	end
end

function NibTweaks:NormalizeGold()
	local bank = C_Bank.FetchDepositedMoney(2)
	local diff = (NibTweaks:GetGoldTarget() * 10000) - GetMoney()
	if diff > 0 and bank > diff and NibTweaks:GetBooleanSetting(WITHDRAW_GOLD) and C_Bank.CanWithdrawMoney(2) then
		C_Bank.WithdrawMoney(2, diff)
	elseif diff > 0 and NibTweaks:GetBooleanSetting(WITHDRAW_GOLD) and C_Bank.CanWithdrawMoney(2) then
		C_Bank.WithdrawMoney(2, bank)
	elseif diff < 0 and NibTweaks:GetBooleanSetting(DEPOSIT_GOLD) and C_Bank.CanWithdrawMoney(2) then
		C_Bank.DepositMoney(2, -diff)
	end
end

function NibTweaks:ClearSlot(slotIndex)
	if not InCombatLockdown() then
		ClearCursor()
		PickupAction(slotIndex)
		ClearCursor()
	end
end

NibTweaks:RegisterEvent(ADDON_LOADED)
NibTweaks:RegisterEvent(MERCHANT_SHOW)
NibTweaks:RegisterEvent(BANKFRAME_OPENED)
NibTweaks:RegisterEvent(SPELL_PUSHED_TO_ACTIONBAR)
Settings.RegisterAddOnCategory(NibTweaks.SettingsCategory)
NibTweaks:SetScript("OnEvent", NibTweaks.OnEvent)
