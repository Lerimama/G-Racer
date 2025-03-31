extends Node


func __z_index(): pass # ------------------------------------------------------------

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
	"vehicles": 1,
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


func __stats(): pass # ------------------------------------------------------------

# tipi:
#	Int ... je samo vrednost
#	Array, PoolIntArray ... potrebno reset uniq ob apliciranju v driverja
#	Array ... lahko se računa current in max value
#	PoolIntArray ... vedno

enum STAT {
		# driver
		LIFE,
		HEALTH,
		POINTS,
		GAS,
		CASH,
		# level (reset on level)
		LEVEL_PROGRESS,
		LEVEL_RANK,
		LAP_COUNT,
		GOALS_REACHED,
		BEST_LAP_TIME,
		LEVEL_FINISHED_TIME,
		LAP_TIME,
		# tournament
		TOURNAMENT_WINS,
		TOURNAMENT_POINTS,
		}

enum CAMPAIGN_STAT {
	ALL_CASH, # int
	HOLDING_RECORDS, # [level_name, record]
	ALL_WINS, # [level_name, result]
	LEVELS_FINISHED, # [level_name, result, rank]
	HOLDING_GAS, # bencin na zalogi
	VEHICLES,
	}

var start_driver_stats: Dictionary = {
	# driver
	STAT.LIFE: 0, # 0 = ni lajfa, 1 = 1 lajf, ni prikazan stat, n > 1 = normal, life as scalp
	STAT.CASH: 0, # int
	STAT.POINTS :0, # int
	# vehicle
	STAT.HEALTH: 1.0, # percetnage
	STAT.GAS: 2000.0, # float
	# level (reset per level)
	STAT.LEVEL_PROGRESS: 0.0, # percetnage
	STAT.LEVEL_RANK: 0, # -1 ... disq, 0 ... in game, 1+ ... finished ... po tem se ravna predvsem gui
	STAT.LEVEL_FINISHED_TIME: 0,
	STAT.BEST_LAP_TIME: 0,
	STAT.LAP_COUNT: [], # lap time
	STAT.GOALS_REACHED: [], # goal names
	STAT.LAP_TIME: 0,
	}

var driver_tournament_stats: Dictionary = {
	STAT.TOURNAMENT_WINS: [], # level index in game levels
	STAT.TOURNAMENT_POINTS: 0,
	}

# referenca
var _game_drivers_data: Dictionary = {
	#	"xavier": {
	#		"driver_profile": {}
	#		"driver_stats": {},
	#		"torunament_stats": {},
	#		"weapon_stats": {},
	#		},
	#	"john": ...
	}

func __drivers(): pass # ------------------------------------------------------------

# za default plejerje (ko ga dodaš) ... glede na index
var avatars: Array = [preload("res://home/drivers/avatar_david.tres"), preload("res://home/drivers/avatar_magnum.tres"), preload("res://home/drivers/avatar_marty.tres"), preload("res://home/drivers/avatar_mrt.tres"), preload("res://home/drivers/avatar_ai.tres")]
var colors: Array = [Refs.color_blue, Refs.color_green, Refs.color_yellow, Refs.color_red, Color.red, Color.magenta, Color.green, Color.violet, Color.lightcoral, Color.orange]
var names: Array = ["KNIGHT", " MAGNUM", "MARTY", "BARACUS"]

enum AI_TYPE {DEFAULT, LAID_BACK, SMART, AGGRESSIVE}

var start_driver_profiles: Dictionary = {} # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam

var def_driver_profile: Dictionary = {
	"driver_name_id": "PLAJER", # uporaba tudi za player id
	"driver_avatar": preload("res://home/drivers/avatar_david.tres"),
	"driver_color": Refs.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
	"controller_type": CONTROLLER_TYPE.ARROWS,
	"vehicle_type": VEHICLE.BASIC,
	}

var def_ai_driver_profile: Dictionary = {
	"driver_name_id": "STEINY",
	"driver_avatar": preload("res://home/drivers/avatar_ai.tres"),
	"driver_color": Refs.color_red,
	"controller_scene": preload("res://game/vehicle/ControlAI.tscn"),
	"controller_type": -1, # ko uvedem različne tipe AI, bo tole malo drugače
	"ai_type": AI_TYPE.DEFAULT, # obs
	"random_start_range": "", # še na nodu
	}


enum CONTROLLER_TYPE {ARROWS, WASD, JP1, JP2}
var controller_profiles: Dictionary = {
	-1: {
		"controller_scene": preload("res://game/vehicle/ControlAI.tscn"),
		},
	CONTROLLER_TYPE.ARROWS: {
		fwd_action = "p1_fwd",
		rev_action = "p1_rev",
		left_action = "p1_left",
		right_action = "p1_right",
		shoot_action = "p1_shoot",
		selector_action = "p1_selector",
		"controller_scene": preload("res://game/vehicle/ControlPlayer.tscn"), # more bit scena, ker ma ai stvari notri
		},
	CONTROLLER_TYPE.WASD : {
		fwd_action = "p2_fwd",
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		selector_action = "p2_selector",
		"controller_scene": preload("res://game/vehicle/ControlPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP1 : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		selector_action = "jp1_selector",
		"controller_scene": preload("res://game/vehicle/ControlPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP2 : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		selector_action = "jp2_selector",
		"controller_scene": preload("res://game/vehicle/ControlPlayer.tscn"),
	},
	}


func __vehicles(): pass # ------------------------------------------------------------

enum VEHICLE {BASIC, TRUCK}
var vehicle_profiles: Dictionary = {
	VEHICLE.BASIC: {
		"vehicle_scene": preload("res://game/vehicle/Vehicle.tscn"),
		"vehicle_profile_path": load("res://game/vehicle/profiles/profile_vehicle_def.tres"),
		"motion_manager_path": load("res://game/vehicle/MotionManager.gd"),
		"height": 10,
		"elevation": 7,
		"gas_usage": -0.005, # per HSP? ... pol ne rabš idle porabe?
		"gas_usage_idle": -0.0005, # per HSP?
		"gas_tank_size": 200, # liters

		# neu
		"group_equipment_by_type": "", # < zakaj string? kako da ni nč? ... grdo
		"health_effect_factor": 1, # vpliva na to koliko škode od planirane naredi neka zadeva
		"on_hit_disabled_time": 1,
		"heal_rate": 0.01, # lerp rate
		"driving_elevation": 7,
		},
	}


func __equipment(): pass # ------------------------------------------------------------

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


func __weapons(): pass # ------------------------------------------------------------

var _temp_mala_icon = preload("res://game/gui/icons/icon_mala_VERS.tres")
enum AMMO {BULLET, MISILE, MINA, SMALL, HOMER} # kot v orožjih
var ammo_profiles : Dictionary = {
	AMMO.BULLET: {
		# "reload_time": 0.2,  ... določim v export var
		"scene": preload("res://game/weapons/ammo/ProjectileBullet.tscn"),
		"icon": preload("res://game/gui/icons/icon_bullet_VERS.tres"),
	},
	AMMO.MISILE: {
		"scene": preload("res://game/weapons/ammo/ProjectileHomer.tscn"),
		"icon": preload("res://game/gui/icons/icon_misile_VERS.tres"),
	},
	AMMO.MINA: {
		"scene": preload("res://game/weapons/ammo/MinaExplode.tscn"),
		"icon": preload("res://game/gui/icons/icon_mina_VERS.tres"),
	},
	AMMO.SMALL: {
		"scene": preload("res://game/weapons/ammo/ProjectileBulletSmall.tscn"),
		"icon": preload("res://game/gui/icons/icon_bullet_VERS.tres"),
	},
	AMMO.HOMER: {
		"scene": preload("res://game/weapons/ammo/ProjectileBulletSmall.tscn"),
		"icon": preload("res://game/gui/icons/icon_bullet_VERS.tres"),
	},
	}


func __level_objects(): pass # ------------------------------------------------------------


enum LEVEL_OBJECT {BRICK_GHOST, BRICK_BOUNCER, BRICK_MAGNET, BRICK_TARGET, FLATLIGHT, GOAL_PILLAR}
var level_object_profiles: Dictionary = {
	# ne rabiš povsod istih vsebin, ker element vleče samo postavke, ki jih rabi
	LEVEL_OBJECT.BRICK_GHOST: {
		"color": Refs.color_brick_ghost,
		"value": 30,
		"speed_brake_div": 10,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickGhost.tscn"),
	},
	LEVEL_OBJECT.BRICK_BOUNCER: {
		"color": Refs.color_brick_bouncer,
		"value": 10,
		"bounce_strength": 2,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickBouncer.tscn"),
	},
	LEVEL_OBJECT.BRICK_MAGNET: {
		"color": Refs.color_brick_magnet_off,
		"value": 0,
		"gravity_force": 300.0,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickMagnet.tscn"),
	},
	LEVEL_OBJECT.BRICK_TARGET: {
		"color": Refs.color_brick_target,
		"value": 100,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/BrickTarget.tscn"),
	},
	LEVEL_OBJECT.FLATLIGHT: {
		"color": Refs.color_brick_light_off,
		"value": 10,
		"elevation": 0,
		"object_scene": preload("res://game/level/objects/FlatLight.tscn"),
	},
	LEVEL_OBJECT.GOAL_PILLAR: {
		"value": 1000,
		"elevation": 5,
		"object_scene": preload("res://game/level/objects/GoalPillar.tscn"),
	},
	}



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

func __pickables(): pass # ------------------------------------------------------------

enum PICKABLE{ # enako kot na pickable
	RANDOM,
	# stats
	LIFE,
	HEALTH,
	GOAL,
	GAS,
	CASH,
	# equipment
	NITRO,
	SHIELD,
	# weapons
	GUN, TURRET, LAUNCHER, DROPPER, MALA, # kot na weapons ... napolni vsa orožja tega tipa
	BULLET, MISILE, MINA,
	}
var pickable_profiles: Dictionary = {
	PICKABLE.GUN: {
		"color": Refs.color_pickable_ammo, # _temp ... color daš v pickable export var
		"value": 20,
	},
	PICKABLE.TURRET: {
		"color": Refs.color_pickable_ammo,
		"value": 2,
	},
	PICKABLE.LAUNCHER: {
		"color": Refs.color_pickable_ammo,
		"value": 3,
	},
	PICKABLE.DROPPER: {
		"color": Refs.color_pickable_ammo,
		"value": 3,
	},
	PICKABLE.MALA: {
		"color": Refs.color_pickable_ammo,
		"value": 3,
	},
	PICKABLE.HEALTH: {
		"color": Refs.color_pickable_stat,
		"value": 0.3,
	},
	PICKABLE.LIFE: {
		"color": Refs.color_pickable_stat,
		"value": 1,
	},
	PICKABLE.GAS: {
		"color": Refs.color_pickable_stat,
		"value": 200,
	},
	PICKABLE.CASH: {
		"color": Refs.color_pickable_stat,
		"value": 50,
	},

	# NO STAT ...instants
	PICKABLE.SHIELD: {
		"color": Refs.color_pickable_ammo,
		"value": 1,
	},
	PICKABLE.NITRO: {
		"color": Refs.color_pickable_feature,
		"value": 2, # factor
	},
	PICKABLE.RANDOM: { # nujno zadnji, ker ga izloči ob žrebanju
		"color": Refs.color_pickable_random,
		"value": 0, # nepomebno, ker random range je število ključev v tem slovarju
	},
	PICKABLE.GOAL: {
		"color": Refs.color_pickable_stat,
		"value": 100,
	},
	}
