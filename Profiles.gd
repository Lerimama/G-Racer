extends Node

## lastnosti entitet, pikablov, boltov, plejerja, ai ...


enum BoltTypes {SMALL, BASIC, BIG}
var current_bolt_type


var bolt_profiles: Dictionary = {
	BoltTypes.BASIC: {
#		"bolt_texture": preload("res://assets/bolt/bolt.png"),
#		"bolt_texture": preload("res://assets/bolt/bolt_varz/boltbolt_alter.png"),
		"bolt_texture": preload("res://assets/bolt/bolt_alt.png"),
		"reload_ability": 1,# 1 - 10 ... to je deljitelj reload timeta od orožja
		"on_hit_disabled_time": 2,
		"shield_loops_limit": 3,
		# orig
		"fwd_engine_power": 320, # 1 - 500 konjev 
		"rev_engine_power": 150, # 1 - 500 konjev 
		"turn_angle": 10, # deg per frame
		"free_rotation_multiplier": 15, # rotacija kadar miruje
		"side_traction": 0.01, # 0 - 1
		"bounce_size": 0.5, # 0 - 1 	
		"mass": 100, # kg
		"drag": 1.5, # 1 - 10 # raste kvadratno s hitrostjo
		"drag_force_div": 100.0, # večji pomeni nižjo drag force
		"fwd_gas_usage": -0.1, # per fram
		"rev_gas_usage": -0.05, # per fram
		"tilt_speed": 150, # trenutno off
		# v1
#		"fwd_engine_power": 300, # 1 - 500 konjev 
#		"rev_engine_power": 150, # 1 - 500 konjev 
#		"turn_angle": 15, # deg per frame
#		"free_rotation_multiplier": 15, # rotacija kadar miruje
#		"drag": 1.0, # 1 - 10 # raste kvadratno s hitrostjo
#		"side_traction": 0.05, # 0 - 1
#		"bounce_size": 0.3, # 0 - 1 
		},
}


var pickable_profiles: Dictionary = {
	# imena so ista kot enum ključi v pickables
	# random so samo pickabli, uporablja se samo v DUEL stilu
	
	"BULLET": { # BULLET
		"for_random_selection": true, # vključeno v random izbor?
		"pickable_color": Set.color_green,
		"pickable_value": 20,
		"pickable_time": 0, # pomeni, da ni časovno pogojen učinek
		"scene_path": preload("res://game/arena_elements/pickables/PickableBullet.tscn"), # pot rabim samo pri random spawnanju
	},
	"MISILE": {
		"for_random_selection": true,
		"pickable_color": Set.color_green,
		"pickable_value": 2,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableMisile.tscn"),
	}, 
	"MINA": {
		"for_random_selection": true,
		"pickable_color": Set.color_green,
		"pickable_value": 3,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableMina.tscn"),
	}, 
	"SHOCKER": {
		"for_random_selection": true,
		"pickable_color": Set.color_green,
		"pickable_value": 3,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableShocker.tscn"),
	}, 
	"SHIELD": {
		"for_random_selection": true,
		"pickable_color": Set.color_green,
		"pickable_value": 1,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableShield.tscn"),
	},
	"ENERGY": {
		"for_random_selection": true,
		"pickable_color": Set.color_red,
		"pickable_value": 0,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableEnergy.tscn"),
	},
	"LIFE": {
		"for_random_selection": true,
		"pickable_color": Set.color_blue,
		"pickable_value": 1,
		"pickable_time": 0, 
		"scene_path": preload("res://game/arena_elements/pickables/PickableLife.tscn"),
	},
	"GAS": {
		"for_random_selection": false,
		"pickable_color": Set.color_red,
		"pickable_value": 200,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickableGas.tscn"),
	},
	"NITRO": {
		"for_random_selection": false,
		"pickable_color": Set.color_yellow,
		"pickable_value": 700,
		"pickable_time": 1, # sekunde
		"scene_path": preload("res://game/arena_elements/pickables/PickableNitro.tscn"),
	},
	"TRACKING": {
		"for_random_selection": false,
		"pickable_color": Set.color_green,
		"pickable_value": 0.7,
		"pickable_time": 5,
		"scene_path": preload("res://game/arena_elements/pickables/PickableTracking.tscn"),
	},
	"POINTS": {
		"for_random_selection": false,
		"pickable_color": Set.color_blue,
		"pickable_value": 100,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena_elements/pickables/PickablePoints.tscn"),
	},
	"RANDOM": {
		"for_random_selection": false,
		"pickable_color": Color.white,
		"pickable_value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"pickable_time": 0, # sekunde
		"scene_path": preload("res://game/arena_elements/pickables/PickableRandom.tscn"),
	},
}


enum Bolts {P1, P2, P3, P4, ENEMY}

var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	Bolts.P1 : { # ključi bodo kasneje samo indexi
#	"P1" : { # ključi bodo kasneje samo indexi
		"player_name" : "Moe",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_01.png"),
		"player_color" : Set.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_profile" : "ARROWS",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Bolts.P2 : {
		"player_name" : "Zed",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_02.png"),
		"player_color" : Set.color_red,
		"controller_profile" : "WASD",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Bolts.P3 : {
		"player_name" : "Dot",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_03.png"),
		"player_color" : Set.color_yellow, # color_yellow, color_green, color_red
#		"controller_profile" : "ARROWS",
		"controller_profile" : "WASD",
#		"controller_profile" : "JP1",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Bolts.P4 : {
		"player_name" : "Jax",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_04.png"),
		"player_color" : Set.color_green,
		"controller_profile" : "WASD",
#		"controller_profile" : "JP2",
#		"controller_profile" : "WASD",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Bolts.ENEMY : {
		"player_name" : "Rat",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_05.png"),
		"player_color" : Set.color_gray0,
		"controller_profile" : "AI",
		"bolt_type:": BoltTypes.BASIC,
#		"player_scene": preload("res://game/bolt/Enemy.tscn"),
		"player_scene": preload("res://game/bolt/BoltEnemy.tscn"),
	},
}


var enemy_profile: Dictionary = {
	
	"aim_time": 1,
	"seek_rotation_range": 60,
	"seek_rotation_speed": 3,
	"seek_distance": 640 * 0.7,
	"racing_engine_power": 78, # 80 ima skoraj identično hitrost kot plejer
	"idle_engine_power": 35,
	"battle_engine_power": 120, # je enaka kot od  bolta 
#	"bullet_push_factor": 0.1,
#	"misile_push_factor": 0.5,
	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
}

#var default_bolt_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
##	"player_start_position" : Vector2(0, 0),
#	"life" : 5,
#	"energy" : 10,
#	"bullet_power" : 0.1,
#	"bullet_count" : 100,
#	"misile_count" : 5,
#	"mina_count" : 3,
#	"shocker_count" : 3,
#	"gas_count" : 500, # 300 je kul
#}

var default_bolt_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
#var default_player_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
# statse ima tudi enemy
#	"player_active" : true,
#	"player_lap_time" : 0,
#	"player_laps" : 0,
#	"player_life" : 5,
	"points" : 0,
	"wins" : 2,
	# ex bolt stats
	"life" : 5,
	"energy" : 10,
	"bullet_power" : 0.1,
	"bullet_count" : 100,
	"misile_count" : 5,
	"mina_count" : 3,
	"shocker_count" : 3,
	# per level/race
	"fastest_lap_time" : 0,
	"laps_finished_count" : 0,
	"level_finished_time" : 0, # sekunde
	"level_rank" : 0, 
#	"race_time": 0,
	"gas_count": 5000,
}

var weapon_profiles : Dictionary = {
	"bullet": {
		"reload_time": 0.1,
		"hit_damage": 2, # z 1 se zavrti pol kroga ... vpliva na hitrost in čas rotacije
		"speed": 1000,
		"lifetime": 1.0, #domet vedno merim s časom
		"mass": 1.5, # glede na to kakšno inercijo hočem
		"direction_start_range": [0, 0] , # natančnost misile
	},
	"misile": {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"hit_damage": 5, # 10 je max energija
		"speed": 100,
		"lifetime": 1.0, #domet vedno merim s časom
		"mass": 5,
		"direction_start_range": [-0.1, 0.1] , # natančnost misile
	},
	"mina": {
		"reload_time": 0.1, #
		"hit_damage": 5,
		"speed": 50,
		"lifetime": 10, #domet vedno merim s časom
		"mass": 3,
		"direction_start_range": [0, 0] , # natančnost misile
	},
	"shocker": {
		"reload_time": 1.0, #
		"hit_damage": 2,
		"speed": 50,
		"lifetime": 10, #domet vedno merim s časom
		"mass": 10,
		"direction_start_range": [0, 0] , # natančnost misile
	},
}

# v plejerja pošljem imena akcij iz input mapa
var default_controller_actions : Dictionary = {
	"ARROWS" : {
		fwd_action = "p1_fwd", 
		rev_action = "p1_rev",
		left_action = "p1_left",
		right_action = "p1_right",
		shoot_action = "p1_shoot",
		feature_action = "p1_feature",
		},
	"WASD" : {
		fwd_action = "p2_fwd", 
		rev_action = "p2_rev",
		left_action = "p2_left",
		right_action = "p2_right",
		shoot_action = "p2_shoot",
		feature_action = "p2_feature",
	},
	"JP1" : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_action = "jp1_shoot",
		feature_action = "jp1_feature",
	},
	"JP2" : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_action = "jp2_shoot",
		feature_action = "jp2_feature",
	},
	"AI" : {
		fwd_action = "nn",
		rev_action = "nn",
		left_action = "nn",
		right_action = "nn",
		shoot_action = "nn",
		feature_action = "nn",
	},
}

# za generator
var arena_tilemap_profiles: Dictionary = {
	"default_arena" : Vector2.ONE,
}
