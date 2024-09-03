extends Node

enum ControllerType {ARROWS, WASD, JOYPAD, AI}
export (ControllerType) var current_controller_type: int = ControllerType.ARROWS

onready var controller_bolt: Node2D = get_parent()

onready var fwd_action: String
onready var rev_action: String
onready var left_action: String
onready var right_action: String
onready var shoot_action: String
onready var selector_action: String

var controller_is_set: bool = false


func _ready() -> void:
	pass

func set_controller(player_controller_profile: int):
	
	if current_controller_type == ControllerType.AI:
		pass
		print("AI controls")
	else:
		var controller_actions: Dictionary = Pro.controller_profiles[player_controller_profile]
		fwd_action = controller_actions["fwd_action"]
		rev_action = controller_actions["rev_action"]
		left_action = controller_actions["left_action"]
		right_action = controller_actions["right_action"]
		shoot_action = controller_actions["shoot_action"]
		selector_action = controller_actions["selector_action"]		


func _input(event: InputEvent) -> void:

	if controller_bolt.bolt_active:
		
		controller_bolt.rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
		
		if Input.is_action_pressed(selector_action) and not controller_bolt.rotation_dir == 0:
			controller_bolt.current_engines_on = controller_bolt.EnginesOn.BOTH
		else:
			if Input.is_action_pressed(fwd_action):
				controller_bolt.current_engines_on = controller_bolt.EnginesOn.FRONT

			elif Input.is_action_pressed(rev_action):
				controller_bolt.current_engines_on = controller_bolt.EnginesOn.BACK
			else:		
				controller_bolt.current_engines_on = controller_bolt.EnginesOn.NONE


		# select weapon and shoot
		if Input.is_action_just_pressed(shoot_action):
			controller_bolt.shoot(1)


	
# HUMAN / AI	
	
#func _input(event: InputEvent) -> void:
#
#
#	if Input.is_action_just_pressed(fwd_action):
#		if not bolt_active and engines_on:
#			$Sounds/EngineRevup.play()
#		elif Ref.game_manager.fast_start_window:
#			$Sounds/EngineRevup.play()
#
#	if not bolt_active:
#		return
#
#	# fast start detection
#	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#		if Input.is_action_just_pressed(fwd_action) and Ref.game_manager.fast_start_window: # če še ni štartal (drugače bi bila slow start power še defoltna)
#			slow_start_engine_power = 0
#	else:
#		slow_start_engine_power = 0
#
#	if Input.is_action_pressed(fwd_action):
#		# slow start
#		if slow_start_engine_power == fwd_engine_power:
#			var slow_start_tween = get_tree().create_tween()
#			slow_start_tween.tween_property(self, "slow_start_engine_power", 0, 1).set_ease(Tween.EASE_IN)
#		engine_power = fwd_engine_power - slow_start_engine_power
#
#	elif Input.is_action_pressed(rev_action):
#		engine_power = - rev_engine_power
#	else:			
#		engine_power = 0
#
#	# rotation ... rotation_angle se računa na inputu (turn_angle)
#	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
#
#	# weapon select
#	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#		if Input.is_action_pressed(selector_action):
#			bolt_hud.selected_active_weapon_index += 1
#	else:
#		if Input.is_action_just_pressed(selector_action):
#			bolt_hud.selected_active_weapon_index += 1
#
#	# select weapon and shoot
#	if Input.is_action_just_pressed(shoot_action):
#		shoot(bolt_hud.selected_weapon_index)
		
