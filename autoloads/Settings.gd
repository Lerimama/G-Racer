extends Node


var game_camera_zoom_factor: float = 0.25 # resolucija igre je 4 krat manjša 2560x1440 proti 640x360
var camera_shake_on: bool =  true
var get_it_time: float = 2

# game units ... ferrari je 4500 mm bolt pa 225px
var kg_per_unit_mass = 10
var px_per_unit_meter = 50
var mm_per_32_grid_unit: float = 640 # grid enotra je 32px, 1 px je 2 cm
var m_per_32_grid_unit: float = 0.64 # grid enotra je 32px, 1 px je 2 cm
var unit_one: float = 32

enum LEVEL {
	FIRST_DRIVE,
	STAFF,
	ROUND, DUEL, NITRO, CITY,
#	RACE_DIRECT, RACE_ROUND, RACE_8, RACE_CIRCO, RACE_SNAKE, RACE_NITRO,
#	RACE_TRAINING,
#	TRAINING,
#	DEBUG_RACE,
#	DEBUG_DUEL,
#	FREE, TESTDRIVE,
	}
var level_settings: Dictionary = {
	LEVEL.FIRST_DRIVE: {
		"level_type": "RACING", # ko bi le lahko level podatki bli tukej
		"level_name": "",
		"level_path": "res://game/level/Level.tscn",
		"time_limit": 0,
		"lap_limit": 0,
		},
	LEVEL.STAFF: {
#		"level_type": "BATTLE", # ko bi le lahko level podatki bli tukej
		"level_type": "RACING", # _temp ...  ko bi le lahko level podatki bli tukej
#		"level_type": "RACE_GOAL", # _temp ...  ko bi le lahko level podatki bli tukej
		"level_name": "",
		"level_path": "res://game/level/LevelStaff.tscn",
		"time_limit": 0,
		"lap_limit": 0,
		},
}

enum GAME_MODE {SINGLE, CAMPAIGN, TOURNAMENT, PRACTICE, BATTLE, SKILLS} # ... ni še
var default_game_settings: Dictionary = { # setano za dirkanje

	# time
#	"stopwatch_mode": true, # uravnavam tudi s skrivanjem lučk ... za quick switch
	"game_time_limit": 0, # če je 0 ni omejitve
	# countdown
	"start_countdown": true,
	"countdown_start_limit": 5,
	# race
	"pull_gas_penalty": -20,
	"fast_start_window_time": 0.32,
	# duel
	"pickables_count_limit": 5,
	"sudden_death_mode": false, # vklopljen, če čas ni omejen
	# modes
	"enemies_mode": false,
	"easy_mode": false,
	"full_equip_mode": true,
	"drifting_mode": true, # drift ali tilt?
	# shadows
	"game_shadows_rotation_deg": 45,
	"game_shadows_color": Color.black, # odvisna od višine vira svetlobe
	"game_shadows_length_factor": 1, # odvisna od višine vira svetlobe
	"game_shadows_alpha": 0.4, # odvisna od moči svetlobe
	# camera
	"camera_zoom_range": [1, 1.5],
}


# UPDATE GAME SETTINGS -----------------------------------------------------------------------------------


var drivers_on_game_start: Array # seta se iz home
var current_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var current_level_settings: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"

#var current_game_levels: Array = []
#var current_game_levels: Array = [LEVEL.ROUND]
var current_game_levels: Array = [LEVEL.STAFF]
#var current_game_levels: Array = [LEVEL.FIRST_DRIVE]
#var current_game_levels: Array = [LEVEL.NITRO]
#var current_game_levels: Array = [LEVEL.00]

func _ready() -> void:

	if OS.is_debug_build():
		default_game_settings["camera_zoom_range"] = [3, 3]
#		default_game_settings["camera_zoom_range"] = [6, 6]
		default_game_settings["start_countdown"] = false
		default_game_settings["easy_mode"] = true
		default_game_settings["game_shadows_direction"] = Vector2(-800, 0)


func get_level_game_settings(selected_level_index: int):

	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	current_game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	var current_level: int = current_game_levels[selected_level_index]

	# debug
	match current_level:
		# racing
		# duel
		LEVEL.STAFF:
			pass
#			current_game_settings["start_countdown"] = true
		LEVEL.DUEL:
			current_game_settings["start_countdown"] = false
			current_game_settings["sudden_death_mode"] = true
#			current_game_settings["stopwatch_mode"] = false

	return current_game_settings # pobere GM ob setanju igre
