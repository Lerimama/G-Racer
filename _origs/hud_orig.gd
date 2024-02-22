extends Control


signal players_ready # za splitscreen popup

# spectrum
var picked_indicator_alpha: float = 1
var unpicked_indicator_alpha: float = 0.2
var neighbor_indicator_alpha: float = 0.4
var active_color_indicators: Array = [] # indikatorji spawnani že ob spawnanju pixlov

# hs
var current_highscore: int
var current_highscore_owner: String

# in/out
var hud_in_out_time: int = 2
var screen_height:int = 720
onready var header_height: int = $Header.rect_size.y
onready var viewport_header: ColorRect = $"%ViewHeder"
onready var viewport_footer: ColorRect = $"%ViewFuter"

# popups 
var p1_energy_warning_popup: Control
var p2_energy_warning_popup: Control
onready var energy_warning_holder: Control = $Popups/EnergyWarning
onready var splitscreen_popup: Control = $Popups/SplitScreens

# header
onready var header: Control = $Header # kontrole iz kamere
onready var game_timer: HBoxContainer = $Header/GameTimer
onready var highscore_label: Label = $Header/TopLineR/HighscoreLabel
onready var music_player: Label = $Header/TopLineR/MusicPlayer
# p1
onready var p1_label: Label = $Header/TopLineL/PlayerLabel
onready var p1_life_counter: HBoxContainer = $Header/TopLineL/LifeIcons
onready var p1_energy_counter: HBoxContainer = $Header/TopLineL/EnergyBar
onready var p1_points_holder: HBoxContainer = $Header/TopLineL/PointsHolder
onready var p1_points_counter: Label = $Header/TopLineL/PointsHolder/Points
onready var p1_color_holder: HBoxContainer = $Header/TopLineL/ColorHolder
onready var p1_color_counter: Label = $Header/TopLineL/ColorHolder/Label
onready var p1_skill_counter: Label = $Header/TopLineL/SkillHolder/Label
onready var p1_burst_counter: Label = $Header/TopLineL/BurstHolder/Label
onready var p1_steps_holder: HBoxContainer = $Header/TopLineL/StepsHolder
onready var p1_steps_counter: Label = $Header/TopLineL/StepsHolder/Label
# p2
onready var p2_statsline: HBoxContainer = $Header/TopLineR/PlayerLineR
onready var p2_life_counter: HBoxContainer = $Header/TopLineR/PlayerLineR/LifeIcons
onready var p2_energy_counter: HBoxContainer = $Header/TopLineR/PlayerLineR/EnergyBar
onready var p2_points_counter: Label = $Header/TopLineR/PlayerLineR/PointsHolder/Points
onready var p2_color_counter: Label = $Header/TopLineR/PlayerLineR/ColorHolder/Label
onready var p2_skill_counter: Label = $Header/TopLineR/PlayerLineR/SkillHolder/Label
onready var p2_burst_counter: Label = $Header/TopLineR/PlayerLineR/BurstHolder/Label
onready var p2_steps_holder: HBoxContainer = $Header/TopLineR/PlayerLineR/StepsHolder
onready var p2_steps_counter: Label = $Header/TopLineR/PlayerLineR/StepsHolder/Label

# futer
onready var footer: Control = $Footer # kontrole iz kamere
onready var game_label: Label = $Footer/FooterLine/GameLine/Game
onready var level_label: Label = $Footer/FooterLine/GameLine/Level
onready var astray_counter: Label = $Footer/FooterLine/StraysLine/AstrayHolder/Label
onready var picked_counter: Label = $Footer/FooterLine/StraysLine/PickedHolder/Label
onready var spectrum: HBoxContainer = $Footer/FooterLine/SpectrumHolder/ColorSpectrum
onready var ColorIndicator: PackedScene = preload("res://game/hud/hud_color_indicator.tscn")

# debug
onready var player_life: Label = $Life
onready var player_energy: Label = $Energy


func _input(event: InputEvent) -> void:
	
	# splitscreen popup
	if splitscreen_popup.visible and Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_disable_input(true) # anti dablklik
		Global.sound_manager.play_gui_sfx("btn_confirm")
		emit_signal("players_ready")
	
	
func _ready() -> void:
	
	Global.hud = self
	
	# pre-hud in pozicije
	header.rect_position.y = - header_height
	footer.rect_position.y = screen_height
		
	game_label.text = Global.game_manager.game_data["game_name"]
	level_label.text = Global.game_manager.game_data["level"]
	
	
func _process(delta: float) -> void:
	
	astray_counter.text = "%03d" % Global.game_manager.strays_in_game_count
	picked_counter.text = "%03d" % Global.game_manager.strays_cleaned_count


func update_stats(stat_owner: Node, player_stats: Dictionary):	
	
	# player stats
	match stat_owner.name:
		"p1":
			p1_life_counter.life_count = player_stats["player_life"]
			p1_energy_counter.energy = player_stats["player_energy"]
			p1_points_counter.text = "%d" % player_stats["player_points"]
			p1_color_counter.text = "%d" % player_stats["colors_collected"]
			p1_burst_counter.text = "%d" % player_stats["burst_count"]
			p1_skill_counter.text = "%d" % player_stats["skill_count"]
			p1_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p1_energy_warning_popup)
		"p2":
			p2_life_counter.life_count = player_stats["player_life"]
			p2_energy_counter.energy = player_stats["player_energy"]
			p2_points_counter.text = "%d" % player_stats["player_points"]
			p2_color_counter.text = "%d" % player_stats["colors_collected"]
			p2_burst_counter.text = "%d" % player_stats["burst_count"]
			p2_skill_counter.text = "%d" % player_stats["skill_count"]
			p2_steps_counter.text = "%d" % player_stats["cells_traveled"]
			check_for_warning(player_stats, p2_energy_warning_popup)

	# debug
	player_life.text = "LIFE: %d" % player_stats["player_life"]
	player_energy.text = "E: %d" % player_stats["player_energy"]

	if Global.game_manager.game_settings["manage_highscores"]:
		check_for_hs(player_stats)
	

func check_for_hs(player_stats: Dictionary):
	
	if player_stats["player_points"] > current_highscore: 
		highscore_label.text = "New highscore " + str(player_stats["player_points"])
		highscore_label.modulate = Global.color_green
	else:
		highscore_label.text = "Highscore " + str(current_highscore)
		highscore_label.modulate = Global.hud_text_color
		

func check_for_warning(player_stats: Dictionary, warning_popup: Control):
	
	if warning_popup:
		var steps_remaining_label: Label
		steps_remaining_label = warning_popup.get_node("StepsRemaining")
	
		if player_stats["player_energy"] == 0:
			if warning_popup.visible == true:
				warning_out(warning_popup)		
		elif player_stats["player_energy"] == 1:
			steps_remaining_label.text = "NO ENERGY! Collect a color to revitalize."
		elif player_stats["player_energy"] == 2: # pomeni samo še en korak in rabim ednino
			steps_remaining_label.text = "ENERGY WARNING! Only 1 step remaining."
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] <= Global.game_manager.game_settings["player_tired_energy"]:
			steps_remaining_label.text = "ENERGY WARNING! Only %s steps remaining." % str(player_stats["player_energy"] - 1)
			if warning_popup.visible == false:
				warning_in(warning_popup)
		elif player_stats["player_energy"] > Global.game_manager.game_settings["player_tired_energy"]:
			if warning_popup.visible == true:
				warning_out(warning_popup)


func warning_in(warning_popup: Control):
	
	var warning_in = get_tree().create_tween()
	warning_in.tween_callback(energy_warning_holder, "show")
	warning_in.tween_callback(warning_popup, "show")
	warning_in.tween_property(warning_popup, "modulate:a", 1, 0.3) #.from(0.0)


func warning_out(warning_popup: Control):
	
	var warning_out = get_tree().create_tween()
	warning_out.tween_property(warning_popup, "modulate:a", 0, 0.5)
	warning_out.tween_callback(warning_popup, "hide")
	warning_out.tween_callback(energy_warning_holder, "hide")


func popups_out(): # kliče GM na gameover
	
	var popups_out = get_tree().create_tween()
	popups_out.tween_property($Popups, "modulate:a", 0, 0.5)
	popups_out.tween_callback($Popups, "hide")

	
func slide_in(players_count: int): # kliče GM set_game()
	
	set_hud(players_count)
	
	get_tree().call_group(Global.group_player_cameras, "zoom_in", hud_in_out_time, players_count)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", Global.hud.header_height, hud_in_out_time)
	
	yield(Global.player1_camera, "zoomed_in")
	
	for indicator in active_color_indicators:
		var indicator_fade_in = get_tree().create_tween()
		indicator_fade_in.tween_property(indicator, "modulate:a", unpicked_indicator_alpha, 0.3).set_ease(Tween.EASE_IN)
	
	if players_count == 2:
		fade_splitscreen_popup()
	else:
		Global.start_countdown.start_countdown() # GM yielda za njegov signal


func slide_out(): # kliče GM na game over
	
	get_tree().call_group(Global.group_player_cameras, "zoom_out", hud_in_out_time)
	
	var fade_in = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD) # trans je ista kot tween na kameri
	fade_in.tween_property(header, "rect_position:y", 0 - header_height, hud_in_out_time)
	fade_in.parallel().tween_property(footer, "rect_position:y", screen_height, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_header, "rect_min_size:y", 0, hud_in_out_time)
	fade_in.parallel().tween_property(viewport_footer, "rect_min_size:y", 0, hud_in_out_time)
	fade_in.tween_callback(self, "hide")
	

# SET HUD ---------------------------------------------------------------------------------------------------------------------------


func set_hud(players_count: int): # kliče main na game-in
	
	if players_count == 1:
		# players
		p1_label.visible = false
		p2_statsline.visible = false
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/Solo
		
		# hs
		if Global.game_manager.game_settings["manage_highscores"]:
			highscore_label.visible = true
			set_current_highscore()
		elif Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
			highscore_label.visible = true
		else:
			highscore_label.visible = false
	
	elif players_count == 2:
		# players
		p1_label.visible = true
		p2_statsline.visible = true
		# popups
		p1_energy_warning_popup = $Popups/EnergyWarning/DuelP1
		p2_energy_warning_popup = $Popups/EnergyWarning/DuelP2
		# hs		
		highscore_label.visible = false
		
	# lajf counter
	if Global.game_manager.game_settings["player_start_life"] == 1:
		p1_life_counter.visible = false
		p2_life_counter.visible = false
	else:
		p1_life_counter.visible = true
		p2_life_counter.visible = true
	
	# level label	
	if Global.game_manager.game_data["level"].empty():
		level_label.visible = false
	
	# scrolling game 	
	if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
#		spawn_color_indicators(10)
		pass
		
		
func set_current_highscore():
	
	var current_game = Global.game_manager.game_data["game"]
	var current_highscore_line: Array = Global.data_manager.get_top_highscore(current_game)
	
	current_highscore = current_highscore_line[0]
	current_highscore_owner = current_highscore_line[1]
	
	highscore_label.text = "Highscore " + str(current_highscore) # se apdejta ob signalu iz plejerja (ob konektanju na začetku?)

		
func fade_splitscreen_popup():
	
	var show_splitscreen_popup = get_tree().create_tween()
	show_splitscreen_popup.tween_callback(splitscreen_popup, "show")
	show_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 1, 1).from(0.0).set_ease(Tween.EASE_IN)

	yield(self, "players_ready")
	
	var hide_splitscreen_popup = get_tree().create_tween()
	hide_splitscreen_popup.tween_property(splitscreen_popup, "modulate:a", 0, 1).set_ease(Tween.EASE_IN)
	hide_splitscreen_popup.tween_callback(splitscreen_popup, "hide")
	hide_splitscreen_popup.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik
	hide_splitscreen_popup.tween_callback(Global.start_countdown, "start_countdown")	
		

# LEVEL INDICATORS -------------------------------------------------------------------------------------------------------------------

#
#func spawn_level_indicators(level_stages_count: int): # kliče GM
#
#	var indicator_index = 0 # za fiksirano zaporedje
#
#	for stage in level_stages_count:
#		indicator_index += 1 
#		# spawn indicator
#		var new_color_indicator = ColorIndicator.instance()
#		new_color_indicator.color = color
#		new_color_indicator.modulate.a = 1 # na fade-in se odfejda do unpicked_indicator_alpha
#		spectrum.add_child(new_color_indicator)
#		active_color_indicators.append(new_color_indicator)


# SPECTRUM ---------------------------------------------------------------------------------------------------------------------------


func spawn_color_indicators(available_colors: Array): # kliče GM
	
	var indicator_index = 0 # za fiksirano zaporedje
	
	for color in available_colors:
		indicator_index += 1 
		# spawn indicator
		var new_color_indicator = ColorIndicator.instance()
		new_color_indicator.color = color
		if not Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
			new_color_indicator.modulate.a = 1 # na fade-in se odfejda do unpicked_indicator_alpha
		else:
			new_color_indicator.modulate.a = 0.3
		spectrum.add_child(new_color_indicator)
		active_color_indicators.append(new_color_indicator)

		# new_color_indicator.get_node("IndicatorCount").text = str(indicator_index) # debug ... zapis indexa

					
func show_color_indicator(picked_color: Color):
	
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


func show_stage_indicator(stage_number: int):

	if not active_color_indicators.empty():
		var current_indicator = active_color_indicators.front()
		current_indicator.modulate.a = 1
		# izbris iz aktivnih indikatorjev
		active_color_indicators.pop_front()
	else:
		if stage_number < 9:
			var color_scheme_name: String = "color_scheme_%s" % stage_number
			Profiles.current_color_scheme = Profiles.game_color_schemes[color_scheme_name]
			for child in spectrum.get_children():
				child.queue_free()
			Global.game_manager.set_scrolling_stage_indicator()
			show_stage_indicator(1)
		else:
			Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)



# SIGNALS ---------------------------------------------------------------------------------------------------------------------------


func _on_GameTimer_sudden_death_active() -> void:
	pass


func _on_GameTimer_gametime_is_up() -> void:
	
	Global.game_manager.game_over(Global.game_manager.GameoverReason.TIME)


func _on_stat_changed(stat_owner: Node, current_player_stats: Dictionary):
	
	update_stats(stat_owner, current_player_stats)
