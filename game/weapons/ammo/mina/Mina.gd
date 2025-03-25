extends Node2D


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 2
export var mass: float = 0.5 # fejk, ker je area, on_hit pa preverja .mass
export var lifetime: float = 0 # 0 = večno
export var hit_damage: float = 0.5
export var hit_inertia: float = 100 # fejk, ker je konematic, on_hit pa preverja .mass
export var speed: float = 50
export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var travel_fx: Array
export (Array, PackedScene) var detect_fx: Array
export (Array, PackedScene) var dissarm_fx: Array
export (Array, PackedScene) var hit_fx: Array

var is_enabled = false
var drop_direction: Vector2 = -transform.x # rikverc na osi x
var drop_time: float = 1.0 # opredeli dolžino meta

var weapon_owner: Node2D
var spawner_color: Color
onready var detect_area: Area2D = $DetectArea
onready var active_timer: Timer = $ActiveTimer
onready var smoke_particles: Particles2D = $SmokeParticles
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

export var icon_texture: Texture = load("res://assets/icons/icon_bullet_VRSA.tres")


func _ready() -> void:

	add_to_group(Refs.group_mine)

	_spawn_fx(shoot_fx, true, Refs.node_creation_parent)

	drop_direction = -transform.x # rikverc na osi x

	# drop
	var drop_tween = get_tree().create_tween()
	drop_tween.tween_property(self, "speed", 0.0, drop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drop_tween.tween_callback(self, "activate")
	yield(drop_tween, "finished")
	smoke_particles.emitting = true


func _physics_process(delta: float) -> void:

	global_position += drop_direction * speed * delta # motion


func _activate():

	detect_area.set_deferred("monitoring", true)
	# Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
	if lifetime > 0:
		active_timer.start(lifetime)
	is_enabled = true


func _explode():

	_spawn_fx(hit_fx, true, Refs.node_creation_parent)
	queue_free()


func _dissarm():
	pass


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


func _on_ActiveTimer_timeout() -> void:

	_explode()
	for body in detect_area.get_overlapping_bodies():
		if body.has_method("on_hit") and body != weapon_owner:
			body.on_hit(self, global_position)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	#	explode()
	#	active_timer.stop()
	pass


func _on_DetectArea_body_entered(body: Node) -> void:

	# ustavi ob trku s telesom
	if body != weapon_owner:
		drop_direction = Vector2.ZERO

		if body.has_method("on_hit"):
			_spawn_fx(detect_fx, true, Refs.node_creation_parent)
			_explode()
			body.on_hit(self, global_position)
