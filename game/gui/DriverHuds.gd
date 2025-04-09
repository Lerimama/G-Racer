extends Control


var view_imitators_with_driver_ids: Dictionary = {} # imitatorja je dimenzijska kopija pripadajočega viewa
var driver_ids_with_driver_huds: Dictionary = {}

onready var def_view_imitator: Control = $ViewImitator # nikoli ga ne zbrišemm
onready var DriverHud: PackedScene = preload("res://game/gui/DriverHud.tscn")


func _ready() -> void:

	# debug reset
	if $ViewImitator/DriverHud:
		$ViewImitator/DriverHud.queue_free()


func set_driver_huds(game: Game, drivers_on_start: Array, mono_view_mode: bool):

	var views_with_drivers: Dictionary = game.game_views.views_with_drivers

	# reset, razen vzorčnega
	for imitator in get_children():
		if not imitator == get_child(0):
			imitator.queue_free()
	view_imitators_with_driver_ids.clear()
	driver_ids_with_driver_huds.clear()

	if mono_view_mode:
		var imitated_view: ViewportContainer = views_with_drivers.keys()[0]
		for driver in drivers_on_start:
			var new_driver_hud: Control = DriverHud.instance()
			def_view_imitator.add_child(new_driver_hud)
			if driver.is_in_group(Refs.group_ai):
				new_driver_hud.set_driver_hud(driver, imitated_view, true)
			else:
				new_driver_hud.set_driver_hud(driver, imitated_view)
			driver_ids_with_driver_huds[driver.driver_id] = new_driver_hud
		view_imitators_with_driver_ids[def_view_imitator] = views_with_drivers.values()[0] # view owner je 1. plejer

	else:
		for view in views_with_drivers:
			# spawn imitatoraja
			var new_view_imitator: Control = def_view_imitator.duplicate()
			add_child(new_view_imitator)

			# spawn hud
			var new_driver_hud: Control = DriverHud.instance()
			new_view_imitator.add_child(new_driver_hud)

			# pripiši driverja
			var driver_id: String = views_with_drivers[view]
			var player_driver: Vehicle
			for driver in drivers_on_start:
				if driver.driver_id == driver_id:
					player_driver = driver
			new_driver_hud.set_driver_hud(player_driver, view)
			driver_ids_with_driver_huds[player_driver.driver_id] = new_driver_hud

			# v slovar
			view_imitators_with_driver_ids[new_view_imitator] = driver_id
			# ai huds
			for ai_driver in drivers_on_start:
				if ai_driver.is_in_group(Refs.group_ai):
					var new_ai_hud: Control = DriverHud.instance()
					new_view_imitator.add_child(new_ai_hud)
					new_ai_hud.set_driver_hud(ai_driver, view, true)
					driver_ids_with_driver_huds[ai_driver.driver_id] = new_ai_hud

	# aplciram game_views dimezije na imitatorja
	_set_imitators_size(views_with_drivers)

	for driver in drivers_on_start:
		var driver_hud: Control = driver_ids_with_driver_huds[driver.driver_id]
		if not driver.is_connected("stat_changed", self, "_on_stat_changed"):
			driver.connect("stat_changed", self, "_on_stat_changed")


func _on_stat_changed(driver_id: String, stat_key: int, stat_value):
	# stat value je že preračunana, končna vrednost

	if driver_id in driver_ids_with_driver_huds: # zazih

		var driver_hud_to_change: Control = driver_ids_with_driver_huds[driver_id]

		match stat_key:
			Pros.STAT.GAS:
				driver_hud_to_change.stat_gas = stat_value
			Pros.STAT.HEALTH:
				driver_hud_to_change.stat_health = stat_value
			Pros.STAT.BEST_LAP_TIME: # skupaj sta ker se zgodita na isti dogodek
				if stat_value > 0:
					var lap_clock_time: String = Mets.get_clock_time_string(stat_value) # array so časi vseh krogov
					driver_hud_to_change.display_hud_message(["PERSONAL BEST"], 2, Refs.color_green)
			Pros.STAT.LEVEL_FINISHED_TIME: # on level finish
				if stat_value > 0:
					var level_clock_time: String = Mets.get_clock_time_string(stat_value) # array so časi vseh krogov
					driver_hud_to_change.call_deferred("display_hud_message", ["LT " + level_clock_time])
			Pros.STAT.LAP_COUNT: # tudi na hudu
				# driver hud - lap time
				if not stat_value.empty():
					var lap_clock_time: String = Mets.get_clock_time_string(stat_value.back()) # array so časi vseh krogov
					# deffered, da je za morebitnim "BEST LAP KLICEM"
					driver_hud_to_change.call_deferred("display_hud_message", [lap_clock_time])
			_: pass # ostale so na hudu


func remove_view_imitator(game_views: Dictionary): # GM na activity change ... ne uporabljam

	var view_added: bool = false

	# preverim kateri player je removed ... views in imitatorji imajo skupnega plejerja
	var view_imitator_to_remove: Control
	for driver in view_imitators_with_driver_ids.values():
		if not driver in game_views.values():
			view_imitator_to_remove = view_imitators_with_driver_ids.find_key(driver)
			break

	# removam imitatorja
	view_imitator_to_remove.queue_free()
	view_imitators_with_driver_ids.erase(view_imitator_to_remove)

	# apliciram nove dimezije
	_set_imitators_size(game_views)


func _set_imitators_size(game_views: Dictionary):

	# počakam na apdejt active_view dimenzij
	yield(get_tree(), "idle_frame")

	# setam novo velikost ... views in imitatorji imajo skupnega plejerja
	for view in game_views:
		var driver_id: String = game_views[view]
		if driver_id in view_imitators_with_driver_ids.values():
			var view_imitator_to_set: Control = view_imitators_with_driver_ids.find_key(driver_id)
			view_imitator_to_set.rect_size = view.rect_size
			view_imitator_to_set.rect_position = view.rect_position
