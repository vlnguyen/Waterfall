local params = ...
local player = params.player
local stats = params.stats

--local playerStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local gradeind = stats:GetGrade() -- playerStats:GetGrade()
local grade = "Grade_Tier0"..gradeind

local t = Def.ActorFrame{}

t[#t+1] = LoadActor(THEME:GetPathG("", "_grades/"..grade..".lua"))..{
	OnCommand=function(self) self:zoom(0.4) end
}

return t