extends Node

# samo referenca
enum LEVEL_TYPE {
	# seta on level ... export var
	# uporablja smamo level, da ve kaj ugasnit in prižgat
	# lahko bi "bolje", a tako je bolj jasno katere oblike so mogoče
	FREE_RIDE,
	# rank_by time
	RACING_TRACK, # start-line > race-track > finish-line
	RACING_GOALS, # start-line > goals > finish-line
	# rank_by points
	BATTLE_GOALS, # start-positions > goals
	BATTLE_SCALPS, # start-positions
	# no ranking
	MISSION, # goals
	}

# grupe
var racing_levels: Array = [
	TESTER,
	GRAND_PRIX,
	]
var battle_levels: Array = [
	]
var training_levels: Array = [
# no damage, no gas, no time
	]
var missions: Array = [
	]

const TESTER: Dictionary = {
	"level_name": "Testing level",
	"level_desc": "Za testiranje različnih značilnosti levelov.",
	"level_scene": preload("res://game/levels/LevelTester.tscn"),
	"level_thumb": preload("res://home/levels/thumb_level_race.tres"), # VERS icon
	"level_time_limit": 0, # secs
	"level_laps": 2, # 0 in 1 je isto
	# load on spawan
	"level_record": [0, ""],
	# opredeli level ob spawnu
	# "rank_by": "TIME", "POINTS, "NONE" ... "SCALPS", "CASH",
	# "level_goals": [],
	}

const FREE: Dictionary = {}
const FULL: Dictionary = {}
const SHOOTER: Dictionary = {}
const DOGFIGHT: Dictionary = {}
const AGILITY: Dictionary = {}

# Racing Track (time)
const SHORTIE: Dictionary = {} # short simple
const SNAKE: Dictionary = {} # long
const SLALOM: Dictionary = {} # agile
const ENDLESS: Dictionary = {} # short laps
const GRAND_PRIX: Dictionary = { # long laps
	"level_name": "GrandPrix",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelGrandPrix.tscn"),
	"level_thumb": preload("res://home/levels/thumb_level_race.tres"),
	"level_time_limit": 0,
	"level_laps": 2,
	"level_record": [0, ""], # pogreba sejvanega
	}

# Racing Goals (time)
const THE_LIGHTS: Dictionary = {} # flags, lose all on bump
const CANYON: Dictionary = {} # agility in kanjon
const PARKING: Dictionary = {} # slow agility (intestate 76)

# Battle (points, scalps)
const COLORS: Dictionary = {}
const YOUR_TARGETS: Dictionary = {}
const DEMOLITION_DERBY: Dictionary = {}
const DERBY: Dictionary = {}

# Mission
const GET_TO_CITY: Dictionary = {}
const GAS_TRANSPORT: Dictionary = {}
const SCOUT: Dictionary = {} # i
