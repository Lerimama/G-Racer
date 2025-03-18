extends CanvasLayer
class_name Gui

var game_manager: Game
var unfinished_driver_ids: Array = []

onready var hud: Control = $Hud
onready var driver_huds_holder: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var game_cover: ColorRect = $GameCover


#func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira
#
#	if Input.is_action_just_pressed("ui_cancel"):
#		if game_manager:
#			if game_manager.game_stage == game_manager.GAME_STAGE.PLAYING or game_manager.game_stage == game_manager.GAME_STAGE.READY:
#				if pause_game.visible:
#					game_manager.game_sound.menu_music.stop()
#					game_manager.game_sound.game_music.stream_paused = false
#					pause_game.play_on()
#				else:
#					game_manager.game_sound.game_music.stream_paused = true
#					game_manager.game_sound.menu_music.play()
#					pause_game.pause_game()


func _ready() -> void:

	pause_game.hide()
	game_over.hide()
	game_cover.modulate.a = 1


func on_game_start():

	hud.on_game_start()


func open_game_over():

	yield(get_tree().create_timer(Sets.get_it_time), "timeout")

	# pseudo fejdout
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(game_cover, "modulate:a", 0.8, 0.7)
	yield(fade_tween, "finished")

	# če je kakšen (ai) prazen, ga dodam med prazne
	unfinished_driver_ids.clear()
	for driver_id in game_manager.final_drivers_data:
		if not "driver_stats" in game_manager.final_drivers_data[driver_id]:
			unfinished_driver_ids.append(driver_id)

	game_over.open(game_manager)
	hud.on_game_over()

	if game_manager.game_sound.win_jingle.is_playing():
		yield(game_manager.game_sound.win_jingle, "finished")
	elif game_manager.game_sound.lose_jingle.is_playing():
		yield(game_manager.game_sound.win_jingle, "finished")
	game_manager.game_sound.menu_music.play()


func set_gui(drivers_on_start: Array):

	hud.set_hud(game_manager, drivers_on_start)
	if game_manager.level_profile["level_time_limit"] > 0:
		if not hud.game_timer.is_connected("time_is_up", game_manager.game_tracker, "_on_game_time_is_up"):
			hud.game_timer.connect("time_is_up", game_manager.game_tracker, "_on_game_time_is_up")
	driver_huds_holder.set_driver_huds(game_manager, drivers_on_start, Sets.mono_view_mode)

	# fejdin
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7)
	yield(fade_tween, "finished")


func _process(delta: float) -> void:

	if game_manager:
		if game_manager.game_stage > game_manager.GAME_STAGE.PLAYING:
			# čakam, da se spremeni število in apdejtam
			var still_driving_count: int = unfinished_driver_ids.size()
			for driver_id in game_manager.final_drivers_data:
				if "driver_stats" in game_manager.final_drivers_data[driver_id]:
					unfinished_driver_ids.erase(driver_id)
			# če se je število čanih spremenilo
			if not unfinished_driver_ids.size() == still_driving_count:
				game_over.score_table.update_scorelines(game_manager.final_drivers_data)


func close_game(transition_to: int, delay_time: float = 0):

	get_tree().paused = true # proces, fp, input ... pavza ga sama seta, mogoče ga lahko skozi cel GO proces?

	game_manager.game_sound.fade_sounds(game_manager.game_sound.menu_music)
	if not unfinished_driver_ids.empty():
		_update_final_data()

	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_over, "modulate:a", 1, 0.3).set_delay(delay_time)
	fade_tween.tween_property(game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")
	game_over.hide()

	get_tree().paused = false # pavza ga sama seta, mogoče ga lahko skozi cel GO proces?
	get_viewport().set_disable_input(false)

	match transition_to:
		-1:
			Refs.main_node.game_out()
		0:
			Refs.main_node.reload_game()
			#			game_manager.set_game(0)
		1:
			game_manager.set_game(1)


func _update_final_data():
	# dodam neuvrščene ai-je, ki vedno pridejo do konca
	# izračun predvidenega časa je glede na prevožen procent

	for driver_id in unfinished_driver_ids:
		var driver_vehicle: Vehicle
		for vehicle in game_manager.game_tracker.drivers_in_game:
			if vehicle.driver_id == driver_id:
				driver_vehicle = vehicle
				break
		# izračun časa
		var current_game_time: int = hud.game_timer.game_time_hunds
		if driver_vehicle:
			var distance_needed_part: float = driver_vehicle.driver_tracker.unit_offset
			if distance_needed_part == 0: # če obtiči na štartu ... verjetno nikoli
				driver_vehicle.driver_stats[Pros.STATS.LEVEL_TIME] = current_game_time
			else:
				driver_vehicle.driver_stats[Pros.STATS.LEVEL_TIME] = current_game_time / distance_needed_part
			game_manager.final_drivers_data[driver_id]["driver_stats"] = driver_vehicle.driver_stats.duplicate()

	if not unfinished_driver_ids.empty():
		game_over.score_table.update_scorelines(game_manager.final_drivers_data)
