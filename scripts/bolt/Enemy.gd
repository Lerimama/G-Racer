extends KinematicBody2D


# premaknjeno v Signals
#signal path_changed (path) # pošlje array pozicij
# signal target_reached # trenutno ni v uporabi

# player data
var player_name: String = "Enemy"
var player_color: Color = Color.antiquewhite

var health: int = 5
var life: int = 3
var hit_push_factor: float = 0.02 # kako močen je potisk metka ... delež hitrosti metka

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

# states
var power_fwd: bool
var power_rev: bool
var no_power: bool

export var control_enabled: bool = true
var control_disabled_color: Color = Config.color_gray0

# features
var bullet_reloaded: bool = true
var bullet_reload_time: float = 1.0
var misile_reloaded: bool = true
var misile_reload_time: float = 1.0
var misile_count = 2
var shocker_reloaded: bool = true
var shocker_reload_time: float = 1.0
var shocker_count = 3
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
onready var vision_ray_distance: float = get_viewport_rect().size.x * 0.7 # dolžina v smeri lokal x ... onready, ker še ni viewporta
export var collision_ray_L_cast: Vector2 = Vector2(10, -40)
export var collision_ray_R_cast: Vector2 = Vector2(10, 40)


# battle_mode
var locked_on_target: bool
var target_reached: bool
var target_location: Vector2

# idle_mode
onready var navigation_cells: Array # sek
export var brakes_strenght: float = 0.95
var idle_direction_set: bool # =  false

# shooting logic
export var shoot_bullet_distance: float = 200
export var shoot_misile_distance: float = 400 # usklajeno z dometom misile
var shocker_deep_time: float = 1.5
var shocker_dropped: bool # da ne zmeče vse naenkrat

# time vars
var time: float = 0
var aim_time: float = 5 # čas od opažanja do streljanja
var break_time: float = 1.0 # čas ustavlčjanja ob zaznanju tarče

var target_presssed: bool # _temp ... za klikanje z miško

# ---------------------------------------------------------------------------------------

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer

# AI
onready var navigation_agent = $NavigationAgent2D
onready var vision_ray = $VisionRay
onready var collision_ray = $CollisionRay
onready var collision_ray_L = $CollisionRayL
onready var collision_ray_R = $CollisionRayR

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn") # trianguliran razpad bolta
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")

var idle_mode# = true
var battle_mode# = false


func _ready() -> void:
	
	idle_mode = true
	randomize()
	
	add_to_group(Config.group_enemies)
	add_to_group(Config.group_bolts)
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
#	vision_ray.set_as_toplevel(true)
	ray_rotation_start = rotation
	vision_ray.cast_to.x = vision_ray_distance


func state_machine(delta):
	
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
		
		
func _physics_process(delta: float) -> void:
	
	time += delta
	state_machine(delta)
	
	if Input.is_mouse_button_pressed(1):
		set_target_location(get_global_mouse_position())
		target_presssed = true
	else:		
		set_target_location(target_location) # tukaj setamo target reached na false
	
	if battle_mode:
		acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	elif idle_mode: 
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
#	if motion_enabled:
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
	
	

func vision(delta):
	
	if idle_mode:
		# obračanje pogleda
		vision_ray.rotation += ray_rotation_speed * delta
		
		# določanje razpona
		if vision_ray.get_rotation_degrees() > ray_rotation_range or vision_ray.get_rotation_degrees() < -ray_rotation_range: 
			ray_rotation_speed *= -1
		
		# target found
		if vision_ray.is_colliding(): 
			var collider = vision_ray.get_collider()
			if collider.is_in_group("Bolts"):# and locked_on_target == true:
				target_location = collider.global_position
				vision_ray.look_at(target_location) # ray zaklenemo na tarčo
				battle_mode = true
				battle(collider)
			else:
				battle_mode = false 
				set_idle_target() # nima tarče in v tem trenutku tudi ne idle smeri
#	elif battle_mode:
#		vision_ray.look_at(target_location)
	
	
func set_idle_target():
	
	if idle_direction_set:
		idle_direction_set = false 
		pass
	else:
		var random_target_cell: Vector2 = global_position# - Vector2(100,-200) # določena pozicija prve celice
		var idle_area: Array
		var idle_vision_angle: float = 60  # plus in minus
		var random_target_max_distance = 200
		
		# tileti na voljo		
		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
					if distance_to_cell < random_target_max_distance: #and distance_to_cell > 150:
						idle_area.append(cell_position)
			# random travel celica 
			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				random_target_cell = idle_area[randi() % idle_area.size()]
			
		idle_direction_set = true # smer je zdaj določena

		# ko se pot izteče, gremo še enkrat iskat tarčo
		var current_path_size = navigation_agent.get_nav_path().size()
		if current_path_size < 5:
			target_location = random_target_cell # boltova tarča je random tarča
			set_idle_target()
			
	detect_walls_for_shocker() # v idle modu jih postavlja?	
	
	
func battle(bolt):
	
	var distance_to_target: float = navigation_agent.distance_to_target()
	
	# če je v dosegu misile	in jih sploh ima
	if distance_to_target <= shoot_misile_distance and misile_count > 0:
		# bremzaj, če je tarča pri miru 
		if bolt.velocity.length() < 15: 
			var tween = get_tree().create_tween()
			tween.tween_property(self, "velocity", Vector2.ZERO, break_time)
			if velocity.length() < 10: # da ne bo neskončno računal pozicije
				velocity = Vector2.ZERO
			
		if time > aim_time: 
			shooting("misile")
				
	elif distance_to_target < shoot_misile_distance and distance_to_target > shoot_bullet_distance:	
			yield(get_tree().create_timer(aim_time), "timeout") # da ni skoraj istočasno z misilo
			shooting("bullet")

	# če je v dosegu metka
	elif distance_to_target < shoot_bullet_distance:
		# bremzaj, če je tarča pri miru 
		if bolt.velocity.length() < 15: 
			var break_tween = get_tree().create_tween()
			break_tween.tween_property(self, "velocity", Vector2.ZERO, break_time)
			if velocity.length() < 10: # da ne bo neskončno računal pozicije
				velocity = Vector2.ZERO
			
		if time > aim_time: 	
			shooting("bullet")
	
	# če je v ožini
	detect_walls_for_shocker()	

	
func detect_walls_for_shocker():
	
	collision_ray_L.cast_to = collision_ray_L_cast
	collision_ray_R.cast_to = collision_ray_R_cast
#	collision_ray_L.cast_to.y = side_distance_to_wall 
#	collision_ray_R.cast_to.y = -side_distance_to_wall 
	
	if collision_ray_L.is_colliding() and collision_ray_R.is_colliding():
		
		var collider_L = collision_ray_L.get_collider()
		var collider_R = collision_ray_R.get_collider()
		var edge_group = Config.group_arena
		
		# če je v prišel v ožino
		if collider_L.is_in_group(edge_group) and collider_R.is_in_group(edge_group) and not shocker_dropped:
				shocker_dropped = true # pomembno, da je pred tajmerjem
				yield(get_tree().create_timer(shocker_deep_time), "timeout") # tajming da ne dropne čist na začetku ožine
				shooting("shocker")
	# če je šel iz ožine ... ta del bi bil lahko bolj specifičen kaj je ožina
	else:
		shocker_dropped = false
	
	
func shooting(weapon) -> void:
	
	if control_enabled:
		match weapon:
			"bullet": 
				if bullet_reloaded:
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
				if misile_reloaded and misile_count > 0:	
					var new_misile = Misile.instance()
					new_misile.position = $Bolt/GunPosition.global_position
					new_misile.rotation = $Bolt/GunPosition.global_rotation
					new_misile.spawned_by = name # ime avtorja izstrelka
					new_misile.spawned_by_color = player_color
					new_misile.spawned_by_speed = velocity.length()
					Global.node_creation_parent.add_child(new_misile)
					
					Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
					misile_reloaded = false
					misile_count -= 1
					
			"shocker": 
				if shocker_reloaded and shocker_count > 0:	
					var new_shocker = Shocker.instance()
					new_shocker.rotation = $Bolt/RearEnginePosition.global_rotation
					new_shocker.global_position = $Bolt/RearEnginePosition.global_position
					new_shocker.spawned_by = name # ime avtorja izstrelka
					new_shocker.spawned_by_color = player_color
					Global.effects_creation_layer.add_child(new_shocker)

					shocker_reloaded = false
					yield(get_tree().create_timer(misile_reload_time), "timeout")
					shocker_reloaded= true	


func on_misile_destroyed(): # iz signala
	misile_reloaded= true	
	
				
func activate_shield():	
	# shield		
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


func explode_and_reset(): # _temp

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
	
	if not shields_on:
		
		if collision_object.is_in_group(Config.group_bullets):
			health -= collision_object.hit_damage
			velocity = collision_object.velocity * hit_push_factor
			# blink efekt ... more bit na koncu zaradi tajmerja
			modulate = Color.black
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 
			
			if health <= 0:
				die()
			
			# mini pobeg
#			duck_move()
#			set_target_location (target: Vector2):
			
		elif collision_object.is_in_group(Config.group_misiles):
			die()
	
		elif collision_object.is_in_group(Config.group_shockers):
			
			if control_enabled == true: # catch
				
				control_enabled = false
				
				var catch_tween = get_tree().create_tween()
				catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
				catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
				catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
				
				bolt_sprite.material.set_shader_param("noise_factor", 2.0)
				bolt_sprite.material.set_shader_param("speed", 0.7)
					
				yield(get_tree().create_timer(collision_object.shock_time), "timeout")
				
				control_enabled = true
				
				var relase_tween = get_tree().create_tween()
				relase_tween.tween_property(self, "engine_power", 200, 0.1)
				relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
				bolt_sprite.material.set_shader_param("noise_factor", 0.0)
				bolt_sprite.material.set_shader_param("speed", 0.0)



var duck_distance
var duck_speed
#idle_direction_set
var duck_direction_set =  false

func duck_move(): # ko je zadet se umakne na stran

	var dir_left = collision_ray_L.get_cast_to()
	var dir_right = collision_ray_R.get_cast_to()
	var dir_target = target_location
	var dir =  target_location + dir_right

	var duck_direction: Vector2
##
##	if collision_ray_L.is_colliding() and collision_ray_R.is_colliding():
##		duck_direction = target_location
###		collision_ray_R.cast_to = duck_direction
##		print("nazaj")
##	elif collision_ray_R.is_colliding():
##		duck_direction = collision_ray_L.get_cast_to()
###		collision_ray_R.cast_to = duck_direction
##		print("levo")
##	elif collision_ray_L.is_colliding():
##		duck_direction = collision_ray_R.get_cast_to()
###		collision_ray_R.cast_to = duck_direction
##		print("desno")
##	else:
##		print("še enkrat nazaj")
###		collision_ray_R.cast_to = duck_direction
##		duck_direction = target_location
#
#
###		rotate(duck_direction)
###		velocity = duck_direction	
##		velocity = Vector2.ONE	
###		transform.x = 
##		print("ne vem")
##		print(duck_direction)
##		print(velocity)
##		print(velocity.length())
#
##	vision_ray.look_at(target_location)
#
#	engine_power = 200
#	velocity = duck_direction
##	var break_tween = get_tree().create_tween()
##	break_tween.tween_property(self, "velocity", duck_direction, 1)
##	look_at(duck_direction)
#	print (duck_direction)
#	print (velocity)
	
	
	
	
	# new target?
	if duck_direction_set:
		duck_direction_set = false 
	else:
		var random_target_cell: Vector2 # = global_position
		var duck_area: Array
		var duck_vision_angle: float = 60  # plus in minus
		var duck_max_distance = 200

		# tileti podna		
		if not navigation_cells.empty(): # napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - duck_vision_angle and angle_to_cell < duck_vision_angle:
					if distance_to_cell < duck_max_distance:
						duck_area.append(cell_position)
			# random duck celica 
			if duck_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				random_target_cell = duck_area[randi() % duck_area.size()]

		print(duck_area.size())	
		duck_direction_set = true # smer je zdaj določena
		
	

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
	print("target")


func _on_NavigationAgent2D_path_changed() -> void:
	
#	emit_signal("path_changed", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja
	Signals.emit_signal("path_changed", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja


func _on_shield_animation_finished(anim_name: String) -> void:
	
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




			
#func _on_NavigationAgent2D_velocity_computed(safe_velocity: Vector2, delta) -> void:
#
#	# moved from phys process + safe_velocity
#	if not arrived_at_location():
#		collision = move_and_collide(safe_velocity * delta, false) # infinite_inertia = false
#	elif not target_reached: # če je prišel na lokacijo in je has arrived false
#		target_reached = true
#		emit_signal("path_changed", []) # pošljemo prazen array, tako se linija sprazne
#		emit_signal("target_reached")



#var duck_distance
#var duck_speed
##idle_direction_set
#var duck_direction_set =  false

#func duck_move(): # ko je zadet se umakne na stran
#
#	var dir_left = collision_ray_L.get_cast_to()
#	var dir_right = collision_ray_R.get_cast_to()
#	var dir_target = target_location
#	var dir =  target_location + dir_right
#
#	var duck_direction: Vector2
##
##	if collision_ray_L.is_colliding() and collision_ray_R.is_colliding():
##		duck_direction = target_location
###		collision_ray_R.cast_to = duck_direction
##		print("nazaj")
##	elif collision_ray_R.is_colliding():
##		duck_direction = collision_ray_L.get_cast_to()
###		collision_ray_R.cast_to = duck_direction
##		print("levo")
##	elif collision_ray_L.is_colliding():
##		duck_direction = collision_ray_R.get_cast_to()
###		collision_ray_R.cast_to = duck_direction
##		print("desno")
##	else:
##		print("še enkrat nazaj")
###		collision_ray_R.cast_to = duck_direction
##		duck_direction = target_location
#
#
###		rotate(duck_direction)
###		velocity = duck_direction	
##		velocity = Vector2.ONE	
###		transform.x = 
##		print("ne vem")
##		print(duck_direction)
##		print(velocity)
##		print(velocity.length())
#
##	vision_ray.look_at(target_location)
#
#	engine_power = 200
#	velocity = duck_direction
##	var break_tween = get_tree().create_tween()
##	break_tween.tween_property(self, "velocity", duck_direction, 1)
##	look_at(duck_direction)
#	print (duck_direction)
#	print (velocity)
	
	
	
	
	# new target?
#	if duck_direction_set:
#		duck_direction_set = false 
#	else:
#		var random_target_cell: Vector2 # = global_position
#		var duck_area: Array
#		var duck_vision_angle: float = 60  # plus in minus
#		var duck_max_distance = 200
#
#		# tileti podna		
#		if not navigation_cells.empty(): # napolne se ob nalaganju enemija
#			for cell_position in navigation_cells:
#				# če je polju dosega
#				var distance_to_cell: float = global_position.distance_to(cell_position)
#				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
#				if angle_to_cell > - duck_vision_angle and angle_to_cell < duck_vision_angle:
#					if distance_to_cell < duck_max_distance:
#						duck_area.append(cell_position)
#			# random duck celica 
#			if duck_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
#				random_target_cell = duck_area[randi() % duck_area.size()]
#
#		print(duck_area.size())	
#		duck_direction_set = true # smer je zdaj določena
		
	
