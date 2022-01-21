WF.RPGData = {}
if not IsServiceAllowed(SL.GrooveStats.AutoSubmit) then return end

local NumEntries = 10

local SetEntryText = function(rank, name, score, date, actor)
	if actor == nil then return end

	actor:GetChild("Rank"):settext(rank)
	actor:GetChild("Name"):settext(name)
	actor:GetChild("Score"):settext(score)
	actor:GetChild("Date"):settext(date)
end

local AutoSubmitRequestProcessor = function(res, overlay)
	local hasRpg = false
	local showRpg = false
	local rpgname
	local shownotif = {false, false}
	local wrplr = 0
	
	if (res ~= nil) and res["status"] == "success" then
		for i = 1, 2 do
			local playerStr = "player"..i
			local data = res["data"]

			if data and data[playerStr] then
				local steps = GAMESTATE:GetCurrentSteps("PlayerNumber_P"..i)
				local loweraf = overlay:GetChild("P"..i.."_AF_Lower")
				local loweraf2 = overlay:GetChild("P"..i.."_AF_Lower2")
				if HashCacheEntry(steps) == data[playerStr]["chartHash"] then
					-- show notification based on result
					if data[playerStr]["result"] == "score-added" or data[playerStr]["result"] == "improved"
					or data[playerStr]["result"] == "score-not-improved"
					or data[playerStr]["result"] == "score-improved" then
						shownotif[i] = true

						-- set qr panes to "already submitted"
						if loweraf:GetChild("GSQR") then
							loweraf:GetChild("GSQR"):playcommand("SetAlreadySubmitted")
						end
						if loweraf2 and loweraf2:GetChild("GSQR2") then
							loweraf2:GetChild("GSQR2"):playcommand("SetAlreadySubmitted")
						end
					elseif not data[playerStr]["isRanked"] then
						-- set qr panes to "not ranked"
						if loweraf:GetChild("GSQR") then
							loweraf:GetChild("GSQR"):playcommand("SetNotRanked")
						end
						if loweraf2 and loweraf2:GetChild("GSQR2") then
							loweraf2:GetChild("GSQR2"):playcommand("SetNotRanked")
						end
					end

					if data[playerStr]["gsLeaderboard"] then
						-- call command for gs leaderboard panes to show
						if loweraf:GetChild("GSLeaderboard") then
							loweraf:GetChild("GSLeaderboard"):playcommand("AddGSLeaderboard",
								data[playerStr]["gsLeaderboard"])
						end
						if loweraf2 and loweraf2:GetChild("GSLeaderboard2") then
							loweraf2:GetChild("GSLeaderboard2"):playcommand("AddGSLeaderboard",
								data[playerStr]["gsLeaderboard"])
						end

						-- wr stuff
						if data[playerStr]["result"] ~= "score-not-improved" then
							for gsEntry in ivalues(data[playerStr]["gsLeaderboard"]) do
								if gsEntry["isSelf"] and gsEntry["rank"] == 1 then
									-- in the event both leaderboards return a self rank of 1, player 2 is
									-- more "up to date" so just take the highest player that received it
									wrplr = i
									break
								end
							end
						end
					end

					if data[playerStr]["rpg"] then
						hasRpg = true
						rpgname = data[playerStr]["rpg"]["name"]
						WF.RPGData[i] = data[playerStr]["rpg"]

						-- add option to L+R menu
						table.insert(WF.MenuSelections[i], 
						{ "View RPG stats", true })
						overlay:GetChild("MenuOverlay"):queuecommand("Update")

						-- if itg mode, set showrpg flag
						if SL["P"..i].ActiveModifiers.SimulateITGEnv then
							showRpg = true
						end
					end
				end
			end
		end

		-- now do one more loop to show the proper notifications
		for i = 1, 2 do
			-- set shownotif to false if player got wr, and broadcast wr message
			if wrplr == i then
				shownotif[i] = false
				MESSAGEMAN:Broadcast("GSWorldRecord", {player = "PlayerNumber_P"..i})
			end

			if shownotif[i] then
				local notifarg = ((hasRpg) and (not showRpg))
				overlay:GetChild("P"..i.."_AF_Upper"):GetChild("GSNotification")
					:playcommand("SetSuccess", {notifarg, rpgname})
			end

			if showRpg then
				local rpgAf = overlay:GetChild("AutoSubmitMaster"):GetChild("RpgOverlay")
					:GetChild("P"..i.."RpgAf")
				if rpgAf and res["data"]["player"..i] and res["data"]["player"..i]["rpg"] then
					rpgAf:playcommand("Show", {data=res["data"]["player"..i]["rpg"]})
				end
			end
		end

		-- finally, if we determined to show rpg automatically, do that now
		if showRpg then
			overlay:GetChild("AutoSubmitMaster"):GetChild("RpgOverlay"):visible(true)
			overlay:queuecommand("DirectInputToRpgHandler")
		end
	else
		-- just signal fail for active players that tried to submit
		for i = 1, 2 do
			if SL["P"..i].ApiKey ~= "" then
				overlay:GetChild("P"..i.."_AF_Upper"):GetChild("GSNotification"):playcommand("SetFail")
				return
			end
		end
	end
end

local CreateCommentString = function(player)
	local pn = ToEnumShortString(player)
	local pnum = tonumber(player:sub(-1))

	-- various conditions determine what windows are "enabled" or modified for itg.
	-- tap note string is in the format f,e,g,d,w,m
	-- if a window is disabled, replace it with an x. if truncated, add a *.
	local taps = {}
	for i = 1, 6 do
		table.insert(taps, tostring(WF.ITGJudgmentCounts[pnum][i]))
	end
	local unknownw5 = false
	if not SL.Global.ActiveModifiers.TimingWindows[5] then
		-- disabled option. add * to g, replace d and w with x
		taps[3] = taps[3].."*"
		taps[4] = "x"
		taps[5] = "x"
	elseif math.abs(0.160 - PREFSMAN:GetPreference("TimingWindowSecondsW5")) < 0.001 then
		-- default option. replace d with x, add * to w
		taps[4] = "x"
		taps[5] = taps[5].."*"
	elseif not (math.abs(0.1815 - PREFSMAN:GetPreference("TimingWindowSecondsW5")) < 0.001) then
		-- not really sure, but add ** to the whole string
		unknownw5 = true
	end
	
	local comment = table.concat(taps, ",")
	if unknownw5 then comment = comment.."**" end

	-- add held count
	local h = WF.ITGJudgmentCounts[pnum][7]
	comment = string.format("%s; %d Held", comment, h)

	-- if mines hit > 0, add mine count to string
	local m = WF.ITGJudgmentCounts[pnum][9]
	if m > 0 then
		comment = string.format("%s; %d Mines", comment, m)
	end

	-- add fa+ counts
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
	local fa10 = WF.FAPlusCount[pnum][1]
	local fa15 = pss:GetTapNoteScores("TapNoteScore_W1") -- w1 is 15ms count
	comment = string.format("%s; 10ms: %d; 15ms: %d", comment, fa10, fa15)

	-- if significant cmod used, add cmod to the end
	local smods = GetSignificantMods(player)
	if (smods) and FindInTable("C", smods) then
		comment = comment.."; C-mod"
	end

	-- if every one of these numbers was 6 digits we would have a 103 character string.
	-- the limit for gs is 150 characters, so this seems fine.
	-- but on the weird off chance this happens to be even longer (??) just substring it
	comment = comment:sub(1, 150)

	return comment
end

local af = Def.ActorFrame {
	Name="AutoSubmitMaster",
	RequestResponseActor("AutoSubmit", 10)..{
		OnCommand=function(self)
			local sendRequest = false
			local data = {
				action="groovestats/score-submit",
				maxLeaderboardResults=NumEntries,
			}

			local rate = SL.Global.ActiveModifiers.MusicRate * 100
			for i=1,2 do
				local player = "PlayerNumber_P"..i
				local pn = ToEnumShortString(player)

				local _, valid = ValidForGrooveStats(player)
				local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

				if GAMESTATE:IsHumanPlayer(player) and
						not WF.ITGFailed[i] and
						valid and
						SL[pn].IsPadPlayer then
					local percentDP = stats:GetPercentDancePoints()
					local score = tonumber((WF.ITGScore[i]:gsub("%.", "")))

					local profileName = ""
					if PROFILEMAN:IsPersistentProfile(player) and PROFILEMAN:GetProfile(player) then
						profileName = PROFILEMAN:GetProfile(player):GetDisplayName()
					end

					local steps = GAMESTATE:GetCurrentSteps(player)
					local hash = HashCacheEntry(steps)
					
					if (SL[pn].ApiKey ~= "") and (hash) and (hash ~= "") then
						data["player"..i] = {
							chartHash=hash,
							apiKey=SL[pn].ApiKey,
							rate=rate,
							score=score,
							comment=CreateCommentString(player),
							profileName=profileName,
						}
						sendRequest = true
					end
				end
			end
			-- Only send the request if it's applicable.
			if sendRequest then
				MESSAGEMAN:Broadcast("AutoSubmit", {
					data=data,
					args=SCREENMAN:GetTopScreen():GetChild("Overlay"):GetChild("ScreenEval Common"),
					callback=AutoSubmitRequestProcessor
				})
			end
		end
	}
}

af[#af+1] = LoadActor("./RpgOverlay.lua")

return af