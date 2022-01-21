local args = ...
local player = args.player
local stats = args.stats
local pn = ToEnumShortString(player)
local pnum = tonumber(player:sub(-1))

local TNSTypes = {
	'TapNoteScore_W1',
	'TapNoteScore_W2',
	'TapNoteScore_W3',
	'TapNoteScore_W4',
	'TapNoteScore_W5',
	'TapNoteScore_Miss'
}

return Def.Actor{
	OnCommand=function(self)
		-- this SL[pn].Stages.Stats subtable was initialized in ./BGAnimations/ScreenGameplay overlay/default.lua
		-- One new table like this gets appended to SL[pn].Stages.Stats, indexed by stage number, to store
		-- lots of information (like below) so that it can persist between screens.
		--
		-- Here, we are storing things like letter grade, percent score, judgment counts, stepchart difficulty, etc.
		-- so that we can more easily display it on ScreenEvaluationSummary when this game cycle ends.
		local storage = SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1]

		-- a PLayerStageStats object from the engine
		-- see: http://quietly-turning.github.io/Lua-For-SM5/LuaAPI#Actors-PlayerStageStats
		local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

		storage.grade = "Grade_Tier0"..(stats:GetGrade()) -- bypass built in grade
		storage.cleartype = stats:GetClearType()
		storage.score = pss:GetPercentDancePoints()
		storage.itg = SL[pn].ActiveModifiers.SimulateITGEnv
		storage.faplus = SL[pn].ActiveModifiers.FAPlus

		-- fa+ count
		storage.fapluscount = 0
		if storage.faplus == 0.010 or storage.faplus == 0.0125 then
			storage.fapluscount = (storage.faplus == 0.010) and WF.FAPlusCount[pnum][1] or WF.FAPlusCount[pnum][2]
		elseif storage.faplus == 0.015 then
			storage.fapluscount = pss:GetTapNoteScores(TNSTypes[1])
		end
		
		storage.judgments = {
			W1 = pss:GetTapNoteScores(TNSTypes[1]),
			W2 = pss:GetTapNoteScores(TNSTypes[2]),
			W3 = pss:GetTapNoteScores(TNSTypes[3]),
			W4 = pss:GetTapNoteScores(TNSTypes[4]),
			W5 = pss:GetTapNoteScores(TNSTypes[5]),
			Miss = pss:GetTapNoteScores(TNSTypes[6])
		}

		-- itg specific stuff (store separately, because eventually we'd like to be able to switch them per row)
		storage.score_itg = WF.ITGScore[pnum]
		local itggrade = WF.ITGFailed[pnum] and "Failed" or "Tier"..(WF.GetITGGrade(WF.ITGScore[pnum]))
		storage.grade_itg = "ITGGrade_"..itggrade
		storage.judgments_itg = {
			W1 = WF.ITGJudgmentCounts[pnum][1],
			W2 = WF.ITGJudgmentCounts[pnum][2],
			W3 = WF.ITGJudgmentCounts[pnum][3],
			W4 = WF.ITGJudgmentCounts[pnum][4],
			W5 = WF.ITGJudgmentCounts[pnum][5],
			Miss = WF.ITGJudgmentCounts[pnum][6]
		}

		if GAMESTATE:IsCourseMode() then
			storage.steps      = GAMESTATE:GetCurrentTrail(player)
			storage.difficulty = storage.steps:GetDifficulty()
			storage.meter      = storage.steps:GetMeter()
			storage.stepartist = GAMESTATE:GetCurrentCourse(player):GetScripter()

		else
			storage.steps      = GAMESTATE:GetCurrentSteps(player)
			storage.difficulty = pss:GetPlayedSteps()[1]:GetDifficulty()
			storage.meter      = pss:GetPlayedSteps()[1]:GetMeter()
			storage.stepartist = pss:GetPlayedSteps()[1]:GetAuthorCredit()

		end

		storage.credittable = GetStepsCredit(player)
	end
}