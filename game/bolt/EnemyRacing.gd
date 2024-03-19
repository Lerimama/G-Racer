extends Bolt
class_name Enemy

signal path_changed (path)

var player_name: String # za opredelitev statistike
var player_profile: Dictionary

# idle
var navigation_cells: Array # sek
var idle_brake_factor: float = 0.80 # množenje s hitrostjo
var idle_vision_angle: float = 45  # plus in minus
var idle_target_max_distance: float = 200
var idle_target_min_distance: float = 100
var idle_target_set: bool #  =  false

# battle AI
var min_attacking_distance: float = 50
var max_attacking_distance: float = 350 # znotraj dometa rakete
var locked_on_target: bool
var target_reached: bool
var target_speed_slow = 25
var shocker_delay_time: float = 1.5

# vision
onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray_front = $VisionFront
onready var vision_ray_rear = $VisionRear
onready var vision_ray_left = $VisionLeft # poz kot
onready var vision_ray_right = $VisionRight # neg kot

# enemy profil
onready var aim_time = Pro.enemy_profile["aim_time"]
onready var seek_rotation_range = Pro.enemy_profile["seek_rotation_range"]
onready var seek_rotation_speed = Pro.enemy_profile["seek_rotation_speed"]
onready var seek_distance = Pro.enemy_profile["seek_distance"]
onready var engine_power_idle = Pro.enemy_profile["engine_power_idle"]
onready var engine_power_battle = Pro.enemy_profile["engine_power_battle"]
onready var shooting_ability = Pro.enemy_profile["shooting_ability"]

# neu
enum AIStates {IDLE, RACING, FOLLOWING,} # MONITORING, ATTACKING, SEARCHING, PATROLING, WANDERING, DYING, DISSARAY,	
var current_ai_state: int = AIStates.IDLE

onready var detect_area: Node2D = $DetectArea
onready var detect_left: Area2D = $DetectArea/DetectLeft
onready var detect_right: Area2D = $DetectArea/DetectRight
onready var detect_front: Area2D = $DetectArea/DetectFront
onready var detect_back: Area2D = $DetectArea/DetectBack

var level_goal_position: Vector2 = Ref.game_manager.level_goal_position
var navigation_target_position: Vector2 = Vector2.ZERO setget _on_target_position_changed
var detected_bolts: Array
var bolt_to_follow: KinematicBody2D	

func _ready() -> void:
	print(player_name)

	# player setup
	player_profile = Pro.default_player_profiles[bolt_id]
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"] # bolt se obarva ... 
	bolt_sprite.modulate = bolt_color
	add_to_group(Ref.group_enemies)
	
	randomize()
	
	navigation_target_position = level_goal_position
#	self.navigation_target_position = level_goal_position

			
func _physics_process(delta: float) -> void:
		
	if not bolt_active: # ai je kot kontrole pri plejerju
		return
		
	var next_position: Vector2 = navigation_agent.get_next_location()
	acceleration = position.direction_to(next_position) * engine_power
	
	navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom
	steering(delta) # more bi pred rotacijo, da se upošteva
	rotation = velocity.angle() 

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()

	set_ai_states()
#	set_motion_states()

	match current_ai_state:
		AIStates.IDLE:
			seek_ray.enabled = false
			bolt_to_follow = null
#			self.navigation_target_position = global_position
			engine_power = 0
		AIStates.RACING:
			seek_ray.enabled = false
			bolt_to_follow = null
#			if not navigation_target_position == level_goal_position:
#				self.navigation_target_position = level_goal_position
			seek_ray.cast_to.x = 100
			seek_ray.look_at(Vector2.RIGHT + global_position)
			bolt_sprite.modulate = Set.color_yellow
			engine_power = 120
		AIStates.FOLLOWING: # plejer je dovlj blizu, da mu sledi
#			self.navigation_target_position = bolt_to_follow.global_position
			seek_ray.cast_to.x = global_position.distance_to(navigation_target_position)
			seek_ray.look_at(navigation_target_position)
			engine_power = 100
		

func set_ai_states():
	
	current_ai_state = AIStates.RACING
	return	
	
	# če ni zaznal pleyerja
	if detected_bolts.empty():
		current_ai_state = AIStates.RACING
		return
	# še leaderja dodaj
	# izberem najustreznejšo tarčo
	for detected_bolt in detected_bolts:
		# če je dovolj blizu ga setam za tarčo
		var distance_to_bolt: float = global_position.distance_to(detected_bolt.global_position) 
		if distance_to_bolt > 100:
			bolt_to_follow = detected_bolt
		else:
			bolt_to_follow = null
	# če tarča je ji sledim		
	if bolt_to_follow:
		seek_ray.enabled = true
		if seek_ray.is_colliding() and not seek_ray.get_collider() == bolt_to_follow:
			current_ai_state = AIStates.RACING
		else:
			current_ai_state = AIStates.FOLLOWING
	# če ne pa dirkam
	else:
		current_ai_state = AIStates.RACING	

	
func set_motion_states():
	
	if engine_power > 0:
		current_motion_state = MotionStates.FWD
	elif engine_power < 0:
		current_motion_state = MotionStates.REV
	else:
		current_motion_state = MotionStates.IDLE


func _on_target_position_changed(new_position: Vector2):

	target_reached = false
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
	
#	bolt_active = false

	pass
	
func _on_NavigationAgent2D_target_reached() -> void:
	print("TARG")
#	bolt_active = false
	pass # Replace with function body.








#func vision(delta: float):
#
#	# čekiraj ovire pred sabo
#	vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost
#
#	# zaviranje pred oviro
#	if vision_ray_front.is_colliding() and not vision_ray_front.get_collider().is_in_group(Ref.group_bolts):
#		velocity *= idle_brake_factor	
		
		
		
#	# večno iskanje tarče
#	if seek_ray.is_colliding() and seek_ray.get_collider().is_in_group(Ref.group_bolts):
#		var collider = seek_ray.get_collider()
#		target_location = collider.global_position
#		if collider.velocity.length() < target_speed_slow:
#			rotation = (target_location - global_position).angle() # kot vektorja AB = B - A
#			look_at(target_location)
#		seek_ray.look_at(target_location)
#		battle(collider)
#		bolt_sprite.modulate = Color.red
#
#	else:
#	idle() # vklopi idle režim
#	bolt_sprite.modulate = bolt_color
#	seek_ray.rotation += seek_rotation_speed * delta
#	if seek_ray.get_rotation_degrees() > seek_rotation_range or seek_ray.get_rotation_degrees() < - seek_rotation_range:
#		seek_rotation_speed *= -1
				
##	if control_enabled:
#	if bolt_active:
#
#		# čekiraj ovire pred sabo
#		vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost
#		if vision_ray_front.is_colliding() and not vision_ray_front.get_collider().is_in_group(Ref.group_bolts):
#			velocity *= idle_brake_factor
#
#		# večno iskanje tarče
#		if seek_ray.is_colliding() and seek_ray.get_collider().is_in_group(Ref.group_bolts):
#			var collider = seek_ray.get_collider()
#			target_location = collider.global_position
#			if collider.velocity.length() < target_speed_slow:
#				rotation = (target_location - global_position).angle() # kot vektorja AB = B - A
#				look_at(target_location)
#			seek_ray.look_at(target_location)
#			battle(collider)
#			bolt_sprite.modulate = Color.red
#
#		else:
#			idle() # vklopi idle režim
#			bolt_sprite.modulate = bolt_color
#			seek_ray.rotation += seek_rotation_speed * delta
#			if seek_ray.get_rotation_degrees() > seek_rotation_range or seek_ray.get_rotation_degrees() < - seek_rotation_range:
#				seek_rotation_speed *= -1
#
#	# reset vision ray
#	elif not bolt_active:
##	elif not control_enabled:
#		seek_ray.rotation = 0


#func idle():
#
#	engine_power = engine_power_idle
#
#	var idle_target_cell: Vector2 = global_position # določena pozicija prve random celice
#	var idle_area: Array = []
#
#	# position node
#	navigation_target_position = idle_target_cell # boltova tarča je random tarča
#
#	# random close area
#	if not idle_target_set:
#		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
#
#			for cell_position in navigation_cells:
#				# če je polju dosega
#				var distance_to_cell: float = global_position.distance_to(cell_position)
#				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
#				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
#					if distance_to_cell > idle_target_min_distance and distance_to_cell < idle_target_max_distance:
#						idle_area.append(cell_position)
#			# random celica je target 
#			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
#				idle_target_cell = idle_area[randi() % idle_area.size() - 1]
#
#			navigation_target_position = idle_target_cell # boltova tarča je random tarča
#			idle_target_set = true
#	else:
#		# ko se pot izteče, gremo še enkrat iskat tarčo
#		var current_path_size = navigation_agent.get_nav_path().size()
#		if current_path_size < 5:
#			idle_target_set = false
#
#	shocker_check() # a postavlja mine v idle modetu?


#func battle(target_body: Node):
#
#	var distance_to_target: float = navigation_agent.distance_to_target()
#	var target_speed: float = target_body.velocity.length()
#
#	# če je raketa počasna se ustavi
#	if target_speed < target_speed_slow:
#		velocity = lerp(velocity, Vector2.ZERO, 0.05)
#		engine_power = lerp(engine_power, 0, 0.05)
#	else:
#		engine_power = engine_power_battle
#
#	# razdalja večja od dosega rakete
#	if distance_to_target >= max_attacking_distance:
#		shooting("bullet")
#	# razdalja manjša od dosega rakete in večja od minimalne bližine
#	elif distance_to_target > min_attacking_distance:
#		# streljaj raketo, če je počasna in jo ima
#		if target_speed < target_speed_slow and misile_count > 0:
#			yield(get_tree().create_timer(2), "timeout")
#			shooting("misile")
#			yield(get_tree().create_timer(2), "timeout")
#		# streljaj metk, če ni počasna ali nima rakete
#		else:
#			# da ni istočasno z raketo ... se na pozna na hitrosti streljanja
#			yield(get_tree().create_timer(aim_time), "timeout") 
#			# na vsakem metku je aim_time zamik, med sabo pa so zamaknjeni za reload time, to pomeni da reload aim zamakne samo začetek streljanja
#			shooting("bullet")
#	# razdalja manjša od minimalne bližine
#	else:
#		bolt_sprite.modulate = Color.red
#		engine_power = lerp(engine_power, 0, 0.05)
#		velocity = lerp(velocity, Vector2.ZERO, 0.05)
#		shooting("bullet")
#
#	shocker_check() # čekiraj razmere za mino


#func shocker_check():
#
#	if vision_ray_left.is_colliding() and vision_ray_right.is_colliding():
#		var collider_left = vision_ray_left.get_collider()
#		var collider_right = vision_ray_right.get_collider()
#		# če je v prišel v ožino in še ni odvrgel mine v trenutni ožini
#		if collider_left.is_in_group(Ref.group_arena) and collider_right.is_in_group(Ref.group_arena):
#			if not shocker_released:
#				shocker_released = true # pomembno, da je pred tajmerjem
#				yield(get_tree().create_timer(shocker_delay_time), "timeout") # tajming da ne dropne čist na začetku ožine
#				shooting("shocker")
#	# če je šel iz ožine ... ta del bi bil lahko bolj specifičen kaj je ožina
#	else:
#		shocker_released = false
#
#	# če ma plejerja na riti
#	if vision_ray_rear.is_colliding() and vision_ray_rear.get_collider().is_in_group(Ref.group_bolts):
#		shooting("shocker")
#		shocker_released = true

