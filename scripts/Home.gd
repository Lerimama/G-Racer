extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var animacija: AnimationNodeAnimation = $

# main
onready var play_btn: Button = $HomeUI/MainMenu/Menu/PlayBtn
onready var settings_btn: Button = $HomeUI/MainMenu/Menu/SettingsBtn
onready var about_btn: Button = $HomeUI/MainMenu/Menu/AboutBtn
onready var quit_btn: Button = $HomeUI/MainMenu/Menu/QuitBtn

# about
onready var about_back_btn: Button = $HomeUI/About/BackBtn

# settings
onready var settings_back_btn: Button = $HomeUI/Settings/BackBtn

#play
onready var play1_confirm_btn: Button = $HomeUI/Play/ItemList/thumb/ConfirmBtn
onready var play2_confirm_btn: Button = $HomeUI/Play/ItemList/thumb2/ConfirmBtn
onready var play3_confirm_btn: Button = $HomeUI/Play/ItemList/thumb3/ConfirmBtn
onready var play4_confirm_btn: Button = $HomeUI/Play/ItemList/thumb4/ConfirmBtn
onready var play_back_btn: Button = $HomeUI/Play/BackBtn

# players
onready var players1_confirm_btn: Button = $HomeUI/Players/ItemList/thumb/ConfirmBtn
onready var players2_confirm_btn: Button = $HomeUI/Players/ItemList/thumb2/ConfirmBtn
onready var players3_confirm_btn: Button = $HomeUI/Players/ItemList/thumb3/ConfirmBtn
onready var players4_confirm_btn: Button = $HomeUI/Players/ItemList/thumb4/ConfirmBtn
onready var players_back_btn: Button = $HomeUI/Players/BackBtn

# arena
onready var generate_arena_btn: Button = $HomeUI/Arena/GenerateBtn
onready var arena_confirm_btn: Button = $HomeUI/Arena/ConfirmBtn
onready var arena_back_btn: Button = $HomeUI/Arena/BackBtn

onready var temp_back_btn: Button = $HomeUI/Arena/temp_BackBtn


func _ready() -> void:


	# main
	play_btn.connect("pressed", self, "_on_play_btn_pressed")
	settings_btn.connect("pressed", self, "_on_settings_btn_pressed")
	about_btn.connect("pressed", self, "_on_about_btn_pressed")
	quit_btn.connect("pressed", self, "_on_quit_btn_pressed")

	# about
	about_back_btn.connect("pressed", self, "_on_about_back_btn_pressed")

	# settings
	settings_back_btn.connect("pressed", self, "_on_settings_back_btn_pressed")

	#play
	play1_confirm_btn.connect("pressed", self, "_on_play1_confirm_btn_pressed")
	play2_confirm_btn.connect("pressed", self, "_on_play2_confirm_btn_pressed")
	play3_confirm_btn.connect("pressed", self, "_on_play3_confirm_btn_pressed")
	play4_confirm_btn.connect("pressed", self, "_on_play4_confirm_btn_pressed")
	play_back_btn.connect("pressed", self, "_on_play_back_btn_pressed")

	# players
	players1_confirm_btn.connect("pressed", self, "_on_players1_confirm_btn_pressed")
	players2_confirm_btn.connect("pressed", self, "_on_players2_confirm_btn_pressed")
	players3_confirm_btn.connect("pressed", self, "_on_players3_confirm_btn_pressed")
	players4_confirm_btn.connect("pressed", self, "_on_players4_confirm_btn_pressed")
	players_back_btn.connect("pressed", self, "_on_players_back_btn_pressed")

	# arena
	generate_arena_btn.connect("pressed", self, "_on_generate_arena_btn")
	arena_confirm_btn.connect("pressed", self, "_on_arena_confirm_btn_pressed")
	arena_back_btn.connect("pressed", self, "_on_arena_back_btn_pressed")

	temp_back_btn.connect("pressed", self, "_on_temp_back_btn_pressed")


# main
func _on_play_btn_pressed():
	animation_player.play("play_in")
func _on_settings_btn_pressed():
	animation_player.play("settings_in")
func _on_about_btn_pressed():
	animation_player.play("about_in")


# settings
func _on_settings_back_btn_pressed():
	animation_player.play_backwards("settings_in")


# about
func _on_about_back_btn_pressed():
	animation_player.play_backwards("about_in")


# play
func _on_play1_confirm_btn_pressed():
	animation_player.play("players_in")
func _on_play_back_btn_pressed():
	animation_player.play_backwards("play_in")

# players
func _on_players_btn_pressed():
	animation_player.play("players_in")
func _on_players1_confirm_btn_pressed():
	animation_player.play("arena_in")
func _on_players_back_btn_pressed():
	animation_player.play_backwards("players_in")
	
# arena
func _on_arena_btn_pressed():
	animation_player.play("arena_in")
func _on_arena_confirm_btn_pressed():
	animation_player.play("start_game")
func _on_arena_back_btn_pressed():
	animation_player.play_backwards("arena_in")
	
	
func _on_temp_back_btn_pressed():
	animation_player.play_backwards("start_game")


# quit
func _on_quit_btn_pressed():
	Global.switch_to_scene("res://scenes/arena/Arena.tscn")
#	Global.switch_to_scene("res://scenes/Game.tscn")

