extends Bolt


onready var controller_profiles: Dictionary = Pro.controller_profiles
onready var controller_profile_name: int = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]
onready var slow_start_engine_power: float = fwd_engine_power # poveča se samo če zgrešiš start


func _input(event: InputEvent) -> void:
	return
			
	if Input.is_action_just_pressed(fwd_action):
		if not bolt_active and engines_on:
			$Sounds/EngineRevup.play()
		elif Ref.game_manager.fast_start_window:
			$Sounds/EngineRevup.play()
			
	if not bolt_active:
		return
	
	# fast start detection
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if Input.is_action_just_pressed(fwd_action) and Ref.game_manager.fast_start_window: # če še ni štartal (drugače bi bila slow start power še defoltna)
			slow_start_engine_power = 0
	else:
		slow_start_engine_power = 0
		
	if Input.is_action_pressed(fwd_action):
		# slow start
		if slow_start_engine_power == fwd_engine_power:
			var slow_start_tween = get_tree().create_tween()
			slow_start_tween.tween_property(self, "slow_start_engine_power", 0, 1).set_ease(Tween.EASE_IN)
		engine_power = fwd_engine_power - slow_start_engine_power
		
	elif Input.is_action_pressed(rev_action):
		engine_power = - rev_engine_power
	else:			
		engine_power = 0
		
	# rotation ... rotation_angle se računa na inputu (turn_angle)
	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
	
	# weapon select
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if Input.is_action_pressed(selector_action):
			bolt_hud.selected_active_weapon_index += 1
	else:
		if Input.is_action_just_pressed(selector_action):
			bolt_hud.selected_active_weapon_index += 1
	
	# select weapon and shoot
	if Input.is_action_just_pressed(shoot_action):
		shoot(bolt_hud.selected_weapon_index)
		
	
func _ready() -> void:
	
	add_to_group(Ref.group_players)
	
onready var velocity_ray: RayCast2D = $VelocityRay
onready var rigid_body_2_d_2: RigidBody2D = $RigidBody2D2
onready var rigid_front: RigidBody2D = $RigidFront

func _physics_process(delta: float) -> void:
	return
	acceleration = wheel_front_l.transform.x.rotated(bolt_big.global_rotation) * engine_power # pospešek je smer (transform.x) z močjo motorja
#	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
#	acceleration =  * engine_power # pospešek je smer (transform.x) z močjo motorja
	velocity_ray.cast_to.x = velocity.length()
	velocity_ray.rotation_degrees = wheel_front_l.rotation_degrees + bolt_big.rotation_degrees
#	if current_motion_state == MotionStates.IDLE: # aplikacija free rotacije
#		rotate(delta * rotation_angle * free_rotation_multiplier)
	
	# poraba bencina
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if current_motion_state == MotionStates.FWD:
			manage_gas(fwd_gas_usage)
		elif current_motion_state == MotionStates.REV:
			manage_gas(rev_gas_usage)
			

	rotate_tires()

	drag_div = 200
	var drag_force = current_drag * velocity * velocity.length() / drag_div # množenje z velocity nam da obliko vektorja
	acceleration -= drag_force
	# hitrost je pospešek s časom
	velocity += acceleration * delta 
#	rigid_body_2d.add_central_force(acceleration)
#	rotation_angle = rotation_dir * deg2rad(turn_angle)
	rotate(delta * rotation_angle)
#	bolt_big.global_rotation = angle_to_vector
#	steering(delta)


onready var wheel_front_l: Line2D = $BoltBig/_TestDrive/WheelFrontL
onready var wheel_front_r: Line2D = $BoltBig/_TestDrive/WheelFrontR
onready var wheel_rear_l: Line2D = $BoltBig/_TestDrive/WheelRearL
onready var wheel_rear_r: Line2D = $BoltBig/_TestDrive/WheelRearR
onready var dir_rear_vector: Line2D = $BoltBig/_TestDrive/DirRear
onready var dir_front_vector: Line2D = $BoltBig/_TestDrive/DirFront


var wheels_rotation_glo: float
onready var pin_joint_2d: PinJoint2D = $PinJoint2D
onready var rigid_body_2d: RigidBody2D = $RigidBody2D

onready var joint_vector: Vector2# = rigid_body_2d.global_position + global_position
#onready var joint_vector: Vector2 = rigid_body_2d.position
var angle_to_vector: float = 0
onready var vector_line2d: Line2D = $DirFront
onready var bolt_big: Sprite = $BoltBig
onready var position_2d: Position2D = $RigidBody2D/Position2D


var WHEEL_DIRECTION: float # glavna smer glede na trenuten položa
func rotate_tires():
#	printt(vec_between,rotation_degrees)
#	joint_vector = rigid_body_2d.global_position.du# + global_position
#	angle_to_vector = get_angle_to(joint_vector) #- rotation_degrees
#	angle_to_vector = Vector2.RIGHT.angle_to_point(rigid_body_2d.global_position) #- rotation_degrees
	vector_line2d.set_point_position(0, rigid_front.position)
	vector_line2d.set_point_position(1, rigid_body_2d.position)
	angle_to_vector = Vector2.RIGHT.angle_to(-rigid_body_2d.position)
	bolt_big.rotation = angle_to_vector# - rad2deg(180)
#	printt("ANGLE", rad2deg(angle_to_vector), rotation_dir)#,  rigid_body_2d.to_global(rigid_body_2d.position))
#	rotation_degrees = get_angle_to(vec_between) #- rotation_degrees
	turn_angle = 50
	WHEEL_DIRECTION += rotation_dir
	var zero: float = 180
	if rotation_dir == 0:
		wheel_front_r.rotation_degrees = 0
		wheel_front_l.rotation_degrees = 0
		WHEEL_DIRECTION = 0
#	elif wheel_front_r.rotation_degrees >= -90 and wheel_front_r.rotation_degrees <= 90:
	else:
#		printt("DIST", axis_distance)
		wheel_front_r.rotation_degrees = WHEEL_DIRECTION
		wheel_front_l.rotation_degrees = WHEEL_DIRECTION
#		wheel_front_l.rotation = self.rotation
#		wheel_front_r.rotation = self.rotation
	
	
func steering(delta: float) -> void:
#	return
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading: Vector2 = (front_axis_position - rear_axis_position).normalized()
#	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction" ... 10 je za adaptacijo inputa	
	
	
	# if current_motion_state == MotionStates.FWD:
	# if fwd_motion:
	#	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	# elif current_motion_state == MotionStates.REV:
	# elif rev_motion:
	#	velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
#	rotation = new_heading.angle() # sprite se obrne v smeri	
	
	
	
	
func pull_bolt_on_screen(pull_position: Vector2, current_leader: KinematicBody2D):
	
	if not bolt_active:
		return
		
	bolt_collision.set_deferred("disabled", true)
	shield_collision.set_deferred("disabled", true)	
	
	# reštartam trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	yield(pull_tween, "finished")
	
	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	if player_stats["laps_count"] < current_leader.player_stats["laps_count"]:
		var laps_finished_difference: int = current_leader.player_stats["laps_count"] - player_stats["laps_count"]
		update_stat("laps_count", laps_finished_difference)
	
	# če preskoči checkpoint, ga dodaj, če ga leader ima
	var all_checked_bolts: Array = Ref.game_manager.bolts_checked
	if all_checked_bolts.has(current_leader):
		all_checked_bolts.append(self)

	# ne dela
	#	if Ref.game_manager.current_pull_positions.has(pull_position):
	#		Ref.game_manager.current_pull_positions.erase(pull_position)

	manage_gas(Ref.game_manager.game_settings["pull_gas_penalty"])
