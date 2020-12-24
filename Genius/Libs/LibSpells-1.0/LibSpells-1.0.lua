---------------------
-- Local Definations
---------------------
local MAJOR_VERSION = "LibSpells-1.0"
local MINOR_VERSION = 10000 + tonumber(("$Rev: 001 $"):match("%d+"))

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Metatable
lib.__sub = function(op1, op2)
	if type(op1) == "number" then
		return op1 - op2.timeleft
	elseif type(op2) == "number" then
		return op1.timeleft - op2
	else
		return op1.timeleft - op2.timeleft
	end
end

lib.__add = function(op1, op2)
	if type(op1) == "number" then
		return op1 + op2.timeleft
	elseif type(op2) == "number" then
		return op1.timeleft + op2
	else
		return op1.timeleft + op2.timeleft
	end
end

-- 创建实例
function lib:New(spellId, auraId, unit, filter, magiclock)
	local object = {}
	
	object.name = spellId and GetSpellInfo(spellId) or "*"
	object.aura = GetSpellInfo(auraId or spellId)
	object.sid = spellId
	object.aid = auraId or spellId
	object.unit = unit or "target"
	object.filter = filter or "HARMFUL|PLAYER"
	object.magiclock = magiclock or 0	--防止重复施法标记
	object.key = ""		--按键
	
	object.CD = 0
	object.CDMAX = 0
	object.timeleft = 0
	object.count = 0
	object.stack = 0 -- alias of count
	object.duration = 0
	object.refresh = 0	-- 刷新效果最大值
	object.tick = 0
	object.damage = 0
	object.charges = 0
	object.chargeleft = 0
	object.charges_fractional = 0
	object.cost = 0
	
	setmetatable(object, self)
	self.__index = self
	return object
end

function lib:NewByName(spellName, auraName, unit, filter, magiclock)
	local spellId = select(7, GetSpellInfo(spellName))
	local auraId = select(7, GetSpellInfo(auraName or spellName))
	return self:New(spellId, auraId, unit, filter, magiclock)
end

-- 效果组
function lib:NewAuras(auras, unit, filter)
	local object = {}
	object.auras = {}
	
	for _, id in ipairs(auras) do
		local name = GetSpellInfo(id)
		table.insert(object.auras, name)
	end
	
	object.timeleft = 0
	object.count = 0
	object.stack = 0
	object.duration = 0
	object.refresh = 0	-- 刷新效果最大值
	object.tick = 0
	object.unit = unit or "target"
	object.filter = filter or "HARMFUL"
	object.affects = 0	-- 影响中的增益数量
	object.affects_list = {}
	object.cost = 0
	
	setmetatable(object, self)
	self.__index = self
	return object
end

-- 设置目标
function lib:SetUnit(unit, filter)
	self.unit = unit or self.unit
end

-- 设置按键
function lib:SetKey(key)
	self.key = key
end

-- 更新信息
function lib:Update(useId)
	local timeleft, count, duration, value = 0, 0, 0, 0
	local charges, cmax, cstart, cduration, charges_fractional = 0, 0, 0, 0, 0
	local cost = 0
	local costtable = {}
	
	if self.auras then
		timeleft, count, duration, value = self:GetAuraByGroup()
	elseif useId then
		timeleft, count, duration, value = self:GetAuraByID(self.aid)
		self.CD, self.CDMAX = self:GetCooldown()
	else
		timeleft, count, duration, value = self:GetAura(self.aura)
		self.CD, self.CDMAX = self:GetCooldown()
	end
	
	if self.sid then
		charges, cmax, cstart, cduration = GetSpellCharges(self.sid)
		
		if charges == cmax then
			cstart = 0
			charges_fractional = cmax
		else
			cstart = cstart or 0
			cstart = cstart > 0 and (cduration - GetTime() + cstart) or 0
			charges_fractional = cduration and charges + (cduration - cstart) / cduration or charges
		end
		
		costtable = GetSpellPowerCost(self.sid)
		
		if costtable ~= nil and #costtable > 0 and costtable[1]["cost"] ~= nil then
			cost = costtable[1]["cost"]
		end
	end
	
	self.timeleft = timeleft
	self.count = count
	self.stack = count or 0
	self.duration = duration
	self.refresh = duration * 0.3
	self.tick = value
	self.charges = charges
	self.chargeleft = cstart
	self.charges_fractional = charges_fractional
	self.cost = cost
end

-- 是否可以施法
function lib:CanCast()
	if self.sid then
		
--		if (not IsSpellKnown(self.sid)) then return end	--新增检查法术是否学习
		local usable, nomana = IsUsableSpell(self.sid)
		if (not usable) or nomana then return end
		local start, duration = GetSpellCooldown(self.sid)
		if start > 0 and duration > 0 then return end
		
		local inRange = IsSpellInRange(self.name, "target")
		if (not IsHelpfulSpell(self.name)) and inRange then	--不支持spellID
			return (inRange == 1)
		else
			return true
		end
	end
end

-- 是否在有效距离
function lib:InRange()
	local inRange = IsSpellInRange(self.name, "target")
	if (not IsHelpfulSpell(self.name)) and inRange then	--不支持spellID
		return (inRange == 1)
	else
		return true
	end
end

-- 取得技能冷却时间
function lib:GetCooldown()
	local start, duration = GetSpellCooldown(self.name)
	
	if not start or start == 0 then
		return 0, duration or 0
	else
		return duration - (GetTime() - start), duration
	end
end

function lib:GetCD()
	return self:GetCooldown()
end

-- 取得施法时间
function lib:GetCastTime()
	if not self.sid then return end
	local spell, _, _, castTime, _, _, spellId = GetSpellInfo(self.sid)
	if spell then
		return castTime / 1000
	else
		return 999
	end
end

-- 取得效果信息
function lib:GetAura(aura)
	if not aura then
		return 0, 0, 0, 0
	end
	local name, id, count, duration, expires, value = nil, nil, 0, 0, 0, 0
	
	for i = 1, 40 do
	
		name, _, count, _, duration, expires, _, _, _, id, _, _, castbyplayer, _, tick = UnitAura(self.unit, i, self.filter)
		
		if name and name == aura then
			count = count or 0
			tick = tick or 0
			
			if expires == 0 then
				return 60, count, 60, tick
			else
				return expires - GetTime(), count, duration, tick
			end
		end
	end

	return 0, 0, 0, 0
end

-- 根据ID获取效果信息
function lib:GetAuraByID(aid)
	local name, id, count, duration, expires, value = nil, nil, 0, 0, 0, 0
	
	for i = 1, 40 do
		name, _, count, _, duration, expires, _, _, _, id, _, _, castbyplayer, _, tick = UnitAura(self.unit, i, self.filter)
		
		if not name then return 0, 0, 0, 0 end
		
		if id == aid then
			count = count or 0
			tick = tick or 0
			
			if expires == 0 then
				return 60, count, 60, tick
			else
				return expires - GetTime(), count, duration, tick
			end
		end
	end
	
	return 0, 0, 0, 0
end

-- 获取效果组信息
function lib:GetAuraByGroup()
	local timeleft, count, duration, tick = 0, 0, 0, 0
	local timeleft_one, count_one, duration_one, tick_one = 0, 0, 0, 0
	
	-- 清空表
	for i = #self.affects_list, 1, -1 do  
		if self.affects_list[i] ~= nil then  
			table.remove(self.self.affects_list, i)
		end
	end
	
	for _, aura in ipairs(self.auras) do
		timeleft_one, count_one, duration_one, tick_one = self:GetAura(aura)
		
		if timeleft > 0 then
			self.affects = self.affects + 1
			table.insert(self.affects_list, name)
			timeleft = timeleft_one
			count = count_one
			duration = duration_one
			tick = tick_one

--			return timeleft, count, duration, tick
		end
	end
	
	return timeleft, count, duration, tick
end

-- 效果存在
function lib:UP()
	return self.timeleft > 0
end

-- 没有效果
function lib:NONE()
	return self.timeleft == 0
end

-- 等于效果剩余时间
function lib:EQ(num)
	return self.timeleft == num
end

-- 小于效果剩余时间
function lib:LT(num)
	return self.timeleft < num
end

-- 小于等于效果剩余时间
function lib:LE(num)
	return self.timeleft <= num
end

-- 大于效果剩余时间
function lib:RT(num)
	return self.timeleft > num
end

-- 大于等于效果剩余时间
function lib:RE(num)
	return self.timeleft >= num
end

-- 剩余效果范围内
function lib:BT(num1, num2)
	return self.timeleft > num1 and self.timeleft < num2
end

function lib:BE(num1, num2)
	return self.timeleft >= num1 and self.timeleft <= num2
end

-- 堆叠次数
function lib:GetStack()
	return self.count or 0
end

-- 效果存在
function lib:Ticking()
	return self.timeleft > 0
end

-- 效果需要刷新
function lib:NeedRefresh()
	return self.timeleft <= self.refresh
end

function lib:Refreshable()
	return self.timeleft <= self.refresh
end

-- 取得技能消耗
function lib:Cost()
	local costtable = GetSpellPowerCost(self.sid)
	
	if costtable == nil then
		return 0
	elseif #costtable == 0 then
		return 0
	elseif costtable[1]["cost"] == nil then
		return 0
	else
		return costtable[1]["cost"]
	end
end

function lib:Known()
	return IsSpellKnown(self.sid)
end