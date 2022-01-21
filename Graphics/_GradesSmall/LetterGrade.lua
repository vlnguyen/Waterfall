local args = ...
local grade = args.grade
local itg = args.itg

-- conditionally return an actor for the grade and mode passed in.
-- for itg we just return a sprite with the index pertaining to the grade, since we're just highjacking
-- musicwheelitem grades for now (heh).
-- for standard grades, we can reference most as just single frames, with AA and AAA requiring some additional logic.

if type(grade) == "number" then grade = string.format("Grade_Tier%02d", grade) end
if grade == "Failed" or grade == "Fail" or grade == "Grade_Tier18" then grade = "Grade_Failed" end

local af = Def.ActorFrame{}

local unplayedtext = LoadFont("Common Normal")..{ Text = "None", InitCommand = function(self) self:zoom(3) end }

if grade == "Grade_Tier99" then
    af[#af+1] = unplayedtext
    return af
end

if itg then
    local frame = 17
    if grade ~= "Grade_Failed" then frame = tonumber((grade:gsub("Grade_Tier", ""))) - 1 end
    af[#af+1] = Def.Sprite{
        -- IM DRINKIN A SPRITE LOL
        Texture = "grades 1x18.png",
        InitCommand = function(self) self:animate(false):setstate(frame) end
    }
    return af
end

local WFFrames = {
    Grade_Tier01 = 5,
    Grade_Tier04 = 8,
    Grade_Tier05 = 11,
    Grade_Tier06 = 14,
    Grade_Tier07 = 16
}

if grade ~= "Grade_Tier02" and grade ~= "Grade_Tier03" then
    local frame = WFFrames[grade]
    af[#af+1] = Def.Sprite{
        -- IM DRINKIN A SPRITE LOL
        Texture = "grades 1x18.png",
        InitCommand = function(self) self:animate(false):setstate(frame) end
    }
    return af
else
    local placements = {
        Grade_Tier02 = {0, -40, 40},
        Grade_Tier03 = {-20, 20}
    }

    for p in ivalues(placements[grade]) do
        af[#af+1] = Def.Sprite{
            -- IM DRINKIN A SPRITE LOL
            Texture = "grades 1x18.png",
            InitCommand = function(self) self:animate(false):setstate(8):x(p) end
        }
    end

    return af
end

af[#af+1] = unplayedtext
return af