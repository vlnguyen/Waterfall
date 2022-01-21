local player = ...

local LetterGradesAF
local playerStats
local steps, meter, difficulty, stepartist, grade, score, itg, faplus, fapluscount, cleartype
local TNSTypes = { 'W1', "W1-", 'W2', 'W3', 'W4', 'W5', 'Miss' }

-- variables for positioning and horizalign, dependent on playernumber
local col1x, col2x, gradex, align1, align2
if player == PLAYER_1 then
	col1x =  -90
	col2x =  -_screen.w/2.5
	gradex = -_screen.w/3.33
	align1 = right
	align2 = left
elseif player == PLAYER_2 then
	col1x = 90
	col2x = _screen.w/2.5
	gradex = _screen.w/3.33
	align1= left
	align2 = right
end

local af = Def.ActorFrame{
	OnCommand=function(self)
		LetterGradesAF = self:GetParent():GetParent():GetChild("LetterGradesAF")
	end,
	DrawStageCommand=function(self, params)
		playerStats = SL[ToEnumShortString(player)].Stages.Stats[params.StageNum]

		if playerStats then
			itg = playerStats.itg
			steps = playerStats.steps
	 		meter = playerStats.meter
	 		difficulty = playerStats.difficulty
	 		stepartist = playerStats.stepartist
	 		grade = (not itg) and playerStats.grade or playerStats.grade_itg
			cleartype = playerStats.cleartype
			score = (not itg) and playerStats.score or playerStats.score_itg
			faplus = playerStats.faplus
			fapluscount = playerStats.fapluscount
		end
	end
}

--percent score
af[#af+1] = LoadFont("_wendy small")..{
	InitCommand=function(self) self:zoom(0.5):horizalign(align1):x(col1x):y(-38) end,
	DrawStageCommand=function(self)
		if playerStats and score then

			-- trim off the % symbol
			-- kinda weird/inconsistent but if itg, we actually send the properly formatted score string as is
			if not itg then
				score = string.sub(FormatPercentScore(score),1,-2)
			end

			-- If the score is < 10.00% there will be leading whitespace, like " 9.45"
			-- trim that too, so PLAYER_2's scores align properly.
			score = score:gsub(" ", "")
			self:settext(score):diffuse(Color.White)

			if ((not itg) and cleartype == WF.ClearTypes.Fail) or ((itg) and grade == "ITGGrade_Failed") then
				self:diffuse(Color.Red)
			end
		else
			self:settext("")
		end
	end
}

-- difficulty meter
af[#af+1] = LoadFont("_wendy small")..{
	InitCommand=function(self) self:zoom(0.4):horizalign(align1):x(col1x):y(-13) end,
	DrawStageCommand=function(self)
		if playerStats and meter then
			self:diffuse(DifficultyColor(difficulty)):settext(meter)
		else
			self:settext("")
		end
	end
}

-- credits
for i = 1, 3 do
	local cybase = 32 - (i-1)*13
	af[#af+1] = LoadFont("Common Normal")..{
		InitCommand=function(self) self:zoom(0.65):horizalign(align1):x(col1x):y(cybase):maxwidth(108/0.65) end,
		DrawStageCommand=function(self)
			if playerStats then
				self:y(cybase - 13 * (3 - #playerStats.credittable))
				self:settext(playerStats.credittable[i] or "")
			else
				self:settext("")
			end
		end
	}
end

-- letter grade
af[#af+1] = Def.ActorProxy{
	InitCommand=function(self)
		self:zoom(WideScale(0.275,0.3)):x( WideScale(194,250) * (player==PLAYER_1 and -1 or 1) ):y(-6)
	end,
	DrawStageCommand=function(self)
		if playerStats and grade then
			self:SetTarget( LetterGradesAF:GetChild(grade) ):visible(true)
		else
			self:visible(false)
		end
	end
}

-- fa+
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand = function(self) self:xy(WideScale(194,250) * (player==PLAYER_1 and -1 or 1), -44):zoom(0.75) end,
	DrawStageCommand = function(self)
		if (not playerStats) or faplus == 0 then self:settext("") return end
		self:settext(string.format("FA+ %dms", faplus * 1000))
	end
}

-- clear type
af[#af+1] = Def.Quad{
	InitCommand = function(self) self:xy(WideScale(194,250) * (player==PLAYER_1 and -1 or 1), 28):zoomto(86, 14)
		self:diffuse(0,0,0,0.8) end,
	DrawStageCommand = function(self) if itg or (not playerStats) then self:visible(false) else self:visible(true) end end
}
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand = function(self) self:xy(WideScale(194,250) * (player==PLAYER_1 and -1 or 1), 28):zoom(0.7) end,
	DrawStageCommand = function(self)
		if itg or (not playerStats) then self:settext("") return end
		self:settext(WF.ClearTypes[cleartype])
		self:diffuse(WF.ClearTypeColor(cleartype))
	end
}



-- numbers
for i=1,#TNSTypes do
	local ybase = i*13 - 50
	af[#af+1] = LoadFont("_wendy small")..{
		InitCommand=function(self)
			self:zoom(0.28):horizalign(align2):x(col2x):y(ybase)
		end,
		DrawStageCommand=function(self, params)
			local mode = (not itg) and "Waterfall" or "ITG"
			local judgments
			if playerStats then
				judgments = (not itg) and playerStats.judgments or playerStats.judgments_itg
				if (i == 2) and (faplus) and faplus == 0 then
					self:settext("")
					return
				end
			end
			
			if judgments then
				-- need to separate "white" if fa+ was used
				local val = judgments[TNSTypes[i]] or (judgments["W1"] - playerStats.fapluscount)
				if i == 1 and faplus > 0 then val = fapluscount end

				local windowind = i
				if i > 1 then windowind = windowind - 1 end

				local sety = ybase
				if faplus > 0 then sety = ybase - 8 end
				if faplus == 0 and windowind > 1 then sety = sety - 13 end
				self:y(sety)

				if not (faplus > 0 and i == 2) then self:diffuse( SL.JudgmentColors[mode][windowind] ) end
				
				if val then self:settext(val) end

				-- determine windows to show
				local windows = {true, true, true, true, true}
				local w5 = SL.Global.Stages.Stats[params.StageNum].W5Size
				if w5 < SL.Preferences.Waterfall.TimingWindowSecondsW5 - 0.005 then
					windows[5] = false
					windows[4] = (not itg)
				end
				if itg and (math.abs(w5 - SL.Preferences.Waterfall.TimingWindowSecondsW5) < 0.001) then
					windows[4] = false
				end

				self:visible( windows[windowind] or i==#TNSTypes )
			else
				self:settext("")
			end
		end
	}
end

return af