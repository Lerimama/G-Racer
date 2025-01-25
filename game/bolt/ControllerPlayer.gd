extends Node


var controlled_bolt: RigidBody2D
var controller_type: int
var bolt_motion_manager: Node

onready var controller_actions: Dictionary = Pfs.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

var _driving_input_pressed: Array = []


func _input(event: InputEvent) -> void:
	# ta del inputa je kar razdelan, ampak ko enkrat regidtrira vse možnosti ga lahko "pozabim"

	if controlled_bolt.is_active:
		var input_changed: bool = false

		# rotacija
		if Input.get_axis(left_action, right_action) == 1:
			if not right_action in _driving_input_pressed:
				_driving_input_pressed.append(right_action)
				input_changed = true
		elif Input.get_axis(left_action, right_action) == -1:
			if not left_action in _driving_input_pressed:
				_driving_input_pressed.append(left_action)
				input_changed = true
		else:
			if right_action in _driving_input_pressed:
				_driving_input_pressed.erase(right_action)
				input_changed = true
			if left_action in _driving_input_pressed:
				_driving_input_pressed.erase(left_action)
				input_changed = true

		# premikanje
		if Input.is_action_pressed(fwd_action):
			if not fwd_action in _driving_input_pressed:
				_driving_input_pressed.append(fwd_action)
				input_changed = true
		elif Input.is_action_pressed(rev_action):
			if not rev_action in _driving_input_pressed:
				_driving_input_pressed.append(rev_action)
				input_changed = true
		else:
			if fwd_action in _driving_input_pressed:
				_driving_input_pressed.erase(fwd_action)
				input_changed = true
			if rev_action in _driving_input_pressed:
				_driving_input_pressed.erase(rev_action)
				input_changed = true

		if input_changed:
			_react_to_driving_input()

		# select weapon
		if Input.is_action_just_pressed(selector_action):
			controlled_bolt.bolt_hud.selected_feature_index += 1


func _ready() -> void:

	controlled_bolt.add_to_group(Rfs.group_players)
	# player coližn lejer
	controlled_bolt.set_collision_layer_bit(4, true)


func _physics_process(delta: float) -> void:

	if Input.is_action_pressed(shoot_action):
		controlled_bolt.is_shooting = true
	else:
		controlled_bolt.is_shooting = false


func _react_to_driving_input():
#	print ("_current_driving_action_pressed", _current_driving_action_pressed)

	# FWD
	if _driving_input_pressed.has(fwd_action):
		bolt_motion_manager.motion = bolt_motion_manager.MOTION.FWD
		if Rfs.game_manager.fast_start_window or not Rfs.game_manager.game_on:
			controlled_bolt.revup()
	# REV
	elif _driving_input_pressed.has(rev_action):
		bolt_motion_manager.motion = bolt_motion_manager.MOTION.REV
	# IDLE
	else:
		bolt_motion_manager.motion = bolt_motion_manager.MOTION.IDLE

	# ROTATION
	if _driving_input_pressed.has(left_action):
		bolt_motion_manager.rotation_dir = -1
	elif _driving_input_pressed.has(right_action):
		bolt_motion_manager.rotation_dir = 1
	else:
		bolt_motion_manager.rotation_dir = 0


func _on_game_state_change(new_game_state: bool, level_settings: Dictionary): # od GMja

	if new_game_state == true:
		#		printt ("game on SMS", new_game_state)
		pass
	else:
		#		printt ("game on SMS", new_game_state)
		pass
