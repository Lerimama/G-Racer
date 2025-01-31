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


# ---------------------------------------------------------------------------------------------------------------------------
func stats(): pass

# vsi mogoči statsi
enum STATS {
		WINS, LIFE, HEALTH, POINTS, GAS, CASH,
		BULLET_COUNT, MISILE_COUNT, MINA_COUNT,
		LEVEL_RANK, LAPS_FINISHED, BEST_LAP_TIME, LEVEL_TIME, GOALS_REACHED
		}
var start_bolt_level_stats: Dictionary = { # tale slovar je med igro v level stats slovarju
	STATS.LEVEL_RANK: 0,
	STATS.LEVEL_TIME: 0, # hunds
	STATS.BEST_LAP_TIME: 0,
	STATS.LAPS_FINISHED: [], # časi
	STATS.GOALS_REACHED: [], # nodeti
}
var start_bolt_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	STATS.WINS : 2,
	STATS.LIFE : 5,
	STATS.CASH: 0,
	STATS.HEALTH : 1, # health percetnage
	STATS.BULLET_COUNT : 100,
	STATS.MISILE_COUNT : 5,
	STATS.MINA_COUNT : 3,
	STATS.GAS: 5000,
	STATS.POINTS : 0,
}


# ---------------------------------------------------------------------------------------------------------------------------
func drivers(): pass

enum DRIVER_ID {P1, P2, P3, P4}
var driver_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
	DRIVER_ID.P1 : {
		"driver_name": "P1",
		"driver_avatar": preload("res://home/avatar_david.tres"),
		"driver_color": Color.black, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_type": CONTROLLER_TYPE.ARROWS,
		"bolt_type": BOLTS.BASIC,
	},
	DRIVER_ID.P2 : {
		"driver_name": "P2",
		"driver_avatar": preload("res://home/avatar_magnum.tres"),
		"driver_color": Rfs.color_red,
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLTS.BASIC,
	},
	DRIVER_ID.P3 : {
		"driver_name" : "P3",
		"driver_avatar" : preload("res://home/avatar_marty.tres"),
		"driver_color" : Rfs.color_yellow, # color_yellow, color_green, color_red
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLTS.BASIC,
	},
	DRIVER_ID.P4 : {
		"driver_name" : "P4",
		"driver_avatar" : preload("res://home/avatar_mrt.tres"),
		"driver_color" : Rfs.color_green,
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLTS.BASIC,
	},
}

enum AI_TYPE {DEFAULT, LAID_BACK, SMART, AGGRESSIVE}
var ai_profile: Dictionary = {
	AI_TYPE.DEFAULT: {
		"controller_type" : CONTROLLER_TYPE.AI,
		"ai_avatar" : preload("res://home/avatar_ai.tres")
		# driving
#		"max_engine_power": 80, # 80 ima skoraj identično hitrost kot plejer
#		"battle_engine_power": 120, # je enaka kot od  bolta
		# ni še implementiran!!!!!!
#		"ai_brake_distance": 0.8, # množenje s hitrostjo
#		"ai_brake_factor": 150, # distanca do trka ... večja ko je, bolj je pazljiv
		# battle
#		"aim_time": 1,
		#	"seek_rotation_range": 60,
		#	"seek_rotation_speed": 3,
		#	"seek_distance": 640 * 0.7,
#		"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo
	},
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
		"controller_scene": preload("res://game/bolt/ControllerPlayer.tscn"),
		},
	CONTROLLER_TYPE.WASD : {
		fwd_action = "p2_fwd",
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		selector_action = "p2_selector",
		"controller_scene": preload("res://game/bolt/ControllerPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP1 : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		selector_action = "jp1_selector",
		"controller_scene": preload("res://game/bolt/ControllerPlayer.tscn"),
	},
	CONTROLLER_TYPE.JP2 : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		selector_action = "jp2_selector",
		"controller_scene": preload("res://game/bolt/ControllerPlayer.tscn"),
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


# ---------------------------------------------------------------------------------------------------------------------------
func bolt(): pass

enum BOLTS {SMALL, BASIC, BIG, TRUCK}
var bolt_profiles: Dictionary = {
	BOLTS.BASIC: {
		"bolt_scene": preload("res://game/bolt/Bolt.tscn"),
		"height": 10,
		"elevation": 7,
		"gas_usage": -0.1, # per HSP?
		"idle_motion_gas_usage": -0.05, # per HSP?
		"ai_target_rank": 5,
		"on_hit_disabled_time": 2,
		# driving params
		"engine_rotation_speed": 1,
		"fast_start_engine_power": 5,# pospešek motorja do največje moči (horsepower?)
		"masa": 100, # kg ... na driving mode set se porazdeli na prvi in drugi pogon
		"bounce": 0.5,
		"friction": 0.2,
		# NONE
		# masa in damping je na celotnem boltu
		# ostale vrednosti so vse 0
		"max_engine_power": 500, # = konjev
		#		"lin_damp": 1, # vpliva na pojemek
		#		"max_engine_rotation_deg": 45, # ne vpliva na nič ... tolk da je neka default vredbost
		#		"ang_damp": 16, # ne vpliva na vožnjo samo vpliva pa na hitrost poravnave pri prehodu

		# ---
		# MASSLESS
		# ostale vrednosti ostanejo kot za NONE
		"max_engine_power_massless": 800,
		"max_engine_rotation_deg_massless": 25,
		"ang_damp_massless": 0,
		"front_mass_bias_massless": 0.5,
		"lin_damp_front_massless": 0,
		"lin_damp_rear_massless": 5,

		# SPIN
#		"spin_torque": 10000000,
		"ang_damp_float": 0.5,
#		"max_free_thrust_rotation_deg": 90,
#		"free_rotation_power": 14, # na oba
		# DRIFT
		"drift_power": 17000, # na rear
		# GLIDE
		"glide_power_F": 465,#00,
		"glide_power_R": 500,#00,
#		"glide_ang_damp": 5, # da se ha rotirat
		},
	BOLTS.TRUCK: {
		"bolt_scene": preload("res://game/bolt/Vechicle.tscn"),
		"height": 30,
		"elevation": 5,
		"gas_usage": -0.1,
		"idle_motion_gas_usage": -0.05,
		"ai_target_rank": 11,
		"on_hit_disabled_time": 2,
		"bounce": 0.5,
		"friction": 0.2,

		# driving params
		"engine_rotation_speed": 1,
		"fast_start_engine_power": 5,# pospešek motorja do največje moči (horsepower?)
		"masa": 100, # kg ... na driving mode set se porazdeli na prvi in drugi pogon
		# DRIVING SETUP
		# ---
		# NONE
		# masa in damping je na celotnem boltu
		# ostale vrednosti so vse 0
		"max_engine_power": 500, # = konjev
		"max_engine_rotation_deg": 45, # ne vpliva na nič ... tolk da je neka default vredbost
		"ang_damp": 16, # ne vpliva na vožnjo samo vpliva pa na hitrost poravnave pri prehodu
		"lin_damp": 1, # vlpiva na pojemek
		# ---
		# MASSLESS
		"max_engine_power_massless": 800,
		"max_engine_rotation_deg_massless": 25,
		"ang_damp_massless": 0,
		"front_mass_bias_massless": 0.5,
		"lin_damp_front_massless": 0,
		"lin_damp_rear_massless": 5,
		# ostale vrednosti ostanejo kot za NONE

		# ROTATE
		"spin_torque": 10000000,
		"ang_damp_float": 0.5,
		"max_free_thrust_rotation_deg": 90,


		},
}


# ---------------------------------------------------------------------------------------------------------------------------
func equipment(): pass

enum EQUIPMENT {NITRO, SHIELD}
var equipment_profiles : Dictionary = {
	EQUIPMENT.NITRO: {
		"value": 1,
		"nitro_power_adon": 700,
		"time": 2,
	},
	EQUIPMENT.SHIELD: {
		"lifetime": 5,
		"scene": preload("res://game/equipment/shield/Shield.tscn"),
		"time": 3,
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
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
		"icon": preload("res://assets/icons/icon_bullet_VRSA.tres"),
		"scene": preload("res://game/weapons/ammo/bullet/Bullet.tscn"),
		"stat_key": STATS.BULLET_COUNT,
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
		"icon": preload("res://assets/icons/icon_misile_VRSA.tres"),
		"ammo_count_key": "misile_count", # znebi se
		"stat_key": STATS.MISILE_COUNT,
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
		"icon": preload("res://assets/icons/icon_mina_VRSA.tres"),
		"ammo_count_key": "mina_count",
		"stat_key": STATS.MINA_COUNT,
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},

}


# ---------------------------------------------------------------------------------------------------------------------------
func surfaces(): pass

enum SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}
var surface_type_profiles: Dictionary = {
	SURFACE.NONE: {
		# "all powers"
		"engine_power_adon": 0,
		"shake_amount": 0,
	},
	SURFACE.CONCRETE: {
		# "all powers"
		"engine_power_adon": 0,
		"shake_amount": 0,
	},
	SURFACE.NITRO: {
		# "all powers"
		"engine_power_adon": 700,
		"shake_amount": 0,
	},
	SURFACE.GRAVEL: {
		# "all powers"
		"engine_power_adon": -800,
		"shake_amount": 0,
	},
	SURFACE.HOLE: {
		"engine_power_adon": 0,
		"shake_amount": 0,
	},
	SURFACE.TRACKING: {
		"engine_power_adon": 0,
		"shake_amount": 0,
	},
}


# ---------------------------------------------------------------------------------------------------------------------------
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

