extends GameHud

	
func fade_in_instructions_popup(in_time: float):
	# namen: prilagojena navodila
	
	if Global.game_manager.game_data["game"] == Profiles.Games.CLEANER:
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Collect colors and beat the highscore"
		label.text = "Game is over when you are out of energy or time runs out"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is limited"
		label_5.text = "Highscore is the highest points total"
		label_6.text = ""
	elif Global.game_manager.game_data["game"] == Profiles.Games.CLEANER_DUEL:
		$Popups/Instructions/Controls.hide()
		$Popups/Instructions/ControlsDuel.show()
		title.text = Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
		win_label.text = "Surviving player or player with higher points total wins"
		label.text = "Game is over when a player loses all lives or time runs out"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is limited"
		label_5.text = "No highscores"
		label_6.text = ""
	else: # ERASERji
		$Popups/Instructions/Controls.show()
		$Popups/Instructions/ControlsDuel.hide()
		title.text = Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
		win_label.text = "Collect all available colors"
		label.text = "Game is over when you are out of energy"
		label_2.text = "Energy depletes with travelling or hitting a wall"
		label_3.text = "Bursting power affects the amount of collected colors in stack"
		label_4.text = "Time is unlimited"
		label_5.text = "Highscore is the fastest time"
		label_6.text = ""
					
	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)
