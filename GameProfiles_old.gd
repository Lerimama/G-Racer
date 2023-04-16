## ------------------------------------------------------------------------------------------------------------------------------
##
##	! autolad filet !
##
## 	KAJ JE ...
##	- v tem filetu so vsi prednastavljeni profili igre ... Lastnosti, ki se tekom igre ne spreminjajo
##	- vse štartne nastavitve za igro ... props: barve, pravila igre, orožja, funkcije opek ...
##	- štart vrednosti vseh elementov v levelih
##	- štart pogoji za igro ... game rules
##	- defolt vsebine menijev
##	- defolt lastnosti rakete (motion, ...)
##
##	KAJ NI ...
##	- tukaj ni profilov igralcev
##	- tukaj ni variabl, ki se se lahko spreminjajo
##
## -----------------------------------------------------------------------------------------------------------------------------


extends Node


## temp_
var odmik_od_roba = 20
var playerstats_w = 500
var playerstats_h = 32
#
#var anchor_L = odmik_od_roba
#var anchor_R = get_viewport().size.x - odmik_od_roba - playerstats_w
#var anchor_U = odmik_od_roba
#var anchor_D = get_viewport().size.y - odmik_od_roba - playerstats_h
#
#var playerstats_positions : Dictionary = {
#	"playerstats_position_1" : Vector2 (anchor_L,anchor_U),
#	"playerstats_position_2" : Vector2 (anchor_R,anchor_U),
#	"playerstats_position_3" : Vector2 (anchor_L,anchor_D),
#	"playerstats_position_4" : Vector2 (anchor_R,anchor_D),
#	}	


#var player_hud_positions : Dictionary = {
#	"position_1" : Vector2(-16, -16),
#	"position_2" : Vector2(688, 668),
#	"position_3" : Vector2(678, -16),
#	"position_4" : Vector2(-16, 744),
#	}


# -------------------------------------------------------------------------------------------------------------
#	GAME VALUES
# -------------------------------------------------------------------------------------------------------------

var default_game_theme : Dictionary = {

	"disabled_player_color" : Color.gray,

	# menus
	"menu_text_color" : Color.white,
	"menu_accent_color" : Color.orange,
	"menu_edit_color" : Color.red, # v rabi v controller meniju
	"menu_colorsq_size" : Vector2(40, 40),
	"menu_colorsq_select_size" : Vector2(24, 24),

	#hud
	"icon_color" : Color.palegoldenrod,
	"label_color" : Color.pink,
	"minus_color" : Color.red,
	"plus_color" : Color.green, # drugačna ker se to zgodi na bonus efekt
	}

var game_rules : Dictionary = {

	# player_default_values diki?

	"score for win" : Color.red,
	"wins for turnament win" : Color.red,
	}

var level_values : Dictionary = { # tale bo na koncu obsoleten, al bo za drzgam?

	# e bonus
	"energy_bonus" : 10,
	"bonus_e_color" : Color.yellow,
	# m bonus
	"misile_bonus" : 1,
	"bonus_m_color" : Color.pink,

	# pointer
	"pointer_score" : 100,
	"pointer_color" : Color.aquamarine,
	"pointer_brake" : 3,
	# exploder
	"exploder_color_1" : Color.purple,
	"exploder_color_2" : Color.pink,
	"exploder_color_3" : Color.white,
	# bonucer
	"bouncer_color" : Color.violet,
	"bouncer_strenght" : 2,
	# magnet
	"magnet_color" : Color.aquamarine, # !!!! float
	"gravity_velocity" : 3.0, 	# hitrost glede na distanco od magneta ...gravitacijski pospešek	!!!! float
	"gravity_force" : 50000.0, 	# sila gravitacije 		!!!!!!!const

	}

var player_motion_values : Dictionary = {
	"accelaration" : 400,
	"max_speed" : 400,
	"rotation_speed" : 5,
	"friction" : 0.02, # def friction
	"bounce_size" : 0.3, # večji ko je, večji je bounce
	}

var weapon_values : Dictionary = {

#	"def_weapon_load_time" : 0,
#	"weapon_load_time" : 100,
	"misile_load_time" : 100,
	"weapon_relaod_time" : 0.2,

	"bullet_speed" : 1000,
	"bullet_pow" : 1,
	"bullet_damage" : 100,
	"bullet_score" : 2,

	"misile_speed" : 400,
	"misile_pow" : 2,
	"misile_damage" : 100,
	"misile_score" : 1,

	"mina_pow" : 10,
	"mina_damage" : 100,
	"mina_score" : 3,
	}

var name_menu_characters : Dictionary = {
	1 : "A",
	2 : "B",
	3 : "C",
	4 : "D",
	5 : "E",
	6 : "F",
	7 : "G",
	8 : "H",
	9 : "I",
	10 : "J",
	11 : "K",
	12 : "L",
	13 : "M",
	14 : "N",
	15 : "O",
	16 : "P",
	17 : "Q",
	18 : "R",
	19 : "S",
	20 : "T",
	21 : "U",
	22 : "V",
	23 : "W",
	24 : "X",
	25 : "Y",
	26 : "Z",
	27 : "_",
	28 : ":",
	29 : "/",
	30 : ".",
	31 : "-",
	32 : " ",
	}

var avatar_menu_selection: Dictionary = {
	1: preload("res://materiali/avatars/avatar1.png"),
	2: preload("res://materiali/avatars/avatar2.png"),
	3: preload("res://materiali/avatars/avatar3.png"),
	4: preload("res://materiali/avatars/avatar4.png"),
	5: preload("res://materiali/avatars/avatar5.png"),
	6: preload("res://materiali/avatars/avatar6.png"),
	7: preload("res://materiali/avatars/avatar7.png"),
	8: preload("res://materiali/avatars/avatar8.png"),
	9: preload("res://materiali/avatars/avatar9.png"),
	10: preload("res://materiali/avatars/avatar10.png"),
	11: preload("res://materiali/avatars/avatar11.png"),
	12: preload("res://materiali/avatars/avatar12.png"),
	13: preload("res://materiali/avatars/avatar13.png"),
	14: preload("res://materiali/avatars/avatar14.png"),
	15: preload("res://materiali/avatars/avatar15.png"),
	16: preload("res://materiali/avatars/avatar16.png"),
	}

var color_menu_selection: Dictionary = {
	1 : Color.skyblue,
	2 : Color.blueviolet,
	3 : Color.tomato,
	4 : Color.turquoise,
	5 : Color.greenyellow,
	6 : Color.bisque,
	7 : Color.goldenrod,
	8 : Color.thistle,
	9 : Color.palegoldenrod,
	10 : Color.fuchsia,
	11 : Color.pink,
	12 : Color.blue,
	13 : Color.red,
	14 : Color.green,
	15 : Color.greenyellow,
	16 : Color.darkkhaki,
	}


# -------------------------------------------------------------------------------------------------------------
#	PLAYER PROFILES ... sestavljeni iz start values in "per player" properties
# -------------------------------------------------------------------------------------------------------------

var default_player_profiles : Dictionary = { # ime profila ime igralca ... pazi da je CAPS, ker v kodi tega ne pedenam
	"ACE" : {
		"player_name" : "ACE",
		# "player_controller" : "Up/Le/Do/Ri/Al",
		"player_avatar" : preload("res://materiali/avatars/avatar1.png"),
		"player_color" : Color.skyblue,
		"player_editable" : false,
		},
	"RIT" : {
		"player_name" : "RIT",
		# "player_controller" : "W/A/S/D/Sp",
		"player_avatar" : preload("res://materiali/avatars/avatar2.png"),
		"player_color" : Color.turquoise,
		"player_editable" : false,
		},
	}

var default_new_player_profile : Dictionary = { # ime profila ime igralca
	"player_name" : "XXX",
	"player_controller" : "vseeno, kaj je, ker ga itak kasneje spremenimo v ime kopije def kontroler profila",
	"player_avatar" : preload("res://materiali/avatars/avatar3.png"),
	"player_color" : Color.tomato,
	"player_editable" : true,
	}

var default_player_game_stats : Dictionary = { # tole ne uporabljam v zadnji varianti

	"player_active" : true,
#	"player_start_position" : Vector2(0, 0),
	# score
	"score" : 0000,
	"bricks" : 0,
	"wins" : 0,
	# health
	"energy" : 5,
	"life" : 3,
	# weapons
	"misile_no" : 5,
	"bullet_no" : 30,
	"mina_no" : 300,
	}


# -------------------------------------------------------------------------------------------------------------
#	CONTROLLER PROFILES
# -------------------------------------------------------------------------------------------------------------


var forward_action_name: String = "gasa" # variable za imena akcij (jih ni potrebno popravljat v kodi za kontrole)
var backward_action_name: String = "bremza"
var left_action_name: String = "levo"
var right_action_name: String = "desno"
var shoot_action_name: String = "strel"

var controller_profiles_editable_key : String = "is_editable" # da ga lahko znotraj kode izločam iz generacije imena
var empty_controller_name : String = "PRAZN" # ime je samo za izpis predno se spremeni ... ni pravo ime kontrole, ker ga ne rabiš, ker se potem zapiše pravo

var empty_controller_profile : Dictionary = {
	forward_action_name : KEY_P,
	left_action_name : KEY_R,
	backward_action_name : KEY_A,
	right_action_name : KEY_Z,
	shoot_action_name : KEY_N,
	"is_editable" : true,
	}

var default_controller_profiles : Dictionary = {
	"UpLeDoRiAl" : {
		forward_action_name: KEY_UP,
		left_action_name: KEY_LEFT,
		backward_action_name: KEY_DOWN,
		right_action_name: KEY_RIGHT,
		shoot_action_name: KEY_ALT,
		"is_editable" : false,
		},
	"WASDSp" : {
		forward_action_name: KEY_W,
		left_action_name: KEY_A,
		backward_action_name: KEY_S,
		right_action_name: KEY_D,
		shoot_action_name: KEY_SPACE,
		"is_editable" : false,
		},
	}
