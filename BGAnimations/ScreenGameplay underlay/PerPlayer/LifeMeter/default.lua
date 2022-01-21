local player = ...
if SL[ToEnumShortString(player)].ActiveModifiers.HideLifebar then return end

local useitg = SL[ToEnumShortString(player)].ActiveModifiers.SimulateITGEnv

local lifemeter_actor = Def.ActorFrame{}

-- conditionally load the "normal" lifebars, or itg lifebar if using "simulate itg" option
if not useitg then
	-- create a bar for all 3
	for i = 1, #WF.LifeBarNames do
		lifemeter_actor[#lifemeter_actor+1] = LoadActor("Standard.lua", {player=player, index=i})
	end
else
	lifemeter_actor[#lifemeter_actor+1] = LoadActor("ITG.lua", player)
end

return lifemeter_actor