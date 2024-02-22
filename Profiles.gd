extends Node

## lastnosti entitet, pikablov, boltov, plejerja, ai ...


var pickable_profiles: Dictionary = {
	# imena so ista kot enum ključi v pickables
	"BULLET": { # BULLET
#		"path": preload("res://game/arena_elements/pickables/PickableBullet.tscn"),
		"pickable_value": 20,
		"pickable_time": 0, # sekunde
	},
	"MISILE": { # MISILE
#		"path": preload("res://game/arena_elements/pickables/PickableMisile.tscn"),
		"pickable_value": 2,
		"pickable_time": 0, # sekunde
	}, 
	"SHOCKER": { # SHOCKER
#		"path": preload("res://game/arena_elements/pickables/PickableShocker.tscn"),
		"pickable_value": 3,
		"pickable_time": 10, # sekunde
	}, 
	"SHIELD": { # SHIELD
#		"path": preload("res://game/arena_elements/pickables/PickableShield.tscn"),
		"pickable_value": 1,
		"pickable_time": 0, # sekunde
	},
	"ENERGY": { # ENERGY
#		"path": preload("res://game/arena_elements/pickables/PickableEnergy.tscn"),
		"pickable_value": 0,
		"pickable_time": 0, # sekunde
	},
	"LIFE": { # LIFE
#		"path": preload("res://game/arena_elements/pickables/PickableLife.tscn"),
		"pickable_value": 1,
		"pickable_time": 0, # sekunde
	},
	"NITRO": { # NITRO
#		"path": preload("res://game/arena_elements/pickables/PickableNitro.tscn"),
		"pickable_value": 500,
		"pickable_time": 10, # sekunde
	},
	"TRACKING": { # TRACKING
#		"path": preload("res://game/arena_elements/pickables/PickableTracking.tscn"),
		"pickable_value": 0.7,
		"pickable_time": 10, # sekunde
	},
	"RANDOM": { # RANDOM
#		"path": preload("res://game/arena_elements/pickables/PickableRandom.tscn"),
		"pickable_value": 0, # nepomebno, ker random range je število ključev v tem slovarju
		"pickable_time": 0, # sekunde
	},
}

var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam	
	"P1" : { # ključi bodo kasneje samo indexi
		"player_name" : "Moe",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_01.png"),
		"player_color" : Set.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
		"controller_profile" : "ARROWS",
	},
	"P2" : {
		"player_name" : "Zed",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_02.png"),
		"player_color" : Set.color_red,
		"controller_profile" : "WASD",
	},
	"P3" : {
		"player_name" : "Dot",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_03.png"),
		"player_color" : Set.color_yellow, # color_yellow, color_green, color_red
		"controller_profile" : "ARROWS",
#		"controller_profile" : "JP1",
	},
	"P4" : {
		"player_name" : "Jax",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_04.png"),
		"player_color" : Set.color_green,
#		"controller_profile" : "JP2",
		"controller_profile" : "WASD",
		
	},
	"E1" : {
		"player_name" : "Rat",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_05.png"),
		"player_color" : Set.color_gray0,
		"controller_profile" : "AI",
	},
	"E2" : {
		"player_name" : "Bub",
		# "player_controller" : "W/A/S/D/Sp",
		"player_avatar" : preload("res://assets/sprites/avatars/avatar_06.png"),
		"player_color" : Set.color_gray0,
		"controller_profile" : "AI",
	},
}



var bolt_profiles: Dictionary = {
	"basic": {
		"bolt_texture": preload("res://assets/bolt/bolt_basic.png"),
		"fwd_engine_power": 200, # 1 - 500 konjev 
		"rev_engine_power": 150, # 1 - 500 konjev 
		"turn_angle": 15, # deg per frame
		"free_rotation_multiplier": 15, # rotacija kadar miruje
		"drag": 1.0, # 1 - 10 # raste kvadratno s hitrostjo
		"side_traction": 0.1, # 0 - 1
		"bounce_size": 0.3, # 0 - 1 
		"inertia": 5, # kg
		"reload_ability": 1,# 1 - 10 ... to je deljitelj reload timeta od orožja
		"on_hit_disabled_time": 1.5,
		"shield_loops_limit": 3,
		# "bolt_trail_alpha": 0.05, ... ne dela ... trail je prozoren
		},
}

var enemy_profile: Dictionary = {
	"aim_time": 1,
	"seek_rotation_range": 60,
	"seek_rotation_speed": 3,
	"seek_distance": 640 * 0.7,
	"engine_power_idle": 35,
	"engine_power_battle": 120, # je enaka kot od  bolta 
#	"bullet_push_factor": 0.1,
#	"misile_push_factor": 0.5,
	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
}

var default_bolt_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
#	"player_start_position" : Vector2(0, 0),
	"life" : 5,
	"energy" : 2,
	"bullet_power" : 0.1,
	"bullet_count" : 30,
	"misile_count" : 5,
	"shocker_count" : 5,
}

var default_player_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"player_active" : true,
	"life" : 5,
	"points" : 10,
	"wins" : 0,
}

var weapon_profiles : Dictionary = {
	"bullet": {
		"reload_time": 0.2,
		"hit_damage": 1,
		"speed": 1000,
		"lifetime": 1.0, #domet vedno merim s časom
		"inertia": 50,
		"direction_start_range": [0, 0] , # natančnost misile
	},
	"misile": {
		"reload_time": 3, # ga ne rabi, ker mora misila bit uničena
		"hit_damage": 4,
		"speed": 150,
		"lifetime": 1.0, #domet vedno merim s časom
		"inertia": 100,
		"direction_start_range": [-0.1, 0.1] , # natančnost misile
	},
	"shocker": {
		"reload_time": 1.0, #
		"hit_damage": 1,
		"speed": 50,
		"lifetime": 10, #domet vedno merim s časom
		"inertia": 1,
		"direction_start_range": [0, 0] , # natančnost misile
	},
}

# v plejerja pošljem imena akcij iz input mapa
var default_controller_actions : Dictionary = {
	"ARROWS" : {
		fwd_action = "forward", 
		rev_action = "reverse",
		left_action = "left",
		right_action = "right",
		shoot_bullet_action = "ctrl",
		shoot_misile_action = "shift",
		shoot_shocker_action = "alt",
		},
	"WASD" : {
		fwd_action = "w",
		rev_action = "s",
		left_action = "a",
		right_action = "d",
		shoot_bullet_action = "v",
		shoot_misile_action = "g",
		shoot_shocker_action = "space",
	},
	"JP1" : {
		fwd_action = "jp1_fwd",
		rev_action = "jp1_rev",
		left_action = "jp1_left",
		right_action = "jp1_right",
		shoot_bullet_action = "jp1_bullet",
		shoot_misile_action = "jp1_misile",
		shoot_shocker_action = "jp1_shocker",
	},
	"JP2" : {
		fwd_action = "jp2_fwd",
		rev_action = "jp2_rev",
		left_action = "jp2_left",
		right_action = "jp2_right",
		shoot_bullet_action = "jp2_bullet",
		shoot_misile_action = "jp2_misile",
		shoot_shocker_action = "jp2_shocker",
	},
}

# za generator
var arena_tilemap_profiles: Dictionary = {
	"default_arena" : Vector2.ONE,
}