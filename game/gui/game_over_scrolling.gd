extends GameOver


func show_game_summary():
	# namen: druga statistika game summarya
	
	focus_btn = selected_game_summary.get_node("Menu/RestartBtn")

	# get stats
	selected_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
#	selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.game_data["level"])
	selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.current_level)
	selected_game_summary.get_node("DataContainer/Points").text %= str(p1_final_stats["player_points"])
	selected_game_summary.get_node("DataContainer/Time").text %= str(Global.hud.game_timer.time_since_start)
	selected_game_summary.get_node("DataContainer/CellsTraveled").text %= str(p1_final_stats["cells_traveled"])
	selected_game_summary.get_node("DataContainer/BurstCount").text %= str(p1_final_stats["burst_count"])
#	selected_game_summary.get_node("DataContainer/SkillsUsed").text %= str(p1_final_stats["skill_count"])
	selected_game_summary.get_node("DataContainer/PixelsOff").text %= str(p1_final_stats["colors_collected"])
#	selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
	
	selected_game_summary.visible = true	
	game_summary_holder.visible = true	
	game_summary_holder.modulate.a = 0

	# hide title and name_popup > show game summary
	var cross_fade = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	cross_fade.tween_property(name_input_popup, "modulate:a", 0, 0.5)
	cross_fade.parallel().tween_property(gameover_title_holder, "modulate:a", 0, 1)
	cross_fade.parallel().tween_property(background, "color:a", 1, 1)
	cross_fade.tween_callback(name_input_popup, "hide")
	cross_fade.parallel().tween_callback(gameover_title_holder, "hide")
	cross_fade.parallel().tween_property(game_summary_holder, "modulate:a", 1, 1)#.set_delay(1)
	cross_fade.tween_callback(Global, "grab_focus_no_sfx", [focus_btn])


# TITLES --------------------------------------------------------------	

		
func set_game_gameover_title():
	
	match current_gameover_reason:
		Global.game_manager.GameoverReason.CLEANED:
			selected_gameover_title = gameover_title_cleaned
			selected_gameover_jingle = "win_jingle"
			name_input_label.text = "Great work!"
		Global.game_manager.GameoverReason.LIFE:
			selected_gameover_title = gameover_title_life
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
		Global.game_manager.GameoverReason.TIME:
			selected_gameover_title = gameover_title_time
			selected_gameover_jingle = "lose_jingle"
			name_input_label.text = "But still ... "
