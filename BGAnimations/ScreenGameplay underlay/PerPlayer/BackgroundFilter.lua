local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers

-- if no BackgroundFilter is necessary, it's safe to bail now
if mods.BackgroundFilter == "Off" then return end

local FilterAlpha = {
	Dark = 0.5,
	Darker = 0.75,
	Darkest = 0.95
}

return Def.Quad{
	InitCommand=function(self)
		self:xy(GetNotefieldX(player), _screen.cy )
			:diffuse(Color.Black)
			:diffusealpha( FilterAlpha[mods.BackgroundFilter] or 0 )
			:zoomto( GetNotefieldWidth(), _screen.h )
	end,
	OffCommand=function(self) self:queuecommand("ComboFlash") end,
	ComboFlashCommand=function(self)
		local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
		local FlashColor = nil

		local stepcount = GAMESTATE:GetCurrentSteps(player):GetRadarValues(player):GetValue("RadarCategory_TapsAndHolds")
		local totaljudgments = pss:GetTapNoteScores("TapNoteScore_W1") + pss:GetTapNoteScores("TapNoteScore_W2") +
			pss:GetTapNoteScores("TapNoteScore_W3") + pss:GetTapNoteScores("TapNoteScore_W4") +
			pss:GetTapNoteScores("TapNoteScore_W5") + pss:GetTapNoteScores("TapNoteScore_Miss")
		
		if totaljudgments < stepcount then return end

		if not mods.SimulateITGEnv then
			local WorstAcceptableFC = SL.Preferences.Waterfall.MinTNSToHideNotes:gsub("TapNoteScore_W", "")

			for i=1, tonumber(WorstAcceptableFC) do
				if pss:FullComboOfScore("TapNoteScore_W"..i) then
					FlashColor = SL.JudgmentColors.Waterfall[i]
					break
				end
			end
		else
			local p = tonumber(player:sub(-1))
			if WF.ITGFCType[p] < 4 then FlashColor = SL.JudgmentColors.ITG[WF.ITGFCType[p]] end
		end

		if (FlashColor ~= nil) then
			self:accelerate(0.25):diffuse( FlashColor )
				:accelerate(0.5):faderight(1):fadeleft(1)
				:accelerate(0.15):diffusealpha(0)
		end
	end
}