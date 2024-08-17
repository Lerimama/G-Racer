extends Node

## lastnosti entitet, pikablov, boltov, plejerja, ai ...

enum Players {P1, P2, P3, P4, ENEMY}
enum BoltTypes {SMALL, BASIC, BIG}


var bolt_profiles: Dictionary = {
	BoltTypes.BASIC: {
		"bolt_texture": preload("res://assets/sprites/bolt/bolt_alt.png"),
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
		},
}


var default_bolt_stats: Dictionary = { # tole ne uporabljam v zadnji varianti
	# bolt stats
	"wins" : 2,
	"life" : 5,
	"energy" : 10,
	"bullet_count" : 100,
	"misile_count" : 5,
	"mina_count" : 3,
	"shocker_count" : 3,
	"gas_count": 5000,
	# score
	"points" : 0,
	"level_rank" : 0, 
	"laps_count" : 0,
	"best_lap_time" : 0,
	"level_time" : 0, # sekunde ... naj bodo stotinke
}


var enemy_profile: Dictionary = {
	"aim_time": 1,
	"seek_rotation_range": 60,
	"seek_rotation_speed": 3,
	"seek_distance": 640 * 0.7,
	"racing_engine_power": 80, # 80 ima skoraj identično hitrost kot plejer
	"idle_engine_power": 35,
	"battle_engine_power": 120, # je enaka kot od  bolta 
	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
}

var ai_profile: Dictionary = {
	# ni še implementiran!!!!!!
	"ai_brake_distance": 0.8, # množenje s hitrostjo
	"ai_brake_factor": 150, # distanca do trka ... večja ko je, bolj je pazljiv
	"racing_engine_power": 78, # 80 ima skoraj identično hitrost kot plejer
	"idle_engine_power": 35,
	
	
#	"seek_rotation_speed": 3,
#	"seek_distance": 640 * 0.7,
#	"battle_engine_power": 120, # je enaka kot od  bolta 
#	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
}


var player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	Players.P1 : {
		"player_name" : "Moe",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_01.png"),
		"player_color" : Set.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_profile" : "ARROWS",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Players.P2 : {
		"player_name" : "Zed",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_02.png"),
		"player_color" : Set.color_red,
		"controller_profile" : "WASD",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Players.P3 : {
		"player_name" : "Dot",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_03.png"),
		"player_color" : Set.color_yellow, # color_yellow, color_green, color_red
#		"controller_profile" : "ARROWS",
		"controller_profile" : "WASD",
#		"controller_profile" : "JP1",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Players.P4 : {
		"player_name" : "Jax",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_04.png"),
		"player_color" : Set.color_green,
		"controller_profile" : "WASD",
#		"controller_profile" : "JP2",
#		"controller_profile" : "WASD",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltPlayer.tscn"),
	},
	Players.ENEMY : {
		"player_name" : "Rat",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_05.png"),
		"player_color" : Color.whitesmoke,
		"controller_profile" : "AI",
		"bolt_type:": BoltTypes.BASIC,
		"player_scene": preload("res://game/bolt/BoltEnemy.tscn"),
	},
}


var pickable_profiles: Dictionary = {
	# imena so ista kot enum ključi v pickables
	# random so samo pickabli, uporablja se samo v DUEL stilu
	
	"BULLET": { # BULLET
		"for_random_selection": true, # vključeno v random izbor?
		"pickable_color": Set.color_pickable_weapon,
		"pickable_value": 20,
		"pickable_time": 0, # pomeni, da ni časovno pogojen učinek
		"scene_path": preload("res://game/arena/pickables/PickableBullet.tscn"), # pot rabim samo pri random spawnanju
	},
	"MISILE": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_weapon,
		"pickable_value": 2,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableMisile.tscn"),
	}, 
	"MINA": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_weapon,
		"pickable_value": 3,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableMina.tscn"),
	}, 
	"SHOCKER": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_weapon,
		"pickable_value": 3,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableShocker.tscn"),
	}, 
	"SHIELD": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_feature,
		"pickable_value": 1,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableShield.tscn"),
	},
	"ENERGY": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_stat,
		"pickable_value": 0,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableEnergy.tscn"),
	},
	"LIFE": {
		"for_random_selection": true,
		"pickable_color": Set.color_pickable_stat,
		"pickable_value": 1,
		"pickable_time": 0, 
		"scene_path": preload("res://game/arena/pickables/PickableLife.tscn"),
	},
	"GAS": {
		"for_random_selection": false,
		"pickable_color": Set.color_pickable_stat,
		"pickable_value": 200,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickableGas.tscn"),
	},
	"NITRO": {
		"for_random_selection": false,
		"pickable_color": Set.color_pickable_feature,
		"pickable_value": 700,
		"pickable_time": 1.5, # sekunde
		"scene_path": preload("res://game/arena/pickables/PickableNitro.tscn"),
	},
	"TRACKING": {
		"for_random_selection": false,
		"pickable_color": Set.color_pickable_feature,
		"pickable_value": 0.7,
		"pickable_time": 5,
		"scene_path": preload("res://game/arena/pickables/PickableTracking.tscn"),
	},
	"POINTS": {
		"for_random_selection": false,
		"pickable_color": Set.color_pickable_stat,
		"pickable_value": 100,
		"pickable_time": 0,
		"scene_path": preload("res://game/arena/pickables/PickablePoints.tscn"),
	},
	"RANDOM": {
		"for_random_selection": false,
		"pickable_color": Set.color_pickable_random,
		"pickable_value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"pickable_time": 0, # sekunde
		"scene_path": preload("res://game/arena/pickables/PickableRandom.tscn"),
	},
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


var controller_profiles : Dictionary = {
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
