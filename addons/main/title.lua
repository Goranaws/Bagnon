--[[
	title.lua
		A title frame widget
--]]


local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Title = Addon.Tipped:NewClass('Title', 'Button')


--[[ Construct ]]--

function Title:New(parent, title)
	local b = self:Super(Title):New(parent)
	b.title = title

	b:SetScript('OnHide', b.OnMouseUp)
	b:SetScript('OnMouseDown', b.OnMouseDown)
	b:SetScript('OnMouseUp', b.OnMouseUp)
	b:SetScript('OnDoubleClick', b.OnDoubleClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnClick', b.OnClick)

	b:RegisterSignal('SEARCH_TOGGLED', 'UpdateVisible')
	b:RegisterFrameSignal('OWNER_CHANGED', 'Update')
	b:RegisterForClicks('anyUp')

	b:SetHighlightFontObject('GameFontHighlightLeft')
	b:SetNormalFontObject('GameFontNormalLeft')
	b:SetToplevel(true)
	b:Update()

	return b
end


--[[ Interaction ]]--

function Title:OnMouseDown()
	local parent = self:GetParent()
	if not parent.profile.managed and (not Addon.sets.locked or IsAltKeyDown()) then
		parent:StartMoving()
	end
end

function Title:OnMouseUp()
	local parent = self:GetParent()
	parent:StopMovingOrSizing()
	parent:RecomputePosition()
end

function Title:OnDoubleClick()
	Addon.canSearch = true
	Addon:SendSignal('SEARCH_TOGGLED', self:GetFrameID())
end

function Title:OnClick(button)
	if button == 'RightButton' and LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frameID = self:GetFrameID()
		Addon.FrameOptions:Open()
	end
end

local modifierActions = {
	IsShiftKeyDown = .1,
	IsControlKeyDown = 1,
	IsAltKeyDown = 5,
}

local function GetNudgeStep()
	for funcName, stepValue in pairs(modifierActions) do
		if _G[funcName]() == true then
			return stepValue
		end
	end
end

function Title:OnEnter()
	GameTooltip:SetOwner(self:GetTipAnchor())
	GameTooltip:SetText(self:GetText())
	GameTooltip:AddLine(L.TipConfigure:format(L.RightClick), 1,1,1)
	GameTooltip:AddLine(L.TipShowSearch:format(L.DoubleClick), 1,1,1)
	GameTooltip:AddLine(L.TipMove:format(L.Drag), 1,1,1)
	GameTooltip:Show()
	
	
	if IsModifierKeyDown() == true then
		self:SetKeyboardNudgeEnable(true)
	end	
end

local KEYBOARD_MOVEMENT_INCREMENT = 1

function Title:SetKeyboardNudgeEnable(flag)
	
	self:SetScript('OnKeyDown', function(_, key)
		KEYBOARD_MOVEMENT_INCREMENT = GetNudgeStep() or KEYBOARD_MOVEMENT_INCREMENT
		self:OnKeyDown(key)
	end)
	
	self:SetScript('OnKeyUp', function(_, key)
		if IsModifierKeyDown() ~= true then 
			self:SetScript('OnKeyDown', nil)
			self:SetScript('OnKeyUp', nil)
		end
	end)
end

local nudge = {
	MOVEFORWARD = {0, KEYBOARD_MOVEMENT_INCREMENT},
	MOVEBACKWARD = {0, -KEYBOARD_MOVEMENT_INCREMENT},
	TURNLEFT = {-KEYBOARD_MOVEMENT_INCREMENT, 0},
	TURNRIGHT = {KEYBOARD_MOVEMENT_INCREMENT, 0},
	
}

function Title:OnKeyDown(key)
	local increment, bind = nudge[GetBindingAction(key)], GetBindingAction(key)
	if increment and bind then
		self:NudgeFrame(unpack(increment))
		self:SetPropagateKeyboardInput(false) --must be called or will move character as well.
	end
end

function Title:NudgeFrame(dx, dy)
    local oX, oY, ow, oh = self:GetParent():GetRect()
    local pw, ph = UIParent:GetSize()
	local eS = self:GetParent():GetEffectiveScale()
	pw, ph = pw / eS, ph / eS
    local x = Clamp((oX + dx), 0, pw - ow)
    local y = Clamp((oY + dy), 0, ph - oh)

	self:GetParent():ClearAllPoints()
	self:GetParent():SetPoint("BOTTOMLEFT", self:GetParent():GetParent(), "BOTTOMLEFT", x, y)
    self:GetParent():SavePosition("BOTTOMLEFT", "BOTTOMLEFT", x, y)
end

--[[ API ]]--

function Title:Update()
	self:SetFormattedText(self.title, self:GetOwnerInfo().name)
	self:GetFontString():SetAllPoints(self)
end

function Title:UpdateVisible(_, busy)
	self:SetShown(not busy)
end

function Title:IsFrameMovable()
	return not Addon.sets.locked
end
