## --- stara verzija ---------------------------------------------------------------------------------------------------------------------------
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


var bolt_explosion_shake
var bullet_hit_shake
var misile_hit_shake


# game groups
var group_players =  "Players"
var group_enemies =  "Enemies"
var group_bolts =  "Bolts"
var group_misiles =  "Misiles"
var group_bullets =  "Bullets"
var group_shockers =  "Shockers"
var group_arena =  "Arena"
var group_pickups =  "Pickups"


var player_name: String = "P1"

# game colors
var color_gray0 = Color("#535b68") # najsvetlejša
var color_gray1 = Color("#404954")
var color_gray2 = Color("#2f3649")
var color_gray3 = Color("#272d3d")
var color_gray4 = Color("#1d212d")
var color_gray5 = Color("#171a23") # najtemnejša
var color_gray_trans = Color("#272d3d00") # transparentna
var color_red = Color("#f35b7f")
var color_green = Color("#5effa9")
var color_blue = Color("#4b9fff")
var color_yellow = Color("#fef98b")


## temp_
var odmik_od_roba = 20
var playerstats_w = 500
var playerstats_h = 32






#
#var anchor_L = odmik_od_roba
#var anchor_R = get_viewport_rect().size.x - odmik_od_roba - playerstats_w
#var anchor_U = odmik_od_roba
#var anchor_D = get_viewport_rect().size.y - odmik_od_roba - playerstats_h
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
	"pointer_points" : 100,
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

