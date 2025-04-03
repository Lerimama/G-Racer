extends CanvasLayer
class_name Gui

var game: Game
var waiting_drivers_finished: int = 0
var deactivating_unfinished_drivers: bool = false

onready var hud: Control = $Hud
onready var driver_huds: Control = $DriverHuds
onready var pause_game: Control = $PauseGame

onready var game_over: Control = $GameOver
onready var game_cover: ColorRect = $GameCover
onready var level_finished: Control = $GameOver/LevelFinished
onready var game_summary: Control = $GameOver/GameSummary

onready var game_over_menu: HBoxContainer = $GameOver/Menu
onready var quit_btn: Button = $GameOver/Menu/QuitBtn
onready var continue_btn: Button = $GameOver/Menu/ContinueBtn
onready var next_restart_btn: Button = $GameOver/Menu/NextRestartBtn


func _ready() -> void:

	pause_game.hide()
	game_cover.show()
	game_over.hide()
	level_finished.hide()
	game_summary.hide()
	game_over_menu.hide()


func set_gui(drivers_on_start: Array):

	waiting_drivers_finished = 0

	# hud
	hud.set_hud(game, drivers_on_start)
	driver_huds.set_driver_huds(game, drivers_on_start, Sets.mono_view_mode)

	# če je omejen čas, povežem s timerjem
	if game.level_profile["level_time_limit"] > 0:
#		if not hud.game_timer.is_connected("time_is_up", game.game_tracker, "_on_game_time_is_up"):
		hud.game_timer.connect("time_is_up", game.game_tracker, "_on_game_time_is_up", CONNECT_ONESHOT)

#	driver_huds.set_driver_huds(game, drivers_on_start, Sets.mono_view_mode)
	_update_all_stats_display()

	# fejdin
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7).from(1.0)
	yield(fade_tween, "finished")
	game_cover.hide()


func on_game_start():

	print("start")
	hud.game_timer.start_timer()

func on_level_finished():


	# da bo miš delovala
#	game.set_process_input(false)
#	get_viewport().set_disable_input(true)


	# če je konec, ustavim čas ... moram pred ostalo kodo, da je natančno
	var level_ended: = true

	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		if driver.is_active:
			level_ended = false
	if level_ended == true:
		hud.game_timer.stop_timer()

	match game.level_profile["rank_by"]:
		Levs.RANK_BY.TIME:
			# zapišem uvrščene driverje, čakane ai, disq driverje
			# nagradim uvrščene
			for driver_id in game.game_drivers_data:
				var driver_rank: int = game.game_drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				if driver_rank > 0: # 0 ... še vozi, -1 ... disq
					_reward_driver_for_level(game.game_drivers_data[driver_id])
		Levs.RANK_BY.POINTS:
			# vsi driverji, čakani ai
			# ranking po točkah nima veze s časom prihoda končanja naloge ...
			# razvrstitev (tudi že uvrščenih) je jasna šele po končanju vseh
			# nagradim šele, ko so vsi uvrščeniuvrščene in disejblane (disq tukaaj ni)
			# zapišem skor za uvrščene
			for driver_id in game.game_drivers_data:
				#				var driver_rank: int = game.game_drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				#				if driver_rank > 0: # 0 ... še vozi, -1 ... disq
				#					_reward_driver_for_level(game.game_drivers_data[driver_id])
				pass

	game_over.set_level_finished(game)

	# set GO menu ... single level nima summarija
	if Sets.game_levels.size() == 1:
		quit_btn.text = "TO MAIN MENU" # -> finish unfinished > close game
		continue_btn.hide()
		next_restart_btn.text = "RESTART" # -> finish unfinished > close game
		next_restart_btn.connect("pressed", self, "_on_restart_game_pressed", [], CONNECT_ONESHOT)
		next_restart_btn.show()
		next_restart_btn.grab_focus()
	else:
		quit_btn.text = "QUIT TOURNAMENT" # -> finish unfinished > close game
		continue_btn.show() # -> finish unfinished > open summary
		continue_btn.grab_focus()
		next_restart_btn.hide() # ... pokaže se na summary open
		if not continue_btn.is_connected("pressed", self, "_on_continue_btn_pressed"):
			continue_btn.connect("pressed", self, "_on_continue_btn_pressed", [], CONNECT_ONESHOT)

	#	yield(get_tree().create_timer(Sets.get_it_time), "timeout")

	game_over.show()
	game_cover.show()
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_cover, "modulate:a", 0.5, 0.5).from(0.0)
	fade_tween.tween_callback(level_finished, "show")
	fade_tween.parallel().tween_callback(game_over_menu, "show")
	fade_tween.tween_property(level_finished, "modulate:a", 1, 0.7).from(0.0)
	fade_tween.parallel().tween_property(game_over_menu, "modulate:a", 1, 1).from(0.0)
	yield(fade_tween, "finished")
	if Sets.game_levels.size() == 1:
		next_restart_btn.grab_focus()
	else:
		continue_btn.grab_focus()
#	next_restart_btn.hide() # ... pokaže se na summary open

	prints("FO",game_over.get_focus_owner())
	if game.game_sound.win_jingle.is_playing():
		yield(game.game_sound.win_jingle, "finished")
	elif game.game_sound.lose_jingle.is_playing():
		yield(game.game_sound.win_jingle, "finished")
	game.game_sound.menu_music.play()



# level finished for player(s)
#func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira
#
#	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
#		# _temp način, ker gumb sam ne dela dokler ne ustavim igre
#		if continue_btn.visible and continue_btn.has_focus():
##			yield(_finish_unfinished_drivers(), "completed")
##			get_viewport().set_disable_input(true)
##			game_over_menu.hide()
##			_open_game_summary()
#			_on_FinishBtn_pressed()


func _finish_unfinished_drivers():

	get_viewport().set_disable_input(true)

	# če niso vsi tekmovalci v cilju (igra še teče)
	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		if driver.is_active:
			deactivating_unfinished_drivers = true # more bit pred deaktivacijo
			driver.is_active = false

	yield(get_tree(), "idle_frame") # za yield

	if deactivating_unfinished_drivers:
		hud.game_timer.stop_timer()
		match game.level_profile["rank_by"]:
			Levs.RANK_BY.POINTS, Levs.RANK_BY.SCALPS: # vrstni red je znan šele ko so vsi v cilju
				for driver_id in game.game_drivers_data:
					_reward_driver_for_level(game.game_drivers_data[driver_id])

		var final_level_data: Dictionary = game.game_drivers_data.duplicate()
		game_over.level_finished_score_table.set_scoretable(final_level_data, game.level_profile["rank_by"], false)
		yield(get_tree().create_timer(Sets.get_it_time), "timeout")
		deactivating_unfinished_drivers = false


func _open_game_summary():

	get_viewport().set_disable_input(true)

	# menu setup
	continue_btn.hide()
	next_restart_btn.show()

	# mid level
	if game.level_index < Sets.game_levels.size() - 1:
		quit_btn.text = "QUIT TOURNAMENT"
		next_restart_btn.text = "NEXT LEVEL"
		if next_restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
			next_restart_btn.disconnect("pressed", self, "_on_restart_game_pressed")
		if not next_restart_btn.is_connected("pressed", self, "_on_next_level_pressed"):
			next_restart_btn.connect("pressed", self, "_on_next_level_pressed", [], CONNECT_ONESHOT)
	# last level
	else:
		quit_btn.text = "TO MAIN MENU"
		next_restart_btn.text = "RESTART TOURNAMENT"
		if next_restart_btn.is_connected("pressed", self, "_on_next_level_pressed"):
			next_restart_btn.disconnect("pressed", self, "_on_next_level_pressed")
		if not next_restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
			next_restart_btn.connect("pressed", self, "_on_restart_game_pressed", [], CONNECT_ONESHOT)

	#	yield(_finish_unfinished_drivers(), "completed")

	game_over.set_summary(game)

#	print("get_focus_owner 2", game_summary.get_focus_owner())
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	# hide lvel finished
	fade_tween.tween_property(level_finished, "modulate:a", 0, 0.5)
	fade_tween.tween_callback(level_finished, "hide")
	# set pause
	# show summary, menu
	fade_tween.tween_callback(game_summary, "show")
	fade_tween.tween_callback(game_over_menu, "show")
	fade_tween.tween_callback(next_restart_btn, "show")
	fade_tween.parallel().tween_callback(next_restart_btn, "grab_focus")
	fade_tween.tween_property(game_summary, "modulate:a", 1, 0.5).from(0.0)
	fade_tween.parallel().tween_property(game_cover, "modulate:a", 1, 0.5)
	fade_tween.parallel().tween_property(game_over_menu, "modulate:a", 1, 0.5).from(0.0)
	yield(fade_tween, "finished")
	get_tree().set_pause(true)
	get_viewport().set_disable_input(false)


func close_game():

	get_viewport().set_disable_input(true)

	hud.reset_hud()
	driver_huds.reset_driver_huds()

	game.game_sound.fade_sounds(game.game_sound.menu_music)

	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(game_summary, "modulate:a", 0, 0.5)
	fade_tween.tween_property(game_cover, "modulate:a", 1, 0.3)
	fade_tween.tween_property(game_cover, "modulate", Color.pink, 0.3)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)

	game_summary.hide()



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


func _update_all_stats_display():

	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		# hud
		if driver.driver_id in hud.statboxes_with_driver_ids.values(): # ai nima svojga statboxa
			for stat in driver.driver_stats:
				hud._on_stat_changed(driver.driver_id, stat, driver.driver_stats[stat])
		# driver huds
		if driver.driver_id in driver_huds.driver_ids_with_driver_huds:
			var driver_hud: Control = driver_huds.driver_ids_with_driver_huds[driver.driver_id]
			for stat in driver.driver_stats:
				driver_huds._on_stat_changed(driver.driver_id, stat, driver.driver_stats[stat])


func _on_waiting_driver_finished(driver_id: String):

	var driver_final_data: Dictionary = game.game_drivers_data[driver_id]

	match game.level_profile["rank_by"]:
		Levs.RANK_BY.TIME:
			if deactivating_unfinished_drivers:
				waiting_drivers_finished += 1 # za rank
				var new_rank: int = game.game_tracker.drivers_finished.size() + waiting_drivers_finished
				var new_drivers_level_time: int = hud.game_timer.game_time_hunds
				var punish_time: int = new_drivers_level_time / 2
				new_drivers_level_time += punish_time * new_rank
				driver_final_data.driver_stats[Pros.STAT.LEVEL_RANK] = new_rank
				driver_final_data.driver_stats[Pros.STAT.LEVEL_FINISHED_TIME] = new_drivers_level_time
				_reward_driver_for_level(driver_final_data)
			else:
				_reward_driver_for_level(driver_final_data)
				game_over.level_finished_score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], false)

		Levs.RANK_BY.POINTS:
			#			if deactivating_unfinished_drivers:
			#				var punish_driver_points: int = 50
			#				driver_final_data[Pros.STAT.POINTS] += punish_driver_points
			#			else:
			# če spremenim točke, ponovno opredelim ranking vseh driverjev ... koda je spodaj
			game_over.level_finished_score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], false)
		Levs.RANK_BY.SCALPS:
			#			if deactivating_unfinished_drivers:
			#				var punish_driver_points: int = 50
			#				driver_final_data[Pros.STAT.SCALPS] += punish_driver_points
			#			else:
			# če spremenim število, skalpov ponovno opredelim ranking vseh driverjev ... koda je spodaj
			game_over.level_finished_score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], false)

			# re-rank
			#	var driver_points_arrays: Array = []
			#	for driver_id in game.game_drivers_data:
			#		driver_points_arrays.append([driver_id, game.game_drivers_data[driver_id]["driver_stats"][Pros.STAT.POINTS]])
			#	driver_points_arrays.sort_custom(self, "_sort_arrays_on_points")
			#	for driver_array in driver_points_arrays:
			#		var driver_rank: int = driver_points_arrays.find(driver_array) + 1
			#		var driver_array_id: int = driver_array[0]
			#		game.game_drivers_data[driver_array_id]["driver_stats"][Pros.STAT.LEVEL_RANK] = driver_rank
			#
			#	func _sort_arrays_on_points(driver_points_array_1: Array, driver_points_array_2: Array):
			#
			#		if driver_points_array_1[1] > driver_points_array_2[1]:
			#			return true
			#		return false


func _on_QuitBtn_pressed() -> void:
	# oneshot
	# na finished in summary

	game_over_menu.hide()
	yield(_finish_unfinished_drivers(), "completed")
	yield(close_game(), "completed")
	Refs.main_node.to_home()


func _on_continue_btn_pressed() -> void:
	# oneshot
	# na finished

	print("cont")
	game_over_menu.hide()
	yield(_finish_unfinished_drivers(), "completed")
	_open_game_summary()


func _on_next_level_pressed() -> void:
	# oneshot
	# na summary

	game_over_menu.hide()
	yield(close_game(), "completed")
	get_tree().set_pause(false)
	Refs.main_node.reload_to_level(game.level_index + 1)


func _on_restart_game_pressed() -> void:
	# oneshot
	# na finished
	print("res")
	game_over_menu.hide()
	yield(_finish_unfinished_drivers(), "completed")
	yield(close_game(), "completed")
	Refs.main_node.reload_to_level()
