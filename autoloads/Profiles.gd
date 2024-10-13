extends Node


# BOLTS so vozila
# PLAYERS so vozniki vozil (P1, P2, P3, ...)
# AI je komp kontroler
# HUMAN je človeški kontroller (ARROWS, WASD, JP1, JP2, AI)

func players_and_ai(): pass

var default_player_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	# bolt stats
	"wins" : 2,
	"life" : 5,
	"cash_count": 0,
	"health" : 10,
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

enum PLAYER {P1, P2, P3, P4}
var player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	PLAYER.P1 : {
		"player_name": "P1",
		"player_avatar": preload("res://gui/avatars/avatar_01.png"),
#		"player_color": Color.white,
		"player_color": Color.black, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_type": CONTROLLER_TYPE.ARROWS,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	PLAYER.P2 : {
		"player_name": "P2",
		"player_avatar": preload("res://gui/avatars/avatar_02.png"),
		"player_color": Ref.color_red,
		"controller_type" : CONTROLLER_TYPE.WASD,
#		"controller_type" : CONTROLLER_TYPE.JP1,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	PLAYER.P3 : {
		"player_name" : "P3",
		"player_avatar" : preload("res://gui/avatars/avatar_03.png"),
		"player_color" : Ref.color_yellow, # color_yellow, color_green, color_red
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLT_TYPE.BASIC,
	},
	PLAYER.P4 : {
		"player_name" : "P4",
		"player_avatar" : preload("res://gui/avatars/avatar_04.png"),
		"player_color" : Ref.color_green,
		"controller_type" : CONTROLLER_TYPE.WASD,
		"bolt_type": BOLT_TYPE.BASIC,
	},
}

var ai_profile: Dictionary = {
	# za prepis player profila
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

enum BOLT_TYPE {SMALL, BASIC, BIG, RIGID}
var bolt_profiles: Dictionary = {
	BOLT_TYPE.BASIC: {
#		"bolt_texture": preload("res://assets/textures/bolt/bolt_alt.png"),
		"bolt_scene": preload("res://game/bolt/Bolt.tscn"),
		"on_hit_disabled_time": 2,
		"engine_hsp": 5000, # pospešek motorja do največje moči (horsepower?)
		"power_burst_hsp": 5000, # pospešek motorja do največje moči (horsepower?)
		"max_engine_power": 500000, # 1 - 500 konjev 
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


func ammo(): pass

enum AMMO {BULLET, MISILE, MINA, SHIELD}
var ammo_profiles : Dictionary = {
	AMMO.BULLET: {
		"reload_time": 0.2,
		"hit_damage": 2, # z 1 se zavrti pol kroga ... vpliva na hitrost in čas rotacije
		"speed": 1500,
		"lifetime": 1.0, # domet vedno merim s časom
		"mass": 0.03, # 300g
		"direction_start_range": [0, 0] , # natančnost misile
#		"scene": preload("res://game/weapons/ammo/bullet/Bullet.tscn"),
		"scene": preload("res://game/weapons/ammo/bullet/Bullet.tscn"),
		"ammo_count_key": "bullet_count", # player stats name
		#		"icon_scene": preload("res://assets/icons/icon_bullet.tres"), ... trenutno ne rabim
	},
	AMMO.MISILE: {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"hit_damage": 5, # 10 je max energija
		"speed": 500,
		"lifetime": 3.2, # domet vedno merim s časom
		"mass": 1, # 10kg
		"direction_start_range": [-0.1, 0.1] , # natančnost misile
		"scene": preload("res://game/weapons/ammo/misile/Misile.tscn"),
		"ammo_count_key": "misile_count",
		#		"icon_scene": preload("res://assets/icons/icon_misile.tres"),
	},
	AMMO.MINA: {
		"reload_time": 0.1, #
		"hit_damage": 5,
		"speed": 50,
		"lifetime": 0, # 0 pomeni večno
		"mass": 0.5, # prilagojeno za učinek na tarčo
		"direction_start_range": [0, 0] , # natančnost misile
		"scene": preload("res://game/weapons/ammo/mina/Mina.tscn"),
		"ammo_count_key": "mina_count",
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},
	AMMO.SHIELD: {
#		"reload_time": 0.1, #
#		"hit_damage": 5,
#		"speed": 50,
		"lifetime": 5, # cikli animacije
		"scene": preload("res://game/weapons/ammo/shield/Shield.tscn"),
#		"mass": 3,
#		"direction_start_range": [0, 0] , # natančnost misile
		#		"icon_scene": preload("res://assets/icons/icon_mina.tres"),
	},
}


func levels(): pass

enum SURFACE_TYPE {PLAIN, NITRO, GRAVEL, HOLE, TRACKING}
var surface_type_profiles: Dictionary = {
	SURFACE_TYPE.PLAIN: {
		"engine_power_factor": 1, # koliko original powerja
	},
	SURFACE_TYPE.NITRO: {
		"engine_power_factor": 2, # koliko original powerja
	},
	SURFACE_TYPE.GRAVEL: {
		"engine_power_factor": 0.3, 
		"rear_lin_damp": 20, # vrednost, da riti nič ne odnaša
	},
	SURFACE_TYPE.HOLE: {
		"engine_power_factor": 0.1,
	},
	SURFACE_TYPE.TRACKING: {
	},
}


func level_objects(): pass

enum LEVEL_OBJECT {BRICK_GHOST, BRICK_BOUNCER, BRICK_MAGNET, BRICK_TARGET, FLATLIGHT, GOAL_PILLAR}
var level_object_profiles: Dictionary = { 
	# ne rabiš povsod istih vsebin, ker element vleče samo postavke, ki jih rabi
	LEVEL_OBJECT.BRICK_GHOST: {
		"color": Ref.color_brick_ghost,
		"value": 30,
		"speed_brake_div": 10,
		"elevation": 5,
		"object_scene": preload("res://game/objects/BrickGhost.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.BRICK_BOUNCER: {
		"color": Ref.color_brick_bouncer,
		"value": 10,
		"bounce_strength": 2,
		"elevation": 5,
		"object_scene": preload("res://game/objects/BrickBouncer.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.BRICK_MAGNET: {
		"color": Ref.color_brick_magnet_off,
		"value": 0,
		"gravity_force": 300.0,
		"elevation": 5,
		"object_scene": preload("res://game/objects/BrickMagnet.tscn"),
		"ai_target_rank": 0, # 0 pomeni, da se izogneš
	},	
	LEVEL_OBJECT.BRICK_TARGET: {
		"color": Ref.color_brick_target,
		"value": 100,
		"elevation": 5,
		"object_scene": preload("res://game/objects/BrickTarget.tscn"),
		"ai_target_rank": 0,
	},
	LEVEL_OBJECT.FLATLIGHT: {
		"color": Ref.color_brick_light_off,
		"value": 10,
		"elevation": 0,
		"object_scene": preload("res://game/objects/FlatLight.tscn"),
		"ai_target_rank": 3,
	},
	LEVEL_OBJECT.GOAL_PILLAR: {
		"value": 1000,
		"elevation": 5,
		"object_scene": preload("res://game/objects/GoalPillar.tscn"),
		"ai_target_rank": 5,
	},
}


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
		"in_random_selection": true, # vključeno v random izbor?
		"color": Ref.color_pickable_ammo,
		"value": 20,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_MISILE: {
		"in_random_selection": true,
		"color": Ref.color_pickable_ammo,
		"value": 2,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 3,
	}, 
	PICKABLE.PICKABLE_MINA: {
		"in_random_selection": true,
		"color": Ref.color_pickable_ammo,
		"value": 3,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 3,
	}, 
	PICKABLE.PICKABLE_SHIELD: {
		"in_random_selection": true,
		"color": Ref.color_pickable_ammo,
		"value": 1,
		"elevation": 3,
		"time": 3,
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_HEALTH: {
		"in_random_selection": true,
		"color": Ref.color_pickable_stat,
		"value": 0,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_LIFE: {
		"in_random_selection": true,
		"color": Ref.color_pickable_stat,
		"value": 1,
		"elevation": 3,
		"time": 0, # sekunde
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_GAS: {
		"in_random_selection": false,
		"color": Ref.color_pickable_stat,
		"value": 200,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 3,
	},
	PICKABLE.PICKABLE_CASH: {
		"in_random_selection": false,
		"color": Ref.color_pickable_stat,
		"value": 50,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 0,
	},
	PICKABLE.PICKABLE_POINTS: {
		"in_random_selection": false,
		"color": Ref.color_pickable_stat,
		"value": 100,
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 2,
	},
	PICKABLE.PICKABLE_NITRO: {
		"in_random_selection": false,
		"color": Ref.color_pickable_feature,
		"value": 2, # factor
		"elevation": 3,
		"time": 1.5,
		"ai_target_rank": 10,
	},
	PICKABLE.PICKABLE_RANDOM: {
		"in_random_selection": false,
		"color": Ref.color_pickable_random,
		"value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"elevation": 3,
		"time": 0,
		"ai_target_rank": 9,
	},
}


var arena_tilemap_profiles: Dictionary = { # za generator
	"default_arena" : Vector2.ONE,
}
