-- Functions relating to custom lifebars
-- Eventually the whole "SL" table will be merged with the WF table created here for now.

WF = {}

WF.Version = GetThemeVersion()

WF.LifeBarNames = enum_table( {"Easy","Normal","Hard"} )

-- used for graphs and potentially other visulizations
WF.LifeBarColors = { {0,1,0.70,1}, {1,1,1,1}, {1,0.39,0,1} }

-- actual lifebar metrics
WF.LifeBarMetrics = {
    {
        -- Easy
        InitialValue = 1000,
        MaxValue = 1000,
        LifeChangeW1 = 12,
        LifeChangeW2 = 12,
        LifeChangeW3 = 12,
        LifeChangeW4 = 12,
        LifeChangeW5 = -40,
        LifeChangeMiss = -80,
        LifeChangeHitMine = -40,
        LifeChangeHeld = 10,
        LifeChangeLetGo = -40,

        ComboToRegainLifeInitialValue = 0,
        ComboAfterMiss = 0,
        MaxComboAfterMiss = 0,

        UseAutoRegen = true,
        UseAutoRegenInCourse = true, -- except easy will probably be disabled in courses?
        RegenWaitTime = 400,
        RegenThreshold = 500,
        RegenTickTime = 0.01,
        RegenLifeChangeAddTime = 100,
        RegenTickLifeInc = 1
    },
    {
        -- Normal
        InitialValue = 1000,
        MaxValue = 1000,
        LifeChangeW1 = 10, -- +1%
        LifeChangeW2 = 10,
        LifeChangeW3 = 10,
        LifeChangeW4 = 5, -- +.5% for "close"
        LifeChangeW5 = -50, -- -5%
        LifeChangeMiss = -100, -- -10%
        LifeChangeHitMine = -50,
        LifeChangeHeld = 10,
        LifeChangeLetGo = -100,

        -- combo to regain life
        ComboToRegainLifeInitialValue = 0,
        ComboAfterMiss = 5,
        MaxComboAfterMiss = 5,
        
        -- regen stuff
        UseAutoRegen = true,
        UseAutoRegenInCourse = false,
        RegenWaitTime = 500,
        RegenThreshold = 350,
        RegenTickTime = 0.01,
        RegenLifeChangeAddTime = 100,
        RegenTickLifeInc = 3
    },
    {
        -- Hard
        InitialValue = 1000,
        MaxValue = 1000,
        LifeChangeW1 = 8,
        LifeChangeW2 = 8,
        LifeChangeW3 = 4,
        LifeChangeW4 = 0,
        LifeChangeW5 = -100,
        LifeChangeMiss = -125,
        LifeChangeHitMine = -100,
        LifeChangeHeld = 0,
        LifeChangeLetGo = -125,

        ComboToRegainLifeInitialValue = 0,
        ComboAfterMiss = 10,
        MaxComboAfterMiss = 10,

        UseAutoRegen = false
    }
}

WF.ActiveLifeBars = {1,2,3}
WF.LifeBarValues = {}
WF.LifeBarChanges = {} -- table that will track timestamps and life values for each bar, for the graph
                       -- in marathon mode this will be an array of tables for each song

-- some stuff relating to danger
WF.VisibleLifeBar = {3,3}
WF.DangerThreshold = {200,250,315} -- 2.5ish miss increments for each

WF.TrackLifeChange = function(pn, ind, newlife, songtime)
    -- each node in WF.LifeBarChanges[pn][ind] will have { lifeval, timestamp }
    local t = (not GAMESTATE:IsCourseMode()) and WF.LifeBarChanges[pn][ind]
        or WF.LifeBarChanges[pn][ind][WF.CurrentSongInCourse]
    table.insert(t, { newlife, songtime })
end

WF.PreferredLifeBar = {3,3}
WF.LowestLifeBarToFail = {1,1} -- this will eventually be an option to select; actually not anymore lol

WF.InitializeLifeBars = function(actor)
    -- pass in actor so that RegenTick can be called at the beginning of a song in a course if needed (WTF)
    local iscourse = GAMESTATE:IsCourseMode()
    for i = 1, 2 do -- each player
        if (not iscourse) or (iscourse and WF.CurrentSongInCourse == 1) then
            -- everything that should only happen on the first song if in a course
            WF.LifeBarValues[i] = {}
            WF.LifeBarChanges[i] = {}
            for j = 1, #WF.LifeBarNames do
                local active = FindInTable(j, WF.ActiveLifeBars) and true or false
                WF.LifeBarChanges[i][j] = {}
                WF.LifeBarValues[i][j] = {
                    Active = active,
                    CurrentLife = active and WF.LifeBarMetrics[j].InitialValue or 0,
                    ComboToRegainLife = WF.LifeBarMetrics[j].ComboToRegainLifeInitialValue,
                    Failed = false,
                    RegenState = 0,
                    RegenTimer = 0,
                    ScoreAtFail = -1,
                    FinalLifePerSongInCourse = {},
                    SongInCourseAtFail = -1,
                    ScoreAtFailSongInCourse = -1
                }
            end
            if SL["P"..i].ActiveModifiers.PreferredLifeBar then
                WF.PreferredLifeBar[i] = WF.LifeBarNames[SL["P"..i].ActiveModifiers.PreferredLifeBar]
                WF.VisibleLifeBar[i] = WF.PreferredLifeBar[i]
            end
        end
        if iscourse then
            -- every song in a course
            for j = 1, #WF.LifeBarNames do
                table.insert(WF.LifeBarChanges[i][j], {})

                -- if not first song, get current life and record to previous song's final life value
                if (WF.CurrentSongInCourse > 1) and (not WF.LifeBarValues[i][j].Failed) then
                    WF.LifeBarValues[i][j].FinalLifePerSongInCourse[WF.CurrentSongInCourse - 1]
                        = WF.LifeBarValues[i][j].CurrentLife
                end

                -- set final life right away if already failed in a course
                if WF.LifeBarValues[i][j].Failed then
                    WF.LifeBarValues[i][j].FinalLifePerSongInCourse[WF.CurrentSongInCourse] = 0
                end
            end
        end
    end
end

WF.InitializeLifeBars()

-- some functions for easier access to lifebar values
WF.GetCurrentLife = function(pn, ind)
    return WF.LifeBarValues[pn][ind].CurrentLife
end
WF.IsLifeBarActive = function(pn, ind)
    return WF.LifeBarValues[pn][ind].Active
end
WF.IsLifeBarFailed = function(pn, ind)
    return WF.LifeBarValues[pn][ind].Failed
end
WF.GetLifePercent = function(pn, ind)
    -- get life value on a scale from 0 to 1
    return WF.GetCurrentLife(pn, ind) / WF.LifeBarMetrics[ind].MaxValue
end

WF.GetShortLifeBarTable = function(pn, songincourse)
    -- returns a short table of just the life values i.e. {1,1,1} for the given player number
    -- returns for a specific song index in a course if songincourse is included
    local t = {}
    for i = 1, #WF.LifeBarValues[pn] do
        t[i] = (not songincourse) and WF.LifeBarValues[pn][i].CurrentLife
            or WF.LifeBarValues[pn][i].FinalLifePerSongInCourse[songincourse]
    end
    return t
end

WF.ChangeLife = function(pn, ind, amount, regenflag)
    -- change the lifebar value of corresponding lifebar for the pn and ind (1, 2 or 3) by the given amount
    -- regenflag includes a signal in the params so that certain logic doesn't respond to this
    local iscourse = GAMESTATE:IsCourseMode()
    local oldlife = WF.LifeBarValues[pn][ind].CurrentLife
    WF.LifeBarValues[pn][ind].CurrentLife = math.max(0, math.min(WF.LifeBarMetrics[ind].MaxValue, 
        WF.LifeBarValues[pn][ind].CurrentLife + amount))
    local newlife = WF.LifeBarValues[pn][ind].CurrentLife
    local delta = newlife - oldlife
    if delta ~= 0 then
        MESSAGEMAN:Broadcast("WFLifeChanged", {pn = pn, ind = ind, newlife = newlife, delta = delta, regenflag = regenflag})
    end

    if newlife <= 0 then
        WF.LifeBarValues[pn][ind].Failed = true
        local score = STATSMAN:GetCurStageStats():GetPlayerStageStats("PlayerNumber_P"..pn):GetPercentDancePoints()
        WF.LifeBarValues[pn][ind].ScoreAtFail = math.floor(score*10000)

        -- course specific
        if iscourse then
            WF.LifeBarValues[pn][ind].SongInCourseAtFail = WF.CurrentSongInCourse
            WF.LifeBarValues[pn][ind].FinalLifePerSongInCourse[WF.CurrentSongInCourse] = 0
            local player = "PlayerNumber_P"..pn
            WF.LifeBarValues[pn][ind].ScoreAtFailSongInCourse = math.floor(WF.CalculatePercentDP(
                WF.JudgmentCountsCurrentSongInCourse[pn], GAMESTATE:GetCurrentSteps(player)) * 10000)
        end

        MESSAGEMAN:Broadcast("WFLifeBarFailed", {pn = pn, ind = ind})
        if ind == WF.VisibleLifeBar[pn] and ind > WF.LowestLifeBarToFail[pn] then
            WF.VisibleLifeBar[pn] = WF.VisibleLifeBar[pn] - 1
        end
        if ind == WF.LowestLifeBarToFail[pn] then
            -- handle fail
            WF.FailPlayer(pn)
        end
    end

    -- danger messages
    if (newlife <= WF.DangerThreshold[ind] and oldlife > WF.DangerThreshold[ind]) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "In"})
    elseif (newlife > WF.DangerThreshold[ind] and oldlife <= WF.DangerThreshold[ind]) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "Out"})
    elseif (newlife <= 0 and oldlife > 0) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "Dead"})
    end
end

WF.SetLife = function(pn, ind, amount, regenflag)
    -- this logic is a bit redundant; maybe i'll combine these two functions at some point
    local oldlife = WF.LifeBarValues[pn][ind].CurrentLife
    WF.LifeBarValues[pn][ind].CurrentLife = math.max(0, math.min(WF.LifeBarMetrics[ind].MaxValue, amount))
    local newlife = WF.LifeBarValues[pn][ind].CurrentLife
    local delta = newlife - oldlife
    if delta ~= 0 then
        MESSAGEMAN:Broadcast("WFLifeChanged", {pn = pn, ind = ind, newlife = newlife, delta = delta, regenflag = regenflag})
    end
    if newlife <= 0 then
        WF.LifeBarValues[pn][ind].Failed = true
        local score = STATSMAN:GetCurStageStats():GetPlayerStageStats("PlayerNumber_P"..pn):GetPercentDancePoints()
        WF.LifeBarValues[pn][ind].ScoreAtFail = math.floor(score*10000)
        -- course specific
        if iscourse then
            WF.LifeBarValues[pn][ind].SongInCourseAtFail = WF.CurrentSongInCourse
            local player = "PlayerNumber_P"..pn
            WF.LifeBarValues[pn][ind].ScoreAtFailSongInCourse = math.floor(WF.CalculatePercentDP(
                WF.JudgmentCountsCurrentSongInCourse, GAMESTATE:GetCurrentSteps(player)) * 10000)
        end
        MESSAGEMAN:Broadcast("WFLifeBarFailed", {pn = pn, ind = ind})
        if ind == WF.VisibleLifeBar[pn] and ind > WF.LowestLifeBarToFail[pn] then
            WF.VisibleLifeBar[pn] = WF.VisibleLifeBar[pn] - 1
        end
        if ind == WF.LowestLifeBarToFail[pn] then
            -- handle fail
            WF.FailPlayer(pn)
        end
    end
    -- danger messages
    if (newlife <= WF.DangerThreshold[ind] and oldlife > WF.DangerThreshold[ind]) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "In"})
    elseif (newlife > WF.DangerThreshold[ind] and oldlife <= WF.DangerThreshold[ind]) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "Out"})
    elseif (newlife <= 0 and oldlife > 0) then
        MESSAGEMAN:Broadcast("WFDanger", {pn = pn, ind = ind, event = "Dead"})
    end
end

WF.FailPlayer = function(pn)
    -- handle everything relating to failing a player
    -- set all lifebars to 0 (it's possible a lower lifebar still running than the "lowest to fail" is still above 0)
    -- (also, this allows this to be used as a force fail)
    for i = #WF.LifeBarNames, 1, -1 do
        if not (WF.LifeBarValues[pn][i].CurrentLife == 0 and WF.LifeBarValues[pn][i].Failed) then
            WF.LifeBarValues[pn][i].CurrentLife = 0
            MESSAGEMAN:Broadcast("WFLifeChanged", {pn = pn, ind = i, newlife = 0, regenflag = false})
            WF.LifeBarValues[pn][i].Failed = true
            MESSAGEMAN:Broadcast("WFLifeBarFailed", {pn = pn, ind = i})
        end
    end

    -- tell sm to fail
    -- bit of a weird unlikely case here -- if in a course and using itg mode, don't fail the player if they
    -- are still alive for itg since that would be dumb to have happen. it's extremely unlikely to fail easy
    -- while still being alive in itg but definitely possible due to fault taking up some of great and all of decent.
    -- byproduct of this is that you'd still keep gaining score for wf which is strange, but probably not too harmful.
    if not (GAMESTATE:IsCourseMode() and SL["P"..pn].ActiveModifiers.SimulateITGEnv and (not WF.ITGFailed[pn])) then
        STATSMAN:GetCurStageStats():GetPlayerStageStats("PlayerNumber_P"..pn):FailPlayer()
    end

    -- broadcast custom message
    MESSAGEMAN:Broadcast("WFFailed", {pn = pn})
end

WF.LifeBarProcessJudgment = function(params)
    -- call this in JudgmentMessageCommand; params should be the params table from the message
    local pn = tonumber(params.Player:sub(-1))
    if (params.TapNoteScore and params.TapNoteScore == "TapNoteScore_AvoidMine") or
       (params.HoldNoteScore and params.HoldNoteScore == "HoldNoteScore_MissedHold") then
        -- no need to do anything for dodged mines or missedhold
        return
    end

    local name
    if params.TapNoteScore and not params.HoldNoteScore then
        name = params.TapNoteScore:gsub("TapNoteScore_","")
    elseif params.HoldNoteScore then
        name = params.HoldNoteScore:gsub("HoldNoteScore_","")
    end

    -- i am making combotoregainlife actually use combo judgments specifically, rather than just using
    -- the life change values. this is my lifebar i do what i want  .
    if name == "W1" or name == "W2" or name == "W3" or name == "W4" or name == "Held" then
        for i, bar in ipairs(WF.LifeBarValues[pn]) do
            if bar.Active and not bar.Failed then
                if bar.ComboToRegainLife > 0 and name ~= "Held" then
                    bar.ComboToRegainLife = bar.ComboToRegainLife - 1
                end
                if bar.ComboToRegainLife <= 0 then
                    WF.ChangeLife(pn, i, WF.LifeBarMetrics[i]["LifeChange"..name])
                end
            end
        end
    elseif name == "W5" or name == "Miss" or name == "HitMine" or name == "LetGo" then
        for i, bar in ipairs(WF.LifeBarValues[pn]) do
            if bar.Active and not bar.Failed then
                bar.ComboToRegainLife = math.min(WF.LifeBarMetrics[i].MaxComboAfterMiss,
                    bar.ComboToRegainLife + WF.LifeBarMetrics[i].ComboAfterMiss)
                WF.ChangeLife(pn, i, WF.LifeBarMetrics[i]["LifeChange"..name])
            end
        end
    end

    --- debug message to notify if ever an easier lifebar has a lower life value than a harder one
    if WF.GetCurrentLife(pn, 1) < WF.GetCurrentLife(pn, 2) then
        SM("---LIFEBAR CONFLICT--- 1 = "..WF.GetCurrentLife(pn, 1)..", 2 = "..WF.GetCurrentLife(pn, 2).."---")
    end
    if WF.GetCurrentLife(pn, 1) < WF.GetCurrentLife(pn, 3) then
        SM("---LIFEBAR CONFLICT--- 1 = "..WF.GetCurrentLife(pn, 1)..", 3 = "..WF.GetCurrentLife(pn, 3).."---")
    end
    if WF.GetCurrentLife(pn, 2) < WF.GetCurrentLife(pn, 3) then
        SM("---LIFEBAR CONFLICT--- 2 = "..WF.GetCurrentLife(pn, 2)..", 3 = "..WF.GetCurrentLife(pn, 3).."---")
    end
end


-- auto regen functions
WF.ResetLifeRegenState = function(pn, ind)
    if not WF.LifeBarMetrics[ind].UseAutoRegen then return end
    WF.LifeBarValues[pn][ind].RegenState = 0
    WF.LifeBarValues[pn][ind].RegenTimer = WF.LifeBarMetrics[ind].RegenWaitTime
end

WF.LifeChangedAddRegenTime = function(pn, ind)
    if not WF.LifeBarMetrics[ind].UseAutoRegen then return end
    WF.LifeBarValues[pn][ind].RegenTimer = math.min(WF.LifeBarValues[pn][ind].RegenTimer
        + WF.LifeBarMetrics[ind].RegenLifeChangeAddTime, WF.LifeBarMetrics[ind].RegenWaitTime)
end

WF.LifeRegenTick = function(pn, ind, actor)
    if WF.IsLifeBarFailed(pn, ind) or (not WF.LifeBarMetrics[ind].UseAutoRegen)
    or (GAMESTATE:IsCourseMode() and (not WF.LifeBarMetrics[ind].UseAutoRegenInCourse)) then return end

    if WF.GetCurrentLife(pn, ind) >= WF.LifeBarMetrics[ind].RegenThreshold then
        WF.ResetLifeRegenState(pn, ind)
        return
    end

    if WF.LifeBarValues[pn][ind].RegenTimer > 0 then
        WF.LifeBarValues[pn][ind].RegenTimer = WF.LifeBarValues[pn][ind].RegenTimer - 1
    else
        if WF.LifeBarMetrics[ind].RegenThreshold - WF.GetCurrentLife(pn, ind) > WF.LifeBarMetrics[ind].RegenTickLifeInc then
            WF.ChangeLife(pn, ind, WF.LifeBarMetrics[ind].RegenTickLifeInc, true)
        else
            WF.SetLife(pn, ind, WF.LifeBarMetrics[ind].RegenThreshold, true)
        end
    end

    actor:sleep(WF.LifeBarMetrics[ind].RegenTickTime)
    actor:queuecommand("RegenTick")
end

-- get vertices for lifebar graph
WF.GetLifeGraphVertices = function(pn, ind, graphwidth, graphheight, songstart, songend, songincourse, xoff)
    if not WF.IsLifeBarActive(pn, ind) then
        return nil
    end

    -- pass in songincourse to provide a specific song index within a course
    -- xoff should also be sent to this to adjust the x value based on the total length of songs so far
    local ctable = (not songincourse) and WF.LifeBarChanges[pn][ind] or WF.LifeBarChanges[pn][ind][songincourse]
    if not xoff then xoff = 0 end

    local m = WF.LifeBarMetrics[ind]
    local verts = {}
    local songlength = songend - songstart
    local timescale = songlength / graphwidth
    local t = songstart
    local l = m.InitialValue / m.MaxValue
    if (songincourse) and songincourse > 1 then
        l = WF.LifeBarValues[pn][ind].FinalLifePerSongInCourse[songincourse - 1] / m.MaxValue
    end
    local clr = WF.LifeBarColors[ind]
    local py = (1 - l) * graphheight
    local skipped = {0, 0}

    table.insert(verts, {{xoff,py,0},clr})

    for i, v in ipairs(ctable) do
        if v[2] - t >= timescale or v[1] == 0 or v[1] == m.MaxValue then
            local lifetouse = (v[1] == 0 or v[1] == m.MaxValue) and v[1] or (skipped[1]+v[1])/(skipped[2]+1)
            local x = (v[2] - songstart) / timescale
            local y = (1 - (lifetouse / m.MaxValue)) * graphheight
            -- insert another vertex 1 unit to the left at previous life if the gap in time is long
            if v[2] - t >= timescale * 4 then
                table.insert(verts, {{xoff + x - 1, py, 0},clr})
            end

            -- insert current vertex
            table.insert(verts, {{xoff + x, y, 0},clr})

            t = v[2]
            l = v[1]
            py = y
            skipped = {0, 0}
        elseif v[2] - t < timescale then
            -- store sum of any values skipped, so we can average them
            skipped[1] = skipped[1] + v[1]
            skipped[2] = skipped[2] + 1
        end
    end

    table.insert(verts, {{xoff + graphwidth, py, 0},clr})

    return verts
end

WF.GetLifeGraphVerticesCourse = function(pn, ind, graphwidth, graphheight)
    if not WF.IsLifeBarActive(pn, ind) then
        return nil
    end

    local trail = GAMESTATE:GetCurrentTrail("PlayerNumber_P"..pn)
    local totaltime = 0

    -- get total length first
    for te in ivalues(trail:GetTrailEntries()) do
        totaltime = totaltime + te:GetSong():GetLastSecond()
    end

    local xoff = 0
    local verts = {}
    for i, v in ipairs(WF.LifeBarChanges[pn][ind]) do
        -- i'd validate that trail:GetTrailEntry(i-1) exists here, but if it didn't the program would crash anyway
        local curlen = trail:GetTrailEntry(i-1):GetSong():GetLastSecond()
        local w = (curlen / totaltime) * graphwidth
        local curverts = WF.GetLifeGraphVertices(pn, ind, w, graphheight, 0, curlen, i, xoff)

        for vert in ivalues(curverts) do
            table.insert(verts, vert) -- vert
        end

        xoff = xoff + w
    end

    return verts
end