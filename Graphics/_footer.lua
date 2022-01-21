-- tables of rgba values
local light = {0, 0, 0.25, 0.8}

return Def.Quad{
	Name="Footer",
	InitCommand=function(self)
		self:draworder(90):zoomto(_screen.w, 32):vertalign(bottom):y(32)
		self:diffuse(light)
	end
}