local args = ...
local af = args.af
local num_panes = args.num_panes

if not af then return end

local style = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())

local btndown = {{MenuLeft=false,MenuRight=false},{MenuLeft=false,MenuRight=false}}

return function(event)

	if not (event and event.PlayerNumber and event.button) then return false end

	local pn = ToEnumShortString(event.PlayerNumber)
	if style == "OnePlayerTwoSides" then
		pn = "P"..(event.controller:sub(-1))
	end

	local p = tonumber(pn:sub(-1))
	if (not WF.EvalPanes[p]) or #WF.EvalPanes[p] < 2 then return false end

	if event.type == "InputEventType_Release" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
			btndown[p][event.GameButton] = false
		end
	end

	if event.type == "InputEventType_FirstPress" then

		-- take screenshot with select button
		if event.GameButton == "Select" then
			MESSAGEMAN:Broadcast("TakeScreenshot", {PlayerNumber = event.PlayerNumber})
		end

		if event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
			btndown[p][event.GameButton] = true

			-- if doubles and other pane is already viewing per panel, exit here
			if style == "OnePlayerTwoSides" then
				local otherp = (p == 1) and 2 or 1
				if WF.EvalPanes[otherp][WF.ActivePane[otherp]]:GetName():find("PerPanel") then return end
			end

			-- cycle index
			local lastpane = WF.ActivePane[p]
			if event.GameButton == "MenuRight" then
				WF.ActivePane[p] = (WF.ActivePane[p] % #WF.EvalPanes[p]) + 1
			elseif event.GameButton == "MenuLeft" then
				WF.ActivePane[p] = ((WF.ActivePane[p] - 2) % #WF.EvalPanes[p]) + 1
			end

			MESSAGEMAN:Broadcast("EvalPaneChanged", {pn = p, activepane = WF.ActivePane[p]})

			-- expand for double
			if style == "OnePlayerTwoSides" then
				--SM("expan ?")
				if WF.EvalPanes[p][WF.ActivePane[p]]:GetCommand("ExpandForDouble") then
					af:queuecommand("ExpandP"..p)
				else
					af:queuecommand("ShrinkP"..p)
				end
			end

			for i=1,#WF.EvalPanes[p] do
				local pane = WF.EvalPanes[p][i]
				--pane:finishtweening()
				if i == WF.ActivePane[p] then pane:playcommand("Show") else pane:playcommand("Hide") end
			end

			-- finally, force hide/show other pane on doubles depending on if switched to or from per panel
			if style == "OnePlayerTwoSides" then
				local otherp = (p == 1) and 2 or 1
				if WF.EvalPanes[p][WF.ActivePane[p]]:GetName():find("PerPanel") then
					WF.EvalPanes[otherp][WF.ActivePane[otherp]]:queuecommand("Hide")
				elseif WF.EvalPanes[p][lastpane]:GetName():find("PerPanel") then
					WF.EvalPanes[otherp][WF.ActivePane[otherp]]:queuecommand("Show")
				end
			end
		end

		-- up/down to switch graphs
		local panename = WF.EvalPanes[p][WF.ActivePane[p]]:GetName()
		if (event.GameButton == "MenuUp" or event.GameButton == "MenuDown") or
		((ThemePrefs.Get("EvalAllowUpDownArrows")) and (event.GameButton == "Up" or event.GameButton == "Down")
		and (not panename:find("TestInput"))) then
			if not panename:find("Timing") then
				WF.GraphView[p] = (WF.GraphView[p] == "Life") and "Scatterplot" or "Life"
				MESSAGEMAN:Broadcast("GraphViewChanged", {pn = p, graphview = WF.GraphView[p]})
			end
		end
	end

	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") and event.type ~= "InputEventType_Repeat" then
		MESSAGEMAN:Broadcast("TestInputEvent", event)
	end

	-- trigger menu if left and right are both down for an active player
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and btndown[p].MenuLeft and btndown[p].MenuRight then
		btndown = {{MenuLeft=false,MenuRight=false},{MenuLeft=false,MenuRight=false}}
		af:queuecommand("DirectInputToMenu")
		af:GetChild("MenuOverlay"):playcommand("Show")
	end

	return false
end