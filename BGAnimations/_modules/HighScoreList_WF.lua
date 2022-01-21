local af = Def.ActorFrame{}

-- ---------------------------------------------
-- setup involving optional arguments that might have been passed in via a key/value table

local args = ...

-- a player object, indexed by "Player"; default to GAMESTATE's MasterPlayer if none is provided
local player = args.Player or GAMESTATE:GetMasterPlayerNumber()
if not player then return af end

local pn = tonumber(player:sub(-1))

-- the number of HighScores to retrieve, indexed by "NumHighScores"; default to 5 if none is provided
local NumHighScores = args.NumHighScores or 5

-- WF player profiles don't have "high score lists" so the profile arg is never used

-- optionally provide Song/Course and Steps/Trail objects; if none are provided
-- default to using whatever GAMESTATE currently thinks they are
local iscourse = GAMESTATE:IsCourseMode()
local SongOrCourse = args.SongOrCourse or (iscourse and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong())
local StepsOrTrail = args.StepsOrTrail or (iscourse and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player))
if not (SongOrCourse and StepsOrTrail) then return af end

-- if HSData is passed, that will take highest priority. otherwise, SongStats can be passed. Else, get the SongStats
-- from song, steps, and hash
local HSData = args.HSData
local sarg = (not iscourse) and "SongStats" or "CourseStats"
local SongStats = HSData and HSData[pn]["Machine"..sarg] or args[sarg] --args sarg :)
if not SongStats then
	local hash = (args.Hash ~= "") and args.Hash
	-- caution here: assume current rate mod if none passed, but in the event of getting the list for some previous song
	-- played, we need to be passed the rate of not the whole songstats
	local rate = args.Rate or RateFromNumber(SL.Global.ActiveModifiers.MusicRate)
	SongStats = WF.FindProfileSongStatsFromSteps(SongOrCourse, StepsOrTrail, rate, hash)
end

if not SongStats then return af end

local Font = args.Font or "Common Normal"
local row_height = args.RowHeight or 22

local ITG = args.ITG -- ITG

-- ---------------------------------------------
-- setup that can occur now that the arguments have been handled

local HighScores = ITG and SongStats.HighScoreList_ITG or SongStats.HighScoreList
if not HighScores then return af end

-- don't attempt to retrieve more HighScores than are actually saved
local MaxHighScores = WF.MaxMachineRecordsPerChart
NumHighScores = math.min(NumHighScores, MaxHighScores)


local months = {}
for i=1,12 do
	table.insert(months, THEME:GetString("HighScoreList", "Month"..i))
end

-- ---------------------------------------------
-- lower and upper will be used as loop start and end points
-- we'll loop through the the list of highscores from lower to upper indices
-- initialize them to 1 and NumHighScores now; they may change later
local lower = 1
local upper = NumHighScores

-- If the we're on Evaluation or EvaluationSummary, we might want to compare the player's recent
-- performance to the overall list of highscores.
-- this can be passed in directly, or taken from HSData if that's passed in
local highscoreindex = args.HighScoreIndex or (HSData and HSData[pn]["MachineHSInd"..(ITG and "_ITG" or "")])

-- ---------------------------------------------

if highscoreindex then
	-- this shifting logic should not be applicable anymore in theory, but it could
	if highscoreindex > upper then
		lower = lower + highscoreindex - upper
		upper = highscoreindex
	end
end

-- ---------------------------------------------


for i=lower,upper do

	local row_index = i-lower
	local score, name, date
	local numbers = {}

	if HighScores[i] then
		score = string.format("%0.2f%%", HighScores[i].PercentDP/100)
		name = HighScores[i].PlayerFullName
		date = HighScores[i].DateObtained

		-- make the date look nice
		for number in string.gmatch(date, "%d+") do
			numbers[#numbers+1] = number
	    end
		date = months[tonumber(numbers[2])] .. " " ..  numbers[3] ..  ", " .. numbers[1]
	else
		name	= "----"
		score	= "------"
		date	= "----------"
	end

	local row = Def.ActorFrame{}

	-- if we wanted to compare a player's performance against the list of highscores we are returning
	if highscoreindex then
		-- then specify and OnCommand that will check if this row represents the player's performance for this round
		row.OnCommand=function(self)
			if i == highscoreindex then
				-- apply a diffuseshift effect to draw attentiont to this row
				self:diffuseshift():effectperiod(4/3)
				self:effectcolor1( PlayerColor("PlayerNumber_P1") )
				self:effectcolor2( Color.White )
			end
		end
	end

	row[#row+1] = LoadFont(Font)..{
		Text=i..". ",
		InitCommand=function(self) self:horizalign(right):xy(-132, row_index*row_height) end
	}

	row[#row+1] = LoadFont(Font)..{
		Text=name,
		InitCommand=function(self) self:horizalign(left):xy(-122, row_index*row_height):maxwidth(96) end
	}

	row[#row+1] = LoadFont(Font)..{
		Text=score,
		InitCommand=function(self) self:horizalign(left):xy(-24, row_index*row_height) end
	}

	row[#row+1] = LoadFont(Font)..{
		Text=date,
		InitCommand=function(self) self:horizalign(left):xy(50, row_index*row_height) end
	}

	af[#af+1] = row

	row_index = row_index + 1
end


return af