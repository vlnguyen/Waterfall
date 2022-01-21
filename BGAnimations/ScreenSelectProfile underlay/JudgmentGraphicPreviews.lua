local args = ...
local af = args.af

local already_loaded = {}

for profile in ivalues(args.profile_data) do
	local jname = profile.judgment
	if jname then jname = (profile.itg and "ITG/" or "")..jname end
	if jname ~= nil and jname ~= "" and not FindInTable(jname, already_loaded) then

		if FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."/Graphics/_judgments/"..jname) then
			af[#af+1] = LoadActor(THEME:GetPathG("","_judgments/"..jname))..{
				Name="JudgmentGraphic_"..StripSpriteHints(profile.judgment)..(profile.itg and "ITG" or ""),
				InitCommand=function(self)
					self:y(-50):animate(false)
				end
			}
			table.insert(already_loaded, jname)

		-- based on the way i'm handling judgments by design, this case should never happen, but who knows
		-- what people are gonna do
		elseif FILEMAN:DoesFileExist(THEME:GetCurrentThemeDirectory().."/Graphics/_judgments/ITG/"..profile.judgment) then
			af[#af+1] = LoadActor(THEME:GetPathG("","_judgments/ITG/"..profile.judgment))..{
				Name="JudgmentGraphic_"..StripSpriteHints(profile.judgment),
				InitCommand=function(self) self:y(-50):animate(false)
					-- why is the original Love judgment asset so... not aligned?
					-- it throws the aesthetic off as-is, so fudge a little
					if profile.judgment == "Love 2x6.png" then self:y(-55) end
				end
			}
			table.insert(already_loaded, profile.judgment)

		end
	end
end

af[#af+1] = Def.Actor{ Name="JudgmentGraphic_None", InitCommand=function(self) self:visible(false) end }
af[#af+1] = LoadFont("Common Normal")..{
	Name = "JudgmentGraphic_Plain Text",
	Text = WF.PlainTextJudgmentNames.Waterfall.W1,
	InitCommand = function(self)
		self:y(-50)
		self:zoom(WF.PlainTextJudgmentBaseZoom)
		self:diffuse(SL.JudgmentColors.Waterfall[1])
	end
}
af[#af+1] = LoadFont("Common Normal")..{
	Name = "JudgmentGraphic_Plain TextITG",
	Text = WF.PlainTextJudgmentNames.ITG.W1,
	InitCommand = function(self)
		self:y(-50)
		self:zoom(WF.PlainTextJudgmentBaseZoom)
		self:diffuse(SL.JudgmentColors.ITG[1])
	end
}