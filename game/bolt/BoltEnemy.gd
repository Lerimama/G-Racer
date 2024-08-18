extends Bolt
class_name Enemy


#signal path_changed (path)


enum AiModes {RACING, FOLLOWING, FIGHTING} # RACING ... kadar šiba proti cilju, FOLLOWING ... kadar sledi gibajoči se tarči, FIGHTING ... kadar želi tarčo zadeti
var current_ai_mode: int = AiModes.RACING

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
#	player_name = player_profile["player_name"]
#	bolt_color = player_profile["player_color"] # bolt se obarva ... 
#	bolt_sprite.modulate = bolt_color
	
	randomize()
	
			
func _physics_process(delta: float) -> void:
	
#	printt("FPS", Performance.get_monitor(Performance.TIME_FPS))# _temp
	if Set.kamera_frcera:
		printt("FPS", Engine.get_physics_frames(), self.name) # _temp	

	
#	printt("Enemy", self)	
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
		steering(delta) # more bi pred rotacijo, da se upošteva ... ne vem če kaj vpliva
		rotation = velocity.angle()
		# čekiraj ovire pred sabo
#		vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost	

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()

	vision(delta)


func shoot():
#	selected_feature_index = 1
	match selected_feature_index:
		0: # no feature
			return
		1: # bullet
			shooting("bullet")
		2: # misile
			shooting("misile")
		3: # mina
			shooting("mina")
		4: # shocker 
			shooting("shocker")
			
			
func vision(delta: float):

	
	var ai_brake_factor: float = 0.8 # množenje s hitrostjo
	#	var ai_brake_distance: float = 50 # večja ko je, bolj je pazljiv
	var ai_shoot_distance: float = 100 # najbližja pri kateri še strelja 		
	# čekiraj ovire pred sabo
	#		var vision_ray_length: float = ai_shoot_distance #velocity.length()
	var vision_ray_length: float = velocity.length()
	vision_ray_front.cast_to = Vector2(vision_ray_length, 0) # zmeraj dolg kot je dolga hitrost
	if vision_ray_front.is_colliding():
		var current_collider = vision_ray_front.get_collider()
		var distance_to_collider: float = global_position.distance_to(current_collider.global_position)
		if current_collider.is_in_group(Ref.group_players) and distance_to_collider > ai_shoot_distance:
			selected_feature_index = 1
			printt("aim_at", current_collider)
			shoot()
		velocity *= ai_brake_factor
		#			print("bremzam", current_collider)
		
		
func manage_modes():

#	var bolt_to_follow: KinematicBody2D	

	match current_ai_mode:
		AiModes.RACING:
			seek_ray.enabled = false
#			bolt_to_follow = null
			# target pošilja GM
			seek_ray.cast_to.x = velocity.length()
			seek_ray.look_at(Vector2.RIGHT + global_position)
#			engine_power = 30
			engine_power = racing_engine_power
		AiModes.FOLLOWING: # plejer je dovlj blizu, da mu sledi
			seek_ray.cast_to.x = global_position.distance_to(navigation_target_position)
			seek_ray.look_at(navigation_target_position)
			engine_power = racing_engine_power	

				
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
	
#	emit_signal("path_changed", navigation_agent.get_nav_path()) # levelu preko arene pošljemo točke poti do cilja	
	pass


func _on_NavigationAgent2D_navigation_finished() -> void:
#	print("_on_NavigationAgent2D_navigation_finished")
	pass
	
	
func _on_NavigationAgent2D_target_reached() -> void:
#	print("_on_NavigationAgent2D_target_reached")
	pass
