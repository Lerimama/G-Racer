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

onready var health_bar: Control = $HealthBar
onready var health_bar_line: ColorRect = $HealthBar/Bar
onready var gas_bar: Control = $GasBar
onready var gas_bar_line: ColorRect = $GasBar/Bar
onready var message_tag: Node2D = $MessageTag
onready var selector: Control = $Selector
onready var visibility_notifier: VisibilityNotifier2D = $VisibilityNotifier2D

var stat_gas: float = 0 setget _change_stat_gas
var stat_health: float = 0 setget _change_stat_health
var offset_y: float = 200 # odmik od centra vehikla


func _ready() -> void:

	item_counter_template = Mets.remove_chidren_and_get_template(selector.get_children())
	for child in message_tag.get_child(0).get_children():
		child.queue_free()
	hide()


func _process(delta: float) -> void:

	# manage positions and rotation
	if not is_instance_valid(hud_driver):
		hide()
		is_set =false

	if is_set:
		_update_hud_position()

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


func _update_hud_position():

	# globalna pozicija
	rect_position = drivers_viewport.canvas_transform * hud_driver.global_position

	# y offset ... adaptacija na zoom
	rect_position.y += offset_y / drivers_viewport.get_node("GameCamera").zoom.y

	# hor poravnava
	if driver_is_ai: # na širino driver huda
		rect_position.x -= rect_size.x/2
	else: # na širino selectorja
		rect_position.x -= selector.rect_size.x/2


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


func display_hud_message(messages: Array, tag_time: int = 2, message_color: Color = Color.white):
	# 0 tag time pomeni permanentno

	if not message_tag.visible:
		message_tag.show()

	# pozicija
	message_tag.position.x = rect_size.x/2
	# y_offset je zrcalen driver_hud poziciji  ...
	# y_offset podvojim, ker štejem od driver_hud pozicije
	var additional_y_offset: float = -24
	offset_y -= additional_y_offset
	message_tag.position.y = - 2 * offset_y / drivers_viewport.get_node("GameCamera").zoom.y

	# label spawn
	var new_message_labels: Array = []
	for message in messages:
		var new_label: Label = Label.new()
		new_label.align = ALIGN_CENTER
		new_label.text = message
		new_label.modulate = message_color
		message_tag.get_child(0).add_child(new_label)
		new_message_labels.append(new_label)

	# kvefri timer
	if tag_time > 0:
		yield(get_tree().create_timer(tag_time), "timeout")
		for message_label in new_message_labels:
			message_label.queue_free()
		if message_tag.get_children().empty():
			message_tag.hide()


# STATS ---------------------------------------------------------------------------------------


func _change_stat_health(new_health: float):

	stat_health = new_health
	if health_bar.visible:
		health_bar_line.rect_scale.x = stat_health
		if health_bar_line.rect_scale.x <= 0.5:
			health_bar_line.color = Refs.color_red
		else:
			health_bar_line.color = Refs.color_blue


func _change_stat_gas(new_gas: float):

	stat_gas = new_gas
	if gas_bar.visible:
		gas_bar_line.rect_scale.x = stat_gas / hud_driver.gas_tank_size
		if gas_bar_line.rect_scale.x <= 0.5:
			gas_bar_line.color = Refs.color_red
		else:
			gas_bar_line.color = Refs.color_yellow


# ITEMS ---------------------------------------------------------------------------------------


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

			# LNF
			for counter in counters_with_items:
				if counter == new_selected_item:
					counter.modulate.a = 1
				else:
					counter.modulate.a = 0.32
		# timer
		if not always_open:
			yield(get_tree().create_timer(selector_open_time), "timeout")
			selector.hide()


func _on_VisibilityNotifier2D_screen_entered() -> void:
#	print("SHOW")
	show()


func _on_VisibilityNotifier2D_screen_exited() -> void:
#	print("HIDE")
	hide()
