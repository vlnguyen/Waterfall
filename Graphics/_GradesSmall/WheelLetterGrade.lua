local args = ...
local grade = args.grade
local itg = args.itg

-- lite copy of small grades actors for music wheel.

if type(grade) == "number" then grade = string.format("Grade_Tier%02d", grade) end
if grade == "Failed" or grade == "Fail" or grade == "Grade_Tier18" then grade = "Grade_Failed" end

local af = Def.ActorFrame{}

if itg then
    local frame = 99
    if (grade) and grade ~= "Grade_Failed" then frame = tonumber((grade:gsub("Grade_Tier", ""))) - 1 end
    af[#af+1] = Def.Sprite{
        -- IM DRINKIN A SPRITE LOL
        Texture = "grades 1x18.png",
        InitCommand = function(self)
            self:animate(false)
            if frame < 90 then self:setstate(frame) else self:visible(false) end
        end,
        SetGradeCommand = function(self, param)
            local frame = 17
            if (not param) or (type(param == "number") and param[1] > 90) then
                self:visible(false)
                return
            else
                local grade = param[1]
                if type(grade) == "string" then
                    if grade:find("Fail") then frame = 17
                    else frame = tonumber((grade:gsub("Grade_Tier", ""))) - 1 end
                else frame = grade - 1 end
            end
            self:setstate(frame):visible(true)
            Trace("Grade set "..frame)
        end
    }
end

--[[ Removing wf grades for now, probably won't use them

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
]]

return af