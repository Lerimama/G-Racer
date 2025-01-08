extends Node

var fade_time = 0.7

onready var home_scene_path: String = "res://home/Home.tscn"
onready var game_scene_path: String = "res://game/Game.tscn"

#func _input(event: InputEvent) -> void:
#
#	if Input.is_action_just_pressed("no1"):
#		var all_nodes = Mets.get_all_nodes_in_node(self)
#
#		for node in all_nodes:
#			if node.name[0] == "_" and node.name[1] == "_":
#				printt("_NODE",node.name)
#
#		print("All nodes in MAIN scene",  all_nodes.size())


func _ready() -> void:

	Refs.main_node = self

#	home_in_intro()
#	home_in_no_intro()
	game_in()


func home_in_intro():

	spawn_new_scene(home_scene_path, self)
	current_scene.open_with_intro()
#	Mets.spawn_new_scene(home_scene_path, self)
#	Mets.current_scene.open_with_intro()

	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time)
	fade_in.tween_property(current_scene, "modulate", Color.white, fade_time)


func home_in_no_intro(): # debug

	get_tree().set_pause(false)

	spawn_new_scene(home_scene_path, self)
#	Mets.spawn_new_scene(home_scene_path, self)
#	Mets.current_scene.open_without_intro()

#	Mets.current_scene.modulate = Color.black
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time)#.from(Color.black)


func home_in_from_game():

	get_tree().set_pause(false)

#	Mets.spawn_new_scene(home_scene_path, self)
#	Mets.current_scene.open_from_game() # select game screen

	spawn_new_scene(home_scene_path, self)
	current_scene.open_from_game() # select game screen

	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima

#	Mets.current_scene.modulate = Color.black
	current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time)
	fade_in.tween_property(current_scene, "modulate", Color.white, fade_time)


func home_out():

	$Sounds/MenuFade.play()

#	if not Refs.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
#		Refs.sound_manager.stop_music("menu_music")

	var fade_out = get_tree().create_tween()
#	fade_out.tween_property(Mets.current_scene, "modulate", Color.black, 1)
	fade_out.tween_callback(self, "release_scene", [current_scene])
#	fade_out.tween_callback(Mets, "release_scene", [Mets.current_scene])
	fade_out.tween_callback(self, "game_in")#.set_delay(1)


func game_in():

#	game_scene_path = Profiles.current_game_data["game_scene_path"]

	get_viewport().set_disable_input(false)
	get_tree().set_pause(false)


#	Sets.get_game_settings(0) # setaš prvi level (ali edini)

#	Sets.get_level_game_settings(0) # setaš prvi level
#	Mets.spawn_new_scene(game_scene_path, self)
	spawn_new_scene(game_scene_path, self)
#	Mets.current_scene.modulate = Color.black
#	Refs.game_manager.call_deferred("set_game")
#	Refs.game_manager.set_game()
#	yield(get_tree().create_timer(1), "timeout") # da se kamera centrira (na restart)
#
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time).from(Color.black)


#	fade_in.tween_callback(Refs.game_manager, "set_game")

#var game_level_index: int = 0
#
#func to_next_level(): # reload game scene z neslednjim levelom
#
#	if game_level_index < Sets.current_game_levels.size() - 1:
#		game_level_index += 1
#		reload_game()
#	else:
#		game_level_index = 0
#		game_over_in()


#	yield(fade_out, "finished")
#	get_tree().set_current_scene(Mets.current_scene)
#	print("CURR", get_tree().current_scene)
#	get_tree().reload_current_scene()

func game_over_in():

#	printt ("GO", Mets.current_scene)
	printt ("GO", current_scene)
	$Sounds/MenuFade.play()

	# game_out
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	yield(fade_out, "finished")
	release_scene(current_scene)

	var path = "res://game/GameEnd.tscn"
	spawn_new_scene(path, self)
	current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(current_scene, "modulate", Color.white, fade_time).from(Color.black)
	printt ("GO poo", current_scene)

#	# game_out
#	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	fade_out.tween_property(Mets.current_scene, "modulate", Color.black, fade_time)
#	yield(fade_out, "finished")
#	Mets.release_scene(Mets.current_scene)
#
#	var path = "res://game/GameEnd.tscn"
#	Mets.spawn_new_scene(path, self)
#	Mets.current_scene.modulate = Color.black
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time).from(Color.black)
#	printt ("GO poo", Mets.current_scene)

#	fade_in.tween_callback(Refs.game_manager, "set_game")
#	Refs.game_manager.game_over(1)

	pass

#func level_in(level_to_load: int):
#func level_in(level_to_load_index: int):
#	Sets.set_game_settings(level_to_load_index)
#	current_level_index = level_to_load_index
#	print ("CL", level_to_load_index)
##	Sets.set_game_settings(current_level) # setaš prvi level
#
#	Mets.spawn_new_scene(game_scene_path, self)
#	Mets.current_scene.modulate = Color.black
#	Refs.game_manager.set_game()
#	yield(get_tree().create_timer(1), "timeout") # da se kamera centrira (na restart)
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Mets.current_scene, "modulate", Color.white, fade_time).from(Color.black)
#
#
#func level_out():
#	pass


func game_out():

#	get_viewport().set_disable_input(true) # anti dablklik

#	Global.player1_camera = null
#	Global.player2_camera = null
#
	$Sounds/MenuFade.play()

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(self, "release_scene", [current_scene])
	fade_out.tween_callback(self, "home_in_no_intro").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu

#	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	fade_out.tween_property(Mets.current_scene, "modulate", Color.black, fade_time)
#	fade_out.tween_callback(Mets, "release_scene", [Mets.current_scene])
#	fade_out.tween_callback(self, "home_in_no_intro").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu


func reload_game(): # game out z drugačnim zaključkom

	get_viewport().set_disable_input(true) # anti dablklik

#	Global.player1_camera = null
#	Global.player2_camera = null

	$Sounds/ScreenSlide.play()

#	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	fade_out.tween_property(Mets.current_scene, "modulate", Color.black, fade_time)
#	fade_out.tween_callback(Mets, "release_scene", [Mets.current_scene])
#	fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(self, "release_scene", [current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu

#	yield(fade_out, "finished")
#	get_tree().set_current_scene(Mets.current_scene)
#	print("CURR", get_tree().current_scene)
#	get_tree().reload_current_scene()



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
