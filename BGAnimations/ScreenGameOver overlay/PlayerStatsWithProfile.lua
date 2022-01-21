local player = ...
local pn = tonumber(player:sub(-1))
local profile = PROFILEMAN:GetProfile(player)

local af = Def.ActorFrame{}

if not WF.PlayerProfileStats[pn] then return af end

local lineheight = 20

af[#af+1] = LoadFont("Common Normal")..{
	Text = "Session Achievements",
	InitCommand = function(self) self:zoom(0.9) end
}

for i, v in ipairs(WF.PlayerProfileStats[pn].SessionAchievements) do
	af[#af+1] = LoadFont("Common Normal")..{
		Text = WF.ClearTypes[i],
		InitCommand = function(self) self:horizalign("left"):xy(-70, 24 + (i-1)*lineheight):diffuse(WF.ClearTypeColor(i))
			:zoom(0.9) end
	}
	af[#af+1] = LoadFont("Common Normal")..{
		Text = tostring(v),
		InitCommand = function(self) self:horizalign("right"):xy(70, 24 + (i-1)*lineheight):zoom(0.9) end
	}
end

return af