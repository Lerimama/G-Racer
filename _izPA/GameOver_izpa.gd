extends Control
class_name GameOver

signal name_input_finished

var focus_btn: Button
var current_gameover_reason: int # za prenašanje
onready var background: ColorRect = $Background

# players
var players_in_game: Array
var p1_final_stats: Dictionary
var p2_final_stats: Dictionary

# gameover title
var selected_gameover_title: Control
var selected_gameover_menu: Control
var selected_gameover_jingle: String

onready var gameover_title_holder: Control = $GameoverTitle
onready var gameover_title_cleaned: Control = $GameoverTitle/ReasonCleaned
onready var gameover_title_time: Control = $GameoverTitle/ReasonTime
onready var gameover_title_life: Control = $GameoverTitle/ReasonLife
onready var gameover_title_duel: Control = $GameoverTitle/Duel
#onready var gameover_title_tutorial: Control = $GameoverTitle/Tutorial

# game summary
var selected_game_summary: Control
onready var game_summary_holder: Control = $GameSummary
onready var game_summary_no_hs: Control = $GameSummary/NoHS
onready var game_summary_with_hs: Control = $GameSummary/WithHS
onready var highscore_table: VBoxContainer = $GameSummary/WithHS/HighscoreTable

# name input
var input_invite_text: String = "..."
var input_string: String # = "" # neki more bit, če plejer nč ne vtipka in potrdi predvsem, da zaznava vsako črko in jo lahko potrdiš na gumbu
onready var name_input_popup: Control = $NameInputPopup
onready var name_input: LineEdit = $NameInputPopup/NameInput
onready var name_input_label: Label = $NameInputPopup/Label


func _input(event: InputEvent) -> void:

	if name_input_popup.visible == true and name_input_popup.modulate.a == 1:
		if Input.is_action_just_pressed("ui_cancel"):
			_on_CancelBtn_pressed()
			accept_event()
	
	# change focus sounds
	if (selected_gameover_menu != null and selected_gameover_menu.modulate.a == 1) or (selected_game_summary != null and selected_game_summary.visible and selected_game_summary.modulate.a == 1):
		if Input.is_action_just_pressed("ui_left"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
		elif Input.is_action_just_pressed("ui_right"):
			Global.sound_manager.play_gui_sfx("btn_focus_change")
			
				
func _ready() -> void:
	
	Global.gameover_menu = self
	
	visible = false
	gameover_title_holder.visible = false
	game_summary_holder.visible = false
	name_input_popup.visible = false
	
	
func open_gameover(gameover_reason: int):
	
	current_gameover_reason = gameover_reason
	players_in_game = get_tree().get_nodes_in_group(Global.group_players)
	
	p1_final_stats = players_in_game[0].player_stats
	
	if players_in_game.size() == 2:
		p2_final_stats = players_in_game[1].player_stats
		set_duel_gameover_title()
	else:
		set_game_gameover_title()
		
	Global.hud.slide_out()
	yield(Global.player1_camera, "zoomed_out") # tukaj notri setam zamik
	show_gameover_title()	


func show_gameover_title():

	# get_tree().call_group(Global.group_players, "set_physics_process", false) ... old
	
	visible = true
	selected_gameover_title.visible = true
	gameover_title_holder.modulate.a = 0
	
	var background_fadein_transparency: float = 0.85 # cca 217
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(gameover_title_holder, "show")
	fade_in.tween_property(gameover_title_holder, "modulate:a", 1, 1)
	fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property(background, "color:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)
	

func show_gameover_menu():
	
	get_tree().set_pause(true) # setano čez celotno GO proceduro
	
	if players_in_game.size() == 2 or Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
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
			if Global.game_manager.game_data["game_name"] == "Eraser" and not current_gameover_reason == Global.game_manager.GameoverReason.CLEANED: 
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


func show_game_summary():
	
	focus_btn = selected_game_summary.get_node("Menu/RestartBtn")

	# get stats
	selected_game_summary.get_node("DataContainer/Game").text %= str(Global.game_manager.game_data["game_name"])
	selected_game_summary.get_node("DataContainer/Level").text %= str(Global.game_manager.game_data["level"])
	selected_game_summary.get_node("DataContainer/Points").text %= str(p1_final_stats["player_points"])
	selected_game_summary.get_node("DataContainer/Time").text %= str(Global.hud.game_timer.time_since_start)
	selected_game_summary.get_node("DataContainer/CellsTraveled").text %= str(p1_final_stats["cells_traveled"])
	selected_game_summary.get_node("DataContainer/BurstCount").text %= str(p1_final_stats["burst_count"])
	selected_game_summary.get_node("DataContainer/SkillsUsed").text %= str(p1_final_stats["skill_count"])
	selected_game_summary.get_node("DataContainer/PixelsOff").text %= str(p1_final_stats["colors_collected"])
	selected_game_summary.get_node("DataContainer/AstrayPixels").text %= str(Global.game_manager.strays_in_game_count)
	
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

		
func set_duel_gameover_title():
	
	selected_gameover_title = gameover_title_duel
	selected_gameover_menu = selected_gameover_title.get_node("Menu")
	focus_btn = selected_gameover_menu.get_node("RestartBtn")
	selected_gameover_jingle = "win_jingle"

	var winner_label: Label = selected_gameover_title.get_node("Win/PlayerLabel")
	var winning_reason_label: Label = selected_gameover_title.get_node("Win/ReasonLabel")
	var loser_name: String
	var draw_label: Label = selected_gameover_title.get_node("Draw/DrawLabel")
	
	# če je kdo brez lajfa, zmaga preživeli
	if p1_final_stats["player_life"] == 0 and p2_final_stats["player_life"] > 0: # P1 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 1"
		loser_name = "Player 2"
		winning_reason_label.text = "Player 1 cleaned Player 2"
		return
	elif p2_final_stats["player_life"] == 0 and p1_final_stats["player_life"] > 0: # P2 zmaga
		selected_gameover_title.get_node("Win").visible = true
		winner_label.text = "Player 2"
		loser_name = "Player 1"
		winning_reason_label.text = "Player 2 cleaned Player 1"
		return
	 
	# če sta oba preživela ali oba umrla
	var points_difference: int = p1_final_stats["player_points"] - p2_final_stats["player_points"]
	if points_difference == 0: # draw
		selected_gameover_title.get_node("Draw").visible = true
		draw_label.text = "You both collected the same amount of points."
	else: # win
		selected_gameover_title.get_node("Win").visible = true
		if points_difference > 0: # P1 zmaga
			winner_label.text = "Player 1"
			loser_name = "Player 2"
		elif points_difference < 0: # P2 zmaga
			winner_label.text = "Player 2"
			loser_name = "Player 1"
		if abs(points_difference) == 1:
			winning_reason_label.text = winner_label.text + " was better by only one point"
		else: 
			winning_reason_label.text =  winner_label.text + " was " + str(abs(points_difference)) + " points better than " + loser_name + ""# + " points."
		
			
func set_game_gameover_title():
	
	if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
		var gameover_title_tutorial: Control = $GameoverTitle/Tutorial
		match current_gameover_reason:
			Global.game_manager.GameoverReason.CLEANED:
				gameover_title_tutorial.get_node("Finished").show()
				selected_gameover_title = gameover_title_tutorial
				selected_gameover_jingle = "win_jingle"
			Global.game_manager.GameoverReason.LIFE:
				gameover_title_tutorial.get_node("NotFinished").show()
				selected_gameover_title = gameover_title_tutorial
				selected_gameover_jingle = "lose_jingle"
		selected_gameover_menu = selected_gameover_title.get_node("Menu")
		focus_btn = selected_gameover_menu.get_node("QuitBtn")
	else:
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
	
	
# NAME INPUT --------------------------------------------------------------------	


func open_name_input():
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	
	name_input_popup.visible = true
	name_input_popup.modulate.a = 0

	var fade_in_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.tween_property(name_input_popup, "modulate:a", 1, 0.5)
	
	# setam input label
	name_input.text = input_invite_text
	
	Global.grab_focus_no_sfx(name_input)
	name_input.select_all()
	
	
func confirm_name_input():
	
	# pogrebam string in zapišem ime v končno statistiko igralca
	p1_final_stats["player_name"] = input_string
	close_name_input()

	
func close_name_input ():
	
	name_input.editable = false
	emit_signal("name_input_finished") # sporočim DM, da sem končal (ime povleče iz GO stats) ... on kliče "highscores_updated"
	

func _on_NameEdit_text_changed(new_text: String) -> void:
	
	# signal, ki redno beleži vnešeni string
	input_string = new_text
	Global.sound_manager.play_gui_sfx("typing")

	
func _on_PopupNameEdit_text_entered(new_text: String) -> void: # ko stisneš return
	
	_on_ConfirmBtn_pressed()

	
func _on_ConfirmBtn_pressed() -> void:

	Global.grab_focus_no_sfx($NameInputPopup/HBoxContainer/ConfirmBtn)
	get_viewport().set_disable_input(true) # anti dablklik
	
	Global.sound_manager.play_gui_sfx("btn_confirm")
	
	if input_string == input_invite_text or input_string.empty():
		input_string = p1_final_stats["player_name"]
		confirm_name_input()
	else:
		confirm_name_input()
		

func _on_CancelBtn_pressed() -> void:
	
	Global.grab_focus_no_sfx($NameInputPopup/HBoxContainer/CancelBtn)
	get_viewport().set_disable_input(true) # anti dablklik
	close_name_input()


# MENU ---------------------------------------------------------------------------------------------


func _on_RestartBtn_pressed() -> void:

	Global.main_node.reload_game()
	
	
func _on_QuitBtn_pressed() -> void:

	Global.main_node.game_out()
