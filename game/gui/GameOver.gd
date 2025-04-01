extends Control


var level_data: Dictionary = {}

onready var background: ColorRect = $Background
onready var score_table: VBoxContainer = $ScoreTable
onready var title: Label = $Title
onready var restart_btn: Button = $Menu/RestartBtn


func _ready() -> void:

	hide()



func set_summary(game: Game):

	var level_index: int = game.level_index
	var levels_count: int = game.game_levels.size()

	# fai
	if game.game_stage == game.GAME_STAGE.FINISHED_FAIL:
		title.text = "TOURNAMENT OVER"
		title.modulate = Refs.color_red
	# success
	else:
		title.modulate = Refs.color_green
		# zadnji
		if level_index == levels_count - 1:
			if restart_btn.is_connected("pressed", self, "_on_next_pressed"):
				restart_btn.disconnect("pressed", self, "_on_next_pressed")
			if not restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
				restart_btn.connect("pressed", self, "_on_restart_game_pressed")
			restart_btn.text = "RESTART TOURNAMENT"
			title.text = "TOURNAMENT FINISHED"
		else:
			if restart_btn.is_connected("pressed", self, "_on_restart_game_pressed"):
				restart_btn.disconnect("pressed", self, "_on_restart_game_pressed")
			if not restart_btn.is_connected("pressed", self, "_on_next_pressed"):
				restart_btn.connect("pressed", self, "_on_next_pressed")
			restart_btn.text = "NEXT LEVEL"
			title.text = "TOURNAMENT SUMMARY"

	score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], true)

	var background_fadein_transparency: float = 1



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
