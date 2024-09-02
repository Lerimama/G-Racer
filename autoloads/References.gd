extends Node

# global nodes
var current_level = null  # zaenkrat samo zaradi pozicij ... lahko bi bolje
var node_creation_parent = null # NCP ... ven?
var game_arena = null
var current_camera = null
var game_manager = null
var hud = null
var sound_manager = null
var data_manager = null
var main_node = null
var game_over = null
var level_completed = null

# groups
var group_players = "Players"
var group_ai = "Ais"
var group_bolts = "Bolts"
var group_misiles = "Misiles"
var group_bullets = "Bullets"
var group_mine = "Mine"
var group_pickables = "Pickables"
var group_thebolts = "TheBolts"
#var group_arena =  "Arena"
#var group_tilemap = "Tilemap" # defender in patterns
#var group_menu_confirm_btns = "Menu confirm btns"
#var group_menu_cancel_btns = "Menu cancel btns"


# game colors
var color_gray0 = Color("#535b68") # najsvetlejša
var color_gray1 = Color("#404954")
var color_gray2 = Color("#2f3649")
var color_gray3 = Color("#272d3d")
var color_gray4 = Color("#1d212d")
var color_gray5 = Color("#171a23") # najtemnejša
var color_gray_trans = Color("#00272d3d") # transparentna
var color_red = Color("#f35b7f")
var color_green = Color("#5effa9")
var color_blue = Color("#4b9fff")
var color_yellow = Color("#fef98b")

# --- specs
var color_hud_base = Color("#ffffff")

var color_brick_ghost = Color.goldenrod
var color_brick_magnet_off = Color.crimson
var color_brick_magnet_on = Color.magenta
var color_brick_target = Color.aquamarine
var color_brick_target_hit_1 = Color.red
var color_brick_target_hit_2 = Color.blue
var color_brick_target_hit_3 = Color.yellow
var color_brick_bouncer = Color.purple
var color_brick_light_off = Color.violet
var color_brick_light_on = Color.greenyellow

var color_pickable_random = Color.pink 
var color_pickable_stat = Color.black
var color_pickable_feature = Color.white
var color_pickable_weapon = Color.yellow

# gui colors
var color_almost_white_text: Color = Color("#f5f5f5") # če spremeniš tukaj, moraš tudi v temi
var color_gui_gray: Color = Color("#78ffffff") # siv text s transparenco (ikone ...#838383) ... v kodi samo na btn defocus
var color_hud_text: Color = color_almost_white_text # za vse, ki modulirajo barvo glede na + ali -
#var color_almost_black_pixel: Color = Color("#141414") 
#var color_dark_gray_pixel: Color = Color("#232323")#Color("#323232") # start normal
#var color_white_pixel: Color = Color(1, 1, 1, 1.22)
#var color_thumb_hover: Color = Color("#232323")
#var strays_on_screen: Array = [] # za stray position indikatorje
