extends Node


var controlled_bolt: RigidBody2D # seta spawner
var controller_type: int

onready	var controller_actions: Dictionary = Pros.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]


func _input(event: InputEvent) -> void:

	if controlled_bolt.is_active:

		# ko ni igre ima v leru
		if not Refs.game_manager.game_on:
			if Input.is_action_just_pressed(fwd_action):
				controlled_bolt.revup()
		else:
			# rotacija
			controlled_bolt.rotation_dir = Input.get_axis(left_action, right_action) # 1, -1, 0
			if Input.is_action_pressed(fwd_action):
				controlled_bolt.bolt_shift = 1
				controlled_bolt.current_motion = controlled_bolt.MOTION.FWD
				if Refs.game_manager.fast_start_window:
					controlled_bolt.revup()
			elif Input.is_action_pressed(rev_action):
				controlled_bolt.bolt_shift = -1
				controlled_bolt.current_motion = controlled_bolt.MOTION.REV
			elif controlled_bolt.rotation_dir == 0:
				controlled_bolt.current_motion = controlled_bolt.MOTION.IDLE
			elif controlled_bolt.rotation_dir == 1 or controlled_bolt.rotation_dir == -1:
				controlled_bolt.current_motion = controlled_bolt.free_motion_type

			# select weapon
			if Input.is_action_just_pressed(selector_action):
				controlled_bolt.bolt_hud.actived_weapon_key += 1


func _ready() -> void:

	controlled_bolt.add_to_group(Refs.group_humans)


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed(shoot_action):
		controlled_bolt.is_shooting = true
	else:
		controlled_bolt.is_shooting = false
		#			if Input.is_action_just_pressed(shoot_action):
		#				controlled_bolt.shoot(controlled_bolt.bolt_hud.selected_ammo_index)
		#			controlled_bolt.shoot(0)
	# dokler ni igre fizika ne dela
	if Refs.game_manager.game_on and controlled_bolt.is_active:
#		return
		controlled_bolt.force_rotation = controlled_bolt.heading_rotation + controlled_bolt.get_global_rotation()
