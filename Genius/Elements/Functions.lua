local Core = LibStub("AceAddon-3.0"):GetAddon("Genius")

--是否可以驱散
function Core:CanDispel(unit, spellName, dispelType)
	local name, auraType = nil, nil

	for i = 1, 40 do
		name, _, _, _, auraType = UnitAura(unit, i, "RAID|HARMFUL")
		
		if not name then
			return
		else
			if dispelType then
				if dispelType == auraType then
					return Core:CanCast(spellName)
				end
			else
				return Core:CanCast(spellName)
			end
		end
	end
end

--是否能爆发
function Core:CanBurst()
	local level = UnitLevel("target")
	if level > 0 and level < 86 then return end
	
	local class = UnitClassification("target")
	if class == "elite" or class == "worldboss" then
		return UnitCanAttack("player", "target")
	end
end

--是否装备了指定雕纹
function Core:SearchGlyph(id)
	for i=1, NUM_GLYPH_SLOTS do
		local _, _, _, glyphSpell = GetGlyphSocketInfo(i)
		if glyphSpell and glyphSpell == id then
			return true
		end
	end
end


