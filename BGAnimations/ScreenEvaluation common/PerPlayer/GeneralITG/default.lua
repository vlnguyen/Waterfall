-- This is essentially a copy of Pane1, but using the ITG data

local args = ...
local player = args.player
local name = "GeneralITG"
if args.sec then name = name.."2" end
local pn = tonumber(player:sub(-1))

return Def.ActorFrame{
	Name = name,

	InitCommand=function(self)
		self:visible(false)
	end,

	-- labels like "FANTASTIC", "MISS", "holds", "rolls", etc.
	LoadActor("./JudgmentLabels.lua", args),

	-- score displayed as a percentage
	LoadActor("./Percentage.lua", args),

	-- numbers (How many Fantastics? How many Misses? etc.)
	LoadActor("./JudgmentNumbers.lua", args),
}