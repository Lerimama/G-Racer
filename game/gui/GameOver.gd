extends Control


onready var level_finished: Control = $LevelFinished
onready var level_finished_score_table: VBoxContainer = $LevelFinished/ScoreTable
onready var level_finished_title: Label = $LevelFinished/Title
onready var level_record_label: Label = $LevelFinished/LevelRecord

onready var game_summary: Control = $GameSummary
onready var game_summary_title: Label = $GameSummary/Title
onready var game_summary_score_table: VBoxContainer = $GameSummary/ScoreTable


func set_level_finished(game: Game):

	var level_index: int = game.level_index
	var levels_count: int = Sets.game_levels.size()

	# level or game finished
	if game.game_stage == game.GAME_STAGE.FINISHED_FAIL:
		level_finished_title.text = "GAME OVER"
		level_finished_title.modulate = Refs.color_red
	else:
		level_finished_title.text = "LEVEL FINISHED"
		level_finished_title.modulate = Refs.color_green

	if "level_record" in game.level_profile:
		var level_record: Array = game.level_profile["level_record"]
		if not level_record[0] == 0:
			var level_record_clock_time: String = Mets.get_clock_time_string(level_record[0])
			level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(level_record[1])
			level_record_label.show()
		else:
			level_record_label.hide()
	else:
		level_record_label.hide()

	level_finished_score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], false)


func set_summary(game: Game):

	var level_index: int = game.level_index
	var levels_count: int = Sets.game_levels.size()

	# fai
	if game.game_stage == game.GAME_STAGE.FINISHED_FAIL:
		game_summary_title.text = "TOURNAMENT OVER"
		game_summary_title.modulate = Refs.color_red
	# success
	else:
		game_summary_title.modulate = Refs.color_green
		# zadnji
		if level_index == levels_count - 1:
			game_summary_title.text = "TOURNAMENT FINISHED"
		else:
			game_summary_title.text = "TOURNAMENT SUMMARY"

	game_summary_score_table.set_scoretable(game.game_drivers_data, game.level_profile["rank_by"], true)



