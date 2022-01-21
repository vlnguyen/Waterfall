-- temporary "waterfally" background animation (i'm just kinda dicking around here)
local alpha = 0.7
local color1 = {0,0,0,alpha}
local color2 = {0,0,0.3,alpha}
local num_rectangles = 20
local h = SCREEN_HEIGHT / num_rectangles
local spd = 0.25
local yoff = 0

local afupdate = function(af)
    yoff = yoff + spd
    if yoff > h then yoff = yoff - h end
    for i = 1, num_rectangles + 1 do
        local cury = (i-2) * h + yoff
        af:GetChild("AMV"..i):y(cury)
    end
end

local af = Def.ActorFrame{
    OnCommand = function(self)
        self:SetUpdateFunction(afupdate)
    end
}

for i = 1, num_rectangles + 1 do
    local ay = (i-2) * h
    af[#af+1] = Def.ActorMultiVertex{
        Name = "AMV"..i,
        OnCommand=function(self)
            self:SetDrawState({Mode="DrawMode_Quads"})
                :SetVertices({
                    {{0,0,0},color1},
                    {{SCREEN_WIDTH,0,0},color1},
                    {{SCREEN_WIDTH,h,0},color2},
                    {{0,h,0},color2}
                })
                :y(ay)
        end
    }
end

return af