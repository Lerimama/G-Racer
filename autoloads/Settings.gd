extends Node


# WORLD
var world_100kmh_pxsecond: float = 1778 # 100km/h = 1,67 km/min = 106666,67 px/min = 1777,78 px/s
var world_1m_pixels: float = 64
var world_hsp_power_factor: float = 1000 # engine power je 300 namesto 300000
# zgolj reference
var power_vs_speed = "250 hsp > 100 kmh"
var world_1kg_mass = 0.1 # masa ...
var kg_per_unit_mass = 10

# GAME
enum GAME_MODE {SINGLE, CAMPAIGN, TOURNAMENT, PRACTICE, BATTLE, SKILLS} # ... ni še
var game_mdoe: int = GAME_MODE.SINGLE
var game_time_limit: int = 5 # če je 0 ni omejitve
var start_countdown: bool = true
var countdown_start_limit: int = 5
var fast_start_window_time: float = 0.32
var fast_start_time: float = 0.2
var pickables_count_limit: int = 5
var sudden_death_mode: bool = false # vklopljen, če čas ni omejen
var enemies_mode: bool = false
var easy_mode: bool = false
var full_equip_mode: bool = false
var full_equip_value: int = 100
var camera_zoom_range: Array = [1, 1.5]
var camera_shake_on: bool = true
# driving
var pull_gas_penalty: float = -20
var drifting_mode: bool = true # drift ali tilt?
# shadows
var game_shadows_rotation_deg: float = 45
var game_shadows_color: Color = Color.black # odvisna od višine vira svetlobe
var game_shadows_length_factor: float = 1 # odvisna od višine vira svetlobe
var game_shadows_alpha: float = 0.4 # odvisna od moči svetlobe
var game_shadows_direction: Vector2 = Vector2(800,0) # odvisna od moči svetlobe
# helpers
var get_it_time: float = 2

# neu ... nis še optimalno nastavvljene
var fx_zero_intensity_distance: float = 100000
var one_screen_mode: bool = true
var hide_view_on_player_deactivated: = false
var slomo_time_scale: float = 0.1
var slomo_fx_on: bool = true
# UPDATE GAME SETTINGS -----------------------------------------------------------------------------------

var drivers_on_game_start: Array # = [0]# samo 1. level ... seta se iz home
var current_game_settings: Dictionary # duplikat originala, ki mu spremenim setingse glede na level
var current_level_settings: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var current_game_levels: Array = []

var names_on_game_start: Array

func _ready() -> void:

	if OS.is_debug_build():
#		current_game_levels = [Pfs.LEVELS.TRAINING]
#		current_game_levels = [Pfs.LEVELS.DEFAULT]
#		current_game_levels = [Pfs.LEVELS.STAFF]
		current_game_levels = [Pfs.LEVELS.FIRST_DRIVE, Pfs.LEVELS.FIRST_DRIVE]

		camera_zoom_range = [2, 2.3]
		camera_zoom_range = [1, 5]
		fast_start_window_time = 1
		game_shadows_rotation_deg = 45

		# obratne vrednosti
		start_countdown = false
		easy_mode = true
#		full_equip_mode = true
		enemies_mode = true
		camera_shake_on = false
		slomo_fx_on = false
#		one_screen_mode = false
#		hide_view_on_player_deactivated = true

		drivers_on_game_start = [ "0", 1, 2,# 3,
		]

		names_on_game_start = ["Prvi", "Drugi","sdfwsgfsdf"]

		Pfs.driver_profiles = {}
		for driver_index in drivers_on_game_start:
			Pfs.driver_profiles[driver_index] = Pfs.default_driver_profile.duplicate()
			if drivers_on_game_start.find(driver_index) == 0:
				Pfs.driver_profiles[driver_index]["driver_name"] = "P1"
				Pfs.driver_profiles[driver_index]["controller_type"] = Pfs.CONTROLLER_TYPE.ARROWS
#				Pfs.driver_profiles[driver]["driver_type"] = Pfs.DRIVER_TYPE.AI
			elif drivers_on_game_start.find(driver_index) == 1:
				Pfs.driver_profiles[driver_index]["driver_name"] = "P2"
				Pfs.driver_profiles[driver_index]["controller_type"] = Pfs.CONTROLLER_TYPE.WASD
#				Pfs.driver_profiles[driver]["driver_type"] = Pfs.DRIVER_TYPE.AI
			elif drivers_on_game_start.find(driver_index) == 2:
				Pfs.driver_profiles[driver_index]["driver_name"] = "P3"
#				Pfs.driver_profiles[driver]["controller_type"] = Pfs.CONTROLLER_TYPE.JP1
				Pfs.driver_profiles[driver_index]["driver_type"] = Pfs.DRIVER_TYPE.AI
			elif drivers_on_game_start.find(driver_index) == 4:
				Pfs.driver_profiles[driver_index]["driver_name"] = "P4"
#				Pfs.driver_profiles[driver]["controller_type"] = Pfs.CONTROLLER_TYPE.JP2
				Pfs.driver_profiles[driver_index]["driver_type"] = Pfs.DRIVER_TYPE.AI

	set_game_settings_per_level()


func set_game_settings_per_level(selected_level_index: int = 0):

	# kliče GM pred spawnanjem levela
	# namen je predvsem, da se lahko spreminjajo game settingsi glede na level
	var current_level: int = current_game_levels[selected_level_index]

	game_time_limit = Pfs.level_profiles[current_level]["level_time_limit"]

	# debug
	match current_level:
		# racing
		# duel
		Pfs.LEVELS.STAFF:
			pass
		Pfs.LEVELS.FIRST_DRIVE:
			pass

	return current_game_settings # pobere GM ob setanju igre
