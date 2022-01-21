if not IsServiceAllowed(SL.GrooveStats.AutoSubmit) then return Def.ActorFrame{} end

local player = ...
local pn = tonumber(player:sub(-1))

local af = Def.ActorFrame{
    Name = "GSWR",
    GSWorldRecordMessageCommand = function(self, arg)
        if not (arg and (arg.player == player)) then return end
        if SL["P"..pn].ActiveModifiers.SimulateITGEnv then
            local rt = self:GetParent():GetChild("RecordText")
            if rt then rt:diffusealpha(0) end
        end
        self:queuecommand("PlayGSWR")
    end,
    ShowCommand = function(self) self:finishtweening():visible(true) end,
    HideCommand = function(self) self:finishtweening():visible(false) end,

    -- the gs logo
    LoadActor(THEME:GetPathG("", "GrooveStats.png"))..{
        InitCommand = function(self)
            self:zoom(24/128):diffusealpha(0)
        end,
        PlayGSWRCommand = function(self)
            self:linear(0.1):diffusealpha(1)
        end
    },

    -- the text
    LoadFont("Common Normal")..{
        Text = "World Record!",
        InitCommand = function(self)
            self:x(60):diffuse(Color.Yellow):zoom(0)
        end,
        PlayGSWRCommand = function(self)
            self:diffuseshift():effectcolor1(Color.Yellow):effectcolor2(Color.White)
            :sleep(0.05):zoom(1.1):decelerate(0.1):zoom(1.3):accelerate(0.2):zoom(1)
        end
    }
}

return af