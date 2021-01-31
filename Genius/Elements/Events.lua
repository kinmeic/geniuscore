local select = select

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")
local L = LibStub("AceLocale-3.0"):GetLocale("Genius")

function Core:VARIABLES_LOADED()
	self:ACTIVE_TALENT_GROUP_CHANGED()
end

function Core:PLAYER_ALIVE()
	self:ACTIVE_TALENT_GROUP_CHANGED()
end

function Core:PLAYER_ENTERING_WORLD()
	self:ACTIVE_TALENT_GROUP_CHANGED()
end

function Core:PLAYER_REGEN_DISABLED()
	self:Print(L["Enter Combat"])
	self:ShowNotifier(L["Enter Combat"])
	self:RegisterEvent("COMBAT_LOG_EVENT")
	self.CombatTime = GetTime()
	if self["ENTER_COMBAT"] then
		self["ENTER_COMBAT"](self)
	end
end

function Core:PLAYER_REGEN_ENABLED()
	self:Print(L["Leave Combat"])
	self:ShowNotifier(L["Leave Combat"])
	self:UnregisterEvent("COMBAT_LOG_EVENT")
	self.CombatTime = 0
	if self["LEAVE_COMBAT"] then
		self["LEAVE_COMBAT"](self)
	end
end

function Core:ACTIVE_TALENT_GROUP_CHANGED()
	self.Stance = GetShapeshiftForm() or 0
	self.Talent = GetSpecialization() or 0
	
	-- 更新开关状态和文本
	self.UpdateSwitchs()

	if self.Talent and self.Talent > 0 then
		-- 设置提示信息
		local talentName = select(2, GetSpecializationInfo(self.Talent)) or L["Normal"]
		self:Printf(L["Change Talent"], talentName)
		
		-- 触发额外事件方法
		if self["TALENT_CHANGED"] then
			self["TALENT_CHANGED"](self, self.Talent)
		end
	end
end

function Core:UPDATE_SHAPESHIFT_FORM()
	self.Stance = GetShapeshiftForm() or 0

	if self.ShowStanceNotice == false then return end
	if self.Stance ~= 0 then
		local spellId = select(4, GetShapeshiftFormInfo(self.Stance))
		local stanceName = GetSpellInfo(spellId) or L["Normal"]
		self:Printf(L["Change Stance"], stanceName)
	else
		self:Printf(L["Change Stance"], L["Normal"])
	end
end

function Core:UPDATE_STEALTH()
--	self:UPDATE_SHAPESHIFT_FORM()
--	if IsStealthed() == true then
--		self.Stance = 1
--	else
--		self.Stance = 0
--	end
end

function Core:UNIT_SPELLCAST_SENT(event, unit, spell)
	if unit ~= "player" then return end
	self:Press(nil)
	if self["SPELLCAST_SENTED"] then
		self["SPELLCAST_SENTED"](self, spell)
	end
end

function Core:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell, rank, lineID, spellID)
	if unit ~= "player" then return end
	if Core.AutoAfterCasted then
		Core.AutoAfterCasted = false
		Core.Switch1:SetChecked(true)
	end
	if self["SPELLCAST_SUCCEEDED"] then
		self["SPELLCAST_SUCCEEDED"](self, spell, spellID, lineID)
	end
end

-- 施法失败
function Core:UNIT_SPELLCAST_FAILED(event, unit, spell)
	if unit ~= "player" then return end
	self:Press(nil)
	
	if self["SPELLCAST_FAILED"] then
		self["SPELLCAST_FAILED"](self, spell, event)
	end
end

-- 效果变化
--function Core:UNIT_AURA(event, unit)
--	if self["UNIT_AURA"] then
--		self["UNIT_AURA"](self, unit, event)
--	end
--end

-- error message on center of window
function Core:UI_ERROR_MESSAGE(event, message)
	if self["NEW_ERROR_MESSAGE"] then
		self["NEW_ERROR_MESSAGE"](self, message)
	end
end

