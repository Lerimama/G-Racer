extends KinematicBody2D


# premaknjeno v Signals
# signal misile_destroyed

var spawned_by: String
var spawned_by_color: Color
var spawned_by_speed: float

# gibanje
export var speed: float = 20.0
export var max_speed: float = 150.0
var velocity: Vector2
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var direction_start_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta
var acceleration_time = 2.0
var collision: KinematicCollision2D	

var hit_damage: float = 10
var dissarm_speed_drop: float = 3 # notri je to v kvadratni funkciji
var wiggle_direction_range: Array = [-24, 24] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6

# domet
var time: float = 0
export var lifetime: float = 1.0 # zadetek ali domet

#homming
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var target_location: Vector2
onready var target: Node

var new_misile_trail: Object
onready var trail_position: Position2D = $TrailPosition
onready var drop_position: Position2D = $DropPosition

onready var homming_detect: Area2D = $HommingArea
onready var spawner_detect: Area2D = $DetectArea
onready var collision_shape: CollisionShape2D = $MisileCollision

onready var MisileExplosion = preload("res://scenes/weapons/MisileExplosionParticles.tscn")
onready var MisileTrail = preload("res://scenes/weapons/MisileTrail.tscn")
onready var DropParticles = preload("res://scenes/weapons/MisileDropParticles.tscn")


func _ready() -> void:
	
	randomize()
	
	add_to_group(Config.group_misiles)
	$Sprite.modulate = spawned_by_color
	collision_shape.disabled = true # da ne trka z avtorjem ... ga vključimo, ko raycast zazna izhod
		
	# set movement
	var random_range = rand_range(direction_start_range[0],direction_start_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2(cos(rotation), sin(rotation))
	speed = speed + spawned_by_speed
	
	# spawn trail
	new_misile_trail = MisileTrail.instance()
	new_misile_trail.gradient.colors[3] = spawned_by_color
	Global.effects_creation_parent.add_child(new_misile_trail)
	

func _physics_process(delta: float) -> void:
	
	time += delta
	
	# detect avtorja ... prva je zato, ker se zgodi hitreje
	if spawner_detect.get_overlapping_bodies().empty() == true:
		collision_shape.disabled = false
	else:
		for body in spawner_detect.get_overlapping_bodies():
			if body.name == spawned_by:
				collision_shape.disabled = true
	# pospeševanje
	if time < lifetime:
		var accelaration_tween = get_tree().create_tween()
		accelaration_tween.tween_property(self ,"speed", max_speed, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		new_misile_trail.add_points(trail_position.global_position)
	# bremzanje	
	elif time > lifetime:
		speed -= pow(dissarm_speed_drop, 1.0) # deactivated_speed_drop na kvadrat
		speed = clamp(speed, 0.0, speed)
		new_misile_trail.add_points(trail_position.global_position)
		if speed <= 50.0:
			dissarm()

	if is_homming == true: 
		direction = lerp(direction, global_position.direction_to(target_location), 0.1) 	
		rotation = global_position.direction_to(target_location).angle()
		
		if homming_detect.monitoring != true:
			homming_detect.monitoring = true
		elif homming_detect.monitoring == true:
			homming_detect.monitoring = false
		
	velocity = direction * speed
	move_and_slide(velocity) 
	
	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision = get_slide_collision(0) # we wan't to take the first collision
		if collision.collider.name != spawned_by:
			explode()
			if collision.collider.has_method("on_hit"):
				collision.collider.on_hit(self) # pošljem node z vsemi podatki in kolizijo
			
			
func dissarm():
	
	# wigle
#	var wiggle: Vector2  
#	wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
#	transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)
##	transform.x = direction # random smer je določena ob štartu in ob deaktivaciji
#	velocity = transform.x * speed
#	position += velocity * delta

	# drop particles
	var new_drop_particles: CPUParticles2D = DropParticles.instance()
	new_drop_particles.global_position = drop_position.global_position
	new_drop_particles.color = spawned_by_color
	new_drop_particles.set_one_shot(true)
	new_drop_particles.set_emitting(true)
	Global.effects_creation_parent.add_child(new_drop_particles)

	queue_free()
	
	new_misile_trail.start_decay()
		
		
func explode():

	new_misile_trail.start_decay()
	
	var new_misile_explosion = MisileExplosion.instance()
	new_misile_explosion.global_position = global_position
	new_misile_explosion.set_one_shot(true)
	new_misile_explosion.process_material.color_ramp.gradient.colors[1] = spawned_by_color
	new_misile_explosion.process_material.color_ramp.gradient.colors[2] = spawned_by_color
	new_misile_explosion.set_emitting(true)
	new_misile_explosion.get_node("ExplosionBlast").play()
	Global.effects_creation_parent.add_child(new_misile_explosion)
	
	Signals.emit_signal("misile_destroyed") # pošlje avtorju, da lahko izstreli novo
	
	queue_free()
	
	
func _on_HommingArea_body_entered(body: Node) -> void:
	
	if body.is_in_group("Bolts") and body.name != spawned_by:
		is_homming = true
		target = body
		target_location = body.global_position

