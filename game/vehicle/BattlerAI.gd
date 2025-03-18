extends Node

var selected_item_index = 0
var vehicle: Vehicle # dobi od controllerja
var available_items: Array = []

func _ready() -> void:
	pass



func select_item():

	selected_item_index += 1
	if selected_item_index > vehicle.enabled_triggering_equipment.size() - 1:
		selected_item_index = 0
	elif selected_item_index < 0:
		selected_item_index = vehicle.enabled_triggering_equipment.size() - 1
	emit_signal("item_selected", selected_item_index)
	# weapon ai on/ off
	var selected_weapon: Node2D = vehicle.enabled_triggering_equipment[selected_item_index]
	if selected_weapon.use_ai:
		selected_weapon.weapon_ai.ai_enabled = true
	else:
		for weapon in vehicle.enabled_triggering_equipment:
			weapon.weapon_ai.ai_enabled = false


func use_selected_item(selected_item_index: int):

	var selected_weapon: Node2D = vehicle.enabled_triggering_equipment[selected_item_index]
	if selected_weapon.has_method("_on_weapon_triggered"):
		selected_weapon._on_weapon_triggered()

	# še vsa orožja istega tipa
	if vehicle.group_weapons_by_type:
		for weapon in vehicle.weapons_holder.get_children():
			if weapon.weapon_type == selected_weapon.weapon_type:
				weapon._on_weapon_triggered()
