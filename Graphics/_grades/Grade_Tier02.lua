return Def.ActorFrame{
	LoadActor("./assets/a.png")..{ OnCommand=function(self) self:x(-80) self:zoom(0.85) end },
	LoadActor("./assets/a.png")..{ OnCommand=function(self) self:zoom(0.85) end },
	LoadActor("./assets/a.png")..{ OnCommand=function(self) self:x(80) self:zoom(0.85) end }
}