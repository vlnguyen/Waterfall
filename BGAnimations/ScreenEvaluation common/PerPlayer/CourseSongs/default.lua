local args = ...
local player = args.player
local mode = args.mode
local name = "CourseSongs"
if args.mode == "ITG" then name = name.."ITG" end
if args.sec then name = name.."2" end
local pn = tonumber(player:sub(-1))
local side = pn
if args.sec then side = (player == PLAYER_1) and 2 or 1 end
local itg = (args.mode == "ITG")

-- only relevant in marathon mode
if not GAMESTATE:IsCourseMode() then return end
local trail = GAMESTATE:GetCurrentTrail(player)
local numitems = #trail:GetTrailEntries()

local itemw = 290
local itemh = 40
local itemspace = 4
local topy = _screen.cy - 52

local af = Def.ActorFrame{
    Name = name,
    --mask quads
    Def.Quad{
        InitCommand = function(self) self:vertalign("bottom"):y(topy-itemspace+2):zoomto(300, 300):MaskSource() end
    },
    Def.Quad{
        InitCommand = function(self) self:vertalign("top"):y(topy-itemspace+178):zoomto(300, 100):MaskSource() end
    }
}

-- the scroller frame
local scroller = Def.ActorFrame{
    InitCommand = function(self)
        self:MaskDest():queuecommand("Reset")
    end,
    EvalPaneChangedMessageCommand = function(self, params)
        if not (params.pn == side) then return end
        self:stoptweening()
        self:queuecommand("Reset")
    end,
    ResetCommand = function(self)
        self:y(0)
        self:sleep(2)
        self:queuecommand("Scroll")
    end,
    ScrollCommand = function(self)
        if numitems <= 4 then return end
        local scrollamt = (itemh+itemspace) * (numitems - 4)
        local scrolltime = (numitems - 4) * 0.5
        self:y(0)
        self:linear(scrolltime)
        self:y(-scrollamt)
        self:sleep(3)
        self:queuecommand("Reset")
    end,
}

for i, te in ipairs(trail:GetTrailEntries()) do
    local song = te:GetSong()
    local steps = te:GetSteps()
    local checkdata = (not itg) and WF.CurrentCourseStatsObjects[pn] or WF.ITGJudgmentCountsPerSongInCourse[pn]
    local score, ct, grade, fail
    local ind = (not itg) and (i + 1) or i
    if checkdata[ind] then
        if not itg then
            score = checkdata[ind]:GetPercentDP()
            ct = checkdata[ind]:GetClearType()
            grade = checkdata[ind]:GetGrade()
            fail = checkdata[ind]:GetFail()
        else
            if WF.ITGFailed[pn] then
                if ind < WF.ITGSongInCourseAtFail[pn] then fail = false
                elseif ind == WF.ITGSongInCourseAtFail[pn] then fail = true end
            else fail = false end
            if fail ~= nil then
                score = WF.CalculatePercentDP(checkdata[ind], steps, player, itg)
                grade = (not fail) and CalculateGradeITG(math.floor(score*10000)) or 18
            end
        end
    end
    scroller[#scroller+1] = Def.ActorFrame{
        InitCommand = function(self)
            self:y(topy + (itemh+itemspace)*(i-1))
        end,
        -- backing quad
        Def.Quad{
            InitCommand = function(self)
                self:vertalign("top"):zoomto(itemw,itemh):diffuse(0,0,0,0.9)
            end
        },
        -- song title
        LoadFont("Common Normal")..{
            Text = song:GetDisplayFullTitle(),
            InitCommand = function(self)
                self:zoom(0.7):vertalign("top"):y(2):maxwidth((itemw-4)/0.7)
            end
        },
        -- difficulty
        LoadFont("_wendy small")..{
            Text = steps:GetMeter(),
            InitCommand = function(self)
                self:x(-itemw/2+30):horizalign("right"):vertalign("bottom"):y(37):zoom(0.5)
                :diffuse(DifficultyColor(steps:GetDifficulty()))
            end
        },
        -- % score
        LoadFont("_wendy small")..{
            Text = (score) and string.format("%.2f", math.floor(score*10000)/100) or "",
            InitCommand = function(self)
                self:x(-2):horizalign("right"):vertalign("bottom"):y(37):zoom(0.5)
                if fail then self:diffuse(Color.Red) end
            end
        },
        -- clear type
        LoadFont("Common Normal")..{
            Text = (ct) and WF.ClearTypes[ct] or "",
            InitCommand = function(self)
                self:x(48):vertalign("bottom"):y(37):zoom(0.65):diffuse(WF.ClearTypeColor(ct))
            end
        },
        -- conditional "not available" text
        LoadFont("Common Normal")..{
            Text = (not score) and "Not Available" or "",
            InitCommand = function(self)
                self:zoom(0.7):y(36):vertalign("bottom"):diffuse(Color.Red)
            end
        },
        -- grade
        LoadActor(THEME:GetPathG("","_GradesSmall/LetterGrade.lua"), {grade = grade or 99, itg = itg})..{
            OnCommand = function(self)
                if not grade then self:visible(false) end
                self:x(118):y(28):zoom(0.3)
            end
        }
    }
end

af[#af+1] = scroller

return af