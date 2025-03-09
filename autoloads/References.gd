extends Node


func global_nodes(): pass # ------------------------------------------------------------

var main_node: Node = null
var game_reactor: Node = null
var sound_manager: Node = null
var node_creation_parent: Node2D = null # NCP ... ven?
var ultimate_popup: Popup = null

func groups(): pass # ------------------------------------------------------------

var group_agents = "agents"
var group_vehicles = "vehicles"
var group_players = "players"
var group_ai = "ais"
var group_drivers = "drivers"

var group_pickables = "pickables"
var group_shadows = "shadows"
var group_projectiles = "projectiles"
var group_mine = "mine"
var group_male = "male"
var group_player_cameras = "player_cameras"
#var group_misiles = "misiles"
#var group_bullets = "bullets"
#var group_menu_confirm_btns = "Menu confirm btns"
#var group_menu_cancel_btns = "Menu cancel btns"


func colors(): pass # ------------------------------------------------------------

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
var color_brick_ghost = Color.white
var color_brick_magnet_off = Color.white
var color_brick_magnet_on = Color.red
var color_brick_target = Color.white
var color_brick_target_hit_1 = Color.red
var color_brick_target_hit_2 = Color.gray
var color_brick_target_hit_3 = Color.black
var color_brick_bouncer = Color.red
var color_brick_light_off = Color.white
var color_brick_light_on = Color.red
var color_pickable_random = Color.red
var color_pickable_stat = Color.red
var color_pickable_feature = Color.yellow
var color_pickable_ammo = Color.black

# gui colors
var color_almost_white_text: Color = Color("#f5f5f5") # če spremeniš tukaj, moraš tudi v temi
var color_gui_gray: Color = Color("#78ffffff") # siv text s transparenco (ikone ...#838383) ... v kodi samo na btn defocus
var color_hud_text: Color = color_almost_white_text # za vse, ki modulirajo barvo glede na + ali -
#var color_almost_black_pixel: Color = Color("#141414")
#var color_dark_gray_pixel: Color = Color("#232323")#Color("#323232") # start normal
#var color_white_pixel: Color = Color(1, 1, 1, 1.22)
#var color_thumb_hover: Color = Color("#232323")
#var strays_on_screen: Array = [] # za stray position indikatorje
