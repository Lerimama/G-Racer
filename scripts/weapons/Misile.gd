extends Node2D


var spawned_by: String
var spawned_by_color: Color

# gibanje
export var speed: float = 140.00
export var accelaration: float # pospešek
export var max_accelaration: float = 10.0 # pospešek

var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var direction_start_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta

# domet
export var is_active_time_limit: float = 3.0 # zadetek ali domet
var is_active_time: float
var is_active: bool # zadetek ali domet
var deactivated_speed_drop_factor: float = 70

var wiggle_direction_range: Array = [-2, 2] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6

#homming
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var homming_precision: float = 0.03 # lerp utež ... manjša ko je, manj je natančna
var target_location: Vector2
#var homming_target: Object = null # null je zato ker je še nenastavljen
#var target: Object = null # null je zato ker je še nenastavljen

var new_misile_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var drop_position: Position2D = $DropPosition
onready var accelaration_tween: Tween = $AccelarationTween

onready var MisileExplosion = preload("res://scenes/weapons/MisileExplosionParticles.tscn")
onready var MisileTrail = preload("res://scenes/weapons/MisileTrail.tscn")
onready var DropParticles = preload("res://scenes/weapons/MisileDropParticles.tscn")

onready var target: Node


func _ready() -> void:
	
	add_to_group("Misiles")
	is_active = true
	randomize()
	$Sprite.modulate = spawned_by_color
	
	
	# spawn trail
	new_misile_trail = MisileTrail.instance()
	new_misile_trail.gradient.colors[3] = spawned_by_color
	Global.effects_creation_parent.add_child(new_misile_trail)
#	new_misile_trail.position = TrailPosition.position # ne dela kot bi prićakoval
	
	# random start dir
	var random_range = rand_range(direction_start_range[0],direction_start_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	direction = transform.x.rotated(random_range) # rotacija smeri ob štartu
	rotation = random_range # rotacija misile
	
	accelaration_tween.interpolate_property(self ,"accelaration", 0.0, max_accelaration, is_active_time_limit, Tween.TRANS_SINE, Tween.EASE_IN )
	accelaration_tween.start()
	
	
func _process(delta: float) -> void:
	
	print(is_active_time)
	is_active_time += 1.5 * delta # prirejeno, da je cirka sekunda na frejm
		
	transform.x = direction # random smer je določena ob štartu in ob deaktivaciji
	position += direction * speed * delta# * accelaration
	
	# pospeševanje in propad
	if is_active_time < is_active_time_limit:
		speed += 1 * accelaration
	elif is_active_time >= is_active_time_limit:
		dissarm()
		
	if is_homming == true: 
		direction = lerp(direction, global_position.direction_to(target_location), homming_precision) 
	
	new_misile_trail.add_points(trail_position.global_position)


func dissarm(): # po pretečenem dometu
	
	is_active = false
	is_homming = false
	
	# Wigle
	var wiggle: Vector2  
	wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
	transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)

	# upočasnitev
	speed -= 0.1 * deactivated_speed_drop_factor
	speed = clamp(speed, 0.0, speed)
	
	# pri kateri hitrosti izgine
	if speed <= 100:
		
		# drop particles
		var new_drop_particles: CPUParticles2D = DropParticles.instance()
		new_drop_particles.global_position = drop_position.global_position
		new_drop_particles.color = spawned_by_color
		new_drop_particles.set_one_shot(true)
		new_drop_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_drop_particles)
		
		new_misile_trail.start_decay()
		
		queue_free()
		
		
func _on_DetectArea_body_entered(body: Node) -> void:
	
	# čekiramo, da ni avtor
	if body.is_in_group("Bolts") && body.name != spawned_by:
		target_location = body.global_position
		is_homming = true


func _on_MisileArea_body_entered(body: Node) -> void:
	
	if body.name != spawned_by: # ni avtor?

		new_misile_trail.start_decay()
		
		var new_misile_explosion = MisileExplosion.instance()
		new_misile_explosion.global_position = global_position
		new_misile_explosion.set_one_shot(true)
		new_misile_explosion.process_material.color_ramp.gradient.colors[1] = spawned_by_color
		new_misile_explosion.process_material.color_ramp.gradient.colors[2] = spawned_by_color
		new_misile_explosion.set_emitting(true)
		Global.effects_creation_parent.add_child(new_misile_explosion)

		if body.has_method("on_hit"): 
			body.on_hit(self)
			
		queue_free()
