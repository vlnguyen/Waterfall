local player = Var "Player"
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local sprite
local text

------------------------------------------------------------
-- A profile might ask for a judgment graphic that doesn't exist
-- If so, use the first available Judgment graphic
-- If that fails too, fail gracefully and do nothing

local useitg = SL[pn].ActiveModifiers.SimulateITGEnv
local available_judgments = GetJudgmentGraphics(useitg and "ITG" or nil)

local file_to_load = (FindInTable(mods.JudgmentGraphic, available_judgments) ~= nil and mods.JudgmentGraphic or available_judgments[1]) or "None"

if file_to_load == "None" then
	return Def.Actor{ InitCommand=function(self) self:visible(false) end }
end

local usetext = (file_to_load == "Plain Text")

if useitg and (not usetext) then file_to_load = "itg/"..file_to_load end

local threshold = mods.FAPlus
if (not useitg) and threshold == 0.015 then threshold = 0 end

------------------------------------------------------------

local TNSFrames = {
	TapNoteScore_W1 = 0,
	TapNoteScore_W2 = 2,
	TapNoteScore_W3 = 3,
	TapNoteScore_W4 = 4,
	TapNoteScore_W5 = 5,
	TapNoteScore_Miss = 6
}

local af = Def.ActorFrame{
	Name="Player Judgment",
	InitCommand=function(self)
		local kids = self:GetChildren()
		sprite = kids.JudgmentWithOffsets
		if usetext then
			text = kids.PlainTextJudgment
		end
	end,
	JudgmentMessageCommand=function(self, param)
		if param.Player ~= player then return end
		if not param.TapNoteScore then return end
		if param.HoldNoteScore then return end

		-- if in "ITG" mode, display the frame based on the ITG judgment by calculating it from the offset
		local TNSToUse = param.TapNoteScore
		if useitg and (TNSToUse ~= "TapNoteScore_Miss" and TNSToUse ~= "TapNoteScore_AvoidMine"
		and TNSToUse ~= "TapNoteScore_HitMine") then
			local window = DetermineTimingWindow(param.TapNoteOffset, "ITG")
			TNSToUse = "TapNoteScore_W"..window
		end

		-- sprite based commands
		if not usetext then
			-- "frame" is the number we'll use to display the proper portion of the judgment sprite sheet
			-- Sprite actors expect frames to be 0-indexed when using setstate() (not 1-indexed as is more common in Lua)
			-- an early W1 judgment would be frame 0, a late W2 judgment would be frame 3, and so on
			local frame = TNSFrames[ TNSToUse ]
			if not frame then return end

			-- judgment fonts now have only 7 frames, with frame 1 being "white w1"
			if TNSToUse == "TapNoteScore_W1" and threshold > 0 and math.abs(param.TapNoteOffset) > threshold then
				frame = 1
			end

			self:playcommand("Reset")

			sprite:visible(true):setstate(frame)
			-- this should match the custom JudgmentTween() from SL for 3.95
			sprite:zoom(0.8):decelerate(0.1):zoom(0.75):sleep(0.6):accelerate(0.2):zoom(0)
		else
			local mode = (not useitg) and "Waterfall" or "ITG"
			local ind = ToEnumShortString(TNSToUse)
			local word = WF.PlainTextJudgmentNames[mode][ind]
			if not word then return end
			self:playcommand("Reset")
			local cind = (ind ~= "Miss") and tonumber(ind:sub(-1)) or 6
			text:settext(word)
			if threshold > 0 and ((param.TapNoteOffset) and ind == "W1" and math.abs(param.TapNoteOffset) > threshold) then
				text:diffuse(Color.White)
			else
				text:diffuse(SL.JudgmentColors[mode][cind])
			end
			text:visible(true)
			local bz = WF.PlainTextJudgmentBaseZoom
			text:zoom(0.8*bz):decelerate(0.1):zoom(0.75*bz):sleep(0.6):accelerate(0.2):zoom(0)
		end
	end,

	Def.Sprite{
		Name="JudgmentWithOffsets",
		InitCommand=function(self)
			-- animate(false) is needed so that this Sprite does not automatically
			-- animate its way through all available frames; we want to control which
			-- frame displays based on what judgment the player earns
			self:animate(false):visible(false)

			-- if we are on ScreenEdit, judgment graphic is always "Love"
			-- because ScreenEdit is a mess and not worth bothering with.
			if string.match(tostring(SCREENMAN:GetTopScreen()), "ScreenEdit") then
				self:Load( THEME:GetPathG("", "_judgments/Optimus Dark") )

			elseif file_to_load ~= "Plain Text" then
				self:Load( THEME:GetPathG("", "_judgments/" .. file_to_load) )
			end
		end,
		ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end
	}
}

if usetext then
	af[#af+1] = LoadFont(WF.PlainTextJudgmentFont)..{
		Name = "PlainTextJudgment",
		InitCommand = function(self)
			self:visible(false)
		end,
		ResetCommand = function(self)
			self:finishtweening():stopeffect():visible(false)
		end
	}
end

return af