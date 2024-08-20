extends Node2D
class_name Mina


var spawned_by: Node
var spawned_by_color: Color

var drop_direction: Vector2 = -transform.x # rikverc na osi x
var drop_time: float = 1.0 # opredeli dolžino meta

var shock_time: float = 5
var is_expanded: bool = false
var detect_expand_size: float = 3.5 # doseg šoka

onready var detect: Area2D = $DetectArea
onready var shocker_sprite: AnimatedSprite = $ShockerSprite
onready var shock_shader: ColorRect = $ShockShader
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var active_timer: Timer = $ActiveTimer

onready var weapon_profile: Dictionary = Pro.weapon_profiles[Pro.Weapons.MINA]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var speed: float = weapon_profile["speed"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var mass: float = weapon_profile["mass"]
onready var direction_start_range: Array = weapon_profile["direction_start_range"] # natančnost misile

onready var MisileExplosion = preload("res://game/weapons/MisileExplosionParticles.tscn")


func _ready() -> void:
	print("Mina")
	add_to_group(Ref.group_mine)
	modulate = spawned_by_color
	
	drop_direction = -transform.x # rikverc na osi x
	
#	Ref.sound_manager.play_sfx("mina_shoot")
	$Sounds/MinaShoot.play()
	
	# drop mine
	var drop_tween = get_tree().create_tween()
	drop_tween.tween_property(self, "speed", 0.0, drop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drop_tween.tween_callback(self, "activate")


func _physics_process(delta: float) -> void:
	
	global_position += drop_direction * speed * delta # motion
	
		 
func activate():
	
	detect.monitoring = true
	shocker_sprite.play("loop")
	active_timer.set_wait_time(lifetime)
	active_timer.start()

func explode():

	Ref.sound_manager.play_sfx("mina_explode")
	
	var new_misile_explosion = MisileExplosion.instance()
	new_misile_explosion.global_position = global_position
	new_misile_explosion.set_one_shot(true)
	new_misile_explosion.process_material.color_ramp.gradient.colors[1] = spawned_by_color
	new_misile_explosion.process_material.color_ramp.gradient.colors[2] = spawned_by_color
	new_misile_explosion.z_index = z_index + Set.explosion_z_index
	new_misile_explosion.set_emitting(true)
	new_misile_explosion.get_node("ExplosionBlast").play()
	Ref.node_creation_parent.add_child(new_misile_explosion)
#	queue_free()
	

func _on_CollisionArea_body_entered(body: Node) -> void:
	
	# ustavi ob trku	
	if body != spawned_by:
		drop_direction = Vector2.ZERO
		
	# sproži val in detect shape			
	if body.has_method("on_hit") and body.is_class("KinematicBody2D") and body != spawned_by:
		active_timer.stop()
		explode()
		animation_player.play("shockwave_mina")
					
		# ugasnem kar ne rabim
		shocker_sprite.stop()
		shocker_sprite.visible = false
	
		body.on_hit(self)
	
	
func _on_ActiveTimer_timeout() -> void:
	
	shocker_sprite.play("deactivate")
	
	var deactivate_tween = get_tree().create_tween() # tween dam zato, da se animacija lahko odvije
	deactivate_tween.tween_property(detect, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	deactivate_tween.tween_callback(self, "queue_free")

# kvefri
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
