local t = ...

-- what i'm doing here feels really dumb but i think if i manage the number of judgment fonts availabile it shouldn't
-- be too problematic and will at least work...

local modes = {"Waterfall","ITG"}

for mode in ivalues(modes) do
	for judgment_filename in ivalues( GetJudgmentGraphics(mode == "ITG" and mode or nil) ) do
		if judgment_filename ~= "None" and judgment_filename ~= "Plain Text" then
			local fullfilename = mode == "Waterfall" and judgment_filename or "itg/"..judgment_filename
			t[#t+1] = LoadActor( THEME:GetPathG("", "_judgments/" .. fullfilename) )..{
				Name="JudgmentGraphic_"..StripSpriteHints(judgment_filename)..(mode == "ITG" and "_ITG" or ""),
				InitCommand=function(self)
					self:visible(false):animate(false)
					local num_frames = self:GetNumStates()

					self:setstate(0)
				end
			}
		elseif judgment_filename == "None" and mode == "Waterfall" then
			t[#t+1] = Def.Actor{ Name="JudgmentGraphic_None", InitCommand=function(self) self:visible(false) end }
		elseif judgment_filename ~= "None" then
			t[#t+1] = LoadFont(WF.PlainTextJudgmentFont)..{
				Name = "JudgmentGraphic_Plain Text"..(mode == "ITG" and "_ITG" or ""),
				Text = WF.PlainTextJudgmentNames[mode].W1,
				InitCommand = function(self)
					self:visible(false)
					self:zoom(WF.PlainTextJudgmentBaseZoom)
					self:diffuse(SL.JudgmentColors[mode][1])
				end
			}
		end
	end
end