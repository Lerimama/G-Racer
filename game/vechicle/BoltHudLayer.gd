extends CanvasLayer


onready var hud_owner: Node2D = get_parent()
var y_position_offset: float

var selected_item_index: int = 0 setget _change_selected_weapon # index znotraj aktivnih orožij
var selected_weapon: Node2D # index znotraj aktivnih orožij
var selector_items: Dictionary = {} # item in njegovo orožja
var selector_item_template: Control
var always_open: bool = true
var selector_open_time: float = 0

onready var selector: Control = $BoltHudLines/Selector
onready var selector_timer: Timer = $BoltHudLines/SelectorTimer
onready var rotation_label: Label = $BoltHudLines/RotationLabel
onready var health_bar: Control = $BoltHudLines/HealthBar
onready var health_bar_line: ColorRect = $BoltHudLines/HealthBar/Bar
onready var gas_bar: Control = $BoltHudLines/GasBar
onready var gas_bar_line: ColorRect = $BoltHudLines/GasBar/Bar

onready var bolt_hud_lines: VBoxContainer = $BoltHudLines

func _ready() -> void:

#	hide()
	y_position_offset = bolt_hud_lines.rect_position.y
	selector_item_template = Mts.remove_chidren_and_get_template(selector.get_children())
	hide()


func setup(owner_node: Node2D):

	hud_owner = owner_node

	if hud_owner.driver_stats[Pfs.STATS.GAS] > hud_owner.gas_tank_size:
		hud_owner.gas_tank_size = hud_owner.driver_stats[Pfs.STATS.GAS]

	for weapon in hud_owner.weapons.get_children():
		if weapon.is_set:
			_add_weapon_selector(weapon)

	self.selected_item_index = 0

	show()


func _process(delta: float) -> void:
	# manage positions and rotation
	if visible:
#		global_rotation = 0 # negiramo rotacijo bolta, da je pri miru
		var position_relative_to_bolt: Vector2 = bolt_hud_lines.rect_global_position - hud_owner.global_position
#		offset = position_relative_to_bolt
		printt("off", offset)
#		offset = hud_owner.global_position
		transform.origin.y = hud_owner.transform.origin.y
		transform.origin.x = hud_owner.transform.origin.x# + get_viewport().size.x / 2
#		printt("position_relative_to_bolt", position_relative_to_bolt)
#		bolt_hud_lines.rect_position = position_relative_to_bolt + Vector2(0, y_position_offset)
#		bolt_hud_lines.rect_position = position_relative_to_bolt
#		bolt_hud_lines.rect_position = Vector2(0, y_position_offset)
#		bolt_hud_lines.rect_global_position = hud_owner.global_position + Vector2(0, y_position_offset)

	if hud_owner:
		# manage health bar
		if health_bar.visible:
			health_bar_line.rect_scale.x = hud_owner.driver_stats[Pfs.STATS.HEALTH]
			if health_bar_line.rect_scale.x <= 0.5:
				health_bar_line.color = Rfs.color_red
			else:
				health_bar_line.color = Rfs.color_blue

		# manage gas bar
		if gas_bar.visible:
			gas_bar_line.rect_scale.x = hud_owner.driver_stats[Pfs.STATS.GAS] / hud_owner.gas_tank_size
			if gas_bar_line.rect_scale.x <= 0.5:
				gas_bar_line.color = Rfs.color_red
			else:
				gas_bar_line.color = Rfs.color_yellow

		# weapons
		for weapon in selector_items.values():
			var ammo_count_key: int = Pfs.ammo_profiles[weapon.weapon_ammo]["stat_key"]
			var ammo_count: float = hud_owner.driver_stats[ammo_count_key]
			var selector_item: Control = selector_items.find_key(weapon)
			selector_item.get_node("CountLabel").text = "%02d" % ammo_count

			if ammo_count == 0:
				_remove_weapon_selector(selector_item)

		# pokažem, če ima municijo
		for weapon in hud_owner.weapons.get_children():
			if weapon.is_set:
				var ammo_count_key: int = Pfs.ammo_profiles[weapon.weapon_ammo]["stat_key"]
				var ammo_count: float = hud_owner.driver_stats[ammo_count_key]
				if ammo_count > 0:
					_add_weapon_selector(weapon)


func _add_weapon_selector(item_weapon: Node2D):

	# preverim če je za isti tip že notri
	var weapon_item_exists: bool = false
	for weapon in selector_items.values():
		if weapon.weapon_type == item_weapon.weapon_type:
			weapon_item_exists = true

	if not weapon_item_exists:
		var new_selector_item: Control = selector_item_template.duplicate()
		selector.add_child(new_selector_item)

		selector_items[new_selector_item] = item_weapon

		new_selector_item.get_node("Icon").texture = Pfs.ammo_profiles[item_weapon.weapon_ammo]["icon"]
		var weapon_ammo_count_key: int = Pfs.ammo_profiles[item_weapon.weapon_ammo]["stat_key"]
		new_selector_item.get_node("CountLabel").text = "%02d" % hud_owner.driver_stats[weapon_ammo_count_key]


func _remove_weapon_selector(selector_item: Control):

	selector_items.erase(selector_item)
	selector_item.queue_free()


func _change_selected_weapon(new_selected_item_index: int):

	if not selector_items.empty():

		# loop select
		if selector_items.size() == 1:
			selected_item_index = 0
		else:
			if selector.visible:
				if new_selected_item_index > selector_items.size() - 1:
					new_selected_item_index = 0
				elif new_selected_item_index < 0:
					new_selected_item_index = selector_items.size() - 1
				selected_item_index = new_selected_item_index
			else: # če še ni prižgan se samo pokaže, izbrana ostane stara ikona
				selector.show()
				selected_item_index = new_selected_item_index

		# izberem orožje
		var new_selected_item: Control = selector_items.keys()[selected_item_index]
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
