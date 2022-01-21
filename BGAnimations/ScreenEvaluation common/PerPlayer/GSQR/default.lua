-- Pane6 displays QR codes for uploading scores to groovestats.com

-- This feature will still be available, but only under specific conditions.
-- If not playing on "Simulate ITG Environment," the pane will not even appear at all.
-- However, if it is in use, all the normal checks prepared by SL will be done (all the ones that still apply anyway).
-- There are also some parameters I am just going to set in WF-Scoring.lua that will enforce some extra restrictions
-- but have those still be easily changeable. For example, I can have whether this disqualifies a score that isn't using
-- a "verified" noteskin (one that comes with the theme), or whether FA+ is visible in gameplay, configurable.

local args = ...
local player = args.player
local hash = args.hash
local name = args.sec and "GSQR2" or "GSQR"

if GAMESTATE:IsCourseMode() then return nil end

-- ------------------------------------------
--

-- See SL-Helpers-GrooveStats.lua for all the checks in ValidForGrooveStats

local checks, IsValid = ValidForGrooveStats(player)

local url, text = nil, ""
local X_HasBeenBlinked = false

-- GrooveStatsURL.lua returns a formatted URL with some parameters in the query string
if IsValid then
	url = LoadActor("./GrooveStatsURL.lua", {player = player, hash = hash})
	text = ScreenString("QRInstructions")
else
	url = GetFunnyURL()

	for i, passed_check in ipairs(checks) do
		if passed_check == false then
			text = text .. ScreenString("QRInvalidScore"..i) .. "\n"
		end
	end
end

local qrcode_size = 168

-- ------------------------------------------
local what_prob = 25
if (#GAMESTATE:GetHumanPlayers() == 2) or SL[ToEnumShortString(player)].ActiveModifiers.SimulateITGEnv then
	what_prob = what_prob * 2
end

local pane = Def.ActorFrame{
	Name = name,
	InitCommand=function(self) self:visible(false):xy(-140, 222) end,
	ShrinkCommand=function(self)
		if self:GetVisible() and not IsValid and not X_HasBeenBlinked then
			self:queuecommand("BlinkX")
		end
	end,
	SetAlreadySubmittedCommand = function(self) self:playcommand("What") end,
	SetNotRankedCommand = function(self) self:playcommand("What") end,
	WhatCommand = function(self)
		if math.random(1, what_prob) == 17 then
			self:sleep(0.01):queuecommand("ActuallyWhat")
		end
	end
}

pane[#pane+1] = qrcode_amv( url, qrcode_size )..{
	InitCommand=function(self) self:xy(116, -32):align(0,0.5) end
}

-- quad to block out qr code if a score has already been submitted, or is not ranked
pane[#pane+1] = Def.Quad{
	InitCommand = function(self) self:xy(116, -32):zoom(qrcode_size+1):horizalign("left"):vertalign("top")
		:diffuse(0.1,0.1,0.1,1):visible(false) end,
	SetAlreadySubmittedCommand = function(self) self:visible(true) end,
	SetNotRankedCommand = function(self) self:visible(true) end
}

-- ?
pane[#pane+1] = qrcode_amv(GetFunnyURL(), qrcode_size)..{
	InitCommand=function(self) self:xy(116, -32):align(0,0.5):visible(false) end,
	ActuallyWhatCommand = function(self) self:visible(true) end
}

-- red X to visually cover the QR code if the score was invalid
if not IsValid then
	pane[#pane+1] = LoadActor("x.png")..{
		InitCommand=function(self)
			self:zoom(1):xy(120,-28):align(0,0)
		end,
		-- blink the red X once when the player first toggles into the QR pane
		BlinkXCommand=function(self)
			X_HasBeenBlinked = true
			self:finishtweening():sleep(0.25):linear(0.3):diffusealpha(0):sleep(0.175):linear(0.3):diffusealpha(1)
		end
	}
end

pane[#pane+1] = LoadActor("../PerPanel/Percentage.lua", {player=player, mode="ITG"})..{
	OnCommand=function(self) self:xy(25, -22) end
}

pane[#pane+1] = LoadFont("Common Normal")..{
	Text="GrooveStats QR",
	InitCommand=function(self) self:align(0,0) end
}

pane[#pane+1] = Def.Quad{
	InitCommand=function(self) self:y(23):zoomto(96,1):align(0,0):diffuse(1,1,1,0.33) end
}

-- if there are multiple reasons the score was invalid for GrooveStats ranking
-- the help text might spill outside the vertical bounds of the pane
-- hide any such spillover with a mask
if not IsValid then
	pane[#pane+1] = Def.Quad{
		InitCommand=function(self) self:xy(-10, 142):zoomto(121,140):align(0,0):MaskSource() end
	}
end

-- localized help text, either "use your phone to scan" or "here's why your score was invalid"
pane[#pane+1] = LoadFont("Common Normal")..{
	Text=text,
	InitCommand=function(self)
		self:align(0,0):vertspacing(-3):MaskDest()

		local z = IsValid and 0.8 or 0.675
		self:zoom(z)
		self:y( scale(35, 0,0.8,   0,z) )
		self:x( scale(-4, 0,0.675, 0,z) )
		self:wrapwidthpixels( scale(98, 0,0.675, 0,z)/z)

		-- FIXME: Oof.
		if THEME:GetCurLanguage() == "ja" then self:_wrapwidthpixels( scale(96, 0,0.8, 0,z)/z ) end
	end,
	SetAlreadySubmittedCommand = function(self)
		self:settext("This score has already been submitted to GrooveStats.")
	end,
	SetNotRankedCommand = function(self)
		self:settext("This chart is not ranked on GrooveStats.")
	end,
	ActuallyWhatCommand = function(self)
		self:settext(self:GetText().." But here's another QR to scan if you want 🙂")
	end
}


return pane
