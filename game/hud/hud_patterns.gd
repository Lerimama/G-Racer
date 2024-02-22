extends GameHud

	
func set_hud(players_count: int): # kliče main na game-in
	# namen: ikone v player statline, samo 1 player, ni lajfov, ni energije, level data je vis tudi če je prazen, energy counter

	# players
	p1_label.visible = false
	p2_statsline.visible = false
#	strays_counters_holder.visible = false
	
	# if Global.game_manager.game_data["game"] == Profiles.Games.SLIDER:
#	p1_color_holder.visible = false	

	# popups
	p1_energy_warning_popup = $Popups/EnergyWarning/Solo	

	# lajf counter
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
	else:
		p1_life_counter.visible = true

	# energy counter
	if Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:
		p1_energy_counter.visible = true
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		p1_energy_counter.visible = false

	# level label
	if Global.game_manager.game_data["level"].empty():
		level_label.visible = false

	# glede na to kaj šteje ...
	if current_gamed_hs_type == Profiles.HighscoreTypes.NO_HS:
		highscore_label.visible = false
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH or Global.game_manager.game_data["highscore_type"] == Profiles.HighscoreTypes.HS_TIME_LOW:
		p1_points_holder.visible = false
		highscore_label.visible = true
		set_current_highscore()
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_POINTS:
		p1_points_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()
	elif current_gamed_hs_type == Profiles.HighscoreTypes.HS_COLORS:
		p1_points_holder.visible = false
		p1_color_holder.visible = true
		highscore_label.visible = true
		set_current_highscore()
	
	
func slide_in(players_count: int): # kliče GM set_game()
	# namen: indikatorji ostanejo alpha 1, start countdown po zoominu
	
	var indicator_alpha_on_start: float
	if Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:	
		indicator_alpha_on_start = 1
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		indicator_alpha_on_start = 0.3
	
	set_hud(players_count)
	
	# instructions popup
	if Global.game_manager.game_settings["game_instructions_popup"]:
		var instructions_popup_time: float = 0.7
		fade_in_instructions_popup(instructions_popup_time)
		yield(self, "players_ready")
		fade_out_instructions_popup(instructions_popup_time)
		yield(get_tree().create_timer(instructions_popup_time), "timeout")
	
	Global.start_countdown.start_countdown() # GM yielda za njegov signal
	
	get_tree().call_group(Global.group_player_cameras, "zoom_in", hud_in_out_time, players_count)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	
	# yield(Global.player1_camera, "zoomed_in") ... namesto tega signaliziranje prevzame start countdown
	
	for indicator in active_color_indicators:
		var indicator_fade_in = get_tree().create_tween()
		indicator_fade_in.tween_property(indicator, "modulate:a", unpicked_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
	
	
func show_color_indicator(picked_color: Color):
	# namen: pobrani indikatorji potemnijo

	if Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:	
		picked_indicator_alpha = 0.3
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		picked_indicator_alpha = 1

	var current_indicator_index: int
	for indicator in active_color_indicators:
		# pobrana barva
		if indicator.color == picked_color:
			current_indicator_index = active_color_indicators.find(indicator)
			indicator.modulate.a = picked_indicator_alpha
			break

	# izbris iz aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.erase(active_color_indicators[current_indicator_index])


func deactivate_all_indicators():

	if Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:	
		picked_indicator_alpha = 0.3
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		picked_indicator_alpha = 1	
	
	for indicator in active_color_indicators:
		indicator.modulate.a = picked_indicator_alpha
		# animacija deaktivacije
		var current_indicator_index: int = active_color_indicators.find(indicator)
		if current_indicator_index % 20 == 0:
			yield(get_tree().create_timer(0.05), "timeout")

	# izbris aktivnih indikatorjev
	if not active_color_indicators.empty():
		active_color_indicators.clear()

	
func fade_in_instructions_popup(in_time: float):
	# namen: prilagojena navodila
	
	$Popups/Instructions/Controls.show()
	$Popups/Instructions/ControlsDuel.hide()
	
	if Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:
		title.text = Global.game_manager.game_data["game_name"]
		win_label.text = "Get through the maze and hit the white pixel on the other side"
		label.text = "Game is over when you are out of energy"
		label_2.text = "Energy depletes with travelling, touching stray pixels or upon hitting a wall"
		label_3.text = "Bursting always collects all colors in stack"
		label_4.text = "Time is unlimited"
		label_5.text = "Highscore is fastest time"
		label_6.text = ""
	else: # RIDDLERs
		title.text = Global.game_manager.game_data["game_name"] + " " + Global.game_manager.game_data["level"]
		win_label.text = "Collect all colors with a single burst"
		label.text = "Game is over when you burst and don't collect all available colors"
		label_2.text = "Energy and speed are constant"
		label_3.text = "Bursting always collects all colors in stack"
		label_4.text = "Time is unlimited"
		label_5.text = "Highscore is fastest time"
		label_6.text = ""
		
						
	var show_instructions_popup = get_tree().create_tween()
	show_instructions_popup.tween_callback(instructions_popup, "show")
	show_instructions_popup.tween_property(instructions_popup, "modulate:a", 1, in_time).from(0.0).set_ease(Tween.EASE_IN)
