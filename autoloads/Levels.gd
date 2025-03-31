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


func _ready() -> void:
	# določeni stili levela ne rabijo določenih postavk
	# tukaj jih nulirane, da ni kakega errorja

	for level in racing_levels:
		if not "level_laps" in level:
			level["level_laps"] = 0
		level["rank_by"] = "TIME"
		level["level_goals"] = []
	for level in training_levels:
		level["level_goals"] = []
		level["level_time"] = 0
		level["level_laps"] = 0
	for level in battle_levels:
		level["level_goals"] = []
		level["level_laps"] = 0


const TESTER: Dictionary = {
	"level_name": "Testing level",
	"level_desc": "Za testiranje različnih značilnosti levelov.",
	"level_scene": preload("res://game/levels/LevelTester.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0, # secs
	"level_laps": 0, # 0 in 1 je isto
	"rank_by": "TIME"

	# load on spawan, če je ranking
	# "level_record": [0, ""],
	# opredeli level ob spawnu
	# "level_goals": [],
	# "rank_by": "TIME", "POINTS, ... "SCALPS", "CASH",
	# "level_goals": [],
	}


func TRENING(): pass
# no damage, no gas, no time, no laps, no goals

var training_levels: Array = [TRAINING_DRIVE, TRAINING_AGILITY, TRAINING_SHOOT]
const TRAINING_DRIVE: Dictionary = {
	"level_name": "TRAINING DRIVE",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTrainingDrive.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const TRAINING_AGILITY: Dictionary = {
	"level_name": "TRAINING AGILITY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTrainingAgility.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const TRAINING_SHOOT: Dictionary = {
	"level_name": "TRAINING SHOOT",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTrainingShoot.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	}
const TRAINING_BATTLE: Dictionary = {
	"level_name": "TRAINING BATTLE",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTrainingBattle.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	}


func REJSING(): pass
# time, gas, no damage, no goals

var racing_levels: Array = [QUICKY, SERPENTINE, THE_LOOP, GRAND_PRIX]
const QUICKY: Dictionary = { # short simple
	"level_name": "QUICKY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelQuicky.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const SERPENTINE: Dictionary = { # long
	"level_name": "SERPENTINE",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelSerpentine.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const THE_LOOP: Dictionary = { # short laps
	"level_name": "THE_LOOP",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTheLoop.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const GRAND_PRIX: Dictionary = { # long laps
	"level_name": "GRAND PRIX",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelGrandPrix.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 2,
	}


func GOULS(): pass
# Racing Goals (time, points) ... da le prideš do konca z vsemi cilji

var goals_levels: Array = [LIGHTS_ON, THE_KNOT, FINESS]
const LIGHTS_ON: Dictionary = { # flags, lose all on bump
	"level_name": "LIGHTS_ON",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelLightsOn.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const THE_KNOT: Dictionary = { # agility in kanjon
	"level_name": "THE_KNOT",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTheKnot.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}
const FINESS: Dictionary = { # slow agility (intestate 76)
	"level_name": "FINESS",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelFiness.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 0,
	}


func BATTLE(): pass
# Battle (points, scalps)

var battle_levels: Array = []
const COLORS: Dictionary = {
	"level_name": "DEMOLITION DERBY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 2,
	}
const YOUR_TARGETS: Dictionary = {
	"level_name": "DEMOLITION DERBY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	"level_laps": 2,
	}
const DEMOLITION_DERBY: Dictionary = {
	"level_name": "DEMOLITION DERBY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	}
const DERBY: Dictionary = {
	"level_name": "DERBY",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelDerby.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	}


func MISSIONS(): pass
# Mission

var missions: Array = []
const TRAVEL: Dictionary = {
	"level_name": "TRAVEL",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelTravel.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	}
const GAS_TRANSPORT: Dictionary = {
	"level_name": "GAS TRANSPORT",
	"level_desc": "Level description ... ",
	"level_scene": preload("res://game/levels/LevelGasTransport.tscn"),
	"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
	"level_time": 0,
	}
const SCOUT: Dictionary = {} # i
