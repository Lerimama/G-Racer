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
				controlled_bolt.current_motion = controlled_bolt.MOTION.FWD
				if Input.is_action_pressed(selector_action):
					controlled_bolt.is_drifting = true
				else:
					controlled_bolt.is_drifting = false
			
			# nazaj
			elif Input.is_action_pressed(rev_action):
				controlled_bolt.current_motion = controlled_bolt.MOTION.REV
			
			# v leru
			else:		
				controlled_bolt.current_motion = controlled_bolt.MOTION.IDLE
					
			# shooting
			#			# OPT kontorole selector weapon vs drift
			#			if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE: 
			#				if Input.is_action_pressed(selector_action):
			#					controlled_bolt.bolt_hud.selected_active_weapon_index += 1
			#			else:
			#				if Input.is_action_just_pressed(selector_action):
			#					controlled_bolt.bolt_hud.selected_active_weapon_index += 1
			
			if Input.is_action_just_pressed(shoot_action):
				#				controlled_bolt.shoot(controlled_bolt.bolt_hud.selected_weapon_index)
				controlled_bolt.shoot(2) # debug ... shoot


func _ready() -> void:
	
	controlled_bolt.add_to_group(Ref.group_humans)
	
	
func _physics_process(delta: float) -> void:

	# dokler ni igre fizika ne dela
	if Ref.game_manager.game_on and controlled_bolt.bolt_active:
		controlled_bolt.force_rotation = controlled_bolt.current_engines_rotation + controlled_bolt.get_global_rotation()
