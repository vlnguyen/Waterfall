return Def.Actor{
	OnCommand=function(self)
		SL.Global.Stages.Stats[SL.Global.Stages.PlayedThisGame + 1] = {
			song = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong(),
			TimingWindows = SL.Global.ActiveModifiers.TimingWindows,
			ErrorWindow = SL.Global.ActiveModifiers.TimingWindows[5],
			W5Size = PREFSMAN:GetPreference("TimingWindowSecondsW5"),
			MusicRate = SL.Global.ActiveModifiers.MusicRate
		}
	end
}