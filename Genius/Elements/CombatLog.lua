local select, UnitGUID = select, UnitGUID
local timestamp, subevent, sourceGUID, sourceName, destGUID, destName, spellID, spellName, spellSchool, suffixe1, suffixe2, suffixe3
local prefix

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")
local L = LibStub("AceLocale-3.0"):GetLocale("Genius")

function Core:COMBAT_LOG_EVENT(event, ...)
	timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName = ...
	spellID, spellName, spellSchool, suffixe1, suffixe2, suffixe3 = select(12, ...)
--	prefix = strsub(subevent, 1, 5)

	if sourceGUID == UnitGUID("player") then	-- 主动的
		-- 打断施法
		if subevent == "SPELL_INTERRUPT" then
			SendChatMessage(string.format(L["Break Success"], destName, select(16, ...)), "yell")
		end
	elseif destGUID == UnitGUID("player") then	-- 被动的

	else	-- 别人的
		
		
		
		
	end
	
	
--	if sourceGUID == UnitGUID("player") then
--		if subevent == "SPELL_INTERRUPT" then
--			SendChatMessage(string.format(L["Break Success"], destName, select(16, ...)), "yell")
--		elseif surfix == "SPELL" and self["LOG_"..subevent] then
--			self["LOG_"..subevent](self, destGUID, spellID, spellName)
--	elseif surfix == "UNIT_DIED" then
--		self["LOG_UNIT_DIED"](self, destGUID, destName)
--	end
end
