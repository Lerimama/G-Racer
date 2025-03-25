extends VBoxContainer


var hud_driver: Vehicle
var is_set: bool = false
var driver_is_ai: bool = false

var counters_with_items: Dictionary = {} # {counter: item_1 node}
var item_counter_template: Control
var drivers_viewport: Viewport
var always_open: bool = true
var selector_open_time: float = 0
var hide_on_empty: bool = false

onready var selector: Control = $Selector
onready var selector_timer: Timer = $SelectorTimer
onready var rotation_label: Label = $RotationLabel
onready var health_bar: Control = $HealthBar
onready var health_bar_line: ColorRect = $HealthBar/Bar
onready var gas_bar: Control = $GasBar
onready var gas_bar_line: ColorRect = $GasBar/Bar
onready var visibility_notifier: VisibilityNotifier2D = $VisibilityNotifier2D


func _ready() -> void:

	item_counter_template = Mets.remove_chidren_and_get_template(selector.get_children())
	hide()


func _process(delta: float) -> void:

	# manage positions and rotation
	if not is_instance_valid(hud_driver):
		hide()

	if is_set:
		_update_hud_position()

		# manage health bar
		if health_bar.visible:
			health_bar_line.rect_scale.x = hud_driver.driver_stats[Pros.STAT.HEALTH]
			if health_bar_line.rect_scale.x <= 0.5:
				health_bar_line.color = Refs.color_red
			else:
				health_bar_line.color = Refs.color_blue

		# manage gas bar
		if gas_bar.visible:
			gas_bar_line.rect_scale.x = hud_driver.driver_stats[Pros.STAT.GAS] / hud_driver.gas_tank_size
			if gas_bar_line.rect_scale.x <= 0.5:
				gas_bar_line.color = Refs.color_red
			else:
				gas_bar_line.color = Refs.color_yellow

		# items
		if driver_is_ai:
			if selector.visible:
				selector.hide()
		else:
			for counter in counters_with_items:
				var weapon_type: int = counters_with_items[counter].weapon_type
				var counter_load_count: int = counters_with_items[counter].load_count
				if hud_driver.group_equipment_by_type:
					var grouped_weapons_count: int = hud_driver.weapon_types_with_trigger_weapons[weapon_type].size()
					counter_load_count = counters_with_items[counter].load_count * grouped_weapons_count
				counter.get_node("CountLabel").text = "%02d" % counter_load_count
				# skrijem če je prazno?
				if hide_on_empty and counter_load_count <= 0:
					hide()
				elif not visible:
					show()


func set_driver_hud(driver_node: Vehicle, view: ViewportContainer, for_ai: bool = false):

	hud_driver = driver_node
	drivers_viewport = view.get_node("Viewport")

	if hud_driver.driver_stats[Pros.STAT.GAS] > hud_driver.gas_tank_size:
		hud_driver.gas_tank_size = hud_driver.driver_stats[Pros.STAT.GAS]

	_update_hud_position()

	visibility_notifier.rect.size = rect_size

	if for_ai:
		driver_is_ai = true
		is_set = true
		if Sets.ai_gas_on:
			gas_bar.show()
		else:
			gas_bar.hide()
	else:
		hud_driver.controller.connect("item_selected", self, "_on_item_selected")
		for weapon_type in hud_driver.weapon_types_with_trigger_weapons:
			if hud_driver.group_equipment_by_type:
				var first_item: Node2D = hud_driver.weapon_types_with_trigger_weapons[weapon_type].front()
				_add_item_counter(first_item)
			else:
				for item in hud_driver.weapon_types_with_trigger_weapons[weapon_type]:
					_add_item_counter(item)

		is_set = true
		_on_item_selected(0)

	show()


func _update_hud_position():

	# globalna pozicija
	rect_position = drivers_viewport.canvas_transform * hud_driver.global_position

	# adaptacija na zoom
	var offset_y: float = 200
	rect_position.y += offset_y / drivers_viewport.get_node("GameCamera").zoom.y# + 50

	# hor poravnava
	if driver_is_ai: # na širino driver huda
		rect_position.x -= rect_size.x/2
	else: # na širino selectorja
		rect_position.x -= selector.rect_size.x/2


func _add_item_counter(new_item: Node2D):

	var new_selector_item: Control = item_counter_template.duplicate()
	selector.add_child(new_selector_item)

	counters_with_items[new_selector_item] = new_item
	new_selector_item.get_node("CountLabel").text = "%02d" % new_item.load_count
	new_selector_item.get_node("Icon").texture = new_item.load_icon


func _remove_counter(counter_to_remove: Control): # ni v uporabi

	counters_with_items.erase(counter_to_remove)
	counter_to_remove.queue_free()


func _on_item_selected(selected_index: int):

	if is_set and not counters_with_items.empty() and not driver_is_ai:

		# če ni viden ga samo pokaže in izbira v naslednjem koraku
		if not selector.visible:
			selector.show()
		# če je viden izbira
		else:
			# prevent ... zazih
			if selected_index > counters_with_items.size() - 1: # poskrbi tudi za primer, da je samo en item
				selected_index = counters_with_items.size() - 1

			# izberem orožje
			var new_selected_item: Control = counters_with_items.keys()[selected_index]
#			selected_item = counters_with_items[new_selected_item]

			# LNF
			for counter in counters_with_items:
				if counter == new_selected_item:
					counter.modulate.a = 1
				else:
					counter.modulate.a = 0.32
		# timer
		if not always_open:
			selector_timer.start(selector_open_time)


func _on_SelectorTimer_timeout() -> void:

	selector.hide()


func _on_VisibilityNotifier2D_screen_entered() -> void:
#	print("SHOW")
	show()


func _on_VisibilityNotifier2D_screen_exited() -> void:
#	print("HIDE")
	hide()
