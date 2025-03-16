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


# GAME SETTINGS --------------------------------------------------------------------------------------------

enum GAME_MODE {SINGLE, CAMPAIGN, TOURNAMENT, PRACTICE, BATTLE, SKILLS} # ... ni še
var game_mode: int = GAME_MODE.SINGLE

var slomo_fx_on: bool = true
var easy_mode: bool = false
var full_equip_mode: bool = false
var sudden_death_mode: bool = false # vklopljen, če čas ni omejen
#var camera_zoom_range: Array = [1, 1.5]
var camera_zoom_range: Vector2 = Vector2(1, 1.5)
var camera_shake_on: bool = true
var enemies_mode: bool = false
var wins_goal_count: int = 5 # kdo pride prej do tega števila zmag
var one_screen_mode: bool = true


# PER LEVEL STYLE --------------------------------------------------------------------------------------------

var start_countdown: bool = true
var countdown_start_time: int = 3
var pickables_count_limit: int = 5
var pull_gas_penalty: float = -20
var drifting_mode: bool = true # drift ali tilt?
var life_as_life_taken: bool = true
var ranking_cash_rewards: Array = [5000, 3000, 1000]

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
#enum DAMAGE_EFFECTS
var sudden_death_start_time: int = 20


# ON START -----------------------------------------------------------------------------------


var new_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var game_levels: Array = []
#var game_levels: Array = [Pros.LEVELS.FIRST_DRIVE_SHORT, Pros.LEVELS.FIRST_DRIVE_SHORT]

var default_game_settings_resource: Resource = preload("res://game/game_settings_def.tres")


func _ready() -> void:

	pass


func _apply_debug_settings():

#	game_levels = [Pros.LEVELS.TRAINING]
#	game_levels = [Pros.LEVELS.DEFAULT]
#	game_levels = [Pros.LEVELS.STAFF]
#	game_levels = [Pros.LEVELS.FIRST_DRIVE, Pros.LEVELS.FIRST_DRIVE]
	game_levels = [Pros.LEVELS.FIRST_DRIVE_SHORT, Pros.LEVELS.FIRST_DRIVE_SHORT]
#	game_levels = [Pros.LEVELS.SETUP]
	print("game_levels", game_levels)

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
	enemies_mode = true
	camera_shake_on = false
	slomo_fx_on = false
#	full_equip_mode = true
#	one_screen_mode = false
#	hide_view_on_player_deactivated = true
	time_game_heal_rate_factor = 0
#	health_effects = [HEALTH_EFFECTS.POWER, HEALTH_EFFECTS.GAS, HEALTH_EFFECTS.MOTION]
#	health_effects = [HEALTH_EFFECTS.MOTION]
	health_effects = []
	# max wins is level count
	var max_wins_is_level_count: bool = true
	if max_wins_is_level_count:
		wins_goal_count = game_levels.size()


	var drivers_on_game_start: Array = ["JOU"]
#	drivers_on_game_start = [ "JOU", "MOU"]
	drivers_on_game_start = [ "JOU", "MOU", "ROU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU", "SOU"]
#	drivers_on_game_start = [ "JOU", "MOU", "ROU", "heh", "OU", "MO", "RO", "he"]


	Pros.start_driver_profiles = {}
	for driver_id in drivers_on_game_start:
		Pros.start_driver_profiles[driver_id] = Pros.default_driver_profile.duplicate()

	for driver_id in drivers_on_game_start:
		Pros.start_driver_profiles[driver_id] = Pros.default_driver_profile.duplicate()
		Pros.start_driver_profiles[driver_id]["driver_type"] = Pros.DRIVER_TYPE.PLAYER
		if drivers_on_game_start.find(driver_id) == 0:
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_blue
#			Pros.start_driver_profiles[driver_id]["driver_type"] = Pros.DRIVER_TYPE.AI
		elif drivers_on_game_start.find(driver_id) == 1:
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_red
			Pros.start_driver_profiles[driver_id]["driver_avatar"] = preload("res://home/drivers/avatar_marty.tres")
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.WASD
#			Pros.start_driver_profiles[driver_id]["driver_type"] = Pros.DRIVER_TYPE.AI
		elif drivers_on_game_start.find(driver_id) == 2:
#			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
			Pros.start_driver_profiles[driver_id]["driver_type"] = Pros.DRIVER_TYPE.AI
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_green
		elif drivers_on_game_start.find(driver_id) == 3:
			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.ARROWS
#			Pros.start_driver_profiles[driver_id]["controller_type"] = Pros.CONTROLLER_TYPE.JP2
#			Pros.start_driver_profiles[driver_id]["driver_type"] = Pros.DRIVER_TYPE.AI
			Pros.start_driver_profiles[driver_id]["driver_color"] = Refs.color_yellow


func start_debug():

	load_saved_game_settings(default_game_settings_resource) # _temp ... loas sevad game bo na game reload
	_apply_debug_settings()
	_set_game_settings_per_level()

	Refs.main_node._home_in()
#	Refs.main_node._game_in()



func _set_game_settings_per_level(selected_level_index: int = 0):

	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	var current_level: int = game_levels[selected_level_index]


	# debug
	match current_level:
		# racing
		# duel
		Pros.LEVELS.STAFF:
			pass
		Pros.LEVELS.FIRST_DRIVE:
			pass


func load_saved_game_settings(saved_game_settings: Resource):

	ai_gets_record = saved_game_settings.ai_gets_record
	health_effects = saved_game_settings.health_effects
	time_game_heal_rate_factor = saved_game_settings.time_game_heal_rate_factor
	points_game_heal_rate_factor = saved_game_settings.points_game_heal_rate_factor

	sudden_death_start_time = saved_game_settings.sudden_death_start_time
	camera_zoom_range = saved_game_settings.camera_zoom_range
	start_countdown = saved_game_settings.start_countdown
	countdown_start_time = saved_game_settings.countdown_start_time
	pickables_count_limit = saved_game_settings.pickables_count_limit
	pull_gas_penalty = saved_game_settings.pull_gas_penalty
	drifting_mode = saved_game_settings.drifting_mode
	life_as_life_taken = saved_game_settings.life_as_life_taken
	ranking_cash_rewards = saved_game_settings.ranking_cash_rewards

	# daytime params
	game_shadows_rotation_deg = saved_game_settings.game_shadows_rotation_deg
	game_shadows_color = saved_game_settings.game_shadows_color
	game_shadows_length_factor = saved_game_settings.game_shadows_length_factor
	game_shadows_alpha = saved_game_settings.game_shadows_alpha
	game_shadows_direction = saved_game_settings.game_shadows_direction



