-- the height of the footer is defined in ./Graphics/_footer.lua, but we'll
-- use it here when calculating where to position the PaneDisplay
local footer_height = 32

-- height of the PaneDisplay in pixels
local pane_height = 60

local text_zoom = WideScale(0.8, 0.9)

-- use this to suppress responses that can come back after the song/chart scrolled away
local chartchanged = false

-- -----------------------------------------------------------------------
-- Convenience function to return the SongOrCourse and StepsOrTrail for a
-- for a player.
local GetSongAndSteps = function(player)
	local SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
	local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
	return SongOrCourse, StepsOrTrail
end

-- function to determine for some player ("P1"/"P2") whether the actors should be overridden by groovestats
local UseGSScore = function(pn)
	return (IsServiceAllowed(SL.GrooveStats.GetScores)) and (SL[pn].ApiKey ~= "")
	and (SL[pn].ActiveModifiers.SimulateITGEnv) and 
	((SL.Global.ActiveModifiers.MusicRate == 1.0) or SL[pn].ActiveModifiers.GSOverride)
end

-- -----------------------------------------------------------------------
-- requires a profile (machine or player) as an argument
-- returns formatted strings for player tag (from ScreenNameEntry) and PercentScore

local GetNameAndScore = function(SongOrCourse, StepsOrTrail, pn, itg)
	-- nil pn means machine score
	-- if we don't have everything we need, return empty strings
	if not (SongOrCourse and StepsOrTrail) then return "","" end
	if (pn) and (not WF.PlayerProfileStats[pn]) then return "","" end

	local score, name, ct, fa10, fa15
	local rate = RateFromNumber(SL.Global.ActiveModifiers.MusicRate)
	local iscourse = (SongOrCourse.GetAllSteps == nil)
	local hash = (not iscourse) and HashCacheEntry(StepsOrTrail)
	local stats = WF.FindProfileSongStatsFromSteps(SongOrCourse, StepsOrTrail,
		rate, hash, pn)

	if stats then
		if pn then
			score = string.format("%0.2f", ((not itg) and stats.BestPercentDP or stats.BestPercentDP_ITG)/100)
			name = "PB"
			fa10 = stats.BestFAPlusCounts[1]
			fa15 = stats.BestFAPlusCounts[3]
			if not itg then
				ct = stats.BestClearType
			else
				if stats.Cleared_ITG then ct = (stats.Cleared_ITG == "C") and WF.ClearTypes.Clear or WF.ClearTypes.Fail
				else ct = WF.ClearTypes.None end
			end
		else
			local item = stats["HighScoreList"..(itg and "_ITG" or "")][1]
			if item then
				score = string.format("%0.2f", item.PercentDP/100)
				name = item.PlayerHSName
			else
				score = "0.00"
				name = "----"
			end
		end
	else
		score = "0.00"
		name = "----"
	end

	return score, name, ct, fa10, fa15
end

-- -----------------------------------------------------------------------
local SetNameAndScore = function(name, score, nameActor, scoreActor)
	if not scoreActor or not nameActor then return end
	scoreActor:settext(score)
	nameActor:settext(name)
end
local SetClearType = function(ct, cttext)
	if (not ct) or ct == WF.ClearTypes.None then
		cttext:settext("None"):diffuse(Color.White)
	else
		cttext:settext(WF.ClearTypes[ct]):diffuse(WF.ClearTypeColor(ct))
	end
end

local GetMachineTag = function(gsEntry)
	if not gsEntry then return end
	if gsEntry["machineTag"] then
		-- Make sure we only use up to 5 characters for space concerns.
		return gsEntry["machineTag"]:sub(1, 5):upper()
	end

	-- User doesn't have a machineTag set. We'll "make" one based off of
	-- their name.
	if gsEntry["name"] then
		-- 4 Characters is the "intended" length.
		-- i feel like i can get away with 5 or 6
		return gsEntry["name"]:sub(1,5):upper()
	end

	return ""
end

local GetScoresRequestProcessor = function(res, master)
	if master == nil then return end
	-- If we're not hovering over a song when we get the request, then we don't
	-- have to update anything. We don't have to worry about courses here since
	-- we don't run the RequestResponseActor in CourseMode.
	local song = GAMESTATE:GetCurrentSong()
	if song == nil then return end
	if chartchanged then return end

	for i=1,2 do
		local steps = GAMESTATE:GetCurrentSteps("PlayerNumber_P"..i)

		local paneDisplay = master:GetChild("PaneDisplayP"..i)

		local machineScore = paneDisplay:GetChild("MachineHighScore")
		local machineName = paneDisplay:GetChild("MachineHighScoreName")

		local playerScore = paneDisplay:GetChild("PlayerHighScore")
		local playerName = paneDisplay:GetChild("PlayerHighScoreName")
		local cttext = paneDisplay:GetChild("CTText")

		local playerStr = "player"..i
		local rivalNum = 1
		local worldRecordSet = false
		local personalRecordSet = false
		local data = ((res ~= nil) and res["status"] == "success") and res["data"] or nil

		-- First check to see if the leaderboard even exists.
		if data and data[playerStr] and data[playerStr]["gsLeaderboard"] then
			-- And then also ensure that the chart hash matches the currently parsed one.
			-- It's better to just not display anything than display the wrong scores.
			-- also don't bother doing this stuff if player isn't on itg mode.
			-- finally, we don't want to set these if on a rate mod and the preference to override is off.
			if (HashCacheEntry(steps) == data[playerStr]["chartHash"])
			and SL["P"..i].ActiveModifiers.SimulateITGEnv
			and ((SL.Global.ActiveModifiers.MusicRate == 1.0) or SL["P"..i].ActiveModifiers.GSOverride) then
				for gsEntry in ivalues(data[playerStr]["gsLeaderboard"]) do
					if gsEntry["rank"] == 1 then
						SetNameAndScore(
							GetMachineTag(gsEntry),
							string.format("%0.2f", gsEntry["score"]/100),
							machineName,
							machineScore
						)
						worldRecordSet = true
					end

					if gsEntry["isSelf"] then
						-- we can update the local player score if the gs score is higher :)
						-- see WF-Profiles.lua for all the logic considered here
						WF.PullITGScoreFromGrooveStats(i, data[playerStr]["chartHash"], gsEntry)

						-- compare score to local first
						local rate = RateFromNumber(SL.Global.ActiveModifiers.MusicRate)
						local stats = WF.FindProfileSongStatsFromSteps(song, steps,
							rate, HashCacheEntry(steps), i)

						local usegspr = true
						if (stats) and (stats.BestPercentDP_ITG > gsEntry["score"]) then
							usegspr = false
						end

						local ct = WF.ClearTypes.None
						if usegspr then
							SetNameAndScore(
								"PB",
								string.format("%0.2f", gsEntry["score"]/100),
								playerName,
								playerScore
							)
							ct = (gsEntry["isFail"]) and WF.ClearTypes.Fail or WF.ClearTypes.Clear
						else
							SetNameAndScore(
								"LOCAL",
								string.format("%0.2f", stats.BestPercentDP_ITG/100),
								playerName,
								playerScore
							)
							ct = (stats.Cleared_ITG == "F") and WF.ClearTypes.Fail or WF.ClearTypes.Clear
						end
						SetClearType(ct, cttext)
						personalRecordSet = true
					end

					if gsEntry["isRival"] then
						local rivalScore = paneDisplay:GetChild("Rival"..rivalNum.."Score")
						local rivalName = paneDisplay:GetChild("Rival"..rivalNum.."Name")
						SetNameAndScore(
							GetMachineTag(gsEntry),
							string.format("%0.2f", gsEntry["score"]/100),
							rivalName,
							rivalScore
						)
						rivalNum = rivalNum + 1
					end
				end
			end
		end

		-- Fall back to to using the machine profile's record if we never set the world record.
		-- This chart may not have been ranked, or there is no WR, or the request failed.
		if not worldRecordSet then
			machineName:queuecommand("SetDefault")
		end

		-- Fall back to to using the personal profile's record if we never set the record.
		-- This chart may not have been ranked, or we don't have a score for it, or the request failed.
		if not personalRecordSet then
			playerName:queuecommand("SetDefault")
		end

		-- Iterate over any remaining rivals and hide them.
		-- This also handles the failure case as rivalNum will never have been incremented.
		-- Only do tihs if expected to use gs in the first place
		if UseGSScore("P"..i) then
			for j=rivalNum,3 do
				local rivalScore = paneDisplay:GetChild("Rival"..j.."Score")
				local rivalName = paneDisplay:GetChild("Rival"..j.."Name")
				rivalScore:settext("----")
				rivalName:settext("----")
			end
		end
	end
end

-- -----------------------------------------------------------------------
-- define the x positions of four columns, and the y positions of three rows of PaneItems
local pos = {
	col = { WideScale(-104,-133), WideScale(-36,-38), WideScale(54,76), WideScale(150, 190) },
	row = { 13, 31, 49 }
}

local num_rows = 3
local num_cols = 2

-- HighScores handled as special cases for now until further refactoring
local PaneItems = {
	-- first row
	{ name=THEME:GetString("RadarCategory","Taps"),  rc='RadarCategory_TapsAndHolds'},
	{ name=THEME:GetString("RadarCategory","Mines"), rc='RadarCategory_Mines'},
	-- { name=THEME:GetString("ScreenSelectMusic","NPS") },

	-- second row
	{ name=THEME:GetString("RadarCategory","Jumps"), rc='RadarCategory_Jumps'},
	{ name=THEME:GetString("RadarCategory","Hands"), rc='RadarCategory_Hands'},
	-- { name=THEME:GetString("RadarCategory","Lifts"), rc='RadarCategory_Lifts'},

	-- third row
	{ name=THEME:GetString("RadarCategory","Holds"), rc='RadarCategory_Holds'},
	{ name=THEME:GetString("RadarCategory","Rolls"), rc='RadarCategory_Rolls'},
	-- { name=THEME:GetString("RadarCategory","Fakes"), rc='RadarCategory_Fakes'},
}

-- -----------------------------------------------------------------------
local af = Def.ActorFrame{ Name="PaneDisplayMaster" }

af.OnCommand = function(self)									self:playcommand("Set") end
af.CurrentCourseChangedMessageCommand=function(self)			self:playcommand("Set") end
af.CurrentSongChangedMessageCommand=function(self)				self:playcommand("Set") end
af.CurrentStepsP1ChangedMessageCommand=function(self) self:playcommand("Set") end
af.CurrentStepsP2ChangedMessageCommand=function(self) self:playcommand("Set") end
af.CurrentTrailP1ChangedMessageCommand=function(self) self:playcommand("Set") end
af.CurrentTrailP2ChangedMessageCommand=function(self) self:playcommand("Set") end

af.SetCommand = function(self)
	-- do a little delay, then call CheckScores command
	chartchanged = true
	self:stoptweening():sleep(0.5):queuecommand("CheckScores")
end

af[#af+1] = RequestResponseActor("GetScores", 10)..{
	OnCommand=function(self)
		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			-- If a profile is joined for this player, try and fetch the API key.
			-- A non-valid API key will have the field set to the empty string.
			if PROFILEMAN:GetProfile(player) then
				ParseGrooveStatsIni(player)
			end
		end
	end,
	PlayerJoinedMessageCommand=function(self, params)
		if GAMESTATE:IsHumanPlayer(params.Player) and PROFILEMAN:GetProfile(params.Player) then
			ParseGrooveStatsIni(params.Player)
		end
	end,
	CheckScoresCommand=function(self)
		chartchanged = false
		if not (GAMESTATE:GetCurrentSong() or GAMESTATE:GetCurrentCourse()) then return end

		-- signal everything to set default for any of these exit conditions
		local defaultall = false
		if GAMESTATE:IsCourseMode() then defaultall = true end
		if not IsServiceAllowed(SL.GrooveStats.GetScores) then defaultall = true end
		if not (SL.P1.ActiveModifiers.SimulateITGEnv or SL.P2.ActiveModifiers.SimulateITGEnv) then
			defaultall = true
		end
		if not (SL.Global.ActiveModifiers.MusicRate == 1.0 or (SL.P1.ActiveModifiers.GSOverride or 
			SL.P2.ActiveModifiers.GSOverride)) then defaultall = true end

		if defaultall then
			self:GetParent():playcommand("SetDefault")
			return
		end

		-- Get hash for current steps from the Hash Cache #HashCash.
		local sendRequest = false
		local data = {
			action="groovestats/player-scores",
		}

		for i=1,2 do
			local pn = "P"..i
			local steps = GAMESTATE:GetCurrentSteps("PlayerNumber_P"..i)
			local hash = steps and HashCacheEntry(GAMESTATE:GetCurrentSteps("PlayerNumber_P"..i))
			local pane = SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("PaneDisplayMaster")
				:GetChild("PaneDisplayP"..i)
			if (SL[pn].ApiKey ~= "") and hash then
				data["player"..i] = {
					chartHash=hash,
					apiKey=SL[pn].ApiKey
				}
				if UseGSScore(pn) then pane:playcommand("SetLoading") end
				sendRequest = true
			end
			if not UseGSScore(pn) then pane:playcommand("SetDefault") end
		end

		-- Only send the request if it's applicable.
		if sendRequest then
			MESSAGEMAN:Broadcast("GetScores", {
				data=data,
				args=SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("PaneDisplayMaster"),
				callback=GetScoresRequestProcessor
			})
		end
	end,

}

for player in ivalues(PlayerNumber) do
	local pn = ToEnumShortString(player)
	local pnum = tonumber(player:sub(-1))
	
	local itg = SL[pn].ActiveModifiers.SimulateITGEnv

	af[#af+1] = Def.ActorFrame{ Name="PaneDisplay"..ToEnumShortString(player) }

	local af2 = af[#af]

	af2.InitCommand=function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))

		if player == PLAYER_1 then
			self:x(_screen.w * 0.25 - 5)
		elseif player == PLAYER_2 then
			self:x(_screen.w * 0.75 + 5)
		end

		self:y(_screen.h - footer_height - pane_height)
	end

	af2.PlayerJoinedMessageCommand=function(self, params)
		if player==params.Player then
			-- ensure BackgroundQuad is colored before it is made visible
			self:GetChild("BackgroundQuad"):playcommand("Set")
			self:visible(true)
				:zoom(0):croptop(0):bounceend(0.3):zoom(1)
				:playcommand("Update")
		end
	end
	-- player unjoining is not currently possible in SL, but maybe someday
	af2.PlayerUnjoinedMessageCommand=function(self, params)
		if player==params.Player then
			self:accelerate(0.3):croptop(1):sleep(0.01):zoom(0):queuecommand("Hide")
		end
	end
	af2.HideCommand=function(self) self:visible(false) end

	-- -----------------------------------------------------------------------
	-- colored background Quad

	af2[#af2+1] = Def.Quad{
		Name="BackgroundQuad",
		InitCommand=function(self)
			self:zoomtowidth(_screen.w/2-10)
			self:zoomtoheight(pane_height)
			self:vertalign(top)
			self:diffuse(PlayerColor(player))
		end
	}

	-- -----------------------------------------------------------------------
	-- loop through the six sub-tables in the PaneItems table
	-- add one BitmapText as the label and one BitmapText as the value for each PaneItem

	for i, item in ipairs(PaneItems) do

		local col = ((i-1)%num_cols) + 1
		local row = math.floor((i-1)/num_cols) + 1

		af2[#af2+1] = Def.ActorFrame{

			Name=item.name,

			-- numerical value
			LoadFont("Common Normal")..{
				InitCommand=function(self)
					self:zoom(text_zoom):diffuse(Color.Black):horizalign(right)
					self:x(pos.col[col])
					self:y(pos.row[row])
				end,

				SetCommand=function(self)
					local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
					if not SongOrCourse then self:settext("?"); return end
					if not StepsOrTrail then self:settext("");  return end

					if item.rc then
						local val = StepsOrTrail:GetRadarValues(player):GetValue( item.rc )
						-- the engine will return -1 as the value for autogenerated content; show a question mark instead if so
						self:settext( val >= 0 and val or "?" )
					end
				end
			},

			-- label
			LoadFont("Common Normal")..{
				Text=item.name,
				InitCommand=function(self)
					self:zoom(text_zoom):diffuse(Color.Black):horizalign(left)
					self:x(pos.col[col]+3)
					self:y(pos.row[row])
				end
			},
		}
	end

	-- Machine/World Record Machine Tag
	af2[#af2+1] = LoadFont("Common Normal")..{
		Name="MachineHighScoreName",
		InitCommand=function(self)
			self:zoom(text_zoom):diffuse(Color.Black):maxwidth(30)
			self:x(pos.col[3]-50*text_zoom)
			self:y(pos.row[1])
		end,
		SetCommand=function(self)
			-- just set blank, this is controlled elsewhere
			self:settext("----")
		end,
		SetLoadingCommand = function(self) self:settext(". . .") end,
		SetDefaultCommand=function(self)
			local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
			local machine_score, machine_name = GetNameAndScore(SongOrCourse, StepsOrTrail, nil, itg)
			self:settext(machine_name or ""):diffuse(Color.Black)
			DiffuseEmojis(self)
			self:GetParent():GetChild("MachineHighScore"):settext(machine_score or ""):diffuse(Color.Black)
		end
	}

	-- Machine/World Record HighScore
	af2[#af2+1] = LoadFont("Common Normal")..{
		Name="MachineHighScore",
		InitCommand=function(self)
			self:zoom(text_zoom):diffuse(Color.Black):horizalign(right)
			self:x(pos.col[3]+20*text_zoom)
			self:y(pos.row[1])
		end,
		SetCommand=function(self)
			self:settext("----")
		end,
		SetLoadingCommand = function(self) self:settext(". . .") end
	}

	-- Player Profile/GrooveStats Machine Tag  ("PB" text in my case)
	af2[#af2+1] = LoadFont("Common Normal")..{
		Name="PlayerHighScoreName",
		Text = "PB",
		InitCommand=function(self)
			self:zoom(text_zoom):diffuse(Color.Black):maxwidth(30)
			self:x(pos.col[3]-50*text_zoom)
			self:y(pos.row[2])
			if not PROFILEMAN:IsPersistentProfile(player) then self:visible(false) end
		end,
		SetCommand = function(self) self:settext("PB") end,
		SetDefaultCommand=function(self)
			local SongOrCourse, StepsOrTrail = GetSongAndSteps(player)
			local player_score, player_name, ct, fa10, fa15
			if UseGSScore(pn) then self:settext("LOCAL") end
			if PROFILEMAN:IsPersistentProfile(player) then
				player_score, player_name, ct, fa10, fa15 = 
					GetNameAndScore(SongOrCourse, StepsOrTrail, pnum, itg)
			else
				self:visible(false)
			end
			self:GetParent():GetChild("PlayerHighScore"):settext(player_score or "")
			SetClearType(ct, self:GetParent():GetChild("CTText"))
			if (not UseGSScore(pn)) and WF.PlayerProfileStats[pnum] then
				local song, steps = GetSongAndSteps(player)
				if not steps then return end
				local rvarg = (not GAMESTATE:IsCourseMode()) and player or nil
				local stepcount = steps:GetRadarValues(rvarg):GetValue("RadarCategory_TapsAndHolds")
				local p10, p15
				if stepcount == 0 then p10 = "0.00" p15 = "0.00"
				elseif stepcount < 0 then p10 = "?" p15 = "?"
				else
					p10 = string.format("%0.2f", math.floor(((fa10 or 0)/stepcount)*10000)/100)
					p15 = string.format("%0.2f", math.floor(((fa15 or 0)/stepcount)*10000)/100)
				end
				self:GetParent():GetChild("Rival2Score"):settext(p10)
				self:GetParent():GetChild("Rival3Score"):settext(p15)
			end
		end
	}

	-- Player Profile/GrooveStats HighScore
	af2[#af2+1] = LoadFont("Common Normal")..{
		Name="PlayerHighScore",
		InitCommand=function(self)
			self:zoom(text_zoom):diffuse(Color.Black):horizalign(right)
			self:x(pos.col[3]+20*text_zoom)
			self:y(pos.row[2])
			if not PROFILEMAN:IsPersistentProfile(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			self:settext("----")
		end,
		SetLoadingCommand = function(self) self:settext(". . .") end
	}

	-- ct quad/text
	local quadwidth = (not itg) and WideScale(84, 100) or 72
	af2[#af2+1] = Def.Quad{
		InitCommand = function(self)
			if not WF.PlayerProfileStats[pnum] then self:visible(false) end
			self:x(pos.col[3]-WideScale(18,20)):y(pos.row[3]):zoomto(quadwidth, 18):diffuse(0,0,0,0.9)
		end
	}

	af2[#af2+1] = LoadFont("Common Normal")..{
		Name="CTText",
		Text="",
		InitCommand=function(self)
			if not WF.PlayerProfileStats[pnum] then self:visible(false) end
			self:zoom(text_zoom):diffuse(Color.White)
			self:x(pos.col[3]-WideScale(18,20))
			self:y(pos.row[3])
			self:maxwidth((quadwidth-2)/text_zoom)
		end,
		SetCommand=function(self)
			self:settext("")
		end
	}

	-- Add actors for Rival score data. Hidden by default
	-- We position relative to column 3 for spacing reasons.
	for i=1,3 do
		-- Rival Machine Tag
		af2[#af2+1] = LoadFont("Common Normal")..{
			Name="Rival"..i.."Name",
			InitCommand=function(self)
				self:zoom(text_zoom):diffuse(Color.Black):maxwidth(30)
				self:x(pos.col[3]+WideScale(50, 54)*text_zoom)
				self:y(pos.row[i])
			end,
			OnCommand=function(self)
				--if not ((IsServiceAllowed(SL.GrooveStats.GetScores) and UseGSScore(pn))
				--or ((not itg) and WF.PlayerProfileStats[pnum])) then
				if not WF.PlayerProfileStats[pnum] then
					self:visible(false)
				end
			end,
			SetCommand=function(self)
				-- hijack this to show fa+ if not itg
				if UseGSScore(pn) then
					self:settext("----")
				else
					if i == 1 then self:settext("FA+")
					elseif i == 2 then self:settext("10ms")
					elseif i == 3 then self:settext("15ms") end
				end
			end,
			SetLoadingCommand = function(self) self:settext(". . .") end
		}

		-- Rival HighScore
		af2[#af2+1] = LoadFont("Common Normal")..{
			Name="Rival"..i.."Score",
			InitCommand=function(self)
				self:zoom(text_zoom):diffuse(Color.Black):horizalign(right)
				self:x(pos.col[3]+WideScale(122, 125)*text_zoom)
				self:y(pos.row[i])
			end,
			OnCommand=function(self)
				--if not ((IsServiceAllowed(SL.GrooveStats.GetScores) and UseGSScore(pn))
				--or ((not itg) and WF.PlayerProfileStats[pnum])) then
				if not WF.PlayerProfileStats[pnum] then
					self:visible(false)
				end
				if (not UseGSScore(pn)) and i == 1 then self:visible(false) end
			end,
			SetCommand=function(self)
				self:settext("----")
			end,
			SetLoadingCommand = function(self) self:settext(". . .") end
		}
	end
end

return af