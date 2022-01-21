-- do the initial profile load per player here
for player in ivalues(GAMESTATE:GetHumanPlayers()) do
    WF.LoadPlayerProfileStats(tonumber(player:sub(-1)))
end

return Def.ActorFrame{
    Def.Quad{
        InitCommand = function(self) self:diffuse(Color.Black):FullScreen() end
    },
    LoadFont("Common Normal")..{
        Text = "",
        InitCommand = function(self)
            self:Center()
            if WF.ImportCheck() then self:settext("Merging profile data...") end
            self:sleep(0.02):queuecommand("Merge")
        end,
        MergeCommand = function(self)
            -- import all stats if desired. see WF-Profiles.lua
			if not WF.MergeProfileStats() then
                SM("ERROR OCCURRED IMPORTING STATS\nSee log file...")
                PROFILEMAN:SetStatsPrefix("WF-")
                self:sleep(0.5)
                self:queuecommand("Continue")
            else
                self:queuecommand("Continue")
            end
        end,
        ContinueCommand = function(self)
            SCREENMAN:GetTopScreen():PostScreenMessage("SM_GoToNextScreen", 0)
        end
    }
}