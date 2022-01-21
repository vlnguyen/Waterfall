--local profileind = 0
--local profileid = PROFILEMAN:GetLocalProfileIDFromIndex(profileind)
--WF.ModifyingProfileID = profileid
local themename = THEME:GetThemeDisplayName()
local profiledir
local profilename = "(none)"
local prefs

if WF.ModifyingProfileID ~= "" then
    profiledir = PROFILEMAN:LocalProfileIDToDir(WF.ModifyingProfileID)
    local ind = PROFILEMAN:GetLocalProfileIndexFromID(WF.ModifyingProfileID)
    profilename = PROFILEMAN:GetLocalProfileFromIndex(ind):GetDisplayName()
    prefs = IniFile.ReadFile(profiledir..themename.." UserPrefs.ini")[themename]
    if prefs then
        for k, v in pairs(prefs) do
            if WF.CustomProfileOptions[k] then
                WF.CustomProfileOptions[k] = v
            end
        end
        -- if any CustomProfileOptions settings didn't already exist in prefs, set them to defaults here
        for k, v in pairs(WF.CustomProfileOptions) do
            if not prefs[k] then
                prefs[k] = v
            end
        end
    else
        -- if there was no UserPrefs defined at all, create the prefs here
        prefs = DeepCopy(WF.CustomProfileOptionDefaults)
    end
end

local af = Def.ActorFrame{
    OnCommand = function(self)
        --SM(WF.ModifyingProfileID.."  "..profilename)
        if WF.ModifyingProfileID == "" then
            SM("Invalid Profile")
            SCREENMAN:GetTopScreen():Cancel()
        end
    end,
    OffCommand = function(self)
        for k, v in pairs(WF.CustomProfileOptions) do
            prefs[k] = v
        end
        IniFile.WriteFile(profiledir..themename.." UserPrefs.ini", {[themename] = prefs} )
        WF.ModifyingProfileID = ""
    end
}

return af