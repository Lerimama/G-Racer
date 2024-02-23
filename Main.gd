extends Node

var fade_time = 0.7
var camera_shake_on: bool =  true #_temp


onready var home_scene_path: String = "res://home/Home_fast.tscn"
onready var game_scene_path: String = "res://game/Game.tscn"
#onready var game_scene_path: String = Profiles.current_game_data["game_scene_path"]

func _ready() -> void:
	
	Ref.main_node = self
	
#	home_in_intro()
#	home_in_no_intro()
	game_in()

	
func home_in_intro():
	
	Met.spawn_new_scene(home_scene_path, self)
	Met.current_scene.open_with_intro()
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Met.current_scene, "modulate", Color.white, fade_time)
	
	
func home_in_no_intro(): # debug
	
	get_tree().set_pause(false)
	
	Met.spawn_new_scene(home_scene_path, self)
#	Met.current_scene.open_without_intro()
	
#	Met.current_scene.modulate = Color.black
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_property(Met.current_scene, "modulate", Color.white, fade_time)#.from(Color.black)


func home_in_from_game():
	
	get_tree().set_pause(false)
	
	Met.spawn_new_scene(home_scene_path, self)
	Met.current_scene.open_from_game() # select game screen
	
	yield(get_tree().create_timer(0.7), "timeout") # da se title naštima
	
	Met.current_scene.modulate = Color.black
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Met.current_scene, "modulate", Color.white, fade_time)


func home_out():
	
	if not Ref.sound_manager.menu_music_set_to_off: # če muzka ni setana na off
		Ref.sound_manager.stop_music("menu_music")
	
	var fade_out = get_tree().create_tween()
#	fade_out.tween_property(Met.current_scene, "modulate", Color.black, 1)
	fade_out.tween_callback(Met, "release_scene", [Met.current_scene])
	fade_out.tween_callback(self, "game_in")#.set_delay(1)


func game_in():	
	
#	game_scene_path = Profiles.current_game_data["game_scene_path"]	
	
	get_viewport().set_disable_input(false) # anti dablklik
	get_tree().set_pause(false)
	
	Met.spawn_new_scene(game_scene_path, self)
	Met.current_scene.modulate = Color.black
	# tukaj se seta GM glede na izbiro igre
	
#	Met.game_manager.set_tilemap()
#	Met.game_manager.set_game_view()
#	Met.game_manager.set_players()
	
	yield(get_tree().create_timer(0.5), "timeout") # da se kamera centrira (na restart)
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(Met.current_scene, "modulate", Color.white, fade_time).from(Color.black)
#	fade_in.tween_callback(Met.game_manager, "set_game")
	

func game_out():
	
#	get_viewport().set_disable_input(true) # anti dablklik
	
#	Global.player1_camera = null
#	Global.player2_camera = null
#
	Ref.sound_manager.play_gui_sfx("menu_fade")
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Met.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Met, "release_scene", [Met.current_scene])
#	fade_out.tween_callback(self, "home_in_from_game").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu
	fade_out.tween_callback(self, "home_in_no_intro").set_delay(1) # fajn delay ker se release zgodi šele v naslednjem frejmu


func reload_game(): # game out z drugačnim zaključkom
	
	get_viewport().set_disable_input(true) # anti dablklik
	
#	Global.player1_camera = null
#	Global.player2_camera = null
	
	Ref.sound_manager.play_gui_sfx("menu_fade")

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(Met.current_scene, "modulate", Color.black, fade_time)
	fade_out.tween_callback(Met, "release_scene", [Met.current_scene])
	fade_out.tween_callback(self, "game_in").set_delay(1) # dober delay ker se relese zgodi šele v naslednjem frejmu
	
