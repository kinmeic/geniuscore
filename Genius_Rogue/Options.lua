if select(2, UnitClass("player")) ~= "ROGUE" then return end

local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

Core.Options["ROGUE"] = {
	["SWITCH_SCHEME"] = {
		["TALENT1"] = {
			[1] = {["name"] = "自动攻击", ["show"] = true},
			[2] = {["name"] = "禁止断法", ["show"] = true},
			[3] = {["name"] = "手动爆发", ["show"] = true},
			[4] = {["name"] = "群体攻击", ["show"] = true}
		}
	}
}
