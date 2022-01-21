local file

if GAMESTATE:IsCourseMode() then
	file = LoadActor("./CourseContentsList.lua")
else
	file = LoadActor("./DifficultyGrid.lua")
end

return file