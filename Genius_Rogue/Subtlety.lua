if select(2, UnitClass("player")) ~= "ROGUE" then return end

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

-- 方法静态化
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local GetShapeshiftFormID = GetShapeshiftFormID

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
local BS = LibSpell:New(53)		--背刺
local EV = LibSpell:New(196819)	--剔骨
local SE = LibSpell:New(185438)	--暗影打击
local SK = LibSpell:New(197835)	--袖剑风暴
local SB = LibSpell:New(121471, nil, "player", "HELPFUL|PLAYER")	--暗影之刃
local MD = LibSpell:New(137619)	--死亡标记(天赋)
local GB = LibSpell:New(209782)	--斥候之咬（神器技能）

local NI = LibSpell:New(195452, nil, "target", "HARMFUL|PLAYER")	--夜刃
local SD = LibSpell:New(185313, 185422, "player", "HELPFUL|PLAYER")	--暗影之舞
local SoD = LibSpell:New(212283, nil, "player", "HELPFUL|PLAYER")	--死亡标记
local ES = LibSpell:New(206237, nil, "player", "HELPFUL|PLAYER")	--暗影笼罩（天赋）
local MoS = LibSpell:New(nil, 31665, "player", "PLAYER|HELPFUL")	--敏锐大师


-- 变量定义
local energy = 0
local energy_deficit = 0
local combo = 0
local combo_deficit = 0
local stealthed = false
local ssw_er = 0
local ed_threshold = false
local time = 0
local tm_threshold = 0
local stealth_cds= false	--潜行优先级技能循环
local shd_fractionnal = 2.45
local aoe = 0

-- 是否能够消失
local CanVanish = function()
	local isInstance, instanceType = IsInInstance()

	if isInstance and (instanceType == "party" or instanceType == "raid") then
		return GetNumGroupMembers() > 1
	else
		return false
	end
end

local finishers = function()
	if NI:Refreshable() and NI:CanCast() then	--夜刃
		return "D6"
	elseif EV:CanCast() then	--剔骨
		return "D7"
	else
		return
	end
end

local stealthed_rotation = function()
	SoD:Update()	--死亡标记
	SB:Update()		--暗影之刃
	
	if SoD:Refreshable() and SoD:CanCast() then	--死亡标记
		return "D0"
	elseif SW4:GetChecked() and combo_deficit >= 3 and SK:CanCast() then	--袖剑风暴（AOE）
		return "D3"
	elseif (combo_deficit >= 2 or (SB:RT(0) and combo_deficit >= 3)) and SE:CanCast() then	--暗影打击
		return "D2"
 --	elseif combo >= 5 then
--		return finishers()

	elseif combo >= 5 and NI:Refreshable() and NI:CanCast() then	--夜刃
		return "D6"
	elseif combo >= 5 and EV:CanCast() then	--剔骨
		return "D7"

	elseif SE:CanCast() then	--暗影打击
		return "D2"
	else
		return
	end
end


local update_variable = function()
	ssw_er = 0 * (10 + 0.5)
	ed_threshold = energy_deficit <= (20 + 25 + ssw_er)
	tm_threshold = time >= 10 and 1 or 0
	
	if combo_deficit >= 2 and (ed_threshold or (VA:GetCD() == 0 and SD.charges <= 1) or SW4:GetChecked()) then
		stealth_cds = true
	else
		stealth_cds = false
	end
	
	aoe = SW4:GetChecked() and 1 or 0
end

local main = function()
	NI:Update()		--夜刃
	SD:Update()		--暗影之舞
	
	
	-- 更新变量信息
	update_variable()
	
	if (not SW2:GetChecked()) and Target:CanBreak() and KK:CanCast() then	--脚踢
		return "S="
	elseif (not SW3:GetChecked()) and Target:IsBoss() and combo <= 2 and SB:CanCast() then	--暗影之刃
		return "S-"
	elseif (not stealthed) and SD.charges_fractional <= 2.45 and (combo_deficit >= 4 - tm_threshold * 2 and energy_deficit > 50 - tm_threshold * 15) and GB:CanCast() then	--斥候之咬（神器技能）
		return "D9"
	elseif stealthed then
		return stealthed_rotation()
	elseif combo >= 5 - aoe then
		return finishers()

	-- Stealth Cooldowns
	elseif stealth_cds and SD.charges_fractional >= shd_fractionnal and SD:CanCast() then	--暗影之舞
		return "D4"
	elseif stealth_cds and CanVanish() and VA:CanCast() then	--消失
		return "D5"
	elseif stealth_cds and SD.charges >= 2 and combo <= 1 and SD:CanCast() then	--暗影之舞
		return "D4"
	elseif stealth_cds and combo <= 1 and SD:CanCast() then	--暗影之舞
		return "D4"

	-- Builders
	elseif ed_threshold and SW4:GetChecked() and SK:CanCast() then	--袖剑风暴（AOE）
		return "D3"
	elseif ed_threshold and BS:CanCast() then	--背刺
		return "D2"
	else
		return
	end
end


Core.Scheme[3] = function()
	Target:Update()
	
	-- 更新通用状态
	energy = UnitPower("player")
	energy_deficit = UnitPowerMax("player") - UnitPower("player")
	combo = UnitPower("player", 4)
	combo_deficit = UnitPowerMax("player", 4) - UnitPower("player", 4)
	stealthed = (GetShapeshiftFormID() == 30)
	time = GetTime() - Core.CombatTime
	
	return main()
end
