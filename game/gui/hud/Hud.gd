extends Control


enum STATBOX_TYPE{BOX, BOX_MINIMAL, VER, VER_STRICT, VER_MINIMAL, HOR, MINIMAL}

var level_lap_count: int
var level_goals: Array = []
var level_record: Array # [value, owner]
var max_wins_count: int
var time_still_time: float = 1.5
var statboxes_with_drivers: Dictionary = {} # statbox in njen driver

onready var sections_holder: HBoxContainer = $HudSections
onready var left_section: VBoxContainer = $HudSections/Left
onready var right_section: VBoxContainer = $HudSections/Right
onready var center_top: VBoxContainer = $HudSections/Center/Top
onready var center_btm: VBoxContainer = $HudSections/Center/Btm

onready var level_name_label: Label = $HudSections/Center/Btm/LevelId/BoxContainer/LevelName
onready var level_record_label: Label = $HudSections/Center/Top/Record/BoxContainer/LevelRecord
onready var game_timer: HBoxContainer = $HudSections/Center/Top/Timer/BoxContainer/GameTimer

onready var start_countdown: Control = $Popups/StartCountdown
onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")

onready var StatBox_Boxed: PackedScene = preload("res://game/gui/hud/StatBox_Boxed.tscn")
onready var StatBox_Boxed_Minimal: PackedScene = preload("res://game/gui/hud/StatBox_Boxed_Minimal.tscn")
onready var StatBox_Hor: PackedScene = preload("res://game/gui/hud/StatBox_Hor.tscn")
onready var StatBox_Ver: PackedScene = preload("res://game/gui/hud/StatBox_Ver.tscn")
onready var StatBox_Ver_Strict: PackedScene = preload("res://game/gui/hud/StatBox_Ver_Strict.tscn")
onready var StatBox_Ver_Minimal: PackedScene = preload("res://game/gui/hud/StatBox_Ver_Minimal.tscn")
onready var StatBox_Minimal: PackedScene = preload("res://game/gui/hud/StatBox_Minimal.tscn")

var level_profile: Dictionary = {} # za zapisovanje rekorda


func _ready() -> void:

	# debug reset
	for sec in [$HudSections/Left, $HudSections/Right]:
		for child in sec.get_children():
			child.queue_free()


func set_hud(game_manager: Game):

	level_profile = game_manager.level_profile
	level_lap_count = game_manager.level_profile["level_laps"]
	level_goals = game_manager.level_profile["level_goals"]
	max_wins_count = game_manager.curr_game_settings["max_wins_count"]

	var level_time_limit: int = game_manager.level_profile["level_time_limit"]

	if level_profile["rank_by"] == Pfs.RANK_BY.TIME:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	level_name_label.text = level_profile["level_name"]

	# game stats
	game_timer.stop_timer()
	game_timer.reset_timer(level_time_limit)
	game_timer.get_parent().get_parent().show()
	level_record_label.get_parent().get_parent().hide()
	for section in sections_holder.get_children():
		section.show()

	# statboxes reset
	for statbox in statboxes_with_drivers:
		statbox.queue_free()
	statboxes_with_drivers.clear()

	# new statboxes
	var viewed_drivers: Array = []
	for driver in game_manager.drivers_on_start:
		if not driver.motion_manager.is_ai:
			viewed_drivers.append(driver)
	for viewed_driver in viewed_drivers:
		set_driver_statbox(viewed_driver, viewed_drivers.find(viewed_driver), viewed_drivers.size(), game_manager.level_profile["rank_by"])

	# level rekord
	level_record = game_manager.level_profile["level_record"]
	if not level_record[0] == 0:
		var level_record_clock_time: String = Mts.get_clock_time_string(level_record[0])
		level_record_label.text = "LEVEL RECORD " + level_record_clock_time + " by " + str(level_record[1])
		level_record_label.get_parent().get_parent().show()


func on_game_start():

	game_timer.start_timer()


func on_game_over():

	for section in sections_holder.get_children():
		section.hide()


func set_driver_statbox(statbox_driver: Vehicle, statbox_index: int, all_statboxes_count: int, rank_by: int): # kliče GM

	var NewStatBox: PackedScene #= StatBox
	NewStatBox = _get_statbox_by_type(statbox_index, all_statboxes_count)

	var new_statbox: BoxContainer = NewStatBox.instance()
	if statbox_index % 2 == 0:
		left_section.add_child(new_statbox)
	else:
		right_section.add_child(new_statbox)

	statboxes_with_drivers[new_statbox] = statbox_driver.driver_id

	var driver_stats: Dictionary = statbox_driver.driver_stats
	var driver_profile: Dictionary = statbox_driver.driver_profile

	# driver line
	new_statbox.driver_name_label.text = str(statbox_driver.driver_id)
	new_statbox.driver_name_label.modulate = driver_profile["driver_color"]
	new_statbox.driver_avatar.set_texture(driver_profile["driver_avatar"])

	if all_statboxes_count == 1: # single player
		new_statbox.set_statbox_elements(rank_by, true)
	else:
		new_statbox.set_statbox_elements(rank_by)

	# določim zadnje v sekcijah ... spawnani so levo, denos, levo, desno, ...
	var left_side_statboxes_count: int = ceil(all_statboxes_count / 2)
	if statbox_index == left_side_statboxes_count or statbox_index == all_statboxes_count - 1:
		new_statbox.set_statbox_align(statbox_index, true)
	else:
		new_statbox.set_statbox_align(statbox_index)

	# driver stats
	for stat in driver_stats:
		_on_driver_stat_changed(statbox_driver.driver_id, stat, driver_stats[stat])

	new_statbox.show()

	statbox_index += 1 # pred idle, ker je na vrsti že naslednja


func _get_statbox_by_type(statbox_index: int, all_statboxes_count: int):

	var statbox_type: int = 0

	if all_statboxes_count == 1:
		statbox_type = STATBOX_TYPE.VER_STRICT
	elif Sts.one_screen_mode:
		if all_statboxes_count <= 4:
			statbox_type = STATBOX_TYPE.BOX
		elif all_statboxes_count <= 10:
			statbox_type = STATBOX_TYPE.BOX_MINIMAL
		else:
			statbox_type = STATBOX_TYPE.MINIMAL
	else:
		if all_statboxes_count <= 2:
			statbox_type = STATBOX_TYPE.VER_STRICT
		elif all_statboxes_count == 3:
			if statbox_index == 1: # desni view je večji
				statbox_type = STATBOX_TYPE.BOX
#				statbox_type = STATBOX_TYPE.VER_STRICT
			else:
				statbox_type = STATBOX_TYPE.VER_MINIMAL
		elif all_statboxes_count == 4:
			statbox_type = STATBOX_TYPE.VER_MINIMAL

	match statbox_type:
		STATBOX_TYPE.BOX:
			return StatBox_Boxed
		STATBOX_TYPE.BOX_MINIMAL:
			return StatBox_Boxed_Minimal
		STATBOX_TYPE.VER:
			return StatBox_Ver
		STATBOX_TYPE.VER_STRICT:
			return StatBox_Ver_Strict
		STATBOX_TYPE.VER_MINIMAL:
			return StatBox_Ver_Minimal
		STATBOX_TYPE.HOR:
			return StatBox_Hor
		STATBOX_TYPE.MINIMAL:
			return StatBox_Minimal


func _on_driver_stat_changed(driver_id: String, stat_key: int, stat_value):
	# stat value je že preračunana, končna vrednost
	# tukaj se opredeli obliko zapisa

	if Pfs.driver_profiles[driver_id]["driver_type"] == Pfs.DRIVER_TYPE.AI and Sts.ai_gets_record:
		if stat_key == Pfs.STATS.BEST_LAP_TIME and not stat_value == 0:
			if stat_value < level_record[0] and not level_record[0] == 0:
				var new_level_record: Array = [stat_value, driver_id]
				var level_record_clock_time: String = Mts.get_clock_time_string(new_level_record[0])
				level_profile["level_record"] = new_level_record
				level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(new_level_record[1])
				level_record_label.get_parent().get_parent().show()
				level_record_label.modulate = Rfs.color_green
				yield(get_tree().create_timer(time_still_time), "timeout")
				level_record_label.modulate = Color.white
	else:
		# opredelim statbox
		var statbox_to_change: Control
		if driver_id in statboxes_with_drivers.values():
			var statbox: Control = statboxes_with_drivers.find_key(driver_id)
			if statbox != null: # find key lahko vrne null
				statbox_to_change = statbox
		if not statbox_to_change: # ai ga nima, statistiko pa vseeno pošilja
			return

		# stat_to_change ... STAT key string
		var current_key_index: int = Pfs.STATS.values().find(stat_key)
		var current_key: String = Pfs.STATS.keys()[current_key_index]
		var stat_to_change: Control = statbox_to_change.get(current_key)

		match stat_key:

			# stat_value = Int, Float
			Pfs.STATS.GAS:
				stat_to_change.stat_value = stat_value
			Pfs.STATS.HEALTH: # ENERGY BAR
				# 10 = 100 % v pseudo-bar
				var curr_health_percent: int = round(stat_value * 10)
				stat_to_change.stat_value = [curr_health_percent, 10]
			Pfs.STATS.LIFE:
				stat_to_change.stat_value = [stat_value, 3]
			Pfs.STATS.CASH:
				stat_to_change.stat_value = stat_value
			Pfs.STATS.POINTS: # default
				stat_to_change.stat_value = stat_value

			# stat_value = Array
			Pfs.STATS.GOALS_REACHED:
				stat_to_change.stat_value = [stat_value.size(), level_goals.size()]
			Pfs.STATS.WINS:
				# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
				#			stat_to_change.stat_value = [stat_value.size(), Sts.wins_goal_count]
				stat_to_change.stat_value = stat_value.size()

			# level
			Pfs.STATS.LEVEL_RANK:
				stat_to_change.stat_value = stat_value
			Pfs.STATS.LEVEL_TIME:
				stat_to_change.stat_value = stat_value
			Pfs.STATS.LAP_COUNT: # vsakič, ko gre čez finish
				stat_to_change.stat_value = [stat_value.size(), level_lap_count]
				# apdejtam tudi LAP TIME prikaz
				var time_stat: Control = statbox_to_change.get("LAP_TIME")
				time_stat.stat_value = stat_value.back()
				# stoječi prikaz časa kroga
				if not time_stat.stat_value == 0:
					var time_still_stat: Control = statbox_to_change.get("lap_time_still")
					time_still_stat.stat_value = time_stat.stat_value
					time_still_stat.modulate = Rfs.color_red # zeleno ga obarva BEST LAP event
					time_stat.hide()
					time_still_stat.show()
					yield(get_tree().create_timer(time_still_time), "timeout")
					time_still_stat.hide()
					time_stat.show()
			Pfs.STATS.BEST_LAP_TIME:
				if not stat_value == 0:
					# statičen čas zapišem kot string
					var stat_to_change_clock_time: String = Mts.get_clock_time_string(stat_value)
					stat_to_change.stat_value = stat_to_change_clock_time
					stat_to_change.get_parent().get_parent().show()
					# obarvam stoječi prikaz časa kroga
					statbox_to_change.get("lap_time_still").modulate = Rfs.color_green
					# je tudi rekord levela?
					if stat_value < level_record[0] and not level_record[0] == 0:
						var new_level_record: Array = [stat_value, driver_id]
						var level_record_clock_time: String = Mts.get_clock_time_string(new_level_record[0])
						level_profile["level_record"] = new_level_record
						level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(new_level_record[1])
						level_record_label.get_parent().get_parent().show()
						level_record_label.modulate = Rfs.color_green
						yield(get_tree().create_timer(time_still_time), "timeout")
						level_record_label.modulate = Color.white
			Pfs.STATS.LAP_TIME: # za uro med krogom ... vsak frejm
				stat_to_change.stat_value = stat_value
			_: # ammo, ...
				#				stat_to_change.stat_value = stat_value
				pass


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
