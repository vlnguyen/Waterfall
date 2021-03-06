-- The code here is only half of what's needed for this screen's ScreenShot animation.
--
-- The texture that is loaded into this Sprite actor is created via an
-- ActorFrameTexture in ./BGAnimations/ScreenEvaluationStage background.lua
--
-- The AFT there contains an ActorProxy of the entire Screen object, which listens
-- for "ScreenshotCurrentScreen" to be broadcast via MESSAGEMAN.  When that message is
-- broadcast from this file, the ActorProxy there queues a command causing the AFT
-- to become visible for a moment, render, and then go back to being not-drawn.
--
-- Even though the AFT is no longer drawing to the screen, its rendered texture is still
-- in memory.  We put a reference to that texture in the global SL table, so that we can
-- then retrieve it here, assign it to this Sprite, and tween it to the bottom of the screen.

local player = nil
local saveddf = {false, false} -- whether detailed file has manually been saved already

return Def.Sprite{
	InitCommand=function(self) self:draworder(200) end,

	-- this message is now sent from an input handler
	TakeScreenshotMessageCommand=function(self, params)
		-- organize Screenshots take using this theme into directories, like...
		-- ./Screenshots/Waterfall/2015/06-June/2015-06-05_121708.png
		local prefix = "Waterfall/" .. Year() .. "/"
		prefix = prefix .. string.format("%02d", tostring(MonthOfYear()+1)) .. "-" .. THEME:GetString("Months", "Month"..MonthOfYear()+1) .. "/"

		local success, path = SaveScreenshot(params.PlayerNumber, false, true, prefix)
		if success then
			player = params.PlayerNumber

			MESSAGEMAN:Broadcast("ScreenshotCurrentScreen")
		end

		-- the first time the screenshot button is pressed per player, save a detailed high score file
		-- with a more easily recognizable file name under a special directory, so that you can analyze any
		-- run if you want to
		local pn = tonumber(params.PlayerNumber:sub(-1))
		if (not GAMESTATE:IsCourseMode()) and GAMESTATE:IsHumanPlayer(params.PlayerNumber)
		and (not saveddf[pn]) then
			MESSAGEMAN:Broadcast("WriteDetailed", params)
		end
	end,
	DelayAndScreenshotMessageCommand = function(self, params)
		player = params.PlayerNumber
		self:sleep(0.05):queuecommand("ScreenshotAfterDelay")
	end,
	ScreenshotAfterDelayCommand = function(self)
		local prefix = "Waterfall/" .. Year() .. "/"
		prefix = prefix .. string.format("%02d", tostring(MonthOfYear()+1)) .. "-" .. THEME:GetString("Months", "Month"..MonthOfYear()+1) .. "/"

		local success, path = SaveScreenshot(player, false, true, prefix)
		if success then
			MESSAGEMAN:Broadcast("ScreenshotCurrentScreen")
		end
	end,
	WriteDetailedMessageCommand = function(self, params)
		local pn = tonumber(params.PlayerNumber:sub(-1))
		if saveddf[pn] then SM("\nDetailed stats already saved!\n") return end
		local songtitle = (GAMESTATE:GetCurrentSong():GetDisplayMainTitle():gsub("[^A-Z^a-z^0-9]", ""))
		if (not songtitle) or (songtitle == "") then
			songtitle = (GAMESTATE:GetCurrentSong():GetTranslitMainTitle():gsub("[^A-Z^a-z^0-9]", ""))
		end
		if (not songtitle) or (songtitle == "") then songtitle = "UnknownSong" end
		local diff = THEME:GetString("Difficulty",
			ToEnumShortString(GAMESTATE:GetCurrentSteps(params.PlayerNumber):GetDifficulty()))
		local datestr = (WF.DateTimeString():gsub(":", ""):gsub(" ", "_"))
		local fname = "/saved/"..songtitle.."_"..diff.."_"..datestr
		if WF.WriteDetailedHighScoreStats(pn, nil, nil, fname) then
			SM("\nSaved detailed stats for Player "..pn.."\n")
		else
			SM("\nError writing detailed stats for Player"..pn.."!\n")
		end
		if not GAMESTATE:IsCourseMode() then
			WF.MenuSelections[pn][2][2] = false
		end
		saveddf[pn] = true
	end,
	WriteUpscoresDetailedMessageCommand = function(self, params)
		local pn = tonumber(params.PlayerNumber:sub(-1))
		local wfcount = WF.WriteDetailedHighScoreStatsFromCourseList(pn, nil, params.Data.WF)
		local itgcount = WF.WriteDetailedHighScoreStatsFromCourseList(pn, "_ITG", params.Data.ITG)
		if (wfcount > 0 or itgcount > 0) then
			SM("Saved upscore stats for Player "..pn)
		else
			SM("No upscores found...")
		end
		WF.MenuSelections[pn][2][2] = false
	end,
	WriteAllDetailedMessageCommand = function(self, params)
		local pn = tonumber(params.PlayerNumber:sub(-1))
		local total = WF.WriteAllDetailedHighScoresForCourse(pn, params.Data.WF, params.Data.ITG)
		if total > 0 then
			SM("Saved all detailed stats for Player "..pn)
		else
			SM("Error: no detailed stats were saved...")
		end
		WF.MenuSelections[pn][2][2] = false
		WF.MenuSelections[pn][3][2] = false
	end,


	AnimateScreenshotCommand=function(self)
		-- (re)set these upon attempting to take a screenshot since we can
		-- reuse this same sprite for multiple screenshot animations
		self:finishtweening()
		self:Center():zoomto(_screen.w, _screen.h)
		self:SetTexture(SL.Global.ScreenshotTexture)

		-- shrink it
		self:zoom(0.2)

		-- make it blink to to draw attention to it
		self:glowshift():effectperiod(0.5)
		self:effectcolor1(1,1,1,0)
		self:effectcolor2(1,1,1,0.2)

		-- sleep with it blinking in the center of the screen for 0.5 seconds
		self:sleep(0.4)

		if player and PROFILEMAN:IsPersistentProfile(player) then
			-- tween to the player's bottom corner
			local x_target = player==PLAYER_1 and 20 or _screen.w-20
			self:smooth(0.75):xy(x_target, _screen.h+10):zoom(0)
		else
			SM(THEME:GetString("ScreenEvaluation", "MachineProfileScreenshot"))
			-- tween directly down
			self:sleep(0.25)
			self:smooth(0.75):y(_screen.h+10):zoom(0)
		end

		player = nil
	end
}
