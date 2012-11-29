local ADDON_NAME, addon = ...

local filename, fontHeight, flags = NumberFont_Outline_Med:GetFont()

local mediaPath = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\"
local cfg = {
	texture = mediaPath.."Cabaret",
	glowTex = mediaPath.."glowTex",

	--font = mediaPath.."FONT.ttf",
	--fontoutline = "THINOUTLINE",

	font = filename,
	fontoutline = flags,

	width = 150,

	bar1 = {
		height = 18,
		fontsize = fontHeight,
		r = .1,
		g = .9,
		b = .1,
	},

	bar2 = {
		height = 12,
		fontsize = 11,
		r = .9,
		g = .1,
		b = .1,
	},

	WARRIOR = 112048,
	MONK = 115295,
	DEATHKNIGHT = 77535,
	PALADIN = 65148,
}

local _, class = UnitClass("player")

if not cfg[class] then return end

local spellname = GetSpellInfo(cfg[class])

local GetTime = GetTime
local format = format

local numberize = function(val)
	if (val >= 1e6) then
		return ("%.1fm"):format(val / 1e6)
	elseif (val >= 1e3) then
		return ("%.1fk"):format(val / 1e3)
	else
		return ("%d"):format(val)
	end
end

local frameBD = {
	edgeFile = cfg.glowTex, edgeSize = 5,
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local createBackdrop = function(parent, anchor) 
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetFrameStrata("LOW")

	frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", -4, 4)
	frame:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 4, -4)
	frame:SetBackdrop(frameBD)

	frame:SetBackdropColor(.05, .05, .05, 1)
	frame:SetBackdropBorderColor(0, 0, 0)

	return frame
end

local createStatusbar = function(parent, tex, layer, height, width, r, g, b, alpha)
	local bar = CreateFrame"StatusBar"
	bar:SetParent(parent)
	bar:SetHeight(height)
	bar:SetWidth(width)
	bar:SetStatusBarTexture(tex, layer)
	bar:SetStatusBarColor(r, g, b, alpha)

	bar.bg = bar:CreateTexture(nil, "BORDER")
	bar.bg:SetAllPoints(bar)
	bar.bg:SetTexture(tex)
	bar.bg:SetVertexColor(.1,.1,.1)

	return bar
end

local createFont = function(parent, layer, font, fontsize, outline, r, g, b, justify)
	local str = parent:CreateFontString(nil, layer)
	str:SetFont(font, fontsize, outline)
	str:SetShadowOffset(1, -1)
	str:SetTextColor(r, g, b)
	if justify then
		str:SetJustifyH(justify)
	end

	return str
end

local FAT = CreateFrame("Frame", ADDON_NAME, UIParent)
FAT:SetSize(cfg.width, (cfg.bar1.height+cfg.bar2.height)+1)
FAT.bg = createBackdrop(FAT, FAT)
FAT:Hide()

addon.FAT = FAT

local min, max, abs = math.min, math.max, abs
local GetFramerate = GetFramerate
local SetValue = CreateFrame("StatusBar").SetValue
local function Smooth(self, value)
	if value == self:GetValue() then
		self.smoothing = nil
	else
		self.smoothing = value
	end
end

local SmoothUpdate = function(self)
	local value = self.smoothing
	if not value then return end

	local limit = 30/GetFramerate()
	local cur = self:GetValue()
	local new = cur + min((value-cur)/4, max(value-cur, limit))

	if new ~= new then
		new = value
	end

	self:SetValue_(new)
	if cur == value or abs(new - value) < 2 then
		self:SetValue_(value)
		self.smoothing = nil
	end
end

local updateTime = function(self, elapsed)
	local timeLeft = (self.timeLeft or 0) - elapsed
	if timeLeft <= 0 then return end

	self.text:SetFormattedText("%.1f", timeLeft)
	self:SetValue(timeLeft)

	self.timeLeft = timeLeft
end

local bar1 = createStatusbar(FAT, cfg.texture, "OVERLAY", cfg.bar1.height, cfg.width, cfg.bar1.r, cfg.bar1.g, cfg.bar1.b, 1)
bar1:SetPoint"LEFT"
bar1:SetPoint"RIGHT"
bar1:SetPoint"TOP"
bar1.SetValue_ = SetValue
bar1.SetValue = Smooth
bar1:SetScript("OnUpdate", SmoothUpdate)

bar1.text = createFont(bar1, "OVERLAY", cfg.font, cfg.bar1.fontsize, cfg.fontoutline, 1, 1, 1)
bar1.text:SetPoint"CENTER"

local bar2 = createStatusbar(FAT, cfg.texture, "OVERLAY", cfg.bar2.height, cfg.width, cfg.bar2.r, cfg.bar2.g, cfg.bar2.b, 1)
bar2:SetPoint"LEFT"
bar2:SetPoint"RIGHT"
bar2:SetPoint"BOTTOM"
bar2:SetScript("OnUpdate", updateTime)

bar2.text = createFont(bar2, "OVERLAY", cfg.font, cfg.bar2.fontsize, cfg.fontoutline, 1, 1, 1)
bar2.text:SetPoint"CENTER"

local function updateFAT(value1, duration, expirationTime)
	bar1.text:SetText(numberize(value1))
	bar1:SetValue(value1)

	bar2.timeLeft = expirationTime - GetTime()

	if not bar1.running then
		bar1:SetMinMaxValues(0, value1)
		bar1.running = true

		bar2:SetMinMaxValues(0, duration)

		FAT:Show()
	end
end

FAT:RegisterEvent"UNIT_AURA"
FAT:SetScript("OnEvent", function(self, event, arg1)
	if(event ~= "UNIT_AURA") or (arg1 ~= "player") then return end
	local _Hide = true

	local index=1
	while true do 
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, _,
		_, spellId, _, isBossDebuff, _, value1, value2, value3 = UnitBuff("player", index)

		if not name then break end

		if(value1 and unitCaster == "player" and spellId == cfg[class]) then
			updateFAT(value1, duration, expirationTime)

			_Hide = false
			break
		end

		_Hide = true
		index = index + 1
	end

	if _Hide then
		bar1.running = false
		bar2.duration = nil
		FAT:Hide()
	end
end)
