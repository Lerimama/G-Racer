extends CanvasLayer
class_name Gui

var game_manager: Game
var unfinished_drivers: Array = []

onready var hud: Control = $Hud
onready var driver_huds_holder: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var game_cover: ColorRect = $GameCover
onready var level_finished: Control = $LevelFinished


func _ready() -> void:

	pause_game.hide()
	game_over.hide()
	game_cover.modulate.a = 1


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


func on_game_start():

	hud.game_timer.start_timer()


func open_level_finished():

	# da bo miš delovala
#	game_manager.set_process_input(false)
#	get_viewport().set_disable_input(true)

	# če je kakšen (ai) prazen, ga dodam med prazne
	unfinished_drivers.clear()
	for driver in game_manager.game_tracker.drivers_in_game:
		if driver.is_active:
			unfinished_drivers.append(driver)

	# če so deaktivirani vsi driverji, ustavim timer
	if unfinished_drivers.empty():
		hud.game_timer.stop_timer()

	level_finished.set_level_finished(game_manager)

	yield(get_tree().create_timer(Sets.get_it_time), "timeout")

	# pseudo fejdout
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_cover, "modulate:a", 0.8, 0.7)
	fade_tween.tween_callback(level_finished.finish_btn, "grab_focus")
	fade_tween.tween_callback(level_finished, "show")
	fade_tween.tween_property(level_finished, "modulate:a", 1, 1).from(0.0)
	yield(fade_tween, "finished")

	if game_manager.game_sound.win_jingle.is_playing():
		yield(game_manager.game_sound.win_jingle, "finished")
	elif game_manager.game_sound.lose_jingle.is_playing():
		yield(game_manager.game_sound.win_jingle, "finished")
	game_manager.game_sound.menu_music.play()


func open_game_over():

	if not unfinished_drivers.empty():
		_update_final_data()

	hud.game_timer.stop_timer()
	#	hud.hide() ... itak ga pokrije cover
	game_over.open(game_manager)
	get_tree().set_pause(true) # proces, fp, input

	print("get_focus_owner 2", game_over.get_focus_owner())
	get_viewport().set_disable_input(true)
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(level_finished, "modulate:a", 0, 0.5)
	fade_tween.tween_callback(level_finished, "hide")
	fade_tween.tween_callback(game_over, "show")
	fade_tween.tween_callback(game_over.restart_btn, "grab_focus")
	fade_tween.tween_property(game_over, "modulate:a", 1, 0.5).from(0.0)
	fade_tween.parallel().tween_property(game_cover, "color", Color.darkmagenta, 0.5)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)


func close_game(transition_to: int):

	game_manager.game_sound.fade_sounds(game_manager.game_sound.menu_music)

	get_viewport().set_disable_input(true)
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_over, "modulate:a", 0, 0.5)
	fade_tween.tween_property(game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)

	game_over.hide()

	match transition_to:
		-1:
			Refs.main_node.game_out()
		0:
			Refs.main_node.reload_game()
			#			game_manager.set_game(0)
		1:
			get_tree().set_pause(false)
			game_manager.set_game(1)


func _on_waiting_driver_finished(late_driver: Vehicle, drivers_final_data: Dictionary):

	level_finished.score_table.update_scorelines(drivers_final_data)
	unfinished_drivers.erase(late_driver)


func _update_final_data():
	# dodam neuvrščene ai-je, ki vedno pridejo do konca
	# izračun predvidenega časa je glede na prevožen procent

	var current_game_time: int = hud.game_timer.game_time_hunds
	for driver in unfinished_drivers:
		# če ma tarckerja upoštevam preostalo distanco
		if driver.driver_tracker:
			var distance_needed_part: float = driver.driver_tracker.unit_offset
			if distance_needed_part == 0: # če obtiči na štartu ... verjetno nikoli
				driver.driver_stats[Pros.STAT.LEVEL_TIME] = current_game_time
			else:
				driver.driver_stats[Pros.STAT.LEVEL_TIME] = current_game_time / distance_needed_part
		else:
		# če ni trackerja ... provizorij .. tolk da je večji čas od tistih v cilju
			driver.driver_stats[Pros.STAT.LEVEL_TIME] = current_game_time * 1.5

		game_manager.final_drivers_data[driver.driver_id]["driver_stats"] = driver.driver_stats.duplicate()
		game_manager.final_drivers_data[driver.driver_id]["weapon_stats"] = driver.weapon_stats.duplicate()

	unfinished_drivers.clear()
	level_finished.score_table.update_scorelines(game_manager.final_drivers_data)
