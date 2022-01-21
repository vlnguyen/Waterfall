local player = ...
local pn = ToEnumShortString(player)
local p = tonumber(player:sub(-1))
local mods = SL[pn].ActiveModifiers

if not mods.SubtractiveScoring then return end

local useitg = mods.SimulateITGEnv
local mode = (not useitg) and "Waterfall" or "ITG"

-- -----------------------------------------------------------------------

local metrics = SL.Metrics.Waterfall

local dpdiff = {
	-- numbers above 10 actually don't matter here
	ITG =       {W1 = 0, W2 = 1, W3 = 3, W4 = 5, W5 = 10, Miss = 17, HitMine = 6, Held = 0, LetGo = 5},
	Waterfall = {W1 = 0, W2 = 1, W3 = 4, W4 = 7, W5 = 10, Miss = 10, HitMine = 3, Held = 0, LetGo = 6}
}
local dplost = 0

local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

-- which font should we use for the BitmapText actor?
-- [TODO] this font will probably not be " wendy " in the end. sorry wendy :(
local font = "_wendy small"

-- -----------------------------------------------------------------------

-- the BitmapText actor
local bmt = LoadFont(font)

bmt.InitCommand=function(self)
	self:diffuse(color("#ff55cc"))
	self:zoom(0.35):shadowlength(1):horizalign(center)

	local width = GetNotefieldWidth()
	local NumColumns = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
	-- mirror image of MeasureCounter.lua
	self:xy( GetNotefieldX(player) + (width/NumColumns), _screen.cy - 55 )

	-- Fix overlap issues when MeasureCounter is centered
	-- since in this case we don't need symmetry.
	if (mods.MeasureCounterLeft == false) then
		self:horizalign(left)
		-- nudge slightly left (15% of the width of the bitmaptext when set to "100.00%")
		self:settext("100.00%"):addx( -self:GetWidth()*self:GetZoom() * 0.15 )
		self:settext("")
	end
end

bmt.JudgmentMessageCommand=function(self, params)
	if player == params.Player then
		tns = ToEnumShortString(params.TapNoteScore)
		-- compensate for itg
		if useitg and params.TapNoteOffset and (tns == "W1" or tns == "W2" or tns == "W3" or tns == "W4" or tns == "W5") then
			tns = "W"..DetermineTimingWindow(params.TapNoteOffset, "ITG")
		end
		hns = params.HoldNoteScore and ToEnumShortString(params.HoldNoteScore)
		
		local judgment = hns or tns
		if not dpdiff[mode][judgment] then return end

		dplost = dplost + dpdiff[mode][judgment]
		if dplost == 0 then return end

		if dplost < 10 then
			self:settext(string.format("-%d", dplost))
		else
			local possible_dp = (not useitg) and pss:GetPossibleDancePoints() or WF.ITGMaxDP[p]
			local current_possible_dp = (not useitg) and pss:GetCurrentPossibleDancePoints() or WF.ITGCurMaxDP[p]

			-- max to prevent subtractive scoring reading more than -100%
			local dp = (not useitg) and pss:GetActualDancePoints() or WF.ITGDP[p]
			local actual_dp = math.max(dp, 0)

			local score = current_possible_dp - actual_dp
			score = math.floor(((possible_dp - score) / possible_dp) * 10000) / 100

			-- specify percent away from 100%
			self:settext( string.format("-%.2f%%", 100-score) )
		end
	end
end

return bmt
