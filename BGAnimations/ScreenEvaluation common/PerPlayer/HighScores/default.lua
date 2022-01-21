-- Pane3 displays a list of HighScores for the stepchart that was played.

local args = ...
local player = args.player
local hsdata = args.hsdata
local itg = (args.mode == "ITG")
local name = "HighScores"
if itg then name = name.."ITG" end
if args.sec then name = name.."2" end

local pane = Def.ActorFrame{
	Name=name,
	InitCommand=function(self)
		self:visible(false)
		self:y(_screen.cy - 62):zoom(0.8)
	end
}

-- row_height of a HighScore line
local rh
local listargs = { Player=player, RowHeight=rh}

-- less line spacing between HighScore rows to fit the horizontal line
rh = 20.25
listargs.RowHeight = rh

-- heading quad
pane[#pane+1] = Def.Quad{
	InitCommand = function(self)
		self:vertalign("top"):y(7):zoomto(300/0.8, rh+2):diffuse(color("#101519"))
	end
}
-- heading text
pane[#pane+1] = LoadFont("Common Normal")..{
	Text = "Local Records ("..(itg and "ITG" or "Standard")..")",
	InitCommand = function(self) self:y(rh/2+8) end
}

-- top 10 records
listargs.NumHighScores = 10
listargs.HSData = hsdata
listargs.ITG = itg
pane[#pane+1] = LoadActor(THEME:GetPathB("", "_modules/HighScoreList_WF.lua"), listargs)..{
	InitCommand = function(self) self:y(rh) end
}

return pane