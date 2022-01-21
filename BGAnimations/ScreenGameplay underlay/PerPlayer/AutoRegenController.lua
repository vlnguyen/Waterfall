local player = ...
local pn = tonumber(player:sub(-1))

local af = Def.ActorFrame{}

-- create an invisible quad actor to control each active lifebar for this player

for ind in ivalues(WF.ActiveLifeBars) do
    if WF.LifeBarMetrics[ind].UseAutoRegen
    and not (GAMESTATE:IsCourseMode() and not WF.LifeBarMetrics[ind].UseAutoRegenInCourse) then
        af[#af+1] = Def.Quad{
            InitCommand = function(self)
                self:visible(false)
                WF.ResetLifeRegenState(pn, ind)
            end,
            WFLifeChangedMessageCommand = function(self, params)
                --SCREENMAN:SystemMessage(tostring(tonumber(params.Player:sub(-1)) ~= pn))
                if (params.pn ~= pn or params.ind ~= ind) or params.regenflag then return end

                local life = WF.GetCurrentLife(pn, ind)
                if life > 0 and life < WF.LifeBarMetrics[ind].RegenThreshold then
                    --SCREENMAN:SystemMessage("Low life")
                    if WF.LifeBarValues[pn][ind].RegenState == 0 then
                        WF.LifeBarValues[pn][ind].RegenState = 1
                        WF.LifeRegenTick(pn, ind, self)
                    else
                        WF.LifeChangedAddRegenTime(pn, ind)
                    end
                end
            end,
            RegenTickCommand = function(self)
                WF.LifeRegenTick(pn, ind, self)
                --if demo then SCREENMAN:SystemMessage(tostring(WF.RegenTimer[pn])) end
            end
        }
    end
end

return af