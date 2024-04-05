extends Node

## settings(namesto slovarja so variable), zagon levela), home_settings


## temp
var odmik_od_roba = 20
var playerstats_w = 500
var playerstats_h = 32
var bolt_explosion_shake
var bullet_hit_shake
var misile_hit_shake

# game colors
var color_gray0 = Color("#535b68") # najsvetlejša
var color_gray1 = Color("#404954")
var color_gray2 = Color("#2f3649")
var color_gray3 = Color("#272d3d")
var color_gray4 = Color("#1d212d")
var color_gray5 = Color("#171a23") # najtemnejša
var color_gray_trans = Color("#272d3d00") # transparentna
var color_red = Color("#f35b7f")
var color_green = Color("#5effa9")
var color_blue = Color("#4b9fff")
var color_yellow = Color("#fef98b")
var color_hud_base = Color("#ffffff")

## Z index spawnanih elementov ... relativno glede na tistega, ki jih spawna
#var bolt_z_index = -1
var weapons_z_index = -1 # bolt je 0
var engine_z_index = -1
var trail_z_index = -1
var explosion_z_index = 1

var debug_mode = true
#var debug_mode = false

var default_game_settings: Dictionary = { # tukaj imam settingse ki jih lahko še spreminjam glede na tip igre
	# bricks and area values ... drugam
	"goal_points": 1000,
	"light_points": 10,
	"target_brick_points": 100,
	"ghost_brick_points": 30,
	"bouncer_brick_points": 10,
	"magnet_brick_points": 0,
	"area_tracking_value": 1, # 1 = 100%
	# level
	"gravel_drag_div": 25.0, 
	"hole_drag_div": 5.0,
	"nitro_drag_div": 500.0,	
	
#	"area_gravel_drag_force_div": 25.0, 
#	"area_hole_drag_force_div": 5.0,
#	"area_nitro_drag_force_div": 500.0,
##	"precision_start_drag_force_div": 500.0, # drugam
#
#	"area_gravel_drag": 6,
#	"area_hole_drag": 30,
#	"area_nitro_drag": 0.3,
#	"precision_start_drag": 0.3,
	
	# time
	"stopwatch_mode": true, # uravnavam tudi s skrivanjem lučk ... za quick switch
	"game_time_limit": 0, # če je 0 ni omejitve
	# countdown
	"start_countdown": false,
	"gameover_countdown_duration": 5,
	# race
	"race_mode": false, # ranking, gas use, enemy AI
	"pull_gas_penalty": -20,
	# duel
	"pickables_count_limit": 5,
	"sudden_death_mode": false,
	"sudden_death_limit": 10, # koliko pred koncem
	# modes
	"enemies_mode": false,
	"easy_mode": false,
	"full_equip_mode": true,
}

enum Levels {
	RACE_DIRECT, RACE_ROUND, RACE_CIRCO, RACE_SNAKE, RACE_NITRO
	TRAINING, 
	NITRO, 
	RACE_8, 
	DUEL, 
	DEBUG_RACE, 
	DEBUG_DUEL, 
	NITRO_STRAIGHT
	}

var level_settings: Dictionary = {
	Levels.TRAINING: {
		"level": Levels.TRAINING,
		"level_path": "res://game/levels/LevelTraining.tscn",
		"time_limit": 10,
		"lap_limit": 0,
		},
	Levels.NITRO: {
		"level": Levels.NITRO,
		"level_path": "res://game/levels/LevelRaceNitro.tscn",
		"time_limit": 0,
		"lap_limit": 10,
		},
	Levels.NITRO_STRAIGHT: {
		"level": Levels.NITRO_STRAIGHT,
		"level_path": "res://game/levels/LevelNitroStraight.tscn",
		"time_limit": 0,
		"lap_limit": 1,
		},
	Levels.RACE_8: {
		"level": Levels.RACE_8,
		"level_path": "res://game/levels/Level8.tscn",
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
		"lap_limit": 2,
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


# UPDATE GAME SETTINGS -----------------------------------------------------------------------------------


var players_on_game_start: Array # seta se iz home
var current_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var current_level_settings: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"

#var current_game_levels: Array = []
#var current_game_levels: Array = [Levels.RACE_SNAKE]
var current_game_levels: Array = [Levels.RACE_DIRECT, Levels.RACE_SNAKE]
#var current_game_levels: Array = [Levels.RACE_ROUND, Levels.RACE_DIRECT]
#var game_levels: Array = [Levels.RACE_DIRECT, Levels.RACE_SNAKE, Levels.RACE_DIRECT, Levels.RACE_ROUND]
#var game_levels: Array = [Levels.RACE_DIRECT, Levels.RACE_CIRCO, Levels.RACE_ROUND, Levels.RACE_SNAKE, Levels.RACE_NITRO]


func get_level_game_settings(selected_level_index: int):
	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	current_game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	var current_level: int = current_game_levels[selected_level_index]
	
	match current_level:
		# racing
		Levels.RACE_DIRECT: 
			current_game_settings["race_mode"] = true
#			current_game_settings["start_countdown"] = true
		Levels.RACE_CIRCO: 
			current_game_settings["race_mode"] = true
		Levels.RACE_ROUND: 
			current_game_settings["race_mode"] = true
		Levels.RACE_SNAKE: 
			current_game_settings["race_mode"] = true
#			current_game_settings["start_countdown"] = true
		Levels.RACE_NITRO: 
			current_game_settings["race_mode"] = true
		Levels.RACE_8: 
			current_game_settings["race_mode"] = true
		# duel
		Levels.DUEL: 
			current_game_settings["start_countdown"] = false
			current_game_settings["sudden_death_mode"] = true
			current_game_settings["stopwatch_mode"] = false		
		# trening
		Levels.TRAINING: 
			current_game_settings["race_mode"] = true
		
		Levels.NITRO: 
			current_game_settings["race_mode"] = true
		Levels.NITRO_STRAIGHT: 
			current_game_settings["race_mode"] = true
		Levels.DEBUG_RACE: 
			current_game_settings["race_mode"] = true
		Levels.DEBUG_DUEL: 
			current_game_settings["stopwatch_mode"] = false		
			current_game_settings["sudden_death_mode"] = true
			

	return current_game_settings
