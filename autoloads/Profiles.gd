extends Node


# BOLTS so vozila
# DRIVERS so vozniki vozil (P1, P2, P3, ...)
# AI je komp kontroler
# HUMAN je človeški kontroller (ARROWS, WASD, JP1, JP2, AI)

func drivers_and_ai(): pass

var default_driver_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	# bolt stats
	"wins" : 2,
	"life" : 5,
	"cash_count": 0,
#	"health" : 10,
	"health" : 1, # health percetnage
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

enum DRIVER {P1, P2, P3, P4}
var driver_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
	DRIVER.P1 : {
		"driver_name": "P1",
		"driver_avatar": preload("res://game/gui/avatars/avatar_01.png"),
#		"driver_color": Color.white,
		"driver_color": Color.black, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_type": CONTROLLER_TYPE.ARROWS,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	DRIVER.P2 : {
		"driver_name": "P2",
		"driver_avatar": preload("res://game/gui/avatars/avatar_02.png"),
		"driver_color": Rfs.color_red,
		"controller_type" : CONTROLLER_TYPE.WASD,
#		"controller_type" : CONTROLLER_TYPE.JP1,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	DRIVER.P3 : {
		"driver_name" : "P3",
		"driver_avatar" : preload("res://game/gui/avatars/avatar_03.png"),
		"driver_color" : Rfs.color_yellow, # color_yellow, color_green, color_red
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	DRIVER.P4 : {
		"driver_name" : "P4",
		"driver_avatar" : preload("res://game/gui/avatars/avatar_04.png"),
		"driver_color" : Rfs.color_green,
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLT_TYPE.BASIC,
	},
}

var ai_profile: Dictionary = {
	# za prepis driver profila
	"controller_type" : CONTROLLER_TYPE.AI,
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

enum CONTROLLER_TYPE {ARROWS, WASD, JP1, JP2, AI}
var controller_profiles : Dictionary = {
	CONTROLLER_TYPE.ARROWS: {
		fwd_action = "p1_fwd",
		rev_action = "p1_rev",
		left_action = "p1_left",
		right_action = "p1_right",
		shoot_action = "p1_shoot",
		selector_action = "p1_selector",
		"controller_scene": preload("res://game/bolt/ControllerHuman.tscn"),
		},
	CONTROLLER_TYPE.WASD : {
		fwd_action = "p2_fwd",
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		selector_action = "p2_selector",
		"controller_scene": preload("res://game/bolt/ControllerHuman.tscn"),
	},
	CONTROLLER_TYPE.JP1 : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		selector_action = "jp1_selector",
		"controller_scene": preload("res://game/bolt/ControllerHuman.tscn"),
	},
	CONTROLLER_TYPE.JP2 : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		selector_action = "jp2_selector",
		"controller_scene": preload("res://game/bolt/ControllerHuman.tscn"),
	},
	CONTROLLER_TYPE.AI : {
		fwd_action = "ai_fwd",
		rev_action = "ai_rev",
		left_action = "ai_left",
		right_action = "ai_right",
		shoot_action = "ai_shoot",
		selector_action = "ai_selector",
		"controller_scene": preload("res://game/bolt/ControllerAI.tscn"),
	},
}

#const bolt_engine_power_factor:  =


enum BOLT_TYPE {SMALL, BASIC, BIG, RIGID}
var bolt_profiles: Dictionary = {
	BOLT_TYPE.BASIC: {
#		"bolt_texture": preload("res://assets/textures/bolt/bolt_alt.png"),
		"bolt_scene": preload("res://game/bolt/Bolt.tscn"),
		"on_hit_disabled_time": 2,
		"accelaration_power": 5000, # delta seštevanje moči motorja do največje moči
		"max_engine_power": 500000, # 1 - 500 konjev
		"engine_power_fast_start": 5000, # pospešek motorja do največje moči (horsepower?)
		"gas_usage": -0.1, # per HSP?
		"idle_motion_gas_usage": -0.05, # per HSP?
		"ai_target_rank": 5,
		# fizika
		"mass": 80, # 800 kil, front in rear teža se uporablja bolj za razmerje
		# driving
		"drive_ang_damp": 16, # regulacija ostrine zavijanja ... tudi driftanja
		"drive_lin_damp": 2, # imam ga za omejitev slajdanja prvega kolesa
		"drive_lin_damp_rear": 20, # regulacija driftanja
		# idle motion
		"idle_lin_damp": 0.5,
		"idle_ang_damp": 0.5,
		"free_rotation_power": 14000, # na oba
		"drift_power": 17000, # na rear
		"glide_power_F": 46500,
		"glide_power_R": 50000,
		"glide_ang_damp": 5, # da se ha rotirat
		"max_engine_rotation_deg": 35, # obračanje koles (45 stzopinj je bolj ala avto)
		# material
		"bounce": 0.5,
		"friction": 0.2,
		},
}


func equipment(): pass

enum EQUIPMENT {NITRO, SHIELD}
var equipment_profiles : Dictionary = {
	EQUIPMENT.NITRO: {
		"value": 1,
		"nitro_power_adon": 1, # prišteješ moč
		"time": 3,
	},
	EQUIPMENT.SHIELD: {
#		"reload_time": 0.1, #
#		"hit_damage": 5,
#		"speed": 50,
		"lifetime": 5, # cikli animacije
		"scene": preload("res://game/weapons/ammo/shield/Shield.tscn"),
		"time": 3,
#		"direction_start_range": [0, 0] , # natančnost misile
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},
}


func ammo(): pass

enum AMMO {BULLET, MISILE, MINA, SHIELD}
var ammo_profiles : Dictionary = {
	AMMO.BULLET: {
		"reload_time": 0.2,
		"hit_damage": 0.2, # z 1 se zavrti pol kroga ... vpliva na hitrost in čas rotacije
		"speed": 1500,
		"lifetime": 1.0, # domet vedno merim s časom
		"mass": 0.03, # 300g
		"direction_start_range": [0, 0] , # natančnost misile
#		"scene": preload("res://game/weapons/ammo/bullet/Bullet.tscn"),
		"scene": preload("res://game/weapons/ammo/bullet/Bullet.tscn"),
		"ammo_count_key": "bullet_count", # driver stats name
		"ammo_stat_key": DRIVER_STATS.BULLET_COUNT,
		#		"icon_scene": preload("res://assets/icons/icon_bullet.tres"), ... trenutno ne rabim
	},
	AMMO.MISILE: {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"hit_damage": 0.5, # 10 je max energija
		"speed": 500,
		"lifetime": 3.2, # domet vedno merim s časom
		"mass": 1, # 10kg
		"direction_start_range": [-0.1, 0.1] , # natančnost misile
		"scene": preload("res://game/weapons/ammo/misile/Misile.tscn"),
		"ammo_count_key": "misile_count", # znebi se
		"ammo_stat_key": DRIVER_STATS.MISILE_COUNT,
		#		"icon_scene": preload("res://assets/icons/icon_misile.tres"),
	},
	AMMO.MINA: {
		"reload_time": 0.1, #
		"hit_damage": 0.5,
		"speed": 50,
		"lifetime": 0, # 0 pomeni večno
		"mass": 0.5, # prilagojeno za učinek na tarčo
		"direction_start_range": [0, 0] , # natančnost misile
		"scene": preload("res://game/weapons/ammo/mina/Mina.tscn"),
		"ammo_count_key": "mina_count",
		"ammo_stat_key": DRIVER_STATS.MINA_COUNT,
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},

}


func levels(): pass

enum SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}
var surface_type_profiles: Dictionary = {
	SURFACE.NONE: {
		"max_engine_power_factor": 1, # koliko original powerja
		"shake_amount": 0,
	},
	SURFACE.CONCRETE: {
		"max_engine_power_factor": 1.15, # koliko original powerja
		"shake_amount": 0,
	},
	SURFACE.NITRO: {
		"max_engine_power_factor": 2, # koliko original powerja
		"shake_amount": 0,
	},
	SURFACE.GRAVEL: {
		"max_engine_power_factor": 0.3,
		"shake_amount": 0,
	},
	SURFACE.HOLE: {
		"max_engine_power_factor": 0.1,
		"shake_amount": 0,
	},
	SURFACE.TRACKING: {
		"shake_amount": 0,
	},
}


func level_objects(): pass

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



func pickables(): pass

enum DRIVER_STATS {BULLET_COUNT, MISILE_COUNT, MINA_COUNT, HEALTH, GAS_COUNT, LIFE,CASH_COUNT, POINTS }

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
		"driver_stat": DRIVER_STATS.BULLET_COUNT,
	},
	PICKABLE.PICKABLE_MISILE: {
		"color": Rfs.color_pickable_ammo,
		"value": 2,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": DRIVER_STATS.MISILE_COUNT,
	},
	PICKABLE.PICKABLE_MINA: {
		"color": Rfs.color_pickable_ammo,
		"value": 3,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": DRIVER_STATS.MINA_COUNT,
	},
	PICKABLE.PICKABLE_HEALTH: {
		"color": Rfs.color_pickable_stat,
		"value": 0,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": DRIVER_STATS.HEALTH,
	},
	PICKABLE.PICKABLE_LIFE: {
		"color": Rfs.color_pickable_stat,
		"value": 1,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": DRIVER_STATS.LIFE,
	},
	PICKABLE.PICKABLE_GAS: {
		"color": Rfs.color_pickable_stat,
		"value": 200,
		"elevation": 3,
		"ai_target_rank": 3,
		"driver_stat": DRIVER_STATS.GAS_COUNT,
	},
	PICKABLE.PICKABLE_CASH: {
		"color": Rfs.color_pickable_stat,
		"value": 50,
		"elevation": 3,
		"ai_target_rank": 0,
		"driver_stat": DRIVER_STATS.CASH_COUNT,
	},
	PICKABLE.PICKABLE_POINTS: {
		"color": Rfs.color_pickable_stat,
		"value": 100,
		"elevation": 3,
		"ai_target_rank": 2,
		"driver_stat": DRIVER_STATS.POINTS,
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


var arena_tilemap_profiles: Dictionary = { # za generator
	"default_arena" : Vector2.ONE,
}

func z_index(): pass

var z_indexes: Dictionary = {
	# indexi so delno poštimani tudi v nodetih levela
	# ref "background": -10,
	"ground": 0, # streets, surfaces
	"bolts": 1,
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
#Z INDEX
#- background = -10
#- ground terrain < -1
#- flat objects and default = 0
#- not flat or floating object = 1 - 9
#- sky > 10
