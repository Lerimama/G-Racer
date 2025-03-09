extends CanvasLayer
class_name Gui

var game_manager: Game
var unfinished_driver_ids: Array = []

onready var hud: Control = $Hud
onready var driver_huds_holder: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var game_cover: ColorRect = $GameCover


func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):
		if game_manager:
			if game_manager.game_stage == game_manager.GAME_STAGE.PLAYING or game_manager.game_stage == game_manager.GAME_STAGE.READY:
				if pause_game.visible:
					pause_game.play_on()
				else:
					pause_game.pause_game()


func _ready() -> void:

	pause_game.hide()
	game_over.hide()
	game_cover.modulate.a = 1


func _on_game_stage_changed(curr_game_manager: Game):

	game_manager = curr_game_manager

	match game_manager.game_stage:

		game_manager.GAME_STAGE.READY:
			hud.set_hud(game_manager)
			if game_manager.level_profile["level_time_limit"] > 0:
				if not hud.game_timer.is_connected("time_is_up", game_manager.game_reactor, "_on_game_time_is_up"):
					hud.game_timer.connect("time_is_up", game_manager.game_reactor, "_on_game_time_is_up")
			driver_huds_holder.set_driver_huds(game_manager, Sts.one_screen_mode)

			# fejdin
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7)
			yield(fade_tween, "finished")

		game_manager.GAME_STAGE.PLAYING:
			hud.on_game_start()

		game_manager.GAME_STAGE.END_SUCCESS, game_manager.GAME_STAGE.END_FAIL:
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")

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


func close_gui(close_to: int):

	get_viewport().set_disable_input(true)

	if not unfinished_driver_ids.empty():
		_update_final_data()


	var time_to_read: float = 2
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(game_over, "modulate:a", 1, 0.3).set_delay(time_to_read)
	fade_tween.tween_property(game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")
	game_over.hide()

	get_viewport().set_disable_input(false)

	match close_to:
		-1:
			Rfs.main_node.game_out()
		0:
			Rfs.main_node.reload_game()
		1:
			game_manager.set_game()


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
				driver_vehicle.driver_stats[Pfs.STATS.LEVEL_TIME] = current_game_time
			else:
				driver_vehicle.driver_stats[Pfs.STATS.LEVEL_TIME] = current_game_time / distance_needed_part
			game_manager.final_drivers_data[driver_id]["driver_stats"] = driver_vehicle.driver_stats.duplicate()

	if not unfinished_driver_ids.empty():
		game_over.score_table.update_scorelines(game_manager.final_drivers_data)
