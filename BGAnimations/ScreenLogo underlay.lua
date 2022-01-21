-- [TODO] will not be using simply __ logo obviously, but arrows will be placeholder for now
local image = "Arrows"
local game = GAMESTATE:GetCurrentGame():GetName()
if game ~= "dance" and game ~= "pump" then
	game = "techno"
end

local t = Def.ActorFrame{}

-- WF logo
af[#af+1] = LoadActor(THEME:GetPathG("", "_logos/WFLogo.png"))..{
	InitCommand=function(self) self:x(2):zoom((SCREEN_WIDTH*2/3)/1486):shadowlength(0.75) end,
	OffCommand=function(self) self:linear(0.5):shadowlength(0) end
}

return t