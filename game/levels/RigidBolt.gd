extends Node2D

onready var rigid_front: RigidBody2D = $RigidFront
onready var wheel: Node2D = $Wheel



onready var player_stats: Dictionary = Pro.default_player_stats.duplicate()
onready var max_energy: float = player_stats["energy"] # zato, da se lahko resetira
var bolt_id: int # ga seta spawner
# player profil
onready var player_profile: Dictionary = Pro.player_profiles[bolt_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]

# bolt type profil
onready var bolt_profile: Dictionary = Pro.bolt_profiles[bolt_type].duplicate()
onready var controller_profiles: Dictionary = Pro.controller_profiles
onready var controller_profile_name: int = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]
#onready var slow_start_engine_power: float = fwd_engine_power # poveča se samo če zgrešiš start

var rotation_dir = 0
var max_engine_power: float = 100
var current_engine_power: float
func _input(event: InputEvent) -> void:

			
	if Input.is_action_pressed(fwd_action):
		current_engine_power += 107
	elif Input.is_action_pressed(rev_action):
		current_engine_power -= 7
	else:			
		current_engine_power = 0
	current_engine_power = clamp(current_engine_power, -max_engine_power, max_engine_power)
#
#	# rotation ... rotation_angle se računa na inputu (turn_angle)
	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
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
func _ready() -> void:
	pass
onready var wheel_front_l: Line2D = $RigidBack/BoltBig/_TestDrive/WheelFrontL
onready var wheel_front_r: Line2D = $RigidBack/BoltBig/_TestDrive/WheelFrontR
onready var rigid_back: RigidBody2D = $RigidBack

var wheel_rotation: float 
var back_rotation: float
func _process(delta: float) -> void:
	
	back_rotation = rigid_back.get_global_rotation()
	
	if not rotation_dir == 0:
#		wheel.rotation_degrees += rotation_dir
#	else:

		wheel.rotation_degrees += rotation_dir * 7# + rigid_body_2d.rotation_degrees
		wheel.rotation_degrees = clamp(wheel.rotation_degrees, -45, 45)
		wheel_rotation = wheel.rotation + back_rotation
		wheel_front_l.rotation_degrees = wheel.rotation_degrees
		wheel_front_r.rotation_degrees = wheel.rotation_degrees
	else:
		pass
#		pass
#		wheel_rotation = 0
		wheel.rotation_degrees = 0
		wheel_front_l.rotation_degrees = wheel.rotation_degrees
		wheel_front_r.rotation_degrees = wheel.rotation_degrees
	printt(rad2deg(wheel_rotation))
	
