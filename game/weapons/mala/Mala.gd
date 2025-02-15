extends Area2D


signal weapon_shot

enum WEAPON_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}

export (WEAPON_TYPE) var weapon_type: int = 4


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.HIT

export var height: float = 0
export var elevation: float = 0 # glese na owner
export var hit_damage: float = 1
export (Array, PackedScene) var travel_fx: Array
export (Array, PackedScene) var hit_fx: Array

var influenced_bodies: Array = []
var mala_owner: Node2D
var is_set: bool = false
onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:

	add_to_group(Rfs.group_male)

	collision_poly.set_deferred("disabled", true)
	monitoring = false
	_spawn_fx(travel_fx, false, Rfs.node_creation_parent)


func _physics_process(delta: float) -> void:

	for influenced_body in influenced_bodies:
		influenced_body.on_hit(self, global_position)


func setup(owner_node: Node2D):

	mala_owner = owner_node
	elevation = mala_owner.elevation + elevation
	collision_poly.set_deferred("disabled", false)
	monitoring = true
	is_set = true


func _on_detect_collision(body):

	if body.has_method("on_hit") and not body == mala_owner:
		if not influenced_bodies.has(body):
			influenced_bodies.append(body)

		_spawn_fx(hit_fx, true, Rfs.node_creation_parent)


func _on_weapon_triggered(trigger_owner: Node2D):
	pass


func _shoot(weapon_owner: Node2D):
	#	emit_signal("weapon_shot", ammo_stat_key, -1)
	pass


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
				new_fx.connect("finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)
		else:
			# spawn
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			spawn_parent.add_child(new_fx)
			new_fx.start_fx(self_destruct) # znotraj urejeno
			# connect
			if not self_destruct:
				new_fx.connect("fx_finished", Rfs.game_manager, "_on_fx_finished", [], CONNECT_ONESHOT)

		spawned_fx.append(new_fx)


func _on_Mala_body_entered(body: Node) -> void:

	_on_detect_collision(body)


func _on_Mala_body_exited(body: Node) -> void:

	influenced_bodies.erase(body)
