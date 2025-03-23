extends Node

enum BATTLE_STATE {NONE, GUN, TURRET, LAUNCHER, DROPPER, MALA}
var selected_weapon_type: int = BATTLE_STATE.NONE

var vehicle: Vehicle # dobi od controllerja
var available_items: Array = []


func _ready() -> void:
	pass



func use_selected_item():

	var battle_state_key: String = BATTLE_STATE.find_key(selected_weapon_type)

	var shooting_weapons: Array = []

	# poišče prvo orožje setanega tipa
	# če so grupirana, poišče vse
	for weapon in vehicle.weapons_holder.get_children():
#		var weapon_type_index: int = weapon.WEAPON_TYPE.keys().find(selected_weapon_type_key)
#		var weapon_type: int = weapon.WEAPON_TYPE.values()[weapon_type_index]
		var curr_weapon_type: int = weapon.WEAPON_TYPE.get(battle_state_key)
		if weapon.weapon_type == curr_weapon_type:
			shooting_weapons.append(weapon)
#			if not vehicle.group_equipment_by_type:
#				break

	# če izbranega tipa ne najde, izbere naslednjega po indexu in prilagodi battle state
	if shooting_weapons.empty():
		var selected_weapon: Node2D = vehicle.enabled_triggering_equipment[selected_item_index]
#	selected_item_index = new_selected_item_index
#	if selected_weapon.has_method("on_weapon_triggered"):
#		selected_weapon.on_weapon_triggered()
		pass

	for weapon in shooting_weapons:
		weapon.on_weapon_triggered()




var is_shooting: bool = false

func shoot(new_selected_weapon_type: int = selected_weapon_type, shoot_till_stop_call: bool = false):

	if not new_selected_weapon_type == selected_weapon_type:

		selected_weapon_type = new_selected_weapon_type

		if BATTLE_STATE.NONE:
			is_shooting = false
		else:
			match selected_weapon_type:
				BATTLE_STATE.GUN:
					use_selected_item()
					pass
				BATTLE_STATE.TURRET:
					use_selected_item()
					pass
				BATTLE_STATE.LAUNCHER:
					use_selected_item()
					pass
				BATTLE_STATE.DROPPER:
					use_selected_item()
					pass
				BATTLE_STATE.MALA:
					use_selected_item()
					pass

			if shoot_till_stop_call:
				is_shooting = true


# iz plejerja


var selected_item_index = 0

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


#func use_selected_item_old(new_selected_item_index: int):
#
#	selected_item_index = new_selected_item_index
#	var selected_weapon: Node2D = vehicle.enabled_triggering_equipment[selected_item_index]
#	if selected_weapon.has_method("on_weapon_triggered"):
#		selected_weapon.on_weapon_triggered()
#
#	# še vsa orožja istega tipa
#	if vehicle.group_equipment_by_type:
#		for weapon in vehicle.weapons_holder.get_children():
#			if weapon.weapon_type == selected_weapon.weapon_type:
#				weapon.on_weapon_triggered()
