---------------------
-- Local Definations
---------------------
local MAJOR_VERSION = "LibUnit-6.0"
local MINOR_VERSION = 60000 + tonumber(("$Rev: 001 $"):match("%d+"))

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax = UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax
local GetTalentInfo = GetTalentInfo
local select = select

function lib:New(unit)
	local obj = {}
	obj.unit = unit
	
	-- 基本属性
	obj.HP = 0
	obj.HPM = 0					-- 最大血量
	obj.HPL = 0					-- 血量损失
	obj.HPP = 0					-- 血量百分比
	obj.MP = 0
	obj.MPM = 0
	obj.MPL = 0
	obj.MPP = 0
	obj.CPS = 0
	obj.Moving = false
	obj.Threat = 0
	obj.BreakList = {}
	obj.MPMT = 0				-- 能量自己回满需要的时间
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

-- 更新所有状态
function lib:Update()
	if UnitExists(self.unit) then
		self.HP = self:GetHP()
		self.HPM = self:GetHPMax()
		self.HPL = self.HPM - self.HP
		self.HPP = self.HP / self.HPM * 100
		self.MP = self:GetMP()
		self.MPM = self:GetMPMax()
		self.MPL = self.MPM - self.MP
		self.MPP = self.MP / self.MPM * 100
		self.CPS = self:GetCP()
		self.Threat = self:GetThreat()
		self.MPMT = self.MPL / GetPowerRegen()
	else
		self.HP = 0
		self.HPM = 0
		self.HPL = 0
		self.HPP = 100
		self.MP = 0
		self.MPM = 0
		self.MPL = 0
		self.MPP = 0
		self.MPP = 0
		self.CPS = 0
		self.Threat = 0
		self.MPMT = 0
	end
end

-- 获取名称
function lib:GetName()
	return UnitName(self.unit)
end

-- 获取职业
function lib:GetClass()
	return select(2, UnitClass(self.unit))
end

-- 当前生命值
function lib:GetHP()
	return UnitHealth(self.unit)
end

-- 最大生命值
function lib:GetHPMax()
	return UnitHealthMax(self.unit)
end

-- 当前法力值
function lib:GetMP(powerType, ...)
	return UnitPower(self.unit, powerType, ...)
end

-- 最大法力值
function lib:GetMPMax(powerType)
	return UnitPowerMax(self.unit, powerType)
end

-- 是否在副本
function lib:InInstance()
	local isInstance, instanceType = IsInInstance()
	if isInstance and (instanceType == "party" or instanceType == "raid") then
		return 1
	else
		return 0
	end
end

-- 獲取連擊點數
function lib:GetCP()
--	return GetComboPoints("player", "target")
	return UnitPower("player", 4)
end

-- 獲取角色位置變化
function lib:Moving()
	return IsPlayerMoving()
end

-- 是否可以攻击
function lib:CanAttack(inCombat)
	if IsMounted() or UnitInVehicle("player") then return end	--在马上或载具上
	if not UnitExists(self.unit) then return end	--目标不存在
	if UnitIsDeadOrGhost(self.unit) then return end
	if inCombat == true and (not UnitAffectingCombat("player")) then return end
	if UnitCanAttack("player", self.unit) then
		return true
	end
end

-- 是否可以攻击（在马上）
function lib:CanAttackMounted(inCombat)
	if UnitInVehicle("player") then return end	--在马上或载具上
	if not UnitExists(self.unit) then return end	--目标不存在
	if UnitIsDeadOrGhost(self.unit) then return end
	if inCombat == true and (not UnitAffectingCombat("player")) then return end
	if UnitCanAttack("player", self.unit) then
		return true
	end
end

-- 是否是玩家
function lib:IsPlayer()
	return UnitIsPlayer(self.unit)
end

-- 是否已经死亡
function lib:Dead()
	return UnitIsDeadOrGhost(self.unit)
end

-- 是否可以打断施法
function lib:CanBreak()
	if not UnitExists("target") then return end
	local spell = UnitCastingInfo("target") or UnitChannelInfo("target")
	if not spell then return end
	
	local name = UnitName("target")
	if self.BreakList[name] and self.BreakList[name] ~= spell then
		return
	end
	
	if select(9, UnitCastingInfo("target")) == false then
		return true
	elseif select(8, UnitChannelInfo("target")) == false then
		return true
	end
end

-- 获取仇恨
function lib:GetThreat()
	local _, _, threat = UnitDetailedThreatSituation(self.unit, self.unit.."target")
	return threat or 0
--	return math.floor(threat or 0)
end

-- 获取天赋
function lib:GetTalent()
	return GetSpecialization()
end

-- 获取姿态
function lib:GetStance()
	return GetShapeshiftForm() or 0
end

-- 是否是BOSS
function lib:IsBoss()
	if UnitClassification(self.unit) == "worldboss" then
		return true
	elseif UnitLevel(self.unit) == -1 then
		return true
	end
end

-- 是否是精英
function lib:IsElite()
	if UnitClassification(self.unit) == "elite" then
		return true
	elseif UnitLevel(self.unit) - UnitLevel("player") >= 2 then
		return true
	else
		return self:IsBoss()
	end
end

-- 是否是特殊目标
function lib:IsSpecialUnit()
	if UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite" then
		return 2
	elseif UnitLevel("target") - UnitLevel("player") >= 2 then
		return 2
	elseif UnitLevel("target") == -1 then
		return 2
	elseif UnitClassification("target") == "elite" then
		return 1
	else
		return 0
	end
end

-- 是否正在施法
function lib:Casting(timeleftMS)
	if SpellIsTargeting() then
		return true
	elseif timeleftMS == nil or timeleftMS == 0 then
		return UnitCastingInfo(self.unit) or UnitChannelInfo(self.unit)
	end

	local _, _, lagHomeMS, lagWorldMS = GetNetStats()
	local endtimeMS = select(5, UnitCastingInfo(self.unit)) or select(5, UnitChannelInfo(self.unit))

	if endtimeMS ~= nil then
		endtimeMS = endtimeMS - math.max(lagHomeMS, lagWorldMS)
		return endtimeMS - GetTime() * 1000 <= timeleftMS
	end
end

-- 施法剩余时间
function lib:GetCastingTime()
	local name, _, _, _, startTime, endTime = UnitCastingInfo(self.unit)
	
	if name then
		return endTime / 1000 - GetTime()
	else
		return 0
	end
end

-- 返回单位唯一编号
function lib:GUID()
	return UnitGUID(self.unit)
end

-- 是否能驱散
function lib:CanDispel(dispelType1, dispelType2, dispelType3, dispelType4)
	local name, auraType = nil, nil
	
	for i = 1, 40 do
		name, _, _, _, auraType = UnitAura(self.unit, i, "RAID|HARMFUL")
		
		if not name then
			return
		elseif auraType and auraType == dispelType1 then
			return name
		elseif auraType and auraType == dispelType2 then
			return name
		elseif auraType and auraType == dispelType3 then
			return name
		elseif auraType and auraType == dispelType4 then
			return name
		end
	end
end

-- 是否能窃取
function lib:CanStealable()
	local isStealable = 0
	
	for i = 1, 40 do
		isStealable = select(UnitAura(self.unit, i, "HELPFUL"), 9)
		
		if isStealable == 1 then
			return true
		end
	end
end

-- 返回天赋是否选中
function lib:TalentSelected(talentIndex)
	return select(5, GetTalentInfo(talentIndex))
end

-- 是否是坦克
function lib:IsTank()
	return GetPartyAssignment("MAINTANK", self.unit)
end

-- 不是玩家本身
function lib:IsMe()
	return UnitIsUnit("player", self.unit)
end

-- 是否隐身
function lib:IsStealthed()
	return IsStealthed()
end