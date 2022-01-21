local totalcharts = #WF.NewChartsToCache
if totalcharts == 0 then return end
local timestart

local takeinput = false
local function InputHandler(event)
    if not takeinput then return end
    if event.GameButton == "Start" and event.type == "InputEventType_FirstPress" then
        WF.HashCacheBuildFinish()
        SCREENMAN:SetNewScreen("ScreenOptionsService")
    end
end

local af = Def.ActorFrame{
    InitCommand = function(self) self:Center() end,
    Def.Quad{
        InitCommand = function(self)
            self:visible(false)
            Trace("Building Hash Cache started. Charts to cache: "..totalcharts)
            timestart = GetTimeSinceStart()
            self:queuecommand("GetStatus")
        end,
        OnCommand = function(self)
            SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
        end,
        GetStatusCommand = function(self)
            local st = WF.GetHashCacheBuildStatus(totalcharts)

            MESSAGEMAN:Broadcast("SendStatus", st)
        end,
        ProcessChartMessageCommand = function(self)
            WF.ProcessHashCacheItem()
            self:queuecommand("GetStatus")
        end
    },

    LoadFont("Common Normal")..{
        Name = "StatusText",
        Text = "",
        InitCommand = function(self) self:draworder(1000) end,
        SendStatusMessageCommand = function(self, st)
            if st.Step == "Done" then
                takeinput = false
                local finaltime = GetTimeSinceStart() - timestart
                --TestHashes()
                Trace("Hash cache build time: "..SecondsToHHMMSS(finaltime))
                Trace(string.format("Files parsed: %d    Charts hashed: %d", WF.SongsParsed, WF.ChartsHashed))
                self:settext("Done"):linear(0.3):diffusealpha(0):queuecommand("Done")
                return
            end

            self:settext(string.format("Building Hash Cache.\n%d/%d charts processed.\n\nCurrent chart:\n%s\n\nPress &START; to back out into the service menu\n(cache will be saved).",
            st.Finished, st.Total, st.ChartID))

            self:queuecommand("SignalProcess")
        end,
        SignalProcessCommand = function(self)
            if not takeinput then takeinput = true end
            MESSAGEMAN:Broadcast("ProcessChart")
        end,
        DoneCommand = function(self)
            SCREENMAN:GetTopScreen():PostScreenMessage("SM_GoToNextScreen", 0)
        end
    }
}

return af