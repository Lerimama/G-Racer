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
var camera_zoom_range: Vector2 = Vector2(1, 1.5) # vektor, da ga lahko množim
var camera_shake_on: bool = true
var camera_start_zoom: float = 5
var countdown_start_time: int = 3

# že povezano v home
var mono_view_mode: bool = true


# PER LEVEL TYPE --------------------------------------------------------------------------------------------

var pickables_count_limit: int = 5
var pull_gas_penalty: float = -0.2
var drifting_mode: bool = true # drift ali tilt?
var life_counts: bool = false
var sudden_death_mode: bool = false # vklopljen, če čas ni omejen
var sudden_death_start_time: int = 20

var level_cash_rewards: Array = [5000, 3000, 1000, 500]
var level_points_rewards: Array = [25, 20, 15, 10, 8, 5, 4, 3, 2, 1]

# daytime params
var game_shadows_rotation_deg: float = 45
var game_shadows_color: Color = Color.black # odvisna od višine vira svetlobe
var game_shadows_length_factor: float = 1 # odvisna od višine vira svetlobe
var game_shadows_alpha: float = 0.4 # odvisna od moči svetlobe
var game_shadows_direction: Vector2 = Vector2(800,0) # odvisna od moči svetlobe

# neu
enum DAMAGE_EFFECTS {MOTION, POWER, GAS} # kot v settings profilu
var health_effects: Array = []

#var health_effects_performance: bool = true
var time_game_heal_rate_factor: float = 0.01 # 0, če nočeš vpliva, 1 je kot da ni damiđa da ma vehicle lahko med 0 in 1
var points_game_heal_rate_factor: float = 0 # na ta način, ker lahko obstaja (kot nagrada?)
var ai_gets_record: bool = true
# ni v def game profilu
var heal_rate_factor: float = 0


# ON START -----------------------------------------------------------------------------------


var new_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var game_levels: Array = []
var current_game_drivers_data: Dictionary = {
	#	"xavier": {
	#		"vehicle_profile": {}
	#		"driver_profile": {}
	#		"tournament_stats": {}, # med igro se ne spreminja
	#		"driver_stats": {}, # delni reset na level
	#		"weapon_stats": {}, # napolne se ob prvem levelu
	#		},
	#	"john": ...
	}


func _ready() -> void:

	pass


func _apply_debug_settings():

#	game_levels = [Levs.GRAND_PRIX]
#	game_levels = [Levs.TESTER, Levs.GRAND_PRIX]
#	game_levels = [Levs.LEVEL.TESTER, Levs.LEVEL.TESTER, Levs.LEVEL.TESTER]
	game_levels = [Levs.LEVEL.TESTER, Levs.LEVEL.TESTER]
	game_levels = [Levs.LEVEL.TESTER]
	game_levels = [Levs.LEVEL.QUICKY]
#	game_levels = [Levs.QUICKY]
#	print("game_levels", game_levels)

	camera_zoom_range = Vector2(2, 2.3)
	camera_zoom_range *= 1.1 # 2 plejers > 3
	camera_zoom_range *= 2 #  3 + plejers > 3
#	camera_zoom_range *= 5
#	camera_zoom_range *= 0.7
#	camera_zoom_range *= 4


	fast_start_time = 1
	game_shadows_rotation_deg = 45

	# obratne vrednosti
#	start_countdown = false
	easy_mode = true # ne učinkuje
	camera_shake_on = false
	slomo_fx_on = false
#	full_equip_mode = true
	mono_view_mode = false
#	hide_view_on_player_deactivated = true
#	heal_rate_factor = time_game_heal_rate_factor # 0.01
	heal_rate_factor = points_game_heal_rate_factor # 0
#	health_effects = [DAMAGE_EFFECTS.POWER, DAMAGE_EFFECTS.GAS, DAMAGE_EFFECTS.MOTION]
#	health_effects = [DAMAGE_EFFECTS.MOTION]
	health_effects = []

	var drivers_on_game_start: Array = ["JOU"]
#	drivers_on_game_start = [ "JOU", "MOU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU"]
	drivers_on_game_start = [ "JOU", "MOU", "ROU", "SOU"]
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

#	set_level_settings(0)

	Refs.main_node.to_home()
#	_apply_debug_settings()
#	Refs.main_node.to_game()


func apply_settings(level_index: int):

	var selected_level_key: int = game_levels[level_index]

	_set_drivers_game_data()

	# mono_view_mode ... zaenkrat ga plejer ... testiraj battle
	if selected_level_key in Levs.training_levels:
		life_counts = false
		health_effects = []
		heal_rate_factor = 0
		sudden_death_mode = false
	elif selected_level_key in Levs.racing_levels:
		life_counts = false
		health_effects = [DAMAGE_EFFECTS.POWER]
		heal_rate_factor = time_game_heal_rate_factor
		sudden_death_mode = false
		#		pickables_count_limit = 10
	elif selected_level_key in Levs.battle_levels:
		health_effects = []
		life_counts = false
		heal_rate_factor = 0
		sudden_death_mode = true
		sudden_death_start_time = 60
		#		pickables_count_limit = 10
	elif selected_level_key in Levs.mission_levels:
		health_effects = []
		life_counts = true
		mono_view_mode = false
		heal_rate_factor = 0
		sudden_death_mode = false

#	var level_group
#
#	var level_id game_levels
#	match level_group:




func _set_drivers_game_data():
	# za shranjevanje game data med leveli
	# ker v igri ta slovar ni dupliciran, je vedno apdejtan z zadnjim game data

	for driver_id in Pros.start_driver_profiles:
		# driver data - prvi setup
		current_game_drivers_data[driver_id] = {}
		var vehicle_type: int = Pros.start_driver_profiles[driver_id]["vehicle_type"]
		current_game_drivers_data[driver_id]["vehicle_profile"] = Pros.vehicle_profiles[vehicle_type].duplicate()
		current_game_drivers_data[driver_id]["driver_profile"] = Pros.start_driver_profiles[driver_id].duplicate()
		current_game_drivers_data[driver_id]["driver_stats"] = Pros.start_driver_stats.duplicate()
		current_game_drivers_data[driver_id]["tournament_stats"] = Pros.driver_tournament_stats.duplicate()
		current_game_drivers_data[driver_id]["weapon_stats"] = {}
		# unique arrays
		current_game_drivers_data[driver_id]["tournament_stats"][Pros.STAT.TOURNAMENT_WINS] = []
		current_game_drivers_data[driver_id]["driver_stats"][Pros.STAT.LAP_COUNT] = []
		current_game_drivers_data[driver_id]["driver_stats"][Pros.STAT.GOALS_REACHED] = []
		current_game_drivers_data[driver_id]["driver_stats"][Pros.STAT.SCALPS] = []
