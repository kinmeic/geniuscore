if select(2, UnitClass("player")) ~= "ROGUE" then return end

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

-- 方法静态化
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local GetPowerRegen = GetPowerRegen

-- 开关定义
local SW2 = _G["GeniusPanelSwitch2"]
local SW3 = _G["GeniusPanelSwitch3"]
local SW4 = _G["GeniusPanelSwitch4"]

-- 单位定义
local LibUnit = LibStub("LibUnit-1.0")
--local Player = LibUnit:New("player")
local Target = LibUnit:New("target")

-- 法术定义
local LibSpell = LibStub("LibSpells-1.0")

-- 通用技能
local KK = LibSpell:New(1766)	--脚踢
local VA = LibSpell:New(1856)	--消失
local FT = LibSpell:New(1966, nil, "player", "HELPFUL|PLAYER")		--佯攻
local TotT = LibSpell:New(57934, 59628, "player", "HELPFUL|PLAYER")	--嫁祸诀窍

-- 专精技能
local RT = LibSpell:New(2098)	--刺骨
local SS = LibSpell:New(1752)	--邪恶攻击
local PS = LibSpell:New(185763)	--手枪射击
local DA = LibSpell:New(152150)	--死从天降(天赋)
local RB = LibSpell:New(193316)	--命运骨骰
local KS = LibSpell:New(51690)	--杀戮盛宴
local MD = LibSpell:New(137619)	--死亡标记(天赋)
local SP = LibSpell:New(193315)	--疾跑
local BE = LibSpell:New(199804)	--正中眉心
local GG = LibSpell:New(1776)	--凿击

local AR = LibSpell:New(13750, nil, "player", "PLAYER|HELPFUL")		--冲动
local OP = LibSpell:New(195627, nil, "player", "PLAYER|HELPFUL")	--可乘之机
local AG = LibSpell:New(nil, 193538, "player", "PLAYER|HELPFUL")	--敏锐（天赋）
local CD = LibSpell:New(202665, nil, "player", "PLAYER|HARMFUL")	--恐惧之刃诅咒（神器）
local GS = LibSpell:New(196937, nil, "target", "PLAYER|HARMFUL")	--鬼魅攻击（天赋）
local SD = LibSpell:New(5171, nil, "player", "PLAYER|HELPFUL")		--切割（天赋）

-- 变量定义
local energy = 0
local energy_deficit = 0
local energy_to_max = 0
local combo = 0

local main = function()
--	SD:Update()		--切割（天赋）
	
	if (not SW2:GetChecked()) and Target:CanBreak() and KK:CanCast() then	--脚踢
		return "S="
	elseif (not SW3:GetChecked()) and Target:IsBoss() and AR:NONE() and (time > 20 or energy_deficit > 0) and AR:CanCast() then	--冲动
		return "D4"
	elseif combo < 5 and SS:CanCast() then	--邪恶攻击
		return "D2"
	elseif combo == 5 and RT:CanCast() then	--穿刺
		return "D5"
	else
		return
	end
end

Core.Scheme[2] = function()
	-- 更新通用状态
	energy = UnitPower("player")
	energy_deficit = UnitPowerMax("player") - UnitPower("player")
	energy_to_max = energy_deficit / GetPowerRegen()
	combo = GetComboPoints("player", "target")

	return main()
end
