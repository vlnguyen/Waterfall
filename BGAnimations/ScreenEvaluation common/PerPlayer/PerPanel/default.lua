-- Pane2 displays per-columnm judgment counts.
-- In "dance" the columns are left, down, up, right.
-- In "pump" the columns are downleft, upleft, center, upright, downright
-- etc.

local args = ...
local player = args.player
local name = "PerPanel"
if args.mode == "ITG" then name = name.."ITG" end
if args.sec then name = name.."2" end

return Def.ActorFrame{
	Name = name,
	-- ExpandForDoubleCommand() does not do anything here, but we check for its presence in
	-- this ActorFrame in ./InputHandler to determine which panes to expand the background for
	ExpandForDoubleCommand=function() end,
	InitCommand=function(self)
		local style = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())
		if style == "OnePlayerTwoSides" then
			local p2side = (player == PLAYER_1 and (args.sec)) or (player == PLAYER_2 and (not args.sec))
			if p2side then self:x(-310 + 40)
			else self:x(40) end
		end

		self:draworder(100)
		self:visible(false)
	end,

	LoadActor("./Percentage.lua", args),
	LoadActor("./JudgmentLabels.lua", args),
	LoadActor("./Arrows.lua", args)
}