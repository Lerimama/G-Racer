extends Area2D


#signal weapon_shot

enum WEAPON_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}

export (WEAPON_TYPE) var weapon_type: int = 4

enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.HIT

export var height: float = 0
export var elevation: float = 0 # glese na owner
export var hit_damage: float = 1
export (Array, PackedScene) var travel_fx: Array
export (Array, PackedScene) var hit_fx: Array
export (Texture) var load_icon: Texture = null # uni ime

var influenced_bodies: Array = []
var weapon_owner: Node2D
var is_set: bool = false
onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:

	add_to_group(Refs.group_male)

	collision_poly.set_deferred("disabled", true)
	monitoring = false
	_spawn_fx(travel_fx, false, Refs.node_creation_parent)


func _physics_process(delta: float) -> void:

	for influenced_body in influenced_bodies:
		if not influenced_body.is_queued_for_deletion():
			influenced_body.on_hit(self, global_position)


func set_weapon(owner_node: Node2D):

	weapon_owner = owner_node
	elevation = weapon_owner.elevation + elevation
	collision_poly.set_deferred("disabled", false)
	monitoring = true
	is_set = true


func _on_detect_collision(body):

	if body.has_method("on_hit") and not body == weapon_owner:
		if not body in influenced_bodies:
			influenced_bodies.append(body)

		_spawn_fx(hit_fx, true, Refs.node_creation_parent)


func _shoot():

	var no_use_disabled = true


func _dissarm():
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
				new_fx.connect("finished", Refs.game_tracker, "_on_fx_finished", [], CONNECT_ONESHOT)
		else:
			# spawn
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			spawn_parent.add_child(new_fx)
			new_fx.start_fx(self_destruct) # znotraj urejeno
			# connect
			if not self_destruct:
				new_fx.connect("fx_finished", Refs.game_tracker, "_on_fx_finished", [], CONNECT_ONESHOT)

		spawned_fx.append(new_fx)


func _on_Mala_body_entered(body: Node) -> void:

	_on_detect_collision(body)


func _on_Mala_body_exited(body: Node) -> void:

	influenced_bodies.erase(body)
