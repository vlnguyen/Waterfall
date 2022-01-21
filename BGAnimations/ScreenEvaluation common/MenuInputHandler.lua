local actions = {
    MenuLeft = "Up", MenuUp = "Up",
    MenuRight = "Down", MenuDown = "Down",
    Back = "Cancel",
    Select = "Cancel",
    Start = "Confirm"
}

return function(event)
    if not event.PlayerNumber then return false end
    if not GAMESTATE:IsHumanPlayer(event.PlayerNumber) then return false end
    if event.type ~= "InputEventType_FirstPress" then return false end

    local pn = tonumber(event.PlayerNumber:sub(-1))
    local action = actions[event.GameButton]
    
    if action then
        MESSAGEMAN:Broadcast("EvalMenuInputEvent", {pn = pn, action = action})
    end

    return false
end