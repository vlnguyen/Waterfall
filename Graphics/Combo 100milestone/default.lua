
local style = "Arrows"
local c = GetDefaultColor()

return Def.ActorFrame{
	InitCommand=function(self) self:visible(false) end,
	HundredMilestoneCommand=function(self) self:finishtweening():visible(true):sleep(0.6):queuecommand("Hide") end,
	ThousandMilestoneCommand=function(self) self:finishtweening():queuecommand("HundredMilestone") end,
	HideCommand=function(self) self:visible(false) end
}