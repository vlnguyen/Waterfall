-- plan is to have one set menu song but i'll keep this logic because it could allow some neat things anyway
local songs = {
	Waterfall = "Aquatic"
}

-- use the style to index the songs table (above)
local file = songs.Waterfall

-- if a song file wasn't defined in the songs table above
-- fall back on the song for Hearts as default music
if not file then file = songs.Waterfall end

return THEME:GetPathS("", "_common menu music/" .. file)
