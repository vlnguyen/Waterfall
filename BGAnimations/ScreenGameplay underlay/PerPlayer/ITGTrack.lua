local player = ...
local pn = tonumber(player:sub(-1))

local af = Def.ActorFrame{
    JudgmentMessageCommand = function(self, params)
        if params.Player ~= player then return end
        WF.TrackITGJudgment(pn, params)
    end
}

return af