local player = ...
local pn = PlayerNumber:Reverse()[player]
local infotable = GetStepsCredit(player)
local currentSteps = GAMESTATE:GetCurrentSteps(player)

local af = Def.ActorFrame{

	-- all this difficulty icon stuff should probably be in its own lua file, but i'm likely gonna make it
	-- graphical down the line anyway so it probably doesn't matter

	-- outline for diff icon
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(48,48)
			self:y( _screen.cy-48 )
			self:x(126 * (player==PLAYER_1 and -1 or 1))

			if currentSteps then
				local currentDifficulty = currentSteps:GetDifficulty()
				self:diffuse( 0,0,0,1 )
			end
		end
	},

	-- colored square as the background for the difficulty meter
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(44,44)
			self:y( _screen.cy-48 )
			self:x(126 * (player==PLAYER_1 and -1 or 1))

			if currentSteps then
				local currentDifficulty = currentSteps:GetDifficulty()
				self:diffuse( DifficultyColor(currentDifficulty) )
			end
		end
	},

	-- difficulty name
	LoadFont("Common Normal")..{
		Text = "",
		InitCommand = function(self)
			self:x((126 * (player==PLAYER_1 and -1 or 1)) - 20)
			self:y(_screen.cy-68)
			self:horizalign("left")
			self:vertalign("top")
			self:zoom(0.75)
			self:diffuse(0,0,0,1)
			if currentSteps then
				local diff = ToEnumShortString(currentSteps:GetDifficulty())
				self:settext(THEME:GetString("Difficulty", diff))
			end
		end
	},

	-- numerical difficulty meter
	LoadFont("_wendy small")..{
		InitCommand=function(self)
			self:diffuse(Color.Black):zoom( 0.55 )
			self:y( _screen.cy-42 )
			self:x((126 * (player==PLAYER_1 and -1 or 1)) + 20)
			self:horizalign("right")

			local meter
			if GAMESTATE:IsCourseMode() then
				local trail = GAMESTATE:GetCurrentTrail(player)
				if trail then meter = trail:GetMeter() end
			else
				local steps = GAMESTATE:GetCurrentSteps(player)
				if steps then meter = steps:GetMeter() end
			end

			if meter then self:settext(meter) end
		end
	}
}

-- little gradient backing for chart info sections
local amvw = 252
local amvrh = 16
local amvc1 = {0,0,0,0.8}
local amvc2 = {0.1,0.1,0.1,0.8}
af[#af+1] = Def.ActorMultiVertex{
	InitCommand = function(self)
		self:SetDrawState({Mode="DrawMode_Quads"})
			:x(player == PLAYER_1 and -102 or -150)
			:y(_screen.cy-72)
			:SetVertices({
				{{0,0,0},amvc1},
				{{amvw,0,0},amvc1},
				{{amvw,amvrh,0},amvc2},
				{{0,amvrh,0},amvc2},

				{{0,amvrh,0},amvc1},
				{{amvw,amvrh,0},amvc1},
				{{amvw,amvrh*2,0},amvc2},
				{{0,amvrh*2,0},amvc2},

				{{0,amvrh*2,0},amvc1},
				{{amvw,amvrh*2,0},amvc1},
				{{amvw,amvrh*3,0},amvc2},
				{{0,amvrh*3,0},amvc2}
			})
	end
}

-- loop through info table and create texts from bottom to top
for i = #infotable, 1, -1 do
	af[#af+1] = LoadFont("Common Normal")..{
		Text = infotable[i],
		InitCommand = function(self)
			self:y(_screen.cy - 32 - (i-1)*16)
			self:x(98 * (player==PLAYER_1 and -1 or 1))
			self:horizalign(player == PLAYER_1 and "left" or "right")
			self:zoom(0.85)
			self:maxwidth(200/0.85)
		end
	}
end

return af