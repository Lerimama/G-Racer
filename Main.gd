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
		return

	to_home()


func to_home():

	# release game
	if game_scene:
		get_tree().set_pause(true)
		get_viewport().set_disable_input(true)
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
		home_scene.queue_free()
		yield(home_scene, "tree_exited")
		home_scene = null
		get_tree().set_pause(false)

	# spawn game
	var NewScene = ResourceLoader.load(game_scene_path)
	var new_scene = NewScene.instance()
	add_child(new_scene) # direct child of root
	game_scene = new_scene

	game_scene.call_deferred("set_game", 0)

	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)

	prints ("GAME SCENE ADDED:", game_scene.name)


func reload_to_level(to_level_index: int = 0):

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

	game_scene.call_deferred("set_game", to_level_index)

	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)

	prints ("GAME SCENE ADDED:", game_scene.name)


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

