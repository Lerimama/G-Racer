extends Control


var statbox_owners: Dictionary = {}
var loading_time: float = 0.5 # pred prikazom naj se v miru postavi
var record_lap_time: int = 0 #setget _on_lap_record_changed # stotinke 
var record_level_time: int = 0 # setget _on_level_record_changed # stotinke 

onready var statbox_topL: Control = $StatBox
onready var statbox_topR: Control = $StatBox2
onready var statbox_btmL: Control = $StatBox3
onready var statbox_btmR: Control = $StatBox4

onready var record_lap_label: Label = $GameStats/RecordLap
onready var game_stats: VBoxContainer = $GameStats
onready var game_timer: Control = $"%GameTimer"
onready var start_countdown: Control = $"%StartCountdown"
onready var level_name: Label = $LevelName

onready var FloatingTag: PackedScene = preload("res://game/ui/FloatingTag.tscn")


func _ready() -> void:
	
	print("HUD")
	Ref.hud = self	
	
	# skrij statistiko, ki se prikaže ponovno, ob spawnu bolta
	statbox_topL.visible = false
	statbox_topR.visible = false
	statbox_btmL.visible = false
	statbox_btmR.visible = false
	
	Ref.game_manager.connect("new_bolt_spawned", self, "_set_bolt_statbox") # signal pride iz GM in pošlje spremenjeno statistiko


func set_hud(): # kliče GM
	
	game_timer.reset_timer()
	
#	var stat_boxes: Array = [$StatBox, $StatBox2, $StatBox3, $StatBox4]
#	for box in stat_boxes:
#		# najprej skrijem vse in potem pokažem glede na igro
#		for stat in box.get_children():
#			stat.hide()
#		box.player_line.show()
#		if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#			# player stats
#			box.stat_gas.show()
#			box.stat_level_rank.show()	
#			if Ref.game_manager.level_settings["lap_limit"] > 1:
#				box.stat_laps_count.show()
#			# prikaže se med igro
#			box.stat_best_lap.hide()
#			box.stat_level_time.hide()	
#			box.stat_bullet.hide()	
#			box.stat_misile.hide()	
#			box.stat_shocker.hide()	
#			box.stat_mina.hide()	
#			# game stats
#			if record_lap_time == 0:
#				record_lap_label.hide()
#		else:
#			box.stat_life.show()
#			box.stat_bullet.show()	
#			box.stat_misile.show()	
#			box.stat_mina.show()	
#			box.stat_shocker.show()	
#			record_lap_label.hide()
#			game_timer.get_node("Dots2").hide()
#			game_timer.get_node("Hunds").hide()
			
						
func on_game_start():
	
	game_stats.show()
	game_timer.start_timer()


func on_level_finished():
	game_timer.stop_timer()
	#	hide_stats()
	
	
func on_game_over():
	
	game_timer.stop_timer()
	hide_stats()
	

func hide_stats():
	# skrij statistiko
	
	statbox_topL.visible = false
	statbox_topR.visible = false
	statbox_btmL.visible = false
	statbox_btmR.visible = false	
	game_stats.hide()


func spawn_bolt_floating_tag(tag_owner: KinematicBody2D, lap_time: float, best_lap: bool):
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 4 # višje od straysa in playerja
	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = tag_owner.global_position
	new_floating_tag.tag_owner = tag_owner
	new_floating_tag.scale = Vector2.ONE * Set.game_camera_zoom_factor
	
	new_floating_tag.content_to_show = lap_time
	new_floating_tag.tag_type = new_floating_tag.TagTypes.TIME
	Ref.node_creation_parent.add_child(new_floating_tag) # OPT
	if best_lap == true:
		new_floating_tag.modulate = Set.color_green
	else:
		new_floating_tag.modulate = Set.color_red
	
	
	
# PRIVAT ------------------------------------------------------------------------------------------------------------

	
func _set_bolt_statbox(bolt: KinematicBody2D):
	
	if bolt.bolt_id == Pro.Players.ENEMY: # če je enemy ne rabim hud statsov ... zaenkrat
		return
	
	var current_statbox: Control
	
	match bolt.bolt_id:
		0:
			current_statbox = statbox_topL
			statbox_owners[bolt.bolt_id] = statbox_topL 
		1:
			current_statbox = statbox_topR
			statbox_owners[bolt.bolt_id] = statbox_topR 
		2:
			current_statbox = statbox_btmL
			statbox_owners[bolt.bolt_id] = statbox_btmL 
		3:
			current_statbox = statbox_btmR
			statbox_owners[bolt.bolt_id] = statbox_btmR 
	
	# bolt stats
	var bolt_stats: Dictionary = bolt.bolt_stats
	current_statbox.stat_bullet.stat_value = bolt_stats["bullet_count"]
	current_statbox.stat_misile.stat_value = bolt_stats["misile_count"]
	current_statbox.stat_mina.stat_value = bolt_stats["mina_count"]
	current_statbox.stat_shocker.stat_value = bolt_stats["shocker_count"]
	current_statbox.stat_gas.stat_value = bolt_stats["gas_count"]
	current_statbox.stat_life.stat_value = bolt_stats["life"]
	current_statbox.stat_points.stat_value = bolt_stats["points"]
	current_statbox.stat_wins.stat_value = bolt_stats["wins"]
	
		
	# player line
	var player_profiles: Dictionary = Pro.player_profiles
	current_statbox.player_name_label.modulate = player_profiles[bolt.bolt_id]["player_color"]
#	current_statbox.stat_wins.modulate = player_profiles[bolt.bolt_id]["player_color"]
	current_statbox.player_name_label.text = player_profiles[bolt.bolt_id]["player_name"]
	var new_text: Texture = player_profiles[bolt.bolt_id]["player_avatar"]
	current_statbox.player_avatar.set_texture(new_text)
	current_statbox.stat_wins.modulate = Color.red
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	current_statbox.visible = true


func _on_GameTimer_gametime_is_up() -> void:
	
	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		Ref.game_manager.level_completed(Ref.game_manager.GameoverReason.TIME)
	# v dirki je trenutno je game over samo, če ti zmanjka bencina

	
func _on_stats_changed(bolt_id: int, bolt_stats: Dictionary):
	
	var statbox_to_change: Control = statbox_owners[bolt_id]

	# BOLT STATS
	
	statbox_to_change.stat_wins.stat_value = bolt_stats["wins"] # setget
	statbox_to_change.stat_life.stat_value = bolt_stats["life"] # setget
	statbox_to_change.stat_points.stat_value = bolt_stats["points"] # setget
	statbox_to_change.stat_gas.stat_value = bolt_stats["gas_count"] # setget	
	statbox_to_change.stat_level_rank.stat_value = bolt_stats["level_rank"] # setget
	statbox_to_change.stat_laps_count.stat_value = bolt_stats["laps_count"] + 1 # setget
	
	# weapons	
	statbox_to_change.stat_bullet.stat_value = bolt_stats["bullet_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_bullet.stat_value == 0:
			statbox_to_change.stat_bullet.hide()
		else:
			statbox_to_change.stat_bullet.show()	
	statbox_to_change.stat_misile.stat_value = bolt_stats["misile_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_misile.stat_value == 0:
			statbox_to_change.stat_misile.hide()
		else:
			statbox_to_change.stat_misile.show()	
	statbox_to_change.stat_mina.stat_value = bolt_stats["mina_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_mina.stat_value == 0:
			statbox_to_change.stat_mina.hide()
		else:
			statbox_to_change.stat_mina.show()		
	statbox_to_change.stat_shocker.stat_value = bolt_stats["shocker_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_shocker.stat_value == 0:
			statbox_to_change.stat_shocker.hide()
		else:
			statbox_to_change.stat_shocker.show()	

	# best lap time
	statbox_to_change.stat_best_lap.stat_value = bolt_stats["best_lap_time"]
	if not statbox_to_change.stat_best_lap.visible: # če je prvi krog moram stat še pokazat
		statbox_to_change.stat_best_lap.show()
	
	# level finished time
	statbox_to_change.stat_level_time.stat_value = bolt_stats["level_time"]
	if not statbox_to_change.stat_level_time.visible:
		statbox_to_change.stat_level_time.show()
	
	# GAME STATS
	
	# record lap
	if bolt_stats["best_lap_time"] < record_lap_time or record_lap_time == 0:
		record_lap_time = bolt_stats["best_lap_time"] 
		Met.write_clock_time(record_lap_time, record_lap_label.get_node("TimeLabel"))
		if not record_lap_label.visible:
			record_lap_label.show()		
	
	# level record
	#	if level_finished_time < record_level_time or record_level_time == 0:
	#		record_level_time = level_finished_time 
	#		var game_record_time_on_clock: String = "Record: " + Met.get_clock_time(record_level_time)
	#		statbox_to_change.stat_level_time.modulate = Set.color_green


