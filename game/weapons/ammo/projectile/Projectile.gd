extends RigidBody2D
class_name Projectile


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 5 # elevation se doda elevationu objektu spawnanja
export var hit_damage: float = 0.2
export var lifetime: float = 1 # 0 = večno
export var masa: float = 0.03 # domet vedno merim s časom
export var speed: float = 320
export var direction_start_range: Vector2 = Vector2(0, 0)
export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var flight_fx: Array
export (Array, PackedScene) var hit_fx: Array
export (Array, PackedScene) var dissarm_fx: Array

var spawner: Node
var spawner_color: Color
var spawner_speed: float

var new_trail: Object
var is_active: bool = false
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D
var bullet_momentum: float # je zmnožek hitrosti in teže
var collider_momentum: float # je zmnožek hitrosti in teže

onready var trail_position: Position2D = $TrailPosition
onready var dissarm_position: Position2D = $DissarmPosition
onready var hit_position: Position2D = $HitPosition
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $BulletCollision
onready var influence_area: Area2D = $InfluenceArea # območje vpliva


func _ready() -> void:

	add_to_group(Rfs.group_bullets)

	if spawner:
		vision_ray.add_exception(spawner)

	_spawn_fx(shoot_fx, Rfs.node_creation_parent)
	_spawn_fx(flight_fx, Rfs.node_creation_parent)

	elevation = spawner.elevation + elevation

	var random_range = rand_range(direction_start_range.x,direction_start_range.y) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2.RIGHT.rotated(rotation)

	# spawn trail
	if trail:
		new_trail = trail.instance()
		new_trail.z_index = trail_position.z_index + 1
		Rfs.node_creation_parent.add_child(new_trail)

	is_active = true


func _physics_process(delta: float) -> void:

	if new_trail:
		new_trail.add_points(trail_position.global_position) # premaknjeno iz process

	if vision_ray.is_colliding():
		if vision_ray.get_collider().has_method("on_hit"):
			vision_ray.get_collider().on_hit(self, vision_ray.get_collision_point()) # pošljem node z vsemi podatki in kolizijo
		call_deferred("_explode", vision_ray.get_collision_point(), vision_ray.get_collision_normal())


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	set_applied_force(direction * speed)


func _explode(collision_position: Vector2, collision_normal: Vector2):

	_spawn_fx(hit_fx, Rfs.node_creation_parent, collision_position, deg2rad(180) + collision_normal.angle()) # 180 dodatek omogča, da ni na vertikalah naroben kot

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(collision_position)

	speed = 0
	queue_free()


func _dissarm():

	if is_active:
		is_active = false

		# misile drop
		var new_drop_tween = get_tree().create_tween()
		new_drop_tween.tween_property(self, "scale", scale * 0.5, 0.7).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CIRC)
		yield(new_drop_tween, "finished")

		_spawn_fx(dissarm_fx, Rfs.node_creation_parent, dissarm_position.global_position)

		queue_free()

		if new_trail and not new_trail.in_decay:
			new_trail.start_decay()


func _spawn_fx(fx_array: Array, spawn_parent: Node2D = self, fx_pos: Vector2 = global_position, fx_rot: float = global_rotation):

	var spawned_fx: Array = []

	for fx in fx_array:
		var new_fx = fx.instance()
		if new_fx is AudioStreamPlayer:
			add_child(new_fx)
		else:
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			spawn_parent.add_child(new_fx)

			# štarta če je kaj za štartat
			for fx_child in new_fx.get_children():
				if fx_child is Particles2D or fx_child is CPUParticles2D:
					fx_child.emitting = true
				if fx_child is AnimationPlayer: # prva animacija
					if "animation_player" in fx: # preverim, da je "vklopljen"
						fx_child.play(fx_child.get_animation_list()[0])
				if fx_child is AnimatedSprite:
					fx_child.playing = true

		spawned_fx.append(new_fx)


func on_out_of_playing_field():

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(global_position)
	queue_free()


func _exit_tree() -> void:

	if new_trail and not new_trail.in_decay:
		new_trail.start_decay(new_trail.global_position)
