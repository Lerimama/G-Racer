extends Node

## settings(namesto slovarja so variable), zagon levela), home_settings

var bolt_explosion_shake
var bullet_hit_shake
var misile_hit_shake


#var player_name: String = "P1"

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


## temp_
var odmik_od_roba = 20
var playerstats_w = 500
var playerstats_h = 32

## Z index spawnanih elementov ... relativno glede na tistega, ki jih spawna
#var bolt_z_index = -1
var weapons_z_index = -1 # bolt je 0
var engine_z_index = -1
var trail_z_index = -1
var explosion_z_index = 1

var default_game_settings: Dictionary = {
	"game_time_limit": 0, # če je 0 ni omejitve
	"timer_mode_countdown": false,
	"gameover_countdown_duration": 5,
	"start_countdown": true,
	# bricks and area values
	"goal_points": 1000,
	"light_points": 10,
	"target_brick_points": 100,
	"ghost_brick_points": 30,
	"bouncer_brick_points": 10,
	"magnet_brick_points": 0,
	"area_tracking_value": 1, # 1 = 100%
	"area_gravel_drag_force_div": 25.0, 
	"area_hole_drag_force_div": 5.0,
	"area_nitro_drag_force_div": 500.0,
	"pull_penalty_gas": -20,
	# modes
	"fight_mode": true, # take damage, energy
	"race_mode": false, # ranking, gas use
	"suddent_death_mode": false,
	"sudden_death_limit": 20,
#	"dogfight_mode": false,
#	"use_gas_mode": false,
}

enum Levels {TRAINING, NITRO, DOGFIGHT}

var level_settings: Dictionary = {
	Levels.TRAINING: {
		"level": Levels.TRAINING,
		"level_path": "res://game/levels/LevelTraining.tscn",
		"level_scene": preload("res://game/levels/LevelTraining.tscn"),
		},
	Levels.NITRO: {
		"level": Levels.NITRO,
		"level_path": "res://game/levels/LevelNitroOrig.tscn",
		"level_scene": preload("res://game/levels/LevelNitroOrig.tscn"),
#		"level_scene": preload("res://game/levels/LevelNitro.tscn"),
#		"level_path": "res://game/levels/LevelNitro.tscn",
		},
	Levels.DOGFIGHT: {
		"level": Levels.DOGFIGHT,
		"level_path": "res://game/levels/LevelDogfight.tscn",
#		"level_scene": preload("res://game/levels/LevelDogfight.tscn"),
		"level_scene": preload("res://game/levels/LevelDogfight.tscn"),
		} 
}


# ON GAME START -----------------------------------------------------------------------------------


var current_game_settings: Dictionary = {} # ta je uporabljen ob štartu igre
var current_level_settings: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var selected_level: int

func _ready() -> void:
	
	# če greš iz menija je tole povoženo
#	var debug_level = Levels.NITRO
#	var debug_level = Levels.TRAINING
	var debug_level = Levels.DOGFIGHT
	set_game_settings(debug_level)
	
	
func set_game_settings(selected_level) -> void:
	
	current_game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	match selected_level:
		Levels.TRAINING: 
			current_level_settings = level_settings[Levels.TRAINING]
#			current_game_settings["area_nitro_value"] = 0
			current_game_settings["start_countdown"] = false
			current_game_settings["race_mode"] = false
			current_game_settings["fight_mode"] = true			
		Levels.NITRO: 
			current_level_settings = level_settings[Levels.NITRO]
			current_game_settings["start_countdown"] = false
			current_game_settings["race_mode"] = true
			current_game_settings["fight_mode"] = false
		Levels.DOGFIGHT: 
			current_level_settings = level_settings[Levels.DOGFIGHT]
			current_game_settings["start_countdown"] = false
			current_game_settings["race_mode"] = false
			current_game_settings["fight_mode"] = true


#
#var default_game_settings: Dictionary = {
#	# to so default CLEANER settings
#	# player on start
#	"player_start_life": 1, # 1 lajf skrije ikone v hudu in določi "lose_life_on_hit"
#	"player_start_energy": 192, # če je 0, je 0 ... instant GO
#	"player_start_color": Color("#232323"), # old #141414
#	# player in game
#	"player_max_energy": 192, # max energija
#	"player_tired_energy": 20, # pokaže steps warning popup in hud oabrva rdeče
#	"step_time_fast": 0.09, # default hitrost
#	"step_time_slow": 0.15, # minimalna hitrost
#	"step_slowdown_rate": 18, # delež energije, manjši pada hitreje
#	"step_slowdown_mode": true,
#	"lose_life_on_hit": false, # zadetek od igralca ali v steno pomeni izgubo življenja, alternativa je izguba energije
#	# scoring
#	"all_cleaned_points": 100,
#	"color_picked_points": 2, 
#	"cell_traveled_points": 0,
#	"skill_used_points": 0,
#	"burst_released_points": 0,
#	"on_hit_points_part": 2,
#	# energija
#	"color_picked_energy": 10,
#	"cell_traveled_energy": -1,
#	"skill_used_energy": 0,
#	"burst_released_energy": 0,
#	"on_hit_energy_part": 2, # delež porabe od trenutne energije
#	"touching_stray_energy": 0,
#	# game
#	"game_instructions_popup": true,
#	"camera_fixed": false,
#	"gameover_countdown_duration": 5,
#	"sudden_death_limit" : 20,
#	"show_position_indicators_stray_count": 5,
#	"start_countdown": true,
#	"timer_mode_countdown" : true, # če prišteva in je "game_time_limit" = 0, nima omejitve navzgor
#	"minimap_on": false,
#	"position_indicators_mode": true, # duel jih nima 
#	"suddent_death_mode": false,
#	"manage_highscores": true, # obsoleten, ker je vključen v HS type
##	"stray_step_time": 0.2,
#}


#
#var anchor_L = odmik_od_roba
#var anchor_R = get_viewport_rect().size.x - odmik_od_roba - playerstats_w
#var anchor_U = odmik_od_roba
#var anchor_D = get_viewport_rect().size.y - odmik_od_roba - playerstats_h
#
#var playerstats_positions : Dictionary = {
#	"playerstats_position_1" : Vector2 (anchor_L,anchor_U),
#	"playerstats_position_2" : Vector2 (anchor_R,anchor_U),
#	"playerstats_position_3" : Vector2 (anchor_L,anchor_D),
#	"playerstats_position_4" : Vector2 (anchor_R,anchor_D),
#	}	


#var player_hud_positions : Dictionary = {
#	"position_1" : Vector2(-16, -16),
#	"position_2" : Vector2(688, 668),
#	"position_3" : Vector2(678, -16),
#	"position_4" : Vector2(-16, 744),
#	}


# -------------------------------------------------------------------------------------------------------------
#	GAME VALUES
# -------------------------------------------------------------------------------------------------------------

var default_game_theme : Dictionary = {

	"disabled_player_color" : Color.gray,

	# menus
	"menu_text_color" : Color.white,
	"menu_accent_color" : Color.orange,
	"menu_edit_color" : Color.red, # v rabi v controller meniju
	"menu_colorsq_size" : Vector2(40, 40),
	"menu_colorsq_select_size" : Vector2(24, 24),

	#hud
	"icon_color" : Color.palegoldenrod,
	"label_color" : Color.pink,
	"minus_color" : Color.red,
	"plus_color" : Color.green, # drugačna ker se to zgodi na bonus efekt
	}

var game_rules : Dictionary = {

	# player_default_values diki?

	"score for win" : Color.red,
	"wins for turnament win" : Color.red,
	}

var level_values : Dictionary = { # tale bo na koncu obsoleten, al bo za drzgam?

	# e bonus
	"energy_bonus" : 10,
	"bonus_e_color" : Color.yellow,
	# m bonus
	"misile_bonus" : 1,
	"bonus_m_color" : Color.pink,

	# pointer
	"pointer_points" : 100,
	"pointer_color" : Color.aquamarine,
	"pointer_brake" : 3,
	# exploder
	"exploder_color_1" : Color.purple,
	"exploder_color_2" : Color.pink,
	"exploder_color_3" : Color.white,
	# bonucer
	"bouncer_color" : Color.violet,
	"bouncer_strenght" : 2,
	# magnet
	"magnet_color" : Color.aquamarine, # !!!! float
	"gravity_velocity" : 3.0, 	# hitrost glede na distanco od magneta ...gravitacijski pospešek	!!!! float
	"gravity_force" : 50000.0, 	# sila gravitacije 		!!!!!!!const

	}

