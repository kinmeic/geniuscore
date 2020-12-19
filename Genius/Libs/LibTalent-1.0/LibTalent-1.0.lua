---------------------
-- Local Definations
---------------------
local MAJOR_VERSION = "LibTalent-1.0"
local MINOR_VERSION = 40000 + tonumber(("$Rev: 001 $"):match("%d+"))

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local GetTalentInfo = GetTalentInfo
local select = select

local currX, currY, lastX, lastY = 0, 0, 0, 0

function lib:New(unit)
	local obj = {}
	obj.unit = unit
	
	-- 基本属性
	obj.HP = 0
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

-- 更新所有状态
function lib:Update()
	if UnitExists(self.unit) then
		
	end
end

-- 获取名称
function lib:GetName()
	return UnitName(self.unit)
end
