extends RigidBody2D


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 3 # elevation se doda elevationu objektu spawnanja
export var hit_damage: float = 0.5
export var lifetime: float = 3.2 # 0 = večno
export var masa: float = 5 # fejk, ker je konematic, on_hit pa preverja .mass
export var hit_inertia: float = 0 # fejk, ker je konematic, on_hit pa preverja .mass
export var start_thrust_power: float = 10
export var max_thrust_power: float = 150
export var direction_start_range: Vector2 = Vector2(-0.1, 0.1)
export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var flight_fx: Array
export (Array, PackedScene) var homming_fx: Array
export (Array, PackedScene) var dissarm_fx: Array
export (Array, PackedScene) var hit_fx: Array

var spawner: Node

# gibanje
var thrust_power: float = 0
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var acceleration_time = 1.0
var wiggle_direction_range: Array = [-24, 24] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6
var dissarm_thrust_power_drop: float = 3 # notri je to v kvadratni funkciji

var is_active: bool = false
var misile_time: float = 0 # čas za domet
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var new_trail: Line2D

onready var trail_position: Position2D = $TrailPosition
onready var homming_area: Area2D = $HommingArea
onready var collision_shape: CollisionShape2D = $MisileCollision
onready var vision_ray: RayCast2D = $VisionRay
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

# neu homer
var homming_target: Node2D = null
var out_of_spawner: bool = false
var thrust_power_to_spawner_factor: float = 100 # na ready pomnoi vse power elemente
var spawner_speed_factor: float = 10


func _ready() -> void:

	randomize()

	add_to_group(Rfs.group_misiles)

	elevation = spawner.elevation + elevation
	mass = masa
	collision_shape.disabled = true

	_spawn_fx(shoot_fx, true, Rfs.node_creation_parent)
	_spawn_fx(flight_fx, false, Rfs.node_creation_parent)

	# rotation
	var random_range = rand_range(direction_start_range.x,direction_start_range.y) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2(cos(rotation), sin(rotation))

	# power
	var spawner_speed: float = 0
	if spawner.is_class("RigidBody2D"):
		spawner_speed = spawner.get_linear_velocity().length()
	thrust_power = start_thrust_power * thrust_power_to_spawner_factor + spawner_speed * 10
	max_thrust_power *= thrust_power_to_spawner_factor

	if spawner: # trenutno ga ne rabim
		vision_ray.add_exception(spawner)

	# spawn trail
	if trail:
		new_trail = trail.instance()
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
		accelaration_tween.tween_property(self ,"thrust_power", max_thrust_power, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# bremzanje
	elif misile_time > lifetime:
		thrust_power -= pow(dissarm_thrust_power_drop / thrust_power_to_spawner_factor, 1.0) # deactivated_thrust_power_drop na kvadrat
		thrust_power = clamp(thrust_power, 0, thrust_power)
		if thrust_power <= 5:
			_dissarm()

	# sledenje
	if not is_instance_valid(homming_target):
		homming_target = null

	if homming_target:
		direction = lerp(direction, global_position.direction_to(homming_target.global_position), 0.1)
		rotation = global_position.direction_to(homming_target.global_position).angle()
		if homming_area.monitoring:
			homming_area.set_deferred("monitoring", false) # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		else:
			homming_area.set_deferred("monitoring", true)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	if state.get_contact_count() > 0:
		var contact_collider: Object = state.get_contact_collider_object(0)
		var collision_local_position: Vector2 = state.get_contact_local_position(0)
		_on_collision_contact(contact_collider, collision_local_position)

	set_applied_force(direction * thrust_power)



func _on_collision_contact(colliding_object: Object, collision_local_position: Vector2):

	var collision_global_position: Vector2 = collision_local_position + global_position

	if not colliding_object == spawner: # sam sebe lahko ubiješ
		_explode(collision_local_position)
		if colliding_object.has_method("on_hit"):
			colliding_object.on_hit(self, collision_global_position) # pošljem node z vsemi podatki in kolizijo
		#	else:
		#		printt("HOMMER COLLIDED", spawner, colliding_object)


func _dissarm():

	if is_active:
		#	var wiggle: Vector2
		#	wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
		#	transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)

		is_active = false

		# misile drop
		var new_drop_tween = get_tree().create_tween()
		new_drop_tween.tween_property(self, "scale", scale * 0.5, 0.7).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CIRC)
		yield(new_drop_tween, "finished")

		# drop particles
		_spawn_fx(dissarm_fx, true, Rfs.node_creation_parent, global_position)

		#		$Sounds/MisileDetect.stop()
		#		$Sounds/MisileFlight.stop()
		queue_free()

		if new_trail and not new_trail.in_decay:
			new_trail.start_decay()


func _explode(collision_local_position: Vector2):

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay()

	_spawn_fx(hit_fx, true, Rfs.node_creation_parent, global_position + collision_local_position)

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


func _exit_tree() -> void:

	thrust_power = 0
	if new_trail and not new_trail.in_decay:
		new_trail.start_decay()


func _on_HommingArea_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_agents) and body != spawner:

		if homming_target == null:
			_spawn_fx(homming_fx, false, Rfs.node_creation_parent)
			homming_target = body


func _on_DetectArea_body_exited(body: Node) -> void:

	if body == spawner:
		collision_shape.set_deferred("disabled", false)
