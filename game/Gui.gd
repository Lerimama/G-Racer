extends CanvasLayer
class_name Gui

var game: Game
var waiting_drivers_finished: int = 0
var deactivating_unfinished_drivers: bool = false

onready var hud: Control = $Hud
onready var driver_huds: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_summary: Control = $GameSummary
onready var game_cover: ColorRect = $FinishedBackground
onready var level_finished: Control = $LevelFinished


func _ready() -> void:

	pause_game.hide()
	game_summary.hide()
	game_cover.show()


func set_gui(drivers_on_start: Array):

	hud.set_hud(game, drivers_on_start)
	waiting_drivers_finished = 0

	if game.level_profile["level_time"] > 0:
		if not hud.game_timer.is_connected("time_is_up", game.game_tracker, "_on_game_time_is_up"):
			hud.game_timer.connect("time_is_up", game.game_tracker, "_on_game_time_is_up")
	driver_huds.set_driver_huds(game, drivers_on_start, Sets.mono_view_mode)

	hud.update_all_stats_display()

	# fejdin
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7).from(1.0)
	yield(fade_tween, "finished")


func on_game_start():

	hud.game_timer.start_timer()


func on_level_finished():

	# da bo miš delovala
#	game.set_process_input(false)
#	get_viewport().set_disable_input(true)

	# če je konec, ustavim čas ... moram pred ostalo kodo, da je natančno
	if game.game_tracker.drivers_in_game.empty():
		hud.game_timer.stop_timer()

	print("drivers data")
	print("")
	# zapišem skor za nečakajoče
	for driver_id in game.game_drivers_data:
		var driver_rank: int = game.game_drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
		if driver_rank > 0: # 0 ... še vozi, -1 ... disq
			_reward_driver_for_level(game.game_drivers_data[driver_id])
		print(driver_id)
		print(game.game_drivers_data[driver_id])
		print("")

	level_finished.set_level_finished(game)

	#	yield(get_tree().create_timer(Sets.get_it_time), "timeout")

	# pseudo fejdout
	game_cover.show()
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_cover, "modulate:a", 0.5, 0.7).from(0.0)
	fade_tween.tween_callback(level_finished.finish_btn, "grab_focus")
	fade_tween.tween_callback(level_finished, "show")
	fade_tween.tween_property(level_finished, "modulate:a", 1, 1).from(0.0)
	yield(fade_tween, "finished")

	if game.game_sound.win_jingle.is_playing():
		yield(game.game_sound.win_jingle, "finished")
	elif game.game_sound.lose_jingle.is_playing():
		yield(game.game_sound.win_jingle, "finished")
	game.game_sound.menu_music.play()


func _reward_driver_for_level(driver_data: Dictionary):

	var driver_final_rank: int = driver_data["driver_stats"][Pros.STAT.LEVEL_RANK]

	# win
	if driver_final_rank == 1:
		driver_data["tournament_stats"][Pros.STAT.TOURNAMENT_WINS].append(game.level_index)
		# ček for rekord reward?

	# cash
	if not driver_final_rank > Sets.level_cash_rewards.size():
		driver_data["driver_stats"][Pros.STAT.CASH] += Sets.level_cash_rewards[driver_final_rank - 1]
	# points
	if not driver_final_rank > Sets.level_cash_rewards.size():
		driver_data["tournament_stats"][Pros.STAT.TOURNAMENT_POINTS] += Sets.level_points_rewards[driver_final_rank - 1]


func open_game_summary():

	# če niso vsi tekmovalci v cilju (igra še teče)
	if not game.game_tracker.drivers_in_game.empty():
		deactivating_unfinished_drivers = true
		for driver in game.game_tracker.drivers_in_game:
			driver.is_active = false
		hud.game_timer.stop_timer()
		yield(get_tree(), "idle_frame") # zazih
		var final_level_data: Dictionary = game.game_drivers_data.duplicate()
		level_finished.score_table.set_scoretable(final_level_data, false)
		yield(get_tree().create_timer(Sets.get_it_time), "timeout")
		deactivating_unfinished_drivers = false

	#	hud.hide() ... itak ga pokrije cover
	game_summary.set_summary(game)

	get_tree().set_pause(true) # proces, fp, input
#	print("get_focus_owner 2", game_summary.get_focus_owner())
	get_viewport().set_disable_input(true)
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(level_finished, "modulate:a", 0, 0.5)
	fade_tween.tween_callback(level_finished, "hide")
	fade_tween.tween_callback(game_summary, "show")
	fade_tween.tween_callback(game_summary.restart_btn, "grab_focus")
	fade_tween.tween_property(game_summary, "modulate:a", 1, 0.5).from(0.0)
	fade_tween.parallel().tween_property(game_cover, "modulate:a", 1, 0.5)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)


func close_game(transition_to: int):

	game.game_sound.fade_sounds(game.game_sound.menu_music)

	get_viewport().set_disable_input(true)
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_summary, "modulate:a", 0, 0.5)
	fade_tween.tween_property(game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)

	game_summary.hide()

	match transition_to:
		-1:
			Refs.main_node.game_out()
		0:
			Refs.main_node.reload_game()
			#			game.set_game(0)
		1:
			get_tree().set_pause(false)
			game.set_game(1)


func _on_waiting_driver_finished(driver_id: String):

	var driver_final_data: Dictionary = game.game_drivers_data[driver_id]

	if deactivating_unfinished_drivers:
		waiting_drivers_finished += 1

		var new_rank: int = game.game_tracker.drivers_finished.size() + waiting_drivers_finished
		var new_drivers_level_time: int = hud.game_timer.game_time_hunds
		var punish_time: int = new_drivers_level_time / 2
		new_drivers_level_time += punish_time * new_rank

		driver_final_data.driver_stats[Pros.STAT.LEVEL_RANK] = new_rank
		driver_final_data.driver_stats[Pros.STAT.LEVEL_FINISHED_TIME] = new_drivers_level_time
		_reward_driver_for_level(driver_final_data)
	else:
		_reward_driver_for_level(driver_final_data)
		level_finished.score_table.set_scoretable(game.game_drivers_data, false)


