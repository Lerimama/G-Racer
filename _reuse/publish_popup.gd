extends Control

signal score_published

var game_global_leaderboard_key: String # enum ime igre

onready var skip_btn: Button = $HBoxContainer/SkipBtn
onready var publish_btn: Button = $HBoxContainer/PublishBtn


func _ready() -> void:

	hide()
	publish_btn.add_to_group(Global.group_menu_confirm_btns)
	skip_btn.add_to_group(Global.group_menu_cancel_btns)


func open_popup(game_data: Dictionary):
	
	var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_callback(self, "show")	
	fade_in.tween_property(self, "modulate:a", 1, 0.5)
	publish_btn.grab_focus()


func close_popup():
	
	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(self, "modulate:a", 0, 0.5)	
	fade_out.tween_callback(self, "hide")	
	
	ConnectCover.close_cover() # ... animiram ga v nivoju višje višje
	
	
func _on_PublishBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	skip_btn.disabled = true # zazih
	publish_btn.disabled = true # zazih
	$Label.modulate.a = 0.32 # disabled theme color
	
	get_tree().set_pause(false) # da lahko procedura steče
	get_focus_owner().release_focus()
	var publish_name: String = Global.gameover_gui.p1_final_stats["player_name"]
	var publish_score: float = Global.gameover_gui.player_final_score
	var publish_game_data: Dictionary = Global.game_manager.game_data
	LootLocker.publish_score_to_lootlocker(publish_name, publish_score, publish_game_data)
	yield(LootLocker, "connection_closed")
	ConnectCover.cover_label_text = "Finished"
	yield(get_tree().create_timer(LootLocker.final_panel_open_time), "timeout")
#	ConnectCover.close_cover() # ... animiram ga v nivoju višje višje
	
	emit_signal("score_published")
	get_tree().set_pause(true) # spet setano čez celotno GO proceduro

func _on_SkipBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("btn_cancel")
	emit_signal("score_published")
	

