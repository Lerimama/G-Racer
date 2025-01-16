extends Node2D


var get_it_time: float = 1 # tajming za dojet določene faze igre
var throttler_msec_threshold: int = 5 # koliko msec je še na voljo v frejmu, ko raje premaknem na naslednji frame
var allow_ui_sfx: bool = false
var strays_on_screen: Array = [] # za stray position indikatorje


# node ref
var enviroment_node = null # za setat (brajtnes)
var main_node = null
var game_arena = null # arena
# managers
var sound_manager = null
var data_manager = null
var game_manager = null # tudi za intro
var anal_manager = null
# gui
var current_tilemap = null
var hud = null
var start_countdown = null
var gameover_gui = null
var tutorial_gui = null
# camera
var intro_camera = null
var game_camera = null

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap" # defender in patterns
var group_ghosts = "Ghosts"
var group_critical_btns = "Menu confirm btns" # scene changing > turn off > turnes on on scene reload
var group_menu_cancel_btns = "Menu cancel btns"

# colors
var current_color_pool: Array  # ni še v uporabi
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")
var color_orange: Color = Color("#ff9990")
var color_purple: Color = Color("#c774f5")

# gui colors
var color_almost_white_text: Color = Color("#f5f5f5") # če spremeniš tukaj, moraš tudi v temi
#var color_gui_gray_trans: Color = Color(255, 255, 255, 131) # 83ffffff siv text s transparenco (ikone ...#838383) ... v kodi samo na btn defocus
var color_gui_gray_trans: Color = Color("#8dffffff") # skor pol-črna a=140
#var color_gui_gray_trans: Color = Color("#838383") # skor pol-črna
var color_gui_gray: Color = Color("#838383") # skor pol-črna a=131
var color_hud_text: Color = color_almost_white_text # za vse, ki modulirajo barvo glede na + ali -
var color_btn_disabled: Color = Color("#32ffffff")
var color_btn_enabled: Color = Color("#838383")
var color_btn_hover: Color = Color("#f0f0f0")
var color_btn_focus: Color = Color("#ffffff")
var color_thumb_hover: Color = Color("#232323")


# pixel colors
var color_almost_black: Color = Color("#141414")
var color_dark_gray_pixel: Color = Color("#232323")
var color_hunting: Color = Color("#f35b7f") # color_red
var color_holding: Color = Color(color_hunting, 1.3) # color_red bloom
var color_white_pixel_bloom: Color = Color(1, 1, 1, 1.22)

# tilemap colors
var color_wall: Color = Color("#141414") # Color("#232323")
var color_edge: Color = Color.black
var color_floor: Color = Color("#15ffffff")

# hs / lootlocker
var default_highscore_line_name: String = "Empty score line" # se uporabi, če še ni nobenega v filetu



#func _unhandled_input(event: InputEvent) -> void:
#
#	if Input.is_action_just_pressed("next"):
#		generate_random_string(10)

#		delete_all_debug_nodes()


func _ready():

	randomize() # custom color scheme


var _helper_nodes: Array = []
var helper_nodes_prefix: String = "__"


func hide_helper_nodes(delete_it: bool = false):

	get_all_nodes_in_node(helper_nodes_prefix)
	for node in _helper_nodes:
		if "visible" in node:
				node.hide()


func get_all_nodes_in_node(string_to_search: String = "", node_to_check: Node = get_tree().root, all_nodes_of_nodes: Array = []):

	all_nodes_of_nodes.push_back(node_to_check)
	for node in node_to_check.get_children():
		if not string_to_search.empty() and node.name.begins_with(string_to_search):
			#			printt("node", node.name, node.get_parent())
			if node.name.begins_with(helper_nodes_prefix):
				_helper_nodes.append(node)
		all_nodes_of_nodes = get_all_nodes_in_node(string_to_search, node)

	return all_nodes_of_nodes


func detect_collision_in_direction(direction_to_check: Vector2, raycast_node: RayCast2D, raycast_length: float = 45):

	if direction_to_check == Vector2.ZERO:
		raycast_node.cast_to = Vector2.ZERO

		return
	else:
		raycast_node.cast_to = raycast_length * direction_to_check
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()


func snap_to_nearest_grid(global_position_to_snap: Vector2):

	var floor_cells: Array = current_tilemap.all_floor_tiles_global_positions
	var cell_size_x: float = current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa

	# adaptacija s pixla na grid
	var current_position_on_grid: Vector2 = Vector2(global_position_to_snap.x - cell_size_x/2, global_position_to_snap.y - cell_size_x/2)
	# snepana grid pozicija
	var snapped_grid_position = current_position_on_grid.snapped(Vector2.ONE * cell_size_x)
	# adaptacija z grida na pixel
	var snapped_pixel_global_position: Vector2 = Vector2(snapped_grid_position.x + cell_size_x/2, snapped_grid_position.y + cell_size_x/2)

	return snapped_pixel_global_position


func get_level_out_of_path(tilemap_path: String):
	# neki_neki_XX.tscn

	var tilemap_name: String = tilemap_path.get_slice(".", 0) # odstranim .tscn
	var btn_level_name: String = tilemap_name.get_slice("_", 2).to_upper()

	return btn_level_name


func get_hunds_from_clock(clock_string: String):

	var clock_format: String = "00:00.00"

	var mins: int = int(clock_string.get_slice(":", 0))
	var secs_and_hunds: String = clock_string.get_slice(":", 1)
	var secs: int = int(clock_string.get_slice(".", 0))
	var hunds: int = int(clock_string.get_slice(".", 1))

	return (mins * 60 * 100) + (secs * 100) + hunds


func get_clock_time(hundreds_to_split: float): # cele stotinke ali ne cele sekunde

	# če so podane stotinke, pretvorim v sekunde z decimalko
	var seconds_to_split: float = hundreds_to_split / 100

	# če so podane sekunde
	var minutes: int = floor(seconds_to_split / 60) # vse cele sekunde delim s 60
	var seconds: int = floor(seconds_to_split) - minutes * 60 # vse sekunde minus sekunde v celih minutah
	var hundreds: int = round((seconds_to_split - floor(seconds_to_split)) * 100) # decimalke množim x 100 in zaokrožim na celo

	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if hundreds == 100:
		seconds += 1
		hundreds = 0

	# return [minutes, seconds, hundreds]
	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + "." + "%02d" % hundreds

	return time_on_clock


func generate_random_string(random_string_length: int):

#	var available_characters: Array = [a, ]
	var available_characters: String = "ABCDEFGHIJKLMNURSTUVZYXWQ0123456789"
	var random_string: String = ""
	for character in random_string_length:
		var random_index: int = randi() % available_characters.length()
		random_string += available_characters[random_index]

	#	print ("Random string ", random_string)

	return random_string



# COLORS ------------------------------------------------------------------------------------------------


var spectrum_rect: TextureRect
var game_color_theme_gradient: Gradient
onready var gradient_texture: Resource = preload("res://assets/theme/color_theme_gradient.tres")
onready	var spectrum_texture_scene: PackedScene = preload("res://assets/theme/color_theme_spectrum.tscn")


func get_random_gradient_colors(color_count: int):

	var setting_game_color_theme: bool = false

	# za barvno shemo igre ... pomeni, da se kliče iz settingsov
	if color_count == 0:
		setting_game_color_theme = true
		color_count = 320

	# grebam texturo spectruma
	spectrum_rect = spectrum_texture_scene.instance()
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()

	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	var new_color_scheme_split_size: float = spectrum_texture_width / color_count

	# PRVA barva
	var random_split_index_1: int = randi() % int(color_count)
	var random_color_position_x_1: float = random_split_index_1 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_1: Color = spectrum_image.get_pixel(random_color_position_x_1, 0) # barva na lokaciji v spektrumu

	# DRUGA barva
	var random_split_index_2: int = randi() % int(color_count)
	var random_color_position_x_2: float = random_split_index_2 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_2: Color = spectrum_image.get_pixel(random_color_position_x_2, 0) # barva na lokaciji v spektrumu

	# TRETJA barva
	var random_split_index_3: int = randi() % int(color_count)
	var random_color_position_x_3: float = random_split_index_3 * new_color_scheme_split_size # lokacija barve v spektrumu
	var random_color_3: Color = spectrum_image.get_pixel(random_color_position_x_3, 0) # barva na lokaciji v spektrumu

	# GRADIENT

	# za barvno shemo igre
	if setting_game_color_theme:

		# setam gradient barvne sheme (node)
		game_color_theme_gradient = gradient_texture.get_gradient()
		game_color_theme_gradient.set_color(0, random_color_1)
		game_color_theme_gradient.set_color(1, random_color_2)
		game_color_theme_gradient.set_color(2, random_color_3)

		return	game_color_theme_gradient # settingsi rabijo barvno temo

	# za barvno shemo levela
	else: # ostali rabijo barve

		# setam gradient barvne sheme (node)
		var level_scheme_gradient: Gradient = gradient_texture.get_gradient()
		level_scheme_gradient.set_color(0, random_color_1)
		level_scheme_gradient.set_color(1, random_color_2)
		level_scheme_gradient.set_color(2, random_color_3)

		# naberem barve glede na število potrebnih barv
		var split_colors: Array
		var color_split_offset: float = 1.0 / color_count
		for n in color_count:
			var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
			var color = level_scheme_gradient.interpolate(color_position_x) # barva na lokaciji v spektrumu
			split_colors.append(color)

		return	split_colors # level rabi že izbrane barve


func get_spectrum_colors(color_count: int):
	randomize()

	# grabam texturo spectruma
	if not spectrum_rect:
		spectrum_rect = spectrum_texture_scene.instance()
	var spectrum_texture: Texture = spectrum_rect.texture
	var spectrum_image: Image = spectrum_texture.get_data()
	spectrum_image.lock()

	# izžrebam barvi gradienta iz nastavljenega spektruma
	var spectrum_texture_width: float = spectrum_rect.rect_size.x
	var new_color_scheme_split_size: float = spectrum_texture_width / color_count

	# naberem barve glede na število potrebnih barv
	var split_colors: Array
	var color_split_offset: float = spectrum_texture_width / color_count
	for n in color_count:
		var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
		var color = spectrum_image.get_pixel(color_position_x, 0) # barva na lokaciji v spektrumu
		split_colors.append(color)

	return	split_colors


# BUTTONS --------------------------------------------------------------------------------------------------



func object_not_in_deletion(object_to_check: Node): # za tole pomoje obstaja biltin funkcija

	if str(object_to_check) == "[Deleted Object]": # anti home_out nek toggle btn
		print ("Object in deletion: ", object_to_check, " > [Deleted Object]")
		return true
	else:
		printt ("Object OK ... not in deletion: ", object_to_check)
		return false
