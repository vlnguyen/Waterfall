local px = WideScale(160, 184)
local pw = WideScale(304, 352)

local hy = 84
local hh = 80
local sy = _screen.cy + 52
local sh = 316

-- scrolling stuff
local spos = {1, 1}
local maxitems = {0, 0}
local r = {PlayerNumber_P1 = {MenuLeft = 0, MenuRight = 0}, PlayerNumber_P2 = {MenuLeft = 0, MenuRight = 0}}
local rt = 6
local viewitems = 5
local itemfh = sh/viewitems
local itemw = pw - 4
local itemh = itemfh - 4
local acceptinput = true

local InputHandler = function(event)
    if not acceptinput then return end
    if event.type == "InputEventType_Release" then
        if event.GameButton == "Start" or event.GameButton == "Back" then
            SCREENMAN:PlayStartSound()
            SCREENMAN:GetTopScreen():queuecommand("Off")
            acceptinput = false
        elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuRight" then
            r[event.PlayerNumber][event.GameButton] = 0
        end
    elseif event.type == "InputEventType_FirstPress" or event.type == "InputEventType_Repeat" then
        if event.GameButton == "MenuLeft" or event.GameButton == "MenuRight" then
            MESSAGEMAN:Broadcast("TryScroll", {Player = event.PlayerNumber,
                Inc = (event.GameButton == "MenuLeft") and -1 or 1, Repeat = false})
            
            if r[event.PlayerNumber][event.GameButton] > rt then
                for i = 1, 3 do
                    MESSAGEMAN:Broadcast("TryScroll", {Player = event.PlayerNumber,
                    Inc = (event.GameButton == "MenuLeft") and -1 or 1, Repeat = true})
                end
            end

            r[event.PlayerNumber][event.GameButton] = r[event.PlayerNumber][event.GameButton] + 1
        elseif event.type == "InputEventType_FirstPress" and event.GameButton == "Select" then
            local prefix = "ECFA/"
            local success, path = SaveScreenshot(event.PlayerNumber, false, true, prefix)
            if success then
                SCREENMAN:PlayScreenshotSound()
            end
        end
    end
end

local af = Def.ActorFrame{
    OnCommand = function(self)
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
    end
}

-- create actors on either side for each player
for player in ivalues(GAMESTATE:GetHumanPlayers()) do
    local pn = tonumber(player:sub(-1))
    local hasstats = WF.PlayerProfileStats[pn] and true or false
    local hasecfa = hasstats and WF.PlayerProfileStats[pn].ECFA2021ScoreList and true or false

    -- load stuff we care about
    local data
    if hasecfa then
        data = {}
        data.total = WF.PlayerProfileStats[pn].ECFA2021ScoreList.TotalPoints
        data.songs = WF.PlayerProfileStats[pn].ECFA2021ScoreList.Songs
        data.maxdiff = 0
        for item in ivalues(WF.PlayerProfileStats[pn].ECFA2021ScoreList) do
            if item.ECFAScore > 0 then
                data.maxdiff = math.max(item:GetChart():GetMeter(), data.maxdiff)
            else
                break
            end
        end

        local list = hasecfa and WF.PlayerProfileStats[pn].ECFA2021ScoreList or {}
        maxitems[pn] = #list
        for i, item in ipairs(list) do
            data[i] = {}
            data[i].song = SONGMAN:FindSong(item.Song)
            data[i].chart = item:GetChart()
            data[i].actualpts = ((i <= 50) and item.ECFAScore) or ((i <= 100) and item.ECFAScore/2)
                or math.min(item.ECFAScore, 1)
            data[i].zjudges = item.Judgments[3] + item.Judgments[4] + item.Judgments[5] + item.Judgments[6]
            data[i].njudges = item.Judgments[8]
            if data[i].chart then
                local rv = data[i].chart:GetRadarValues(player)
                local holds = rv:GetValue("Holds") + rv:GetValue("Rolls")
                data[i].njudges = (holds - item.Judgments[7]) + item.Judgments[8]
            end
            data[i].item = item
        end
    end

    -- frame to position player
    local pf = Def.ActorFrame{
        InitCommand = function(self) self:x(_screen.cx + (pn == 1 and -1 or 1) * px) end,
        OffCommand = function(self) self:accelerate(0.25):addx((pn == 1 and -1 or 1) * 500)
            :queuecommand("NextScreen") end,
        NextScreenCommand = function(self)
            SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
        end
    }

    -- backing quades
    pf[#pf+1] = Def.Quad{
        InitCommand = function(self)
            self:y(hy):zoomto(pw, hh):diffuse(0, 0, 0, 0.9)
        end
    }

    -- avatar
    local ppath = PROFILEMAN:GetProfileDir("ProfileSlot_Player"..pn).."/avatar.png"
    ppath = (ppath ~= "/avatar.png" and FILEMAN:DoesFileExist(ppath) and ppath)
        or THEME:GetPathG("", "_profilecard/fallbackav.png")
    if hasstats then pf[#pf+1] = LoadActor(ppath)..{
        InitCommand = function(self)
            self:xy(-pw/2 + 52, hy + 10):zoomto(48, 48)
        end
    } end
    -- name
    if hasstats then pf[#pf+1] = LoadFont("Common Normal")..{
        Text = PROFILEMAN:GetProfile(player):GetDisplayName(),
        InitCommand = function(self)
            self:xy(-pw/2 + 52, hy - hh/2 + 6):vertalign("top"):maxwidth(100)
        end
    } end
    -- no stats message
    pf[#pf+1] = LoadFont("Common Normal")..{
        Text = (not hasstats) and "No profile loaded." or (not hasecfa) and "No ECFA stats." or "",
        InitCommand = function(self)
            self:y(hy)
        end
    }

    if hasecfa then
        -- top stats
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = "Total Points",
            InitCommand = function(self) self:xy(-36, hy - 34):horizalign("left"):vertalign("top"):zoom(1.2) end
        }
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = "Songs Played",
            InitCommand = function(self) self:xy(0, hy - 6):horizalign("left"):vertalign("top"):zoom(0.9) end
        }
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = "Max Difficulty",
            InitCommand = function(self) self:xy(0, hy + 16):horizalign("left"):vertalign("top"):zoom(0.9) end
        }
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = tostring(math.floor(data.total)),
            InitCommand = function(self) self:xy(pw/2-8, hy-34):horizalign("right"):vertalign("top"):zoom(1.2) end
        }
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = tostring(data.songs),
            InitCommand = function(self) self:xy(pw/2-8, hy-6):horizalign("right"):vertalign("top"):zoom(0.9) end
        }
        pf[#pf+1] = LoadFont("Common Normal")..{
            Text = tostring(data.maxdiff),
            InitCommand = function(self) self:xy(pw/2-8, hy+16):horizalign("right"):vertalign("top"):zoom(0.9) end
        }
    end

    if hasecfa then pf[#pf+1] = Def.Quad{
        InitCommand = function(self)
            self:y(sy):zoomto(pw, sh):diffuse(0, 0, 0.5, 0.6)
        end
    } end

    -- masks (to hide outer parts of scroller)
    pf[#pf+1] = Def.Quad{
        InitCommand = function(self)
            self:y(sy - sh/2 + 2):zoomto(pw, 200):vertalign("bottom"):MaskSource()
        end
    }
    pf[#pf+1] = Def.Quad{
        InitCommand = function(self)
            self:y(sy + sh/2 - 2):zoomto(pw, 200):vertalign("top"):MaskSource()
        end
    }

    -- "scroller" frame
    local sf = Def.ActorFrame{
        InitCommand = function(self) self:y(sy):MaskDest() end,
        TryScrollMessageCommand = function(self, params)
            if params.Player ~= player then return end
            if (params.Inc == -1 and spos[pn] > 1) or (params.Inc == 1 and spos[pn] <= maxitems[pn] - viewitems) then
                spos[pn] = spos[pn] + params.Inc
                self:playcommand("Set")
                self:finishtweening()
                self:decelerate(0.08)
                self:y(sy - (spos[pn]-1) * itemfh)
                if not params.Repeat then
                    MESSAGEMAN:Broadcast("PlayScroll")
                end
            end
        end
    }

    -- populate scroller frame with items for each song played
    local list = hasecfa and WF.PlayerProfileStats[pn].ECFA2021ScoreList or {}
    maxitems[pn] = #list
    for i = 1, math.min(maxitems[pn], 7) do
        local itf = Def.ActorFrame{
            InitCommand = function(self)
                self:y(-sh/2 + itemfh/2 + itemfh*(i-1)):aux(i)
            end,
            SetCommand = function(self)
                if self:getaux() < spos[pn] - 1 then
                    self:aux(self:getaux() + 7)
                    self:addy(itemfh * 7)
                elseif self:getaux() > spos[pn] + 5 then
                    self:aux(self:getaux() - 7)
                    self:addy(itemfh * -7)
                end
            end,
            -- back quade
            Def.Quad{
                InitCommand = function(self)
                    self:zoomto(itemw, itemh):diffuse(0, 0, 0, 0.8)
                end
            },
            -- rank number
            LoadFont("Common Normal")..{
                Text = "#"..i,
                InitCommand = function(self)
                    self:xy(-itemw/2 + 2,-itemh/2 + 2):horizalign("left"):vertalign("top"):zoom(1)
                end,
                SetCommand = function(self)
                    self:settext("#"..self:GetParent():getaux())
                end
            },
            -- song title/artist
            LoadFont("Common Normal")..{
                Text = data[i] and data[i].song and data[i].song:GetDisplayFullTitle() or "Unknown",
                InitCommand = function(self)
                    self:xy(0, -itemh/2 + 2):vertalign("top"):zoom(1.1):maxwidth((itemw-96)/1.1)
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    local song = data[ind] and data[ind].song
                    self:settext(song and song:GetDisplayFullTitle() or "")
                end
            },
            LoadFont("Common Normal")..{
                Text = data[i] and data[i].song and data[i].song:GetDisplayArtist() or "Unknown",
                InitCommand = function(self)
                    self:xy(0, -itemh/2 + 21):vertalign("top"):zoom(0.8):maxwidth((itemw-96)/0.8)
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    local song = data[ind] and data[ind].song
                    self:settext(song and song:GetDisplayArtist() or "")
                end
            },
            -- difficulty number
            LoadFont("_wendy white")..{
                Text = data[i] and data[i].chart and data[i].chart:GetMeter() or "",
                InitCommand = function(self)
                    self:xy(-itemw/2 + 30, itemh/2 - 4):horizalign("right"):vertalign("bottom"):zoom(0.4)
                    :diffuse(data[i].chart and DifficultyColor(data[i].chart:GetDifficulty()) or Color.White)
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    local chart = data[ind] and data[ind].chart
                    self:settext(chart and chart:GetMeter() or "")
                    self:diffuse(chart and DifficultyColor(chart:GetDifficulty()) or Color.White)
                end
            },
            -- actual points
            LoadFont("Common Normal")..{
                Text = data[i] and tostring(math.floor(data[i].actualpts)) or "",
                InitCommand = function(self)
                    self:xy(-itemw/2 + 100, itemh/2 - 2):horizalign("right"):vertalign("bottom"):zoom(1.2)
                    if data[i].item.ECFAScore == 0 then self:diffuse(Color.Red)
                    elseif i > 50 and i <= 100 then self:diffuse(Color.Orange)
                    elseif i > 100 then self:diffuse(1, 0.8, 0.8, 1) end
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    if not data[ind] then self:settext("") return end
                    self:settext(tostring(math.floor(data[ind].actualpts)))
                    if data[ind].item.ECFAScore == 0 then self:diffuse(Color.Red)
                    elseif ind <= 50 then self:diffuse(Color.White)
                    elseif ind > 50 and ind <= 100 then self:diffuse(Color.Orange)
                    elseif ind > 100 then self:diffuse(1, 0.8, 0.8, 1) end
                end
            },
            -- max points (along with raw points if > 50)
            LoadFont("Common Normal")..{
                Text = data[i] and ("/ "..math.floor(data[i].item.MaxScore)) or "",
                InitCommand = function(self)
                    self:xy(-itemw/2 + 104, itemh/2 - 2):horizalign("left"):vertalign("bottom"):maxwidth(itemw - 216)
                    if i > 50 then
                        self:settext("("..math.floor(data[i].item.ECFAScore)..") "..self:GetText())
                    end
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    if not data[ind] then self:settext("") return end
                    local t = "/ "..math.floor(data[ind].item.MaxScore)
                    if ind > 50 then
                        t = "("..math.floor(data[ind].item.ECFAScore)..") "..t
                    end
                    self:settext(t)
                end
            },
            -- judgment counts
            LoadFont("Common Normal")..{
                Text = data[i] and tostring(data[i].item.Judgments[1]) or "",
                InitCommand = function(self)
                    self:xy(itemw/2 - 2, -itemh/2 + 2):horizalign("right"):vertalign("top"):zoom(0.8)
                    :diffuse(SL.JudgmentColors.Waterfall[1])
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    self:settext(data[ind] and tostring(data[ind].item.Judgments[1]) or "")
                end
            },
            LoadFont("Common Normal")..{
                Text = data[i] and tostring(data[i].item.Judgments[2]) or "",
                InitCommand = function(self)
                    self:xy(itemw/2 - 2, -itemh/2 + 16):horizalign("right"):vertalign("top"):zoom(0.8)
                    :diffuse(SL.JudgmentColors.Waterfall[2])
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    self:settext(data[ind] and tostring(data[ind].item.Judgments[2]) or "")
                end
            },
            LoadFont("Common Normal")..{
                Text = data[i] and tostring(data[i].zjudges) or "",
                InitCommand = function(self)
                    self:xy(itemw/2 - 2, -itemh/2 + 30):horizalign("right"):vertalign("top"):zoom(0.8)
                    :diffuse(SL.JudgmentColors.Waterfall[5])
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    self:settext(data[ind] and tostring(data[ind].zjudges) or "")
                end
            },
            LoadFont("Common Normal")..{
                Text = data[i] and tostring(data[i].njudges) or "",
                InitCommand = function(self)
                    self:xy(itemw/2 - 2, -itemh/2 + 44):horizalign("right"):vertalign("top"):zoom(0.8)
                    :diffuse(Color.Red)
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    self:settext(data[ind] and tostring(data[ind].njudges) or "")
                end
            },
            -- dp %
            LoadFont("Common Normal")..{
                Text = data[i] and string.format("%.2f%% DP", math.floor(data[i].item.DP*10000)/100) or "",
                InitCommand = function(self)
                    self:xy(itemw/2 - 48, -itemh/2 + 44):horizalign("right"):vertalign("top"):zoom(0.8)
                    if data[i].item.ECFAScore == 0 then self:diffuse(Color.Red) end
                end,
                SetCommand = function(self)
                    local ind = self:GetParent():getaux()
                    if not data[ind] then self:settext("") return end
                    self:settext(string.format("%.2f%% DP", math.floor(data[ind].item.DP*10000)/100))
                    if data[ind].item.ECFAScore == 0 then self:diffuse(Color.Red) else self:diffuse(Color.White) end
                end
            }
        }
        sf[#sf+1] = itf
    end
    
    pf[#pf+1] = sf
    af[#af+1] = pf
end

-- sounds
local scsnd, stsnd
af[#af+1] = Def.Sound{
    File = THEME:GetPathS("ScreenSelectMaster", "change.ogg"),
    PlayScrollMessageCommand = function(self)
        self:play()
    end
}

return af