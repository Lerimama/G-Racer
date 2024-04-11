extends Node
# game data

# DEFAULT -----------------------------------------------------------------------------------


var default_player_stats: Dictionary = {
	"player_name" : "Somebody", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life" : 0, # se opredeli iz game_settings
	"player_energy" : 0, # se opredeli iz game_settings
	"player_points": 0,
	"colors_collected": 0,
	"skill_count" : 0,
	"burst_count" : 0,
	"cells_traveled" : 0,
}


var default_game_settings: Dictionary = {
	# to so default CLEANER settings
	# player on start
	"player_start_life": 1, # 1 lajf skrije ikone v hudu in določi "lose_life_on_hit"
	"player_start_energy": 192, # če je 0, je 0 ... instant GO
	"player_start_color": Color("#232323"), # old #141414
	# player in game
	"player_max_energy": 192, # max energija
	"player_tired_energy": 20, # pokaže steps warning popup in hud oabrva rdeče
	"step_time_fast": 0.09, # default hitrost
	"step_time_slow": 0.15, # minimalna hitrost
	"step_slowdown_rate": 18, # delež energije, manjši pada hitreje
	"step_slowdown_mode": true,
	"lose_life_on_hit": false, # zadetek od igralca ali v steno pomeni izgubo življenja, alternativa je izguba energije
	# scoring
	"all_cleaned_points": 100,
	"color_picked_points": 2, 
	"cell_traveled_points": 0,
	"skill_used_points": 0,
	"burst_released_points": 0,
	"on_hit_points_part": 2,
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": -1,
	"skill_used_energy": 0,
	"burst_released_energy": 0,
	"on_hit_energy_part": 2, # delež porabe od trenutne energije
	"touching_stray_energy": 0,
	# game
	"game_instructions_popup": true,
	"camera_fixed": false,
	"gameover_countdown_duration": 5,
	"sudden_death_limit" : 20,
	"show_position_indicators_stray_count": 5,
	"start_countdown": true,
	"timer_mode_countdown" : true, # če prišteva in je "game_time_limit" = 0, nima omejitve navzgor
	"minimap_on": false,
	"position_indicators_mode": true, # duel jih nima 
	"suddent_death_mode": false,
	"manage_highscores": true, # obsoleten, ker je vključen v HS type
#	"stray_step_time": 0.2,
}



# DEFAULT -----------------------------------------------------------------------------------


var game_color_schemes: Dictionary = {
	"default_color_scheme": { # default
		1: Color.black, # ne velja, ker greba iz spectrum slike
		2: Color.white,	# ne velja, ker greba iz spectrum slike
	},
	"color_scheme_1":{ 
		1: Color.brown, # red
		2: Color.bisque, #yellow
	},
	"color_scheme_2":{ 
		1: Color("#f35b7f"), # red
		2: Color("#fef98b"), #yellow
	},
	"color_scheme_3":{
		1: Color("#f9aa71"), # orange
		2: Color("#fef98b"), # blue
	},
	"color_scheme_4":{
		1: Color("#fef98b"), # yellow
		2: Color("#5effa9"), # green
	},
	"color_scheme_5":{
		1: Color("#5effa9"), # green
		2: Color("#4b9fff"), # blue
	},
	"color_scheme_6":{
		1: Color("#74ffff"), # turkizna
		2: Color("#4b9fff"), # blue
	},
	"color_scheme_7":{
		1: Color("#4b9fff"), # blue
		2: Color("#ec80fb"), #purple
	},
	"color_scheme_8":{
		1: Color("#ec80fb"), # purple
		2: Color("#7053c2"), # viola
	},
	"color_scheme_9":{ 
		1: Color.magenta, # red
		2: Color.greenyellow, #yellow
	},	
}
var current_color_scheme: Dictionary = game_color_schemes["default_color_scheme"]


var scrolling_level_conditions: Dictionary = {
	1: { # tutorial stage ... možnost spucanaj cele linije
		"color_scheme": game_color_schemes["default_color_scheme"],
		"stages_per_level": 32, # tutorial je kratka ... tolk da je skor poln pa glih napreduješ
		"scrolling_pause_time": 0.7, # ne sem bit manjša od stray step hitrosti (0.2)
		"lines_scroll_per_spawn_round": 14,
		"strays_spawn_count": 5, # ne več kot 20 na linijo 
		# naj jih bo toliko, da so  lahko tudi bulki in da je čim več barv
		# kolk cirka dolžina levela ... 2,5min
	},
	2: {
		"color_scheme": game_color_schemes["color_scheme_2"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.7,
		"lines_scroll_per_spawn_round": 10,
		"strays_spawn_count": 14,
	},
	3: {
		"color_scheme": game_color_schemes["color_scheme_3"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.7,
		"lines_scroll_per_spawn_round": 9,
		"strays_spawn_count": 14,
	},
	4: {
		"color_scheme": game_color_schemes["color_scheme_4"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.7,
		"lines_scroll_per_spawn_round": 8,
		"strays_spawn_count": 14,
	},
	5: {
		"color_scheme": game_color_schemes["color_scheme_5"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.6,
		"lines_scroll_per_spawn_round": 10,
		"strays_spawn_count": 14,
	},
	6: {
		"color_scheme": game_color_schemes["color_scheme_6"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.6,
		"lines_scroll_per_spawn_round": 9,
		"strays_spawn_count": 14,
	},
	7: {
		"color_scheme": game_color_schemes["color_scheme_7"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.6,
		"lines_scroll_per_spawn_round": 8,
		"strays_spawn_count": 14,
	},
	8: {
		"color_scheme": game_color_schemes["color_scheme_8"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.5,
		"lines_scroll_per_spawn_round": 10,
		"strays_spawn_count": 14,
	},
	9: {
		"color_scheme": game_color_schemes["color_scheme_9"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.5,
		"lines_scroll_per_spawn_round": 9,
		"strays_spawn_count": 14,
	},
	10: {
		"color_scheme": game_color_schemes["default_color_scheme"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.5,
		"lines_scroll_per_spawn_round": 8,
		"strays_spawn_count": 14,
	},
}

var slider_level_conditions: Dictionary = {
	1: { # tutorial stage ... lahka in hitr
		"color_scheme": game_color_schemes["default_color_scheme"],
		"stages_per_level": 32, # lines scrolled ... tutorial je kratka ... tolk da je skor poln pa glih napreduješ
		"scrolling_pause_time": 0.7, # ne sem bit manjša od stray step hitrosti (0.2)
		"lines_scroll_per_spawn_round": 14,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5, # določim razpon random izbire, wall se spawna, če je izbrana 1 ali 2 ... manj je več možnosti 
	},
	2: {
		"color_scheme": game_color_schemes["color_scheme_2"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.65,
		"lines_scroll_per_spawn_round": 13,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5, 
	},
	3: {
		"color_scheme": game_color_schemes["color_scheme_3"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.6,
		"lines_scroll_per_spawn_round": 12,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	4: {
		"color_scheme": game_color_schemes["color_scheme_4"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.55,
		"lines_scroll_per_spawn_round": 11,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	5: {
		"color_scheme": game_color_schemes["color_scheme_5"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.5,
		"lines_scroll_per_spawn_round": 10,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	6: {
		"color_scheme": game_color_schemes["color_scheme_6"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.45,
		"lines_scroll_per_spawn_round": 9,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	7: {
		"color_scheme": game_color_schemes["color_scheme_7"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.4,
		"lines_scroll_per_spawn_round": 8,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	8: {
		"color_scheme": game_color_schemes["color_scheme_8"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.35,
		"lines_scroll_per_spawn_round": 7,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	9: {
		"color_scheme": game_color_schemes["color_scheme_9"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.3,
		"lines_scroll_per_spawn_round": 6,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
	10: {
		"color_scheme": game_color_schemes["default_color_scheme"],
		"stages_per_level": 32,
		"scrolling_pause_time": 0.25,
		"lines_scroll_per_spawn_round": 5,
		"strays_spawn_count": 14,
		"wall_spawn_random_range": 5,
	},
}

# GAMES ---------------------------------------------------------------------------------------------------------


enum Games {
	ERASER_S, ERASER_M, ERASER_L,
	CLEANER, CLEANER_DUEL,
	SCROLLER, SLIDER, SIDEWINDER,
	AMAZE, 
	RUNNER, 
	RIDDLER_S, RIDDLER_M, RIDDLER_L
	TUTORIAL,
	}


enum HighscoreTypes {
	NO_HS, 
	HS_POINTS, 
	HS_COLORS, 
	HS_TIME_LOW, 
	HS_TIME_HIGH
	}


var game_data_eraser_S: Dictionary = { 
	"game": Games.ERASER_S,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "S",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50,
}


var game_data_eraser_M: Dictionary = {
	"game": Games.ERASER_M,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "M",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser.tscn",
	"game_time_limit": 0,
	"strays_start_count": 140, 
}


var game_data_eraser_L: Dictionary = {
	"game": Games.ERASER_L,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Eraser",
	"level": "L",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_eraser.tscn",
	"game_time_limit": 0,
	"strays_start_count": 320, 
}


var game_data_cleaner: Dictionary = {
	"game": Games.CLEANER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Cleaner",
	"level": "",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner.tscn",
	"game_time_limit": 300,
	"strays_start_count": 320, 
}


var game_data_cleaner_duel: Dictionary = {
	"game": Games.CLEANER_DUEL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "Cleaner",
	"level": "Duel",
	"game_scene_path": "res://game/game_cleaning.tscn",
	"tilemap_path": "res://game/tilemaps/cleaning/tilemap_cleaner_duel.tscn",
	"game_time_limit": 60,
	"strays_start_count": 1000, 
}


var game_data_runner: Dictionary = {
	"game": Games.RUNNER,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Runner",
	"level": "",
	"game_scene_path": "res://game/game_patterns.tscn",
	"tilemap_path": "res://game/tilemaps/patterns/tilemap_runner.tscn",
	"game_time_limit": 0,
	"strays_start_count": 320, # 468 jih je v stackih
}


var game_data_riddler_S: Dictionary = {
	"game": Games.RIDDLER_S,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Riddler",
	"level": "S", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_patterns.tscn",
	"tilemap_path": "res://game/tilemaps/patterns/tilemap_riddler_S.tscn", # odvisna od sselected level
	"game_time_limit": 0, # odvisna od selected level
	"strays_start_count": 0, # 468 jih je v stackih
}


var game_data_riddler_M: Dictionary = {
	"game": Games.RIDDLER_M,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Riddler",
	"level": "M", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_patterns.tscn",
	"tilemap_path": "res://game/tilemaps/patterns/tilemap_riddler_M.tscn", # odvisna od sselected level
	"game_time_limit": 0, # odvisna od selected level
	"strays_start_count": 0, # 468 jih je v stackih
}


var game_data_riddler_L: Dictionary = {
	"game": Games.RIDDLER_L,
	"highscore_type": HighscoreTypes.HS_TIME_LOW,
	"game_name": "Riddler",
	"level": "L", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_patterns.tscn",
	"tilemap_path": "res://game/tilemaps/patterns/tilemap_riddler_L.tscn", # odvisna od sselected level
	"game_time_limit": 0, # odvisna od selected level
	"strays_start_count": 0, # 468 jih je v stackih
}


var game_data_scroller: Dictionary = { 
	"game": Games.SCROLLER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Scroller",
	"level": " ", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_scrolling.tscn",
	"tilemap_path": "res://game/tilemaps/scrolling/tilemap_scrolling.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50, # pravi se seta znotraj igre
}


var game_data_slider: Dictionary = { 
	"game": Games.SLIDER,
	"highscore_type": HighscoreTypes.HS_POINTS,
	"game_name": "Slider",
	"level": " ", # če je čist prazen se ne izpisuje, rabim da samo zgleda prazen za HS lestvico
	"game_scene_path": "res://game/game_scrolling.tscn",
	"tilemap_path": "res://game/tilemaps/scrolling/tilemap_slider.tscn",
	"game_time_limit": 0,
	"strays_start_count": 50, # pravi se seta znotraj igre
}


var game_data_tutorial: Dictionary = { 
	"game": Games.TUTORIAL,
	"highscore_type": HighscoreTypes.NO_HS,
	"game_name": "Tutorial",
	"level": "",
	"game_scene_path": "res://game/game_class.tscn",
	"tilemap_path": "res://game/tilemaps/tutorial_tilemap.tscn",
	"game_time_limit": 0,
	"strays_start_count": 10,
}


# ON GAME START -----------------------------------------------------------------------------------


var game_settings: Dictionary = {}
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"


func _ready() -> void:
	
	# če greš iz menija je tole povoženo
	var current_game = Games.CLEANER
#	var current_game = Games.ERASER_S
#	var current_game = Games.CLEANER_DUEL
#	var current_game = Games.SCROLLER
#	var current_game = Games.SLIDER
#	var current_game = Games.RUNNER
#	var current_game = Games.RIDDLER_M
#	var current_game = Games.TUTORIAL
	set_game_data(current_game)
	
	
func set_game_data(selected_game) -> void:
	
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre
	
	match selected_game:
		Games.TUTORIAL: 
			current_game_data = game_data_tutorial
			game_settings["player_start_life"] = 3
			game_settings["game_instructions_popup"] = false
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
		Games.CLEANER: 
			current_game_data = game_data_cleaner
		Games.ERASER_S: 
			current_game_data = game_data_eraser_S
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 0
			game_settings["color_picked_points"] = 0
		Games.ERASER_M: 
			current_game_data = game_data_eraser_M
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 0
			game_settings["color_picked_points"] = 0
		Games.ERASER_L: 
			current_game_data = game_data_eraser_L
			game_settings["timer_mode_countdown"] = false
			game_settings["all_cleaned_points"] = 1000
			game_settings["color_picked_points"] = 0
		Games.CLEANER_DUEL: 
			current_game_data = game_data_cleaner_duel
			game_settings["player_start_life"] = 3
			game_settings["lose_life_on_hit"] = true
			game_settings["position_indicators_mode"] = false 
			game_settings["start_countdown"] = false
		Games.SCROLLER:
			current_game_data = game_data_scroller
			game_settings["cell_traveled_energy"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["camera_fixed"] = true
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
			game_settings["position_indicators_mode"] = false 
		Games.SLIDER:
			current_game_data = game_data_slider
			game_settings["color_picked_energy"] = 2
			game_settings["camera_fixed"] = true
			game_settings["touching_stray_energy"] = -0.4
			game_settings["timer_mode_countdown"] = false
			game_settings["start_countdown"] = false
			game_settings["position_indicators_mode"] = false 
		Games.RUNNER: 
			current_game_data = game_data_runner
			game_settings["minimap_on"] = true
			game_settings["step_time_fast"] = 0.07
			game_settings["step_time_slow"] = 0.2
			game_settings["timer_mode_countdown"] = false
			game_settings["color_picked_points"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["touching_stray_energy"] = -0.4
#			game_settings["player_start_color"] = Color.white
			
			# debug kombo
			game_settings["game_instructions_popup"] = false
			game_settings["start_countdown"] = false
			
		Games.RIDDLER_S:
			current_game_data = game_data_riddler_S
			game_settings["cell_traveled_energy"] = 0
			game_settings["color_picked_points"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["on_hit_energy_part"] = 1
			game_settings["timer_mode_countdown"] = false
			game_settings["camera_fixed"] = true
			game_settings["position_indicators_mode"] = false 
#			game_settings["player_start_color"] = Color.white
		Games.RIDDLER_M:
			current_game_data = game_data_riddler_M
			game_settings["cell_traveled_energy"] = 0
			game_settings["color_picked_points"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["on_hit_energy_part"] = 1
			game_settings["timer_mode_countdown"] = false
			game_settings["camera_fixed"] = true
			game_settings["position_indicators_mode"] = false 
#			game_settings["player_start_color"] = Color.white
		Games.RIDDLER_L:
			current_game_data = game_data_riddler_L
			game_settings["cell_traveled_energy"] = 0
			game_settings["color_picked_points"] = 0
			game_settings["all_cleaned_points"] = 0
			game_settings["on_hit_energy_part"] = 1
			game_settings["timer_mode_countdown"] = false
			game_settings["camera_fixed"] = true
			game_settings["position_indicators_mode"] = false 
#			game_settings["player_start_color"] = Color.white
