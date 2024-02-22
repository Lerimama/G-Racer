extends Node2D
# references

## konstantne variable in metode

# --------------------------------------------------------------------------------------------------------------
# VARIABLE -----------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------


var main_node = null
var node_creation_parent = null # arena

# managers
var sound_manager = null
var data_manager = null
var game_manager = null # tudi za intro

# gui
var current_tilemap = null
var hud = null
var start_countdown = null
var gameover_menu = null
var tutorial_gui = null

# camera
var intro_camera = null
var player1_camera = null
var player2_camera = null

var strays_on_screen: Array = []

# groups
var group_players = "Players"
var group_strays = "Strays"
var group_tilemap = "Tilemap"
var group_player_cameras = "Player Cameras"
var group_ghosts = "Ghosts"

# colors
var color_blue: Color = Color("#4b9fff")
var color_green: Color = Color("#5effa9")
var color_red: Color = Color("#f35b7f")
var color_yellow: Color = Color("#fef98b")

var color_white: Color = Color("#ffffff")
var hud_text_color: Color = Color("#fafafa")

# reference ... ni nujno, da so v kodi
var color_almost_black: Color = Color("#141414") # start player, wall, floor
var color_gray_dark: Color = Color("#232323") # tudi color_floor_scroller
var color_gui_gray: Color = Color("#838383") # siva v tekstih (naslovi) in ikonah
#var color_gui_btn: Color = Color("#82ffffff") # siva gumbih je transparentna bela ... imitacija #838383
#var color_gui_btn: Color = Color("#838383") # siva gumbih je transparentna bela ... imitacija #838383
var color_hud_background: Color = Color("#141414")
var color_wall_gray: Color = Color("#141414")


# --------------------------------------------------------------------------------------------------------------
# FUNKCIJE -----------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------


var current_scene = null # za scene switching
var allow_focus_sfx: bool = false # focus sounds


func _ready(): 
	
	# when _ready is called, there might already be nodes in the tree, so connect all existing buttons
	connect_buttons(get_tree().root)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	


func snap_to_nearest_grid(current_global_position: Vector2):
	
	if not is_instance_valid(current_tilemap):
		print("ERROR! Snapanje na grid ... manjka Global.current_tilemap")
		
	var floor_cells: Array = current_tilemap.floor_global_positions
	var cell_size_x: float = current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
	
	# adaptacija zaradi središčne točke strejsa in playerja
	var current_position: Vector2 = Vector2(current_global_position.x - cell_size_x/2, current_global_position.y - cell_size_x/2)
	
	# če ni že snepano
	if not floor_cells.has(current_position): 
		# določimo distanco znotraj katere preverjamo bližino točke
		var distance_to_position: float = cell_size_x # začetna distanca je velikosti celice ... potem izbrana je itak bližja
		var nearest_cell: Vector2
		for cell in floor_cells:
			if cell.distance_to(current_position) < distance_to_position:
				distance_to_position = cell.distance_to(current_position)
				nearest_cell = cell
		# snap position
		var snap_to_position: Vector2 = Vector2(nearest_cell.x + cell_size_x/2, nearest_cell.y + cell_size_x/2)
		return snap_to_position
	else: 
		return current_global_position # vrneš isto pozicijo na katere že je 


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------


func release_scene(scene_node): # release scene
	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)	


func _free_scene(scene_node):
	print ("SCENE RELEASED (in next step): ", scene_node)	
	scene_node.free()
	

func spawn_new_scene(scene_path, parent_node): # spawn scene

	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	print ("SCENE INSTANCED: ", current_scene)
	
	current_scene.modulate.a = 0
	parent_node.add_child(current_scene) # direct child of root
	print ("SCENE ADDED: ", current_scene)	
	
	return current_scene


# BUTTONS --------------------------------------------------------------------------------------------------

# vsak hover, postane focus
# dodam sounde na focus
# dodam sounde na confirm, cancel, quit
# dodam modulate na Checkbutton focus


func _on_SceneTree_node_added(node: Control):
	
	if node is BaseButton or node is HSlider:
		connect_to_button(node)


func connect_buttons(root: Node): # recursively connect all buttons
	
	for child in root.get_children():
		if child is BaseButton or child is HSlider:
			connect_to_button(child)
		connect_buttons(child)


func connect_to_button(button):
	
	# pressing btnz
	if button is CheckButton:
		button.connect("toggled", self, "_on_button_toggled")
#	else:# not HSlider:
	elif not button is HSlider:
		button.connect("pressed", self, "_on_button_pressed", [button])
	
	# hover and focus
	button.connect("mouse_entered", self, "_on_control_hovered", [button])
	button.connect("focus_entered", self, "_on_control_focused", [button])
	button.connect("focus_exited", self, "_on_control_unfocused", [button])


func _on_button_pressed(button: BaseButton):
	print("PRESSED ", button)
	if button.name == "BackBtn":
		Global.sound_manager.play_gui_sfx("btn_confirm")
	elif button.name == "QuitBtn" or button.name == "CancelBtn":
		Global.sound_manager.play_gui_sfx("btn_cancel")
	else:
		Global.sound_manager.play_gui_sfx("btn_confirm")

	
func _on_button_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Global.sound_manager.play_gui_sfx("btn_cancel")


func _on_control_hovered(control: Control):
	
	if not control.has_focus():		
		control.grab_focus()
		Global.sound_manager.play_gui_sfx("btn_focus_change")
		
				
func _on_control_focused(control: Control):
	
	Global.sound_manager.play_gui_sfx("btn_focus_change")
	# check btn color fix
	if control is CheckButton or control is HSlider:
		control.modulate = Color.white


func _on_control_unfocused(control: Control):
	
	if control is CheckButton or control is HSlider:
		control.modulate = color_gui_gray # Color.white


func grab_focus_no_sfx(control_to_focus: Control):
	
	allow_focus_sfx = false
	control_to_focus.grab_focus()
	allow_focus_sfx = true
