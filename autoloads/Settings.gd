extends Node


var game_camera_zoom_factor: float = 0.25 # resolucija igre je 4 krat manjša 2560x1440 proti 640x360
var camera_shake_on: bool =  true
var get_it_time: float = 2

# Z-index spawnanih elementov ... relativno glede na tistega, ki jih spawna
var weapons_z_index = -1 # bolt je 0
var engine_z_index = -1
var trail_z_index = -1
var explosion_z_index = 1

enum Levels {
	RACE_DIRECT, RACE_ROUND, RACE_8, RACE_CIRCO, RACE_SNAKE, RACE_NITRO, 
	RACE_TRAINING, 
	TRAINING, 
	DUEL, 
	DEBUG_RACE, 
	DEBUG_DUEL, 
	}
var level_settings: Dictionary = {
	Levels.TRAINING: {
		"level": Levels.TRAINING,
		"level_path": "res://game/levels/LevelTraining.tscn",
		"time_limit": 0,
		"lap_limit": 0,
		},
	Levels.RACE_TRAINING: {
		"level": Levels.RACE_TRAINING,
		"level_path": "res://game/levels/LevelRaceTraining.tscn",
		"time_limit": 0,
		"lap_limit": 2,
		},
	Levels.RACE_8: {
		"level": Levels.RACE_8,
		"level_path": "res://game/levels/LevelRace8.tscn",
		"time_limit": 0,
		"lap_limit": 2,
		},
	Levels.DUEL: {
		"level": Levels.DUEL,
		"level_path": "res://game/levels/LevelDuel.tscn",
		"time_limit": 0,
		"lap_limit": 0,
		},
	Levels.DEBUG_RACE: {
		"level": Levels.DEBUG_RACE,
		"level_path": "res://game/levels/LevelDebugRace.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
	Levels.DEBUG_DUEL: {
		"level": Levels.DEBUG_DUEL,
		"level_path": "res://game/levels/LevelDebugDuel.tscn",
		"time_limit": 10,
		"lap_limit": 0,
		},
	Levels.RACE_DIRECT: {
		"level": Levels.RACE_DIRECT,
		"level_path": "res://game/levels/LevelRaceDirect.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
	Levels.RACE_CIRCO: {
		"level": Levels.RACE_CIRCO,
		"level_path": "res://game/levels/LevelRaceCirco.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
	Levels.RACE_ROUND: {
		"level": Levels.RACE_ROUND,
		"level_path": "res://game/levels/LevelRaceRound.tscn",
		"time_limit": 0,
		"lap_limit": 3,
		},
	Levels.RACE_SNAKE: {
		"level": Levels.RACE_SNAKE,
		"level_path": "res://game/levels/LevelRaceSnake.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
	Levels.RACE_NITRO: {
		"level": Levels.RACE_NITRO,
		"level_path": "res://game/levels/LevelRaceNitro.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
}

enum GameModes {SINGLE, CAMPAIGN, TOURNAMENT, PRACTICE, BATTLE, SKILLS} # ... ni še
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
}


# UPDATE GAME SETTINGS -----------------------------------------------------------------------------------


var players_on_game_start: Array # seta se iz home
var current_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var current_level_settings: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"

#var current_game_levels: Array = []
#var current_game_levels: Array = [Levels.TRAINING]
#var current_game_levels: Array = [Levels.RACE_TRAINING]
#var current_game_levels: Array = [Levels.RACE_SNAKE]
var current_game_levels: Array = [Levels.RACE_8]
#var current_game_levels: Array = [Levels.RACE_ROUND]
#var current_game_levels: Array = [Levels.RACE_CIRCO]
#var current_game_levels: Array = [Levels.RACE_DIRECT]
#var current_game_levels: Array = [Levels.RACE_NITRO]
#var current_game_levels: Array = [Levels.RACE_DIRECT, Levels.RACE_SNAKE]
#var current_game_levels: Array = [Levels.RACE_DIRECT, Levels.RACE_CIRCO, Levels.RACE_ROUND, Levels.RACE_SNAKE, Levels.RACE_NITRO]

	
func get_level_game_settings(selected_level_index: int):
	
	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	current_game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	var current_level: int = current_game_levels[selected_level_index]
	
	# debug
	current_game_settings["start_countdown"] = false
	
	match current_level:
		# racing
		Levels.RACE_DIRECT: pass
		Levels.RACE_CIRCO: pass
		Levels.RACE_ROUND: pass 
		Levels.RACE_SNAKE: pass
		Levels.RACE_NITRO: pass
		Levels.RACE_8: pass
		# duel
		Levels.DUEL: 
			current_game_settings["start_countdown"] = false
			current_game_settings["sudden_death_mode"] = true
#			current_game_settings["stopwatch_mode"] = false		
		# trening
		Levels.TRAINING: pass
		Levels.DEBUG_RACE: pass
		Levels.DEBUG_DUEL: 
			current_game_settings["stopwatch_mode"] = false		
#			current_game_settings["sudden_death_mode"] = true
			
	return current_game_settings # pobere GM ob setanju igre
