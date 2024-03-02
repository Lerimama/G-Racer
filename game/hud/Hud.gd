extends Control


#var spawned_player_profile
#var playerstats_index: int = 0 # index znotraj ene runde
#var playerstats_round: int = 0 # ena runda so 4 hudi

#onready var bolt_stats: = Pro.default_bolt_stats
#onready var driver_stats: = Pro.default_player_stats
#onready var driver_profiles: = Pro.default_player_profiles
#onready var player_name = Profiles.default_player_profiles["player_name"]

#onready var stat_line_topL: Control = $StatLineTopL
#onready var stat_line_topR: Control = $StatLineTopR
#onready var stat_line_btmL: Control = $StatLineBtmL
#onready var stat_line_btmR: Control = $StatLineBtmR
onready var stat_line_topL: Control = $StatLineRacer1
onready var stat_line_topR: Control = $StatLineRacer2
onready var stat_line_btmL: Control = $StatLineRacer3
onready var stat_line_btmR: Control = $StatLineRacer4
onready var game_stats: HBoxContainer = $GameStats

#onready var game_time: Control = $GameTime
#onready var game_over: Control = $Popups/GameOver
#onready var game_start: Control = $Popups/GameStart

var stat_line_topL_active: bool = false
var stat_line_topR_active: bool = false
var stat_line_btmL_active: bool = false
var stat_line_btmR_active: bool = false

var stat_lines_owners: Dictionary = {}
var loading_time: float = 0.5 # pred prikazom nbaj se v miru postavi

# neu
onready var game_timer: Control = $"%GameTimer"
#onready var game_over: Control = $"%GameOver"
onready var start_countdown: Control = $"%StartCountdown"

func _input(event: InputEvent) -> void:
	
#	if Input.is_action_just_released("ui_cancel"):
#		toggle_pause()
	pass
	
	
func _ready() -> void:
	
	print("HUD")
	
	Ref.hud = self	
	
	# skrij statistiko
	stat_line_topL.visible = false
	stat_line_topR.visible = false
	stat_line_btmL.visible = false
	stat_line_btmR.visible = false
#	game_time.visible = false
#	game_over.visible = false

	Ref.game_manager.connect("new_bolt_spawned", self, "_set_spawned_bolt_hud") # signal pride iz GM in pošlje spremenjeno statistiko
	
	# gameover
#	gameover_restart_btn.connect("pressed", self, "_on_gameover_restart_btn_pressed")
#	gameover_high_score_btn.connect("pressed", self, "_on_gameover_high_score_btn_pressed")
#	gameover_quit_btn.connect("pressed", self, "_on_gameover_quit_btn_pressed")
#	game_over_ui.visible = false


func on_game_start():
	
#	game_start.visible = false
#	game_time.visible = true
#	game_over.visible = false
	game_stats.show()
	game_timer.start_timer()


func on_game_over():
	
	game_timer.stop_timer()
#	game_start.visible = false
#	game_time.visible = false
#	game_over.visible = true
	
	hide_player_stats()
	

func hide_player_stats():
	# skrij statistiko
	
	stat_line_topL.visible = false
	stat_line_topR.visible = false
	stat_line_btmL.visible = false
	stat_line_btmR.visible = false	
	game_stats.hide()

	
# PRIVAT ------------------------------------------------------------------------------------------------------------

	
func _on_stat_changed(stat_owner_id, stat_name, new_stat_value):
	
	var stat_line_to_change: Control = stat_lines_owners[stat_owner_id]
	
	match stat_name:
		# value se preračun na plejerju
		# player stats
		"player_points":
			stat_line_to_change.stat_points.current_stat_value = new_stat_value # setget
		"player_life": 
			stat_line_to_change.stat_life.current_stat_value = new_stat_value # setget
		"player_wins": 
			stat_line_to_change.stat_wins.current_stat_value = new_stat_value # setget
		# bolt stats
		"bullet_count": 
			stat_line_to_change.stat_bullet.current_stat_value = new_stat_value # setget
		"misile_count": 
			stat_line_to_change.stat_misile.current_stat_value = new_stat_value # setget
		"shocker_count": 
			stat_line_to_change.stat_shocker.current_stat_value = new_stat_value # setget
		"gas_count":
			stat_line_to_change.stat_gas.current_stat_value = new_stat_value # setget
	
	
func _set_spawned_bolt_hud(bolt_index, bolt_id):
	
	var current_stat_line: Control
	
	# poveži plejerja in stat line ... v slovarju
	match bolt_index:
		1:
			current_stat_line = stat_line_topL
			stat_lines_owners[bolt_id] = stat_line_topL 
		2:
			current_stat_line = stat_line_topR
			stat_lines_owners[bolt_id] = stat_line_topR 
		3:
			current_stat_line = stat_line_btmL
			stat_lines_owners[bolt_id] = stat_line_btmL 
		4:
			current_stat_line = stat_line_btmR
			stat_lines_owners[bolt_id] = stat_line_btmR 
	
	# data

	var bolt_stats: Dictionary = Pro.default_bolt_stats
	var player_stats: Dictionary = Pro.default_player_stats
	var player_profiles: Dictionary = Pro.default_player_profiles
	
	current_stat_line.stat_line_color = player_profiles[bolt_id]["player_color"]
	current_stat_line.stat_name.text = player_profiles[bolt_id]["player_name"]
	
	# bolt stats
	current_stat_line.stat_bullet.current_stat_value = bolt_stats["bullet_count"]
	current_stat_line.stat_shocker.current_stat_value = bolt_stats["shocker_count"]
	current_stat_line.stat_misile.current_stat_value = bolt_stats["misile_count"]
	current_stat_line.stat_gas.current_stat_value = bolt_stats["gas_count"]
	
	# player stats
	current_stat_line.stat_points.current_stat_value = player_stats["player_points"]
	current_stat_line.stat_life.current_stat_value = player_stats["player_life"]
	current_stat_line.stat_wins.current_stat_value = player_stats["player_wins"]
	
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	current_stat_line.visible = true

	



# BTNS ------------------------------------------------------------------------------------------------------------

# gameover
onready var game_over_ui: Control = $"../GameOverUI"
onready var gameover_restart_btn: Button = $"../GameOverUI/RestartBtn"
onready var gameover_high_score_btn: Button = $"../GameOverUI/HighScoreBtn"
onready var gameover_quit_btn: Button = $"../GameOverUI/QuitBtn"

onready var scene_tree: = get_tree()

		
func _on_gameover_restart_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Met.switch_to_scene("res://game/arena/Arena.tscn")
	
func _on_gameover_quit_btn_pressed():
#	yield(get_tree().create_timer(2), "timeout")
	Met.switch_to_scene("res://home/Home.tscn")
	
func _on_gameover_high_score_btn_pressed():
	game_over_ui.visible = false
