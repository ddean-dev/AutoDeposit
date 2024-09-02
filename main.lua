--Saved Variables
AutoDepositSettings = {}
AutoDepositCharacterSettings = {}

--API Events
local ADDON_LOADED = "ADDON_LOADED"
local MERCHANT_SHOW = "MERCHANT_SHOW"
local BANKFRAME_OPENED = "BANKFRAME_OPENED"
local SPELL_PUSHED_TO_ACTIONBAR = "SPELL_PUSHED_TO_ACTIONBAR"

--Settings
local PREFIX = "AutoDeposit_"
local PREFIX_CHARACTER = "AutoDeposit_Character_"
local CHECKBOX_SUFFIX = "_Checkbox"
local TARGET_GOLD = "TargetGold"
local TARGET_GOLD_RANGE = "TargetGoldRange"
local DEPOSIT_GOLD = "DepositGold"
local WITHDRAW_GOLD = "WithdrawGold"
local SELL_JUNK = "SellJunk"
local REPAIR_ALL = "RepairAll"
local REPAIR_GUILD = "RepairGuild"
local DEPOSIT_REAGENTS = "DepositReagents"

AutoDeposit = CreateFrame("Frame")

function AutoDeposit:Init()
	--Account Settings
	AutoDeposit:AddGoldSliderSetting(
		TARGET_GOLD,
		"Target Gold",
		"How much gold to leave in the character bag when automatically depositing to and withdrawing from the Warband Bank",
		true,
		false
	)
	AutoDeposit:AddGoldSliderSetting(
		TARGET_GOLD_RANGE,
		"Target Range",
		"If enabled allows any value between 'Target Gold` and the set value to be acceptable, only withdrawing/depositing when outside the set range",
		true,
		true
	)
	AutoDeposit:AddBooleanSetting(
		DEPOSIT_GOLD,
		"Automatically Deposit Gold",
		"Automatically attempts to deposit character gold in excess of the 'Target Gold' into the Warband Bank.",
		true
	)
	AutoDeposit:AddBooleanSetting(
		WITHDRAW_GOLD,
		"Automatically Withdraw Gold",
		"Automatically attempts to withdraw gold from the Warband Bank to reach the set 'Target Gold'.",
		true
	)
	AutoDeposit:AddBooleanSetting(
		REPAIR_ALL,
		"Automatically Repair All Items",
		"Automatically repair all items when interacting with vendors with repair capability.",
		true
	)
	AutoDeposit:AddBooleanSetting(
		REPAIR_GUILD,
		"Guild Repair",
		"Use funds from the guild bank when automatically repairing.",
		true
	)
	AutoDeposit:AddBooleanSetting(
		SELL_JUNK,
		"Automatically Sell Junk",
		"Automatically sells all junk when interacting with vendors.",
		true
	)
	AutoDeposit:AddBooleanSetting(
		DEPOSIT_REAGENTS,
		"Automatically Deposit Reagents",
		"Automatically deposits reagents when opening the bank.",
		true
	)

	--Character Settings
	AutoDeposit:AddGoldSliderSetting(
		TARGET_GOLD,
		"Character Target Gold",
		"A character specific override for the 'Target Gold' setting.",
		false,
		true
	)
	AutoDeposit:AddGoldSliderSetting(
		TARGET_GOLD_RANGE,
		"Character Target Range",
		"A character specific override for the 'Target Gold' setting.",
		false,
		true
	)
	AutoDeposit:AddBooleanSetting(
		DEPOSIT_GOLD,
		"Character Deposit Gold",
		"A character specific override for the 'Automatically Deposit Gold' setting.",
		false,
		true
	)
	AutoDeposit:AddBooleanSetting(
		WITHDRAW_GOLD,
		"Character Withdraw Gold",
		"A character specific override for the 'Automatically Withdraw Gold' setting.",
		false
	)
	AutoDeposit:AddBooleanSetting(
		REPAIR_ALL,
		"Character Repair All Items",
		"A character specific override for the 'Repair All Items' setting.",
		false
	)
	AutoDeposit:AddBooleanSetting(
		REPAIR_GUILD,
		"Character Guild Repair",
		"A character specific override for the 'Guild Repair' setting.",
		false
	)
	AutoDeposit:AddBooleanSetting(
		SELL_JUNK,
		"Character Sell Junk",
		"A character specific override for the 'Automatically Sell Junk' setting.",
		false
	)
	AutoDeposit:AddBooleanSetting(
		DEPOSIT_REAGENTS,
		"Character Deposit Reagents",
		"A character specific override for  the `Automatically Deposit Reagents` setting.",
		false
	)
end

function AutoDeposit:OnEvent(event, arg1, arg2)
	if event == ADDON_LOADED and arg1 == "AutoDeposit" then
		self:Init()
	elseif event == MERCHANT_SHOW then
		self:SellJunk()
		self:Repair()
	elseif event == SPELL_PUSHED_TO_ACTIONBAR then
		self:ClearSlot(arg2)
	elseif event == BANKFRAME_OPENED then
		AutoDeposit:NormalizeGold()
		AutoDeposit:DepositReagents()
	end
end

function AutoDeposit:GetGoldTarget()
	-- Get target and range values from global and character settings
	local target = AutoDeposit:GoldSliderToValue(AutoDepositSettings[TARGET_GOLD])
	local range = AutoDeposit:GoldSliderToValue(AutoDepositSettings[TARGET_GOLD_RANGE])
	if AutoDepositCharacterSettings[TARGET_GOLD .. CHECKBOX_SUFFIX] == true then
		target = AutoDeposit:GoldSliderToValue(AutoDepositCharacterSettings[TARGET_GOLD])
	end
	if AutoDepositCharacterSettings[TARGET_GOLD_RANGE .. CHECKBOX_SUFFIX] == true then
		range = AutoDeposit:GoldSliderToValue(AutoDepositCharacterSettings[TARGET_GOLD_RANGE])
	end

	-- If either range enabled return range, otherwise return target for both min and max
	if
		AutoDepositSettings[TARGET_GOLD_RANGE .. CHECKBOX_SUFFIX]
		or AutoDepositCharacterSettings[TARGET_GOLD_RANGE .. CHECKBOX_SUFFIX]
	then
		if target > range then
			return range, target
		else
			return target, range
		end
	else
		return target, target
	end
end

function AutoDeposit:SellJunk()
	if
		AutoDeposit:GetBooleanSetting(SELL_JUNK)
		and C_MerchantFrame.IsSellAllJunkEnabled()
		and not C_Container.GetBackpackSellJunkDisabled()
	then
		local qty = C_MerchantFrame.GetNumJunkItems()
		if qty > 0 then
			print("Selling " .. tostring(qty) .. " junk items")
			C_MerchantFrame.SellAllJunkItems()
		end
	end
end

function AutoDeposit:Repair()
	if AutoDeposit:GetBooleanSetting(REPAIR_ALL) and CanMerchantRepair() then
		local cost, needed = GetRepairAllCost()
		if needed then
			print("Repairing all items for " .. GetMoneyString(cost, true))
			RepairAllItems(AutoDeposit:GetBooleanSetting(REPAIR_GUILD) and CanGuildBankRepair())
		end
	end
end

function AutoDeposit:DepositReagents()
	if IsReagentBankUnlocked() and AutoDeposit:GetBooleanSetting(DEPOSIT_REAGENTS) then
		print("Depositing all reagents")
		DepositReagentBank()
	end
end

function AutoDeposit:NormalizeGold()
	local bag = GetMoney()
	local bank = C_Bank.FetchDepositedMoney(2)
	local min, max = AutoDeposit:GetGoldTarget()
	local doDeposit = AutoDeposit:GetBooleanSetting(DEPOSIT_GOLD) and C_Bank.CanDepositMoney(2)
	local doWithdraw = AutoDeposit:GetBooleanSetting(WITHDRAW_GOLD) and C_Bank.CanWithdrawMoney(2)

	--deposit
	if doDeposit and bag > max then
		local dif = bag - max
		print("Depositing " .. GetMoneyString(dif, true))
		C_Bank.DepositMoney(2, dif)
	end

	--withdraw
	if doWithdraw and bag < min then
		local dif = min - bag
		if dif > bank then
			dif = bank
		end
		print("Withdrawing " .. GetMoneyString(dif, true))
		C_Bank.WithdrawMoney(2, dif)
	end
end

function AutoDeposit:AddBooleanSetting(setting_id, text, tooltip, global, default)
	local setting
	if global then
		setting = Settings.RegisterAddOnSetting(
			AutoDeposit.SettingsCategory,
			PREFIX .. setting_id,
			setting_id,
			AutoDepositSettings,
			"boolean",
			text,
			default or false
		)
		Settings.CreateCheckbox(AutoDeposit.SettingsCategory, setting, tooltip)
	else
		setting = Settings.RegisterAddOnSetting(
			AutoDeposit.SettingsCategory,
			PREFIX_CHARACTER .. setting_id,
			setting_id,
			AutoDepositCharacterSettings,
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
		Settings.CreateDropdown(AutoDeposit.SettingsCategory, setting, trinary, tooltip)
	end
	return setting
end

function AutoDeposit:GetBooleanSetting(id)
	if AutoDepositCharacterSettings[id] == 1 then
		return true
	elseif AutoDepositCharacterSettings[id] == 2 then
		return false
	end
	return AutoDepositSettings[id] or false
end

function AutoDeposit:AddGoldSliderSetting(setting_id, text, tooltip, global, checkbox)
	local db, identifier, template
	if global then
		db = AutoDepositSettings
		identifier = PREFIX .. setting_id
	else
		db = AutoDepositCharacterSettings
		identifier = PREFIX_CHARACTER .. setting_id
	end
	if checkbox then
		template = "SettingsCheckboxSliderControlTemplate"
	else
		template = "SettingsSliderControlTemplate"
	end
	local setting =
		Settings.RegisterAddOnSetting(AutoDeposit.SettingsCategory, identifier, setting_id, db, "number", text, 27)
	local cbsetting = Settings.RegisterAddOnSetting(
		AutoDeposit.SettingsCategory,
		identifier .. CHECKBOX_SUFFIX,
		setting_id .. CHECKBOX_SUFFIX,
		db,
		"boolean",
		text,
		false
	)
	local data = {
		setting = setting,
		name = setting:GetName(),
		tooltip = tooltip,
		cbSetting = cbsetting,
		cbTooltip = tooltip,
		sliderSetting = setting,
		sliderOptions = {
			minValue = -1,
			maxValue = 63,
			steps = 64,
			formatters = {
				[MinimalSliderWithSteppersMixin.Label.Right] = function(x)
					return GetMoneyString(AutoDeposit:GoldSliderToValue(x), true)
				end,
			},
		},
		sliderTooltip = tooltip,
	}
	data.options = data.sliderOptions
	local initializer = Settings.CreateSettingInitializer(template, data)
	Settings.CreateSliderInitializer(setting, data, tooltip)
	local layout = SettingsPanel:GetLayout(AutoDeposit.SettingsCategory)
	layout:AddInitializer(initializer)
end

function AutoDeposit:GoldSliderToValue(x)
	if x == -1 then
		return 0
	end
	local power = math.floor(x / 9)
	local multiplier = (x % 9) + 1
	local value = 10000 * (10 ^ power) * multiplier
	if value >= 100000000000 then
		return 99999999999
	end
	return value
end

AutoDeposit:RegisterEvent(ADDON_LOADED)
AutoDeposit:RegisterEvent(MERCHANT_SHOW)
AutoDeposit:RegisterEvent(BANKFRAME_OPENED)
AutoDeposit:SetScript("OnEvent", AutoDeposit.OnEvent)
AutoDeposit.SettingsCategory = Settings.RegisterVerticalLayoutCategory("AutoDeposit")
Settings.RegisterAddOnCategory(AutoDeposit.SettingsCategory)
