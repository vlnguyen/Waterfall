-- custom life graphs
local params = ...
local pn = tonumber(params.player:sub(-1))
local gw = params.GraphWidth
local gh = params.GraphHeight
local songstart = 0 --GAMESTATE:GetCurrentSong():GetFirstSecond()
local songend = GAMESTATE:GetCurrentSong():GetLastSecond()

local af = Def.ActorFrame{}

for ind in ivalues(WF.ActiveLifeBars) do
    local verts = (not GAMESTATE:IsCourseMode()) and WF.GetLifeGraphVertices(pn, ind, gw, gh, songstart, songend)
        or WF.GetLifeGraphVerticesCourse(pn, ind, gw, gh)

    if verts then
        local fail = WF.IsLifeBarFailed(pn, ind)
        local order = 50 + ind * (fail and -1 or 1)
        af[#af+1] = Def.ActorMultiVertex{
            InitCommand = function(self)
                self:x(-gw/2)
                self:draworder(order)
                if ind < WF.LowestLifeBarToFail[pn] then self:visible(false) end
            end,
            OnCommand = function(self)
                self:SetDrawState({Mode="DrawMode_LineStrip"}):SetLineWidth(2)
                    :SetVertices(verts)
            end
        }
    end
end

return af