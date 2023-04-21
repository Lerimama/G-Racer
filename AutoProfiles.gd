extends Node


var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
	"P1" : {
		"player_name" : "P1",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_01.png"),
		"player_color" : Config.color_blue, # color_yellow, color_green, color_red
		"controller_profile" : "ARROWS",
	},
	"P2" : {
		"player_name" : "P2",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_02.png"),
		"player_color" : Config.color_red,
		"controller_profile" : "WASD",
	},
	"E1" : {
		"player_name" : "E1",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_03.png"),
		"player_color" : Color.greenyellow,
		"controller_profile" : "AI",
	},
	"E2" : {
		"player_name" : "E2",
		# "player_controller" : "W/A/S/D/Sp",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_04.png"),
		"player_color" : Color.white,
		"controller_profile" : "AI",
	},
}

var bolt_profiles: Dictionary = {
	"basic": {
		"bolt_texture": preload("res://assets/bolt/bolt_basic.png"),
		"engine_power": 250, # 1 - 500 konjev 
		"max_speed_reverse": 50, # velocity.length() 
		"turn_angle": 15, # deg per frame
		"rotation_multiplier": 15, # rotacija kadar miruje
		"drag": 1.0, # 1 - 10 # raste kvadratno s hitrostjo
		"side_traction": 0.1, # 0 - 1
		"bounce_size": 0.3, # 0 - 1 
		"inertia": 5, # kg
		"reload_ability": 1,# 1 - 10 ... to je deljitelj reload timeta od orožja
		"on_hit_disabled_time": 1.5,
		"shield_loops_limit": 3,
		},
}

var enemy_profiles: Dictionary = {
	"aim_time": 1,
	"seek_rotation_range": 60,
	"seek_rotation_speed": 3,
	"seek_distance": 640 * 0.7,
	"engine_power_idle": 50,
	"engine_power_battle": 150, # je enaka kot od  bolta 
	"shooting_ability": 0.5, # adaptacija hitrosti streljanja, adaptacija natančnosti ... 1 pomeni, da adaptacij ni - 2 je že zajebano u nulo 
#	"bullet_push_factor": 0.1,
#	"misile_push_factor": 0.5,
}

var default_bolt_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
#	"player_start_position" : Vector2(0, 0),
	"health" : 10,
	"bullet_count" : 30,
	"misile_count" : 5,
	"shocker_count" : 3,
}


var default_player_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
	"player_active" : true,
#	"player_start_position" : Vector2(0, 0),
#	"health" : 10,
#	"life" : 3,
#	"bullet_count" : 30,
#	"misile_count" : 5,
#	"shocker_count" : 3,
	"score" : 0000,
	"bricks" : 0,
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

# v uporabi šele ko je kofigurator
# imena akcij za player "input"
#var fwd_action: String = "fwd" 
#var rev_action: String = "rev"
#var left_action: String = "left"
#var right_action: String = "right"
#var shoot_bullet_action: String = "shoot_bullet"
#var shoot_misile_action: String = "shoot_misile"
#var shoot_shocker_action: String = "shoot_shocker"
## tipke, ki jih opredelimo po input akcijah ...
#var default_controller_profiles : Dictionary = {
#	"ARROWS" : {
#		fwd_action: KEY_UP, # inputeventkey
#		rev_action: KEY_DOWN,
#		left_action: KEY_LEFT,
#		right_action: KEY_RIGHT,
#		shoot_bullet_action: KEY_CONTROL,
#		shoot_misile_action: KEY_SHIFT,
#		shoot_shocker_action: KEY_ALT,
##		"is_editable" : false,
#		},
#	"WASD" : {
#		fwd_action: KEY_W,
#		rev_action: KEY_S,
#		left_action: KEY_A,
#		right_action: KEY_D,
#		shoot_bullet_action: KEY_V,
#		shoot_misile_action: KEY_G,
#		shoot_shocker_action: KEY_SPACE,
##		"is_editable" : false,
#	},
#}

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
}
