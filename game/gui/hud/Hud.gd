extends Control


enum STATBOX_TYPE{BOX, BOX_MINIMAL, VER, VER_STRICT, VER_MINIMAL, HOR, MINIMAL}

var level_record: Array = [0, ""]# [value, owner]
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
onready var StatBox_Hor: PackedScene = preload("res://game/gui/hud/StatBox_Hor_temp.tscn")
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


func set_hud(game_manager: Game, drivers_on_start: Array):

	level_profile = game_manager.level_profile

	if level_profile["rank_by"] == Pros.RANK_BY.TIME:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	# game stats
	game_timer.stop_timer()
	game_timer.reset_timer(level_profile["level_time_limit"])
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
	for driver in drivers_on_start:
		if not driver.is_in_group(Refs.group_ai):
#		if not driver.motion_manager.is_ai:
			viewed_drivers.append(driver)
	for viewed_driver in viewed_drivers:
		var driver_index: int = viewed_drivers.find(viewed_driver)
		_set_driver_statbox(viewed_driver, driver_index, viewed_drivers.size())

	# level rekord
	var level_record_value: int = level_profile["level_record"][0]
	var level_record_owner: String = level_profile["level_record"][1]
	if not level_record_value == 0:
		if level_profile["rank_by"] == Pros.RANK_BY.TIME:
			var level_record_clock_time: String = Mets.get_clock_time_string(level_record_value)
			level_record_label.text = "RECORD TIME: " + level_record_clock_time + " by " + str(level_record_owner)
			level_record_label.get_parent().get_parent().show()
		elif level_profile["rank_by"] == Pros.RANK_BY.POINTS:
			level_record_label.text = "RECORD POINTS: " + str(level_record_value) + " by " + str(level_record_owner)
			level_record_label.get_parent().get_parent().show()
		else:
			level_record_label.get_parent().get_parent().hide()

	# level name
	level_name_label.text = level_profile["level_name"]


func on_game_start():

	game_timer.start_timer()


func on_game_over():

	for section in sections_holder.get_children():
		section.hide()


func _set_driver_statbox(statbox_driver: Vehicle, statbox_index: int, all_statboxes_count: int):

	var NewStatBox: PackedScene #= StatBox
	NewStatBox = _get_statbox_by_type(statbox_index, all_statboxes_count)

	var new_statbox: BoxContainer = NewStatBox.instance()
	if statbox_index % 2 == 0:
		left_section.add_child(new_statbox)
	else:
		right_section.add_child(new_statbox)

	statboxes_with_drivers[new_statbox] = statbox_driver.driver_id

	# driver line
	new_statbox.driver_name_label.text = str(statbox_driver.driver_id)
	new_statbox.driver_avatar.set_texture(statbox_driver.driver_profile["driver_avatar"])
	new_statbox.driver_name_label.modulate = statbox_driver.driver_profile["driver_color"]
	new_statbox.statbox_color = statbox_driver.driver_profile["driver_color"]

	# statbox
	var one_life_mode: bool = false
	if statbox_driver.driver_stats[Pros.STATS.LIFE] == 1 and not Sets.life_as_scalp:
		one_life_mode = true
	new_statbox.set_statbox_stats( \
		level_profile["rank_by"],
		level_profile["level_laps"],
		level_profile["level_goals"].size(), # statbox sam opredeli ali upošteva finish line
		all_statboxes_count,
		one_life_mode
		)

	# levo / desno
	if statbox_index % 2 == 0:
		# zadnja na desni je predzadnja skupno
		if statbox_index + 1 == all_statboxes_count - 1:
			new_statbox.set_statbox_align(-1, true)
		else:
			new_statbox.set_statbox_align(-1)
	else:
		# zadnja na levi je zadnja skupno
		if statbox_index + 1 == all_statboxes_count:
			new_statbox.set_statbox_align(1, true)
		else:
			new_statbox.set_statbox_align(1)

	# driver stats
	for stat in statbox_driver.driver_stats:
		_on_driver_stat_changed(statbox_driver.driver_id, stat, statbox_driver.driver_stats[stat])

	new_statbox.show()

	statbox_index += 1 # pred idle, ker je na vrsti že naslednja


func _get_statbox_by_type(statbox_index: int, all_statboxes_count: int):

	var statbox_type: int = 0

	if all_statboxes_count == 1:
		statbox_type = STATBOX_TYPE.VER_STRICT
	elif Sets.mono_view_mode:
		if all_statboxes_count <= 4:
#			statbox_type = STATBOX_TYPE.BOX
			statbox_type = STATBOX_TYPE.VER
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

	if Pros.start_driver_profiles[driver_id]["controller_type"] == -1 and Sets.ai_gets_record:
		if stat_key == Pros.STATS.BEST_LAP_TIME and not stat_value == 0:
			var level_record_value = level_profile["level_record"][0]
			if stat_value < level_record_value and not level_record_value == 0:
				var new_level_record: Array = [stat_value, driver_id]
				var level_record_clock_time: String = Mets.get_clock_time_string(new_level_record[0])
				level_profile["level_record"] = new_level_record
				level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(new_level_record[1])
				level_record_label.get_parent().get_parent().show()
				level_record_label.modulate = Refs.color_green
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
		var current_key_index: int = Pros.STATS.values().find(stat_key)
		var current_key: String = Pros.STATS.keys()[current_key_index]
		var stat_to_change: Control = statbox_to_change.get(current_key)

		match stat_key:

			# driver
			Pros.STATS.LIFE:
				stat_to_change.stat_value = [stat_value, 3]
			Pros.STATS.CASH:
				stat_to_change.stat_value = stat_value
			Pros.STATS.POINTS: # default
				stat_to_change.stat_value = stat_value
			Pros.STATS.WINS:
				# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
				#			stat_to_change.stat_value = [stat_value.size(), Sets.wins_needed]
				stat_to_change.stat_value = stat_value.size()
			# vehicle
			Pros.STATS.GAS:
				stat_to_change.stat_value = stat_value
			Pros.STATS.HEALTH: # ENERGY BAR
				# 10 = 100 % v pseudo-bar
				var curr_health_percent: int = round(stat_value * 10)
				stat_to_change.stat_value = [curr_health_percent, 10]
			# level
			Pros.STATS.LEVEL_RANK:
				stat_to_change.stat_value = stat_value
			Pros.STATS.LEVEL_PROGRESS:
				stat_to_change.progress_unit = stat_value
			Pros.STATS.LEVEL_TIME: # on level finish
				stat_to_change.stat_value = stat_value
			Pros.STATS.GOALS_REACHED:
				# progress bar
				if statbox_to_change.use_level_progress_bar:
					# če so goali, ni per frame apdejtanja iz tracking line
					# ta statistika deluje samo, če level_goals niso prazni ... RACING_GOALS, BATTLE_GOALS
					# RACING_GOAL ima finish_line enabled
					# BATTLE_GOAL ima finish_line disabled
					# RACING_GOALS brez goalov ima samo finish line ... pedena ga LAP_COUNT stat
					var adapted_max_count: float = level_profile["level_goals"].size()
					if level_profile["rank_by"] == Pros.RANK_BY.TIME:
						adapted_max_count = level_profile["level_goals"].size() + 1
					statbox_to_change.LEVEL_PROGRESS.progress_unit = stat_value.size() / adapted_max_count
				# goal counter
				stat_to_change.stat_value = [stat_value.size(), level_profile["level_goals"].size()]
			Pros.STATS.LAP_COUNT:
				# progress bar za kroge je opazen samo, če ni "tracking progress per frame "
				if statbox_to_change.use_level_progress_bar:
					# če so goali, je krog celoten progress bar
					if not level_profile["level_goals"].empty():
						statbox_to_change.LEVEL_PROGRESS.progress_unit = 1
						# reset za naslednji krog, če ni bi zadnji
						if stat_value.size() < level_profile["level_laps"]:
							yield(get_tree().create_timer(time_still_time), "timeout")
							statbox_to_change.LEVEL_PROGRESS.progress_unit = 0
					# če ni goalov in so krogi, je krog en tick, level finish pa je celoten progress bar
					elif level_profile["level_laps"] > 1:
						statbox_to_change.LEVEL_PROGRESS.progress_unit = stat_value.size() / float(level_profile["level_laps"])
					# brez lapsov niti golaov
					else:
						statbox_to_change.LEVEL_PROGRESS.progress_unit = 1
				# lap count counter
				stat_to_change.stat_value = [stat_value.size(), level_profile["level_laps"]]
				# lap time
				var time_stat: Control = statbox_to_change.get("LAP_TIME")
				if not stat_value.empty():
					time_stat.stat_value = stat_value.back()
					# stoječi prikaz časa kroga
					if not time_stat.stat_value == 0:
						var time_still_stat: Control = statbox_to_change.lap_time_still_display
						time_still_stat.stat_value = time_stat.stat_value
						time_still_stat.modulate = Refs.color_red # zeleno ga obarva BEST LAP event
						time_stat.hide()
						time_still_stat.show()
						yield(get_tree().create_timer(time_still_time), "timeout")
						time_still_stat.hide()
						time_stat.show()
			Pros.STATS.BEST_LAP_TIME:
				if stat_value == 0:
					stat_to_change.stat_value = 0
					stat_to_change.get_parent().get_parent().hide()
				else:
					# statičen čas zapišem kot string
					var stat_to_change_clock_time: String = Mets.get_clock_time_string(stat_value)
					stat_to_change.stat_value = stat_to_change_clock_time
					stat_to_change.get_parent().get_parent().show()
					# obarvam stoječi prikaz časa kroga
					statbox_to_change.lap_time_still_display.modulate = Refs.color_green
					# je tudi rekord levela?
					if stat_value < level_record[0] and not level_record[0] == 0:
						var new_level_record: Array = [stat_value, driver_id]
						var level_record_clock_time: String = Mets.get_clock_time_string(new_level_record[0])
						level_profile["level_record"] = new_level_record
						level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(new_level_record[1])
						level_record_label.get_parent().get_parent().show()
						level_record_label.modulate = Refs.color_green
						yield(get_tree().create_timer(time_still_time), "timeout")
						level_record_label.modulate = Color.white
			Pros.STATS.LAP_TIME: # za uro med krogom ... vsak frejm
				stat_to_change.stat_value = stat_value
			_:
				#				stat_to_change.stat_value = stat_value
				printerr("Neznana statistika na hudu: ", stat_to_change, ", ", stat_value)


func spawn_driver_floating_tag(tag_owner: Node2D, lap_time: float, best_lap: bool = false):

	var new_floating_tag = FloatingTag.instance()

	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = tag_owner.global_position
	new_floating_tag.tag_owner = tag_owner
	new_floating_tag.scale = Vector2.ONE * Sets.game_camera_zoom_factor

	new_floating_tag.content_to_show = lap_time
	new_floating_tag.tag_type = new_floating_tag.TAG_TYPE.TIME
	Refs.node_creation_parent.add_child(new_floating_tag) # OPT ... floating bi raje v hudu
	if best_lap == true:
		new_floating_tag.modulate = Refs.color_green
	else:
		new_floating_tag.modulate = Refs.color_red
