local ADDON_NAME, addon = ...

if not addon.FAT then return end

local _DB
local _anchor = CreateFrame("Frame", ADDON_NAME.."_Anchor", UIParent)

local setframe
do
	local OnDragStart = function(self)
		self:StartMoving()
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()

		local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()

		_DB.point = point
		_DB.x = xOffset
		_DB.y = yOffset
	end

	setframe = function(frame)
		frame:SetFrameStrata"TOOLTIP"
		frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";})
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)
		frame:RegisterForDrag"LeftButton"
		frame:SetBackdropBorderColor(0, .9, 0)
		frame:SetBackdropColor(0, .9, 0)
		frame:Hide()

		frame:SetScript("OnDragStart", OnDragStart)
		frame:SetScript("OnDragStop", OnDragStop)
		frame:SetScript("OnHide", OnDragStop)

		frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.text:SetPoint"CENTER"
		frame.text:SetJustifyH"CENTER"
		frame.text:SetFont(GameFontNormal:GetFont(), 12)
		frame.text:SetTextColor(1, 1, 1)

		return frame
	end
end

setframe(_anchor)
_anchor:SetHeight(addon.FAT:GetHeight())
_anchor:SetWidth(addon.FAT:GetWidth())
_anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
_anchor.text:SetText(ADDON_NAME)

local _LOCK
SLASH_FREEBABSORBTRACKER1 = "/fat"
SlashCmdList["FREEBABSORBTRACKER"] = function(inp)
	if not _LOCK then
		_anchor:Show()
		_LOCK = true
	else
		_anchor:Hide()
		_LOCK = nil
	end
end

addon.FAT:SetPoint("BOTTOMRIGHT", _anchor, "BOTTOMRIGHT")

do
	local frame = CreateFrame"Frame"
	frame:RegisterEvent"ADDON_LOADED"
	frame:SetScript("OnEvent", function(self, event, addon)
		if addon ~= ADDON_NAME then return end

		_DB = freebAbsorbTrackerDB or {}
		freebAbsorbTrackerDB = _DB

		if _DB.point then
			_anchor:ClearAllPoints()
			_anchor:SetPoint(_DB.point, UIParent, _DB.point, _DB.x, _DB.y)
		end

		self:UnregisterEvent"ADDON_LOADED"
	end)
end

