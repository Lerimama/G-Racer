extends Control


var loading_time: float = 0.5 # pred prikazom naj se v miru postavi
var record_lap_time: int = 0 #setget _on_lap_record_changed # stotinke 
var record_level_time: int = 0 # setget _on_level_record_changed # stotinke 

onready var statboxes: Array = [$StatBox, $StatBox2, $StatBox3, $StatBox4]

onready var record_lap_label: Label = $GameStats/RecordLap
onready var game_stats: VBoxContainer = $GameStats
onready var game_timer: Control = $"%GameTimer"
onready var start_countdown: Control = $"%StartCountdown"
onready var level_name: Label = $LevelName

onready var FloatingTag: PackedScene = preload("res://game/ui/FloatingTag.tscn")


func _ready() -> void:
	
	print("HUD")
	Ref.hud = self	
	
	# skrij vse statboxe, ki se prikažejo, če je spawnan bolt
	for box in statboxes:
		box.hide()
	
	Ref.game_manager.connect("bolt_spawned", self, "_on_bolt_spawned") # signal pride iz GM in pošlje spremenjeno statistiko


func set_hud(): # kliče GM
	
	# player stats
	for box in statboxes:
		# najprej skrijem vse in potem pokažem glede na igro
		for stat in box.get_children():
			record_lap_label.hide()
			stat.hide()
		match Ref.current_level.level_type:
			Ref.current_level.LevelTypes.BATTLE:
				# pokažem: wins, life, gas, points, rank
				# skrijem: timer stotinke 
				box.stat_wins.show()
				box.stat_life.show()
				box.stat_gas.show()
				box.stat_points.show()
				box.stat_level_rank.show()
			Ref.current_level.LevelTypes.RACE:
				# pokažem: wins, life, gas, points, rank, level time
				box.stat_wins.show()
				box.stat_life.show()
				box.stat_gas.show()
				box.stat_points.show()
				box.stat_level_rank.show()
				box.stat_level_time.show()
			Ref.current_level.LevelTypes.RACE_LAPS:
				# pokažem: wins, life, gas, points, rank, lap, best lap, level time
				box.stat_wins.show()
				box.stat_life.show()
				box.stat_gas.show()
				box.stat_points.show()
				box.stat_level_rank.show()
				box.stat_laps_count.show()
				box.stat_best_lap.show()
				box.stat_level_time.show()
	
	# timer
	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		game_timer.hunds_mode = false
	
							
func on_game_start():
	
	game_stats.show()
	game_timer.start_timer()


func on_level_finished():
	game_timer.stop_timer()
	
	
func on_game_over():
	
	game_timer.stop_timer()
	hide_stats()
	

func hide_stats():

	for box in statboxes:
		box.hide() 	
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
		new_floating_tag.modulate = Ref.color_green
	else:
		new_floating_tag.modulate = Ref.color_red
	
	
	
# PRIVAT ------------------------------------------------------------------------------------------------------------

	
func _on_bolt_spawned(spawned_bolt: KinematicBody2D):
	
	if spawned_bolt.is_in_group(Ref.group_ai): # če je AI ne rabim hud statsov ... zaenkrat
		return
		
	var spawned_player_statbox: Control = statboxes[spawned_bolt.bolt_id]
	var spawned_player_stats: Dictionary = spawned_bolt.player_stats
	var spawned_player_profile: Dictionary = Pro.player_profiles[spawned_bolt.bolt_id]
	
	# bolt stats
	spawned_player_statbox.stat_bullet.stat_value = spawned_player_stats["bullet_count"]
	spawned_player_statbox.stat_misile.stat_value = spawned_player_stats["misile_count"]
	spawned_player_statbox.stat_mina.stat_value = spawned_player_stats["mina_count"]
	spawned_player_statbox.stat_shocker.stat_value = spawned_player_stats["shocker_count"]
	spawned_player_statbox.stat_gas.stat_value = spawned_player_stats["gas_count"]
	spawned_player_statbox.stat_life.stat_value = spawned_player_stats["life"]
	spawned_player_statbox.stat_points.stat_value = spawned_player_stats["points"]
	spawned_player_statbox.stat_wins.stat_value = spawned_player_stats["wins"]
	
	# player line
	spawned_player_statbox.player_name_label.modulate = spawned_player_profile["player_color"]
	spawned_player_statbox.player_name_label.text = spawned_player_profile["player_name"]
	spawned_player_statbox.player_avatar.set_texture(spawned_player_profile["player_avatar"])
	spawned_player_statbox.stat_wins.modulate = Color.red
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	spawned_player_statbox.visible = true


func _on_GameTimer_gametime_is_up() -> void:
	
	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		Ref.game_manager.level_finished()

	
func _on_stats_changed(bolt_id: int, player_stats: Dictionary):
	
	var statbox_to_change: Control = statboxes[bolt_id] # bolt id kot index je enak indexu statboxa v statboxih
			
	statbox_to_change.stat_wins.stat_value = player_stats["wins"] # setget
	statbox_to_change.stat_life.stat_value = player_stats["life"] # setget
	statbox_to_change.stat_points.stat_value = player_stats["points"] # setget
	statbox_to_change.stat_gas.stat_value = player_stats["gas_count"] # setget	
	statbox_to_change.stat_level_rank.stat_value = player_stats["level_rank"] # setget
	statbox_to_change.stat_laps_count.stat_value = player_stats["laps_count"] + 1 # setget
	
	# weapons	
	statbox_to_change.stat_bullet.stat_value = player_stats["bullet_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_bullet.stat_value == 0:
			statbox_to_change.stat_bullet.hide()
		else:
			statbox_to_change.stat_bullet.show()	
	statbox_to_change.stat_misile.stat_value = player_stats["misile_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_misile.stat_value == 0:
			statbox_to_change.stat_misile.hide()
		else:
			statbox_to_change.stat_misile.show()	
	statbox_to_change.stat_mina.stat_value = player_stats["mina_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_mina.stat_value == 0:
			statbox_to_change.stat_mina.hide()
		else:
			statbox_to_change.stat_mina.show()		
	statbox_to_change.stat_shocker.stat_value = player_stats["shocker_count"] # setget
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if statbox_to_change.stat_shocker.stat_value == 0:
			statbox_to_change.stat_shocker.hide()
		else:
			statbox_to_change.stat_shocker.show()	

	# best lap time
	statbox_to_change.stat_best_lap.stat_value = player_stats["best_lap_time"]
	if not statbox_to_change.stat_best_lap.visible: # če je prvi krog moram stat še pokazat
		statbox_to_change.stat_best_lap.show()
	
	# level finished time
	statbox_to_change.stat_level_time.stat_value = player_stats["level_time"]
	if not statbox_to_change.stat_level_time.visible:
		statbox_to_change.stat_level_time.show()
	
	# record lap
	if player_stats["best_lap_time"] < record_lap_time or record_lap_time == 0:
		record_lap_time = player_stats["best_lap_time"] 
		Met.write_clock_time(record_lap_time, record_lap_label.get_node("TimeLabel"))
		if not record_lap_label.visible:
			record_lap_label.show()		
	
	# level record
	#	if level_finished_time < record_level_time or record_level_time == 0:
	#		record_level_time = level_finished_time 
	#		var game_record_time_on_clock: String = "Record: " + Met.get_clock_time(record_level_time)
	#		statbox_to_change.stat_level_time.modulate = Ref.color_green
