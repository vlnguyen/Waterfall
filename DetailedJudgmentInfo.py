import sys
import math

args = sys.argv
filepath = args[1]

standardWindows = [0.015,0.030,0.050,0.100,0.1815]
standardWindowNames = ["Masterful","Awesome","Solid","OK","Fault","Miss"]

itgWindows = [0.023,0.0445,0.1035,0.1365,0.1815]
itgWindowNames = ["Fantastic","Excellent","Great","Decent","Way Off","Miss"]

arrows = ["dummy","Left","Down","Up","Right"]

judgetypes = {"M": "Miss","N": "Mine","H": "Held","D": "Dropped"}

standardScoreWeights = {"Masterful": 10,"Awesome": 9,"Solid": 6,"OK": 3,"Fault": 0,"Miss": 0,"Held": 6,"Dropped": 0,"Mine": -3}
itgScoreWeights = {"Fantastic": 5,"Excellent": 4,"Great": 2,"Decent": 0,"Way Off": -6,"Miss": -12,"Held": 5,"Dropped": 0,"Mine": -6}

sigmods = {"C": "CMod","ITG": "Played on ITG Mode","NoBoys": "Fault Window Disabled","BigBoys": "Fault Window Extended","FA100": "10ms FA+","FA125": "12.5ms FA+",\
"FA150": "15ms FA+","NoMines": "No Mines","Left": "Turn Left","Right": "Turn Right","Mirror": "Mirror","Shuffle": "Shuffle","SoftShuffle": "SoftShuffle",\
"SuperShuffle": "Blender"}

def PrintSignificantMods(line):
    if line == "" or line == "-":
        print("No significant mods used.")
        return
    print("Significant mods used:")
    for mod in line.split(","):
        print(sigmods[mod])
    print("")

def PrintChartInfo():
    print("Song title: %s\nArtist: %s\nBPM: %s\nRate mod: %s\nDifficulty rating: %d\nDate obtained: %s\nSteps: %d\nHolds: %d\nRolls: %d\nMines: %d" \
    % (Title, Artist, BPMs, Rate, Rating, DateObtained, StepCount, Holds, Rolls, Mines))
    print("")

def GetJudgment(offset, game = "WF"):
    if game == "WF":
        windows = standardWindows
        names = standardWindowNames
    elif game == "ITG":
        windows = itgWindows
        names = itgWindowNames
    else:
        print("that's not a real game")
        return
    
    for i in range(len(windows)):
        if abs(offset) <= windows[i]:
            return names[i]
    
    # based on the logic of the how judgments are recorded you shouldn't have misses as offsets tho......
    return "Miss"
    
def GetJudgmentCounts(gametype = "WF"):
    j = {}
    if gametype == "WF":
        names = standardWindowNames
    elif gametype == "ITG":
        names = itgWindowNames
    else:
        print("?")
        return
    for name in names:
        j[name] = 0
    j["Held"] = 0
    j["Dropped"] = 0
    j["Mine"] = 0
    for judgment in RawJudgments:
        if judgment["JudgeType"] == "TapHit":
            judge = GetJudgment(judgment["Offset"], gametype)
        else:
            judge = judgment["JudgeType"]
        j[judge] += 1
    
    return j
    
def GetPerPanelJudgments(gametype = "WF"):
    j = {}
    if gametype == "WF":
        names = standardWindowNames
    elif gametype == "ITG":
        names = itgWindowNames
    else:
        print("?")
        return
    for name in names:
        j[name] = {"Left": 0,"Down": 0,"Up": 0,"Right": 0}
    j["Held"] = {"Left": 0,"Down": 0,"Up": 0,"Right": 0}
    j["Dropped"] = {"Left": 0,"Down": 0,"Up": 0,"Right": 0}
    j["Mine"] = {"Left": 0,"Down": 0,"Up": 0,"Right": 0}
    for judgment in RawJudgments:
        if judgment["JudgeType"] == "TapHit":
            judge = GetJudgment(judgment["Offset"], gametype)
        else:
            judge = judgment["JudgeType"]
        for p in judgment["Panels"]:
            j[judge][p] += 1
    
    return j
    
def GetPercentDP(judgments, notecount, holdcount):
    try:
        test = judgments["Masterful"]
        names = standardWindowNames
        weights = standardScoreWeights
    except KeyError:
        names = itgWindowNames
        weights = itgScoreWeights
    
    possibledp = notecount * weights[names[0]] + holdcount * weights["Held"]
    dp = 0
    for name in names:
        dp += judgments[name] * weights[name]
    dp += judgments["Held"] * weights["Held"]
    dp += judgments["Dropped"] * weights["Dropped"]
    dp += judgments["Mine"] * weights["Mine"]
    return max(0, 100.0 * float(dp) / float(possibledp))
    
def GetMeanTimingError():
    totaloffset = 0
    hits = 0
    for judgment in RawJudgments:
        if judgment["JudgeType"] == "TapHit":
            hits += 1
            totaloffset += abs(judgment["Offset"])
    return totaloffset/hits
    
def PrintJudgmentCounts(judgments):
    try:
        test = judgments["Masterful"]
        names = standardWindowNames
    except KeyError:
        names = itgWindowNames
    
    for name in names:
        print("%s: %d" % (name, judgments[name]))
    print("Holds/rolls held: %d" % judgments["Held"])
    print("Holds/rolls dropped: %d" % judgments["Dropped"])
    print("Mines hit: %d" % judgments["Mine"])
    print("")
    
def PrintPerPanelJudgments(judgments):
    try:
        test = judgments["Masterful"]
        names = standardWindowNames
    except KeyError:
        names = itgWindowNames
    
    for name in names:
        print(name + ":")
        for arrow in arrows[1:]:
            print("%s: %6d   " % (arrow, judgments[name][arrow]), end = "")
        print("\n")
    print("Holds/rolls held:")
    for arrow in arrows[1:]:
        print("%s: %4d   " % (arrow, judgments["Held"][arrow]), end = "")
    print("\n\nHolds/rolls dropped:")
    for arrow in arrows[1:]:
        print("%s: %4d   " % (arrow, judgments["Dropped"][arrow]), end = "")
    print("\n\nMines hit:")
    for arrow in arrows[1:]:
        print("%s: %4d   " % (arrow, judgments["Mine"][arrow]), end = "")
    print("\n")

# read file
with open(filepath, "r") as f:
    allLines = f.readlines()
    
if len(allLines) < 16:
    print("?")

# song/chart info
Title = allLines[1].strip()
Artist = allLines[2].strip()
BPMs = allLines[3].strip()
Rating = int(allLines[5].strip())
DateObtained = allLines[6].strip()
Rate = allLines[7].strip()
StepCount = int(allLines[8].strip())
Holds = int(allLines[9].strip())
HoldsHeld = int(allLines[10].strip())
Rolls = int(allLines[11].strip())
RollsHeld = int(allLines[12].strip())
Mines = int(allLines[13].strip())
SignificantMods = allLines[14].strip()

# get judgment info
RawJudgments = []
for line in allLines[15:]:
    line = line.strip()
    if not line == "":
        info = line.split(";")
        obj = {}
        obj["TimeStamp"] = float(info[0])
        try:
            obj["Offset"] = float(info[1])
            obj["JudgeType"] = "TapHit"
        except ValueError:
            obj["JudgeType"] = judgetypes[info[1]]
        obj["Panels"] = []
        for i in info[2]:
            obj["Panels"].append(arrows[int(i)])
        RawJudgments.append(obj)

StandardJudgments = GetJudgmentCounts()
ITGJudgments = GetJudgmentCounts("ITG")
StandardScore = math.floor(GetPercentDP(StandardJudgments, StepCount, Holds + Rolls) * 100) / 100.0
ITGScore = math.floor(GetPercentDP(ITGJudgments, StepCount, Holds + Rolls) * 100) / 100.0
StandardPerPanel = GetPerPanelJudgments()
ITGPerPanel = GetPerPanelJudgments("ITG")
MeanTimingError = GetMeanTimingError() * 1000

PrintChartInfo()
PrintSignificantMods(SignificantMods)
print("WF stats:")
print("Score: %0.2f\n" % StandardScore)
PrintJudgmentCounts(StandardJudgments)
#PrintPerPanelJudgments(StandardPerPanel)
print("\nITG stats:")
print("Score: %0.2f\n" % ITGScore)
PrintJudgmentCounts(ITGJudgments)
#PrintPerPanelJudgments(ITGPerPanel)
print("\nMean timing error: %0.2fms" % MeanTimingError)
