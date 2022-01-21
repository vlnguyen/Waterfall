-- no longer used functions relating to ECFA 2021.
-- Some of this could be useful for future events so I'm just keeping it in here.

ParseTechRadar = function(techRadarString)
	-- ECFA: Parse tech radar string from #CHARTSTYLE into a table.
	-- 
	-- e.g., #CHARTSTYLE:speed=5,stamina=6,tech=7,movement=10,timing=9,gimmick=low;
	if not techRadarString then return nil end

	techRadarTable = {}
	for k, v in string.gmatch(techRadarString, "([^=,]+)=([^=,]+),?") do
		k = string.lower(k)
		v = string.lower(v)
		if k == 'gimmick' then
			v = tonumber(v) or (
				(v == 'cmod') and -1 or
				(v == 'none') and 0 or
				(v == 'low' or v == 'light') and 1 or
				(v == 'mid' or v == 'medium') and 2 or
				(v == 'high' or v == 'heavy') and 3 or nil
			)
			techRadarTable[k] = v
		else
            techRadarTable[k] = tonumber(v)
            if k == "timing" and (not techRadarTable.rhythms) then techRadarTable.rhythms = tonumber(v) end
		end
	end

	return techRadarTable
end

TechRadarFromSteps = function(steps)
    -- pass in a steps and get the tech radar table, including the "rating" field
    local radar = ParseTechRadar(steps:GetChartStyle())
    if not radar then return end
    radar.rating = steps:GetMeter()
    return radar
end

-- Edit these according to ECFA staff's recommendations!
-- NOTE: old system, no longer used
local EasyCoefficientFormulaAsset = {
    rating      = {mult = 2.2, expo = 2.2},
    speed       = {mult = 1.0, expo = 1.1},
    stamina     = {mult = 1.0, expo = 1.1},
    tech        = {mult = 1.5, expo = 1.7},
    movement    = {mult = 1.5, expo = 1.7},
    timing      = {mult = 2.2, expo = 1.7},
    rhythms     = {mult = 2.2, expo = 1.7},
    gimmick     = {1.0, 1.04, 1.08, 1.12}
}

CalculateMaxDP_Unscaled_OLD = function(techRadarTable)
    -- Internal use only!!
    -- Use this to calculate the unscaled maximum DP for a given tech radar.
    -- OLD FORMULA
    local t = techRadarTable
    local c = EasyCoefficientFormulaAsset

    -- Calculate the max DP using the Special Formula(tm).
    return ( 
    (  
        (
            -- Block rating influence
            c.rating.mult   * t.rating      ^ c.rating.expo
        ) + (
            -- Tech features that don't change with cmod
            c.speed.mult    * t.speed       ^ c.speed.expo +
            c.stamina.mult  * t.stamina     ^ c.stamina.expo +
            c.tech.mult     * t.tech        ^ c.tech.expo +
            c.movement.mult * t.movement    ^ c.movement.expo +
            c.rhythms.mult  * t.rhythms     ^ c.rhythms.expo
        )
    ) * (
            -- The gimmick multiplier
            (t.gimmick < 0) and 1.0 or c.gimmick[t.gimmick + 1]
        )
    )
end

local ECFA_ScoreModifiers = {
    scorebase = 40,
    mscale = {
        speed = 1,   --unused
        stamina = 1, --unused
        tech = 3,
        movement = 4,
        rhythms = 6
    },
    gimmick = {1.02, 1.04, 1.06},
    bigscale = 10000,
    exp = 1.75,
    maxs = 404
}
CalculateMaxDP = function(radar)
    local mods = ECFA_ScoreModifiers
    radar.rating = math.min(radar.rating, 14)
    local bmin = math.min(radar.rating/10, 1)

    local S = (mods.scorebase*(radar.rating-7) +
        radar.speed + radar.stamina +
        mods.mscale.tech*bmin*radar.tech + mods.mscale.movement*bmin*radar.movement +
        mods.mscale.rhythms*bmin*radar.rhythms) *
        (radar.gimmick <= 0 and 1 or mods.gimmick[radar.gimmick])

    return mods.bigscale * ((S/mods.maxs) ^ mods.exp)
end

-- Calculate the max DP using the formula above, scaled so that the maximum
-- DP available from any one chart in the event is capped at 1000
-- (i.e. set a 14 that maxes out the radar at 1000)
-- note: this is no longer used
local theAngriestBoi = {
    rating = 14,
    speed = 10,
    stamina = 10,
    tech = 10,
    movement = 10,
    timing = 10,
    rhythms = 10,
    gimmick = 3
}
local theDPScalar = (1 / 0.091313)

CalculateMaxDPByTechRadar = function(techRadarTable)
	-- ECFA: Calculate the maximum DP available for the chart with the
	-- tech radar values in the table provided.
	-- 	
    -- Parse the #CHARTSTYLE: field to get radar values.
    -- e.g., {speed = 5, stamina = 6, tech = 7, movement = 10, timing = 9, gimmick = 0}
	
	if not techRadarTable then return nil end

    local tmpradar = {}
	-- Scan for all required parameters.
	local requiredParams = {'speed', 'stamina', 'tech', 'movement', 'rhythms', 'gimmick', 'rating'}
	for _, v in ipairs(requiredParams) do
		if techRadarTable[v] == nil then
			return nil
        end
        tmpradar[v] = (v ~= "rating") and math.min(techRadarTable[v], 10) or techRadarTable[v]
	end

    -- Calculate the max DP.
    return CalculateMaxDP(tmpradar)
end

SongNameDuringSet = function(self, item)
    self:diffuse(Color.White)
end

SongNameDuringSet_ECFA = function(self, item)
    -- NOTE: For this function to get called at the proper time, the following
    -- lines must be updated in metrics.ini:
    --
    -- [MusicWheelItem]
    -- SongNameSetCommand=%function(self, item) SongNameDuringSet(self, item) end
    
    -- (from original SongNameSetCommand)
	-- hack to recolor song titles back EVERY SetCommand (i.e. a lot)
	self:diffuse(Color.White)

	-- ECFA: Change song title to include the Challenge chart's rating.
    if item.Song then
        -- only do this for songs in an ECFA 2021 folder
        if not item.Song:GetGroupName():find("ECFA 2021") then return end

		-- Grab a list of all steps for the current mode.
		local allSteps = item.Song:GetStepsByStepsType(GAMESTATE:GetCurrentStyle():GetStepsType())

		-- Find the chart occupying the highest non-Edit slot.
		local highestRegularDiff = nil
        local highestRegularChart = nil
        local techRadar
		for _, diff in ipairs({
			'Difficulty_Beginner',
			'Difficulty_Easy',
			'Difficulty_Medium',
			'Difficulty_Hard',
			'Difficulty_Challenge'
		}) do
			for _, step in ipairs(allSteps) do
				techRadar = ParseTechRadar(step:GetChartStyle())
				if (step:GetDifficulty() == diff) and techRadar then
					highestRegularChart = step
					highestRegularDiff = diff
				end
			end
		end
		
		-- Get the block rating / tech max associated with that chart
		-- and append it to the title.
		if highestRegularChart then
			local blockRating = tonumber(highestRegularChart:GetMeter())
            techRadar = ParseTechRadar(highestRegularChart:GetChartStyle())
            if not techRadar then return end
            techRadar.rating = blockRating
            local rawmaxdp = CalculateMaxDPByTechRadar(techRadar)
            if not rawmaxdp then return end
			local techMaxDP = math.floor(rawmaxdp)

			-- Title gets a prepended block rating
			-- Subtitle gets either a Cmod directive, a max DP calculation, or
			-- both, separated by a pipe (e.g. "573 DP | No Cmod")
			local blockRatingString = blockRating and "["..string.format("%02d", blockRating).."] " or ""
			local techMaxDPString   = techMaxDP   and string.format("%d", techMaxDP).." Points" or ""
			local cmodDirective     = (techRadar.gimmick == nil or techRadar.gimmick <= 0) and "" or "No Cmod"
			local subtitleAdd = (techMaxDPString ~= "" and cmodDirective ~= "") and
							(techMaxDPString.." | "..cmodDirective) or
							(techMaxDPString       ..cmodDirective)			

			local fullTitle      = blockRatingString..item.Song:GetDisplayFullTitle()
			local fullTitleTL    = blockRatingString..item.Song:GetTranslitFullTitle()
			local fullSubtitle   = subtitleAdd
			local fullSubtitleTL = subtitleAdd
			--SM("### "..fullTitle)
			self:SetFromString(
				fullTitle, fullTitleTL,
				fullSubtitle, fullSubtitleTL,
				item.Song:GetDisplayArtist(), item.Song:GetTranslitArtist()
			)
		end
	end
end

function IsECFA2021Song()
    -- shorthand for checking if the current song is in an ECFA 2021 folder
    if GAMESTATE:IsCourseMode() then return false end
    local song = GAMESTATE:GetCurrentSong()
    if not song then return false end

    return song:GetGroupName():find("ECFA 2021") and true or false
end

-- functions for calculating the player performance score

ECFA_FAPass = {
    [0]  = 0, --dummy value for handling cases that shouldn't, but could, occur
    [7]  = 0.60,
    [8]  = 0.65,
    [9]  = 0.70,
    [10] = 0.75,
    [11] = 0.80,
    [12] = 0.83,
    [13] = 0.85,
    [14] = 0.86
}

function ECFA2021ScoreWF(player)
    -- function utilizing WF systems that can be called at evaluation simply with a player number
    if not IsECFA2021Song() then return nil end
    local steps = GAMESTATE:GetCurrentSteps(player)
    local radar = TechRadarFromSteps(steps)
    if not radar then return nil end

    if radar.gimmick and radar.gimmick > 0 then
        local smods = GetSignificantMods(player)
        if smods and FindInTable("C", smods) then return nil end
    end

    local maxscore = CalculateMaxDPByTechRadar(radar)
    if not maxscore then return nil end
    local rating = steps:GetMeter()
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
    local perf = pss:GetTapNoteScores("TapNoteScore_W1")
    local exc = pss:GetTapNoteScores("TapNoteScore_W2")
    local mines = pss:GetTapNoteScores("TapNoteScore_HitMine")
    local srv = steps:GetRadarValues(player)
    local stepcount = srv:GetValue("RadarCategory_TapsAndHolds")
    local totalholds = srv:GetValue("RadarCategory_Holds") + srv:GetValue("RadarCategory_Rolls")
    local held = pss:GetHoldNoteScores("HoldNoteScore_Held")
    local nonheld = totalholds - held

    local score, dp = CalculateECFA2021Score(perf, exc, nonheld, mines, stepcount, maxscore, rating)
    -- return score, max score and raw dp%
    return score, maxscore, dp
end

function ECFA2021ScoreSL(player)
    -- similar to the above, but something more tuned to simplay love variants
    -- note that this will still require that either "Experimental" or "Waterfall" game mode is used
    if not IsECFA2021Song() then return nil end
    if not (SL.Global.GameMode == "Experimental" or SL.Global.GameMode == "Waterfall") then return nil end
    local steps = GAMESTATE:GetCurrentSteps(player)
    local radar = TechRadarFromSteps(steps)
    if not radar then return nil end

    if radar.gimmick and radar.gimmick > 0 then
        local mods = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
        if mods and mods:CMod() then return nil end
    end

    local maxscore = CalculateMaxDPByTechRadar(radar)
    local rating = steps:GetMeter()
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
    local perf = pss:GetTapNoteScores("TapNoteScore_W1")
    local exc = pss:GetTapNoteScores("TapNoteScore_W2")
    local mines = pss:GetTapNoteScores("TapNoteScore_HitMine")
    local srv = steps:GetRadarValues(player)
    local stepcount = srv:GetValue("RadarCategory_TapsAndHolds")
    local totalholds = srv:GetValue("RadarCategory_Holds") + srv:GetValue("RadarCategory_Rolls")
    local held = pss:GetHoldNoteScores("HoldNoteScore_Held")
    local nonheld = totalholds - held

    local score, dp = CalculateECFA2021Score(perf, exc, nonheld, mines, stepcount, maxscore, rating)
    -- return score, max score and raw dp%
    return score, maxscore, dp
end

function ECFAPointString(val)
    -- previously this was returning a string in the form of %.2f, but we've decided to only display
    -- integers for aesthetic purposes
    if tostring(val) == tostring(0/0) then val = 0 end
    return tostring(math.floor(val))
end

CalculateECFA2021Score = function(perf, exc, nonheld, mines, stepcount, maxscore, rating)
    -- function to get the score by passing the values in directly
    -- return the raw dp score in addition to the calculated score, because we wantto communicate it
    -- for missing fa pass
    local dp = ECFA_DP(perf, exc, nonheld, mines, stepcount)
    if dp < ECFA_FAPass[rating] then return 0, math.max(0, dp) end
    return maxscore * ECFA_DPExp(dp), dp
end

ECFA_DP = function(perf, exc, nonheld, mines, stepcount)
    return (3*perf + exc - (nonheld + mines))/(3*stepcount)
end

ECFA_DPExp = function(dp)
    return 0.2 + 0.8*(45^(dp-1))
end

-- old unused function
ECFA_Fp = function(dp)
    return 0.446 + (2 * ( 0.054 * (dp-0.5) )) + (ECFA_FExp(dp)/ECFA_FExp(1))/2
end


-- moved from WF-Profiles.lua to remove clutter from that file
--- ECFA 2021 total point calculation stuff ---
mt_ecfa2021item = {
    GetChart = function(self)
        -- self.Song should be "Folder/SongFolder"
        local song = SONGMAN:FindSong(self.Song)
        if not song then return end
        return song:GetStepsByStepsType("StepsType_Dance_Single")[1]
    end,
    SetScore = function(self)
        -- this one needs to be called every time it's inserted into the list, for sorting
        if self.ECFAScore then return end
        self.ECFAScore, self.MaxScore, self.DP = ECFA2021ScoreWF(self.List.Player)
        return self.ECFAScore
    end,
    SetScoreDirect = function(self)
        -- this one doesn't validate cmods, so only use it when loading from files (where the score is already validated)
        local chart = self:GetChart()
        if not chart then return end -- setting nil score should just prohibit the item from being added
        local rv = chart:GetRadarValues(self.List.Player)
        local stepcount = rv:GetValue("RadarCategory_TapsAndHolds")
        local holds = rv:GetValue("RadarCategory_Holds") + rv:GetValue("RadarCategory_Rolls")
        local rating = chart:GetMeter()
        local maxscore = CalculateMaxDPByTechRadar(TechRadarFromSteps(chart))
        local j = self.Judgments

        self.MaxScore = maxscore
        self.ECFAScore, self.DP = CalculateECFA2021Score(j[1], j[2], holds-j[7], j[8], stepcount, maxscore, rating)
        return self.ECFAScore
    end,
    __lt = function(a, b)
        if not a.ECFAScore then a:SetScore() end
        if not b.ECFAScore then b:SetScore() end
        return (a.ECFAScore < b.ECFAScore)
    end,
    __eq = function(a, b)
        if not a.ECFAScore then a:SetScore() end
        if not b.ECFAScore then b:SetScore() end
        return (a.ECFAScore == b.ECFAScore)
    end,
    __index = function(self, key)
        return mt_ecfa2021item[key]
    end
}
mt_ecfa2021list = {
    __newindex = function(list, ind, item)
        if type(ind) ~= "number" then rawset(list, ind, item) return end
        -- calculate score for item
        -- check if an item already exists with same song
        -- remove existing item if lower score, otherwise remove new entry if new is lower
        -- sort table by descending order
        item.List = list
        item:SetScore()
        if not item.ECFAScore then return end
        rawset(list, ind, item)
        for i, v in ipairs(list) do
            if (i ~= #list) and (v.Song == item.Song) then
                if item > v then
                    table.remove(list, i)
                    break
                else
                    table.remove(list, #list)
                    return
                end
            end
        end
        table.sort(list, function(a, b) return a > b end)
        -- update lookups
        for i, item in ipairs(list) do
            list.Lookup[item.Song] = i
        end
        list:CalculateTotals()
    end,
    CalculateTotals = function(self)
        local points = 0
        for i, item in ipairs(self) do
            if not item.ECFAScore then item:SetScore() end
            if i <= 50 then points = points + item.ECFAScore
            elseif i <= 100 then points = points + (item.ECFAScore/2)
            else points = points + math.min(item.ECFAScore, 1) end
        end
        self.TotalPoints = points
        self.Songs = #self
        return points, #self
    end,
    __index = function(self, key)
        return mt_ecfa2021list[key]
    end
}

InitECFA2021List = function(pn)
    if not WF.PlayerProfileStats[pn] then return end
    local player = "PlayerNumber_P"..pn
    local list = {
        Player = player,
        Songs = 0,
        TotalPoints = 0,
        Lookup = {}
    }
    setmetatable(list, mt_ecfa2021list)
    WF.PlayerProfileStats[pn].ECFA2021ScoreList = list
    return list
end
NewECFA2021Item = function(song, w1, w2, w3, w4, w5, miss, held, mines)
    local item = {
        Song = song,
        Judgments = {w1, w2, w3, w4, w5, miss, held, mines},
        DP = 0,
        MaxScore = 0 -- these last two will be assigned at SetScore
    }
    setmetatable(item, mt_ecfa2021item)
    return item
end
AddCurrentScoreToECFA2021List = function(pn)
    -- call this on evaluation
    if not WF.PlayerProfileStats[pn] then return end
    if not IsECFA2021Song() then return end
    if not WF.PlayerProfileStats[pn].ECFA2021ScoreList then InitECFA2021List(pn) end
    local list = WF.PlayerProfileStats[pn].ECFA2021ScoreList

    local song = GAMESTATE:GetCurrentSong()
    local songstr = song:GetSongDir():gsub("/Songs/","",1):gsub("/AdditionalSongs/","",1)
    local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats("PlayerNumber_P"..pn)
    local held = pss:GetHoldNoteScores("HoldNoteScore_Held")

    local item = NewECFA2021Item(songstr, pss:GetTapNoteScores("TapNoteScore_W1"),
        pss:GetTapNoteScores("TapNoteScore_W2"), pss:GetTapNoteScores("TapNoteScore_W3"),
        pss:GetTapNoteScores("TapNoteScore_W4"), pss:GetTapNoteScores("TapNoteScore_W5"),
        pss:GetTapNoteScores("TapNoteScore_Miss"), held, pss:GetTapNoteScores("TapNoteScore_HitMine"))

    list[#list+1] = item
end
SaveECFA2021ScoreList = function(pn)
    if not WF.PlayerProfileStats[pn] then return end
    if not WF.PlayerProfileStats[pn].ECFA2021ScoreList then return end
    local dir = PROFILEMAN:GetProfileDir("ProfileSlot_Player"..pn)
    if (not dir) or dir == "" then return end

    local t = {}
    for item in ivalues(WF.PlayerProfileStats[pn].ECFA2021ScoreList) do
        table.insert(t, item.Song)
        table.insert(t, table.concat(item.Judgments, ","))
    end
    table.insert(t, "")

    local fstr = table.concat(t, "\n")
    if File.Write(dir.."/ECFA2021.wf",fstr) then
        Trace("ECFA 2021 scores for Player "..pn.." saved.")
    else
        SM("ECFA 2021 scores for Player "..pn.." failed to save!")
    end
end
LoadECFA2021ScoreList = function(pn)
    local dir = PROFILEMAN:GetProfileDir("ProfileSlot_Player"..pn)
    if (not dir) or dir == "" then return end
    local fpath = dir.."/ECFA2021.wf"
    if not FILEMAN:DoesFileExist(fpath) then return end

    local sfile = File.Read(fpath)
    if not sfile then
        -- error loading file
        SM("Error loading ECFA 2021 scores for player "..pn.."!")
        return
    end

    local list = InitECFA2021List(pn)
    local cursong
    local lines = split("\n", sfile)
    for line in ivalues(lines) do
        line = line:gsub("[\r\f\n]", "")
        if line and line ~= "" then
            if line:match("/") then
                cursong = line
            else
                local j = line:split_tonumber()
                local item = NewECFA2021Item(cursong, j[1], j[2], j[3], j[4], j[5], j[6], j[7], j[8])
                item.List = list
                item:SetScoreDirect()
                list[#list+1] = item
            end
        end
    end

    Trace("Loaded ECFA 2021 scores for player "..pn..".")
end

-- This function is used on loading an outdated profile, because someone is definitely going to run
-- into problems with that
BackUpECFA2021Stats = function(dir)
    if not FILEMAN:DoesFileExist(dir.."/ECFA2021.wf") then return end
    if FILEMAN:DoesFileExist(dir.."/ECFA2021_backup") then return end
    local filestr = File.Read(dir.."/ECFA2021.wf")
    File.Write(dir.."/ECFA2021_backup", filestr)
end