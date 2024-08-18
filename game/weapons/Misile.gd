extends KinematicBody2D
class_name Misile


var spawned_by: Node
var spawned_by_color: Color
var spawned_by_speed: float

# gibanje
export var speed: float = 20.0

var misile_active: bool = true
var velocity: Vector2
var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
# var direction_start_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta
var acceleration_time = 2.0
var collision: KinematicCollision2D	
var misile_time: float = 0 # čas za domet
var dissarm_speed_drop: float = 3 # notri je to v kvadratni funkciji
var wiggle_direction_range: Array = [-24, 24] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var homming_target_position: Vector2
var new_misile_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var drop_position: Position2D = $DropPosition

onready var homming_detect: Area2D = $HommingArea
onready var collision_shape: CollisionShape2D = $MisileCollision
onready var vision_ray: RayCast2D = $RayCast2D

onready var MisileExplosion = preload("res://game/weapons/MisileExplosionParticles.tscn")
onready var MisileTrail = preload("res://game/weapons/MisileTrail.tscn")
onready var DropParticles = preload("res://game/weapons/MisileDropParticles.tscn")

onready var weapon_profile: Dictionary = Pro.weapon_profiles["misile"]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var max_speed: float = weapon_profile["speed"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var mass: float = weapon_profile["mass"]
onready var direction_start_range: Array = weapon_profile["direction_start_range"] # natančnost misile


func _ready() -> void:
	
	randomize()
	
	add_to_group(Ref.group_misiles)
	$Sprite.modulate = spawned_by_color
	collision_shape.disabled = true # da ne trka z avtorjem ... ga vključimo, ko raycast zazna izhod
		
#	Ref.sound_manager.play_sfx("misile_shoot")
	$Sounds/MisileShoot.play()	
	
	# set movement
	var random_range = rand_range(direction_start_range[0],direction_start_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	rotation += random_range # rotacija misile
	direction = Vector2(cos(rotation), sin(rotation))
	speed = speed + spawned_by_speed
	
	# spawn trail
	new_misile_trail = MisileTrail.instance()
	new_misile_trail.gradient.colors[2] = spawned_by_color
	new_misile_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_misile_trail)
		

					
func _physics_process(delta: float) -> void:
		
	misile_time += delta

	# pospeševanje
	if misile_time < lifetime:
		var accelaration_tween = get_tree().create_tween()
		accelaration_tween.tween_property(self ,"speed", max_speed, acceleration_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		new_misile_trail.add_points(trail_position.global_position)
	# bremzanje	
	elif misile_time > lifetime:
		speed -= pow(dissarm_speed_drop, 1.0) # deactivated_speed_drop na kvadrat
		speed = clamp(speed, 0.0, speed)
		new_misile_trail.add_points(trail_position.global_position)
		if speed <= 50.0:
			dissarm()
	
	# sledenje
	if is_homming == true: 
		direction = lerp(direction, global_position.direction_to(homming_target_position), 0.1) 	
		rotation = global_position.direction_to(homming_target_position).angle()
		
		if homming_detect.monitoring != true:
			homming_detect.monitoring = true
		elif homming_detect.monitoring == true:
			homming_detect.monitoring = false
		
	velocity = direction * speed
	move_and_slide(velocity) 
	
	# preverjam, če se še dotika avtorja
	if vision_ray.is_colliding():
		var current_collider = vision_ray.get_collider()
		if current_collider == spawned_by:
			collision_shape.disabled = true
		else:
			collision_shape.disabled = false
	else:
		collision_shape.disabled = false
			
	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision = get_slide_collision(0) # we wan't to take the first collision
		if collision.collider != spawned_by: # sam sebe lahko ubiješ
			explode()
			if collision.collider.has_method("on_hit"):
				collision.collider.on_hit(self) # pošljem node z vsemi podatki in kolizijo
		
		
#func collide():
#
#	modulate = Color.red
#	var current_collider = vision_ray.get_collider()
#	explode()
#	if current_collider.has_method("on_hit"):
#		if current_collider.is_in_group(Ref.group_enemies):
#			current_collider.on_hit(self)
#			print (current_collider)
#	velocity = Vector2.ZERO
	
				
func dissarm():
	
			
	# wigle
#	var wiggle: Vector2  
#	wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
#	transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)
##	transform.x = direction # random smer je določena ob štartu in ob deaktivaciji
#	velocity = transform.x * speed
#	position += velocity * delta
#	misile_active = false

	# drop particles
	var new_drop_particles: CPUParticles2D = DropParticles.instance()
	new_drop_particles.global_position = drop_position.global_position
	new_drop_particles.color = spawned_by_color
	new_drop_particles.z_index = z_index + Set.explosion_z_index
	new_drop_particles.set_one_shot(true)
	new_drop_particles.set_emitting(true)
	Ref.node_creation_parent.add_child(new_drop_particles)
	queue_free()
	
	if $Sounds/MisileFlight.is_playing():
		$Sounds/MisileFlight.stop()
	elif $Sounds/MisileShoot.is_playing():
		$Sounds/MisileShoot.stop()
	Ref.sound_manager.play_sfx("misile_dissarm")
	new_misile_trail.start_decay()
		
		
func explode():

	if $Sounds/MisileFlight.is_playing():
		$Sounds/MisileFlight.stop()
	elif $Sounds/MisileShoot.is_playing():
		$Sounds/MisileShoot.stop()
	Ref.sound_manager.play_sfx("misile_explode")
	new_misile_trail.start_decay()

	var new_misile_explosion = MisileExplosion.instance()
	new_misile_explosion.global_position = global_position
	new_misile_explosion.set_one_shot(true)
	new_misile_explosion.process_material.color_ramp.gradient.colors[1] = spawned_by_color
	new_misile_explosion.process_material.color_ramp.gradient.colors[2] = spawned_by_color
	new_misile_explosion.z_index = z_index + Set.explosion_z_index
	new_misile_explosion.set_emitting(true)
	new_misile_explosion.get_node("ExplosionBlast").play()
	Ref.node_creation_parent.add_child(new_misile_explosion)
	
	queue_free()
	
	
func _on_HommingArea_body_entered(body: Node) -> void:
	
	if body.is_in_group("Bolts") and body != spawned_by:
		is_homming = true
		homming_target_position = body.global_position
		$Sounds/MisileDetect.play()


func _on_MisileShoot_finished() -> void:
	print("konc")
	$Sounds/MisileFlight.play()
