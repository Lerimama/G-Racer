extends Control


var final_level_data: Dictionary = {}
var waiting_driver_name_ids: Array = []

onready var FinalRankingLine: PackedScene = preload("res://game/gui/FinalRankingLine.tscn")
onready var content: Control = $Content
onready var results: VBoxContainer = $Content/Results
onready var background: ColorRect = $Background



func _ready() -> void:

	hide()


func open(level_data: Dictionary):

	final_level_data = level_data

	# če je kakšen (ai) prazen, ga dodam me prazne
	for driver_name_id in final_level_data:
		if final_level_data[driver_name_id].empty():
			if not driver_name_id in waiting_driver_name_ids:
				waiting_driver_name_ids.append(driver_name_id)

	_set_scorelist()


	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	yield(fade_in, "finished")
	$Menu/ContinueBtn.grab_focus()
	$Menu/QuitBtn.set_disabled(false)
	$Menu/ContinueBtn.set_disabled(false)


func _process(delta: float) -> void:

	for driver_name_id in waiting_driver_name_ids:
		var waiting_driver_data: Dictionary = final_level_data[driver_name_id]
		if not waiting_driver_data.empty():
			waiting_driver_name_ids.erase(driver_name_id)
			_set_scorelist()


func _set_scorelist():

	for child in results.get_children(): child.queue_free()

	# uvrščeni
	var drivers_ranked: Array = []
	for driver_data in final_level_data:
		if not final_level_data[driver_data].empty():
			if not final_level_data[driver_data]["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
				drivers_ranked.append(final_level_data[driver_data])
	# sortiram uvrščene
	drivers_ranked.sort_custom(self, "_sort_driver_data_by_rank")

	# dodam ai, ki jih še čakam
	for driver_data in final_level_data:
		if final_level_data[driver_data].empty():
			drivers_ranked.append(final_level_data[driver_data])
	# dodam neurvščene ... brezzaporedno
	for driver_data in final_level_data:
		if not final_level_data[driver_data].empty():
			if final_level_data[driver_data]["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
				drivers_ranked.append(final_level_data[driver_data])

	# spawnam scoreline
	for ranked_driver_data in drivers_ranked:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		new_ranking_line.get_node("Driver").text = final_level_data.find_key(ranked_driver_data)
		if ranked_driver_data.empty():
			new_ranking_line.get_node("Rank").text = "..."
			new_ranking_line.get_node("Result").text = "... waiting"
		elif ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			new_ranking_line.get_node("Rank").text = "NN"
			new_ranking_line.get_node("Result").text = "timeless"
		else:
			new_ranking_line.get_node("Rank").text = str(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK]) + ". Place"
			new_ranking_line.get_node("Result").text = Mts.get_clock_time(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_TIME])
		results.add_child(new_ranking_line)


func _sort_driver_data_by_rank(driver_data_1: Dictionary, driver_data_2: Dictionary): # ascecnd a1 < a2
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_rank: int = driver_data_1["driver_stats"][Pfs.STATS.LEVEL_RANK]
	var driver_2_rank: int = driver_data_2["driver_stats"][Pfs.STATS.LEVEL_RANK]
	if driver_1_rank < driver_2_rank:
		return true
	return false


func _apply_final_data_and_hide(what_to_do: int):

	get_parent().game_manager.apply_waiting_ai_final_data()
	_set_scorelist()

	get_viewport().set_disable_input(true)
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(get_parent().game_cover, "modulate:a", 1, 0.3)
	yield(fade_tween, "finished")
	yield(get_tree().create_timer(2), "timeout")

	get_parent().back_to_what(what_to_do)
	get_viewport().set_disable_input(false)
	hide()


func _on_ContinueBtn_pressed() -> void:
	$Menu/ContinueBtn.set_disabled(true)
	_apply_final_data_and_hide(1)


func _on_QuitBtn_pressed() -> void:

	$Menu/QuitBtn.set_disabled(true)
	_apply_final_data_and_hide(-1)


func _on_QuitGameBtn_pressed() -> void:

	get_tree().quit()


