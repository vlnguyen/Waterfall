------------------------------------------------------------
-- global functions related to colors in Simply Love

function GetHexColor( n )
	-- if we were passed nil or a non-number, return white
	if n == nil or type(n) ~= "number" then return Color.White end

	-- use the number passed in to lookup a color in the SL.Colors
	-- ensure the index is kept in bounds via modulo operation
	local clr = ((n - 1) % #SL.Colors) + 1
	if SL.Colors[clr] then
		return color(SL.Colors[clr])
	end

	return Color.White
end

-- convenience function to return the current color from SL.Colors
function GetDefaultColor()
	return GetHexColor( SL.DefaultColor )
end

-- PlayerColor will mostly not be used, but helps with menu options
function PlayerColor( pn )
	if pn == PLAYER_1 then return GetHexColor( 8 ) end
	if pn == PLAYER_2 then return GetHexColor( 7 ) end
	return Color.White
end

-- replacing this with a call to SL.Global.DifficultyColors now
-- [TODO] will eventually remove this function entirely
function DifficultyColor( difficulty )
	return color(SL.DifficultyColors[difficulty])
end