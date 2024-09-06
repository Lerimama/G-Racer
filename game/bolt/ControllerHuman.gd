extends Node

#enum ControllerType {ARROWS, WASD, JOYPAD, AI}
#export (ControllerType) var current_controller_type: int = ControllerType.ARROWS # VEN ... seta se ob spavnu
#
#var controller_type: int # seta se ob spavnu

onready var controller_bolt: RigidBody2D# = get_parent()

onready var fwd_action: String
onready var rev_action: String
onready var left_action: String
onready var right_action: String
onready var shoot_action: String
onready var selector_action: String

var controller_is_set: bool = false
var human_controlled: bool = true # OPT ... ai controls na koncu setaš drugače
#onready var ai_controller: Node2D = $"../AIController"

var controller_type: int


func _ready() -> void:
	pass
	sett_controller()
	
#func set_controller(player_controller_type: int):
func sett_controller():
	
	var controller_actions: Dictionary = Pro.controller_profiles[controller_type]
	print ("controller_actions", controller_bolt)
	fwd_action = controller_actions["fwd_action"]
	rev_action = controller_actions["rev_action"]
	left_action = controller_actions["left_action"]
	right_action = controller_actions["right_action"]
	shoot_action = controller_actions["shoot_action"]
	selector_action = controller_actions["selector_action"]		

#	if controller_type == Pro.CONTROLLER_TYPE.AI:
#		human_controlled = false
#		controller_bolt.add_to_group(Ref.group_ai)
#		ai_controller.activate_ai()
#		print("AI IN")
#	else:
	controller_bolt.add_to_group(Ref.group_humans)
#		ai_controller.queue_free()
	print("HUMAN IN")
	
		
func _input(event: InputEvent) -> void:
	
	if human_controlled:
		if controller_bolt.bolt_active:
			controller_bolt.rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
			printt("input works", controller_bolt.rotation_dir)
			if Input.is_action_pressed("no1"):
	#			controller_bolt.spawn_shield(1)
				controller_bolt.manipulate_engine_power(150, 1)
	#			controller_bolt.manipulate_tracking(20, 1)
			if Input.is_action_pressed(selector_action) and not controller_bolt.rotation_dir == 0:
				controller_bolt.current_motion = controller_bolt.MOTION.TILT
			else:
				if Input.is_action_pressed(fwd_action):
					controller_bolt.current_motion = controller_bolt.MOTION.FWD

				elif Input.is_action_pressed(rev_action):
					controller_bolt.current_motion = controller_bolt.MOTION.REV
				else:		
					controller_bolt.current_motion = controller_bolt.MOTION.IDLE
			# select weapon and shoot
			if Input.is_action_just_pressed(shoot_action):
				controller_bolt.shoot(1) # debug


func _process(delta: float) -> void:
	
	if controller_bolt.bolt_active:
		controller_bolt.force_rotation = controller_bolt.current_engines_rotation + controller_bolt.get_global_rotation()

		
	
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
#	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
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
#	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
#		if Input.is_action_pressed(selector_action):
#			bolt_hud.selected_active_weapon_index += 1
#	else:
#		if Input.is_action_just_pressed(selector_action):
#			bolt_hud.selected_active_weapon_index += 1
#
#	# select weapon and shoot
#	if Input.is_action_just_pressed(shoot_action):
#		shoot(bolt_hud.selected_weapon_index)
		
