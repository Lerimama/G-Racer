extends Control


var record_lap_time: int = 0
var record_level_time: int = 0

onready var statboxes: Array = [$StatBox, $StatBox2, $StatBox3, $StatBox4]

onready var record_lap_label: Label = $RecordLap
onready var game_timer: Control = $"%GameTimer"
onready var start_countdown: Control = $"%StartCountdown"
onready var level_name: Label = $LevelName

onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")


func _ready() -> void:
#	print("HUD")

	Rfs.hud = self

	# skrij vse statboxe, ki se prikažejo, če je spawnan bolt
	for box in statboxes:
		box.hide()

	Rfs.game_manager.connect("bolt_spawned", self, "_on_bolt_spawned") # signal pride iz GM in pošlje spremenjeno statistiko


func set_hud(): # kliče GM

	# game stats
	match Rfs.current_level.level_type:
		Rfs.current_level.LEVEL_TYPE.RACE, Rfs.current_level.LEVEL_TYPE.RACE_LAPS:
			game_timer.hunds_mode = true
	game_timer.show()
	record_lap_label.hide()

	# driver stats
	for box in statboxes:
		# najprej skrijem vse in potem pokažem glede na igro
		for stat in box.get_children():
			record_lap_label.hide()
			stat.hide()
		box.driver_line.show()

		box.stat_cash.show()
		box.stat_gas.show()
		box.stat_points.show()
		# debug .... statistika orožja
		box.stat_bullet.show()
		box.stat_misile.show()
		box.stat_mina.show()
		match Rfs.current_level.level_type:
			Rfs.current_level.LEVEL_TYPE.BATTLE:
				# pokažem: wins, life, gas, points, rank
				# skrijem: timer stotinke
				box.stat_wins.show()
				box.stat_life.show()
				box.stat_level_rank.show()
			Rfs.current_level.LEVEL_TYPE.RACE:
				box.stat_wins.show()
				box.stat_level_rank.show()
				box.stat_level_time.show()
			Rfs.current_level.LEVEL_TYPE.RACE_LAPS:
				box.stat_wins.show()
				box.stat_level_rank.show()
				box.stat_laps_count.show()
				box.stat_best_lap.show()
				box.stat_level_time.show()
			Rfs.current_level.LEVEL_TYPE.CHASE:
				box.stat_gas.show()


func on_game_start():

	game_timer.start_timer()


func on_level_finished():
	game_timer.stop_timer()


func on_game_over():

	game_timer.stop_timer()
	hide_stats()


func hide_stats():

	for box in statboxes:
		box.hide()
	game_timer.hide()
	record_lap_label.hide()


func spawn_bolt_floating_tag(tag_owner: Node2D, lap_time: float, best_lap: bool):

	var new_floating_tag = FloatingTag.instance()

	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = tag_owner.global_position
	new_floating_tag.tag_owner = tag_owner
	new_floating_tag.scale = Vector2.ONE * Sts.game_camera_zoom_factor

	new_floating_tag.content_to_show = lap_time
	new_floating_tag.current_tag_type = new_floating_tag.TAG_TYPE.TIME
	Rfs.node_creation_parent.add_child(new_floating_tag) # OPT ... floating bi raje v hudu
	if best_lap == true:
		new_floating_tag.modulate = Rfs.color_green
	else:
		new_floating_tag.modulate = Rfs.color_red



# PRIVAT ------------------------------------------------------------------------------------------------------------


func _on_bolt_spawned(spawned_bolt: Node2D):

	#	if spawned_bolt.is_in_group(Rfs.group_ai): # če je AI ne rabim hud statsov ... zaenkrat
	#		return

	var loading_time: float = 0.5 # pred prikazom naj se v miru postavi
	var spawned_driver_statbox: Control = statboxes[spawned_bolt.driver_id]
	var spawned_driver_stats: Dictionary = spawned_bolt.driver_stats
	var spawned_driver_profile: Dictionary = Pfs.driver_profiles[spawned_bolt.driver_id]

	# bolt stats
	spawned_driver_statbox.stat_bullet.stat_value = spawned_driver_stats["bullet_count"]
	spawned_driver_statbox.stat_misile.stat_value = spawned_driver_stats["misile_count"]
	spawned_driver_statbox.stat_mina.stat_value = spawned_driver_stats["mina_count"]
	spawned_driver_statbox.stat_gas.stat_value = spawned_driver_stats["gas_count"]
	spawned_driver_statbox.stat_life.stat_value = spawned_driver_stats["life"]
	spawned_driver_statbox.stat_points.stat_value = spawned_driver_stats["points"]
	spawned_driver_statbox.stat_cash.stat_value = spawned_driver_stats["cash_count"]
	spawned_driver_statbox.stat_wins.stat_value = spawned_driver_stats["wins"]

	# driver line
	spawned_driver_statbox.driver_name_label.text = spawned_driver_profile["driver_name"]
	spawned_driver_statbox.driver_name_label.modulate = spawned_driver_profile["driver_color"]
	spawned_driver_statbox.driver_avatar.set_texture(spawned_driver_profile["driver_avatar"])
	spawned_driver_statbox.stat_wins.modulate = Color.red
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	spawned_driver_statbox.visible = true


func _on_GameTimer_gametime_is_up() -> void:

	#	if Rfs.current_level.level_type == Rfs.current_level.LEVEL_TYPE.BATTLE:
	Rfs.game_manager.level_finished()


func _on_stats_changed(driver_id: int, driver_stats: Dictionary):
	var statbox_to_change: Control = statboxes[driver_id] # bolt id kot index je enak indexu statboxa v statboxih

	statbox_to_change.stat_wins.stat_value = driver_stats["wins"] # setget
	statbox_to_change.stat_life.stat_value = driver_stats["life"]
	statbox_to_change.stat_bullet.stat_value = driver_stats["bullet_count"]
	statbox_to_change.stat_misile.stat_value = driver_stats["misile_count"]
	statbox_to_change.stat_mina.stat_value = driver_stats["mina_count"]
	statbox_to_change.stat_points.stat_value = driver_stats["points"]
	statbox_to_change.stat_cash.stat_value = driver_stats["cash_count"]
	statbox_to_change.stat_gas.stat_value = driver_stats["gas_count"]
	statbox_to_change.stat_level_rank.stat_value = driver_stats["level_rank"]
	statbox_to_change.stat_laps_count.stat_value = driver_stats["laps_count"] + 1 # +1 ker kaže trnenutnega, ne končanega
	statbox_to_change.stat_best_lap.stat_value = driver_stats["best_lap_time"]
	statbox_to_change.stat_level_time.stat_value = driver_stats["level_time"]

	# level record time
	if not driver_stats["best_lap_time"] == 0:
		if driver_stats["best_lap_time"] < record_lap_time or record_lap_time == 0:
			record_lap_time = driver_stats["best_lap_time"]
			Mts.write_clock_time(record_lap_time, record_lap_label.get_node("TimeLabel"))
			if not record_lap_label.visible:
				record_lap_label.show()


func _on_game_state_change(new_game_state, level_settings):
	pass
