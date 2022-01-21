-- In this file, we're storing judgment offset data that occurs during gameplay so that
-- ScreenEvaluation can use it to draw both the scatterplot and the offset histogram.
--
-- Similar to PerColumnJudgmentTracking.lua, this file doesn't override or recreate the engine's
-- judgment system in any way. It just allows transient judgment data to persist beyond ScreenGameplay.
------------------------------------------------------------

local player = ...
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local pn = tonumber(player:sub(-1))
local iscourse = GAMESTATE:IsCourseMode()
local detailed_judgments = (not iscourse) and {} or nil

return Def.Actor{
	JudgmentMessageCommand=function(self, params)
		if params.Player ~= player then return end
		if params.TapNoteScore == "TapNoteScore_AvoidMine" then return end
		if GAMESTATE:GetPlayerState(player):GetPlayerController() == "PlayerController_Autoplay" then
			return
		end


		local dt = (not iscourse) and detailed_judgments
			or WF.DetailedJudgmentsPerSongInCourse[pn][WF.CurrentSongInCourse]

		-- some course logic defined in WF-Scoring.lua
		if iscourse then
			WF.TrackCourseJudgment(params, pss)
		end

		if params.HoldNoteScore then
			if params.HoldNoteScore == "HoldNoteScore_MissedHold" then return end
			local seconds = GAMESTATE:GetCurMusicSeconds()
			local hs = ToEnumShortString(params.HoldNoteScore)
			table.insert(dt, {seconds, hs, (params.FirstTrack + 1) % 10})
			return
		end

		if params.TapNoteScore == "TapNoteScore_HitMine" then
			local seconds = GAMESTATE:GetCurMusicSeconds()
			table.insert(dt, {seconds, "HitMine", (params.FirstTrack + 1) % 10})
			return
		end

		if params.TapNoteOffset then
			-- Record both the TNS and the raw offset; can just use 0 for Miss now, since Miss will be recorded as well.
			-- We want to be able to output both the TNS and offset to a file in a nice way later, and this formatting is
			-- more consistent.
			local offset = params.TapNoteOffset
			local tns = ToEnumShortString(params.TapNoteScore)
			local seconds = GAMESTATE:GetCurMusicSeconds()

			-- need to get panel information in a table for tap note judgments
			local panels = {}
			for c, note in pairs(params.Notes) do
				local tnt = note:GetTapNoteType()
				if tnt == "TapNoteType_Tap" or tnt == "TapNoteType_HoldHead" or tnt == "TapNoteType_Lift" then
					table.insert(panels, c % 10)
				end
			end

			-- Store judgment offsets (including misses) in an indexed table as they occur.
			-- Also store the CurMusicSeconds for Evaluation's scatter plot.
			table.insert(dt, {seconds, tns, panels, offset})

			-- Handle FA+ tracking
			WF.TrackFAPlus(pn, params)
		end
	end,
	OffCommand=function(self)
		local storage = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1]
		storage.detailed_judgments = (not iscourse) and detailed_judgments or WF.DetailedJudgmentsPerSongInCourse[pn]
	end
}