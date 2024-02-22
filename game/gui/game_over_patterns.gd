extends GameOver



func show_gameover_menu():
	# namen: izločim beleženje HS, če runner ali riddler ni končan
	
	get_tree().set_pause(true) # setano čez celotno GO proceduro
	
	if players_in_game.size() == 2:
		selected_gameover_menu.visible = false
		selected_gameover_menu.modulate.a = 0
		var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		fade_in.tween_callback(selected_gameover_menu, "show")#.set_delay(1)
		fade_in.tween_property(selected_gameover_menu, "modulate:a", 1, 1)
		fade_in.parallel().tween_callback(Global, "grab_focus_no_sfx", [focus_btn])		
	else:	
		
		var current_highscore_type: int = Global.game_manager.game_data["highscore_type"]
		var current_player_ranking: int
		
		if current_highscore_type == Profiles.HighscoreTypes.NO_HS:
			selected_game_summary = game_summary_no_hs
			yield(get_tree().create_timer(1), "timeout") # podaljšam pavzo za branje
			show_game_summary()
		else:
			var current_score_points: int = p1_final_stats["player_points"]
			var current_score_time: int = Global.hud.game_timer.time_since_start
			
			# yield čaka na konec preverke ... tip ni opredeljen, ker je ranking, če ni skora kot objecta, če je ranking
			var score_is_ranking = Global.data_manager.manage_gameover_highscores(current_score_points, current_score_time, Global.game_manager.game_data) 
			
			# score štejem samo če vse spuca
			if not current_gameover_reason == Global.game_manager.GameoverReason.CLEANED: 
				yield(get_tree().create_timer(1), "timeout")
				current_player_ranking = 100 # zazih ni na lestvici
			else:
				if score_is_ranking: # manage_gameover_highscores počaka na signal iz name_input
					open_name_input()
					yield(Global.data_manager, "highscores_updated")
					get_viewport().set_disable_input(false) # anti dablklik
					current_player_ranking = Global.data_manager.current_player_ranking
			
			highscore_table.get_highscore_table(Global.game_manager.game_data, current_player_ranking)
			selected_game_summary = game_summary_with_hs
			show_game_summary()
