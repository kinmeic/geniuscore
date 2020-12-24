if select(2, UnitClass("player")) ~= "ROGUE" then return end

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

-- 方法静态化
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local GetTime = GetTime

-- 开关定义
local SW2 = _G["GeniusPanelSwitch2"]
local SW3 = _G["GeniusPanelSwitch3"]
local SW4 = _G["GeniusPanelSwitch4"]

-- 单位定义
local LibUnit = LibStub("LibUnit-4.3")
--local Player = LibUnit:New("player")
local Target = LibUnit:New("target")

-- 法术定义
local LibSpell = LibStub("LibSpells-4.3")

-- 通用技能
local KK = LibSpell:New(1766)	--脚踢
local VA = LibSpell:New(1856)	--消失
local FT = LibSpell:New(1966, nil, "player", "HELPFUL|PLAYER")		--佯攻
local TotT = LibSpell:New(57934, 59628, "player", "HELPFUL|PLAYER")	--嫁祸诀窍

-- 专精技能
local KS = LibSpell:New(192759, nil, "target", "HARMFUL|PLAYER")	--君王之灾(神器)

local MU = LibSpell:New(1329)	--毁伤
local FK = LibSpell:New(51723)	--刀扇

local VA = LibSpell:New(1856, 11327, "player","HELPFUL|PLAYER")		--消失
local RP = LibSpell:New(1943, nil, "target", "HARMFUL|PLAYER")		--割裂
local VE = LibSpell:New(79140, nil, "target", "HARMFUL|PLAYER")		--仇杀
local GA = LibSpell:New(703, nil, "target", "HARMFUL|PLAYER")		--锁喉
local EN = LibSpell:New(32645, nil, "player", "HELPFUL|PLAYER")		--毒化

local AP = LibSpell:New(nil, 200803, "target", "HARMFUL|PLAYER")	--痛苦药膏(天赋)
local EP = LibSpell:New(nil, 193641, "player", "HELPFUL|PLAYER")	--深谋远虑(天赋)


-- 变量定义
local energy = 0
local energy_deficit = 0
local energy_to_max = 0
local combo = 0
local combo_deficit = 0
local time = 0
local cp_max_spend = 5
local stealthed = false

-- 是否是特殊目标
local IsSpecialUnit = function()
	if UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite" then
		return true
	elseif UnitLevel("target") - UnitLevel("player") >= 2 then
		return true
	elseif UnitLevel("target") == -1 then
		return true
	else
		return false
	end
end

-- 是否能够消失
local CanVanish = function()
	local isInstance, instanceType = IsInInstance()

	if isInstance and (instanceType == "party" or instanceType == "raid") then
		return GetNumGroupMembers() > 1
	else
		return false
	end
end

local main = function()
	RP:Update()	--割裂
	GA:Update()	--锁喉
	VE:Update()	--仇杀
	VA:Update()	--消失
	EN:Update()	--毒化
	KS:Update()	--君王之灾（神器）
	AP:Update()	--痛苦药膏（天赋）
--	EP:Update()	--深谋远虑（天赋）

	if (not SW2:GetChecked()) and Target:CanBreak() and KK:CanCast() then	--脚踢
		return "S="
--	elseif (not SW3:GetChecked()) and RP:RT(2) and (energy < 55 or time < 10) and VE:CanCast() then	--仇杀
	elseif (not SW3:GetChecked()) and energy_deficit >= 125 and VE:CanCast() then	--仇杀
		return "D4"
	elseif (not SW3:GetChecked()) and IsSpecialUnit() and combo >= cp_max_spend and RP:Refreshable() and CanVanish() and VA:CanCast() then	--消失(夜行者)
		return "D7"
	elseif VA:RT(0) and RP:CanCast() then	--割裂(夜行者)
		return "D6"
	elseif RP:LE(2) and RP:CanCast() then	--割裂
		return "D6"
	elseif combo >= cp_max_spend and RP:Refreshable() and RP:CanCast() then	--割裂
		return "D6"
--	elseif (VE:RT(0) or VE:GetCD() > 10) and KS:CanCast() then	--君王之灾（神器）
	elseif EN:RT(0) and (VE:RT(0) or VE:GetCD() > 10) and KS:CanCast() then	--君王之灾（神器）
		return "S-"
--	elseif combo_deficit >= 1 and GA:CanCast() then	--锁喉
	elseif GA:LE(3) and GA:CanCast() then	--锁喉
		return "D9"
--	elseif combo >= cp_max_spend and ((RP:Refreshable() or RP:LE(2)) or VA:RT(0)) and RP:CanCast() then	--割裂
--		return "D6"
--	elseif (VA:GetCD() == 0 or VA:GetCD() >= 6) and RP:RE(6) and EP:LT(1.5) and combo > cp_max_spend - 2 and (EN:Refreshable() or EP:LE(0) or GA:GetCD() < 1)and EN:CanCast() then	--毒化(深谋远虑)
	elseif combo >= 4 and (not RP:Refreshable()) and EN:CanCast() then	--毒化
		return "D5"
--	elseif combo_deficit >= 1 and GA:GetCD() > 2 and MU:CanCast() then	--毁伤
	elseif (combo_deficit > 0 or energy_to_max < 1) and SW4:GetChecked() and FK:CanCast() then	--刀扇
		return "D3"
	elseif (combo_deficit > 0 or energy_to_max < 1) and AP:LT(AP.duration * 0.3) and MU:CanCast() then	--毁伤(痛苦药膏)
		return "D2"
	elseif (combo_deficit > 0 or energy_to_max < 1) and MU:CanCast() then	--毁伤
		return "D2"
	else
		return
	end
end

Core.Scheme[1] = function()
	-- 更新通用状态
	energy = UnitPower("player")
	energy_deficit = UnitPowerMax("player") - UnitPower("player")
	energy_to_max = energy_deficit / GetPowerRegen()
	combo = UnitPower("player", 4)
	combo_deficit = UnitPowerMax("player", 4) - UnitPower("player", 4)
	time = GetTime() - Core.CombatTime
	stealthed = (GetShapeshiftFormID() == 30)
	
	return main()
end
