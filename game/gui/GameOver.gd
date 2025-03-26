extends Control


var drivers_data: Dictionary = {}
var level_data: Dictionary = {}

onready var background: ColorRect = $Background
onready var score_table: VBoxContainer = $ScoreTable
onready var title: Label = $Title
onready var level_record_label: Label = $LevelRecord
onready var restart_btn: Button = $Menu/RestartBtn



func _ready() -> void:

	hide()


func open(game_manager: Game):

	level_data = game_manager.final_level_data
	drivers_data = game_manager.final_drivers_data
	var level_index: int = game_manager.level_index
	var levels_count: int = game_manager.game_levels.size()

	# level or game finished
	if game_manager.game_stage == game_manager.GAME_STAGE.FINISHED_FAIL:
		_set_for_game_finished(false)
	else:
		if level_index < levels_count - 1:
			_set_for_level_finished(level_index, levels_count)
		else:
			_set_for_game_finished(true)

	var level_record: Array = level_data["level_profile"]["level_record"]

	if not level_record[0] == 0:
		var level_record_clock_time: String = Mets.get_clock_time_string(level_record[0])
		level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(level_record[1])
		level_record_label.show()
	else:
		level_record_label.hide()

	score_table.set_scorelist(drivers_data)

	var background_fadein_transparency: float = 1

	restart_btn.grab_focus()
	print("get_focus_owner ", get_focus_owner())
#	var fade_in = get_tree().create_tween()
#	fade_in.tween_callback(self, "show")
#	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
#	fade_in.parallel().tween_property($Panel, "modulate:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	#	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)
#	$Menu/RestartBtn.grab_focus()


func _set_for_level_finished(level_index: int, levels_count: int):

	var finished_level_name: String = Sets.game_levels[level_index]["level_name"]

	title.text = finished_level_name.to_upper() + " FINISHED"
	title.modulate = Refs.color_green

	if restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
		restart_btn.disconnect("pressed", self, "_on_restart_game_pressed")
	if not restart_btn.is_connected("pressed", self, "_on_next_pressed"):
		restart_btn.connect("pressed", self, "_on_next_pressed")
	restart_btn.text = "NEXT LEVEL"


func _set_for_game_finished(is_success: bool):

	if is_success:
		title.text = "GAME FINISHED"
		title.modulate = Refs.color_green
	else:
		title.text = "GAME OVER"
		title.modulate = Refs.color_red

	if restart_btn.is_connected("pressed", self, "_on_next_pressed"):
		restart_btn.disconnect("pressed", self, "_on_next_pressed")
	if not restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
		restart_btn.connect("pressed", self, "_on_restart_game_pressed")
	restart_btn.text = "RESTART"


func _on_next_pressed() -> void:

	get_parent().close_game(1)


func _on_restart_game_pressed() -> void:

	get_parent().close_game(0)


func _on_QuitBtn_pressed() -> void:
	print("click")
	get_parent().close_game(-1)


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
