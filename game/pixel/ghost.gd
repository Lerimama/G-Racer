extends Area2D


signal ghost_target_reached(global_position)
signal ghost_detected_body (body)

var speed: float = 0
var max_speed: float = 0
var direction = Vector2.ZERO

var ghost_owner: KinematicBody2D
var teleporting_bodies: Array = []
var target_reached: float = false

onready var ghost_ray: RayCast2D = $RayCast2D
onready var glow_light: Light2D = $GlowLight
onready var cell_size_x: float = Global.current_tilemap.cell_size.x


func _ready() -> void:

	add_to_group(Global.group_ghosts)
	
		
func _physics_process(delta: float) -> void:
	
	global_position += direction * speed
	if not target_reached:
		speed = lerp(speed, max_speed, 0.015)
		
	ghost_ray.cast_to = direction * cell_size_x
	
	glow_light.color = modulate
	
	# skill ghost
	if ghost_ray.is_colliding():
		ghost_ray.get_collider() 
		emit_signal("ghost_detected_body", ghost_ray.get_collider() )


func _on_PixelGhost_body_exited(body: Node) -> void:
	
	# praznenje array kolajderjev
	if teleporting_bodies.has(body):
		teleporting_bodies.erase(body)
	
	# ko je prazno, zaključi teleporting
	if teleporting_bodies.empty():
		target_reached = true
		speed = 0
		global_position = Global.snap_to_nearest_grid(global_position)
		emit_signal("ghost_target_reached", self, global_position)
			

func _on_PixelGhost_body_entered(body: Node) -> void:
	
	# polnenje array kolajderjev
	if body.is_in_group(Global.group_strays):
		teleporting_bodies.append(body)
	elif body.is_in_group(Global.group_players) and not ghost_owner:
		teleporting_bodies.append(body)
	elif body.is_in_group(Global.group_tilemap):
		teleporting_bodies.append(body)
