extends KinematicBody2D


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 3 # elevation se doda elevationu objektu spawnanja
export var hit_damage: float = 0.5
export var lifetime: float = 3.2 # 0 = večno
export var mass: float = 1 # fejk, ker je konematic, on_hit pa preverja .mass
export var start_speed: float = 10.0
export var speed: float = 1500
export var homming_radius: float = 500
export var direction_start_range: Vector2 = Vector2(-0.1, 0.1)
export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var flight_fx: Array
export (Array, PackedScene) var homming_fx: Array
export (Array, PackedScene) var dissarm_fx: Array
export (Array, PackedScene) var hit_fx: Array

var spawner: Node
var spawner_color: Color
var spawner_speed: float
var in_spawner_area: bool =  true

# gibanje
var current_speed: float = 0
var velocity: Vector2
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var acceleration_time = 3.0
var wiggle_direction_range: Array = [-24, 24] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6
var dissarm_speed_drop: float = 3 # notri je to v kvadratni funkciji

var is_active: bool = false
var collision: KinematicCollision2D
var misile_time: float = 0 # čas za domet
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var new_trail: Line2D

onready var trail_position: Position2D = $TrailPosition
onready var dissarm_position: Position2D = $DissarmPosition
onready var hit_position: Position2D = $HitPosition
onready var homming_area: Area2D = $HommingArea
onready var collision_shape: CollisionShape2D = $MisileCollision
onready var vision_ray: RayCast2D = $VisionRay
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

# neu homer
var homming_target_position: Vector2
var homming_target: Node2D = null


func _ready() -> void:

	randomize()

	add_to_group(Rfs.group_projectiles)

	elevation = spawner.elevation + elevation

	_spawn_fx(shoot_fx, true, Rfs.node_creation_parent)
	_spawn_fx(flight_fx, false, Rfs.node_creation_parent)

	# set movement
	var random_range = rand_range(direction_start_range.x,direction_start_range.y) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2(cos(rotation), sin(rotation))
	current_speed = start_speed + spawner_speed

	homming_area.get_child(0).shape.radius = homming_radius

	if spawner:
		vision_ray.add_exception(spawner)

	# spawn trail
	if trail:
		new_trail = trail.instance()
		new_trail.gradient.colors[2] = spawner_color
		new_trail.z_index = trail_position.z_index - 1
		new_trail.modulate.a = 0
		Rfs.node_creation_parent.add_child(new_trail)


func _physics_process(delta: float) -> void:

	misile_time += delta

	if new_trail:
		new_trail.add_points(trail_position.global_position)

	# pospeševanje
	if misile_time < lifetime:
		var accelaration_tween = get_tree().create_tween()
		accelaration_tween.tween_property(self ,"current_speed", speed, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# bremzanje
	elif misile_time > lifetime:
		current_speed -= pow(dissarm_speed_drop, 1.0) # deactivated_speed_drop na kvadrat
		current_speed = clamp(current_speed, 0.0, current_speed)
		if current_speed <= 50.0:
			_dissarm()

	# sledenje
	if not is_instance_valid(homming_target):
		homming_target = null

	if homming_target:
		direction = lerp(direction, global_position.direction_to(homming_target.global_position), 0.1)
		rotation = global_position.direction_to(homming_target.global_position).angle()
		#	if is_homming == true:
		#		direction = lerp(direction, global_position.direction_to(homming_target_position), 0.1)
		#		rotation = global_position.direction_to(homming_target_position).angle()

		if homming_area.monitoring:
			homming_area.set_deferred("monitoring", false) # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		else:
			homming_area.set_deferred("monitoring", true)

	velocity = direction * current_speed

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	collision = move_and_collide(velocity * delta, false)
	if collision:
		if collision.collider != spawner: # sam sebe lahko ubiješ
			_explode()
			if collision.collider.has_method("on_hit"):
				collision.collider.on_hit(self, global_position) # pošljem node z vsemi podatki in kolizijo


func _dissarm():

	if is_active:
		is_active = false

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

		#		$Sounds/MisileDetect.stop()
		#		$Sounds/MisileFlight.stop()

		# drop particles
		_spawn_fx(dissarm_fx, true, Rfs.node_creation_parent, dissarm_position.global_position)

		queue_free()

		if new_trail and not new_trail.in_decay:
			new_trail.start_decay()


func _explode():

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay()

	_spawn_fx(hit_fx, true, Rfs.node_creation_parent, hit_position.global_position)

	queue_free()


func _spawn_fx(fx_array: Array, self_destruct: bool = true, spawn_parent: Node2D = self, fx_pos: Vector2 = global_position, fx_rot: float = global_rotation):

	var spawned_fx: Array = []

	for fx in fx_array:
		var new_fx = fx.instance()

		if new_fx is AudioStreamPlayer:
			# spawn
			add_child(new_fx)
			# connect
			if not self_destruct:
				new_fx.connect("finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)
		else:
			# spawn
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			spawn_parent.add_child(new_fx)
			new_fx.start(self_destruct) # znotraj urejeno
			# connect
			if not self_destruct:
				new_fx.connect("fx_finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)

		spawned_fx.append(new_fx)



func _on_HommingArea_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_agents) and body != spawner:

		if homming_target == null:
			_spawn_fx(homming_fx, false, Rfs.node_creation_parent)
			homming_target = body
			#		if not is_homming:
			#			_spawn_fx(homming_fx, Rfs.node_creation_parent)
			#		is_homming = true
			#		homming_target_position = body.global_position


func _exit_tree() -> void:

	current_speed = 0
	if new_trail and not new_trail.in_decay:
		new_trail.start_decay()
