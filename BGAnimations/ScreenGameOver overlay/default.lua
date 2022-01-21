local Players = GAMESTATE:GetHumanPlayers();

-- dumb hack (see WF-Profiles.lua)
WF.SwitchPrefixFlag = true
WF.DummySave(Players)

local t = Def.ActorFrame{
	LoadFont("_wendy white")..{
		Text="GAME",
		InitCommand=function(self) self:xy(_screen.cx,_screen.cy-40):croptop(1):fadetop(1):zoom(1.2):shadowlength(1) end,
		OnCommand=function(self) self:decelerate(0.5):croptop(0):fadetop(0):glow(1,1,1,1):decelerate(1):glow(1,1,1,1) end,
		OffCommand=function(self) self:accelerate(0.5):fadeleft(1):cropleft(1) end
	},
	LoadFont("_wendy white")..{
		Text="OVER",
		InitCommand=function(self) self:xy(_screen.cx,_screen.cy+40):croptop(1):fadetop(1):zoom(1.2):shadowlength(1) end,
		OnCommand=function(self) self:decelerate(0.5):croptop(0):fadetop(0):glow(1,1,1,1):decelerate(1):glow(1,1,1,1) end,
		OffCommand=function(self) self:accelerate(0.5):fadeleft(1):cropleft(1) end
	},

	--Player 1 Stats BG
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(160,_screen.h):xy(80, _screen.h/2):diffuse(color("#00000099"))
		end,
	},

	--Player 2 Stats BG
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(160,_screen.h):xy(_screen.w-80, _screen.h/2):diffuse(color("#00000099"))
		end,
	}
}

for player in ivalues(Players) do

	local line_height = 60
	local middle_line_y = 284
	local x_pos = player == PLAYER_1 and 80 or _screen.w-80
	local PlayerStatsAF = Def.ActorFrame{ Name="PlayerStatsAF_"..ToEnumShortString(player) }
	local stats
	local pn = tonumber(player:sub(-1))
	local avpath = THEME:GetPathG("", "_profilecard/fallbackav.png")
	local pname = "Guest"

	-- first, check if this player is using a profile (local or MemoryCard)
	if PROFILEMAN:IsPersistentProfile(player) then
		-- set avatar path
		local cavpath = PROFILEMAN:GetProfileDir("ProfileSlot_Player"..pn).."/avatar.png"
		if FILEMAN:DoesFileExist(cavpath) then avpath = cavpath end

		-- set name
		pname = PROFILEMAN:GetProfile(player):GetDisplayName()

		-- PlayerStatsWithProfile will now return an actorframe that contains "session achievements"
		PlayerStatsAF[#PlayerStatsAF+1] = LoadActor("PlayerStatsWithProfile.lua", player)..{
			InitCommand = function(self) self:xy(x_pos, 132) end
		}

	end

	-- name and avatar at top
	PlayerStatsAF[#PlayerStatsAF+1] = LoadFont("Common Normal")..{
		Text = pname,
		InitCommand = function(self) self:xy(x_pos, 20):zoom(1.2):maxwidth(110/1.2) end
	}
	local subtitle = (WF.ProfileCardSubtitle[pn]) and (WF.ProfileCardSubtitle[pn] ~= "")
	PlayerStatsAF[#PlayerStatsAF+1] = LoadFont("Common Normal")..{
		Text = WF.ProfileCardSubtitle[pn] or "",
		InitCommand = function(self) self:xy(x_pos, 40):zoom(0.8):maxwidth(110/0.8) end
	}
	PlayerStatsAF[#PlayerStatsAF+1] = LoadActor(avpath)..{
		InitCommand = function(self) self:xy(x_pos, 70 + (subtitle and 10 or 0)):zoomto(64,64) end
	}

	-- retrieve general gameplay session stats for which a profile is not needed
	stats = LoadActor("PlayerStatsWithoutProfile.lua", player)

	-- loop through those stats, adding them to the ActorFrame for this player as BitmapText actors
	for i,stat in ipairs(stats) do
		PlayerStatsAF[#PlayerStatsAF+1] = LoadFont("Common Normal")..{
			Text=stat,
			InitCommand=function(self)
				self:diffuse(PlayerColor(player))
					:xy(x_pos, (line_height*i) + middle_line_y)
					:maxwidth(150)
			end
		}
	end

	t[#t+1] = PlayerStatsAF
end

return t