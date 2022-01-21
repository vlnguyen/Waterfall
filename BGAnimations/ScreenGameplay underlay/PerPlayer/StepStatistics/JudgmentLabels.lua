local player = ...
local pn = ToEnumShortString(player)

local mode = (not SL[pn].ActiveModifiers.SimulateITGEnv) and "Waterfall" or "ITG"
local faplus = (SL[pn].ActiveModifiers.FAPlus > 0)

-- catch this here too (not necessary but might as well)
if mode == "Waterfall" and SL[pn].ActiveModifiers.FAPlus == 0.015 then
	SL[pn].ActiveModifiers.FAPlus = 0
	faplus = false
end

local TapNoteScores = { Types={'W1', 'W2', 'W3', 'W4', 'W5', 'Miss'}, Names={} }
local tns_string = (mode ~= "ITG") and "TapNoteScore" or "TapNoteScoreITG"
-- get TNS names localized to the current language
for i, judgment in ipairs(TapNoteScores.Types) do
	TapNoteScores.Names[#TapNoteScores.Names+1] = THEME:GetString(tns_string, judgment)
end

local RadarCategories = {
	THEME:GetString("ScreenEvaluation", 'Holds'),
	THEME:GetString("ScreenEvaluation", 'Mines'),
	THEME:GetString("ScreenEvaluation", 'Rolls')
}

local row_height = 28
local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)

if mode == "ITG" and ((not windows[5]) or (math.abs(PREFSMAN:GetPreference("TimingWindowSecondsW5") - 
	(SL.Preferences.ITG.TimingWindowSecondsW3 + SL.Preferences.ITG.TimingWindowAdd)) < 0.00001)) then
	windows = {true,true,true,false,false}
end
if mode == "ITG" and WF.SelectedErrorWindowSetting == 1 then windows[4] = false end

local af = Def.ActorFrame{}

--  labels: W1, W2, W3, W4, W5, Miss
for i, label in ipairs(TapNoteScores.Names) do

	-- no need to add BitmapText actors for TimingWindows that were turned off
	if windows[i] or i==#TapNoteScores.Names then
		local labeltouse = label:upper()

		if mode == "ITG" and ((i == 3 and PREFSMAN:GetPreference("TimingWindowSecondsW5") <= SL.Preferences.Waterfall.TimingWindowSecondsW4)
		or (i == 5 and math.abs(PREFSMAN:GetPreference("TimingWindowSecondsW5") -
		(SL.Preferences.ITG.TimingWindowSecondsW5 + SL.Preferences.ITG.TimingWindowAdd)) >= 0.00001)) then
			labeltouse = labeltouse.." *"
		end

		-- push down for FA+
		local h = (i-1)*row_height - 226
		if (faplus) and i > 1 then h = h + row_height end

		af[#af+1] = LoadFont("Common Normal")..{
			Text=labeltouse,
			InitCommand=function(self) self:zoom(0.833):horizalign(right):maxwidth(72) end,
			BeginCommand=function(self)
				self:x(80):y(h)
				    :diffuse( SL.JudgmentColors[mode][i] )
			end
		}

		-- for FA+, add another row for white W1
		if (faplus) and i == 1 then
			af[#af+1] = LoadFont("Common Normal")..{
				Text=labeltouse,
				InitCommand=function(self) self:zoom(0.833):horizalign(right):maxwidth(72) end,
				BeginCommand=function(self)
					self:x(80):y(row_height - 226)
						:diffuse( Color.White )
				end
			}
		end
	end
end

-- labels: holds, mines, rolls
for i, label in ipairs(RadarCategories) do
	af[#af+1] = LoadFont("Common Normal")..{
		Text=label,
		InitCommand=function(self) self:zoom(0.833):horizalign(right) end,
		BeginCommand=function(self)
			self:x(-94):y((i-1)*row_height - 143)
		end
	}
end

-- fa+ label
if faplus then
	local ms = string.format("%d", SL[pn].ActiveModifiers.FAPlus * 1000)
	af[#af+1] = LoadFont("Common Normal")..{
		Text="FA+ ("..ms.."ms)",
		InitCommand=function(self) self:zoom(0.833) end,
		BeginCommand=function(self)
			self:x(-48):y(3*row_height - 136)
		end
	}
end

return af