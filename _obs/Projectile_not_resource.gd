extends RigidBody2D
#class_name Projectile


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 3 # elevation se doda elevationu objektu spawnanja
export var masa: float = 5 # fejk, ker je konematic, on_hit pa preverja .mass
export var lifetime: float = 3.2 # 0 = večno
export var hit_damage: float = 0.5
export var hit_inertia: float = 0 # fejk, ker je konematic, on_hit pa preverja .mass
export var start_thrust_power: float = 10
export var max_thrust_power: float = 150
export var direction_start_range: Vector2 = Vector2(-0.1, 0.1)

export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var hit_fx: Array
export (Array, PackedScene) var dissarm_fx: Array
export var homming_mode: bool = false # sledilka mode (ko zagleda tarčo v dometu)
export var use_vision: bool = false

var spawner: Node
var is_active: bool = false
var misile_time: float = 0 # čas za domet
var new_trail: Line2D
var detect_target: Node2D

# gibanje
var thrust_power: float = 0
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var acceleration_time = 1.0
var dissarm_thrust_power_drop: float = 3 # v kvadratno funkcijo
var spawner_speed_factor: float = 10
var thrust_power_to_spawner_factor: float = 100 # pomnoži max power in current power vse power elemente

onready var trail_position: Position2D = $TrailPosition
onready var detect_area: Area2D = $DetectArea
onready var collision_shape: CollisionShape2D = $MisileCollision
onready var vision_ray: RayCast2D = $VisionRay
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect
onready var shape_area: Area2D = $ShapeArea
onready var flight_fx: Node2D = $Fx/Flight
onready var detect_fx: Node2D = $Fx/Detect

# neu
export var ammo_resource: Resource

func _override_from_resource():

	damage_type = ammo_resource.damage_type
	height = ammo_resource.height
	elevation = ammo_resource.elevation
	masa = ammo_resource.masa
	lifetime = ammo_resource.lifetime
	hit_damage = ammo_resource.hit_damage
	hit_inertia = ammo_resource.hit_inertia
	start_thrust_power = ammo_resource.start_thrust_power
	max_thrust_power = ammo_resource.max_thrust_power
	direction_start_range = ammo_resource.direction_start_range



func _ready() -> void:

	if ammo_resource:
		_override_from_resource()


	add_to_group(Rfs.group_projectiles)
	randomize()
	print(hit_inertia)
	hit_inertia *= 3
	elevation = spawner.elevation + elevation
	mass = masa
	collision_shape.disabled = true

	_spawn_and_start_fx(shoot_fx, true, Rfs.node_creation_parent)
	$Fx/Flight.start(false)

	# rotation
	var random_range = rand_range(direction_start_range.x,direction_start_range.y) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2.RIGHT.rotated(rotation) # Vector2(cos(rotation), sin(rotation))

	# power
	var spawner_speed: float = 0
	if spawner.is_class("RigidBody2D"):
		spawner_speed = spawner.get_linear_velocity().length()
	if start_thrust_power > max_thrust_power:
		start_thrust_power = max_thrust_power
	thrust_power = start_thrust_power * thrust_power_to_spawner_factor + spawner_speed * 10

	if use_vision:
		vision_ray.enabled = true
		if spawner:
			vision_ray.add_exception(spawner)

	if homming_mode:
		detect_area.set_deferred("monitoring", true)
	else:
		detect_area.set_deferred("monitoring", false)

	# spawn trail
	if trail:
		new_trail = trail.instance()
		new_trail.z_index = trail_position.z_index - 1
		new_trail.modulate.a = 0
		Rfs.node_creation_parent.add_child(new_trail)

	is_active = true


func _physics_process(delta: float) -> void:

	misile_time += delta

	if new_trail:
		new_trail.add_points(trail_position.global_position)

	if use_vision:
		vision_ray.force_raycast_update()
		if vision_ray.get_collider():
			_on_vision_collision()

	if is_active:

		# pospeševanje
		if misile_time < lifetime or lifetime == 0:
			var accelaration_tween = get_tree().create_tween()
			accelaration_tween.tween_property(self ,"thrust_power", max_thrust_power * thrust_power_to_spawner_factor, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# bremzanje, če life ni ničs
		elif not lifetime == 0:
			var min_thrust_power: float = max_thrust_power / 10 * thrust_power_to_spawner_factor
			var decelaration_tween = get_tree().create_tween()
			decelaration_tween.tween_property(self ,"thrust_power", min_thrust_power, acceleration_time)
			yield(decelaration_tween, "finished")
			#		thrust_power -= pow(dissarm_thrust_power_drop * 10 / thrust_power_to_spawner_factor, 1.0) # deactivated_thrust_power_drop na kvadrat
			#		thrust_power = clamp(thrust_power, 0, thrust_power)
			_dissarm()

		# sledenje
		if not is_instance_valid(detect_target):
			detect_target = null

		if detect_target:
			direction = lerp(direction, global_position.direction_to(detect_target.global_position), 0.1)
			rotation = global_position.direction_to(detect_target.global_position).angle()
			# ??
			#			if detect_area.monitoring:
			#				detect_area.set_deferred("monitoring", false) # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
			#			else:
			#				detect_area.set_deferred("monitoring", true)



func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	if not use_vision and state.get_contact_count() > 0:
		_on_contact_collision(state)

	set_applied_force(direction * thrust_power)


func _on_vision_collision():

	#	var pseudo_close_distance: float = max_thrust_power / 3
	#	distance_to_collision = (vision_ray.get_collision_point() - global_position).length()
	#	if distance_to_collision < pseudo_close_distance:
	#		printt("distance_to_collision", distance_to_collision, pseudo_close_distance)
	#		_on_vision_collision()
	#	else:
	#		distance_to_collision = vision_ray.cast_to.x

	vision_ray.force_raycast_update() # mogoče deluje, ker je drugič v parih korakih
	_explode(vision_ray.get_collision_point(), vision_ray.get_collision_normal())

	var detected_collider: Node2D = vision_ray.get_collider()
	if detected_collider.has_method("on_hit"):
		detected_collider.on_hit(self, vision_ray.get_collision_point()) # pošljem node z vsemi podatki in kolizijo


func _on_contact_collision(body_state: Physics2DDirectBodyState):

	var contact_collider: Object = body_state.get_contact_collider_object(0)
	var collision_global_position: Vector2 = body_state.get_contact_local_position(0) + global_position
	var collision_global_normal: Vector2 = body_state.get_contact_local_normal(0) + Vector2.RIGHT.rotated(global_rotation)

	if not contact_collider == spawner: # sam sebe lahko ubiješ
		_explode(body_state.get_contact_local_position(0), collision_global_normal)
		if contact_collider.has_method("on_hit"):
			contact_collider.on_hit(self, collision_global_position) # pošljem node z vsemi podatki in kolizijo


func _dissarm():

	is_active = false

	# misile drop
	#	var new_drop_tween = get_tree().create_tween()
	#	new_drop_tween.tween_property(self, "scale", scale * 0.5, 0.5).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CIRC)
	#	yield(new_drop_tween, "finished")

	# drop particles
	flight_fx.stop_fx()
	_spawn_and_start_fx(dissarm_fx, true, Rfs.node_creation_parent)
	queue_free()

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva


func _explode(collision_position: Vector2, collision_normal: Vector2 = Vector2.ZERO):

	if collision_normal == Vector2.ZERO: # misisle ... pomoje tole ni potrebno ločeno
		_spawn_and_start_fx(hit_fx, true, Rfs.node_creation_parent, collision_position)
	else:
		_spawn_and_start_fx(hit_fx, true, Rfs.node_creation_parent, collision_position, deg2rad(180) + collision_normal.angle()) # 180 dodatek omogča, da ni na vertikalah naroben kot

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(collision_position)

	thrust_power = 0
	queue_free()


func _spawn_and_start_fx(fx_array: Array, self_destruct: bool = true, spawn_parent: Node2D = self, fx_pos: Vector2 = global_position, fx_rot: float = global_rotation):

	for fx in fx_array:
		var new_fx = fx.instance()
		if new_fx is AudioStreamPlayer:
			spawn_parent.add_child(new_fx)
			new_fx.connect("finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)
		else:
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			spawn_parent.add_child(new_fx)
			new_fx.start(self_destruct)
			new_fx.connect("fx_finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)


func _exit_tree() -> void:

	thrust_power = 0
	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(new_trail.global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_agents) and body != spawner:
		if not detect_target or not is_instance_valid(detect_target):
			detect_fx.start(false)
			detect_target = body


func _on_DetectArea_body_exited(body: Node) -> void:

	if body == detect_target:
		detect_fx.stop_fx()
		detect_target == null


func _on_ShapeArea_body_exited(body: Node) -> void:

	if body == spawner:
		collision_shape.set_deferred("disabled", false)
		shape_area.set_deferred("monitoring", false)


func on_out_of_playing_field():

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva
	queue_free()
