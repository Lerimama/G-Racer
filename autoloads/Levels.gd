extends Node

# samo referenca
enum _referenca_LEVEL_TYPE {
	FREE_RIDE, # none rank, no time limit
	RACING_TRACK, # time rank, laps, no damage / elements: start line + tracking line + finish line
	RACING_GOALS, # time rank, no laps, no damage / elements: start line + goals + finish line
	BATTLE_GOALS, # points rank, no laps, damage / elements: goals
	BATTLE_SCALPS, # scalps rank, no laps, damage, / elements: drivers
	MISSION, # none rank, time limit / elements: drivers
	}

enum RANK_BY {NONE, TIME, POINTS, SCALPS} # še ne uporabljam

var training_levels: Array = [LEVEL.TRAINING_DRIVE, LEVEL.TRAINING_AGILITY, LEVEL.TRAINING_SHOOT]
var racing_levels: Array = [LEVEL.QUICKY, LEVEL.SERPENTINE, LEVEL.THE_LOOP, LEVEL.GRAND_PRIX]
var goal_levels: Array = [LEVEL.LIGHTS_ON, LEVEL.THE_KNOT, LEVEL.FINESS]
var battle_levels: Array = [LEVEL.COLORS, LEVEL.YOUR_TARGETS, LEVEL.DEMOLITION_DERBY, LEVEL.DERBY]
var mission_levels: Array = [LEVEL.TRAVEL, LEVEL.GAS_TRANSPORT, LEVEL.SCOUT]


func _ready() -> void:
	# dodam postavke, ki si jih delijo
	# določeni stili levela ne rabijo določenih postavk ... da ni potrebno preverjeati, če obstaja

	for level in training_levels:
		level_profiles[level]["rank_by"] = RANK_BY.NONE
		level_profiles[level]["level_goals"] = []
		level_profiles[level]["level_time_limit"] = 0
		level_profiles[level]["level_lap_count"] = 0
	for level in racing_levels:
		# z goali nima krogov
		if not "rank_by" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["rank_by"] = RANK_BY.TIME
		if not "level_lap_count" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["level_lap_count"] = 0
		level_profiles[level]["level_time_limit"] = 0
		level_profiles[level]["level_goals"] = []
	for level in goal_levels:
		# goali nimajo krogov
		if not "rank_by" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["rank_by"] = RANK_BY.POINTS
		if not "level_lap_count" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["level_lap_count"] = 0
		level_profiles[level]["level_goals"] = []
	for level in battle_levels:
		if not "rank_by" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["rank_by"] = RANK_BY.SCALPS
		level_profiles[level]["level_lap_count"] = 0
		level_profiles[level]["level_goals"] = []
	for level in mission_levels:
		if not "rank_by" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["rank_by"] = RANK_BY.NONE
		if not "level_time_limit" in level_profiles[level]: # če je kaj drugega je opredeljeno v profilu
			level_profiles[level]["level_time_limit"] = 0
		level_profiles[level]["level_lap_count"] = 0
		level_profiles[level]["level_goals"] = []


func TRENING(): pass
# no damage, no gas, no time, no laps, no goals

enum LEVEL {
	TESTER,
	TRAINING_DRIVE, TRAINING_AGILITY, TRAINING_SHOOT, TRAINING_BATTLE, # free
	QUICKY, SERPENTINE, THE_LOOP, GRAND_PRIX, # race, time
	LIGHTS_ON, THE_KNOT, FINESS, # derby, goals
	COLORS, YOUR_TARGETS, DEMOLITION_DERBY, DERBY # battle
	TRAVEL, GAS_TRANSPORT, SCOUT # battle
	}


var level_profiles: Dictionary = {

	LEVEL.TESTER: {
		"level_name": "Testing level",
		"level_desc": "Za testiranje različnih značilnosti levelov.",
		"level_scene": preload("res://game/levels/LevelTester.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0, # secs
		"level_lap_count": 0, # 0 in 1 je isto
		"rank_by": RANK_BY.TIME,
		# load on spawan, če je ranking
		# "level_record": [0, ""],
		# opredeli level ob spawnu
		# "level_goals": [],
		# "level_goals": [],
		},

	LEVEL.TRAINING_DRIVE: {
		"level_name": "TRAINING DRIVE",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTrainingDrive.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 0,
		},
	LEVEL.TRAINING_AGILITY: {
		"level_name": "TRAINING AGILITY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTrainingAgility.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 0,
		},
	LEVEL.TRAINING_SHOOT: {
		"level_name": "TRAINING SHOOT",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTrainingShoot.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		},
	LEVEL.TRAINING_BATTLE: {
		"level_name": "TRAINING BATTLE",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTrainingBattle.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		},
	LEVEL.QUICKY: { # short simple
		"level_name": "QUICKY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelQuicky.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_lap_count": 0,
		},
	LEVEL.SERPENTINE: { # long
		"level_name": "SERPENTINE",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelSerpentine.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_lap_count": 0,
		},
	LEVEL.THE_LOOP: { # short laps
		"level_name": "THE_LOOP",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTheLoop.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_lap_count": 0,
		},
	LEVEL.GRAND_PRIX: { # long laps
		"level_name": "GRAND PRIX",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelGrandPrix.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_lap_count": 2,
		},
	LEVEL.LIGHTS_ON: { # flags, lose all on bump
		"level_name": "LIGHTS_ON",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelLightsOn.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 0,
		},
	LEVEL.THE_KNOT: { # agility in kanjon
		"level_name": "THE_KNOT",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTheKnot.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 0,
		},
	LEVEL.FINESS: { # slow agility (intestate 76)
		"level_name": "FINESS",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelFiness.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 0,
		},
	LEVEL.COLORS: {
		"level_name": "DEMOLITION DERBY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 2,
		},
	LEVEL.YOUR_TARGETS: {
		"level_name": "DEMOLITION DERBY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		"level_lap_count": 2,
		},
	LEVEL.DEMOLITION_DERBY: {
		"level_name": "DEMOLITION DERBY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelDemolitionDerby.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		},
	LEVEL.DERBY: {
		"level_name": "DERBY",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelDerby.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		},
	# missions
	LEVEL.TRAVEL: {
		"level_name": "TRAVEL",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelTravel.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		},
	LEVEL.GAS_TRANSPORT: {
		"level_name": "GAS TRANSPORT",
		"level_desc": "Level description ... ",
		"level_scene": preload("res://game/levels/LevelGasTransport.tscn"),
		"level_thumb": preload("res://game/levels/thumbs/thumb_level_default.tres"),
		"level_time_limit": 0,
		},
	LEVEL.SCOUT: {},

}
