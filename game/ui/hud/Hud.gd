extends Control


var stat_lines_owners: Dictionary = {}
var loading_time: float = 0.5 # pred prikazom naj se v miru postavi

onready var stat_line_topL: Control = $StatLineRacer1
onready var stat_line_topR: Control = $StatLineRacer2
onready var stat_line_btmL: Control = $StatLineRacer3
onready var stat_line_btmR: Control = $StatLineRacer4

var current_record_lap_time: int = 0# stotinke
onready var record_lap_label: Label = $GameStats/RecordLap
onready var game_stats: HBoxContainer = $GameStats
onready var game_timer: Control = $"%GameTimer"
onready var start_countdown: Control = $"%StartCountdown"


func _ready() -> void:
	
	print("HUD")
	
	Ref.hud = self	
	
	# skrij statistiko, ki se prikaže ponovno, ob spawnu bolta
	stat_line_topL.visible = false
	stat_line_topR.visible = false
	stat_line_btmL.visible = false
	stat_line_btmR.visible = false

	Ref.game_manager.connect("new_bolt_spawned", self, "_set_spawned_bolt_hud") # signal pride iz GM in pošlje spremenjeno statistiko
	
	# stats setup
	var stat_lines: Array = [$StatLineRacer1, $StatLineRacer2, $StatLineRacer3, $StatLineRacer4]
	for stat_line in stat_lines:
		if Ref.game_manager.game_settings["race_mode"]:
			stat_line.stat_life.hide()
			stat_line.stat_wins.hide()
		else:
			stat_line.stat_wins.hide()
#			stat_line.stat_points.hide()
			stat_line.stat_gas.hide()
			
			
func on_game_start():
	
	game_stats.show()
	game_timer.start_timer()


func on_game_over():
	
	game_timer.stop_timer()
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
		"lap_finished":
			# laps count
			stat_line_to_change.stat_laps_count.current_stat_value = new_stat_value[0]
			# fast time
			var fastest_lap_time: Array = Met.get_clock_time(new_stat_value[1])
			var fastest_lap_time_on_clock: String = "%02d" % fastest_lap_time[0] + ":" + "%02d" % fastest_lap_time[1] + ":" + "%02d" % fastest_lap_time[2]
			stat_line_to_change.stat_fastest_lap.current_stat_value = fastest_lap_time_on_clock
			
			if current_record_lap_time == 0:
				record_lap_label.text = "Record: 00:00:00"
			
		"points":
			stat_line_to_change.stat_points.current_stat_value = new_stat_value # setget
		"wins": 
			stat_line_to_change.stat_wins.current_stat_value = new_stat_value # setget
		# bolt stats
		"life": 
			stat_line_to_change.stat_life.current_stat_value = new_stat_value # setget
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
	
	# current_stat_line.stat_line_color = player_profiles[bolt_id]["player_color"]
	current_stat_line.stat_name.modulate = player_profiles[bolt_id]["player_color"]
	current_stat_line.stat_name.text = player_profiles[bolt_id]["player_name"]
	
	# bolt stats
	current_stat_line.stat_bullet.current_stat_value = bolt_stats["bullet_count"]
	current_stat_line.stat_shocker.current_stat_value = bolt_stats["shocker_count"]
	current_stat_line.stat_misile.current_stat_value = bolt_stats["misile_count"]
	current_stat_line.stat_gas.current_stat_value = bolt_stats["gas_count"]
	current_stat_line.stat_life.current_stat_value = bolt_stats["life"]
	
	# player stats
	current_stat_line.stat_points.current_stat_value = player_stats["points"]
	current_stat_line.stat_wins.current_stat_value = player_stats["wins"]
	
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	current_stat_line.visible = true
