extends Area2D


signal weapon_shot

enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.HIT

export var height: float = 0
export var elevation: float = 0 # glese na owner
export var hit_damage: float = 1
export (Array, PackedScene) var travel_fx: Array
export (Array, PackedScene) var hit_fx: Array

var mala_owner: Node2D
var is_set = false

onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D
#onready var detect_area: Area2D = $DetectArea



func _ready() -> void:

	add_to_group(Rfs.group_male)

	collision_poly.set_deferred("disabled", true)
	monitoring = false
	_spawn_fx(travel_fx)


func _physics_process(delta: float) -> void:

	pass


func setup(owner_node: Node2D):

	mala_owner = owner_node
	elevation = mala_owner.elevation + elevation
	collision_poly.set_deferred("disabled", false)
	monitoring = true

	# !!!
	is_set = false
	# ne setam ga, da ga bolt hud ne kaže in
	# ker ZAENKRAT noben ne rabi vedet, ali je setan


func _on_detect_collision(body):

	if body.has_method("on_hit") and not body == mala_owner:
		body.on_hit(self, global_position)
		_spawn_fx(hit_fx)


func _on_weapon_triggered(trigger_owner: Node2D):

	#	if is_set:
	#		var shooting_weapon: Node2D = trigger_owner.bolt_hud.selected_weapon
	#		if shooting_weapon.weapon_type == weapon_type:
	#			if ammo_count > 0 and weapon_reloaded:
	#				_shoot(trigger_owner)
	pass


func _shoot(weapon_owner: Node2D):

	#	emit_signal("weapon_shot", ammo_stat_key, -1)
	pass


func _dissarm():
	queue_free()


func _spawn_fx(fx_array: Array, spawn_parent: Node2D = null, fx_pos: Vector2 = global_position, fx_rot: float = global_rotation):
	# tale je bolj moderna od funkcije v ostalih orožjih ... nočeš dat parenta, če ni za vse enak (tudi zvok)

	var spawned_fx: Array = []

	for fx in fx_array:
		var new_fx = fx.instance()
		if new_fx is AudioStreamPlayer:
			# spawn parent ...  bo drugače, ko bodo efekti pvoezani s signali
			if spawn_parent:
				spawn_parent.add_child(new_fx)
			else:
				add_child(new_fx)
		else:
			new_fx.global_position = fx_pos
			new_fx.global_rotation = fx_rot
			# spawn parent
			if spawn_parent:
				spawn_parent.add_child(new_fx)
			else:
				Rfs.node_creation_parent.add_child(new_fx)
			# štarta če je kaj za štartat
			for fx_child in new_fx.get_children():
				if fx_child is Particles2D or fx_child is CPUParticles2D:
					fx_child.emitting = true
				elif fx_child is AnimationPlayer: # prva animacija
					if "animation_player" in fx: # preverim, da je "vklopljen"
						fx_child.play(fx_child.get_animation_list()[0])
				elif fx_child is AnimatedSprite:
					fx_child.playing = true

		spawned_fx.append(new_fx)


func _on_Mala_body_entered(body: Node) -> void:

	_on_detect_collision(body)
