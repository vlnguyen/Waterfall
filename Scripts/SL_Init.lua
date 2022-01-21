-- This script needs to be loaded before other scripts that use it.

local PlayerDefaults = {
	__index = {
		initialize = function(self)
			self.ActiveModifiers = {
				SpeedModType = "X",
				SpeedMod = 1.00,
				JudgmentGraphic = "Optimus Dark 1x7 (doubleres).png",
				EarlyLate = "Enabled",
				NoteSkin = nil,
				Mini = "0%",
				BackgroundFilter = "Off",

				HideTargets = false,
				HideSongBG = false,
				HideCombo = false,
				HideLifebar = false,
				HideScore = false,
				HideDanger = false,

				ColumnFlashOnMiss = false,
				SubtractiveScoring = false,
				MeasureCounter = "None",
				MeasureCounterLeft = true,
				DataVisualizations = "None",
				TargetScore = 1,
				ActionOnMissedTarget = "Nothing",
				LifeMeterType = "Standard",
				MissBecauseHeld = false,
				NPSGraphAtTop = false,

				-- waterfall/bistro options
				SimulateITGEnv = false,
				ExpErrorWindow = "Enabled",
				PreferredLifeBar = "Hard",
				FAPlus = 0,
				EarlyLateThreshold = "FA+",

				-- profile customization
				ProfileCardInfo = "SongsPlayed",
				PreferredSecondPane = "General",
				PreferredGraph = "Life",
				PreferredSecondGraph = "Life",
				PreferredGameEnv = "Waterfall",
				GSOverride = false
			}
			self.Streams = {
				SongDir = nil,
				StepsType = nil,
				Difficulty = nil,
				Measures = nil,
			}
			self.HighScores = {
				EnteringName = false,
				Name = ""
			}
			self.Stages = {
				Stats = {}
			}
			self.PlayerOptionsString = nil

			-- The Groovestats API key loaded for this player
			self.ApiKey = ""
			-- Whether or not the player is playing on pad.
			self.IsPadPlayer = false
		end
	}
}

local GlobalDefaults = {
	__index = {

		-- since the initialize() function is called every game cycle, the idea
		-- is to define variables we want to reset every game cycle inside
		initialize = function(self)
			self.ActiveModifiers = {
				MusicRate = 1.0,
				TimingWindows = {true, true, true, true, true},
			}
			self.Stages = {
				PlayedThisGame = 0,
				Remaining = PREFSMAN:GetPreference("SongsPerPlay"),
				Stats = {}
			}
			self.ScreenAfter = {
				PlayAgain = "ScreenEvaluationSummary",
				PlayerOptions  = "ScreenGameplay",
				PlayerOptions2 = "ScreenGameplay",
				PlayerOptions3 = "ScreenGameplay",
			}
			self.ContinuesRemaining = ThemePrefs.Get("NumberOfContinuesAllowed") or 0
			self.ScreenshotTexture = nil
			self.MenuTimer = {
				ScreenSelectMusic = ThemePrefs.Get("ScreenSelectMusicMenuTimer"),
				ScreenSelectMusicCasual = ThemePrefs.Get("ScreenSelectMusicCasualMenuTimer"),
				ScreenPlayerOptions = ThemePrefs.Get("ScreenPlayerOptionsMenuTimer"),
				ScreenEvaluation = ThemePrefs.Get("ScreenEvaluationMenuTimer"),
				ScreenEvaluationSummary = ThemePrefs.Get("ScreenEvaluationSummaryMenuTimer"),
				ScreenNameEntry = ThemePrefs.Get("ScreenNameEntryMenuTimer"),
			}
			self.TimeAtSessionStart = nil

			self.GameplayReloadCheck = false
		end
	}
}

-- "SL" is a general-purpose table that can be accessed from anywhere
-- within the theme and stores info that needs to be passed between screens
SL = {
	P1 = setmetatable( {}, PlayerDefaults),
	P2 = setmetatable( {}, PlayerDefaults),
	Global = setmetatable( {}, GlobalDefaults),

	-- Colors that Simply Love's background can be
	Colors = {
		"#FF3C23", -- bright red
		"#FF003C", -- bright fuschia
		"#C1006F", -- dark fuschia
		"#8200A1", -- very nice purple
		"#413AD0", -- pale blue
		"#0073FF", -- not actually light blue
		"#0DBEFF", -- light blue
		"#5CE087", -- minty green
		"#AEFA44", -- yellow green
		"#FFFF00", -- yellow
		"#FFBE00", -- light orange
		"#FF7D00" -- orange
	},
	-- use this as a fallback on any element using SL.Global.ActiveColorIndex that I don't know, until deciding on
	-- actual color to use
	DefaultColor = 6,
	-- Difficulty colors (these will now be constant)
	DifficultyColors = {
		Difficulty_Beginner = "#80FFFF",
		Difficulty_Easy = "#80FF80",
		Difficulty_Medium = "#FFFF80",
		Difficulty_Hard = "#FF8080",
		Difficulty_Challenge = "#FF80FF",
		Difficulty_Edit = "#B4B7BA"
	},
	JudgmentColors = {
		ITG = {
			color("#21CCE8"),	-- blue
			color("#e29c18"),	-- gold
			color("#66c955"),	-- green
			color("#b45cff"),	-- purple (greatly lightened)
			color("#c9855e"),	-- peach?
			color("#ff3030")	-- red (slightly lightened)
		},
		Waterfall = {
			color("#FF00BE"),	-- fuschia
			color("#FFFF00"),	-- yellow
			color("#00c800"),	-- green
			color("#0080FF"),	-- blue
			color("#808080"),	-- gray
			color("#ff3030")	-- red (slightly lightened)
		}
	},
	Preferences = {
		ITG = {
			TimingWindowAdd=0.0015,
			RegenComboAfterMiss=5,
			MaxRegenComboAfterMiss=10,
			MinTNSToHideNotes="TapNoteScore_W3",
			HarshHotLifePenalty=true,

			PercentageScoring=true,
			AllowW1="AllowW1_Everywhere",
			SubSortByNumSteps=true,

			TimingWindowSecondsW1=0.021500,
			TimingWindowSecondsW2=0.043000,
			TimingWindowSecondsW3=0.102000,
			TimingWindowSecondsW4=0.135000,
			TimingWindowSecondsW5=0.180000,
			TimingWindowSecondsHold=0.320000,
			TimingWindowSecondsMine=0.070000,
			TimingWindowSecondsRoll=0.350000,
		},
		Waterfall = {
			TimingWindowAdd=0.0000,
			TimingWindowScale=1,
			RegenComboAfterMiss=5,
			MaxRegenComboAfterMiss=5,
			MinTNSToHideNotes="TapNoteScore_W4",
			HarshHotLifePenalty=false,

			PercentageScoring=true,
			AllowW1="AllowW1_Everywhere",
			SubSortByNumSteps=true,

			TimingWindowSecondsW1=0.015000,
			TimingWindowSecondsW2=0.03000,
			TimingWindowSecondsW3=0.050000,
			TimingWindowSecondsW4=0.100000,
			TimingWindowSecondsW5=0.160000,
			TimingWindowSecondsHold=0.300000,
			TimingWindowSecondsMine=0.071500,
			TimingWindowSecondsRoll=0.350000,

			AutogenGroupCourses=false
		}
	},
	Metrics = {
		ITG = {
			PercentScoreWeightW1=5,
			PercentScoreWeightW2=4,
			PercentScoreWeightW3=2,
			PercentScoreWeightW4=0,
			PercentScoreWeightW5=-6,
			PercentScoreWeightMiss=-12,
			PercentScoreWeightLetGo=0,
			PercentScoreWeightHeld=5,
			PercentScoreWeightHitMine=-6,

			GradeWeightW1=5,
			GradeWeightW2=4,
			GradeWeightW3=2,
			GradeWeightW4=0,
			GradeWeightW5=-6,
			GradeWeightMiss=-12,
			GradeWeightLetGo=0,
			GradeWeightHeld=5,
			GradeWeightHitMine=-6,

			LifePercentChangeW1=0.008,
			LifePercentChangeW2=0.008,
			LifePercentChangeW3=0.004,
			LifePercentChangeW4=0.000,
			LifePercentChangeW5=-0.050,
			LifePercentChangeMiss=-0.100,
			LifePercentChangeLetGo=IsGame("pump") and 0.000 or -0.080,
			LifePercentChangeHeld=IsGame("pump") and 0.000 or 0.008,
			LifePercentChangeHitMine=-0.050,
		},
		Waterfall = {
			PercentScoreWeightW1=10,
			PercentScoreWeightW2=9,
			PercentScoreWeightW3=6,
			PercentScoreWeightW4=3,
			PercentScoreWeightW5=0,
			PercentScoreWeightMiss=0,
			PercentScoreWeightLetGo=0,
			PercentScoreWeightHeld=6,
			PercentScoreWeightHitMine=-3,

			GradeWeightW1=10,
			GradeWeightW2=9,
			GradeWeightW3=6,
			GradeWeightW4=3,
			GradeWeightW5=0,
			GradeWeightMiss=0,
			GradeWeightLetGo=0,
			GradeWeightHeld=6,
			GradeWeightHitMine=-3,

			-- lifebar values are defined in WF-LifeBars.lua
			LifePercentChangeW1=0,--0.010,
			LifePercentChangeW2=0,--0.010,
			LifePercentChangeW3=0,--0.010,
			LifePercentChangeW4=0,--0.005,
			LifePercentChangeW5=0,---0.050,
			LifePercentChangeMiss=0,---0.1,
			LifePercentChangeLetGo=0,---0.1,
			LifePercentChangeHeld=0,--0.010,
			LifePercentChangeHitMine=0---0.05,
		}
	},

	-- Fields used to determine the existence of the launcher and the
	-- available GrooveStats services.
	GrooveStats = {
		-- Whether we're launching StepMania with a launcher.
		-- Determined once on boot in ScreenSystemLayer.
		Launcher = false,

		-- Available GrooveStats services. Subject to change while
		-- StepMania is running.
		GetScores = false,
		Leaderboard = false,
		AutoSubmit = false,

		-- ************* CURRENT QR VERSION *************
		-- * Update whenever we change relevant QR code *
		-- *  and when GrooveStats backend is also      *
		-- *   updated to properly consume this value.  *
		-- **********************************************
		ChartHashVersion = 3
	}
}


-- Initialize preferences by calling this method.  We typically do
-- this from ./BGAnimations/ScreenTitleMenu underlay/default.lua
-- so that preferences reset between each game cycle.

function InitializeSimplyLove()
	SL.P1:initialize()
	SL.P2:initialize()
	SL.Global:initialize()
end

InitializeSimplyLove()
