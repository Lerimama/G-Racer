extends Node2D

## metode in njihove variable ... bivši global



var _helper_nodes: Array = []
var helper_nodes_prefix: String = "__"
#	randomize() # custom color scheme


func hide_helper_nodes(delete_it: bool = false):

	get_all_nodes_in_node(helper_nodes_prefix)
	for node in _helper_nodes:
		print("__helper nodes: ", node)
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



func get_hunds_from_clock(clock_string: String):

	var clock_format: String = "00:00.00"

	var mins: int = int(clock_string.get_slice(":", 0))
	var secs_and_hunds: String = clock_string.get_slice(":", 1)
	var secs: int = int(clock_string.get_slice(".", 0))
	var hunds: int = int(clock_string.get_slice(".", 1))

	return (mins * 60 * 100) + (secs * 100) + hunds


func generate_random_string(random_string_length: int):

#	var available_characters: Array = [a, ]
	var available_characters: String = "ABCDEFGHIJKLMNURSTUVZYXWQ0123456789"
	var random_string: String = ""
	for character in random_string_length:
		var random_index: int = randi() % available_characters.length()
		random_string += available_characters[random_index]

	#	print ("Random string ", random_string)

	return random_string



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


func get_all_named_collision_layers(in_range: int = 21):

	var layer_names_by_index = {}

	for i in range(1, in_range):
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i))
		if layer_name:
			layer_names_by_index[i] = layer_name
#			print("Layer " + str(i) + ": " + layer_name)

	return layer_names_by_index


func get_absolute_z_index(target: Node2D) -> int:

	var node = target
	var z_index = 0
	while node and node is Node2D:
		z_index += node.z_index
		if not node.z_as_relative:
			break
		node = node.get_parent()

	return z_index

func remove_chidren_and_get_template(node_with_children: Array):

	# grab template
#	var template = node_with_children.get_child(0).duplicate()
	var template = node_with_children[0].duplicate()

	# reset children
	for child in node_with_children:
		child.queue_free()

	return template


signal fade_out_finished
func sound_fade_out_and_reset(sound: AudioStreamPlayer, fade_time: float):
	print("sound_fade_out_and_reset je off")
	return
	var pre_sound_volume = sound.volume_db

	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(sound, "volume_db", -80, fade_time)
	fade_out.tween_callback(sound, "stop")
	yield(fade_out, "finished")


	sound.volume_db = pre_sound_volume
	emit_signal("fade_out_finished")



func sound_play_fade_in(sound, new_volume: int, fade_time: float):

	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_callback(sound, "play")
	fade_out.tween_property(sound, "volume_db", new_volume, fade_time)


func get_random_member(group_of_members):

		var random_range = group_of_members.size()
		var selected_int = randi() % int(random_range)

		return group_of_members[selected_int]


func get_random_name(string_length: int):

	randomize()

	var woves: String = "aeiouy"
	var silables: String = "bcdfghjklmnpqrstvwxz"
	var random_generated_name: String = ""
	var random_start_index: int = randi() % 2
	for i in string_length:
		var letters: String
		if i % 2 == 0:
			if random_start_index == 0:
				letters = woves
			else:
				letters = silables

		else:
			if random_start_index == 0:
				letters = silables
			else:
				letters = woves
		var random_letter: String = letters[randi() % letters.length()]
		random_generated_name += random_letter

	random_generated_name = random_generated_name.capitalize()

	return random_generated_name


onready var indikator: PackedScene = preload("res://common/debug/DebugIndikator.tscn")
var all_indikators_spawned: Array = []

func spawn_indikator(pos: Vector2, col: Color = Color.red, rot: float = 0, parent_node = get_tree().root, clear_spawned_before: bool = false, scale_by: float = 10):

	if clear_spawned_before:
		for indi in all_indikators_spawned:
			indi.queue_free()
		all_indikators_spawned.clear()

	var new_indikator = indikator.instance()
	new_indikator.global_position = pos
	new_indikator.global_rotation = rot
	new_indikator.modulate = col
	new_indikator.z_index = 1000
	parent_node.call_deferred("add_child", new_indikator)
#	parent_node.add_child(new_indikator)

	new_indikator.scale *= scale_by
#	all_indikators_spawned.append(new_indikator)

	return new_indikator


func spawn_polygon_2d(poylgon_points: PoolVector2Array, spawn_parent = get_tree().root, col: Color = Color.blue):

	var new_polygon_shape: Polygon2D = Polygon2D.new()
	new_polygon_shape.polygon = poylgon_points
	new_polygon_shape.color = col
	spawn_parent.add_child(new_polygon_shape)

	return new_polygon_shape


func spawn_line_2d(first_point: Vector2, second_point: Vector2, spawn_parent = get_tree().root, col: Color = Color.blue, line_width: float = 10):

	var new_indikator_line = Line2D.new()
	new_indikator_line.points =[first_point, second_point]
	new_indikator_line.default_color = col
	new_indikator_line.width = line_width
	spawn_parent.call_deferred("add_child", new_indikator_line)

#	spawn_parent.add_child(new_indikator_line)

	return new_indikator_line

var all_indikator_lines_spawned: Array = []
func spawn_indikator_line(first_point: Vector2, second_point: Vector2, col: Color = Color.blue, parent_node = get_tree().root, clear_spawned_before: bool = false):

	if clear_spawned_before:
		for line in all_indikator_lines_spawned:
			line.queue_free()
		all_indikator_lines_spawned.clear()

	var new_indikator_line = Line2D.new()
	new_indikator_line.points =[first_point, second_point]
	new_indikator_line.z_index = 100
	new_indikator_line.default_color = col
	parent_node.add_child(new_indikator_line)

	new_indikator_line.width = 10
	all_indikator_lines_spawned.append(new_indikator_line)

	return new_indikator_line



func get_raycast_collision_to_position(raycast_node: RayCast2D, check_position: Vector2):

		var distance_to_position: float = (check_position - raycast_node.global_position).length()
		raycast_node.look_at(check_position)
		raycast_node.cast_to.x = distance_to_position
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()



func get_raycast_collision_on_rotation(raycast_node: RayCast2D, ray_direction: Vector2, raycast_length: float = 450):

	if raycast_length == 0:
		return
	else:
		raycast_node.cast_to = ray_direction * raycast_length
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()


#rotation ver
#func detect_and_update_raycast_on_rotation(raycast_node: RayCast2D, ray_rotation: float, raycast_length: float = 450):
#	print(raycast_node.name, " rotation = ", ray_rotation)


#	var cast_to_vector: Vector2 = Vector2.ZERO
#		#	if ray_rotation is Vector2:
#		#		cast_to_vector = ray_rotation.normalized()
#		#		var rotation_as_vector: Vector2 = ray_rotation
#		#		ray_rotation = raycast_node.get_angle_to(rotation_as_vector)
#		#	else:
#	var rotated_vector: Vector2 = raycast_node.global_position.rotated(ray_rotation)
#	raycast_length = rotated_vector.length()
#	cast_to_vector = rotated_vector.normalized()


func detect_collision_in_direction(direction_to_check: Vector2, raycast_node: RayCast2D, raycast_length: float = 45):
	# PA ver
	if direction_to_check == Vector2.ZERO:
		raycast_node.cast_to = Vector2.ZERO
		return
	else:
		raycast_node.cast_to = raycast_length * direction_to_check
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()





func check_object_for_deletion(object_to_check: Node): # za tole pomoje obstaja biltin funkcija

	if str(object_to_check) == "[Deleted Object]": # anti home_out nek toggle btn
		print ("Object in deletion: ", object_to_check, " > [Deleted Object]")
		return true
	else:
		printt ("Object OK ... not in deletion: ", object_to_check)
		return false




# SCENE MANAGER (prehajanje med igro in menijem) --------------------------------------------------------------

#var current_scene = null
#
#func release_scene(scene_node): # release scene
#	scene_node.set_physics_process(false)
#	call_deferred("_free_scene", scene_node)
#
#
#func _free_scene(scene_node):
#	print ("SCENE RELEASED (in next step): ", scene_node)
#	scene_node.free()
#
#
#func spawn_new_scene(scene_path, parent_node): # spawn scene
#	print(scene_path, parent_node)
#	var scene_resource = ResourceLoader.load(scene_path)
#
#	current_scene = scene_resource.instance()
#	print ("SCENE INSTANCED: ", current_scene)
#
##	current_scene.modulate.a = 0
#	parent_node.add_child(current_scene) # direct child of root
#	print ("SCENE ADDED: ", current_scene)
#
#	return current_scene


# COLORS ------------------------------------------------------------------------------------------------


#var spectrum_rect: TextureRect
#var game_color_theme_gradient: Gradient
#onready var gradient_texture: Resource = load("res://assets/gradient/color_theme_gradient.tres")
#onready var spectrum_texture_scene: PackedScene = load("res://assets/gradient/color_theme_spectrum.tscn")
#
#
#func get_random_gradient_colors(color_count: int):
#
#	var setting_game_color_theme: bool = false
#
#	# za barvno shemo igre ... pomeni, da se kliče iz settingsov
#	if color_count == 0:
#		setting_game_color_theme = true
#		color_count = 320
#
#	# grebam texturo spectruma
#	spectrum_rect = spectrum_texture_scene.instance()
#	var spectrum_texture: Texture = spectrum_rect.texture
#	var spectrum_image: Image = spectrum_texture.get_data()
#	spectrum_image.lock()
#
#	var spectrum_texture_width: float = spectrum_rect.rect_size.x
#	var new_color_scheme_split_size: float = spectrum_texture_width / color_count
#
#	# PRVA barva
#	var random_split_index_1: int = randi() % int(color_count)
#	var random_color_position_x_1: float = random_split_index_1 * new_color_scheme_split_size # lokacija barve v spektrumu
#	var random_color_1: Color = spectrum_image.get_pixel(random_color_position_x_1, 0) # barva na lokaciji v spektrumu
#
#	# DRUGA barva
#	var random_split_index_2: int = randi() % int(color_count)
#	var random_color_position_x_2: float = random_split_index_2 * new_color_scheme_split_size # lokacija barve v spektrumu
#	var random_color_2: Color = spectrum_image.get_pixel(random_color_position_x_2, 0) # barva na lokaciji v spektrumu
#
#	# TRETJA barva
#	var random_split_index_3: int = randi() % int(color_count)
#	var random_color_position_x_3: float = random_split_index_3 * new_color_scheme_split_size # lokacija barve v spektrumu
#	var random_color_3: Color = spectrum_image.get_pixel(random_color_position_x_3, 0) # barva na lokaciji v spektrumu
#
#	# GRADIENT
#
#	# za barvno shemo igre
#	if setting_game_color_theme:
#
#		# setam gradient barvne sheme (node)
#		game_color_theme_gradient = gradient_texture.get_gradient()
#		game_color_theme_gradient.set_color(0, random_color_1)
#		game_color_theme_gradient.set_color(1, random_color_2)
#		game_color_theme_gradient.set_color(2, random_color_3)
#
#		return	game_color_theme_gradient # settingsi rabijo barvno temo
#
#	# za barvno shemo levela
#	else: # ostali rabijo barve
#
#		# setam gradient barvne sheme (node)
#		var level_scheme_gradient: Gradient = gradient_texture.get_gradient()
#		level_scheme_gradient.set_color(0, random_color_1)
#		level_scheme_gradient.set_color(1, random_color_2)
#		level_scheme_gradient.set_color(2, random_color_3)
#
#		# naberem barve glede na število potrebnih barv
#		var split_colors: Array
#		var color_split_offset: float = 1.0 / color_count
#		for n in color_count:
#			var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
#			var color = level_scheme_gradient.interpolate(color_position_x) # barva na lokaciji v spektrumu
#			split_colors.append(color)
#
#		return	split_colors # level rabi že izbrane barve
#
#
#func get_spectrum_colors(color_count: int):
#	randomize()
#
#	# grabam texturo spectruma
#	if not spectrum_rect:
#		spectrum_rect = spectrum_texture_scene.instance()
#	var spectrum_texture: Texture = spectrum_rect.texture
#	var spectrum_image: Image = spectrum_texture.get_data()
#	spectrum_image.lock()
#
#	# izžrebam barvi gradienta iz nastavljenega spektruma
#	var spectrum_texture_width: float = spectrum_rect.rect_size.x
#	var new_color_scheme_split_size: float = spectrum_texture_width / color_count
#
#	# naberem barve glede na število potrebnih barv
#	var split_colors: Array
#	var color_split_offset: float = spectrum_texture_width / color_count
#	for n in color_count:
#		var color_position_x: float = n * color_split_offset # lokacija barve v spektrumu
#		var color = spectrum_image.get_pixel(color_position_x, 0) # barva na lokaciji v spektrumu
#		split_colors.append(color)
#
#	return split_colors



# SCENE --------------------------------------






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
