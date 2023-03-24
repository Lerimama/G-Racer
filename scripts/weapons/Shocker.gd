extends Node2D


var spawned_by: String
var spawned_by_color: Color

var drop_direction: Vector2 = -transform.x # rikverc na osi x
var drop_speed: float = 32
var drop_time: float = 1.0 # opredeli dolžino meta

var activate_time: float = 0.3
var deactivate_time: float = 10
var infuence_time: float = 5

var detect_active_size: Vector2 = Vector2(2.5, 2.5)
var detect_expand_size: Vector2 = Vector2(6.0, 6.0) # doseg partiklov

onready var detect_collision: CollisionShape2D = $DetectArea/CollisionShape2D
onready var shocker_sprite: AnimatedSprite = $ShockerSprite
onready var shock_shader: Sprite = $Shock
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var infuence_timer: Timer = $InluenceTimer
onready var deactivate_timer: Timer = $DeactivateTimer


func _ready() -> void:
	
	add_to_group("Shockers")
	modulate = spawned_by_color
	
	drop_direction = -transform.x # rikverc na osi x
	
	# disable detect area
	detect_collision.scale = Vector2.ZERO
	detect_collision.disabled = true # tako se ne zgodi prezgodnja interakcija in poruši vse animacije
	
	# drop mine
	var drop_tween = get_tree().create_tween()
	drop_tween.tween_property(self, "drop_speed", 0.0, drop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drop_tween.tween_callback(self, "activate")
	
	
func _process(delta: float) -> void:
	
	# motion
	global_position += drop_direction * drop_speed * delta
	
		 
func activate():
	
	# najprej aktiviramo detect area ...
	detect_collision.disabled = false
	detect_collision.scale = detect_active_size
	
	# loopanje spajta
	shocker_sprite.play("loop")
	
	deactivate_timer.set_wait_time(deactivate_time)
	deactivate_timer.start()


# catch			
func _on_DetectArea_body_entered(body: Node) -> void:
	
	deactivate_timer.stop()
	infuence_timer.set_wait_time(infuence_time)
	infuence_timer.start()
	
	# preverjam metodo ...
	if body.has_method("on_hit"): # && body.name != spawned_by:
		
		detect_collision.scale = detect_expand_size
		
		var modulate_tween = get_tree().create_tween()
		modulate_tween.tween_property(self, "modulate", Color.white, 0.35)
		
		animation_player.play("shockwave")
		shocker_sprite.stop()
		shocker_sprite.visible = false
		
		body.on_hit(self)
		

# release
func _on_DetectArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit") :#&& body.name != spawned_by:
		body.on_hit(self) # na plejerju se izbira ali je motion true ali false
		body.modulate.a = 1.0


# ustavi ob trku
func _on_CollisionArea_body_entered(body: Node) -> void:
	
	if body.name != spawned_by:
		drop_direction = Vector2.ZERO


func _on_InluenceTimer_timeout() -> void:
	
	detect_collision.scale = Vector2.ZERO
	queue_free()


func _on_DeactivateTimer_timeout() -> void:
	
	shocker_sprite.play("deactivate")
	
	var deactivate_tween = get_tree().create_tween() # tween dam zato, da se animacija lahko odvije
	deactivate_tween.tween_property(detect_collision, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	deactivate_tween.tween_callback(self, "queue_free")
	
