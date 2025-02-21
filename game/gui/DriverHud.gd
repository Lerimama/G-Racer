extends VBoxContainer


var hud_driver: Vehicle
var is_set: bool = false
var driver_is_ai: bool = false

var selected_weapon: Node2D # index znotraj aktivnih orožij
var selector_items: Dictionary = {} # item in njegovo orožja
var selector_item_template: Control
var drivers_viewport: Viewport
var always_open: bool = true
var selector_open_time: float = 0
var hide_no_ammo: bool = false

onready var selector: Control = $Selector
onready var local_offset: Vector2 = Vector2(- selector.rect_size.x, 100)
onready var selector_timer: Timer = $SelectorTimer
onready var rotation_label: Label = $RotationLabel
onready var health_bar: Control = $HealthBar
onready var health_bar_line: ColorRect = $HealthBar/Bar
onready var gas_bar: Control = $GasBar
onready var gas_bar_line: ColorRect = $GasBar/Bar


func _ready() -> void:

	selector_item_template = Mts.remove_chidren_and_get_template(selector.get_children())
	hide()


func set_driver_hud(driver_node: Vehicle, view: ViewportContainer, for_ai: bool = false):


	hud_driver = driver_node
	drivers_viewport = view.get_node("Viewport")

	if hud_driver.driver_stats[Pfs.STATS.GAS] > hud_driver.gas_tank_size:
		hud_driver.gas_tank_size = hud_driver.driver_stats[Pfs.STATS.GAS]

	_update_hud_position()

	if for_ai:
		driver_is_ai = true
		is_set = true
	else:
		# weapons
		hud_driver.control_manager.connect("next_weapon_selected", self, "_on_next_weapon_selected")
		for weapon in hud_driver.triggering_weapons:
			_add_weapon_selector(weapon)
		is_set = true
		_on_next_weapon_selected(0)

	show()


func _update_hud_position():

	rect_position = drivers_viewport.canvas_transform * hud_driver.global_position
	rect_position.x += local_offset.x
	rect_position.y += local_offset.y / drivers_viewport.get_node("GameCamera").zoom.y + 50
	if driver_is_ai:
		rect_position.x += 160
	else:
		rect_position.x -= 30


func _process(delta: float) -> void:

	# manage positions and rotation
	if not is_instance_valid(hud_driver):
		hide()

	if is_set and visible:

		_update_hud_position()

		# manage health bar
		if health_bar.visible:
			health_bar_line.rect_scale.x = hud_driver.driver_stats[Pfs.STATS.HEALTH]
			if health_bar_line.rect_scale.x <= 0.5:
				health_bar_line.color = Rfs.color_red
			else:
				health_bar_line.color = Rfs.color_blue

		# manage gas bar
		if gas_bar.visible:
			gas_bar_line.rect_scale.x = hud_driver.driver_stats[Pfs.STATS.GAS] / hud_driver.gas_tank_size
			if gas_bar_line.rect_scale.x <= 0.5:
				gas_bar_line.color = Rfs.color_red
			else:
				gas_bar_line.color = Rfs.color_yellow

		# weapons
		if driver_is_ai:
			if selector.visible:
				selector.hide()
		else:
			for weapon in selector_items.values():
				if "weapon_ammo" in weapon:
					var ammo_count_key: int = Pfs.ammo_profiles[weapon.weapon_ammo]["stat_key"]
					var ammo_count: float = hud_driver.driver_stats[ammo_count_key]
					var selector_item: Control = selector_items.find_key(weapon)
					selector_item.get_node("CountLabel").text = "%02d" % ammo_count
			if hide_no_ammo:
				for weapon in selector_items:
					if "weapon_ammo" in weapon:
						var ammo_count_key: int = Pfs.ammo_profiles[weapon.weapon_ammo]["stat_key"]
						var ammo_count: float = hud_driver.driver_stats[ammo_count_key]
						if ammo_count > 0:
							hide()
						else:
							show()


func _add_weapon_selector(item_weapon: Node2D):

	var new_selector_item: Control = selector_item_template.duplicate()
	selector.add_child(new_selector_item)

	selector_items[new_selector_item] = item_weapon

	if "weapon_ammo" in item_weapon:
		new_selector_item.get_node("Icon").texture = Pfs.ammo_profiles[item_weapon.weapon_ammo]["icon"]
		var weapon_ammo_count_key: int = Pfs.ammo_profiles[item_weapon.weapon_ammo]["stat_key"]
		new_selector_item.get_node("CountLabel").text = "%02d" % hud_driver.driver_stats[weapon_ammo_count_key]
	else:
		new_selector_item.get_node("Icon").texture = Pfs._temp_mala_icon
		new_selector_item.get_node("CountLabel").hide()


func _remove_weapon_selector(selector_item: Control):

	selector_items.erase(selector_item)
	selector_item.queue_free()


func _on_next_weapon_selected(selected_index: int):

	if is_set and not selector_items.empty() and not driver_is_ai:

		# če ni viden ga samo pokaže in izbira v naslednjem koraku
		if not selector.visible:
			selector.show()
		# če je viden izbira
		else:
			# prevent ... zazih
			if selected_index > selector_items.size() - 1: # poskrbi tudi za primer, da je samo en item
				selected_index = selector_items.size() - 1

			# izberem orožje
			var new_selected_item: Control = selector_items.keys()[selected_index]
			selected_weapon = selector_items[new_selected_item]

			# LNF
			for item in selector_items:
				if item == new_selected_item:
					item.modulate.a = 1
				else:
					item.modulate.a = 0.32
		# timer
		if not always_open:
			selector_timer.start(selector_open_time)


func _on_SelectorTimer_timeout() -> void:

	selector.hide()

#func _on_VisibilityNotifier2D_screen_entered() -> void:
##	show()
#	pass
#
#
#func _on_VisibilityNotifier2D_screen_exited() -> void:
##	hide()
#	pass
