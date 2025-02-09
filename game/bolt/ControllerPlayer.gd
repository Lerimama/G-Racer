extends Node


signal weapon_triggered

var controlled_bolt: Node2D # temp ... Vechile class
var controller_type: int
var bolt_motion_manager: Node

onready var controller_actions: Dictionary = Pfs.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

var pressed_driving_actions: Array = []
var goals_to_reach: Array = [] # lahko v bolta, ker ma tud AI


func _input(event: InputEvent) -> void:
	# ta del inputa je kar razdelan, ampak ko enkrat registrira vse možnosti ga lahko "pozabim"
	# ga lahko "pozabim" in pedenam _react_to_driving_input()

	if controlled_bolt.is_active:

		if Input.is_action_pressed(shoot_action):
			emit_signal("weapon_triggered")
		# select weapon
		elif Input.is_action_just_pressed(selector_action):
			controlled_bolt.vehicle_hud.selected_item_index += 1

		var motion_input_changed: bool = false
		# rotacija
		if Input.get_axis(left_action, right_action) == 1:
			if not right_action in pressed_driving_actions:
				pressed_driving_actions.append(right_action)
			motion_input_changed = true
		elif Input.get_axis(left_action, right_action) == -1:
			if not left_action in pressed_driving_actions:
				pressed_driving_actions.append(left_action)
			motion_input_changed = true
		else:
			if right_action in pressed_driving_actions:
				pressed_driving_actions.erase(right_action)
			motion_input_changed = true
			if left_action in pressed_driving_actions:
				pressed_driving_actions.erase(left_action)
			motion_input_changed = true

		# premikanje
		if Input.is_action_pressed(fwd_action):
			if not fwd_action in pressed_driving_actions:
				pressed_driving_actions.append(fwd_action)
			motion_input_changed = true
		elif Input.is_action_pressed(rev_action):
			if not rev_action in pressed_driving_actions:
				pressed_driving_actions.append(rev_action)
			motion_input_changed = true
		else:
			if fwd_action in pressed_driving_actions:
				pressed_driving_actions.erase(fwd_action)
			motion_input_changed = true
			if rev_action in pressed_driving_actions:
				pressed_driving_actions.erase(rev_action)
			motion_input_changed = true

		if motion_input_changed:
			_react_to_driving_input(pressed_driving_actions)


func _ready() -> void:

	controlled_bolt.add_to_group(Rfs.group_players)
	# player coližn lejer
	controlled_bolt.set_collision_layer_bit(4, true)


func _physics_process(delta: float) -> void:

	pass


func _react_to_driving_input(pressed_actions: Array):

	if not bolt_motion_manager.motion == bolt_motion_manager.MOTION.DISSARAY:

		# FWD
		if pressed_actions.has(fwd_action):
			if not Rfs.game_manager.game_on:
				controlled_bolt.revup()
			else:
				if Rfs.game_manager.fast_start_window:
					if Input.is_action_just_pressed(fwd_action):
						controlled_bolt.revup()
						bolt_motion_manager.boost_bolt(bolt_motion_manager.fast_start_power_addon, Sts.fast_start_time)
				bolt_motion_manager.motion = bolt_motion_manager.MOTION.FWD
		# REV
		elif pressed_actions.has(rev_action):
			bolt_motion_manager.motion = bolt_motion_manager.MOTION.REV
		# IDLE
		else:
			bolt_motion_manager.motion = bolt_motion_manager.MOTION.IDLE

		# ROTATION
		if pressed_actions.has(left_action):
			bolt_motion_manager.rotation_dir = -1
		elif pressed_actions.has(right_action):
			bolt_motion_manager.rotation_dir = 1
		else:
			bolt_motion_manager.rotation_dir = 0


func goal_reached(goal_reached: Node2D, extra_target: Node2D = null): # next_target je za ai zaenkrat

	goals_to_reach.erase(goal_reached)
