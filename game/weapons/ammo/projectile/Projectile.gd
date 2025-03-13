extends RigidBody2D
class_name Projectile


export var projectile_profile: Resource setget _change_projectile_profile

enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot resource
var damage_type = DAMAGE_TYPE.EXPLODE

# resource prepiše
var height: float = 0
var elevation: float = 3 # elevation se doda elevationu objektu spawnanja
var masa: float = 5 # fejk, ker je konematic, on_hit pa preverja .mass
var lifetime: float = 3.2 # 0 = večno
var hit_damage: float = 0.5
var hit_inertia: float = 0 # fejk, ker je konematic, on_hit pa preverja .mass
var start_thrust_power: float = 10
var max_thrust_power: float = 150
var direction_start_range: Vector2 = Vector2(-0.1, 0.1)
# ----
var Trail: PackedScene
var ShootFx: PackedScene
var FlighFx: PackedScene
var DetecFx: PackedScene
var HitFx: PackedScene
var DissarmFx: PackedScene
var homming_mode: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var use_vision_for_collision: bool = false
var delete_on_out_of_screen: bool = false
var spawner: Node
var is_active: bool = false
var misile_time: float = 0
var detect_target: Node2D
var is_out_of_screen: bool = false

# gibanje
var thrust_power: float = 0
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var acceleration_time = 1.0
var dissarm_thrust_power_drop: float = 3 # v kvadratno funkcijo
var spawner_speed_factor: float = 10
var thrust_power_to_spawner_factor: float = 100 # pomnoži max power in current power vse power elemente
var modify_intensity_origin: Vector2 # od tu se meri razdalja def

# inside fx
var trail: Line2D
var flight_fx: Node2D
var detect_fx: Node2D

onready var trail_position: Position2D = $TrailPosition
onready var thrust_position: Position2D = $ThrustPosition
onready var detect_area: Area2D = $DetectArea
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var vision_ray: RayCast2D = $VisionRay
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect
onready var shape_area: Area2D = $ShapeArea

# neu
export var icon_texture: Texture = load("res://assets/icons/icon_bullet_VRSA.tres")
export var magazine_size: int = 10
# ni v profilih
var homming_delay: float = 1


func _ready() -> void:

	add_to_group(Rfs.group_projectiles)

	#	if use_vision_for_collision:
	vision_ray.enabled = true
	if spawner:
		vision_ray.add_exception(spawner)

	if projectile_profile:
		self.projectile_profile = projectile_profile
		yield(get_tree(), "idle_frame")

	hit_inertia *= 3
	elevation = spawner.elevation + elevation
	mass = masa
	collision_shape.disabled = true

	# fx
	_spawn_and_start_fx(ShootFx, true, Rfs.node_creation_parent)
	flight_fx = _spawn_and_start_fx(FlighFx, false, self, trail_position.position)

	# rotation
	randomize()
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

	if homming_mode:
		detect_area.set_deferred("monitoring", true)
	else:
		detect_area.set_deferred("monitoring", false)

	# spawn trail
	if Trail:
		trail = Trail.instance()
		trail.position = trail_position.position
		trail.z_index = trail_position.z_index - 1
		trail.modulate.a = 0
		Rfs.node_creation_parent.add_child(trail)

	is_active = true


func _physics_process(delta: float) -> void:

	misile_time += delta

	# homing vklop
	if homming_mode and misile_time > homming_delay:
		if detect_area.monitoring == false:
			detect_area.set_deferred("monitoring", true)

	if trail:
		trail.add_points(trail_position.global_position)

	#	if use_vision_for_collision:
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

		# off screen
		if is_out_of_screen:
			var distance_from_origin: float = (global_position - modify_intensity_origin).length()
			var fx_zero_intensity_distance: float = Sts.fx_zero_intensity_distance
			#			fx_zero_intensity_distance = 100000
			var distance_to_zero_part: float = distance_from_origin / fx_zero_intensity_distance
			if distance_to_zero_part < 1:
				if flight_fx:
					flight_fx.fx_intensity = 1 - distance_to_zero_part
			else:
				if flight_fx:
					flight_fx.fx_intensity = 0


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	if not use_vision_for_collision and state.get_contact_count() > 0:
		_on_contact_collision(state)

	set_applied_force(direction * thrust_power)


func _on_vision_collision():

	vision_ray.force_raycast_update() # mogoče deluje, ker je drugič v parih korakih
	Rfs.game_reactor.apply_slomo(self, vision_ray.get_collider())

	if use_vision_for_collision:
		var pseudo_close_distance: float = max_thrust_power# / 3
		pseudo_close_distance = vision_ray.cast_to.x # takole je iskanje bližine na off ... trenutno na off
		var distance_to_collision: float = (vision_ray.get_collision_point() - global_position).length()

		if distance_to_collision < pseudo_close_distance:
			#		printt("distance_to_collision", distance_to_collision, pseudo_close_distance)
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
	if flight_fx:
		flight_fx.stop_fx()
	_spawn_and_start_fx(DissarmFx, true, Rfs.node_creation_parent)
	queue_free()

	if trail and not trail.in_decay:
		trail.start_decay(global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva


func _explode(collision_position: Vector2, collision_normal: Vector2 = Vector2.ZERO):

	if is_out_of_screen:
		print ("more bit bolj potihem")

	if collision_normal == Vector2.ZERO: # misisle ... pomoje tole ni potrebno ločeno
		_spawn_and_start_fx(HitFx, true, Rfs.node_creation_parent, collision_position)
	else:
		_spawn_and_start_fx(HitFx, true, Rfs.node_creation_parent, collision_position, deg2rad(180) + collision_normal.angle()) # 180 dodatek omogča, da ni na vertikalah naroben kot

	if trail and not trail.in_decay:
		trail.start_decay(collision_position)

	thrust_power = 0
	queue_free()


func _spawn_and_start_fx(EventFx: PackedScene, self_destruct: bool = true, spawn_parent: Node2D = self, fx_pos: Vector2 = Vector2.ZERO, fx_rot: float = 0):
	# pos in rotacija sta local, če se spawna vase, če ne global

	if EventFx:
		var new_fx = EventFx.instance()
		#	if not spawn_parent == self:
		#		fx_pos += global_position
		#		fx_rot += global_rotation
		new_fx.global_position = fx_pos
		new_fx.global_rotation = fx_rot
		spawn_parent.add_child(new_fx)
		new_fx.start_fx(self_destruct)
		new_fx.connect("fx_finished", Rfs.game_reactor, "_on_fx_finished", [], CONNECT_ONESHOT)
		return new_fx
	else:
		return null


func _change_projectile_profile(new_projectile_profile: Resource):
	# lahko bi lupal ... print ("get_script_property_list", new_projectile_profile.script.get_script_property_list())

	projectile_profile = new_projectile_profile

	damage_type = projectile_profile.damage_type
	height = projectile_profile.height
	elevation = projectile_profile.elevation
	masa = projectile_profile.masa
	lifetime = projectile_profile.lifetime
	hit_damage = projectile_profile.hit_damage
	hit_inertia = projectile_profile.hit_inertia
	start_thrust_power = projectile_profile.start_thrust_power
	max_thrust_power = projectile_profile.max_thrust_power
	direction_start_range = projectile_profile.direction_start_range

	Trail = projectile_profile.trail

	ShootFx = projectile_profile.shoot_fx
	FlighFx = projectile_profile.flight_fx
	DetecFx = projectile_profile.detect_fx
	HitFx = projectile_profile.hit_fx
	DissarmFx = projectile_profile.dissarm_fx

	homming_mode = projectile_profile.homming_mode
	use_vision_for_collision = projectile_profile.use_vision_for_collision
	delete_on_out_of_screen = projectile_profile.delete_on_out_of_screen

	icon_texture = projectile_profile.icon_texture
	magazine_size = projectile_profile.magazine_size


func _exit_tree() -> void:
	# zazih uasnem vse, kar ne sme ostati

	if detect_fx and is_instance_valid(detect_fx):
		detect_fx.stop_fx()
	if flight_fx and is_instance_valid(flight_fx):
		flight_fx.stop_fx()
	thrust_power = 0
	if trail and not trail.in_decay:
		trail.start_decay(trail.global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_drivers) and body != spawner:
		if not detect_target or not is_instance_valid(detect_target):
			detect_fx = _spawn_and_start_fx(DetecFx, false)
			detect_target = body


func _on_DetectArea_body_exited(body: Node) -> void:

	if body == detect_target:
		if detect_fx:
			detect_fx.stop_fx()
		detect_target = null


func _on_ShapeArea_body_exited(body: Node) -> void:

	if body == spawner:
		collision_shape.set_deferred("disabled", false)
		shape_area.set_deferred("monitoring", false)


func on_out_of_playing_field():

	if trail and not trail.in_decay:
		trail.start_decay(global_position) # _temp parametri so zarasi simple trejla, kompleksn jih ne upošteva
	queue_free()


func _on_VisibilityNotifier2D_screen_exited() -> void:

	is_out_of_screen = true
	modify_intensity_origin = global_position
	# intensity se pedena v_FP se pedena
	#	flight_fx.stop_fx()

	if delete_on_out_of_screen:
		queue_free()


func _on_VisibilityNotifier2D_screen_entered() -> void:

#	flight_fx.fx_intensity = 1
	is_out_of_screen = false
