local player = ...
local pn = tonumber(player:sub(-1))

local gw = THEME:GetMetric("GraphDisplay", "BodyWidth")
local gh = THEME:GetMetric("GraphDisplay", "BodyHeight")
local songstart = 0
local songend = GAMESTATE:GetCurrentSong():GetLastSecond()
local verts = (not GAMESTATE:IsCourseMode()) and WF.GetITGLifeVertices(pn, gw, gh, songstart, songend)
    or WF.GetITGLifeVerticesCourse(pn, gw, gh)

local af = Def.ActorFrame{
    Def.ActorMultiVertex{
        InitCommand = function(self)
            self:x(-gw/2)
        end,
        OnCommand = function(self)
            self:SetDrawState({Mode="DrawMode_LineStrip"}):SetLineWidth(2)
                :SetVertices(verts)
        end
    }
}

return af