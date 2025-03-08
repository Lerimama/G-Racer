extends Control


var final_level_data: Dictionary = {}
var still_driving_ids: Array = []

onready var content: Control = $Content
onready var background: ColorRect = $Background
onready var scorelist: VBoxContainer = $Content/Scorelist


func _ready() -> void:

	hide()


func open(level_data: Dictionary):

	final_level_data = level_data

	# če je kakšen (ai) prazen, ga dodam me prazne
	still_driving_ids = []
	for driver_id in final_level_data:
		if not driver_id == "level_data":
			if final_level_data[driver_id].empty():
				still_driving_ids.append(driver_id)

	scorelist.set_scorelist(final_level_data)

	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	yield(fade_in, "finished")

	$Menu/ContinueBtn.grab_focus()
	$Menu/QuitBtn.set_disabled(false)
	$Menu/ContinueBtn.set_disabled(false)


func _process(delta: float) -> void:

	# čakam, da se spremeni število in apdejtam
	var still_driving_count: int = still_driving_ids.size()
	for driver_id in still_driving_ids:
		if not final_level_data[driver_id].empty():
			still_driving_ids.erase(driver_id)

	if not still_driving_ids.size() == still_driving_count:
		scorelist.update_scorelines(final_level_data)


func _apply_final_data_and_hide(what_to_do: int):

	get_parent().game_manager.apply_waiting_ai_final_data()

	still_driving_ids.clear()
	scorelist.update_scorelines(final_level_data)

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


