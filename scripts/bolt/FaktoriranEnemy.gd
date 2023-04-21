extends Bolt


signal path_changed_faktoriran (dpath) # pošlje array pozicij

# idle
onready var navigation_cells: Array # sek
export var idle_brake_force: float = 0.95
var idle_vision_angle: float = 45  # plus in minus
var idle_target_max_distance = 300
var idle_target_set: bool #  =  false

# battle
var locked_on_target: bool
var target_reached: bool
var target_location: Vector2
var target_speed_slow = 15

export var min_attacking_distance: float = 70 # največja bližina do tarče ... engine_power = 0, rotira se okrog svoje osi (bolj nevaren za streljat)
export var max_attacking_distance: float = 400 # najdaljša bližina do tarče ... misile
export var mid_attacking_distance: float = 300 # najbližje ko še strelja misile
var shocker_delay_time: float = 1.5

# ---------------------------------------------------------------------------------------

onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray_front = $VisionFront
onready var vision_ray_rear = $VisionRear
onready var vision_ray_left = $VisionLeft # poz kot
onready var vision_ray_right = $VisionRight # neg kot

onready var rear_engine_position = $Bolt/RearEnginePosition
onready var front_engine_position_L = $Bolt/FrontEnginePositionL
onready var front_engine_position_R = $Bolt/FrontEnginePositionR

# enemy profil
onready var enemy_profile = Profiles.enemy_profiles
onready var aim_time = enemy_profile["aim_time"]
onready var seek_rotation_range = enemy_profile["seek_rotation_range"]
onready var seek_rotation_speed = enemy_profile["seek_rotation_speed"]
onready var seek_distance = enemy_profile["seek_distance"]
onready var engine_power_idle = enemy_profile["engine_power_idle"]
onready var engine_power_battle = enemy_profile["engine_power_battle"]
onready var shooting_ability = enemy_profile["shooting_ability"]

var player_profile: Dictionary
var player_name: String = "E1" # drugače ga pošlje spawner
var player_color: Color# = Color.white

var target_presssed: bool # _temp ... za klikanje z miško


func _ready() -> void:
	
	randomize()
	
	# player setup
#	name = player_name _temp off
	player_profile = Profiles.default_player_profiles[player_name]
	bolt_color = player_profile["player_color"] # bolt se obarva ... 
	bolt_sprite.modulate = bolt_color
	
	add_to_group(Config.group_enemies)
	
	seek_ray.cast_to.x = seek_distance
	

func _physics_process(delta: float) -> void:
	
	if Input.is_mouse_button_pressed(1):
		set_target_location(get_global_mouse_position())
		target_presssed = true
	else:
		set_target_location(target_location) # tukaj setamo target reached na false
	
#	set_target_location(target_location) # tukaj setamo target reached na false
	acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power # * 0

	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
	acceleration -= drag_force

	if control_enabled:
		velocity += acceleration * delta
		navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom

		# tole je načeloma nepomembno
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		rotate(delta * rotation_angle)
		steering(delta)

		# smooth turning
		rotation = velocity.angle()

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()
	
	vision(delta)
	

func vision(delta):
	
	if control_enabled:
		
		# čekiraj ovire pred sabo
		vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost
		if vision_ray_front.is_colliding():
			velocity *= idle_brake_force
		
		# večno iskanje tarče
		if seek_ray.is_colliding() and seek_ray.get_collider().is_in_group(Config.group_bolts):
			var collider = seek_ray.get_collider()
			target_location = collider.global_position
			if collider.velocity.length() < target_speed_slow:
				rotation = (target_location - global_position).angle() # kot vektorja AB = B - A
#				look_at(target_location)
			seek_ray.look_at(target_location)
			battle(collider)
			bolt_sprite.modulate = Color.red
			
		else:
			idle() # vklopi idle režim
			bolt_sprite.modulate = bolt_color
			seek_ray.rotation += seek_rotation_speed * delta
			if seek_ray.get_rotation_degrees() > seek_rotation_range or seek_ray.get_rotation_degrees() < - seek_rotation_range:
				seek_rotation_speed *= -1
				
	# reset vision ray
	elif not control_enabled:
		seek_ray.rotation = 0

	
func idle():
	
	engine_power = engine_power_idle
	
	var idle_target_cell: Vector2 = global_position # določena pozicija prve random celice
	var idle_area: Array = []
	
	if not idle_target_set: # ta pogoj moram met, če ne vsak frejm išče novo tarčo (ne morem preverit, ker ne vidim linije)
		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
					if distance_to_cell < idle_target_max_distance: #and distance_to_cell > 150:
						idle_area.append(cell_position)
			# random celica je target 
			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				idle_target_cell = idle_area[randi() % idle_area.size() - 1]

			target_location = idle_target_cell # boltova tarča je random tarča
			idle_target_set = true
	else:
		# ko se pot izteče, gremo še enkrat iskat tarčo
		var current_path_size = navigation_agent.get_nav_path().size()
		if current_path_size < 5:
			idle_target_set = false
		
	shocker_check() # a postavlja mine v idle modetu?


func battle(target_body):
	
	var distance_to_target: float = navigation_agent.distance_to_target()
	var target_speed: float = target_body.velocity.length()
	
	if target_speed < target_speed_slow:
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		engine_power = lerp(engine_power, 0, 0.1)
	else:
		engine_power = engine_power_battle
		
	shooting("bullet")
	
	# razdalja večja od dosega rakete
	if distance_to_target >= max_attacking_distance:
		# bremzaj, če je tarča počasna
#		shooting("bullet")
		pass
#	# razdalja manjša od dosega rakete in večja od minimalne bližine
#	elif distance_to_target > min_attacking_distance:
##		modulate = Color.red
#		# bremzaj, če je tarča počasna
#		if target_speed < target_slow_speed:
#			velocity = lerp(velocity, Vector2.ZERO, 0.1)
#		# streljaj raketo, če je v coni za raketo in raketo ima
#		if distance_to_target > mid_attacking_distance: # and misile_count > 0:
##			yield(get_tree().create_timer(aim_time), "timeout")
#			shooting("misile")
#			yield(get_tree().create_timer(2*aim_time), "timeout")
#		# streljaj metk, če ni v coni za raketo in raketo ima
#		else:
#			# da ni istočasno z raketo ... se na pozna na hitrosti streljanja
#			# na vsakem metku je aim_time zamik, med sabo pa so zamaknjeni za reload time
#			yield(get_tree().create_timer(aim_time), "timeout")
#			shooting("bullet")
#	# razdalja manjša od minimalne bližine
#	elif distance_to_target <= min_attacking_distance:
#		velocity = lerp(velocity, Vector2.ZERO, 0.1)
#		engine_power = 0 # majhen vpliv na vse skupaj ... prepreči pa kakšen čuden karambol
##		modulate = Color.turquoise
##		shooting("bullet")
	
#	engine_power = engine_power_battle
	
	shocker_check() # čekiraj razmere za mino


func shocker_check():
	
	if vision_ray_left.is_colliding() and vision_ray_right.is_colliding():
		var collider_left = vision_ray_left.get_collider()
		var collider_right = vision_ray_right.get_collider()
		# če je v prišel v ožino in še ni odvrgel mine v trenutni ožini
		if collider_left.is_in_group(Config.group_arena) and collider_right.is_in_group(Config.group_arena):
			if not shocker_released:
				shocker_released = true # pomembno, da je pred tajmerjem
				yield(get_tree().create_timer(shocker_delay_time), "timeout") # tajming da ne dropne čist na začetku ožine
				shooting("shocker")
	# če je šel iz ožine ... ta del bi bil lahko bolj specifičen kaj je ožina
	else:
		shocker_released = false
		
	# če ma plejerja na riti
	if vision_ray_rear.is_colliding() and vision_ray_rear.get_collider().is_in_group(Config.group_bolts):
		shooting("shocker")
		shocker_released = true
	

func set_target_location (target: Vector2):
	target_reached = false
	navigation_agent.set_target_location(target)


func _on_NavigationAgent2D_path_changed() -> void:
	emit_signal("path_changed_faktoriran", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja
	
