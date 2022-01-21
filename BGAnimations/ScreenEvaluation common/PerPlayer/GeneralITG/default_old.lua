-- [TODO] will have to eventually support course mode with this...
if GAMESTATE:IsCourseMode() then return end

--- This panel is for ITG score information. I did more than I wanted to here but people will want it I guess. ---
local player = ...
local pn = tonumber(player:sub(-1))

local af = Def.ActorFrame{
    Name = "Pane7",
    InitCommand = function(self)
        self:visible(false)
        --self:x( -115 )
		self:y( _screen.cy-40 )
    end,
    Def.Quad{
        InitCommand=function(self)
			self:diffuse( color("#101519") )
				:y(-2)
				:zoomto(300, 28)
		end
    },
    Def.BitmapText{
        Font = "_wendy white",
        -- what is the difference between this and wendy small. why are there so many wendys
        Text="ITG",
		InitCommand=function(self) self:horizalign("center"):zoom(0.25):xy( 0, -2) end
    },
    Def.BitmapText{
        Font = "_wendy white",
        Text = WF.ITGFailed[pn] and "Failed" or "Cleared",
        InitCommand = function(self)
            self:horizalign("right")
            self:xy( 140, -2)
            self:zoom(0.25)
            self:diffuse(WF.ITGFailed[pn] and color("#FF0000") or color("#00FF00"))
        end
    },
    Def.BitmapText{
        Font = "_wendy white",
        Text = "",
        InitCommand = function(self)
            self:settext(WF.ITGScore[pn])
            self:zoom(0.25)
            self:horizalign("right")
            self:xy(-85, -2)
        end
    }
}

local box_height = 146
local row_height = box_height / 6

for i = 1, 6 do
    af[#af+1] = Def.BitmapText{
        Font = "Common Normal",
        Text = WF.ITGJudgmentNames[i]:upper(),
        InitCommand = function(self)
            self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( -80 )
                    :y( i * row_height + 4 )
            -- Note: originally I just had these conditions checking a variable value, but I want them to be
            -- comparing the exact timing window values, because that ensures that stuff is working the way it should
            if PREFSMAN:GetPreference("TimingWindowSecondsW5") <= SL.Preferences.Waterfall.TimingWindowSecondsW4 then
                -- error disabled condition
                if i == 4 or i == 5 then
                    self:diffusealpha(0.2)
                elseif i == 3 then
                    self:diffuse(1,1,0.7,1)
                    self:settext("GREAT *")
                end
            elseif math.abs(PREFSMAN:GetPreference("TimingWindowSecondsW5") -
            (SL.Preferences.ITG.TimingWindowSecondsW5 + SL.Preferences.ITG.TimingWindowAdd)) >= 0.00001 and i == 5 then
                -- truncated way off window
                self:diffuse(1,1,0.7,1)
                self:settext("WAY OFF *")
            end
        end
    }
    af[#af+1] = Def.BitmapText{
        Font = "Common Normal",
        Text = "",
        InitCommand = function(self)
            self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( -12 )
                    :y( i * row_height + 4 )
            self:settext(tostring(WF.ITGJudgmentCounts[pn][i]))
            if PREFSMAN:GetPreference("TimingWindowSecondsW5") <= SL.Preferences.Waterfall.TimingWindowSecondsW4
            and (i == 4 or i == 5) then
                self:visible(false)
            end
        end
    }
end
af[#af+1] = Def.BitmapText{
    Font = "Common Normal",
    Text = "HELD",
    InitCommand = function(self)
        self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( 64 )
					:y( 5 * row_height + 4 )
    end
}
af[#af+1] = Def.BitmapText{
    Font = "Common Normal",
    Text = "",
    InitCommand = function(self)
        self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( 132 )
                    :y( 5 * row_height + 4 )
        local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
        local hcount = pss:GetRadarPossible():GetValue("RadarCategory_Holds") + pss:GetRadarPossible():GetValue("RadarCategory_Rolls")
        self:settext(tostring(WF.ITGJudgmentCounts[pn][WF.ITGJudgmentInd.Held]).."/"..hcount)
    end
}
af[#af+1] = Def.BitmapText{
    Font = "Common Normal",
    Text = "MINES HIT",
    InitCommand = function(self)
        self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( 64 )
					:y( 6 * row_height + 4 )
    end
}
af[#af+1] = Def.BitmapText{
    Font = "Common Normal",
    Text = "",
    InitCommand = function(self)
        self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( 132 )
                    :y( 6 * row_height + 4 )
        self:settext(tostring(WF.ITGJudgmentCounts[pn][WF.ITGJudgmentInd.Mine]))
    end
}

-- get letter grade and display in little free space (:
local grade = WF.GetITGGrade(WF.ITGScore[pn])
af[#af+1] = LoadActor(THEME:GetPathG("", "_grades/ITGGrade_"..(WF.ITGFailed[pn] and "Failed" or "Tier"..grade)..".lua"))..{
    InitCommand=function(self)
		self:x(75)
		self:y(56)
	end,
	OnCommand=function(self) self:zoom(0.3) end
}

-- use an actormultivertex to build lifebar graph

local gw = THEME:GetMetric("GraphDisplay", "BodyWidth")
local gh = THEME:GetMetric("GraphDisplay", "BodyHeight")
local songstart = 0 --GAMESTATE:GetCurrentSong():GetFirstSecond()
local songend = GAMESTATE:GetCurrentSong():GetLastSecond()
local verts = WF.GetITGLifeVertices(pn, gw, gh, songstart, songend)

af[#af+1] = Def.Quad{
    InitCommand = function(self)
        self:zoomto(gw,gh+4)
        self:y(164 + gh/2)
        self:diffuse(0,0,0,0.8)
        self:draworder(60)
    end
}
af[#af+1] = Def.ActorMultiVertex{
    InitCommand = function(self)
        self:x(-gw/2)
        self:y(164)
        self:draworder(61)
    end,
    OnCommand = function(self)
        self:SetDrawState({Mode="DrawMode_LineStrip"}):SetLineWidth(2)
			:SetVertices(verts)
    end
}

return af