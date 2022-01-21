-- this is an overly simplified copy of ScreenSelectProfile that does nothing except assign the selected ID
-- to WF.ModifyingProfileID for use for the customize profile menu
WF.ModifyingProfileID = ""

-- this menu only supports one player
local mpn = GAMESTATE:GetMasterPlayerNumber()

-- a table of profile data (highscore name, most recent song, mods, etc.)
-- indexed by "ProfileIndex" (provided by engine)
local profile_data = LoadActor("../ScreenSelectProfile underlay/PlayerProfileData.lua")

local scroller = setmetatable({disable_wrapping=true}, sick_wheel_mt)

-- ----------------------------------------------------

local HandleStateChange = function(self, Player)
	-- this function seems basically unnecessary for what i'm doing
	local frame = self:GetChild(ToEnumShortString(mpn)..'Frame')

	local scrollerframe = frame:GetChild('ScrollerFrame')
	local dataframe = scrollerframe:GetChild('DataFrame')
	local scroller = scrollerframe:GetChild('Scroller')

	local seltext = frame:GetChild('SelectedProfileText')

	-- using local profile
	scrollerframe:visible(true)
	--seltext:visible(true)
end

-- ----------------------------------------------------

local invalid_count = 0

local t = Def.ActorFrame {

	InitCommand=function(self) self:queuecommand("Stall") end,
	StallCommand=function(self)
		-- FIXME: Stall for 0.5 seconds so that the Lua InputCallback doesn't get immediately added to the screen.
		-- It's otherwise possible to enter the screen with MenuLeft/MenuRight already held and firing off events,
		-- which causes the sick_wheel of profile names to not display.  I don't have time to debug it right now.
		self:sleep(0.5):queuecommand("InitInput")
	end,
	InitInputCommand=function(self) SCREENMAN:GetTopScreen():AddInputCallback(
		LoadActor("./Input.lua", {af=self, Scroller=scroller, ProfileData=profile_data}) ) end,

	-- the OffCommand will have been queued, when it is appropriate, from ./Input.lua
	-- sleep for 0.5 seconds to give the PlayerFrames time to tween out
	-- and queue a call to Finish() so that the engine can wrap things up
	OffCommand=function(self)
		self:sleep(0.5):queuecommand("Finish")
	end,
	FinishCommand=function(self)
		-- all we care about is assigning the id to WF.ModifyingProfileID
		local info = scroller:get_info_at_focus_pos()
		--local index = type(info)=="table" and info.index or 0
		local profileid = type(info) == "table" and info.profileid
		WF.ModifyingProfileID = profileid or ""
		--SM(WF.ModifyingProfileID)
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
	end,
	

	-- various events can occur that require us to reassess what we're drawing
	OnCommand=function(self) self:queuecommand('Update') end,
	StorageDevicesChangedMessageCommand=function(self) self:queuecommand('Update') end,
	PlayerJoinedMessageCommand=function(self, params) self:playcommand('Update', {player=params.Player}) end,
	PlayerUnjoinedMessageCommand=function(self, params) self:playcommand('Update', {player=params.Player}) end,

	-- there are several ways to get here, but if we're here, we'll just
	-- punt to HandleStateChange() to reassess what is being drawn
	UpdateCommand=function(self, params)
		HandleStateChange(self, mpn)
	end,

	-- sounds
	LoadActor( THEME:GetPathS("Common", "start") )..{
		StartButtonMessageCommand=function(self) self:play() end
	},
	LoadActor( THEME:GetPathS("ScreenSelectMusic", "select down") )..{
		BackButtonMessageCommand=function(self) self:play() end
	},
	LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{
		DirectionButtonMessageCommand=function(self)
			self:play()
			if invalid_count then invalid_count = 0 end
		end
	},
	LoadActor( THEME:GetPathS("Common", "invalid") )..{
		InvalidChoiceMessageCommand=function(self)
			self:play()
			if invalid_count then
				invalid_count = invalid_count + 1
				if invalid_count >= 10 then MESSAGEMAN:Broadcast("What"); invalid_count = nil end
			end
		end
	},
	LoadActor( THEME:GetPathS("", "what.ogg") )..{
		WhatMessageCommand=function(self) self:play() end
	}
}

-- top mask
t[#t+1] = Def.Quad{
	InitCommand=function(self) self:horizalign(left):vertalign(bottom):setsize(540,50):xy(_screen.cx-self:GetWidth()/2, _screen.cy-110):MaskSource() end
}
-- bottom mask
t[#t+1] = Def.Quad{
	InitCommand=function(self) self:horizalign(left):vertalign(top):setsize(540,120):xy(_screen.cx-self:GetWidth()/2, _screen.cy+111):MaskSource() end
}

-- load PlayerFrame
t[#t+1] = LoadActor("../ScreenSelectProfile underlay/PlayerFrame.lua", {Player=mpn, Scroller=scroller, ProfileData=profile_data, NoGuest=true})

LoadActor("../ScreenSelectProfile underlay/JudgmentGraphicPreviews.lua", {af=t, profile_data=profile_data})
LoadActor("../ScreenSelectProfile underlay/NoteSkinPreviews.lua", {af=t, profile_data=profile_data})
LoadActor("../ScreenSelectProfile underlay/Avatars.lua", {af=t, profile_data=profile_data})

return t