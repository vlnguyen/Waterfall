-- density graph on ScreenEvaluation
local params = ...
local player = params.player
local pn = tonumber(params.player:sub(-1))
local gw = params.GraphWidth
local gh = params.GraphHeight

local af = Def.ActorFrame{
    InitCommand = function(self)
        self:x(-gw/2)
        self:y(gh)
    end
}

af[#af+1] = (not GAMESTATE:IsCourseMode()) and NPS_Histogram_Static(player, gw, gh)
    or NPS_Histogram_Static_Course(player, gw, gh)

return af