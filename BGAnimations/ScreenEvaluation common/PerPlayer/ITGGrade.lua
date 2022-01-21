local player = ...
local pn = tonumber(player:sub(-1))

local grade = WF.GetITGGrade(WF.ITGScore[pn])
return Def.ActorFrame{
    LoadActor(THEME:GetPathG("", "_grades/ITGGrade_"..(WF.ITGFailed[pn] and "Failed" or "Tier"..grade)..".lua"))..{
        OnCommand = function(self)
            self:zoom(0.4)
        end
    }
}
