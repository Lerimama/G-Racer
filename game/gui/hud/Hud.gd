extends Control


enum STATBOX_TYPE{BOX, BOX_MINIMAL, VER, VER_STRICT, VER_MINIMAL, MINIMAL}

var level_record: Array = [0, ""]# [value, owner]
var time_still_time: float = 1.5
var statboxes_with_driver_ids: Dictionary = {} # statbox in njen driver

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

onready var StatBox_Boxed: PackedScene = preload("res://game/gui/hud/statbox/StatBox.tscn")
onready var StatBox_Boxed_Minimal: PackedScene = preload("res://game/gui/hud/statbox/StatBox_Boxed_Minimal.tscn")
onready var StatBox_Ver: PackedScene = preload("res://game/gui/hud/statbox/StatBox_Ver.tscn")
onready var StatBox_Ver_Strict: PackedScene = preload("res://game/gui/hud/statbox/StatBox_Ver_Strict.tscn")
onready var StatBox_Ver_Minimal: PackedScene = preload("res://game/gui/hud/statbox/StatBox_Ver_Minimal.tscn")
onready var StatBox_Minimal: PackedScene = preload("res://game/gui/hud/statbox/StatBox_Minimal.tscn")

var level_profile: Dictionary = {} # za zapisovanje rekorda
onready var driver_huds: Control = $"../DriverHuds"


func _ready() -> void:

	# debug reset
	for sec in [$HudSections/Left, $HudSections/Right]:
		for child in sec.get_children():
			child.queue_free()


func set_hud(game: Game, drivers_on_start: Array):

	level_profile = game.level_profile

	if level_profile["rank_by"] == Levs.RANK_BY.TIME:
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

	# statboxes reset ... če je pravilno ugasnjen je to odveč
	for statbox in statboxes_with_driver_ids:
		statbox.queue_free()
	statboxes_with_driver_ids.clear()

	# new statboxes
	var viewed_drivers: Array = []
	for driver in drivers_on_start:
		if driver.is_in_group(Refs.group_players):
			viewed_drivers.append(driver)
	for viewed_driver in viewed_drivers:
		var driver_index: int = viewed_drivers.find(viewed_driver)
		_set_driver_statbox(viewed_driver, driver_index, viewed_drivers.size())

	# level rekord
	if "level_record" in level_profile:
		var level_record_value: int = level_profile["level_record"][0]
		var level_record_owner: String = level_profile["level_record"][1]
		if not level_record_value == 0:
			if level_profile["rank_by"] == Levs.RANK_BY.TIME:
				var level_record_clock_time: String = Mets.get_clock_time_string(level_record_value)
				level_record_label.text = "RECORD TIME: " + level_record_clock_time + " by " + str(level_record_owner)
				level_record_label.get_parent().get_parent().show()
			elif level_profile["rank_by"] == Levs.RANK_BY.POINTS:
				level_record_label.text = "RECORD POINTS: " + str(level_record_value) + " by " + str(level_record_owner)
				level_record_label.get_parent().get_parent().show()
	else:
		level_record_label.get_parent().get_parent().hide()

	# level name
	level_name_label.text = level_profile["level_name"]

	# driver stats display
	for driver in drivers_on_start:
		if not driver.is_connected("stat_changed", self, "_on_stat_changed"):
			driver.connect("stat_changed", self, "_on_stat_changed")


func _set_driver_statbox(statbox_driver: Vehicle, statbox_index: int, all_statboxes_count: int):

	var NewStatBox: PackedScene #= StatBox
	NewStatBox = _get_statbox_by_type(statbox_index, all_statboxes_count)

	var new_statbox: BoxContainer = NewStatBox.instance()
	if statbox_index % 2 == 0:
		left_section.add_child(new_statbox)
	else:
		right_section.add_child(new_statbox)

	statboxes_with_driver_ids[new_statbox] = statbox_driver.driver_id

	# driver line
	new_statbox.driver_name_label.text = str(statbox_driver.driver_id)
	new_statbox.driver_avatar.set_texture(statbox_driver.driver_profile["driver_avatar"])
	new_statbox.driver_name_label.modulate = statbox_driver.driver_profile["driver_color"]
	new_statbox.statbox_color = statbox_driver.driver_profile["driver_color"]

	# statbox
#	var statbox_rank_type: int = 0
#	if "rank_by" in level_profile:
#	statbox_rank_type = level_profile["rank_by"]
	new_statbox.set_statbox_stats(level_profile["rank_by"], level_profile["level_lap_count"], level_profile["level_goals"].size(), all_statboxes_count)
	# statbox sam opredeli ali upošteva finish line

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
		STATBOX_TYPE.MINIMAL:
			return StatBox_Minimal


func _on_stat_changed(driver_id: String, stat_key: int, stat_value):
	# stat value je že preračunana, končna vrednost
	# tukaj se opredeli obliko zapisa

	# opredelim statbox
	var statbox_to_change: Control
	if driver_id in statboxes_with_driver_ids.values():
		var statbox: Control = statboxes_with_driver_ids.find_key(driver_id)
		statbox_to_change = statbox

	# ai record
	if "level_record" in level_profile and Pros.start_driver_profiles[driver_id]["controller_type"] == -1 and Sets.ai_gets_record:
		if stat_key == Pros.STAT.BEST_LAP_TIME and not stat_value == 0:
			var level_record_value = level_profile["level_record"][0]
			if stat_value < level_record_value and not level_record_value == 0:
				var new_level_record: Array = [stat_value, driver_id]
				var level_record_clock_time: String = Mets.get_clock_time_string(new_level_record[0])
				level_profile["level_record"] = new_level_record
				level_record_label.text = "NEW RECORD " + level_record_clock_time + " by " + str(new_level_record[1])
				level_record_label.get_parent().get_parent().show()
				level_record_label.modulate = Refs.color_green
				yield(get_tree().create_timer(time_still_time), "timeout")
				level_record_label.modulate = Refs.color_hud_text

	# statbox owners ... players
	elif statbox_to_change:

		# stat_to_change ... STAT key string
		var current_key_index: int = Pros.STAT.values().find(stat_key)
		var current_key: String = Pros.STAT.keys()[current_key_index]
		var stat_to_change: Control = statbox_to_change.get(current_key)

		match stat_key:
			Pros.STAT.SCALPS:
				stat_to_change.stat_value = stat_value.size()
			Pros.STAT.CASH:
				stat_to_change.stat_value = stat_value
			Pros.STAT.POINTS:
				stat_to_change.stat_value = stat_value
			Pros.STAT.LEVEL_PROGRESS:
				stat_to_change.progress_unit = stat_value
			Pros.STAT.LEVEL_RANK:
				stat_to_change.stat_value = stat_value
			Pros.STAT.LAP_TIME: # za uro med krogom ... vsak frejm
				stat_to_change.stat_value = stat_value
			Pros.STAT.LAP_COUNT: # tudi na driver hud za lap time
				# progress bar ... za kroge je opazen samo, če ni "tracking progress per frame "
				if statbox_to_change.use_level_progress_bar:
					# če so goali, je krog celoten progress bar
					if not level_profile["level_goals"].empty():
						# reset za naslednji krog, če ni bi zadnji
						if stat_value.size() < level_profile["level_lap_count"]:
							yield(get_tree().create_timer(time_still_time), "timeout")
							statbox_to_change.LEVEL_PROGRESS.progress_unit = 0
					# brez goalov ... so krogi in ni zadnji krog ... en krog je tick, level finish pa je celoten progress bar
					elif level_profile["level_lap_count"] > 1 and stat_value.size() < level_profile["level_lap_count"]:
						statbox_to_change.LEVEL_PROGRESS.progress_unit = stat_value.size() / float(level_profile["level_lap_count"])
					else: # brez lapsov, brez goalov
						statbox_to_change.LEVEL_PROGRESS.progress_unit = 1
				# lap counter
				stat_to_change.stat_value = [stat_value.size(), level_profile["level_lap_count"]]
			Pros.STAT.GOALS_REACHED:
				# progress bar
				if statbox_to_change.use_level_progress_bar:
					# če so goali, ni per frame apdejtanja iz tracking line
					# ta statistika deluje samo, če level_goals niso prazni ... RACING_GOALS, BATTLE_GOALS
					# RACING_GOAL ima finish_line enabled
					# BATTLE_GOAL ima finish_line disabled
					# RACING_GOALS brez goalov ima samo finish line ... pedena ga LAP_COUNT stat
					var adapted_max_count: float = level_profile["level_goals"].size()
					if level_profile["rank_by"] == Levs.RANK_BY.TIME:
						adapted_max_count = level_profile["level_goals"].size() + 1
					statbox_to_change.LEVEL_PROGRESS.progress_unit = stat_value.size() / adapted_max_count
				# goal counter
				stat_to_change.stat_value = [stat_value.size(), level_profile["level_goals"].size()]
			_:
				# na driver hud ... Pros.STAT.GAS, Pros.STAT.HEALTH, Pros.STAT.BEST_LAP_TIME, Pros.STAT.LEVEL_FINISHED_TIME
				#				stat_to_change.stat_value = stat_value
				#				printerr("Neznana statistika na hudu: ", stat_to_change, ", ", stat_value)
				pass


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
