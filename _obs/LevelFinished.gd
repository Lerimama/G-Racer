extends Control


#var drivers_data: Dictionary = {}
#var level_data: Dictionary = {}
#
#onready var background: ColorRect = $Background
#onready var score_table: VBoxContainer = $ScoreTable
#onready var title: Label = $Title
#onready var level_record_label: Label = $LevelRecord
#onready var gui: Gui = get_parent().get_parent()
#
#
#func set_level_finished(game: Game):
#
#	drivers_data = game.game_drivers_data
#	var level_index: int = game.level_index
#	var levels_count: int = game.game_levels.size()
#
#	# level or game finished
#	if game.game_stage == game.GAME_STAGE.FINISHED_FAIL:
#		title.text = "LEVEL OVER"
#		title.modulate = Refs.color_red
#	else:
#		title.text = "LEVEL FINISHED"
#		title.modulate = Refs.color_green
#
#	if "level_record" in game.level_profile:
#		var level_record: Array = game.level_profile["level_record"]
#		if not level_record[0] == 0:
#			var level_record_clock_time: String = Mets.get_clock_time_string(level_record[0])
#			level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(level_record[1])
#			level_record_label.show()
#		else:
#			level_record_label.hide()
#	else:
#		level_record_label.hide()
#
#	score_table.set_scoretable(drivers_data, game.level_profile["rank_by"], false)
#
#	var background_fadein_transparency: float = 1
