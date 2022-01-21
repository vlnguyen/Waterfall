-- functions being called here control the custom lifebars; they are defined in Scripts/WF-LifeBars.lua
local af = Def.ActorFrame{
    JudgmentMessageCommand = function(self, params)
        WF.LifeBarProcessJudgment(params)
    end,
    WFLifeChangedMessageCommand = function(self, params)
        local songtime = GAMESTATE:GetCurMusicSeconds()
        WF.TrackLifeChange(params.pn, params.ind, params.newlife, songtime)
    end
}

return af