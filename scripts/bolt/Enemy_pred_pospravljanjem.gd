extends KinematicBody2D


# premaknjeno v Signals
#signal path_changed (path) # pošlje array pozicij
# signal target_reached # trenutno ni v uporabi

# player data
var player_name: String = "Enemy"
var player_color: Color = Color.antiquewhite

var health: int = 5
var life: int = 3
var hit_push_factor: float = 0.3 # kako močen je potisk metka ... delež hitrosti metka

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
var seek_rotation_range = 60 # (+ ray_rotation_range <> - ray_rotation_range)
var seek_rotation_speed = 2.0
var seek_start_rotation: float # za prenašanje
onready var seek_distance: float = get_viewport_rect().size.x * 0.7 # dolžina v smeri lokal x ... onready, ker še ni viewporta

# battle_mode
var locked_on_target: bool
var target_reached: bool
var target_location: Vector2
var target_slow_velocity = 20

# idle_mode
onready var navigation_cells: Array # sek
export var idle_brakes_force: float = 0.95
var idle_vision_angle: float = 45  # plus in minus
var idle_target_max_distance = 300

# shooting logic
export var min_attacking_distance: float = 100 # zadnja bremza ob napadu ... 
export var max_attacking_distance: float = 400 # prva bremza ob napadu ... usklajeno z dometom misile
var shocker_delay_time: float = 1.5

# ---------------------------------------------------------------------------------------

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

# AI
onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $VisionRay
onready var vision_ray_front = $VisionFront
onready var vision_ray_rear = $VisionRear # poz kot
onready var vision_ray_left = $VisionLeft # neg kot
onready var vision_ray_right = $VisionRight

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn") # trianguliran razpad bolta ... no more (opr. ur.)
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")
onready var poli = preload("res://poli.tscn")


# states
var power_fwd: bool
var power_rev: bool
var no_power: bool
var control_enabled: bool = true

var target_presssed: bool # _temp ... za klikanje z miško
var shocker_dropped: bool # da ne zmeče vse naenkrat

var duck_target_set =  false
var idle_target_set: bool # =  false
var idle_mode # = true
var battle_mode # = false

# time vars
var time: float = 0
var aim_time: float = 5 # čas od opažanja do streljanja
var break_time: float = 0.7 # čas ustavljanja ob zaznanju tarče



func _ready() -> void:
	
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
	
	# set raycast setup
	seek_start_rotation = rotation
	seek_ray.cast_to.x = seek_distance
#	vision_ray_left.cast_to = vision_ray_left_cast
#	vision_ray_right.cast_to = vision_ray_right_cast
#	vision_ray_rear.cast_to = vision_ray_rear_cast
	set_idle_target() # ob štartu pogleda naokrog in postane idle
	

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
	
	if not just_hit: 
		velocity += acceleration * delta
		navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom
	
		# tole je načeloma nepomembno
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		rotate(delta * rotation_angle)
		steering(delta)

		# smooth turning
		rotation = velocity.angle()
		
		# ko je navigacija končana
	#	if motion_enabled:
	#	if navigation_agent.is_navigation_finished():
	#		target_reached = true
	#		emit_signal("path_changed", []) # pošljemo prazen array, tako se linija sprazne
	#		# emit_signal("target_reached")	
	#	else:
	collision = move_and_collide(velocity * delta, false)
	
	if collision:
		on_collision()
	
	# ob spawnu ima idle_mode  in vision potem najde tarčo in opredeli battle_mode
	vision(delta)
	motion_fx()
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

		
func motion_fx() -> void:

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
	
	# ček spredaj
	vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost
	if vision_ray_front.is_colliding():
		velocity *= idle_brakes_force
		engine_particles_rear.modulate.a = 0
	else:
		engine_particles_rear.modulate.a = 1
		
	# seek
	if idle_mode:
		seek_ray.rotation += seek_rotation_speed * delta
		if seek_ray.get_rotation_degrees() > seek_rotation_range or seek_ray.get_rotation_degrees() < - seek_rotation_range: 
			seek_rotation_speed *= -1
		
	# ko vidi plejerja
	if seek_ray.is_colliding() and seek_ray.get_collider().is_in_group("Bolts"):
		if  duck_target_set != true:
			var collider = seek_ray.get_collider()
			
			target_location = collider.global_position
			seek_ray.look_at(target_location) # ray zaklenemo na tarčo
			battle(collider) # vklopi battle režim
	
	# dokler ne vidi plejerja
	else:
		set_idle_target() # vklopi idle režim

	
func set_idle_target():
	
	idle_mode = true
	battle_mode = false
	
	
#	if idle_target_set:
	if duck_target_set != true:
#		idle_target_set = false 
#	else:
#		var idle_target_cell: Vector2 = global_position # določena pozicija prve random celice
		var idle_target_cell: Vector2 = Vector2.ZERO # določena pozicija prve random celice
		var idle_area: Array
		
		# tileti na voljo		
		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
					if distance_to_cell < idle_target_max_distance: #and distance_to_cell > 150:
						idle_area.append(cell_position)
			# random travel celica 
			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				idle_target_cell = idle_area[randi() % idle_area.size() - 1]
			
		idle_target_set = true # smer je zdaj določena

		# ko se pot izteče, gremo še enkrat iskat tarčo
		var current_path_size = navigation_agent.get_nav_path().size()
		if current_path_size < 5:
			target_location = idle_target_cell # boltova tarča je random tarča
	#		set_idle_target()
			
	drop_shocker() # a postavlja mine v idel modetu?
	

func battle(battle_target):
	battle_mode = true
	idle_mode = false
	
	var distance_to_target: float = navigation_agent.distance_to_target()
	var battle_target_speed: float = battle_target.velocity.length()
	
	if duck_target_set != true:
		
		# približa se tarči na doseg misile (če tarča miruje)
		# ko poteče aim time strelja misile (reload timer)
		# ko ni misil, se še bolj približa tarči in strelja metke (reload timer)
		if battle_target_speed < target_slow_velocity:
			if distance_to_target < max_attacking_distance and misile_count > 0:
				hit_brakes()
				yield(get_tree().create_timer(1), "timeout")
	#			if battle_target_speed < 10:
	#				engine_power = 0
				shooting("misile")
			elif distance_to_target < max_attacking_distance and distance_to_target > min_attacking_distance:	
				yield(get_tree().create_timer(aim_time), "timeout") # da ni skoraj istočasno z misilo
				shooting("bullet")
			elif distance_to_target < min_attacking_distance:
	#			if battle_target_speed < target_slow_velocity: 
	#				var break_tween = get_tree().create_tween()
	#				break_tween.tween_property(self, "velocity", Vector2.ZERO, break_time)
				hit_brakes()
				yield(get_tree().create_timer(aim_time), "timeout") # da ni skoraj istočasno z misilo
				shooting("bullet")
	
	drop_shocker()	


func hit_brakes():
	var break_tween = get_tree().create_tween()
#	break_tween.parallel().tween_property(self, "engine_power", 0, break_time) # če ni tega potem se ne ustavi 100%
	break_tween.tween_property(self, "velocity", Vector2.ZERO, break_time)
	
	
func drop_shocker():
	
	
	if vision_ray_left.is_colliding() and vision_ray_right.is_colliding():

		var collider_left = vision_ray_left.get_collider()
		var collider_right = vision_ray_right.get_collider()

		# če je v prišel v ožino in še ni odvrgel mine v trenutni ožini
		if collider_left.is_in_group(Config.group_arena) and collider_right.is_in_group(Config.group_arena) and not shocker_dropped:
				shocker_dropped = true # pomembno, da je pred tajmerjem
				yield(get_tree().create_timer(shocker_delay_time), "timeout") # tajming da ne dropne čist na začetku ožine
				shooting("shocker")
	
	elif vision_ray_rear.is_colliding():
		if vision_ray_rear.get_collider().is_in_group(Config.group_bolts):
			shocker_dropped = true
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
				misile_reloaded = false
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
			
var just_hit: bool = false
var disabled_time: bool = false
var misile_push_factor = 0.5
		
func on_hit(collision_object: Node):
	
	if not shields_on:
		
		just_hit = true
		idle_target_set = false
		
		if collision_object.is_in_group(Config.group_bullets):
		# ko je zadet
		#	izgubi energijo
		# 	izgubi kontrolo
		#	utripne
		#	ga odnese
		# 	izgubi tarčo -> idle mode
		
			control_enabled = false
			velocity = collision_object.velocity * hit_push_factor
			health -= collision_object.hit_damage
			if health <= 0:
				die()
			modulate = Color.black
			yield(get_tree().create_timer(0.05), "timeout")
			yield(get_tree().create_timer(disabled_time), "timeout")
			modulate = Color.white 
			
			control_enabled = true
			just_hit = false
			duck_target_set = false
			set_idle_target()	
			
#			duck_move(collision_object.global_position)
			
		elif collision_object.is_in_group(Config.group_misiles):
			velocity = collision_object.velocity * misile_push_factor
#			vision_ray_rear.set_cast_to(velocity)
#			duck_move(collision_object.global_position)
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


func duck_move(hit_from):
	
	if duck_target_set:
		duck_target_set = false # zazihr
	
	# zabremza (break_time)
	# se obrne proti točki zadetka 
	# gre do točke zadetka
	# nadaljuje idle_mode
	if idle_mode:
		idle_target_set = false 
		target_location = hit_from
		hit_brakes()
		duck_target_set = true
		
		print ("tole bi moral avtomatizirat")
		yield(get_tree().create_timer(1), "timeout") # pavza
		duck_target_set = false
		set_idle_target()
	
	
	# bremzaj (break_time)
	# ostane usmerjen na plejerja?
	# če ma ščit ga vklopi
	# vision je usmerjen na plejerja
	# odpelje random duck target
	elif battle_mode:
		
		seek_ray.look_at(target_location)	
		duck_target_set = false
#		
		# NAV TARGET DIR
		
		var duck_area: Array
		
		var left_angle: float = rad2deg(vision_ray_left.get_cast_to().angle())
		var right_angle: float = rad2deg(vision_ray_right.get_cast_to().angle())
		var rear_angle: float = rad2deg(vision_ray_rear.get_cast_to().angle())
		
		var angle_range: float = 40
		var duck_min_distance = 30
		var duck_max_distance = 40
		var duck_speed_factor = 70
		
		# celice na voljo		
		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
			
				# ček room for duck
				if distance_to_cell > duck_min_distance and distance_to_cell < duck_max_distance:
					# če trka samo levi, pojdi desno
					if vision_ray_left.is_colliding() and not vision_ray_right.is_colliding():
						if angle_to_cell > right_angle and angle_to_cell < right_angle + angle_range:
							duck_area.append(cell_position)
					# če trka samo desni, pojdi levo
					elif vision_ray_right.is_colliding() and not vision_ray_left.is_colliding():
						if angle_to_cell < left_angle and angle_to_cell > left_angle - angle_range:
							duck_area.append(cell_position)
					# če trkata oba, pejd nazaj
					elif vision_ray_right.is_colliding() and vision_ray_left.is_colliding(): # če ne trka
						if angle_to_cell < rear_angle + angle_range and angle_to_cell > rear_angle - angle_range: # izbiraj levo in desno
							duck_area.append(cell_position)
					# če ne trka nobeden, pejd levo ali desno
					else:
						if (angle_to_cell < left_angle and angle_to_cell > left_angle - angle_range) or (angle_to_cell > right_angle and angle_to_cell < right_angle + angle_range):
							duck_area.append(cell_position)
						
			# set duck target 
			var duck_target_cell: Vector2#  = global_position # določena pozicija prve random celice
			if duck_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				duck_target_cell = duck_area[randi() % duck_area.size() - 1]
				var new_poli = poli.instance()
				new_poli.global_position = duck_target_cell
				new_poli.color = Color.white
				get_parent().add_child(new_poli)				
		
			duck_target_set = true
			
			var distance_to_duck_target = global_position.distance_to(duck_target_cell)
			var duck_tween = get_tree().create_tween()
			duck_tween.tween_property(self, "velocity", Vector2.ZERO, break_time)
#			duck_tween.parallel().tween_property(self, "global_position", duck_target_cell, distance_to_duck_target/duck_speed_factor).set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			duck_tween.parallel().tween_property(self, "global_position", duck_target_cell, distance_to_duck_target/duck_speed_factor).set_delay(0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
#			yield(get_tree().create_timer(break_time + 2), "timeout")
			duck_target_set = false	

		# CAST_TO DIR
		
#		# definiraj možne smeri
#		var vision_rays: Array = [vision_ray_rear, vision_ray_left, vision_ray_right] # vision_ray_front ne rabim ker gleda naprotnika in noče it proti njemu
#		var no_collision_rays: Array = []
#
#		for vision_ray in vision_rays:
#			if not vision_ray.is_colliding():
#				no_collision_rays.append(vision_ray)
#
#		# izberi ray cast_to in akcija ...		
#		if vision_rays.size() > 0:
#
#			var selected_ray = vision_ray_right
##			var selected_ray = vision_rays[randi() % vision_rays.size() - 1]
#			duck_target_set = true
#			modulate = Color.chartreuse
#
#			var duck_tween = get_tree().create_tween()
#			duck_tween.tween_property(self, "velocity", Vector2.ZERO, 0.5)
##			duck_tween.tween_property(self, "global_position", global_position  - hit_from, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
##			duck_tween.parallel().tween_property(self, "modulate", Color.pink, 1)
#			duck_tween.parallel().tween_property(self, "global_position", global_position - selected_ray.get_cast_to(), 0.7).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
#			yield(get_tree().create_timer(break_time + 2), "timeout")
#			duck_target_set = false
#		look_at(global_position - selected_ray.get_cast_to())
	
	
	
		pass
	

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
#	print("target")


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
	
	
	

	
