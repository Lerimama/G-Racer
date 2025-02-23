extends Control
#class_name Hud


var record_lap_time: int = 0
var level_lap_limit: int
var game_levels_count: int = 5

var statbox_count: int = 0
var statboxes_with_drivers: Dictionary = {} # statbox in njen driver

onready var sections_holder: HBoxContainer = $HudSections
onready var left_section: VBoxContainer = $HudSections/Left
onready var right_section: VBoxContainer = $HudSections/Right
onready var center_top: VBoxContainer = $HudSections/Center/Top
onready var center_btm: VBoxContainer = $HudSections/Center/Btm

onready var game_timer: HBoxContainer = $HudSections/Center/Top/GameTimer
onready var record_lap_label: Label = $HudSections/Center/Top/RecordLap
onready var level_name: Label = $HudSections/Center/Btm/LevelName

onready var start_countdown: Control = $Popups/StartCountdown

onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")
onready var StatBox: PackedScene = preload("res://game/gui/hud/StatBox.tscn")


func _ready() -> void:

	# debug reset
	for sec in [$HudSections/Left, $HudSections/Right]:
		for child in sec.get_children():
			child.queue_free()


func set_hud(game_manager):

	var level_lap_count: int = game_manager.level_profile["level_laps"]
	var level_time_limit: int = game_manager.level_profile["level_time_limit"]

	if game_manager.level_profile["level_type"] == Pfs.BASE_TYPE.RACING:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	# game stats
	game_levels_count = game_manager.game_levels.size()
	level_lap_limit = level_lap_count
	game_timer.stop_timer()
	game_timer.reset_timer(level_time_limit)
	game_timer.show()
	record_lap_label.hide()
	for section in sections_holder.get_children():
		section.show()

	# statboxes reset
	for statbox in statboxes_with_drivers:
		statbox.queue_free()
	statboxes_with_drivers.clear()
	statbox_count = 0

	# new statboxes
	for vehicle in game_manager.drivers_on_start:
		set_driver_statbox(vehicle, game_manager.level_profile["level_type"], game_manager.drivers_on_start.size())


func set_driver_statbox(statbox_driver: Vehicle, level_type: int, all_statboxes_count: int): # kliče GM

	statbox_count += 1

	# spawn left /right
	var new_statbox: VBoxContainer = StatBox.instance()
	if statbox_count % 2 == 0:
		right_section.add_child(new_statbox)
	else:
		left_section.add_child(new_statbox)

	statboxes_with_drivers[new_statbox] = statbox_driver

	var driver_stats: Dictionary = statbox_driver.driver_stats
	var driver_profile: Dictionary = Pfs.driver_profiles[statbox_driver.driver_name_id]

	# driver line
	new_statbox.driver_name_label.text = str(statbox_driver.driver_name_id)
	new_statbox.driver_name_label.modulate = driver_profile["driver_color"]
	new_statbox.driver_avatar.set_texture(driver_profile["driver_avatar"])

	# driver stats
	for stat in driver_stats:
		_on_driver_stat_changed(statbox_driver.driver_name_id, stat, driver_stats[stat])

	if all_statboxes_count == 1: # single player
		new_statbox.set_statbox_elements(level_type, true)
	else:
		new_statbox.set_statbox_elements(level_type)

	# če je predzadnji bo zadnji ... na levi strani
	# če je zadnji bo zadnji na drugi strani
	if statbox_count < all_statboxes_count - 1:
		new_statbox.set_statbox_align(statbox_count)
	else:
		new_statbox.set_statbox_align(statbox_count, true)

	new_statbox.show()


func on_game_start():

	game_timer.start_timer()


func on_level_over():

	for section in sections_holder.get_children():
		section.hide()


func on_game_over():

	for section in sections_holder.get_children():
		section.hide()


func _on_driver_stat_changed(driver_name_id, driver_stat_key: int, stat_value):
	# stat value je že preračunana, hud samo zapisuje

	# opredelim drive statbox
	var statbox_to_change: Control
	for statbox in statboxes_with_drivers:
		if statboxes_with_drivers[statbox].driver_name_id == driver_name_id:
			statbox_to_change = statbox
			break

	# stat_to_change ... STAT key string
	var current_key_index: int = Pfs.STATS.values().find(driver_stat_key)
	var current_key: String = Pfs.STATS.keys()[current_key_index]
	var stat_to_change: Control = statbox_to_change.get(current_key)

	# če je podan array elementov (laps finished, goals, wins, ...
	if stat_value is Array:
		# preverjam, če hočem current/max ... zadnja količina je int, ostale pa karkoli drugega
		var non_int_present: bool = false
		for value in stat_value:
			if not value is int:
				non_int_present = true
		# zadnja količina je int, ostale pa karkoli drugega
		if stat_value.back() is int and non_int_present:
			stat_value = [min(stat_value.size() - 1, stat_value.back()), stat_value.back()]
		# samo ena količina je int ... curr = 0/max
		elif stat_value.size() == 1 and stat_value.back() is int:
			stat_value = [0, stat_value.back()]
		# samo dve količini količina je int ... curr = [0] / max = [1]
		elif stat_value.size() == 2 and not non_int_present:# and stat_value.back() is int and stat_value.front() is int:
			stat_value = [min(stat_value.front(), stat_value.back()), stat_value.back()]
		else:
			# ni podatka o max value
			# če e tu ni bo treba RFK da bo pravilno
			stat_value = stat_value.size()
		printt ("po", stat_value)

	elif stat_value is PoolIntArray:
		#		print("int array")
		pass

	stat_to_change.stat_value = stat_value


func spawn_driver_floating_tag(tag_owner: Node2D, lap_time: float, best_lap: bool = false):

	var new_floating_tag = FloatingTag.instance()

	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = tag_owner.global_position
	new_floating_tag.tag_owner = tag_owner
	new_floating_tag.scale = Vector2.ONE * Sts.game_camera_zoom_factor

	new_floating_tag.content_to_show = lap_time
	new_floating_tag.tag_type = new_floating_tag.TAG_TYPE.TIME
	Rfs.node_creation_parent.add_child(new_floating_tag) # OPT ... floating bi raje v hudu
	if best_lap == true:
		new_floating_tag.modulate = Rfs.color_green
	else:
		new_floating_tag.modulate = Rfs.color_red
