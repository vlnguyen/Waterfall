local args = ...
local player = args.player
local side = player
if args.sec then side = (player == PLAYER_1) and PLAYER_2 or PLAYER_1 end
local pn = tonumber(player:sub(-1))

local mods = SL["P"..pn].ActiveModifiers
local itg = mods.SimulateITGEnv
local dsp = WF.DefaultSecPane
local dg = mods.PreferredGraph
local dsg = mods.PreferredSecondGraph

local GraphWidth = THEME:GetMetric("GraphDisplay", "BodyWidth")
local GraphHeight = THEME:GetMetric("GraphDisplay", "BodyHeight")

local function ShowOrHideGraph(actor, mode, graphtype, args)
	local s = tonumber(side:sub(-1))
	local pane = WF.DefaultPane[s]
	if args then
		if args.pn ~= s then return end
		pane = (WF.EvalPanes[s][WF.ActivePane[s]]:GetName():gsub("2", ""))
	end
	local comparemode = WF.EnvView[s]
	if FindInTable(pane, WF.WFCentricPanes) then comparemode = "Waterfall"
	elseif FindInTable(pane, WF.ITGCentricPanes) then comparemode = "ITG" end
	local comparetype = WF.GraphView[s]
	if pane:find("Timing") then comparetype = "Scatterplot" end

	actor:visible(comparemode == mode and comparetype == graphtype)
end

return Def.ActorFrame{
	InitCommand=function(self) self:y(_screen.cy + 124) end,

	-- Draw a Quad behind the GraphDisplay (lifebar graph) and Judgment ScatterPlot
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(GraphWidth, GraphHeight):diffuse(color("#101519")):vertalign(top)
		end
	},

	-- density graph
	LoadActor("./DensityGraph.lua", {player=player, GraphWidth=GraphWidth, GraphHeight=GraphHeight} ),

	-- use custom life graphs; don't draw graphdisplay
	LoadActor("./LifeGraphs.lua", {player=player, GraphWidth=GraphWidth, GraphHeight=GraphHeight} )..{
		InitCommand = function(self)
			ShowOrHideGraph(self, "Waterfall", "Life")
		end,
		EvalPaneChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "Waterfall", "Life", args)
		end,
		GraphViewChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "Waterfall", "Life", args)
		end,
		DummyEvalPaneChangedMessageCommand = function(self, args)
			if args.pn ~= pn then return end
			self:finishtweening()
			local pane = WF.EvalPanes[pn][args.activepane]
			if pane and (FindInTable(pane:GetName(),WF.ITGCentricPanes) or pane:GetName() == "Timing") then
				self:queuecommand("Hide")
			else 
				self:queuecommand("Show")
			end
		end,
		ShowCommand = function(self)
			self:visible(true)
		end,
		HideCommand = function(self)
			self:visible(false)
		end
	},

	-- itg life graph
	LoadActor("./ITGLifeGraph.lua", player)..{
		InitCommand = function(self)
			ShowOrHideGraph(self, "ITG", "Life")
		end,
		EvalPaneChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "ITG", "Life", args)
		end,
		GraphViewChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "ITG", "Life", args)
		end,
		DummyEvalPaneChangedMessageCommand = function(self, args)
			if args.pn ~= pn then return end
			self:finishtweening()
			local pane = WF.EvalPanes[pn][args.activepane]
			if pane and (not FindInTable(pane:GetName(),WF.ITGCentricPanes)) then
				self:queuecommand("Hide")
			else 
				self:queuecommand("Show")
			end
		end,
		ShowCommand = function(self)
			self:visible(true)
		end,
		HideCommand = function(self)
			self:visible(false)
		end
	},

	-- standard scatterplot
	Def.ActorFrame{
		InitCommand = function(self)
			self:draworder(60)
			ShowOrHideGraph(self, "Waterfall", "Scatterplot")
		end,
		EvalPaneChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "Waterfall", "Scatterplot", args)
		end,
		GraphViewChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "Waterfall", "Scatterplot", args)
		end,

		Def.Quad{
			InitCommand=function(self)
				self:zoomto(GraphWidth, GraphHeight):diffuse(color("#101519")):vertalign(top)
			end
		},

		LoadActor("./ScatterPlot.lua", {player=player, GraphWidth=GraphWidth, GraphHeight=GraphHeight, mode="Waterfall"} )
	},

	-- itg scatterplot
	Def.ActorFrame{
		InitCommand = function(self)
			self:draworder(60)
			ShowOrHideGraph(self, "ITG", "Scatterplot")
		end,
		EvalPaneChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "ITG", "Scatterplot", args)
		end,
		GraphViewChangedMessageCommand = function(self, args)
			ShowOrHideGraph(self, "ITG", "Scatterplot", args)
		end,

		Def.Quad{
			InitCommand=function(self)
				self:zoomto(GraphWidth, GraphHeight):diffuse(color("#101519")):vertalign(top)
			end
		},

		LoadActor("./ScatterPlot.lua", {player=player, GraphWidth=GraphWidth, GraphHeight=GraphHeight, mode="ITG"} )
	}
}