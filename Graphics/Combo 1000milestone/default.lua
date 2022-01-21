
local style = "Arrows"
local c = GetDefaultColor()

return Def.ActorFrame{
	InitCommand=function(self) self:visible(false) end,
	ThousandMilestoneCommand=function(self) self:finishtweening():visible(true):sleep(0.7):queuecommand("Hide") end,
	HideCommand=function(self) self:visible(false) end
}