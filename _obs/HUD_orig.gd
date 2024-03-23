extends Node2D


var game_is_on: bool = false setget _on_game_status_change


var spawned_player_profile
var playerstats_index: int = 0 # index znotraj ene runde
var playerstats_round: int = 0 # ena runda so 4 hudi

var odmik_od_roba = 24
var odmik_od_roba_spodaj = 48 # adaptacija za anchor
var playerstats_w = 350
var playerstats_h = 38
var premik_runde = 38

#onready var player_line: Control = $PlayerLine_P1
onready var bolt_stats: = Profiles.default_bolt_stats
onready var player_stats: = Profiles.default_player_stats
onready var player_profiles: = Profiles.default_player_profiles
#onready var player_name = Profiles.default_player_profiles["player_name"]

onready var stat_line_topL: Control = $StatLineTopL
onready var stat_line_topR: Control = $StatLineTopR
onready var stat_line_btmL: Control = $StatLineBtmL
onready var stat_line_btmR: Control = $StatLineBtmR
onready var game_time: Control = $GameTime
onready var game_over: Control = $GameOver
onready var game_start: Control = $GameStart

var stat_line_topL_active: bool = false
var stat_line_topR_active: bool = false
var stat_line_btmL_active: bool = false
var stat_line_btmR_active: bool = false

var stat_lines_owners: Dictionary = {}
var loading_time: float = 0.5 # pred prikazom nbaj se v miru postavi

# pavza
onready var pause_ui: Control = $"../PauseUI"
onready var pavza_btn: Button = $PavzaBtn
onready var pavza_back_btn: Button = $"../PauseUI/BackBtn"
onready var pavza_restart_btn: Button = $"../PauseUI/RestartBtn"
onready var pavza_quit_btn: Button = $"../PauseUI/QuitBtn"

# gameover
onready var game_over_ui: Control = $"../GameOverUI"
onready var gameover_restart_btn: Button = $"../GameOverUI/RestartBtn"
onready var gameover_high_score_btn: Button = $"../GameOverUI/HighScoreBtn"
onready var gameover_quit_btn: Button = $"../GameOverUI/QuitBtn"

onready var scene_tree: = get_tree()
onready var game_manager: Node = $"../../GameManager"


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("ui_cancel"):
		toggle_pause()
	
	if Input.is_action_just_released("r"):	
		if not pause_ui.visible:
			yield(get_tree().create_timer(1), "timeout")
			game_over_ui.visible = true
		else:
			game_over_ui.visible = false


func _ready() -> void:
	
	# skrij statistiko
	stat_line_topL.visible = false
	stat_line_topR.visible = false
	stat_line_btmL.visible = false
	stat_line_btmR.visible = false
	game_time.visible = false
	game_over.visible = false

	# Global.game_manager.connect("stat_change_received", self, "on_stat_change_received") # signal pride iz GM in pošlje spremenjeno statistiko
	game_manager.connect("stat_change_received", self, "_on_stat_change_received") # signal pride iz GM in pošlje spremenjeno statistiko
	game_manager.connect("new_bolt_spawned", self, "_on_new_bolt_spawned") # signal pride iz GM in pošlje spremenjeno statistiko
	
	# pavza
	pavza_btn.connect("pressed", self, "_on_pavza_btn_pressed")
	pavza_restart_btn.connect("pressed", self, "_on_pavza_restart_btn_pressed")	
	pavza_back_btn.connect("pressed", self, "_on_pavza_back_btn_pressed")
	pavza_quit_btn.connect("pressed", self, "_on_pavza_quit_btn_pressed")
	pause_ui.visible = false

	# gameover
	gameover_restart_btn.connect("pressed", self, "_on_gameover_restart_btn_pressed")
	gameover_high_score_btn.connect("pressed", self, "_on_gameover_high_score_btn_pressed")
	gameover_quit_btn.connect("pressed", self, "_on_gameover_quit_btn_pressed")
	game_over_ui.visible = false

		
func _on_gameover_restart_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Global.switch_to_scene("res://game/arena/Arena.tscn")
	
func _on_gameover_quit_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Global.switch_to_scene("res://home/Home.tscn")
	
func _on_gameover_high_score_btn_pressed():
	game_over_ui.visible = false


func _on_pavza_btn_pressed():
	toggle_pause()
	
func toggle_pause():
	pause_ui.visible = not pause_ui.visible
	scene_tree.paused = not scene_tree.paused
	pavza_btn.visible = not pavza_btn.visible
	scene_tree.set_input_as_handled()
	
func _on_pavza_back_btn_pressed():
	toggle_pause()
	
func _on_pavza_restart_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Global.switch_to_scene("res://game/arena/Arena.tscn")
	
func _on_pavza_quit_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Global.switch_to_scene("res://home/Home.tscn")


func _on_game_status_change(new_game_status):
	
#	game_time.visible = true
	print(new_game_status)
	if new_game_status == true:
		game_start.visible = false
		game_time.visible = true
		game_over.visible = false
		game_is_on = true
	else:
		game_start.visible = false
		game_time.visible = false
		game_over.visible = true
		game_is_on = false
		pass


func _on_stat_change_received(stat_owner_id, stat_name, new_stat_value):
	
	var stat_line_to_change: Control = stat_lines_owners[stat_owner_id]
	
	match stat_name:
		"points":
#			print("--------- točka")
			# value se preračuna na GM
			stat_line_to_change.stat_points.current_stat_value = new_stat_value # setget
		"life": 
#			print("--------- lajf")
			# value se preračuna na GM
			stat_line_to_change.stat_life.current_stat_value = new_stat_value # setget
#
		"misile_count": 
#			print("--------- misila")
			# value se preračuna v plejerju
			stat_line_to_change.stat_misile.current_stat_value = new_stat_value # setget
		"shocker_count": 
#			print("--------- šoker")
			# value se preračuna v plejerju
			stat_line_to_change.stat_shocker.current_stat_value = new_stat_value # setget

	
func _on_new_bolt_spawned(bolt_index, player_id):
	
	var current_stat_line: Control
	
	# poveži plejerja in stat line ... v slovarju
	match bolt_index:
		1:
			current_stat_line = stat_line_topL
			stat_lines_owners[player_id] = stat_line_topL 
		2:
			current_stat_line = stat_line_topR
			stat_lines_owners[player_id] = stat_line_topR 
		3:
			current_stat_line = stat_line_btmL
			stat_lines_owners[player_id] = stat_line_btmL 
		4:
			current_stat_line = stat_line_btmR
			stat_lines_owners[player_id] = stat_line_btmR 
	
	current_stat_line.stat_line_color = player_profiles[player_id]["player_color"]
	
	# napolni statistiko
	current_stat_line.stat_name.text = player_profiles[player_id]["player_name"]
	current_stat_line.stat_shocker.current_stat_value = bolt_stats["shocker_count"]
	current_stat_line.stat_mina.current_stat_value = bolt_stats["shocker_count"]
	current_stat_line.stat_misile.current_stat_value = bolt_stats["misile_count"]
	current_stat_line.stat_points.current_stat_value = player_stats["points"]
	current_stat_line.stat_life.current_stat_value = player_stats["life"]
	current_stat_line.stat_wins.current_stat_value = player_stats["wins"]
	
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse obarva
	current_stat_line.visible = true

	
func hide_player_stats():
	# skrij statistiko
	stat_line_topL.visible = false
	stat_line_topR.visible = false
	stat_line_btmL.visible = false
	stat_line_btmR.visible = false	






#
#func on_Player_spawned_Q(spawned_player_profile: Dictionary, spawned_player_stats: Dictionary, player_index: int ): # samo za hitri spawn
#
#	print("HEY")
#	var player_name = spawned_player_profile["player_name"]
#	var player_game_stats = spawned_player_stats
#
#	# generiraj playerstats
#	var new_playerstats = playerStats.instance()
#	new_playerstats.set_name("p%s_playerstats" % player_index) # potrebno za kasnejše iskanje nodeta v drevesu
#
#	# izračun playerstats pozicije
#	playerstats_index = player_index # index višamo do 4, potem se resetira ... def je 0
#	match playerstats_index:
#		1: 
#			new_playerstats.set_position(Vector2( 0 + odmik_od_roba, 0 + odmik_od_roba  + premik_runde * playerstats_round ))
#		2: 
##			playerstats_round += 1
##			new_playerstats.set_position(Vector2( 0 + odmik_od_roba, 0 + odmik_od_roba  + premik_runde * playerstats_round ))
#			new_playerstats.set_position(Vector2( get_viewport().size.x - playerstats_w - odmik_od_roba , 0 + odmik_od_roba + premik_runde * playerstats_round ))
#		3: 
#			new_playerstats.set_position(Vector2( 0 + odmik_od_roba, get_viewport().size.y - odmik_od_roba_spodaj - premik_runde  * playerstats_round ))
#		4: 
#			new_playerstats.set_position(Vector2( get_viewport().size.x - playerstats_w - odmik_od_roba , get_viewport().size.y - odmik_od_roba_spodaj - premik_runde * playerstats_round ))
#			playerstats_index	= 0 # začne se nova runda ... resetiramo plejerstats index
#			playerstats_round += 1 # začne se nova runda
#
#	# per-player
#	new_playerstats.get_node("PlayerName").text = player_name
#	new_playerstats.get_node("Avatar").texture = spawned_player_profile["player_avatar"]
#	for stat_label in new_playerstats.get_children(): # barva
#		stat_label.modulate = spawned_player_profile["player_color"]
#
#	# game stats
##	new_playerstats.get_node("EnergyProgressBar").def_energy = spawned_player_profile["energy"]
#	new_playerstats.get_node("EnergyProgressBar/Label").text = str(player_game_stats["energy"])
#	new_playerstats.get_node("LifeCounter/Label").text = str(player_game_stats["life"]) # zakaj more bit tukej string?
#	new_playerstats.get_node("ScoreCounter/Label").text = "%04d" % player_game_stats["score"]
#	new_playerstats.get_node("BulletCounter/Label").text = "%02d" % player_game_stats["bullet_no"]
#	new_playerstats.get_node("MisileCounter/Label").text = "%02d" % player_game_stats["misile_no"]
#
#	# skrijemo gejmover in win
#	new_playerstats.get_node("GameoverLabel").hide()
#	new_playerstats.get_node("WinLabel").hide()
#
#	Ref.node_creation_parent.get_node("HUD").add_child(new_playerstats)
#
#
#func on_Player_spawned(spawned_player_profile: Dictionary, spawned_player_index: int): # kreacija huda za plejerja
#	# ta funkcija se izvrši za vsakega plejerja posebej
#
#	var player_name = spawned_player_profile["player_name"]
#	var player_game_stats = spawned_player_profile["player_game_stats"]
#
#	# generiraj playerstats
#	var new_playerstats = playerStats.instance()
#	new_playerstats.set_name("p%s_playerstats" % spawned_player_index) # potrebno za kasnejše iskanje nodeta v drevesu
#
#	# izračun playerstats pozicije
#	playerstats_index += 1 # index višamo do 4, potem se resetira ... def je 0
#	match playerstats_index:
#		1: 
#			new_playerstats.set_position(Vector2( 0 + odmik_od_roba, 0 + odmik_od_roba  + premik_runde * playerstats_round ))
#		2: 
#			new_playerstats.set_position(Vector2( get_viewport().size.x - playerstats_w - odmik_od_roba , 0 + odmik_od_roba + premik_runde * playerstats_round ))
#		3: 
#			new_playerstats.set_position(Vector2( 0 + odmik_od_roba, get_viewport().size.y - odmik_od_roba_spodaj - premik_runde  * playerstats_round ))
#		4: 
#			new_playerstats.set_position(Vector2( get_viewport().size.x - playerstats_w - odmik_od_roba , get_viewport().size.y - odmik_od_roba_spodaj - premik_runde * playerstats_round ))
#			playerstats_index	= 0 # začne se nova runda ... resetiramo plejerstats index
#			playerstats_round += 1 # začne se nova runda
#
#	# per-player
#	new_playerstats.get_node("PlayerName").text = player_name
#	new_playerstats.get_node("Avatar").texture = spawned_player_profile["player_avatar"]
#	for stat_label in new_playerstats.get_children(): # barva
#		stat_label.modulate = spawned_player_profile["player_color"]
#
#	# game stats
##	new_playerstats.get_node("EnergyProgressBar").def_energy = spawned_player_profile["energy"]
#	new_playerstats.get_node("EnergyProgressBar/Label").text = str(player_game_stats["energy"])
#	new_playerstats.get_node("LifeCounter/Label").text = str(player_game_stats["life"]) # zakaj more bit tukej string?
#	new_playerstats.get_node("ScoreCounter/Label").text = "%04d" % player_game_stats["score"]
#	new_playerstats.get_node("BulletCounter/Label").text = "%02d" % player_game_stats["bullet_no"]
#	new_playerstats.get_node("MisileCounter/Label").text = "%02d" % player_game_stats["misile_no"]
#
#	# skrijemo gejmover in win
#	new_playerstats.get_node("GameoverLabel").hide()
#	new_playerstats.get_node("WinLabel").hide()
#
#	Ref.node_creation_parent.get_node("HUD").add_child(new_playerstats)
#
