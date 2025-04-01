extends Node
# WORLD
# PERMA (per game) ... game settings (user in dev)
# PER LEVEL



var camera_on_tracker: bool = true

# PERMANENT --------------------------------------------------------------------------------------------

var fx_zero_intensity_distance: float = 100000
var get_it_time: float = 2
var slomo_time_scale: float = 0.1
var fast_start_time: float = 0.32
var full_equip_value: int = 100
var ai_gas_on: bool = false

# WORLD
var world_100kmh_pxsecond: float = 1778 # 100km/h = 1,67 km/min = 106666,67 px/min = 1777,78 px/s
var world_1m_pixels: float = 64
var world_hsp_power_factor: float = 1000 # engine power je 300 namesto 300000
# zgolj reference
var power_vs_speed = "250 hsp > 100 kmh"
var world_1kg_mass = 0.1 # masa ...
var kg_per_unit_mass = 10
var unit_one: float = 32 # samo breaker

# GAME SETTINGS --------------------------------------------------------------------------------------------

enum GAME_MODE {SINGLE, CAMPAIGN, TOURNAMENT, PRACTICE, BATTLE, SKILLS} # ... ni še
var game_mode: int = GAME_MODE.SINGLE

var slomo_fx_on: bool = true
var easy_mode: bool = false
var full_equip_mode: bool = false
var sudden_death_mode: bool = false # vklopljen, če čas ni omejen
var camera_zoom_range: Vector2 = Vector2(1, 1.5) # vektor, da ga lahko množim
var camera_shake_on: bool = true
var camera_start_zoom: float = 5

# že povezano v home
var mono_view_mode: bool = true
var wins_needed: int = 5 # kdo pride prej do tega števila zmag


# PER LEVEL STYLE --------------------------------------------------------------------------------------------

var start_countdown: bool = true
var countdown_start_time: int = 3
var pickables_count_limit: int = 5
var pull_gas_penalty: float = -20
var drifting_mode: bool = true # drift ali tilt?
var life_counts: bool = true
var level_cash_rewards: Array = [5000, 3000, 1000, 500]
var level_points_rewards: Array = [25, 20, 15, 10, 8, 5, 4, 3, 2, 1]

# daytime params
var game_shadows_rotation_deg: float = 45
var game_shadows_color: Color = Color.black # odvisna od višine vira svetlobe
var game_shadows_length_factor: float = 1 # odvisna od višine vira svetlobe
var game_shadows_alpha: float = 0.4 # odvisna od moči svetlobe
var game_shadows_direction: Vector2 = Vector2(800,0) # odvisna od moči svetlobe

# neu
enum HEALTH_EFFECTS {MOTION, POWER, GAS} # kot v settings profilu
var health_effects: Array = []

#var health_effects_performance: bool = true
var time_game_heal_rate_factor: float = 0.01 # 0, če nočeš vpliva, 1 je kot da ni damiđa da ma vehicle lahko med 0 in 1
var points_game_heal_rate_factor: float = 0 # na ta način, ker lahko obstaja (kot nagrada?)
var ai_gets_record: bool = true
var sudden_death_start_time: int = 20
# ni v def game profilu
var heal_rate_factor: float = 0




# ON START -----------------------------------------------------------------------------------


var new_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var game_levels: Array = []


func _ready() -> void:

	pass


func _apply_debug_settings():

#	game_levels = [Levs.GRAND_PRIX]
#	game_levels = [Levs.TESTER, Levs.GRAND_PRIX]
	game_levels = [Levs.LEVEL.TESTER, Levs.LEVEL.TESTER, Levs.LEVEL.TESTER]
#	game_levels = [Levs.QUICKY]
#	print("game_levels", game_levels)

	camera_zoom_range = Vector2(2, 2.3)
	camera_zoom_range *= 1.1 # 2 plejers > 3
#	camera_zoom_range *= 2 #  3 + plejers > 3
#	camera_zoom_range *= 5
#	camera_zoom_range *= 0.7
#	camera_zoom_range *= 4


	fast_start_time = 1
	game_shadows_rotation_deg = 45

	# obratne vrednosti
	start_countdown = false
	easy_mode = true
	camera_shake_on = false
	slomo_fx_on = false
#	full_equip_mode = true
#	mono_view_mode = false
#	hide_view_on_player_deactivated = true
#	heal_rate_factor = time_game_heal_rate_factor # 0.01
	heal_rate_factor = points_game_heal_rate_factor # 0
#	health_effects = [HEALTH_EFFECTS.POWER, HEALTH_EFFECTS.GAS, HEALTH_EFFECTS.MOTION]
#	health_effects = [HEALTH_EFFECTS.MOTION]
	health_effects = []
	# max wins is level count
	var max_wins_is_level_count: bool = true
	if max_wins_is_level_count:
		wins_needed = game_levels.size()


	var drivers_on_game_start: Array = ["JOU"]
	drivers_on_game_start = [ "JOU", "MOU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU", "SOU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU", "heh", "OU", "MO", "RO", "he"]


	Pros.start_driver_profiles = {}
	for driver_id in drivers_on_game_start:
		Pros.start_driver_profiles[driver_id] = Pros.def_driver_profile.duplicate()

	for driver_id in drivers_on_game_start:
		Pros.start_driver_profiles[driver_id] = Pros.def_driver_profile.duplicate()
		if drivers_on_game_start.find(driver_id) == 0:
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_blue
		elif drivers_on_game_start.find(driver_id) == 1:
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_red
			Pros.start_driver_profiles[driver_id]["driver_avatar"] = preload("res://home/drivers/avatar_marty.tres")
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.WASD
#			Pros.start_driver_profiles[driver_id]["controller_type"] = -1
		elif drivers_on_game_start.find(driver_id) == 2:
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
			Pros.start_driver_profiles[driver_id]["controller_type"] = -1
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_green
		elif drivers_on_game_start.find(driver_id) == 3:
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
			Pros.start_driver_profiles[driver_id]["controller_type"] = -1
#			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.JP2
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_yellow


func start_debug():

	_apply_debug_settings()
	_set_game_settings_per_level()

#	Refs.main_node._home_in()
	Refs.main_node._game_in()



func _set_game_settings_per_level(selected_level_index: int = 0):

	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	var current_level: int = -1 #game_levels[selected_level_index]


	# debug
#	match current_level:
		# racing
		# duel
	pass




