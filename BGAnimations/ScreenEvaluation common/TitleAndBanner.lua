local path = "/"..THEME:GetCurrentThemeDirectory().."Graphics/_FallbackBanners/Arrows"
local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()

local banner = {
	directory = (FILEMAN:DoesFileExist(path) and path or THEME:GetPathG("","_FallbackBanners/Arrows")),
	width = 418,
	height = 164,
	zoom = 0.5,
}

local y_offset = 40


local af = Def.ActorFrame{ InitCommand=function(self) self:xy(_screen.cx, y_offset) end }

if SongOrCourse and SongOrCourse:HasBanner() then
	--song or course banner, if there is one
	af[#af+1] = Def.Banner{
		Name="Banner",
		InitCommand=function(self)
			if GAMESTATE:IsCourseMode() then
				self:LoadFromCourse( GAMESTATE:GetCurrentCourse() )
			else
				self:LoadFromSong( GAMESTATE:GetCurrentSong() )
			end
			self:setsize(banner.width, 164):zoom(banner.zoom):vertalign("top")
		end,
	}
else
	--fallback banner
	af[#af+1] = LoadActor(banner.directory .. "/banner" .. SL.DefaultColor .. " (doubleres).png")..{
		InitCommand=function(self) self:zoom(banner.zoom):vertalign("top") end
	}
end

-- quad behind the song info text
af[#af+1] = Def.Quad{
	InitCommand=function(self) self:y(banner.height*banner.zoom):vertalign("top"):diffuse(0,0,0,0.8)
		:setsize(banner.width,86):zoom(banner.zoom) end,
}

-- song/course info texts
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		local songtitle = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse():GetDisplayFullTitle()) or GAMESTATE:GetCurrentSong():GetDisplayFullTitle()
		if songtitle then self:settext(songtitle):zoom(0.8):maxwidth(banner.width*banner.zoom*(1/0.8))
						  :vertalign("top"):y(banner.height*banner.zoom+1) end
	end
}
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand = function(self)
		local artist = (not GAMESTATE:IsCourseMode()) and GAMESTATE:GetCurrentSong():GetDisplayArtist()
		if artist then self:settext(artist):zoom(0.65):maxwidth(banner.width*banner.zoom*(1/0.65)):vertalign("top")
					   :y(banner.height*banner.zoom+15) end
	end
}
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self) self:zoom(0.65):xy(-banner.width*banner.zoom*0.5+4,banner.height*banner.zoom+35)
							   :horizalign("left"):maxwidth(banner.width*0.5) end,
	OnCommand=function(self)
		-- FIXME: the current layout of ScreenEvaluation doesn't accommodate split BPMs
		--        so this currently uses the MasterPlayer's BPM values
		local bpms = StringifyDisplayBPMs()
		local MusicRate = SL.Global.ActiveModifiers.MusicRate
		if  MusicRate ~= 1 then
			-- format a string like "BPM: 150 - 300 (1.5x Music Rate)"
			self:settext( ("BPM: %s (%gx %s)"):format(bpms, MusicRate, THEME:GetString("OptionTitles", "MusicRate")) )
		else
			-- format a string like "BPM: 100 - 200"
			self:settext( ("BPM: %s"):format(bpms))
		end
	end
}
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self) self:zoom(0.65):xy(banner.width*banner.zoom*0.5-4,banner.height*banner.zoom+35)
		:horizalign("right") end,
	OnCommand = function(self)
		local seconds
		if not GAMESTATE:IsCourseMode() then
			seconds = GAMESTATE:GetCurrentSong():MusicLengthSeconds()
		else
			local trail = GAMESTATE:GetCurrentTrail(GAMESTATE:GetMasterPlayerNumber())
			if trail then
				seconds = TrailUtil.GetTotalSeconds(trail)
			end
		end
		if seconds then
			seconds = seconds / SL.Global.ActiveModifiers.MusicRate
			-- longer than 1 hour in length
			if seconds > 3600 then
				-- format to display as H:MM:SS
				self:settext(math.floor(seconds/3600) .. ":" .. SecondsToMMSS(seconds%3600))
			else
				-- format to display as M:SS
				self:settext(SecondsToMSS(seconds))
			end
		else
			self:settext("")
		end
	end
}

return af