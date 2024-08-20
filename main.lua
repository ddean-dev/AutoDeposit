NibTweaks = CreateFrame("Frame")

local ADDON_LOADED = "ADDON_LOADED"
local MERCHANT_SHOW = "MERCHANT_SHOW"
local SPELL_PUSHED_TO_ACTIONBAR = "SPELL_PUSHED_TO_ACTIONBAR"

function NibTweaks:OnEvent(event, ...)
	if event == ADDON_LOADED and #arg >= 1 and arg[1] == "NibTweaks" then
		self:Init()
	elseif event == MERCHANT_SHOW then
		self:CleanupInventory()
	elseif event == SPELL_PUSHED_TO_ACTIONBAR then
		self:ClearSlot(arg[2])
	end
end

function NibTweaks:Init()
	--Set tooltip to cursor
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(s, p)
		s:SetOwner(p, "ANCHOR_CURSOR")
	end)
	--Disable Spell Push
	IconIntroTracker.RegisterEvent = function() end
	IconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")
end

function NibTweaks:CleanupInventory()
	--Sell Junk
	if C_MerchantFrame.IsSellAllJunkEnabled() and not C_Container.GetBackpackSellJunkDisabled() then
		local qty = C_MerchantFrame.GetNumJunkItems()
		if qty > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("Selling " .. tostring(qty) .. " junk items")
			C_MerchantFrame.SellAllJunkItems()
		end
	end
	--Repair
	if CanMerchantRepair() then
		local cost, needed = GetRepairAllCost()
		if needed then
			DEFAULT_CHAT_FRAME:AddMessage("Repairing all items for " .. GetCoinTextureString(cost))
			RepairAllItems(false)
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

NibTweaks:RegisterEvent(ADDON_LOADED)
NibTweaks:RegisterEvent(MERCHANT_SHOW)
NibTweaks:RegisterEvent(SPELL_PUSHED_TO_ACTIONBAR)
NibTweaks:SetScript("OnEvent", NibTweaks.OnEvent)
