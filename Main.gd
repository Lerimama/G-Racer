extends Node

var fade_time = 0.7
var current_scene = null

onready var home_scene_path: String = "res://home/Home.tscn"
onready var game_scene_path: String = "res://game/Game.tscn"


#func _input(event: InputEvent) -> void:
#
#	if Input.is_action_just_pressed("no0"):
#		Mets.hide_helper_nodes()


func _ready() -> void:

	Refs.main_node = self

	if OS.is_debug_build():
		Sets.start_debug()
	else:
		_home_in()
	#	_game_in()


# SCENE IN ---------------------------------------------------------------------


func _home_in(): # debug

	get_tree().set_pause(false)
	spawn_new_scene(home_scene_path, self)


func _home_in_from_game():

	get_tree().set_pause(false)

	spawn_new_scene(home_scene_path, self)
	current_scene.open_from_game() # select game screen

	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima

	current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(current_scene, "modulate", Color.white, fade_time)


func _game_in():

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)
	spawn_new_scene(game_scene_path, self)


# SCENE OUT ---------------------------------------------------------------------


func home_out():

	$Sounds/MenuFade.play()

	#	if not Refs.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
	#		Refs.sound_manager.stop_music("menu_music")

	var fade_out = get_tree().create_tween()
	fade_out.tween_callback(self, "release_scene", [current_scene])
	fade_out.tween_callback(self, "_game_in")#.set_delay(1)


func game_out():

	$Sounds/MenuFade.play()

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(self, "release_scene", [current_scene])
	fade_out.tween_callback(self, "_home_in_from_game").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu


func reload_game():
	# game out z drugačnim zaključkom

	get_viewport().set_disable_input(true) # anti dablklik

	$Sounds/ScreenSlide.play()

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(self, "release_scene", [current_scene])
	fade_out.tween_callback(self, "_game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu


# SCENE SPAWN ---------------------------------------------------------------------


func release_scene(scene_node): # release scene
	scene_node.set_physics_process(false)
	call_deferred("_free_scene", scene_node)


func _free_scene(scene_node):
	#	print ("SCENE RELEASED (in next step): ", scene_node)
	scene_node.free()

var is_loading: bool = false
#
#func _process(delta: float) -> void:
#
#	if is_loading:
#		var laoding_status: = ResourceLoader.load_interactive()
func spawn_new_scene(scene_path, parent_node): # spawn scene
	#	print(scene_path, parent_node)
	printt("start_loadding", Time.get_ticks_msec(), scene_path)
	is_loading = true
	var scene_resource = ResourceLoader.load(scene_path)

	current_scene = scene_resource.instance()
	#	print ("SCENE INSTANCED: ", current_scene)

	parent_node.add_child(current_scene) # direct child of root
	print ("SCENE ADDED: ", current_scene)

	printt("scene added", Time.get_ticks_msec())
	is_loading = false
	return current_scene
