if select(2, UnitClass("player")) ~= "ROGUE" then return end

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

-- 开关定义
local Switch1 = _G["GeniusPanelSwitch1"]
local Switch2 = _G["GeniusPanelSwitch2"]
local Switch3 = _G["GeniusPanelSwitch3"]
local Switch4 = _G["GeniusPanelSwitch4"]

-- 单位定义
local LibUnit = LibStub("LibUnit-6.0")
local Player = LibUnit:New("player")
local Target = LibUnit:New("target")

-- 法术定义
local LibSpell = LibStub("LibSpells-1.0")

local DS = LibSpell:NewByName("挫志怒吼", nil, "target", "HARMFUL")


local SS = LibSpell:NewByName("影袭")
local EV = LibSpell:NewByName("刺骨")
local SnD = LibSpell:NewByName("切割", nil, "player", "HELPFUL|PLAYER")
local KK = LibSpell:NewByName("脚踢")
local HH = LibSpell:NewByName("出血")
local RU = LibSpell:NewByName("撕裂", nil, "target", "HARMFUL|PLAYER")
local GA = LibSpell:NewByName("绞喉", nil, "target", "HARMFUL|PLAYER")

-- 变量定义
local combo = 0
local timepassed = 0

-------------------
-- Core Function
-------------------
-- 刺杀
Core.Scheme[1] = function()

end

-- 战斗
Core.Scheme[2] = function()
	SnD:Update()	--切割
	
	if (not Switch2:GetChecked()) and Target:CanBreak() and KK:CanCast() then	--脚踢
		return "S="
	elseif timepassed < 5 and SnD:LE(2) and SnD:CanCast() then	--切割（开场）
		return "D6"
	elseif combo >= 3 and SnD:LE(2) and SnD:CanCast() then	--切割
		return "D6"
	elseif combo >= 4 and EV:CanCast() then --刺骨
		return "D3"
	elseif combo < 5 and SS:CanCast() then --邪恶攻击
		return "D2"
	else
		return
	end
end

-- 敏锐
Core.Scheme[3] = function()

end

-------------------
-- Do not Modify
-------------------
function Core:Manual()
	if not Target:CanAttack(true) then
		self:Press(nil)
		return
	end
	
	-- 更新变量
	combo = GetComboPoints("player", "target")
	timepassed = GetTime() - Core.CombatTime
	
	if self.Talent == 0 then
		self.Talent = 2
	end
	
	if self.Scheme[self.Talent] then
		self:Press(self.Scheme[self.Talent]())
	end
end

function Core:Auto(elapsed)
	if self:IsSwitchChecked(1) then
		Core:Manual()
	end
end


-------------------
-- Panel Function
-------------------
-- 根据天赋改变
function Core:TALENT_CHANGED(talentID)
	GeniusPanel:Show()

	for tier = 1, 4 do
		self:SetSwitch(1, "show")
		self:SetSwitch(1, "off")
	end
	
	self:SetSwitch(1, "text", "自动攻击")
	self:SetSwitch(2, "text", "禁止断法")
	self:SetSwitch(3, "text", "群体攻击")
	self:SetSwitch(4, "text", "手动爆发")
	
	self.ShowStanceNotice = false
end
