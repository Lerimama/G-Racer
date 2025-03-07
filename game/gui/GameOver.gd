extends Control


var final_game_data: Dictionary = {}
var still_driving_ids: Array = []

onready var background: ColorRect = $Background
onready var score_table: VBoxContainer = $ScoreTable
onready var title: Label = $Title
onready var restart_btn: Button = $Menu/RestartBtn


func _ready() -> void:

	hide()


func _process(delta: float) -> void:

	# čakam, da se spremeni število in apdejtam
	var still_driving_count: int = still_driving_ids.size()
	for driver_id in still_driving_ids:
		if "driver_stats" in final_game_data[driver_id]:
			still_driving_ids.erase(driver_id)
	if not still_driving_ids.size() == still_driving_count:
		score_table.update_scorelines(final_game_data)


func open(curr_game_data: Dictionary, level_index: int, levels_count: int, is_success: bool):

	final_game_data = curr_game_data

	# level or game finished
	if level_index < levels_count - 1:
		_set_for_level_finished(level_index, levels_count)
	else:
		_set_for_game_finished(is_success)


	# če je kakšen (ai) prazen, ga dodam med prazne
	still_driving_ids.clear()
	for driver_id in final_game_data:
		if not "driver_stats" in final_game_data[driver_id]:
			still_driving_ids.append(driver_id)

	score_table.set_scorelist(final_game_data)

	var background_fadein_transparency: float = 1

	$Menu/RestartBtn.grab_focus()

	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	# fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	# fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property($Panel, "modulate:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)


func _set_for_level_finished(level_index: int, levels_count: int):

	var finished_level_key: int = Sts.game_levels[level_index]
	var finished_level_name: String = Pfs.level_profiles[finished_level_key]["level_name"]

	title.text = finished_level_name.to_upper() + " FINISHED"
	title.modulate = Rfs.color_green

	if restart_btn.is_connected("pressed", self, "_on_restart_pressed"):
		restart_btn.disconnect("pressed", self, "_on_restart_pressed")
	if not restart_btn.is_connected("pressed", self, "_on_next_pressed"):
		restart_btn.connect("pressed", self, "_on_next_pressed")
	restart_btn.text = "NEXT LEVEL"


func _set_for_game_finished(is_success: bool):

	if is_success:
		title.text = "GAME FINISHED"
		title.modulate = Rfs.color_green
	else:
		title.text = "GAME OVER"
		title.modulate = Rfs.color_red

	if restart_btn.is_connected("pressed", self, "_on_next_pressed"):
		restart_btn.disconnect("pressed", self, "_on_next_pressed")
	if not restart_btn.is_connected("pressed", self, "_on_restart_pressed"):
		restart_btn.connect("pressed", self, "_on_restart_pressed")
	restart_btn.text = "RESTART"



func _apply_final_stats_and_close(close_to: int):

	get_parent().game_manager.game_reactor.apply_stats_to_unfinished_drivers(still_driving_ids)

	get_viewport().set_disable_input(true)

	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(get_parent().game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")

	score_table.update_scorelines(final_game_data)
	var time_to_read: float = 2
	yield(get_tree().create_timer(time_to_read), "timeout")


	match close_to:
		-1:
			Rfs.main_node.game_out()
		0:
			Rfs.main_node.reload_game()
		1:
			get_parent().game_manager.set_game()

	get_viewport().set_disable_input(false)
	hide()


func _on_restart_pressed() -> void:

	_apply_final_stats_and_close(0)


func _on_next_pressed() -> void:

	_apply_final_stats_and_close(1)


func _on_QuitBtn_pressed() -> void:

	_apply_final_stats_and_close(-1)


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
