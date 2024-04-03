extends Bolt
class_name Enemy

signal path_changed (path)

var player_name: String # za opredelitev statistike
var level_goal_position: Vector2 = Ref.game_manager.level_goal_position
onready var player_profile: Dictionary = Pro.player_profiles[bolt_id]

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
	
	add_to_group(Ref.group_enemies)
	
	# player setup
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"] # bolt se obarva ... 
	bolt_sprite.modulate = bolt_color
	
	randomize()
	
	self.navigation_target_position = level_goal_position

			
func _physics_process(delta: float) -> void:
		
	if not bolt_active:
		return

	manage_motion_states(delta)
	manage_modes()
	
	if current_motion_state == MotionStates.DISARRAY:
		acceleration = position.direction_to(Vector2.ZERO) * engine_power
	else:
		var next_position: Vector2 = navigation_agent.get_next_location()
		acceleration = position.direction_to(next_position) * engine_power
		# navigation_agent.set_velocity(velocity) .. to je za avoidance? # vedno za kustom velocity izračunom
		# steering(delta) # more bi pred rotacijo, da se upošteva ... ne vem če kaj vpliva
		rotation = velocity.angle()
		# čekiraj ovire pred sabo
		vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost	

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()


func manage_modes():

	var bolt_to_follow: KinematicBody2D	

	match current_mode:
		Modes.RACING:
			seek_ray.enabled = false
			bolt_to_follow = null
			# target pošilja GM
			seek_ray.cast_to.x = velocity.length()
			seek_ray.look_at(Vector2.RIGHT + global_position)
#			engine_power = 30
			engine_power = racing_engine_power
		Modes.FOLLOWING: # plejer je dovlj blizu, da mu sledi
			seek_ray.cast_to.x = global_position.distance_to(navigation_target_position)
			seek_ray.look_at(navigation_target_position)
			engine_power = racing_engine_power	


#		current_ai_state = AIStates.RACING
#	
#
#func manage_ai_states():
#
#	enum AIStates {IDLE, RACING, FOLLOWING, FIGHTING} # MONITORING, ATTACKING, SEARCHING, PATROLING, WANDERING, DYING, DISSARAY,	
#	var current_ai_state: int = AIStates.IDLE	
#
#	var bolt_to_follow: KinematicBody2D	
#
#	match current_ai_state:
#		AIStates.IDLE:
#			seek_ray.enabled = false
#			bolt_to_follow = null
#			engine_power = idle_engine_power
#		AIStates.RACING:
#			seek_ray.enabled = false
#			bolt_to_follow = null
#			# target pošilja GM
#			seek_ray.cast_to.x = velocity.length()
#			seek_ray.look_at(Vector2.RIGHT + global_position)
#			engine_power = 50
##			engine_power = racing_engine_power
#		AIStates.FOLLOWING: # plejer je dovlj blizu, da mu sledi
#			seek_ray.cast_to.x = global_position.distance_to(navigation_target_position)
#			seek_ray.look_at(navigation_target_position)
#			engine_power = racing_engine_power	

	
#func manage_motion_states():
#
#	if engine_power > 0:
#		current_motion_state = MotionStates.FWD
#	elif engine_power < 0:
#		current_motion_state = MotionStates.REV
#	else:
#		current_motion_state = MotionStates.IDLE


func on_checkpoint_reached(checkpoint: Area2D):
	
	if not checkpoints_reached.has(checkpoint): # če še ni dodana
		checkpoints_reached.append(checkpoint)


func on_race_finished():
	
	var finish_tween = get_tree().create_tween()
	finish_tween.tween_property(self, "velocity", Vector2.ZERO, 1).set_ease(Tween.EASE_OUT).set_delay(1)
	yield(finish_tween, "finished")
	self.bolt_active = false
	set_physics_process(false)
	
				
func _on_target_position_changed(new_position: Vector2):
	
	navigation_agent.set_target_location(new_position)
	navigation_target_position = new_position


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_players):
		detected_bolts.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:
	
	detected_bolts.erase(body)
	

func _on_NavigationAgent2D_path_changed() -> void:
	
	emit_signal("path_changed", navigation_agent.get_nav_path()) # levelu preko arene pošljemo točke poti do cilja	


func _on_NavigationAgent2D_navigation_finished() -> void:
#	print("_on_NavigationAgent2D_navigation_finished")
	pass
	
func _on_NavigationAgent2D_target_reached() -> void:
#	print("_on_NavigationAgent2D_target_reached")
	pass
