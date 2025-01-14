extends Node2D
class_name Mina


export var height: float = 0 # PRO
export var elevation: float = 2 # PRO rabi jo senčka

var spawner: Node
var spawner_color: Color

var drop_direction: Vector2 = -transform.x # rikverc na osi x
var drop_time: float = 1.0 # opredeli dolžino meta

var shock_time: float = 5
var is_expanded: bool = false
var detect_expand_size: float = 3.5 # doseg šoka

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var active_timer: Timer = $ActiveTimer
onready var smoke_particles: Particles2D = $SmokeParticles
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

onready var weapon_profile: Dictionary = Pros.ammo_profiles[Pros.AMMO.MINA]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var speed: float = weapon_profile["speed"]
onready var lifetime: float = 0 #weapon_profile["lifetime"]
onready var mass: float = weapon_profile["mass"]
onready var direction_start_range: Array = weapon_profile["direction_start_range"] # natančnost misile
onready var MisileHit = preload("res://game/weapons/ammo/misile/MisileHit.tscn")

# neu
enum TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # enako kot breaker
var object_type = TYPE.EXPLODING


func _ready() -> void:

	add_to_group(Refs.group_mine)
#	modulate = spawner_color

	drop_direction = -transform.x # rikverc na osi x

	$Sounds/MinaShoot.play()

	# drop mine
	var drop_tween = get_tree().create_tween()
	drop_tween.tween_property(self, "speed", 0.0, drop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drop_tween.tween_callback(self, "activate")
	yield(drop_tween, "finished")
	smoke_particles.emitting = true


func _physics_process(delta: float) -> void:

	global_position += drop_direction * speed * delta # motion


func activate():

	detect_area.monitoring = true
	if lifetime > 0:
		active_timer.start(lifetime)


func explode():

	var new_hit_fx = MisileHit.instance()
	new_hit_fx.global_position = global_position
	new_hit_fx.get_node("ExplosionParticles").process_material.color_ramp.gradient.colors[1] = spawner_color
	new_hit_fx.get_node("ExplosionParticles").process_material.color_ramp.gradient.colors[2] = spawner_color
	new_hit_fx.get_node("ExplosionParticles").set_emitting(true)
	new_hit_fx.get_node("SmokeParticles").set_emitting(true)
	new_hit_fx.get_node("BlastAnimated").play()
	Refs.node_creation_parent.add_child(new_hit_fx)


#	var new_misile_explosion = MisileExplosion.instance()
#	new_misile_explosion.global_position = global_position
#	new_misile_explosion.set_one_shot(true)
#	new_misile_explosion.process_material.color_ramp.gradient.colors[1] = spawner_color
#	new_misile_explosion.process_material.color_ramp.gradient.colors[2] = spawner_color
#	new_misile_explosion.set_emitting(true)
#	new_misile_explosion.get_node("ExplosionBlast").play()
#	Refs.node_creation_parent.add_child(new_misile_explosion)
	queue_free()


func _on_ActiveTimer_timeout() -> void:

	explode()
	for body in detect_area.get_overlapping_bodies():
		if body.has_method("on_hit") and body != spawner:
			body.on_hit(self, global_position)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	#	explode()
	#	active_timer.stop()
	pass


func _on_DetectArea_body_entered(body: Node) -> void:

	# ustavi ob trku s telesom
	if body != spawner:
		drop_direction = Vector2.ZERO

	# sproži val in detect_area shape
		if body.has_method("on_hit"):
			explode()
			# animacije
			#		animation_player.play("shockwave_mina")
			body.on_hit(self, global_position)
