local args = ...
local player = args.player
local oldhs, newhs
local iscourse = GAMESTATE:IsCourseMode()

if args.hsdata then
	oldhs = (not iscourse) and args.hsdata.PlayerSongStats_Old or args.hsdata.PlayerCourseStats_Old
	newhs = (not iscourse) and args.hsdata.PlayerSongStats or args.hsdata.PlayerCourseStats
end

local pn = tonumber(player:sub(-1))

-- [TODO] assigning to p1 color for now; want it to be the same for both players
-- (this text will be replaced in the end anyway)
local c = PlayerColor(PLAYER_1)

-- logic for now is that if evaluation is reached, always go to name entry screen
-- really, this does nothing, because name entry is removed entirely
SL["P"..pn].HighScores.EnteringName = true

-- only thing we care about here is the difference between score and old high score
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local score = math.floor(pss:GetPercentDancePoints() * 10000)
local pb = (newhs) and ((not oldhs) or (score >= oldhs.BestPercentDP))
local itgscore = math.floor(tonumber(WF.ITGScore[pn]) * 100)
local pb_itg = (newhs) and ((not oldhs) or (itgscore >= oldhs.BestPercentDP_ITG))

if pb or pb_itg then	

	local t = Def.ActorFrame{
		Name = "RecordText",
		InitCommand=function(self) self:zoom(0.225) end,
		OnCommand=function(self)
			self:x( (player == PLAYER_1 and -1 or 1) * WideScale(2,34) )
			self:y( 50 )
		end
	}

	if pb then
		t[#t+1] = LoadFont("_wendy small")..{
			Text="PERSONAL BEST",
			InitCommand=function(self)
				if FindInTable(WF.DefaultPane[pn], WF.ITGCentricPanes) then
					self:visible(false)
				end
				self:y(24):diffuse(c)
			end,
			EvalPaneChangedMessageCommand = function(self, args)
				if args.pn ~= pn then return end
				local pane = WF.EvalPanes[pn][args.activepane]
				if pane and FindInTable(pane:GetName(), WF.ITGCentricPanes) then
					self:visible(false)
				elseif pane and FindInTable(pane:GetName(), WF.WFCentricPanes) then
					self:visible(true)
				else
					if SL["P"..pn].ActiveModifiers.SimulateITGEnv then
						self:visible(not SL["P"..pn].ActiveModifiers.SimulateITGEnv)
					end
				end
			end
		}
	end

	if pb_itg then
		t[#t+1] = LoadFont("_wendy small")..{
			Text="PERSONAL BEST",
			InitCommand=function(self)
				if not FindInTable(WF.DefaultPane[pn], WF.ITGCentricPanes) then
					self:visible(false)
				end
				self:y(24):diffuse(c)
			end,
			EvalPaneChangedMessageCommand = function(self, args)
				if args.pn ~= pn then return end
				local pane = WF.EvalPanes[pn][args.activepane]
				if pane and FindInTable(pane:GetName(), WF.ITGCentricPanes) then
					self:visible(true)
				elseif pane and FindInTable(pane:GetName(), WF.WFCentricPanes) then
					self:visible(false)
				else
					if SL["P"..pn].ActiveModifiers.SimulateITGEnv then
						self:visible(SL["P"..pn].ActiveModifiers.SimulateITGEnv)
					end
				end
			end
		}
	end

	return t
end