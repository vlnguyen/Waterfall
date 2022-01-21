-- Conditional "tech radar" for ECFA 2021

-- only need to draw one, since both players will be viewing the same chart
local player = GAMESTATE:GetMasterPlayerNumber()

local rowh = 18
local colw = 138
local columns = 2

local width = 300
local height = 100

local headerh = 18

local xpos = _screen.cx - WideScale(160, 172)
local ypos = _screen.cy + 48

local barw = colw - 64

local elements = {
    {key = "speed", label = "Speed"},
    {key = "stamina", label = "Stamina"},
    {key = "tech", label = "Technique"},
    {key = "movement", label = "Movement"},
    {key = "rhythms", label = "Rhythms"},
    {key = "gimmick", label = "Gimmicks"}
}

local gimmicks = {[-1] = "N/A", [0] = "None", [1] = "Light", [2] = "Medium", [3] = "Heavy"}
local gmkcolors = {Color.Green, Color.Yellow, {1,0.2,0.2,1}}

local rcolors = { {3, Color.Green}, {6, Color.Yellow}, {9, Color.Orange}, {10, {1,0.1,0.1,1}}, {11, {1,0,1,1}}}

local radar -- this gets set in af's SetCommand
local mt_radar = {__index = function(item, ind) item.rating = 0 return 0 end}

local af = Def.ActorFrame{
    Name = "TechRadar",
    InitCommand = function(self)
        self:xy(xpos, ypos)
        self:playcommand("Set")
    end,
    CurrentSongChangedMessageCommand = function(self) self:playcommand("Set") end,
    CurrentStepsP1ChangedMessageCommand = function(self) self:playcommand("Set") end,
    CurrentStepsP2ChangedMessageCommand = function(self) self:playcommand("Set") end,
    SetCommand = function(self)
        local active = IsECFA2021Song()
        self:visible(active)
        if active then
            local steps = GAMESTATE:GetCurrentSteps(player)
            if not steps then return end
            radar = TechRadarFromSteps(steps)
            setmetatable(radar, mt_radar)
        end
    end,

    -- bg quad
    Def.Quad{
        InitCommand = function(self) self:zoomto(width, height):diffuse(color("#1e282f")) end
    },
    -- header quad
    Def.Quad{
        InitCommand = function(self) self:y(-height/2 + headerh/2):zoomto(width, headerh):diffuse(0.1,0.1,0.1,1) end
    },
    -- header text
    LoadFont("Common Normal")..{
        Text = "ECFA 2021 Info",
        InitCommand = function(self) self:xy(-width/2 + 4, -height/2 + headerh/2):horizalign("left"):zoom(0.8) end
    }
}

local startx = -width/2 + 6
local starty = -height/2 + headerh*1.5 + 2

-- add "grid" elements
for i, t in ipairs(elements) do
    local col = (i-1) % columns
    local row = math.floor((i-1)/columns)
    -- label
    af[#af+1] = LoadFont("Common Normal")..{
        Text = t.label,
        InitCommand = function(self) self:xy(startx + (col * (colw + 10)), starty + row*rowh)
            :horizalign("left"):zoom(0.8)
            if t.key ~= "gimmick" then self:maxwidth(42/0.8) end
        end
    }
    -- bars for visual effect
    if t.key ~= "gimmick" then
        af[#af+1] = Def.Quad{
            InitCommand = function(self) self:xy(startx + (col * (colw + 10)) + 46, starty + row*rowh)
                :horizalign("left"):diffuse(Color.Black):zoomto(barw, rowh-4) end
        }
        af[#af+1] = Def.Quad{
            InitCommand = function(self) self:xy(startx + (col * (colw + 10)) + 46, starty + row*rowh)
                :horizalign("left"):zoomto(0, rowh-4) end,
            SetCommand = function(self)
                if radar and radar[t.key] then
                    self:stoptweening()
                    local color = Color.White
                    for c in ivalues(rcolors) do
                        if radar[t.key] <= c[1] then color = c[2] break end
                    end
                    self:decelerate(0.1)
                    self:diffuse(color)
                    self:zoomx(math.min((radar[t.key]/10) * barw, barw))
                end
            end
        }
    end
    -- values
    af[#af+1] = LoadFont("Common Normal")..{
        Text = "",
        InitCommand = function(self) self:xy(startx + (col * (colw + 10) + colw), starty + row*rowh)
            :horizalign("right"):zoom(0.8) end,
        SetCommand = function(self)
            if radar then
                local text
                if t.key == "gimmick" then
                    text = gimmicks[radar.gimmick] or "None"
                    self:diffuse(gmkcolors[radar.gimmick] or Color.White)
                else
                    text = (radar[t.key] <= 10) and tostring(radar[t.key]) or "???"
                end
                self:settext(text)
            end
        end
    }
end

-- max dp
af[#af+1] = LoadFont("Common Normal")..{
    Text = "Max ECFA Points:",
    InitCommand = function(self)
        self:xy(startx, starty + 3*rowh + 3):horizalign("left")
    end,
    SetCommand = function(self)
        local steps = GAMESTATE:GetCurrentSteps(player)
        if radar and steps then
            local dp = CalculateMaxDPByTechRadar(radar)
            if dp then self:settext("Max ECFA Points: "..ECFAPointString(dp)) end
        end
    end
}

-- cmod ok/no good
af[#af+1] = LoadFont("Common Normal")..{
    Text = "",
    InitCommand = function(self) self:xy(startx + (1 * (colw + 10) + colw), starty + 3*rowh)
        :horizalign("right"):zoom(0.8) end,
    SetCommand = function(self)
        if radar then
            local cmod = ((not radar.gimmick) or radar.gimmick < 1)
            self:diffuse(cmod and Color.Green or Color.Orange)
            self:settext(cmod and "CMOD OK" or "NO CMOD")
        end
    end
}

return af