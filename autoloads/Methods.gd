extends Node2D

## metode in njihove variable ... bivši global


#func _ready():
#
#	# za menjavo scen
#	var root = get_tree().root
#	current_scene = root.get_child(root.get_child_count() - 1)
#	print ("root: ", root)
#	print ("current_scene: ", current_scene)

#func get_clock_time_old(time_to_split: float): # sekunde
#
#	var minutes: int = floor(time_to_split / 60) # vse cele sekunde delim s 60
#	var seconds: int = floor(time_to_split) - minutes * 60 # vse sekunde minus sekunde v celih minutah
#	var hundreds: int = round((time_to_split - floor(time_to_split)) * 100) # decimalke množim x 100 in zaokrožim na celo
#
#	# return [minutes, seconds, hundreds]	
#	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + ":" + "%02d" % hundreds	
#	return time_on_clock
		
#func get_all_nodes_in_node(node_to_check: Node = get_tree().root, all_nodes_of_nodes: Array = []):
#
#	all_nodes_of_nodes.push_back(node_to_check)
#
#	for node in node_to_check.get_children():
#		all_nodes_of_nodes = get_all_nodes_in_node(node)
#
#	#	print("Nodes in node",  all_nodes_of_nodes.size())
#	return all_nodes_of_nodes	
	
	
func get_clock_time(hundreds_to_split: int): # cele stotinke ali ne cele sekunde
	
	# če so podane stotinke, pretvorim v sekunde z decimalko
	var seconds_to_split: float = hundreds_to_split / 100.0
	
	# če so podane sekunde
	var minutes: int = floor(seconds_to_split / 60) # vse cele sekunde delim s 60
	var seconds: int = floor(seconds_to_split) - minutes * 60 # vse sekunde minus sekunde v celih minutah
	var hundreds: int = round((seconds_to_split - floor(seconds_to_split)) * 100) # decimalke množim x 100 in zaokrožim na celo
	
	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if hundreds == 100:
		seconds += 1
		hundreds = 0	
		
	# return [minutes, seconds, hundreds]	
	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + ":" + "%02d" % hundreds	
	
	return time_on_clock

	
func write_clock_time(hundreds: int, time_label: HBoxContainer): # cele stotinke ali ne cele sekunde
	
	var seconds: float = hundreds / 100.0
	var rounded_minutes: int = floor(seconds / 60) # vse cele sekunde delim s 60
	var rounded_seconds_leftover: int = floor(seconds) - rounded_minutes * 60 # vse sekunde minus sekunde v celih minutah
	var rounded_hundreds_leftover: int = round((seconds - floor(seconds)) * 100) # decimalke množim x 100 in zaokrožim na celo
	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if rounded_hundreds_leftover == 100:
		rounded_seconds_leftover += 1
		rounded_hundreds_leftover = 0	
	
	time_label.get_node("Mins").text = "%02d" % rounded_minutes
	time_label.get_node("Secs").text = "%02d" % rounded_seconds_leftover
	time_label.get_node("Hunds").text = "%02d" % rounded_hundreds_leftover	
	
	
func sound_stop_fade_out(sound, fade_time: float):

	var current_sound_volume = sound.volume_db
	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(sound, "volume_db", -80, fade_time)
	fade_out.tween_callback(sound, "stop")
	yield(fade_out, "finished")
	sound.volume_db = current_sound_volume


func sound_play_fade_in(sound, new_volume: int, fade_time: float):
	
	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_callback(sound, "play")
	fade_out.tween_property(sound, "volume_db", new_volume, fade_time)
	
	
func get_random_member(group_of_elements):
		
		var random_range = group_of_elements.size()
		var selected_int = randi() % int(random_range)
		# printt ("Random:", group_of_elements.size(), selected_int, group_of_elements[selected_int])
		
		return group_of_elements[selected_int]

	
onready var indikator: PackedScene = preload("res://common/DebugIndikator.tscn")

func spawn_indikator(pos, rot): # neki ne štima
	
	var new_indikator = indikator.instance()
	new_indikator.global_position = pos
	new_indikator.global_rotation = rot
#	new_indikator.global_position = bolt_sprite.global_position + pos
#	new_indikator.global_rotation = bolt_sprite.global_rotation
	new_indikator.modulate = Color.red
	new_indikator.z_index = 10
	Ref.node_creation_parent.add_child(new_indikator)
	
	return new_indikator


# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------

var current_scene = null

func release_scene(scene_node): # release scene
	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)	


func _free_scene(scene_node):
	print ("SCENE RELEASED (in next step): ", scene_node)	
	scene_node.free()
	

func spawn_new_scene(scene_path, parent_node): # spawn scene
	print(scene_path, parent_node)
	var scene_resource = ResourceLoader.load(scene_path)
	
	current_scene = scene_resource.instance()
	print ("SCENE INSTANCED: ", current_scene)
	
#	current_scene.modulate.a = 0
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
		Ref.sound_manager.play_gui_sfx("btn_confirm")
	elif button.name == "QuitBtn" or button.name == "CancelBtn":
		Ref.sound_manager.play_gui_sfx("btn_cancel")
	elif button.name == "ContinueBtn":
		button.set_disabled(true) # ne dela
		Ref.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Ref.sound_manager.play_gui_sfx("btn_confirm")

	
func _on_button_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Ref.sound_manager.play_gui_sfx("btn_confirm")
	else:
		Ref.sound_manager.play_gui_sfx("btn_cancel")


func _on_control_hovered(control: Control):
	
	if not control.has_focus():		
		control.grab_focus()
		Ref.sound_manager.play_gui_sfx("btn_focus_change")
		
				
func _on_control_focused(control: Control):
	
	Ref.sound_manager.play_gui_sfx("btn_focus_change")
	# check btn color fix
	if control is CheckButton or control is HSlider:
		control.modulate = Color.white


func _on_control_unfocused(control: Control):
	
	if control is CheckButton or control is HSlider:
		control.modulate = Color.red # color_gui_gray # Color.white


var allow_focus_sfx: bool = false # focus sounds

func grab_focus_no_sfx(control_to_focus: Control):
	
	allow_focus_sfx = false
	control_to_focus.grab_focus()
	allow_focus_sfx = true




	
	
	
	
	
	
	
	
	
	
	
	
	
	
#
#
#func switch_to_scene(path):
#	# This function will usually be called from a signal callback,
#	# or some other function from the running scene.
#	# Deleting the current scene at this point might be
#	# a bad idea, because it may be inside of a callback or function of it.
#	# The worst case will be a crash or unexpected behavior.
#
#	# The way around this is deferring the load to a later time, when
#	# it is ensured that no code from the current scene is running:
#	call_deferred("_deferred_goto_scene", path)
#
#
#func _deferred_goto_scene(path):
#
#	# free current
##	get_tree().get_current_scene().free()
#	print ("deleted_scene: ", current_scene)	
#	current_scene.free()
#
#	# spawn new
##	var packed_scene = ResourceLoader.load(path)
##	var instanced_scene = packed_scene.instance()
##	get_tree().get_root().add_child(instanced_scene) # direct child of root
#	# set as current scene after it is added to tree
##	get_tree().set_current_scene(instanced_scene)
#
#	var new_scene = ResourceLoader.load(path)
#	current_scene = new_scene.instance()
#	get_tree().root.add_child(current_scene) # direct child of root
#
#	# Optionally, to make it compatible with the SceneTree.change_scene() API.
#	get_tree().current_scene = current_scene
#	print ("new_scene: ", current_scene)



#func instance_node (node, location, direction, parent):
## uporaba -> var bullet = instance_node(bullet_instance, global_position, get_parent()) -> bullet.scale = Vector(1,1)
#
#	var node_instance = node.instance()
#	parent.add_child(node_instance) # instance je uvrščen v določenega starša
#	node_instance.global_position = location
#	node_instance.global_rotation = direction # dodal samostojno
#
#	node_instance.set_name(str(node_instance.name))  # dodal samostojno, da nima generičnega imena  z @ znakci
#	print("ustvarjen node: %s" % node_instance.name)
#
##	add_child manjka? ... pomoje ga v funkciji dodaš
#	return node_instance


#func get_random_position():
## uporaba -> object.global_position = Global.get_random_position()
#
#	randomize() # vedno če hočeš randomizirat
#	var random_position = Vector2(rand_range(50, get_viewport_rect().size.x - 100), rand_range(50, get_viewport_rect().size.y - 100))
#	return random_position


#func get_random_rotation():
#
#	randomize() # vedno če hočeš randomizirat
#	var random_rotation = rand_range(-3, 3)
#	return random_rotation


#func get_direction_to (A_position, B_position):
#
#	var x_to_B = B_position.x - A_position.x
#	var y_to_B = B_position.y - A_position.y
#
#	var A_direction_to_B = atan2(y_to_B, x_to_B)
#
#	return A_direction_to_B


#func get_distance_to (A_position, B_position):
#
#	var x_to_B = B_position.x - A_position.x
#	var y_to_B = B_position.y - A_position.y
#
#	var A_distance_to_B = sqrt ((y_to_B * y_to_B) + (x_to_B * x_to_B))
#
#	return A_distance_to_B


## INSTANCE FROM TILEMAPS ---------------------------------------------------------------------------
#
##func create_instance_from_tilemap(coord:Vector2, prefab:PackedScene, parent: Node2D, origin_zamik:Vector2 = Vector2.ZERO):	# primer dobre prakse ... static typing
##	print("COORD")
##	print(coord)
##	$BrickSet.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
##	var pf = prefab.instance()
##	pf.position = $BrickSet.map_to_world(coord) - origin_zamik
##	parent.add_child(pf)
##	print("COORD")
##	print(coord)
