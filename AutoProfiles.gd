extends Node


# -------------------------------------------------------------------------------------------------------------
#	PLAYER PROFILES ... sestavljeni iz start values in "per player" properties
# -------------------------------------------------------------------------------------------------------------


var default_player_profiles: Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
	"P1" : {
		"player_name" : "ACE",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_01.png"),
		"player_color" : Config.color_blue, # color_yellow, color_green, color_red
		"player_editable" : false,
		},
	"P2" : {
		"player_name" : "CUL",
		# "player_controller" : "W/A/S/D/Sp",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_02.png"),
		"player_color" : Config.color_red,
		"player_editable" : false,
		},
	"E1" : {
		"player_name" : "TIR",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_03.png"),
		"player_color" : Color.white,
		"player_editable" : false,
		},
	"E2" : {
		"player_name" : "RIT",
		# "player_controller" : "W/A/S/D/Sp",
		"player_avatar" : preload("res://assets/bolt/avatars/avatar_04.png"),
		"player_color" : Color.white,
		"player_editable" : false,
		},
	}

var bolt_profiles: Dictionary = {
	"bolt"
#		"bolt_sprite":
		"engine_power": 250, #konjev
		"turn_angle": 15,
		"rotation_multiplier": 15,
		"mass": 250, # kg
		"on_hit_disabled_time": 1.5
		"drag": 1.0
		"reload_ability":
#		feature_positions
	
	
	
}
#var default_new_player_profile : Dictionary = { # ime profila ime igralca
#	"player_name" : "XXX",
#	"player_controller" : "vseeno, kaj je, ker ga itak kasneje spremenimo v ime kopije def kontroler profila",
#	"player_avatar" : preload("res://materiali/avatars/avatar3.png"),
#	"player_color" : Color.tomato,
#	"player_editable" : true,
#	}

#var default_player_game_stats : Dictionary = { # tole ne uporabljam v zadnji varianti
#
#	"player_active" : true,
##	"player_start_position" : Vector2(0, 0),
#	# score
#	"score" : 0000,
#	"bricks" : 0,
#	"wins" : 0,
#	# health
#	"health" : 5,
#	"life" : 3,
#	# weapons
#	"misile_no" : 5,
#	"bullet_no" : 30,
#	"mina_no" : 300,
#	}
