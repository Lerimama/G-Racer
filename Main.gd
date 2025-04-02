extends Node

var fade_time = 0.7
#var current_scene = null


var home_scene: Node2D = null
var game_scene: Node2D = null

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
		to_home()
	#	to_game()



func to_home():

	# release game
	if game_scene:
		get_tree().set_pause(true)
		get_viewport().set_disable_input(true)
		game_scene.set_physics_process(false)
		game_scene.queue_free()
		yield(game_scene, "tree_exited")
		game_scene = null

	# spawn home
	var NewScene = ResourceLoader.load(home_scene_path)
	var new_scene = NewScene.instance()
	add_child(new_scene) # direct child of root
	home_scene = new_scene

	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)

	print ("HOME SCENE ADDED: ", home_scene.name)


func to_game():

	# release home
	if home_scene:
		get_tree().set_pause(true)
		get_viewport().set_disable_input(true)
		home_scene.set_physics_process(false)
		call_deferred("free", home_scene)
		yield(home_scene, "tree_exited")
		home_scene = null

	# spawn game
	var NewScene = ResourceLoader.load(game_scene_path)
	var new_scene = NewScene.instance()
	new_scene.level_index = 2
	add_child(new_scene) # direct child of root
	game_scene = new_scene

	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)

	prints ("GAME SCENE ADDED:", game_scene.name)


func reload_game():

	# release ... current game
	get_tree().set_pause(true)
	get_viewport().set_disable_input(true)
	game_scene.set_physics_process(false)
	game_scene.queue_free()
	yield(game_scene, "tree_exited")

	# spawn game
	var NewScene = ResourceLoader.load(game_scene_path)
	var new_scene = NewScene.instance()
	add_child(new_scene) # direct child of root
	game_scene = new_scene

	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)

	prints ("GAME SCENE ADDED:", game_scene.name)


#func _home_in_from_game():
#
#	get_tree().set_pause(false)
#
##	spawn_new_scene(home_scene_path, self)
#	spawn_home()
#
#	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima
#
#	current_scene.modulate = Color.black
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(current_scene, "modulate", Color.white, fade_time)





# SPAWN ---------------------------------------------------------------------


func spawn_game(): # spawn scene

	var NewScene = ResourceLoader.load(game_scene_path)
	var new_scene = NewScene.instance()
	add_child(new_scene) # direct child of root
	game_scene = new_scene

	prints ("GAME SCENE ADDED:", game_scene.name)


func spawn_home(): # spawn scene

	var NewScene = ResourceLoader.load(home_scene_path)
	var new_scene = NewScene.instance()
	add_child(new_scene) # direct child of root
	home_scene = new_scene

	print ("HOME SCENE ADDED: ", home_scene.name)

