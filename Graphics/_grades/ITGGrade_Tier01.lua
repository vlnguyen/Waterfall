local pss = ...

return Def.ActorFrame{

	--top left
	LoadActor("star.lua", pss)..{
		OnCommand=function(self) self:x(-46):y(-46):zoom(0.5):pulse():effectmagnitude(1,0.9,0) end
	},

	--top right
	LoadActor("star.lua", pss)..{
		OnCommand=function(self) self:x(46):y(-46):zoom(0.5):effectoffset(0.2):pulse():effectmagnitude(0.9,1,0) end
	},

	-- bottom left
	LoadActor("star.lua", pss)..{
		OnCommand=function(self) self:x(-46):y(46):zoom(0.5):effectoffset(0.4):pulse():effectmagnitude(0.9,1,0) end
	},

	--  bottom right
	LoadActor("star.lua", pss)..{
		OnCommand=function(self) self:x(46):y(46):zoom(0.5):effectoffset(0.6):pulse():effectmagnitude(1,0.9,0) end
	}
}