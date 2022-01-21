local args = ...
local af = args.af
local profile_data = args.profile_data

for pdata in ivalues(profile_data) do
    if pdata.avatar then
        af[#af+1] = LoadActor(pdata.avatar)..{
            Name = "Avatar_"..pdata.index,
            InitCommand = function(self) self:y(-100):zoomto(64,64) end
        }
    end
end