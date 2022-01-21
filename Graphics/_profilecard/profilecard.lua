local args = ...
local player = args.player
local loweraf = args.loweraf
local pn = tonumber(player:sub(-1))
local profile = PROFILEMAN:GetProfile(player)
local hassubtitle = (WF.ProfileCardSubtitle[pn] ~= "")

local path = "fallbackav.png"
local guestprofile = false
if profile then
    local ppath = PROFILEMAN:GetProfileDir("ProfileSlot_Player"..pn).."/avatar.png"
    if ppath == "/avatar.png" then guestprofile = true end
    if not guestprofile then path = FILEMAN:DoesFileExist(ppath) and ppath or "fallbackav.png" end
else

end

if not loweraf then loweraf = Def.ActorFrame{} end
loweraf.InitCommand = function(self) self:y(24) end

local namezoom = (not hassubtitle) and 1.2 or 1.05

local w = 96
local h = 128

local af = Def.ActorFrame{
    Def.Quad{
        InitCommand = function(self)
            self:zoomto(w, h)
        end
    },
    Def.Quad{
        InitCommand = function(self)
            self:zoomto(w - 2, h - 2)
            self:diffuse(0.1,0.1,0.1,1)
        end
    },
    LoadFont("Common Normal")..{
        Text = (not guestprofile) and profile:GetDisplayName() or "Guest",
        InitCommand = function(self)
            self:y(-h/2 + 13)
            self:zoom(namezoom)
            self:maxwidth((w - 3) / namezoom)
            if hassubtitle then self:addy(-3) end
        end
    },
    LoadFont("Common Normal")..{
        Text = WF.ProfileCardSubtitle[pn],
        InitCommand = function(self)
            self:zoom(0.6)
            self:y(-h/2 + 26)
            self:maxwidth((w-3)/0.6)
        end
    },
    LoadActor(path)..{
        InitCommand = function(self)
            self:zoomto(48,48)
            self:y(-h/2 + 52)
            if hassubtitle then self:addy(4) end
        end
    },
    loweraf,
    LoadFont("Common Normal")..{
        Text = (not guestprofile) and "" or "",
        InitCommand = function(self)
            self:zoom(0.8)
            self:y(44)
        end
    }
}

return af