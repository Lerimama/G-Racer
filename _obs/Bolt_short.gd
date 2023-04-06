extends KinematicBody2D


enum {BULLET, MISILE, SHOCKER, SHIELD} 

# player data
var player_name: String = "P1"
var player_color: Color = Config.color_blue
var energy: int = 5
var life: int = 3

# bolt data
export var axis_distance: int = 9
export var engine_power: int = 150
export var turn_angle: int = 15 # deg per frame
export var rotation_multiplier: int = 15 # rotacija kadar miruje
export var top_speed_reverse: int = 50
export (float, 0, 10) var drag: float = 2.0 # raste kvadratno s hitrostjo
export (float, 0, 1) var side_traction: float = 0.3
export (float, 0, 1) var bounce_size: float = 0.3		

var input_power: float
var acceleration: Vector2# = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D

var motion_enabled: bool = true

var bullet_reloaded: bool = true
var bullet_reload_time: float = 0.2
var misile_reloaded: bool = true
var misile_reload_time: float = 1.0
var hit_push_factor: float = 0.02 # potisk metka ... delež hitrosti metka

var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 3

var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni, potem je "odklopljena"
var new_bolt_trail: Object

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")



func _ready() -> void:
	
	add_to_group("Bolts")
	name = player_name
	
	bolt_sprite.modulate = player_color
	bolt_collision.disabled = false
	
	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield.self_modulate = player_color 
	shield_collision.disabled = true 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)


func _input(event: InputEvent) -> void:
	
	input_power = Input.get_action_strength("forward") - Input.get_action_strength("reverse") # +1, -1 ali 0
	rotation_dir = Input.get_axis("left", "right") # +1, -1 ali 0	
	
	if Input.is_action_just_pressed("space") && bullet_reloaded == true:
		shooting(BULLET)
	if Input.is_action_just_released("alt") && misile_reloaded == true:	
		shooting(MISILE)
	if Input.is_action_just_released("ctrl"):	
		shooting(SHOCKER)
	if Input.is_action_just_pressed("shift"):
		shooting(SHIELD)
	if Input.is_action_just_pressed("x"):
		explode_and_reset()
		
		
func _physics_process(delta: float) -> void:
	
	
	acceleration = input_power * transform.x * engine_power # transform.x je (-1, 0)
	
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
	if input_power == 0:
		acceleration -= drag_force
		if velocity.length() < 5: # da ne bo neskončno računal pozicije
			velocity = Vector2.ZERO 
	
	velocity += acceleration * delta
	rotation_angle = rotation_dir * deg2rad(turn_angle)  # vsak frejm se obrne za toliko
	if input_power == 0: 
		rotate(delta * rotation_angle * rotation_multiplier)
	else: 
		rotate(delta * rotation_angle)
	
	steering(delta)
	
	
	collision = move_and_collide(velocity * delta, false) # infinite_inertia = false
	
	if collision:
		on_collision()
	
	motion_effects(delta)
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	


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
		
		
func motion_effects(delta: float) -> void:
	
	if input_power > 0:
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.position = $Bolt/RearEnginePosition.global_position
		engine_particles_rear.rotation = $Bolt/RearEnginePosition.global_rotation
		
		# spawn trail
		if bolt_trail_active == false && velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	if input_power < 0:
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.position = $Bolt/FrontEnginePositionL.global_position
		engine_particles_front_left.rotation = $Bolt/FrontEnginePositionL.global_rotation - deg2rad(180)
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.position = $Bolt/FrontEnginePositionR.global_position
		engine_particles_front_right.rotation = $Bolt/FrontEnginePositionR.global_rotation - deg2rad(180)	
		
		# spawn trail
		if bolt_trail_active == false && velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# add trail points
	if bolt_trail_active == true:
		if velocity.length() > 0:
			new_bolt_trail.gradient.colors[1] = player_color
			new_bolt_trail.add_points(global_position)
		elif velocity.length() == 0 && input_power == 0: # "input" je, da izločim za hitre prehode med naprej nazaj
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena

	
func shooting(weapon) -> void:
	
	match weapon:
		BULLET:	
			var new_bullet = Bullet.instance()
			new_bullet.position = $Bolt/GunPosition.global_position
			new_bullet.rotation = $Bolt/GunPosition.global_rotation
			new_bullet.spawned_by = name # ime avtorja izstrelka
			new_bullet.spawned_by_color = player_color
			Global.node_creation_parent.add_child(new_bullet)
			
			bullet_reloaded = false
			yield(get_tree().create_timer(bullet_reload_time), "timeout")
			bullet_reloaded= true
		
		MISILE:			
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
		
		SHOCKER:
			var new_shocker = Shocker.instance()
			new_shocker.rotation = $Bolt/RearEnginePosition.global_rotation
			new_shocker.global_position = $Bolt/RearEnginePosition.global_position
			new_shocker.spawned_by = name # ime avtorja izstrelka
			new_shocker.spawned_by_color = player_color
			Global.effects_creation_layer.add_child(new_shocker)

			misile_reloaded = false
			yield(get_tree().create_timer(misile_reload_time), "timeout")
			misile_reloaded= true		
		
		SHIELD:		
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
		

func steering(delta: float) -> void:
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	if input_power > 0:
		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	elif input_power < 0:
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), top_speed_reverse), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	
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
			energy -= 1
			velocity = collision_object.velocity * hit_push_factor
			# blink efekt ... more bit na koncu zaradi tajmerja
			modulate = Color.black
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 
			if energy <= 0:
				die()

		elif collision_object.is_in_group("Misiles"):
			die()
	
		elif collision_object.is_in_group("Shockers"):
			if motion_enabled == true: # catch
				motion_enabled = false
				velocity = Vector2.ZERO
#				velocity = lerp(velocity, Vector2.ZERO, 0.8)
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
