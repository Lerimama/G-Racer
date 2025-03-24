extends Node2D


#signal weapon_triggered
signal item_selected

var vehicle: Vehicle # temp ... Vehicle class
var controller_type: int
var motion_manager: Node2D

onready var controller_actions: Dictionary = Pros.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

# neu
var pressed_driving_actions: Array = []
var selected_item_index = 0
var fast_start_window_is_open: bool = true # odprt tudi pred štartom, da dela revup


func _input(event: InputEvent) -> void:
	# ta del inputa je kar razdelan, ampak ko enkrat registrira vse možnosti ga lahko "pozabim"
	# ga lahko "pozabim" in pedenam _set_driving_motion()

	if vehicle.is_active:

		# select weapon
		if Input.is_action_just_pressed(selector_action):

			selected_item_index += 1

			# vsa setana orožja, ne glede na tip
			var all_equipment_ungrouped: Array = []
			for weapon_type in vehicle.weapons_types_with_weapons:
				for weapon in vehicle.weapons_types_with_weapons[weapon_type]:
					all_equipment_ungrouped.append(weapon)

			# ungrouped ... preštejem ves equipment
			var selectable_items_count = all_equipment_ungrouped.size()
			# grouped ... preštejem število tipov
			if vehicle.group_equipment_by_type:
				selectable_items_count = vehicle.weapons_types_with_weapons.size()

			if selected_item_index > selectable_items_count - 1: # poskrbi tudi za primer, da je samo en item
				selected_item_index = 0
			elif selected_item_index < 0:
				selected_item_index = selectable_items_count - 1
			emit_signal("item_selected", selected_item_index)

			# weapon ai ON/OFF
			if vehicle.group_equipment_by_type:
				var selected_weapon_group: Node2D = vehicle.vehicle.weapons_types_with_weapons.values()[selected_item_index]
				for weapon in all_equipment_ungrouped:
					if weapon in selected_weapon_group and weapon.use_ai:
						weapon.weapon_ai.ai_enabled = true
					else:
						weapon.weapon_ai.ai_enabled = false
			else:
				var curr_weapon: Node2D = all_equipment_ungrouped[selected_item_index]
				for weapon in all_equipment_ungrouped:
					if weapon == curr_weapon and curr_weapon.use_ai:
						curr_weapon.weapon_ai.ai_enabled = true
					else:
						weapon.weapon_ai.ai_enabled = false


		# shoot
		if Input.is_action_pressed(shoot_action):
#		if Input.is_action_just_pressed(shoot_action):
			if vehicle.group_equipment_by_type:
				var selected_weapons_group: Array = vehicle.weapons_types_with_weapons.values()[selected_item_index]
				var selected_weapon: Node2D = selected_weapons_group.front()
				for weapon in selected_weapons_group:
					weapon.on_weapon_triggered()
			else:
				var ungrouped_equipment: Array = []
				for weapon_type in vehicle.weapons_types_with_weapons:
					for weapon in vehicle.weapons_types_with_weapons[weapon_type]:
						ungrouped_equipment.append(weapon)
				ungrouped_equipment[selected_item_index].on_weapon_triggered()

		# revup
#		if motion_manager.motion == motion_manager.MOTION.DISSABLED:
		if fast_start_window_is_open:
			if Input.is_action_just_pressed(fwd_action) or Input.is_action_just_pressed(rev_action):
				vehicle.engines.revup()

	if not motion_manager.motion == motion_manager.MOTION.DISSARAY \
	and not motion_manager.motion == motion_manager.MOTION.DISSABLED:
		# motion
		var prev_actions: Array = pressed_driving_actions.duplicate()
		if Input.is_action_pressed(fwd_action):
			if not fwd_action in pressed_driving_actions: pressed_driving_actions.append(fwd_action)
		elif Input.is_action_pressed(rev_action):
			if not rev_action in pressed_driving_actions:  pressed_driving_actions.append(rev_action)
		else:
			if fwd_action in pressed_driving_actions: pressed_driving_actions.erase(fwd_action)
			if rev_action in pressed_driving_actions: pressed_driving_actions.erase(rev_action)
		if Input.get_axis(left_action, right_action) == 1:
			if not right_action in pressed_driving_actions: pressed_driving_actions.append(right_action)
		elif Input.get_axis(left_action, right_action) == -1:
			if not left_action in pressed_driving_actions: pressed_driving_actions.append(left_action)
		else:
			if right_action in pressed_driving_actions: pressed_driving_actions.erase(right_action)
			if left_action in pressed_driving_actions: pressed_driving_actions.erase(left_action)

		if not prev_actions == pressed_driving_actions:
			_set_driving_motion(pressed_driving_actions)


func _ready() -> void:

	vehicle.add_to_group(Refs.group_players)
	# player coližn lejer
	vehicle.set_collision_layer_bit(4, true)


func _set_driving_motion(pressed_actions: Array):

		if fwd_action in pressed_actions:
			if pressed_actions.has(left_action):
				motion_manager.motion = motion_manager.MOTION.FWD_LEFT
			elif pressed_actions.has(right_action):
				motion_manager.motion = motion_manager.MOTION.FWD_RIGHT
			else:
				motion_manager.motion = motion_manager.MOTION.FWD
			if fast_start_window_is_open:
				vehicle.engines.revup()
				motion_manager.boost_vehicle(motion_manager.fast_start_power_addon, Sets.fast_start_time)
		elif rev_action in pressed_actions:
			if left_action in pressed_actions:
				motion_manager.motion = motion_manager.MOTION.REV_LEFT
			elif right_action in pressed_actions:
				motion_manager.motion = motion_manager.MOTION.REV_RIGHT
			else:
				motion_manager.motion = motion_manager.MOTION.REV
		else:
			if left_action in pressed_actions:
				motion_manager.motion = motion_manager.MOTION.IDLE_LEFT
			elif right_action in pressed_actions:
				motion_manager.motion = motion_manager.MOTION.IDLE_RIGHT
			else:
				motion_manager.motion = motion_manager.MOTION.IDLE


func on_game_start(game_level: Node2D): # od GMja

	motion_manager.motion = motion_manager.MOTION.IDLE

	fast_start_window_is_open = true
	yield(get_tree().create_timer(Sets.fast_start_time), "timeout")
	fast_start_window_is_open = false

