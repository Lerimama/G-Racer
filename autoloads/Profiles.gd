extends Node


# BOLTS so vozila
# PLAYERS so vozniki vozil (P1, P2, P3, ...)
# AI je komp kontroler
# HUMAN je človeški kontroller (ARROWS, WASD, JP1, JP2, AI)


var default_player_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	# bolt stats
	"wins" : 2,
	"life" : 5,
	"energy" : 10,
	"bullet_count" : 100,
	"misile_count" : 5,
	"mina_count" : 3,
	"gas_count": 5000,
	# score
	"points" : 0,
	"level_rank" : 0, 
	"laps_count" : 0,
	"best_lap_time" : 0,
	"level_time" : 0, # sekunde ... naj bodo stotinke
}

enum Players {P1, P2, P3, P4}
var player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	Players.P1 : {
		"player_name": "P1",
		"player_avatar": preload("res://assets/textures/avatars/avatar_01.png"),
		"player_color": Ref.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_profile": Controller.ARROWS,
		"bolt_type": BoltTypes.RIGID,
		"bolt_scene": preload("res://game/bolt/rigid/TheBolt.tscn"),
	},
	Players.P2 : {
		"player_name": "P2",
		"player_avatar": preload("res://assets/textures/avatars/avatar_02.png"),
		"player_color": Ref.color_red,
		"controller_profile" : Controller.WASD,
		"bolt_type": BoltTypes.BASIC,
		"bolt_scene": preload("res://game/bolt/BoltHuman.tscn"),
	},
	Players.P3 : {
		"player_name" : "P3",
		"player_avatar" : preload("res://assets/textures/avatars/avatar_03.png"),
		"player_color" : Ref.color_yellow, # color_yellow, color_green, color_red
		"controller_profile" : Controller.WASD,
		#		"controller_profile" : Controller.JP1,
		"bolt_type": BoltTypes.BASIC,
		"bolt_scene": preload("res://game/bolt/BoltHuman.tscn"),
	},
	Players.P4 : {
		"player_name" : "P4",
		"player_avatar" : preload("res://assets/textures/avatars/avatar_04.png"),
		"player_color" : Ref.color_green,
		"controller_profile" : Controller.WASD,
		#		"controller_profile" : Controller.JP2,
		"bolt_type": BoltTypes.BASIC,
		"bolt_scene": preload("res://game/bolt/BoltHuman.tscn"),
	},
}


var ai_profile: Dictionary = {
	# za prepis player profila
	"controller_profile" : Controller.AI,
#	"bolt_scene": preload("res://game/bolt/BoltAI.tscn"),
	"bolt_scene": preload("res://game/bolt/rigid/TheBoltAI.tscn"),
	# race
	"max_engine_power": 80, # 80 ima skoraj identično hitrost kot plejer
	# battle
	"battle_engine_power": 120, # je enaka kot od  bolta 
	"aim_time": 1,
#	"seek_rotation_range": 60,
#	"seek_rotation_speed": 3,
#	"seek_distance": 640 * 0.7,
	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
	# ni še implementiran!!!!!!
	"ai_brake_distance": 0.8, # množenje s hitrostjo
	"ai_brake_factor": 150, # distanca do trka ... večja ko je, bolj je pazljiv
}


enum BoltTypes {SMALL, BASIC, BIG, RIGID}
var bolt_profiles: Dictionary = {
	BoltTypes.BASIC: {
		"bolt_texture": preload("res://assets/textures/bolt/bolt_alt.png"),
		"reload_ability": 1,# 1 - 10 ... to je deljitelj reload timeta od orožja
		"on_hit_disabled_time": 2,
		"shield_loops_limit": 3,
		# orig
		"fwd_engine_power": 320, # 1 - 500 konjev 
		"rev_engine_power": 150, # 1 - 500 konjev 
		"turn_angle": 10, # deg per frame
		"free_rotation_multiplier": 15, # rotacija kadar miruje
		"side_traction": 0.2, # 0 - 1
		"bounce_size": 0.5, # 0 - 1 	
		"mass": 100, # kg
		"drag": 1.5, # 1 - 10 # raste kvadratno s hitrostjo
		"drag_div": 100.0, # večji pomeni nižjo drag force
		"fwd_gas_usage": -0.1, # per fram
		"rev_gas_usage": -0.05, # per fram
		"tilt_speed": 150, # trenutno off
		"ai_target_rank": 5,
		},
	BoltTypes.RIGID: {
		"bolt_texture": preload("res://assets/textures/bolt/bolt_alt.png"),
		"reload_ability": 1,# 1 - 10 ... to je deljitelj reload timeta od orožja
		"on_hit_disabled_time": 2,
		# orig
		"engine_power": 320, # 1 - 500 konjev 
		"gas_usage": -0.1, # per HSP?
		"ai_target_rank": 5,
		# rigid
		"mass": 30, # 300 kil, front in rear teža se uporablja bolj za razmerje
		"ang_damp": 8, # ... tudi regulacija driftanja
		"lin_damp_driving": 2, # imam ga za omejitev slajdanja prvega kolesa
		"lin_damp_idle": 0.5, 
		"rear_lin_damp": 5, # regulacija driftanja
		"max_idle_rotation_speed": 500000, # rotacija okrog osi
		"max_engine_rotation_deg": 35, # obračanje koles (45 stzopinj je bolj ala avto)
		},
}


enum Weapons {BULLET, MISILE, MINA}
var weapon_profiles : Dictionary = {
	Weapons.BULLET: {
		"reload_time": 0.1,
		"hit_damage": 2, # z 1 se zavrti pol kroga ... vpliva na hitrost in čas rotacije
		"speed": 1000,
		"lifetime": 1.0, # domet vedno merim s časom
		"mass": 1.5, # glede na to kakšno inercijo hočem
		"direction_start_range": [0, 0] , # natančnost misile
		#		"icon_scene": preload("res://assets/icons/icon_bullet.tres"), ... trenutno ne rabim
	},
	Weapons.MISILE: {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"hit_damage": 5, # 10 je max energija
		"speed": 100,
		"lifetime": 1.0, # domet vedno merim s časom
		"mass": 5,
		"direction_start_range": [-0.1, 0.1] , # natančnost misile
		#		"icon_scene": preload("res://assets/icons/icon_misile.tres"),
	},
	Weapons.MINA: {
		"reload_time": 0.1, #
		"hit_damage": 5,
		"speed": 50,
		"lifetime": 0, # 0 pomeni večno
		"mass": 3,
		"direction_start_range": [0, 0] , # natančnost misile
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},
}


enum Controller {ARROWS, WASD, JP1, JP2, AI}
var controller_profiles : Dictionary = {
	Controller.ARROWS: {
		fwd_action = "p1_fwd", 
		rev_action = "p1_rev",
		left_action = "p1_left",
		right_action = "p1_right",
		shoot_action = "p1_shoot",
		selector_action = "p1_selector",
		},
	Controller.WASD : {
		fwd_action = "p2_fwd", 
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		selector_action = "p2_selector",
	},
	Controller.JP1 : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		selector_action = "jp1_selector",
	},
	Controller.JP2 : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		selector_action = "jp2_selector",
	},
	Controller.AI : {
		fwd_action = "ai_fwd",
		rev_action = "ai_rev",
		left_action = "ai_left",
		right_action = "ai_right",
		shoot_action = "ai_shoot",
		selector_action = "ai_selector",
	},
}


enum LevelAreas {AREA_NITRO, AREA_GRAVEL, AREA_HOLE, AREA_TRACKING}
var level_areas_profiles: Dictionary = {
	LevelAreas.AREA_NITRO: {
		"drag_div": 500,
		"area_scene": preload("res://game/arena/areas/AreaNitro.tscn"),
	},
	LevelAreas.AREA_GRAVEL: {
		"drag_div": 25.0, 
		"area_scene": preload("res://game/arena/areas/AreaGravel.tscn"),
	},
	LevelAreas.AREA_HOLE: {
		"drag_div": 5.0,
		"area_scene": preload("res://game/arena/areas/AreaHole.tscn"),
	},
	LevelAreas.AREA_TRACKING: {
		"area_tracking_value": 1,
		"area_scene": preload("res://game/arena/areas/AreaTracking.tscn"),
	},
}


enum LevelObjects {BRICK_GHOST, BRICK_BOUNCER, BRICK_MAGNET, BRICK_TARGET, BRICK_LIGHT, GOAL_PILLAR}
var level_object_profiles: Dictionary = { 
	# ne rabiš povsod istih vsebin, ker element vleče samo postavke, ki jih rabi
	LevelObjects.BRICK_GHOST: {
		"color": Ref.color_brick_ghost,
		"value": 30,
		"speed_brake_div": 10,
		"altitude": 5,
		"object_scene": preload("res://game/arena/bricks/BrickGhost.tscn"),
		"ai_target_rank": 0,
	},
	LevelObjects.BRICK_BOUNCER: {
		"color": Ref.color_brick_bouncer,
		"value": 10,
		"bounce_strength": 2,
		"altitude": 5,
		"object_scene": preload("res://game/arena/bricks/BrickBouncer.tscn"),
		"ai_target_rank": 0,
	},
	LevelObjects.BRICK_MAGNET: {
		"color": Ref.color_brick_magnet_off,
		"value": 0,
		"gravity_force": 70.0,
		"altitude": 5,
		"object_scene": preload("res://game/arena/bricks/BrickMagnet.tscn"),
		"ai_target_rank": 0, # 0 pomeni, da se izogneš
	},	
	LevelObjects.BRICK_TARGET: {
		"color": Ref.color_brick_target,
		"value": 100,
		"altitude": 5,
		"object_scene": preload("res://game/arena/bricks/BrickTarget.tscn"),
		"ai_target_rank": 0,
	},
	LevelObjects.BRICK_LIGHT: {
		"color": Ref.color_brick_light_off,
		"value": 10,
		"altitude": 0,
		"object_scene": preload("res://game/arena/bricks/BrickLight.tscn"),
		"ai_target_rank": 3,
	},
	LevelObjects.GOAL_PILLAR: {
		"value": 1000,
		"altitude": 5,
		"object_scene": preload("res://game/arena/GoalPillar.tscn"),
		"ai_target_rank": 5,
	},
}


enum Pickables{
	PICKABLE_BULLET, PICKABLE_MISILE, PICKABLE_MINA, PICKABLE_SHIELD, 
	PICKABLE_ENERGY, PICKABLE_LIFE, PICKABLE_GAS, PICKABLE_POINTS
	PICKABLE_NITRO, PICKABLE_TRACKING, 
	PICKABLE_RANDOM
	}
var pickable_profiles: Dictionary = {
	Pickables.PICKABLE_BULLET: {
		"in_random_selection": true, # vključeno v random izbor?
		"color": Ref.color_pickable_weapon,
		"value": 20,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_bullet.tres"),
		"ai_target_rank": 3,
	},
	Pickables.PICKABLE_MISILE: {
		"in_random_selection": true,
		"color": Ref.color_pickable_weapon,
		"value": 2,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_misile.tres"),
		"ai_target_rank": 3,
	}, 
	Pickables.PICKABLE_MINA: {
		"in_random_selection": true,
		"color": Ref.color_pickable_weapon,
		"value": 3,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_mina.tres"),
		"ai_target_rank": 3,
	}, 
	Pickables.PICKABLE_SHIELD: {
		"in_random_selection": true,
		"color": Ref.color_pickable_weapon,
		"value": 1,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_shield.tres"),
		"ai_target_rank": 3,
	},
	Pickables.PICKABLE_ENERGY: {
		"in_random_selection": true,
		"color": Ref.color_pickable_stat,
		"value": 0,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_energy.tres"),
		"ai_target_rank": 3,
	},
	Pickables.PICKABLE_LIFE: {
		"in_random_selection": true,
		"color": Ref.color_pickable_stat,
		"value": 1,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_life.tres"),
		"ai_target_rank": 3,
	},
	Pickables.PICKABLE_GAS: {
		"in_random_selection": false,
		"color": Ref.color_pickable_stat,
		"value": 200,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_gas.tres"),
		"ai_target_rank": 3,
	},
	Pickables.PICKABLE_POINTS: {
		"in_random_selection": false,
		"color": Ref.color_pickable_stat,
		"value": 100,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_points.tres"),
		"ai_target_rank": 2,
	},
	Pickables.PICKABLE_NITRO: {
		"in_random_selection": false,
		"color": Ref.color_pickable_feature,
		"value": 700,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_nitro.tres"),
		"duration": 1.5, # sekunde
		"ai_target_rank": 10,
	},
	Pickables.PICKABLE_TRACKING: {
		"in_random_selection": false,
		"color": Ref.color_pickable_feature,
		"value": 0.7,
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_tracking.tres"),
		"duration": 5,
		"ai_target_rank": 1,
	},
	Pickables.PICKABLE_RANDOM: {
		"in_random_selection": false,
		"color": Ref.color_pickable_random,
		"value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"altitude": 3,
		"icon_scene": preload("res://assets/resources/icons/icon_pickable_random.tres"),
		"ai_target_rank": 9,
	},
}


var arena_tilemap_profiles: Dictionary = { # za generator
	"default_arena" : Vector2.ONE,
}
