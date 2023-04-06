extends KinematicBody2D


signal path_changed (path) # pošlje array pozicij
#signal target_reached # trenutno ni v uporabi

# player data
var player_name: String = "Enemy"
var player_color: Color = Color.antiquewhite
var health: int = 5
var life: int = 3

# bolt data
export var axis_distance: int = 9
export var engine_power: float = 200
export var engine_power_idle: float = 50
export var top_speed_reverse: float = 50
export var turn_angle: float = 10 # deg per frame
export var rotation_multiplier: float = 15 # rotacija kadar miruje
export (float, 0, 10) var drag: float = 1.0 # raste kvadratno s hitrostjo
export (float, 0, 1) var side_traction: float = 0.1
export (float, 0, 1) var bounce_size: float = 0.3

var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D

var power_fwd: bool
var power_rev: bool
var no_power: bool
var motion_enabled: bool = true

var bullet_reloaded: bool = true
var bullet_reload_time: float = 1.0
var misile_reloaded: bool = true
var misile_reload_time: float = 1.0
var hit_push_factor: float = 0.02 # kako močen je potisk metka ... delež hitrosti metka

var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 3

var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni , potem je "odklopljena"
var new_bolt_trail: Object


# AI ------------------------------------------------------------------------
 
# vision
var ray_rotation_range = 60 # (+ ray_rotation_range <> - ray_rotation_range)
var ray_rotation_speed = 3.0
var ray_rotation_start: float

# following
var locked_on_target: bool
var target_reached: bool
var target_location: Vector2

# idle
var idle_time_range: Array = [5, 10] # sek
onready var navigation_cells: Array # sek
onready var vision_ray_distance: float = get_viewport_rect().size.x * 0.7 # dolžina v smeri lokal x ... onready, ker še ni viewporta
var idle_direction_set: bool # =  false

# šuting
export var shooting_distance: float = 200

# ---------------------------------------------------------------------------------------

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var navigation_agent = $NavigationAgent2D
onready var vision_ray = $VisionRay
onready var collision_ray = $CollisionRay

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn") # trianguliran razpad bolta
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")

var aim_speed = 0.05
export var brakes_strenght: float = 0.95


func _ready() -> void:
	
	randomize()
	
	add_to_group("Enemies")
	add_to_group("Bolts")
	name = player_name # lahko da mora bit ugasnjeno zaradi nekega erorja
	bolt_sprite.modulate = player_color
	bolt_collision.disabled = false
	
	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield.self_modulate = player_color 
	shield_collision.disabled = true 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)
	
	# raycast
	ray_rotation_start = rotation
	vision_ray.cast_to.x = vision_ray_distance


func _physics_process(delta: float) -> void:
	
	# motion states
	if velocity.length() > 0:
		power_fwd = true
		power_rev = false
		no_power = false
	elif velocity.length() < 0:
		power_rev = true
		power_fwd = false
		no_power = false
	elif velocity.length() == 0:
		no_power = true
		power_fwd = false
		power_rev = false
	
	if Input.is_mouse_button_pressed(1):
		set_target_location(get_global_mouse_position())
		target_presssed = true
	else:		
		set_target_location(target_location) # tukaj setamo target reached na false
	
	if locked_on_target:
		acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	else: 
		acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power_idle # * 0
	
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
	acceleration -= drag_force
	velocity += acceleration * delta
	
	navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom
	
	# tole je načeloma nepomembno
	rotation_angle = rotation_dir * deg2rad(turn_angle)
	rotate(delta * rotation_angle)
	steering(delta)

	# smooth turning
	rotation = velocity.angle()
	
	# bremzanje pred oviro
	collision_ray.set_cast_to(Vector2(velocity.length(), 0))
	if collision_ray.is_colliding():
		velocity *= brakes_strenght
		engine_particles_rear.modulate.a = 0
	else:
		engine_particles_rear.modulate.a = 1
	
	# ko je navigacija končana
	if navigation_agent.is_navigation_finished():
		target_reached = true
		emit_signal("path_changed", []) # pošljemo prazen array, tako se linija sprazne
		# emit_signal("target_reached")	
	else:
		collision = move_and_collide(velocity * delta, false)
	
	if collision:
		on_collision()
	
	vision(delta)
	motion_effects(delta)
	shield.rotation = -rotation


func vision(delta):
	
	vision_ray.rotation += ray_rotation_speed * delta
	if vision_ray.get_rotation_degrees() > ray_rotation_range or vision_ray.get_rotation_degrees() < -ray_rotation_range: 
		ray_rotation_speed *= -1
	
	# locked on target
	if vision_ray.is_colliding(): 
		
		var collider = vision_ray.get_collider()
		
		if collider.is_in_group("Bolts") and locked_on_target != true:
			locked_on_target = true
			rotation_degrees =  lerp(rotation_degrees,rad2deg(get_angle_to(target_location)),aim_speed)

		if collider.is_in_group("Bolts") and locked_on_target == true:
			target_location = collider.global_position
			vision_ray.look_at(collider.global_position)

			# if target not moving
			if collider.velocity.length() < 5:
				velocity *= 0.4
				if velocity.length() < 5: # da ne bo neskončno računal pozicije
					velocity = Vector2.ZERO 	
				print(collider.velocity.length())
				print(velocity.length())
#			vision_ray.rotation = 0.0
			shooting("misile")

			# if target moving
			
			
			
		else:
			locked_on_target = false 
			set_random_target() # nima tarče in v tem trenutku tudi ne idle smeri
	
	var distance = navigation_agent.distance_to_target()

func on_ray_colliding(collider, ray):
	
#	if collider.is_in_group("Bolts"):
#		ray.look_at(collider.global_position)
	
	if collider.is_in_group("Bolts") and locked_on_target != true:
		locked_on_target = true
		rotation_degrees = lerp(rotation_degrees,rad2deg(get_angle_to(target_location)),aim_speed)

	if collider.is_in_group("Bolts") and locked_on_target == true:
		target_location = collider.global_position
		vision_ray.look_at(collider.global_position)

		# if target not moving
		if collider.velocity.length() < 5:
			velocity *= 0.4
			if velocity.length() < 5: # da ne bo neskončno računal pozicije
				velocity = Vector2.ZERO 	
#			vision_ray.rotation = 0.0
		shooting("misile")

		# if target moving
	else:
		locked_on_target = false 
#		set_random_target() # nima tarče in v tem trenutku tudi ne idle smeri
	
	
func set_random_target(): # sproži se ob štartu in vsakič ko poteče ena smer
	
	var current_potka_size = navigation_agent.get_nav_path().size()
	
	if idle_direction_set:
		idle_direction_set = false 
	else:
		var target_cell: Vector2 = global_position# - Vector2(100,-200) # določena pozicija prve celice
		var idle_area: Array
		var idle_vision_angle: float = 60  # plus in minus
		var random_target_max_distance = 200
		
		# tileti na voljo		
		if not navigation_cells.empty(): # v prvem poskus je area prazen
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
					if distance_to_cell < random_target_max_distance: #and distance_to_cell > 150:
						idle_area.append(cell_position)
			# random travel celica 
			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				target_cell = idle_area[randi() % idle_area.size()]
			
		idle_direction_set = true # smer je zdaj določena

		# ko se pot izteče
		var current_path_size = navigation_agent.get_nav_path().size()
		if current_path_size < 5:
			target_location = target_cell
			set_random_target()
			

func on_collision():
	
	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	
	# odbojni partikli
	if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = velocity.length()/15 # količnik je korektor	
		new_collision_particles.color = player_color
		new_collision_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_collision_particles)
		
		
func motion_effects(delta) -> void:

	if power_fwd:
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.position = $Bolt/RearEnginePosition.global_position
		engine_particles_rear.rotation = $Bolt/RearEnginePosition.global_rotation
		
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	if power_rev:
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.position = $Bolt/FrontEnginePositionL.global_position
		engine_particles_front_left.rotation = $Bolt/FrontEnginePositionL.global_rotation - deg2rad(180)
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.position = $Bolt/FrontEnginePositionR.global_position
		engine_particles_front_right.rotation = $Bolt/FrontEnginePositionR.global_rotation - deg2rad(180)	
		
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# add trail points
	if bolt_trail_active == true:
		if velocity.length() > 0:
			new_bolt_trail.gradient.colors[1] = player_color
			new_bolt_trail.add_points(global_position)
		elif velocity.length() == 0 and no_power: # "input" je, da izločim za hitre prehode med naprej nazaj
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena	
	
	
func shooting(weapon) -> void:
	
	if navigation_agent.distance_to_target() < shooting_distance:
		match weapon:
			"bullet": 
				if bullet_reloaded == true:
					var new_bullet = Bullet.instance()
					new_bullet.position = $Bolt/GunPosition.global_position
					new_bullet.rotation = $Bolt/GunPosition.global_rotation
					new_bullet.spawned_by = name # ime avtorja izstrelka
					new_bullet.spawned_by_color = player_color
					Global.node_creation_parent.add_child(new_bullet)
					
					bullet_reloaded = false
					yield(get_tree().create_timer(bullet_reload_time), "timeout")
					bullet_reloaded= true		
			"misile": 
				if misile_reloaded == true:	
					var new_misile = Misile.instance()
					new_misile.position = $Bolt/GunPosition.global_position
					new_misile.rotation = $Bolt/GunPosition.global_rotation
					new_misile.spawned_by = name # ime avtorja izstrelka
					new_misile.spawned_by_color = player_color
					new_misile.spawned_by_speed = velocity.length()
					Global.node_creation_parent.add_child(new_misile)
					
					misile_reloaded = false
					yield(get_tree().create_timer(misile_reload_time), "timeout")
					misile_reloaded= true	
			"shocker": 
				if bullet_reloaded == true:	
					var new_shocker = Shocker.instance()
					new_shocker.rotation = $Bolt/RearEnginePosition.global_rotation
					new_shocker.global_position = $Bolt/RearEnginePosition.global_position
					new_shocker.spawned_by = name # ime avtorja izstrelka
					new_shocker.spawned_by_color = player_color
					Global.effects_creation_layer.add_child(new_shocker)

					misile_reloaded = false
					yield(get_tree().create_timer(misile_reload_time), "timeout")
					misile_reloaded= true	
				
		
	# shield		
	if Input.is_action_just_pressed("shift"):
		
		if shields_on == false:
			shield.modulate.a = 1
			animation_player.play("shield_on")
			shields_on = true
			bolt_collision.disabled = true
			shield_collision.disabled = false
		else:
			animation_player.play_backwards("shield_on")
			# shields_on = false # premaknjeno dol na konec animacije
			# collisions setup premaknjeno dol na konec animacije
			shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja
			
	# test explozije
	if Input.is_action_just_pressed("x"):
#		die()
		explode_and_reset()
		

func steering(delta: float) -> void:
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	if power_fwd:
		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	elif power_rev:
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), top_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri

			
func engines_setup():
	
	engine_particles_rear = EngineParticles.instance()
	engine_particles_rear.position = $Bolt/RearEnginePosition.global_position
	engine_particles_rear.rotation = $Bolt/RearEnginePosition.global_rotation
	Global.effects_creation_parent.add_child(engine_particles_rear)
	
	engine_particles_front_left = EngineParticles.instance()
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	engine_particles_front_left.position = $Bolt/FrontEnginePositionL.global_position
	engine_particles_front_left.rotation = $Bolt/FrontEnginePositionL.global_rotation - deg2rad(180)
	Global.effects_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	engine_particles_front_right.position = $Bolt/FrontEnginePositionR.global_position
	engine_particles_front_right.rotation = $Bolt/FrontEnginePositionR.global_rotation - deg2rad(180)	
	Global.effects_creation_parent.add_child(engine_particles_front_right)


func explode_and_reset():

	if visible == true:
		var new_exploding_bolt = ExplodingBolt.instance()
		new_exploding_bolt.global_position = global_position
		new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
		new_exploding_bolt.spawned_by_color = player_color
		new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
		Global.node_creation_parent.add_child(new_exploding_bolt)
		visible = false
	else:
		visible = true
	
	
func on_hit(collision_object: Node):
	
	if shields_on != true:
		
		if collision_object.is_in_group("Bullets"):
			health -= 1
			velocity = collision_object.velocity * hit_push_factor
			# blink efekt ... more bit na koncu zaradi tajmerja
			modulate = Color.black
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 
			if health <= 0:
				die()
				
		elif collision_object.is_in_group("Misiles"):
			die()
	
		elif collision_object.is_in_group("Shockers"):
			if motion_enabled == true: # catch
				motion_enabled = false
				velocity = lerp(velocity, Vector2.ZERO, 0.8)
				bolt_sprite.material.set_shader_param("noise_factor", 2.0)
				bolt_sprite.material.set_shader_param("speed", 0.7)
				
				var modulate_tween = get_tree().create_tween()
				modulate_tween.tween_property(bolt_sprite, "modulate", Color.white, 0.5)
				
			elif motion_enabled != true: # release
				motion_enabled = true
				bolt_sprite.material.set_shader_param("noise_factor", 0.0)
				bolt_sprite.material.set_shader_param("speed", 0.0)
				
				var modulate_tween = get_tree().create_tween()
				modulate_tween.tween_property(bolt_sprite, "modulate", player_color, 0.5)		


func die():
	
	# najprej explodiraj 
	# potem ugasni sprite in coll 
	# potem ugasni motor in štartaj trail decay
	# explozijo izključi ko grejo partikli ven
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate = modulate
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	Global.node_creation_parent.add_child(new_exploding_bolt)
	queue_free()		


func set_target_location (target: Vector2):
	target_reached = false
	navigation_agent.set_target_location(target)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	shield_loops_counter += 1
	
	match anim_name:
		"shield_on":	
			# končan outro ... resetiramo lupe in ustavimo animacijo
			if shield_loops_counter > shield_loops_limit:
				animation_player.stop(false) # včasih sem rabil, da se ne cikla, zdaj pa je okej, ker ob
				shield_loops_counter = 0
				shields_on = false
				bolt_collision.disabled = false
				shield_collision.disabled = true
			# končan intro ... zaženi prvi loop
			else:
				animation_player.play("shielding")
		"shielding":
			# dokler je loop manjši od limita ... replayamo animacijo
			if shield_loops_counter < shield_loops_limit:
				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
			# konec loopa, ko je limit dosežen
			elif shield_loops_counter >= shield_loops_limit:
				animation_player.play_backwards("shield_on")

var target_presssed: bool

onready var Poli = preload("res://poli.tscn")

func _on_NavigationAgent2D_path_changed() -> void:
	
	emit_signal("path_changed", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja


#func edit_motion(nav_points):
#
#
#	if nav_points.size() > 10:
#		# določitev pik za preverjanje (0 je takoj pri boltu)
#		var prev_point = nav_points[2]
#		var corner_point = nav_points[3]
#		var next_point = nav_points[4]
#
#		# extra pike za držanje hitrosti
#		var next_point_2 = nav_points[5]
#		var next_point_3 = nav_points[6]
#		var next_point_4 = nav_points[7]
#
#		# preverjanje kota
#		var nav_point_index = 0
#
#		var points_vector_1: Vector2 = prev_point.direction_to(corner_point)
#		var points_vector_2: Vector2 = corner_point.direction_to(next_point)
#		var points_vector_angle: float = points_vector_1.angle_to(points_vector_2)
#
#		if abs(rad2deg(points_vector_angle)) > 60:
#			var new_poli = Poli.instance()
#			new_poli.global_position = corner_point
#			get_parent().add_child(new_poli)
##			print (velocity.normalized())
##			print (velocity)
#
#			# bremzanje
##			drag *= 2
##			velocity *= 0.93
##			var distance_to_corner = global_position.distance_to(corner_point)
#			velocity = velocity.linear_interpolate(Vector2.ZERO, 0.1)
#
#			var next_vector: Vector2 = global_position.direction_to(next_point_4)
#			var velocity_vector: Vector2 =  global_position.direction_to(velocity.normalized())
#
#			print(nav_points.find(next_point_4))
#			# preverjanje, če mimo kornerja
#			if nav_points.find(next_point_4) == -1: # problem jke tem da se indexi vseskozi obnavljajo
#				print ("ETOGA")
#				print (velocity)
#
#
#func draw_poli_path(path_points):
#
#		var poligons: Array
#		var sharp_angle_count = 0	
#
#		for point in path_points:
#			var new_poli = Poli.instance()
#			new_poli.global_position = point
#			get_parent().add_child(new_poli)
#			poligons.append(new_poli)
#
#		# iskanje prvih pik
#		var poli1 = poligons.front()
#		var poli2 = poligons[1]
#		var poli3 = poligons[2]
#		poli1.color = Color.turquoise
#		poli2.color = Color.turquoise
#		poli3.color = Color.turquoise
#
#		# iskanje pravega kota
#		var poligon_index = 0
#
#		for poligon in poligons:
#
#			poligon = poligons[poligon_index]
#
#			if poligon != poligons[poligons.size() -1 ]:
#
#				# trenutni poligon je vogalni poligon
#				var next_poligon = poligons[poligon_index + 1]
#				var prev_poligon = poligons[poligon_index - 1]
#				var polivec1: Vector2 = prev_poligon.global_position.direction_to(poligon.global_position)
#				var polivec2: Vector2 = poligon.global_position.direction_to(next_poligon.global_position)
#				var polivec_angle: float = polivec1.angle_to(polivec2)
#
#				# reakcija na pravi kot
#				if abs(rad2deg(polivec_angle)) > 60:
#					prev_poligon.color = Color.red
#					poligon.color = Color.blue
#					next_poligon.color = Color.yellow
#					poligon.queue_free()
#					sharp_angle_count += 1
##					print("poli")
##					print(sharp_angle_count)
#
##				print("VEK")
##				print(polivec_angle)	
##				print(rad2deg(polivec_angle))	
#			poligon_index += 1	
#
#
#func edit_path_with_remove(nav_points):
#
#		# iskanje prvih pik
#		var nav_point1 = nav_points[0]
#		var nav_point2 = nav_points[1]
#		var nav_point3 = nav_points[2]
#
#		# iskanje pravega kota
#		var nav_point_index = 0
#		var points_to_remove: Array
#
#		for point in nav_points:
#
#			point = nav_points[nav_point_index]
#			if point != nav_points[nav_points.size() - 1 ]:
#				# trenutni poligon je vogalni poligon
#				var next_point = nav_points[nav_point_index + 1]
#				var prev_point = nav_points[nav_point_index - 1]
#				var pointvec1: Vector2 = prev_point.direction_to(point)
#				var pointvec2: Vector2 = point.direction_to(next_point)
#				var pointvec_angle: float = pointvec1.angle_to(pointvec2)
#				# reakcija na pravi kot
#				if abs(rad2deg(pointvec_angle)) > 90:
##					nav_points.remove(nav_point_index) # javi error, ker potem ne more več štet ... dam spodaj
#					points_to_remove.append(point)
#			nav_point_index += 1	
#
#		# primerjava točk in odstranitev iz potke
#		var obs_point_index = 0
#		for point in nav_points:
#			for point_to_remove in points_to_remove:
#				if point == point_to_remove:
#					nav_points.remove(obs_point_index)
#					nav_points.remove(obs_point_index + 1)
#					nav_points.remove(obs_point_index - 1)
#					nav_points.remove(obs_point_index + 2)
#					nav_points.remove(obs_point_index - 2)
#					nav_points.remove(obs_point_index + 3)
#					nav_points.remove(obs_point_index - 3)
#			obs_point_index += 1		
#
#
#func edit_path_with_insert(nav_points):
#
#
#		# iskanje prvih pik
#		var nav_point1 = nav_points[0]
#		var nav_point2 = nav_points[1]
#		var nav_point3 = nav_points[2]
#
#		# iskanje pravega kota
#		var nav_point_index = 0
#		var points_to_remove: Array
#
#		for point in nav_points:
#
#			point = nav_points[nav_point_index]
#
#			if point != nav_points[nav_points.size() - 1 ]:
#
#				# trenutni poligon je vogalni poligon
#				var next_point = nav_points[nav_point_index + 1]
#				var prev_point = nav_points[nav_point_index - 1]
#				var pointvec1: Vector2 = prev_point.direction_to(point)
#				var pointvec2: Vector2 = point.direction_to(next_point)
#				var pointvec_angle: float = pointvec1.angle_to(pointvec2)
#				# reakcija na pravi kot
#				if abs(rad2deg(pointvec_angle)) > 90:
##					nav_points.remove(nav_point_index) # javi error, ker potem ne more več štet ... dam spodaj
#					points_to_remove.append(point)
#
#					nav_points.insert(nav_point_index -1 , point)
#					nav_points.insert(nav_point_index -1 , point)
#					nav_points.insert(nav_point_index -1 , point)
#					nav_points.insert(nav_point_index -1 , point)
#					nav_points.insert(nav_point_index -1 , point)
##					nav_points.insert(nav_point_index +1, point + Vector2(20,20))
##					nav_points.insert(nav_point_index + 2, point + Vector2(30,30))
#
#					print(nav_point_index)
##					print(nav_points.size())
#			nav_point_index += 1	
#
#
#		# primerjava točk in odstranitev iz potke
#		#
##		var obs_point_index = 0
##		for point in nav_points:
##			for point_to_remove in points_to_remove:
##				if point == point_to_remove:
##					nav_points.remove(obs_point_index)
##					nav_points.remove(obs_point_index + 1)
##					nav_points.remove(obs_point_index - 1)
##					nav_points.remove(obs_point_index + 2)
##					nav_points.remove(obs_point_index - 2)
##					nav_points.remove(obs_point_index + 3)
##					nav_points.remove(obs_point_index - 3)
##			obs_point_index += 1		
#
##		nav_points.remove(1)
##		nav_points.remove(2)
##		nav_points.remove(3)
##		nav_points.remove(4)
##		nav_points.remove(5)
##		nav_points.remove(6)
#
#
#
#		emit_signal("path_changed", nav_points) # pošljemo točke poti do cilja
			
#func _on_NavigationAgent2D_velocity_computed(safe_velocity: Vector2, delta) -> void:
#
#	# moved from phys process + safe_velocity
#	if not arrived_at_location():
#		collision = move_and_collide(safe_velocity * delta, false) # infinite_inertia = false
#	elif not target_reached: # če je prišel na lokacijo in je has arrived false
#		target_reached = true
#		emit_signal("path_changed", []) # pošljemo prazen array, tako se linija sprazne
#		emit_signal("target_reached")
