local args = ...
local af = args.af
local scroller = args.Scroller
local profile_data = args.ProfileData

-- we need to calculate how many dummy rows the scroller was "padded" with
-- (to achieve the desired transform behavior since I am not mathematically
-- perspicacious enough to have done so otherwise).
-- we'll use index_padding to get the correct info out of profile_data.
local index_padding = 0
for profile in ivalues(profile_data) do
	if profile.index == nil or profile.index <= 0 then
		index_padding = index_padding + 1
	end
end

local AutoStyle = "none"
local mpn = GAMESTATE:GetMasterPlayerNumber()

local Handle = {}

Handle.Start = function(event)
	local topscreen = SCREENMAN:GetTopScreen()
	-- play the StartButton sound
	MESSAGEMAN:Broadcast("StartButton")
	-- and queue the OffCommand for the entire screen
	topscreen:queuecommand("Off"):sleep(0.4)
end
Handle.Center = Handle.Start


Handle.MenuLeft = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
		local info = scroller:get_info_at_focus_pos()
		local index = type(info)=="table" and info.index or 0

		if index - 1 >= 1 then
			MESSAGEMAN:Broadcast("DirectionButton")
			scroller:scroll_by_amount(-1)

			local data = profile_data[index+index_padding-1]
			local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
			frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
			frame:playcommand("Set", data)
		end
	end
end
Handle.MenuUp = Handle.MenuLeft
Handle.DownLeft = Handle.MenuLeft

Handle.MenuRight = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
		local info = scroller:get_info_at_focus_pos()
		local index = type(info)=="table" and info.index or 0

		if index+1 <= PROFILEMAN:GetNumLocalProfiles() then
			MESSAGEMAN:Broadcast("DirectionButton")
			scroller:scroll_by_amount(1)

			local data = profile_data[index+index_padding+1]
			local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
			frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
			frame:playcommand("Set", data)
		end
	end
end
Handle.MenuDown = Handle.MenuRight
Handle.DownRight = Handle.MenuRight

Handle.Back = function(event)
	SCREENMAN:GetTopScreen():Cancel()
end


local InputHandler = function(event)
	if not event or not event.button then return false end
	--if (AutoStyle=="single" or AutoStyle=="double") and event.PlayerNumber ~= mpn then return false	end

	if event.type ~= "InputEventType_Release" then
		if Handle[event.GameButton] then Handle[event.GameButton](event) end
	end
end

return InputHandler