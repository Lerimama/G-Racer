extends Node

	
var players_activated: Array
var enemies_mode: bool 
var easy_mode: bool 
var arena_on = false

onready var animation_player: AnimationPlayer = $AnimationPlayer

# main
onready var play_btn: Button = $UI/MainMenu/Menu/PlayBtn
onready var settings_btn: Button = $UI/MainMenu/Menu/SettingsBtn
onready var about_btn: Button = $UI/MainMenu/Menu/AboutBtn
onready var quit_btn: Button = $UI/MainMenu/Menu/QuitBtn
# arena
onready var generate_arena_btn: Button = $UI/Arena/GenerateBtn
onready var arena_confirm_btn: Button = $UI/Arena/ConfirmBtn
onready var temp_back_btn: Button = $UI/Arena/temp_BackBtn
# generate
onready var arena_world: PackedScene = preload("res://home/ArenaGenerator.tscn")
onready var arena_view: Panel = $UI/Arena/ArenaView
onready var new_world # : InstancePlaceholder
onready var clean_up_btn: Button = $UI/Arena/CleanUpBtn
# backs
onready var about_back_btn: Button = $UI/About/BackBtn
onready var settings_back_btn: Button = $UI/Settings/BackBtn
onready var play_back_btn: Button = $UI/Play/BackBtn
onready var players_back_btn: Button = $UI/SelectPlayers/BackBtn
onready var arena_back_btn: Button = $UI/Arena/BackBtn

	
func _ready() -> void:

	# main
	play_btn.connect("pressed", self, "_on_play_btn_pressed")
	settings_btn.connect("pressed", self, "_on_settings_btn_pressed")
	about_btn.connect("pressed", self, "_on_about_btn_pressed")
	quit_btn.connect("pressed", self, "_on_quit_btn_pressed")

	# back btnz
	about_back_btn.connect("pressed", self, "_on_about_back_btn_pressed")
	settings_back_btn.connect("pressed", self, "_on_settings_back_btn_pressed")
	play_back_btn.connect("pressed", self, "_on_play_back_btn_pressed")
	players_back_btn.connect("pressed", self, "_on_players_back_btn_pressed")

	# arena
	clean_up_btn.connect("pressed", self, "_on_clean_up_btn_pressed")
	generate_arena_btn.connect("pressed", self, "_on_generate_arena_btn_pressed")
	arena_confirm_btn.connect("pressed", self, "_on_arena_confirm_btn_pressed")
	arena_back_btn.connect("pressed", self, "_on_arena_back_btn_pressed")

	temp_back_btn.connect("pressed", self, "_on_temp_back_btn_pressed")
	
	play_btn.grab_focus()
	

func _process(delta: float) -> void:
	
	# temp barvanje player gumbov
	if $UI/SelectPlayers/ItemList/thumb/PlayersBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb/PlayersBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb/PlayersBtn.get_parent().self_modulate = Ref.color_blue
	if $UI/SelectPlayers/ItemList/thumb2/PlayersBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb2/PlayersBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb2/PlayersBtn.get_parent().self_modulate = Ref.color_red
	if $UI/SelectPlayers/ItemList/thumb3/PlayersBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb3/PlayersBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb3/PlayersBtn.get_parent().self_modulate = Ref.color_yellow
	if $UI/SelectPlayers/ItemList/thumb4/PlayersBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb4/PlayersBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb4/PlayersBtn.get_parent().self_modulate = Ref.color_green	
	if $UI/SelectPlayers/ItemList/thumb5/EnemiesBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb5/EnemiesBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb5/EnemiesBtn.get_parent().self_modulate = Ref.color_gray0
	if $UI/SelectPlayers/ItemList/thumb6/EasyBtn.has_focus():
		$UI/SelectPlayers/ItemList/thumb6/EasyBtn.get_parent().self_modulate = Color.white
	else:
		$UI/SelectPlayers/ItemList/thumb6/EasyBtn.get_parent().self_modulate = Ref.color_gray0
		
	
func _on_AnimationPlayer_animation_finished(animation) -> void:
	
	match animation:
		"play_in":
			if animation_player.get_current_animation_position() == 0:
				play_btn.grab_focus()
			else:
				$UI/Play/thumb7/ConfirmBtn.grab_focus()
		"players_in":
			if animation_player.get_current_animation_position() == 0:
				$UI/Play/thumb/ConfirmBtn.grab_focus()
			else:
				$UI/SelectPlayers/ItemList/thumb/PlayersBtn.grab_focus()
		"arena_in": 
			if not arena_on:
				arena_on = true
				spawn_generator()
			else:
				arena_on = false
				
		"start_game":
			var arena_save_name = "prva arena"
			# trenutna mapa
			var current_used_cells: Array = new_world.arena_tilemap.get_used_cells()
			# shrani trenutno mapo v profile
			Pro.arena_tilemap_profiles[arena_save_name] = current_used_cells
			printt("ANIM", current_used_cells)
			Met.switch_to_scene("res://game/arena/Arena.tscn", current_used_cells) # 2. arg je zato, da jih zbrišemo		


# BTNZ ------------------------------------------------------------------------------------------


# main
func _on_play_btn_pressed():
	animation_player.play("play_in")
func _on_settings_btn_pressed():
	animation_player.play("settings_in")
func _on_about_btn_pressed():
	animation_player.play("about_in")
func _on_quit_btn_pressed():
	get_tree().quit()
	
		
# back btnz
func _on_settings_back_btn_pressed():
	animation_player.play_backwards("settings_in")
func _on_about_back_btn_pressed():
	animation_player.play_backwards("about_in")
func _on_play_back_btn_pressed():
	animation_player.play_backwards("play_in")
func _on_players_back_btn_pressed():
	animation_player.play_backwards("players_in")


# play
func _on_ConfirmBtn_2_pressed() -> void:
#	Set.set_game_settings(Set.Levels.NITRO)
	Set.current_game_levels = [Set.Levels.NITRO]
	animation_player.play("players_in")
func _on_ConfirmBtn_3_pressed() -> void:
#	Set.set_game_settings(Set.Levels.OSMICA)
	Set.current_game_levels = [Set.Levels.RACE_8]
	animation_player.play("players_in")
func _on_ConfirmBtn_5_pressed() -> void:
#	Set.set_game_settings(Set.Levels.DUEL)
	Set.current_game_levels = [Set.Levels.DUEL]
	animation_player.play("players_in")
func _on_ConfirmBtn_7_pressed() -> void:
#	Set.set_game_settings(Set.Levels.RACE_DIRECT)
	Set.current_game_levels = [Set.Levels.RACE_DIRECT]
	animation_player.play("players_in")
func _on_ConfirmBtn_8_pressed() -> void:
#	Set.set_game_settings(Set.Levels.RACE_SNAKE)
	Set.current_game_levels = [Set.Levels.RACE_SNAKE]
	animation_player.play("players_in")
func _on_ConfirmBtn_6_pressed() -> void:
	Set.current_game_levels = [Set.Levels.RACE_DIRECT, Set.Levels.RACE_CIRCO, Set.Levels.RACE_ROUND, Set.Levels.RACE_SNAKE, Set.Levels.RACE_NITRO]
	animation_player.play("players_in")

# debug
func _on_ConfirmBtn_1_pressed() -> void:
	Set.set_game_settings(Set.Levels.DEBUG_DUEL)
	animation_player.play("players_in")
func _on_ConfirmBtn_4_pressed() -> void:
	Set.set_game_settings(Set.Levels.DEBUG_RACE)
	animation_player.play("players_in")


# players ------------------------------------------------------------------------------------------------------------------------


onready var select_players: Control = $UI/SelectPlayers


func _on_PlayersBtn_toggled(button_pressed: bool) -> void:
	var bolt_to_manage: int = Pro.PLAYER.P1
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb/PlayersBtn/Label
	if button_pressed:
		btn_label_node.modulate = Color.white
		players_activated.append(bolt_to_manage)
		btn_label_node.text = Met.get_random_name(5)
	else:
		if players_activated.has(bolt_to_manage):
			players_activated.erase(bolt_to_manage)
			btn_label_node.modulate = Ref.color_gray0
			btn_label_node.text = "P1"
	Pro.player_profiles[bolt_to_manage]["player_name"] = btn_label_node.text	
			
func _on_PlayersBtn_2_toggled(button_pressed: bool) -> void:
	var bolt_to_manage: int = Pro.PLAYER.P2
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb2/PlayersBtn/Label
	if button_pressed:
		players_activated.append(bolt_to_manage)
		btn_label_node.modulate = Color.white
		btn_label_node.text = Met.get_random_name(5)
	else:
		if players_activated.has(bolt_to_manage):
			players_activated.erase(bolt_to_manage)
			btn_label_node.modulate = Ref.color_gray0
			btn_label_node.text = "P2"
	Pro.player_profiles[bolt_to_manage]["player_name"] = btn_label_node.text	
			
func _on_PlayersBtn_3_toggled(button_pressed: bool) -> void:
	var bolt_to_manage: int = Pro.PLAYER.P3
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb3/PlayersBtn/Label
	if button_pressed:
		players_activated.append(bolt_to_manage)
		btn_label_node.modulate = Color.white
		btn_label_node.text = Met.get_random_name(5)
	else:
		if players_activated.has(bolt_to_manage):
			players_activated.erase(bolt_to_manage)
			btn_label_node.modulate = Ref.color_gray0
			btn_label_node.text = "P3"
	Pro.player_profiles[bolt_to_manage]["player_name"] = btn_label_node.text	
			
func _on_PlayersBtn_4_toggled(button_pressed: bool) -> void:
	var bolt_to_manage: int = Pro.PLAYER.P4
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb4/PlayersBtn/Label
	if button_pressed:
		players_activated.append(bolt_to_manage)
		btn_label_node.modulate = Color.white
		btn_label_node.text = Met.get_random_name(5)
	else:
		if players_activated.has(bolt_to_manage):
			players_activated.erase(bolt_to_manage)
			btn_label_node.modulate = Ref.color_gray0
			btn_label_node.text = "P1"
	Pro.player_profiles[bolt_to_manage]["player_name"] = btn_label_node.text	
			
func _on_EnemiesBtn_5_toggled(button_pressed: bool) -> void:
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb5/EnemiesBtn/Label
	if button_pressed:
		enemies_mode = true
		btn_label_node.modulate = Color.white
	else:
		enemies_mode = false
		btn_label_node.modulate = Ref.color_gray0
func _on_EasyBtn_6_toggled(button_pressed: bool) -> void:
	var btn_label_node: Control = $UI/SelectPlayers/ItemList/thumb6/EasyBtn/Label
	if button_pressed:
		easy_mode = true
		btn_label_node.modulate = Color.white
	else:
		easy_mode = false
		btn_label_node.modulate = Ref.color_gray0
func _on_PlayBtn_pressed() -> void:
	
	if players_activated.empty():
		return
		
	# setam vrednost v Set.
	Set.current_game_settings["enemies_mode"] = enemies_mode # slovar, ki je duplikat in se ustvari na Set. ready
	Set.players_on_game_start = players_activated
	
#	Set.bolts_activated = players_in_game
	Ref.main_node.home_out()


# generate arena
func _on_arena_confirm_btn_pressed():
	animation_player.play("start_game")
func _on_arena_back_btn_pressed():
	arena_on = false
	animation_player.play_backwards("arena_in")
func spawn_generator():	
	# spucaj
#	if not new_world == null:
#		new_world.queue_free()
	# spawn walker
	new_world = arena_world.instance()
	new_world.scale *=  0.25
	arena_view.add_child(new_world)
#	new_world.steps_count_limit = 5
	pass
func _on_generate_arena_btn_pressed():
	if not new_world == null:
		spawn_generator()
func _on_clean_up_btn_pressed():
	if not new_world == null:
		new_world.cleanup_map()
func _on_temp_back_btn_pressed():
	animation_player.play_backwards("start_game")




