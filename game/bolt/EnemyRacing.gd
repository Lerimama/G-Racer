extends Bolt
class_name Enemy

signal path_changed (path)


enum AIStates {IDLE, RACING, FOLLOWING,} # MONITORING, ATTACKING, SEARCHING, PATROLING, WANDERING, DYING, DISSARAY,	
var current_ai_state: int = AIStates.IDLE

var player_name: String # za opredelitev statistike
var player_profile: Dictionary
var level_goal_position: Vector2 = Ref.game_manager.level_goal_position

# vision
var navigation_cells: Array # sek
var navigation_target_position: Vector2 = Vector2.ZERO setget _on_target_position_changed
onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray_front = $VisionFront
# detect
var detected_bolts: Array
onready var detect_area: Node2D = $DetectArea
onready var detect_left: Area2D = $DetectArea/DetectLeft
onready var detect_right: Area2D = $DetectArea/DetectRight
onready var detect_front: Area2D = $DetectArea/DetectFront
onready var detect_back: Area2D = $DetectArea/DetectBack
# enemy profil
onready var racing_engine_power = Pro.enemy_profile["racing_engine_power"]
onready var idle_engine_power = Pro.enemy_profile["idle_engine_power"]


func _ready() -> void:

	# player setup
	player_profile = Pro.default_player_profiles[bolt_id]
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"] # bolt se obarva ... 
	bolt_sprite.modulate = bolt_color
	add_to_group(Ref.group_enemies)
	
	randomize()
	
	navigation_target_position = level_goal_position

			
func _physics_process(delta: float) -> void:
	
		
	if not bolt_active: # ai je kot kontrole pri plejerju
		return

	manage_ai_states()
	manage_motion_states()
	
	# čekiraj ovire pred sabo
	vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost	
	
	var next_position: Vector2 = navigation_agent.get_next_location()
	acceleration = position.direction_to(next_position) * engine_power
	
	navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom
	steering(delta) # more bi pred rotacijo, da se upošteva
	if current_motion_state == MotionStates.DISARRAY:
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		rotate(delta * rotation_angle)
	else:
		rotation = velocity.angle()

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()

	current_ai_state = AIStates.RACING
	
	
func manage_ai_states():
	
	var bolt_to_follow: KinematicBody2D	
	
	match current_ai_state:
		AIStates.IDLE:
			seek_ray.enabled = false
			bolt_to_follow = null
			engine_power = idle_engine_power
		AIStates.RACING:
			seek_ray.enabled = false
			bolt_to_follow = null
			# target pošilja GM
			seek_ray.cast_to.x = velocity.length()
			seek_ray.look_at(Vector2.RIGHT + global_position)
			engine_power = racing_engine_power
		AIStates.FOLLOWING: # plejer je dovlj blizu, da mu sledi
			seek_ray.cast_to.x = global_position.distance_to(navigation_target_position)
			seek_ray.look_at(navigation_target_position)
			engine_power = racing_engine_power	

	
func manage_motion_states():
	
	if engine_power > 0:
		current_motion_state = MotionStates.FWD
	elif engine_power < 0:
		current_motion_state = MotionStates.REV
	else:
		current_motion_state = MotionStates.IDLE


func _on_target_position_changed(new_position: Vector2):

	navigation_agent.set_target_location(new_position)
	navigation_target_position = new_position


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body is Player:
		detected_bolts.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:
	
	detected_bolts.erase(body)
	

func _on_NavigationAgent2D_path_changed() -> void:
	
	emit_signal("path_changed", navigation_agent.get_nav_path()) # levelu preko arene pošljemo točke poti do cilja	


func _on_NavigationAgent2D_navigation_finished() -> void:
	print("_on_NavigationAgent2D_navigation_finished")
	
	
func _on_NavigationAgent2D_target_reached() -> void:
	print("_on_NavigationAgent2D_target_reached")


		
