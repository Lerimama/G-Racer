extends Node


# ---------------------------------------------------------------------------------------------------------------------------
func z_index(): pass

#Z INDEX
#- background = -10
#- ground terrain < -1
#- flat objects and default = 0
#- not flat or floating object = 1 - 9
#- sky > 10
var z_indexes: Dictionary = {
	# indexi so delno poštimani tudi v nodetih levela
	# ref "background": -10,
	"ground": 0, # streets, surfaces
	"agents": 1,
	# TUDU
	"pickables": 1, # v levelu
	"breakers": 1,
	"mounts": 100, # noben objekt levela ni všje
	"building": 10, # noben objekt levela ni všje
	"hill": 50, # noben objekt levela ni všje
	"sky": 1000, # top
	#	"surface_z_index": 1,
	#	"SURFACE": 6,
	#	"PICKABLE": 1,
	#	"LEVEL_OBJECT": 1,
}


# ---------------------------------------------------------------------------------------------------------------------------
func stats(): pass

# vsi mogoči statsi
enum STATS {
		WINS, LIFE, HEALTH, POINTS, GAS, CASH,
		BULLET_COUNT, MISILE_COUNT, MINA_COUNT, SMALL_COUNT,
		LEVEL_RANK, LAPS_FINISHED, BEST_LAP_TIME, LEVEL_TIME, GOALS_REACHED
		}

var start_gent_level_stats: Dictionary = { # tale slovar je med igro v level stats slovarju
	STATS.LEVEL_RANK: 0,
	STATS.LEVEL_TIME: 0, # hunds
	STATS.BEST_LAP_TIME: 0,
	STATS.LAPS_FINISHED: [], # časi
	STATS.GOALS_REACHED: [], # nodeti
}
var start_agent_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	STATS.WINS : 2,
	STATS.LIFE : 5,
	STATS.CASH: 0,
	STATS.HEALTH : 1, # health percetnage
	STATS.BULLET_COUNT : 10,
	STATS.MISILE_COUNT : 5,
	STATS.SMALL_COUNT : 5,
	STATS.MINA_COUNT : 3,
	STATS.GAS: 2000,
	STATS.POINTS : 0,
}


# ---------------------------------------------------------------------------------------------------------------------------
func drivers(): pass


enum DRIVER_TYPE {PLAYER, AI}

var driver_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
}

var default_driver_profile: Dictionary = {
	"driver_name": "PLAJER",
	"driver_avatar": preload("res://home/avatar_david.tres"),
	"driver_color": Rfs.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
	"controller_type": CONTROLLER_TYPE.ARROWS,
	"agent_type": AGENT.BASIC,
	"driver_type": DRIVER_TYPE.PLAYER,
}

var avatars: Array = [preload("res://home/avatar_david.tres"), preload("res://home/avatar_magnum.tres"), preload("res://home/avatar_marty.tres"), preload("res://home/avatar_mrt.tres"), preload("res://home/avatar_ai.tres")]
var colors: Array = [Rfs.color_blue, Rfs.color_green, Rfs.color_yellow, Rfs.color_red]
var names: Array = ["KNIGHT", " MAGNUM", "MARTY", "BARACUS"]

enum AI_TYPE {DEFAULT, LAID_BACK, SMART, AGGRESSIVE}
var ai_profile: Dictionary = {
	"controller_scene": preload("res://game/agent/ControllerAI.tscn"),
	"ai_avatar": preload("res://home/avatar_ai.tres"),
	"ai_type": AI_TYPE.DEFAULT,
	"ai_name": "STEINY",
	"random_start_range": "", # še na nodu
}


enum CONTROLLER_TYPE {ARROWS, WASD, JP1, JP2}
var controller_profiles: Dictionary = {
	CONTROLLER_TYPE.ARROWS: {
		fwd_action = "p1_fwd",
		rev_action = "p1_rev",
		left_action = "p1_left",
		right_action = "p1_right",
		shoot_action = "p1_shoot",
		selector_action = "p1_selector",
		"controller_scene": preload("res://game/agent/ControllerPlayer.tscn"),
		},
	CONTROLLER_TYPE.WASD : {
		fwd_action = "p2_fwd",
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		selector_action = "p2_selector",
		"controller_scene": preload("res://game/agent/ControllerPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP1 : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		selector_action = "jp1_selector",
		"controller_scene": preload("res://game/agent/ControllerPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP2 : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		selector_action = "jp2_selector",
		"controller_scene": preload("res://game/agent/ControllerPlayer.tscn"),
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
func agents(): pass

enum AGENT {BASIC, TRUCK}
var agent_profiles: Dictionary = {
	AGENT.BASIC: {
		"agent_scene": preload("res://game/agent/Agent.tscn"),
		"motion_manager_path": load("res://game/agent/MotionManager_Basic.gd"),
		"height": 10,
		"elevation": 7,
		"gas_usage": -0.1, # per HSP?
		"gas_usage_idle": -0.05, # per HSP?
		"ai_target_rank": 5,
		"on_hit_disabled_time": 2,
		"gas_tank_size": 200, # liters
		"group_weapons_by_type": "",
		},
	}

# ---------------------------------------------------------------------------------------------------------------------------
func equipment(): pass

enum EQUIPMENT {NITRO, SHIELD}
var equipment_profiles : Dictionary = {
	EQUIPMENT.NITRO: {
		"value": 1,
		"nitro_power_addon": 700,
		"time": 1,
	},
	EQUIPMENT.SHIELD: {
		"lifetime": 5,
		"scene": preload("res://game/equipment/shield/Shield.tscn"),
		"time": 3,
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
func weapons(): pass

var _temp_mala_icon = preload("res://assets/icons/icon_mala_VRSA.tres")


enum AMMO {BULLET, MISILE, MINA, SMALL} # kot v orožjih

var ammo_profiles : Dictionary = {
	AMMO.BULLET: {
		"reload_time": 0.2,
		"scene": preload("res://game/weapons/ammo/ProjectileBullet.tscn"),
		"icon": preload("res://assets/icons/icon_bullet_VRSA.tres"),
		"stat_key": STATS.BULLET_COUNT,
	},
	AMMO.MISILE: {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"scene": preload("res://game/weapons/ammo/ProjectileHomer.tscn"),
		"icon": preload("res://assets/icons/icon_misile_VRSA.tres"),
		"stat_key": STATS.MISILE_COUNT,
	},
	AMMO.MINA: {
		"reload_time": 0.1, #
		"scene": preload("res://game/weapons/ammo/MinaExplode.tscn"),
		"icon": preload("res://assets/icons/icon_mina_VRSA.tres"),
		"stat_key": STATS.MINA_COUNT,
	},
	AMMO.SMALL: {
		"reload_time": 0.1, #
		"scene": preload("res://game/weapons/ammo/ProjectileSmall.tscn"),
		"icon": preload("res://assets/icons/icon_bullet_VRSA.tres"),
		"stat_key": STATS.SMALL_COUNT,
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
func levels(): pass

enum BASE_TYPE {UNDEFINED, TIMED, UNTIMED}
enum LEVELS {DEFAULT, TRAINING, STAFF, FIRST_DRIVE} # to zaporedje upošteva zapordje home gumbov
var level_profiles: Dictionary = {
	LEVELS.DEFAULT: {
		"level_name": "xxx",
		"level_desc": "jajsjdsjdj",
		"level_scene": preload("res://game/levels/Level.tscn"),
		"level_thumb": preload("res://home/thumb_level_race.tres"),
		"time_limit": 0,
		"lap_limit": 0,
		# določeno ob spawnu
		"level_type": BASE_TYPE.UNDEFINED, # tole povozi level na spawn glede na njegove elemente
		"level_goals": [],
		},
	LEVELS.FIRST_DRIVE: {
		"level_name": "xxx",
		"level_desc": "xxx",
		"level_scene": preload("res://game/levels/LevelFirstDrive.tscn"),
		"level_thumb": preload("res://home/thumb_level_race.tres"),
		"time_limit": 0,
		"lap_limit": 0, # če so goalsi delajo isto kot čekpointi
		# določeno ob spawnu
		"level_type": BASE_TYPE.UNDEFINED, # tole povozi level na spawn glede na njegove elemente
		"level_goals": [],
		},
	LEVELS.TRAINING: {
		"level_name": "xxx",
		"level_desc": "xxx",
#		"level_path": "res://game/levels/LevelTraining.tscn",
		"level_scene": preload("res://game/levels/LevelTraining.tscn"),
		"level_thumb": preload("res://home/thumb_level_training.tres"),
		"time_limit": 0,
		"lap_limit": 0,
		"level_type": BASE_TYPE.UNDEFINED, # tole povozi level na spawn glede na njegove elemente
		"level_goals": [],
		},
	LEVELS.STAFF: {
		"level_name": "xxx",
		"level_desc": "xxx",
		"level_scene": preload("res://game/levels/LevelStaff.tscn"),
		"level_thumb": preload("res://home/thumb_level_mission.tres"),
		"time_limit": 60,
		"lap_limit": 1,
		"level_type": BASE_TYPE.UNDEFINED, # tole povozi level na spawn glede na njegove elemente
		"level_goals": [],
		},
}

enum LEVEL_OBJECT {BRICK_GHOST, BRICK_BOUNCER, BRICK_MAGNET, BRICK_TARGET, FLATLIGHT, GOAL_PILLAR}
var level_object_profiles: Dictionary = {
	# ne rabiš povsod istih vsebin, ker element vleče samo postavke, ki jih rabi
	LEVEL_OBJECT.BRICK_GHOST: {
		"color": Rfs.color_brick_ghost,
		"value": 30,
		"speed_brake_div": 10,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickGhost.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.BRICK_BOUNCER: {
		"color": Rfs.color_brick_bouncer,
		"value": 10,
		"bounce_strength": 2,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickBouncer.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.BRICK_MAGNET: {
		"color": Rfs.color_brick_magnet_off,
		"value": 0,
		"gravity_force": 300.0,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickMagnet.tscn"),
		"ai_target_rank": 0, # 0 pomeni, da se izogneš
	},
	LEVEL_OBJECT.BRICK_TARGET: {
		"color": Rfs.color_brick_target,
		"value": 100,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickTarget.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.FLATLIGHT: {
		"color": Rfs.color_brick_light_off,
		"value": 10,
		"elevation": 0,
		"object_scene": preload("res://game/level/objects/FlatLight.tscn"),
		"ai_target_rank": 3,
	},
	LEVEL_OBJECT.GOAL_PILLAR: {
		"value": 1000,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/GoalPillar.tscn"),
		"ai_target_rank": 5,
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
func surfaces(): pass

enum SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}
var surface_type_profiles: Dictionary = {
	SURFACE.NONE: {
		"engine_power_addon": 0, # 0 je brez vpliva, do 10 seštevam, naprej množim
		"shake_amount": 0,
	},
	SURFACE.CONCRETE: {
		"engine_power_addon": 0,
		"shake_amount": 0,
	},
	SURFACE.NITRO: {
		"engine_power_addon": 700,
		"shake_amount": 0,
	},
	SURFACE.GRAVEL: {
		"engine_power_addon": 0.2,
		"shake_amount": 0,
	},
	SURFACE.HOLE: {
		"engine_power_addon": 0.1,
		"shake_amount": 0,
	},
	SURFACE.TRACKING: {
		"engine_power_addon": 0,
		"shake_amount": 0,
	},
}

# ---------------------------------------------------------------------------------------------------------------------------
func pickables(): pass

enum PICKABLE{
	PICKABLE_BULLET, PICKABLE_MISILE, PICKABLE_MINA,
	PICKABLE_SHIELD, PICKABLE_HEALTH, PICKABLE_LIFE,
	PICKABLE_GAS, PICKABLE_CASH, PICKABLE_NITRO,
	PICKABLE_POINTS,
	PICKABLE_RANDOM
	}
var pickable_profiles: Dictionary = {
	PICKABLE.PICKABLE_BULLET: {
		"color": Rfs.color_pickable_ammo,
		"value": 20,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.BULLET_COUNT,
	},
	PICKABLE.PICKABLE_MISILE: {
		"color": Rfs.color_pickable_ammo,
		"value": 2,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.MISILE_COUNT,
	},
	PICKABLE.PICKABLE_MINA: {
		"color": Rfs.color_pickable_ammo,
		"value": 3,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.MINA_COUNT,
	},
	PICKABLE.PICKABLE_HEALTH: {
		"color": Rfs.color_pickable_stat,
		"value": 0,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.HEALTH,
	},
	PICKABLE.PICKABLE_LIFE: {
		"color": Rfs.color_pickable_stat,
		"value": 1,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.LIFE,
	},
	PICKABLE.PICKABLE_GAS: {
		"color": Rfs.color_pickable_stat,
		"value": 200,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": STATS.GAS,
	},
	PICKABLE.PICKABLE_CASH: {
		"color": Rfs.color_pickable_stat,
		"value": 50,
		"elevation": 3,
		"ai_target_rank": 0,
		"driver_stat": STATS.CASH,
	},
	PICKABLE.PICKABLE_POINTS: {
		"color": Rfs.color_pickable_stat,
		"value": 100,
		"elevation": 3,
		"ai_target_rank": 2,
		"driver_stat": STATS.POINTS,
	},
	# NO STATS ...instants
	PICKABLE.PICKABLE_SHIELD: {
		"color": Rfs.color_pickable_ammo,
		"value": 1,
		"elevation": 3,
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_NITRO: {
		"color": Rfs.color_pickable_feature,
		"value": 2, # factor
		"elevation": 3,
		"ai_target_rank": 10,
	},
	PICKABLE.PICKABLE_RANDOM: { # nujno zadnji, ker ga izloči ob žrebanju
		"color": Rfs.color_pickable_random,
		"value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"elevation": 3,
		"ai_target_rank": 9,
	},
}
