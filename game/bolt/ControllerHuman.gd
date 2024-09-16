extends Node


var controlled_bolt: RigidBody2D # seta spawner
var controller_type: int

onready	var controller_actions: Dictionary = Pro.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]	

	
func _input(event: InputEvent) -> void:
	
	if controlled_bolt.bolt_active:
		
		# ko ni igre ima v leru
		if not Ref.game_manager.game_on: 
			if Input.is_action_just_pressed(fwd_action):
				$Sounds/EngineRevup.play()
			elif Ref.game_manager.fast_start_window:
					$Sounds/EngineRevup.play()
		else:
			# rotacija
			controlled_bolt.rotation_dir = Input.get_axis(left_action, right_action) # 1, -1, 0

			# naprej
			if Input.is_action_pressed(fwd_action):
				if not controlled_bolt.current_motion == controlled_bolt.MOTION.FWD:
					controlled_bolt.current_motion = controlled_bolt.MOTION.FWD
			
			# nazaj
			elif Input.is_action_pressed(rev_action):
				if not controlled_bolt.current_motion == controlled_bolt.MOTION.REV:
					controlled_bolt.current_motion = controlled_bolt.MOTION.REV
			
			# v leru
			else:		
				if not controlled_bolt.current_motion == controlled_bolt.MOTION.IDLE:
					controlled_bolt.current_motion = controlled_bolt.MOTION.IDLE
			
			# idle_motion
			if not controlled_bolt.rotation_dir == 0 and controlled_bolt.current_motion == controlled_bolt.MOTION.IDLE:		
				if controlled_bolt.idle_motion_on == false:
					controlled_bolt.idle_motion_on = true
			else:
				if controlled_bolt.idle_motion_on == true:
					controlled_bolt.idle_motion_on = false
									
			# shooting
			#			# OPT kontorole selector weapon vs drift
			#			if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE: 
			#				if Input.is_action_pressed(selector_action):
			#					controlled_bolt.bolt_hud.selected_active_weapon_index += 1
			#			else:
			#				if Input.is_action_just_pressed(selector_action):
			#					controlled_bolt.bolt_hud.selected_active_weapon_index += 1
			



func _ready() -> void:
	
	controlled_bolt.add_to_group(Ref.group_humans)
	
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed(shoot_action):
#			if Input.is_action_just_pressed(shoot_action):
			#				controlled_bolt.shoot(controlled_bolt.bolt_hud.selected_weapon_index)
			controlled_bolt.shoot(0) # debug ... shoot
	# dokler ni igre fizika ne dela
	if Ref.game_manager.game_on and controlled_bolt.bolt_active:
#		return
		controlled_bolt.force_rotation = controlled_bolt.thrust_rotation + controlled_bolt.get_global_rotation()
