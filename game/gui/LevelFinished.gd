extends Control


var drivers_data: Dictionary = {}
var level_data: Dictionary = {}

onready var background: ColorRect = $Background
onready var score_table: VBoxContainer = $ScoreTable
onready var title: Label = $Title
onready var level_record_label: Label = $LevelRecord
onready var restart_btn: Button = $Menu/RestartBtn


# level finished for player(s)
func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
		if visible:
			_on_FinishBtn_pressed()


func _ready() -> void:

	hide()


func set_level_finished(game_manager: Game):

	level_data = game_manager.final_level_data
	drivers_data = game_manager.final_drivers_data
	var level_index: int = game_manager.level_index
	var levels_count: int = game_manager.game_levels.size()

	# level or game finished
	if game_manager.game_stage == game_manager.GAME_STAGE.END_FAIL:
		title.text = "GAME OVER"
		title.modulate = Refs.color_red
	else:
		title.text = "GAME FINISHED"
		title.modulate = Refs.color_green

	var level_record: Array = level_data["level_profile"]["level_record"]

	if not level_record[0] == 0:
		var level_record_clock_time: String = Mets.get_clock_time_string(level_record[0])
		level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(level_record[1])
		level_record_label.show()
	else:
		level_record_label.hide()

	score_table.set_scorelist(drivers_data)

	var background_fadein_transparency: float = 1

	$Menu/FinishBtn.grab_focus()


func _on_FinishBtn_pressed() -> void:

	get_parent().open_game_over()
