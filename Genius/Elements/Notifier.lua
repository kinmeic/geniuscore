local Notifier = CreateFrame("Frame", "GeniusNotifier", UIParent)
local timer = 0

Notifier:SetSize(418, 72)
Notifier:SetPoint("TOP", 0, -190)
Notifier:EnableMouse(false)
Notifier:Hide()
Notifier.last = 0
Notifier.continue = 1.5

Notifier.bg = Notifier:CreateTexture(nil, 'BACKGROUND')
Notifier.bg:SetTexture([[Interface\LevelUp\LevelUpTex]])
Notifier.bg:SetPoint('BOTTOM')
Notifier.bg:SetSize(326, 103)
Notifier.bg:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
Notifier.bg:SetVertexColor(1, 1, 1, 0.6)

Notifier.lineTop = Notifier:CreateTexture(nil, 'BACKGROUND')
Notifier.lineTop:SetDrawLayer('BACKGROUND', 2)
Notifier.lineTop:SetTexture([[Interface\LevelUp\LevelUpTex]])
Notifier.lineTop:SetPoint("TOP")
Notifier.lineTop:SetSize(418, 7)
Notifier.lineTop:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

Notifier.lineBottom = Notifier:CreateTexture(nil, 'BACKGROUND')
Notifier.lineBottom:SetDrawLayer('BACKGROUND', 2)
Notifier.lineBottom:SetTexture([[Interface\LevelUp\LevelUpTex]])
Notifier.lineBottom:SetPoint("BOTTOM")
Notifier.lineBottom:SetSize(418, 7)
Notifier.lineBottom:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)

Notifier.text = Notifier:CreateFontString(nil, 'ARTWORK', 'GameFont_Gigantic')
Notifier.text:SetPoint("BOTTOM", 0, 17)
Notifier.text:SetTextColor(1, 0.82, 0)
Notifier.text:SetJustifyH("CENTER")

Notifier:SetScript("OnUpdate", function(self, elasped)
	timer = timer + elasped
	if (timer <= 0.5) then self:SetAlpha(timer * 2) end
	if (timer > self.continue + 0.5 and timer < self.continue + 1) then self:SetAlpha(1 - (timer - self.continue - 0.5) * 2) end
	if (timer >= self.continue + 1) then self:Hide(); end
end)

Notifier:SetScript("OnShow", function(self)
	timer = 0
end)
