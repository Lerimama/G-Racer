extends KinematicBody2D
class_name Misile


var spawner: Node
var spawner_color: Color
var spawner_speed: float
var in_spawner_area: bool =  true

export var height: float = 0
onready var elevation: float = spawner.elevation + 7 # PRO rabi jo senčka

# gibanje
#export var height: float = 0 # PRO
export var start_speed: float = 10.0
var speed: float = 0
var is_dissarmed: bool = false
var velocity: Vector2
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
# var direction_start_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta
var acceleration_time = 3.0
var collision: KinematicCollision2D
var misile_time: float = 0 # čas za domet
var dissarm_speed_drop: float = 3 # notri je to v kvadratni funkciji
var wiggle_direction_range: Array = [-24, 24] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var homming_target_position: Vector2
var new_misile_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var drop_position: Position2D = $DropPosition
onready var hit_position: Position2D = $HitPosition

onready var homming_detect: Area2D = $HommingArea
onready var collision_shape: CollisionShape2D = $MisileCollision
onready var vision_ray: RayCast2D = $VisionRay

onready var MisileExplosion = preload("res://game/weapons/ammo/misile/MisileExplosionParticles.tscn")
onready var MisileHit = preload("res://game/weapons/ammo/misile/MisileHit.tscn")
onready var MisileTrail = preload("res://game/weapons/ammo/misile/MisileTrail.tscn")
onready var DropParticles = preload("res://game/weapons/ammo/misile/MisileDropParticles.tscn")

onready var weapon_profile: Dictionary = Pros.ammo_profiles[Pros.AMMO.MISILE]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var max_speed: float = weapon_profile["speed"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var mass: float = weapon_profile["mass"]
onready var direction_start_range: Array = weapon_profile["direction_start_range"] # natančnost misile
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

# neu
enum TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # enako kot breaker
var object_type = TYPE.EXPLODING


func _ready() -> void:

	randomize()

	add_to_group(Refs.group_misiles)
#	$Sprite.modulate = spawner_color
	collision_shape.set_deferred("disabled", true) # da ne trka z avtorjem ... ga vključimo, ko raycast zazna izhod

	$Sounds/MisileShoot.play()
	$Sounds/MisileFlight.play()

	# set movement
	var random_range = rand_range(direction_start_range[0],direction_start_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2(cos(rotation), sin(rotation))
	speed = start_speed + spawner_speed

	# spawn trail
	new_misile_trail = MisileTrail.instance()
	new_misile_trail.gradient.colors[2] = spawner_color
	new_misile_trail.z_index = trail_position.z_index - 1
	new_misile_trail.modulate.a = 0
	Refs.node_creation_parent.add_child(new_misile_trail)


func _physics_process(delta: float) -> void:

#	max_speed = 20
	misile_time += delta

	# pospeševanje
	if misile_time < lifetime:
		var accelaration_tween = get_tree().create_tween()
		accelaration_tween.tween_property(self ,"speed", max_speed, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		new_misile_trail.add_points(trail_position.global_position)
	# bremzanje
	elif misile_time > lifetime:
		speed -= pow(dissarm_speed_drop, 1.0) # deactivated_speed_drop na kvadrat
		speed = clamp(speed, 0.0, speed)
		new_misile_trail.add_points(trail_position.global_position)
		if speed <= 50.0:
			dissarm()

	# sledenje
	if is_homming == true:
		direction = lerp(direction, global_position.direction_to(homming_target_position), 0.1)
		rotation = global_position.direction_to(homming_target_position).angle()

		if homming_detect.monitoring != true:
			homming_detect.monitoring = true
		elif homming_detect.monitoring == true:
			homming_detect.monitoring = false

	# preverjam, če se še dotika avtorja
	if vision_ray.is_colliding():
		if vision_ray.get_collider() == spawner:
			in_spawner_area = true
		else:
			in_spawner_area = false
	else:
		in_spawner_area = true

	# collision enable ... tukaj ker drugače collision prehiti vision ray
	if in_spawner_area:
		collision_shape.set_deferred("disabled", true)
	else:
		collision_shape.set_deferred("disabled", false)

	velocity = direction * speed

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	collision = move_and_collide(velocity * delta, false)
	if collision:
		if collision.collider != spawner: # sam sebe lahko ubiješ
			explode()
			if collision.collider.has_method("on_hit"):
				collision.collider.on_hit(self, global_position) # pošljem node z vsemi podatki in kolizijo


func dissarm():

	if not is_dissarmed:
		is_dissarmed = true
		$Sounds/MisileDissarm.volume_db = -30
		# wigle
		#	var wiggle: Vector2
		#	wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
		#	transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)
		##	transform.x = direction # random smer je določena ob štartu in ob deaktivaciji
		#	velocity = transform.x * speed
		#	position += velocity * delta
		#	misile_active = false


		# misile drop
		var new_drop_tween = get_tree().create_tween()
		new_drop_tween.tween_property(self, "scale", scale * 0.5, 0.7).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CIRC)
		yield(new_drop_tween, "finished")

		$Sounds/MisileDissarm.play()
		$Sounds/MisileDetect.stop()
		$Sounds/MisileFlight.stop()
		$Sounds/MisileShoot.stop()

		# drop particles
		var new_drop_particles: CPUParticles2D = DropParticles.instance()
		new_drop_particles.global_position = drop_position.global_position
		new_drop_particles.color = spawner_color
		new_drop_particles.z_index = drop_position.z_index
		new_drop_particles.set_emitting(true)
		Refs.node_creation_parent.add_child(new_drop_particles)

		yield(get_tree().create_timer(0.15), "timeout")
		queue_free()

		new_misile_trail.start_decay()


func explode():

	# ene rabm
	#	$Sounds/MisileFlight.stop()
	#	$Sounds/MisileShoot.stop()

	new_misile_trail.start_decay()

	var new_hit_fx = MisileHit.instance()
	new_hit_fx.global_position = hit_position.global_position
	new_hit_fx.get_node("ExplosionParticles").process_material.color_ramp.gradient.colors[1] = spawner_color
	new_hit_fx.get_node("ExplosionParticles").process_material.color_ramp.gradient.colors[2] = spawner_color
	new_hit_fx.get_node("ExplosionParticles").set_emitting(true)
	new_hit_fx.get_node("SmokeParticles").set_emitting(true)
	new_hit_fx.get_node("BlastAnimated").play()
	Refs.node_creation_parent.add_child(new_hit_fx)

	queue_free()


func _on_HommingArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts) and body != spawner:
		if not is_homming:
			$Sounds/MisileDetect.play()
		is_homming = true
		homming_target_position = body.global_position


func _exit_tree() -> void:

	speed = 0
	if new_misile_trail and not new_misile_trail.in_decay:
		new_misile_trail.start_decay()
