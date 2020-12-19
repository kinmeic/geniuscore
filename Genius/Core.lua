if not LibStub then error("Genius requires LibStub.") end

local Core = LibStub("AceAddon-3.0"):NewAddon("Genius", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Genius")

-- 按键颜色映射
local keys = {
	["D1"] = 10,
	["D2"] = 15,
	["D3"] = 20,
	["D4"] = 25,
	["D5"] = 30,
	["D6"] = 35,
	["D7"] = 40,
	["D8"] = 45,
	["D9"] = 50,
	["D0"] = 55,
	["S-"] = 60,
	["S="] = 65,
	["F1"] = 70,
	["F2"] = 75,
	["F3"] = 80,
	["F4"] = 85,
	["F5"] = 90,
	["F6"] = 95,
	["F7"] = 100,
	["F8"] = 105,
	["F9"] = 110,
	["F10"] = 115,
	["F11"] = 120,
	["F12"] = 125,
	["ALT"] = 130,
	["NUMPAD0"] = 135,
	["NUMPAD1"] = 140,
	["NUMPAD2"] = 145,
	["NUMPAD3"] = 150,
	["NUMPAD4"] = 155,
	["NUMPAD5"] = 160,
	["NUMPAD6"] = 175,
	["NUMPAD7"] = 170,
	["NUMPAD8"] = 175,
	["NUMPAD9"] = 180,
	["X1"] = 190,
	["X2"] = 195,
	["SPACE"] = 200
}

local options = {
	["DEFAULT_SWITCH_SCHEME"] = {
		{ ["name"] = "自动攻击", ["show"] = true },
		{ ["name"] = "禁止断法", ["show"] = true },
		{ ["name"] = "手动爆发", ["show"] = true },
		{ ["name"] = "群体攻击", ["show"] = true }
	}
}

-- 定时器
local MainTimer = 0
local passed = 0
local OnUpdate = function(self, elapsed)
	MainTimer = MainTimer + elapsed

	--刷荣誉
--	if Core.Switch4:GetChecked() then
--		passed = passed + elapsed
--		
--		if (passed > 3) then
--			StaticPopup1Button1:Click()
--			print("try to close logout dialog.")
--			passed = 0
--		end
--	end

	if (MainTimer > 0.05) then
--		MainTimer = MainTimer - 0.05
		MainTimer = MainTimer - 0.1
		
--		if (not IsLeftShiftKeyDown()) and Core.Auto then
		
		if (not Core.Switch1:GetChecked()) then
			return
		elseif Core.Auto then
			Core:Auto(MainTimer)
		else
			Core:Press(nil)
		end
	end
end

-- 命令行执行
local OnCommand = function(msg)
	local arg, param = msg:match("^(%S*)%s*(.-)$");
	
	arg = string.lower(arg)

	if strlen(arg) == 7 and string.sub(arg, 0, 6) == "switch" then
		Core:SetSwitch(string.sub(arg, 7, 7), param)
	elseif arg == "auto" and param == "next" then
		Core.Switch1:SetChecked(false)
		Core.AutoAfterCasted = true
		Core:Manual(arg, param)
	elseif arg == "auto" then
		Core.Switch1:SetChecked(true)
	else
		Core:Manual(arg, param)
	end
end

-- 插件初始化
function Core:OnInitialize()
	-- 控件映射
	self.Indicator = _G["GeniusIndicator"]
	self.Indicator.Color = _G["GeniusIndicatorColor"]
	self.Label = _G["GeniusIndicatorText"]
	
	-- 开关映射
	self.Switch1 = _G["GeniusPanelSwitch1"]
	self.Switch2 = _G["GeniusPanelSwitch2"]
	self.Switch3 = _G["GeniusPanelSwitch3"]
	self.Switch4 = _G["GeniusPanelSwitch4"]
	
	-- 配置映射
	self.Options = options
	
	-- 声明属性
	self.AutoAfterCasted = false	-- 施法成功够启动自动攻击
	self.ShowStanceNotice = true
	self.Talent = 0
	self.Stance = 0
	self.CombatTime = 0
	self.CalcDamage = 0
	self.IncomingDamage = {}		-- 承受伤害

	-- 天赋方案
	self.Scheme = {}
	
	-- 按键绑定方案
	self.Binding = {}
end

-- 插件启用
function Core:OnEnable()
	self.Indicator:SetFrameStrata("TOOLTIP")	--FULLSCREEN
	
	-- 注册事件
	self:RegisterEvent("VARIABLES_LOADED")				--参数加载
	self:RegisterEvent("PLAYER_ALIVE")					--玩家复活
	self:RegisterEvent("PLAYER_REGEN_DISABLED")			--进入战斗
	self:RegisterEvent("PLAYER_REGEN_ENABLED")			--脱离战斗
--	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")	--玩家切换天赋事件
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")		--玩家可用天赋点数事件
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")		--玩家姿态切换事件
	self:RegisterEvent("UNIT_SPELLCAST_SENT")			--发送施法信息到服务器
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")		--施法成功
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_FAILED")		--施法失败
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED")	--施法中断
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_FAILED")	--施法失败
--	self:RegisterEvent("UNIT_AURA")						--效果变化
	self:RegisterEvent("UI_ERROR_MESSAGE")				--错误消息
	
	-- 注册自动刷新
	self.Indicator:SetScript("OnUpdate", OnUpdate)
	self:HookScript(self.Indicator, "OnEnter", "ShowGameTooltip")
	
	-- 注册命令行
	SlashCmdList["GENIUSSLASH"] = OnCommand
	SLASH_GENIUSSLASH1 = "/genius"
	
	-- 显示加载
	if self.Auto or self.Manual then
		self:Printf(L["Module Enabled"], UnitClass("player"))
		self:ACTIVE_TALENT_GROUP_CHANGED()
	else
		self:Printf(L["Module Not Found"], UnitClass("player"))
	end
end

-- 插件禁用
function Core:OnDisable()
	self.Indicator:SetScript("OnUpdate", nil)
end

-- 发送按键信息
function Core:Press(keyName)
	if keyName and keys[keyName] then
		-- 有效按键
		self.Indicator.Color:SetVertexColor(keys[keyName] / 255, 0.025, 0, 1)
		self.Label:SetText(keyName)
	else
		-- 无效按键
		self.Indicator.Color:SetVertexColor(0, self.CombatTime == 0 and 0 or 0.025, 0, 1)
		self.Label:SetText(IsLeftShiftKeyDown() and L["Pending"] or L["Waiting"])
	end
end

-- 显示鼠标提示
function Core:ShowGameTooltip()
	GameTooltip_SetDefaultAnchor(GameTooltip, self.Indicator);
	GameTooltip:AddLine(L["Information"])
	GameTooltip:AddDoubleLine(L["Talent"], self.Talent, 0, 1, 0)
	GameTooltip:AddDoubleLine(L["Stance"], self.Stance, 0, 1, 0)
--	GameTooltip:AddDoubleLine(L["Memory"], format("%.2f",GetAddOnMemoryUsage("Genius")).." KB")
	GameTooltip:Show()
end

-- 显示提醒
function Core:ShowNotifier(text, continue, force)
	if (not GeniusNotifier) then return end
	if (not GeniusNotifier:IsShown()) or force then
		GeniusNotifier.text:SetText(text)
		GeniusNotifier.continue = continue or 1.5
		GeniusNotifier.last = GetTime()
		GeniusNotifier:Show()
		return GeniusNotifier.last
	end
end

-- 设置开关
function Core:UpdateSwitchs()
	local class = select(2, UnitClass("player"))
	local spec = "TALENT" .. Core.Talent
	local scheme = options["DEFAULT_SWITCH_SCHEME"]
	
	if options[class] and options[class]["SWITCH_SCHEME"] and 
		options[class]["SWITCH_SCHEME"][spec] then
		scheme = options[class]["SWITCH_SCHEME"][spec]
	end
	
	_G["GeniusPanel"]:Show()
	
	for i = 1, #scheme do
		local name = scheme[i]["name"] or ""
		local show = scheme[i]["show"]
		
		if _G["GeniusPanelSwitch" .. i] then
			_G["GeniusPanelSwitch" .. i]:SetChecked(false)
			
			if show then
				_G["GeniusPanelSwitch" .. i]:Show()
				_G["GeniusPanelSwitch" .. i .. "Text"]:SetText(name)
			else
				_G["GeniusPanelSwitch" .. i]:Hide()
			end
		end
	end
end

-- 设置开关
function Core:SetSwitch(number, status, text)
	local widget = "GeniusPanelSwitch" .. number
	
	if _G[widget] then
		if status == "on" then
			_G[widget]:SetChecked(true)
		elseif status == "off" then
			_G[widget]:SetChecked(false)
		elseif status == "show" then
			_G[widget]:Show()
		elseif status == "hide" then
			_G[widget]:Hide()
		elseif status == "text" then
			_G[widget .. "Text"]:SetText(text)
		end
	end
end

-- 获取开关选中情况
function Core:IsSwitchChecked(number)
	local widget = "GeniusPanelSwitch" .. number
	return _G[widget]:GetChecked()
end

function Core:Bind(key, spell)
	if keys[key] == nil then
		self:Printf(L["Unknow Key To Bind"], spell, key)
	elseif SetBindingSpell(key, spell) then
		self:Printf(L["Bind OK"], spell, key)
	else
		self:Printf(L["Bind Fail"], spell, key)
	end
end
