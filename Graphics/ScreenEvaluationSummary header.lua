local af = Def.ActorFrame{}

af[#af+1] = LoadActor( THEME:GetPathG("", "_header.lua") )

af[#af+1] = LoadFont("_wendy small")..{
	Name="SummaryText",
	Text=GAMESTATE:IsCourseMode() and "Marathon" or "Standard",
	InitCommand=function(self)
		self:diffusealpha(0):zoom( WideScale(0.5,0.6)):halign(1):y(15)

		-- move the text further left if MenuTimer is enabled
		if PREFSMAN:GetPreference("MenuTimer") then
			self:x(_screen.w - 70)
		else
			self:x(_screen.w - 10)
		end
	end,
	OnCommand=function(self)
		self:sleep(0.1):decelerate(0.33):diffusealpha(1)
	end
}

return af