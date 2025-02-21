extends Node


#signal weapon_triggered
signal next_weapon_selected

var controlled_vehicle: Vehicle # temp ... Vehicle class
var controller_type: int
var motion_manager: Node

onready var controller_actions: Dictionary = Pfs.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

# neu
var pressed_driving_actions: Array = []
var goals_to_reach: Array = []
var selected_item_index = 0
var game_is_on: bool = false
var fast_start_window_is_open: bool = false


func _input(event: InputEvent) -> void:
	# ta del inputa je kar razdelan, ampak ko enkrat registrira vse možnosti ga lahko "pozabim"
	# ga lahko "pozabim" in pedenam _set_driving_motion()

	if controlled_vehicle.is_active:

		# select weapon
		if Input.is_action_just_pressed(selector_action):
			selected_item_index += 1
			if selected_item_index > controlled_vehicle.triggering_weapons.size() - 1: # poskrbi tudi za primer, da je samo en item
				selected_item_index = 0
			elif selected_item_index < 0:
				selected_item_index = controlled_vehicle.triggering_weapons.size() - 1
			emit_signal("next_weapon_selected", selected_item_index)

		# shoot
		if Input.is_action_pressed(shoot_action):
			var selected_weapon: Node2D = controlled_vehicle.triggering_weapons[selected_item_index]
			if selected_weapon.has_method("_on_weapon_triggered"):
				selected_weapon._on_weapon_triggered()
			# še vsa orožja istega tipa
			if controlled_vehicle.group_weapons_by_type:
				for weapon in controlled_vehicle.weapons.get_children():
					if weapon.weapon_type == selected_weapon.weapon_type:
						weapon._on_weapon_triggered()

		# motion
		var prev_actions: Array = pressed_driving_actions.duplicate()
		if Input.is_action_pressed(fwd_action):
			if not fwd_action in pressed_driving_actions: pressed_driving_actions.append(fwd_action)
		elif Input.is_action_pressed(rev_action):
			if not rev_action in pressed_driving_actions: pressed_driving_actions.append(rev_action)
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

	controlled_vehicle.add_to_group(Rfs.group_players)
	# player coližn lejer
	controlled_vehicle.set_collision_layer_bit(4, true)


func _set_driving_motion(pressed_actions: Array):

	if not game_is_on and pressed_actions.has(fwd_action):
		controlled_vehicle.revup()

	if game_is_on and not motion_manager.motion == motion_manager.MOTION.DISSARAY:
		if fwd_action in pressed_actions:
			if pressed_actions.has(left_action):
				motion_manager.motion = motion_manager.MOTION.FWD_LEFT
			elif pressed_actions.has(right_action):
				motion_manager.motion = motion_manager.MOTION.FWD_RIGHT
			else:
				motion_manager.motion = motion_manager.MOTION.FWD
			if fast_start_window_is_open:
				controlled_vehicle.revup()
				motion_manager.boost_vehicle(motion_manager.fast_start_power_addon, Sts.fast_start_time)
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


func goal_reached(goal_reached: Node2D, extra_target: Node2D = null): # next_target je za ai zaenkrat

	goals_to_reach.erase(goal_reached)


func _on_game_stage_change(game_manager: Game): # od GMja

	match game_manager.game_stage:
		game_manager.GAME_STAGE.PLAYING:
			#			print ("fast start open")
			game_is_on = true
			fast_start_window_is_open = true
			yield(get_tree().create_timer(Sts.fast_start_time), "timeout")
			fast_start_window_is_open = false
			#			print ("fast start closed")
		game_manager.GAME_STAGE.END_SUCCESS,game_manager.GAME_STAGE.END_FAIL:
			game_is_on = false
			if controlled_vehicle.is_active:
				#				set_physics_process(false)
				controlled_vehicle.is_active = false
				print ("disejblam", " _prepozno")

