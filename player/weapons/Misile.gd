extends Node2D


signal Get_hit (hit_location, misile_velocity, misile_owner)

var spawned_by: String

# gibanje
export var speed: float = 140.00
export var accelaration: float # pospešek
export var max_accelaration: float = 10.0 # pospešek

var direction: Vector2 # za variacijo smeri (ob izstrelitvi in med letom)
var direction_start_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta

var wiggle_direction_range: Array = [-2, 2] # uporaba ob deaktivaciji
var wiggle_freq: float = 0.6

# domet
export var is_active_time: float = 10.0 # zadetek ali domet
var is_active: bool# zadetek ali domet
var time: float
var deactivated_speed_drop_factor: float = 50

#homming
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)
var homming_precision: float = 0.03 # lerp utež ... manjša ko je, manj je natančna
#var homming_target: Object = null # null je zato ker je še nenastavljen
var target_location: Vector2
#var target: Object = null # null je zato ker je še nenastavljen

var new_misile_trail: Object

#onready var detect_area_collision = $DetectArea/CollisionShape2D
onready var trail_position: Position2D = $TrailPosition
onready var drop_position: Position2D = $DropPosition
onready var accelaration_tween: Tween = $AccelarationTween

onready var MisileExplosion = preload("res://player/weapons/fx/MisileExplosionParticles.tscn")
onready var MisileTrail = preload("res://player/weapons/fx/MisileTrail.tscn")
onready var DropParticles = preload("res://player/weapons/fx/MisileDropParticles.tscn")

onready var target: Node


func _ready() -> void:
	
	add_to_group("Misiles")
	is_active = true
	randomize()
	
	
	# spawn trail
	new_misile_trail = MisileTrail.instance()
	AutoGlobal.effects_creation_parent.add_child(new_misile_trail)
#	new_misile_trail.position = TrailPosition.position # ne dela kot bi prićakoval
	
	# random start dir
	var random_range = rand_range(direction_start_range[0],direction_start_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	direction = transform.x.rotated(random_range) # rotacija smeri ob štartu
	rotation = random_range # rotacija misile
	
	accelaration_tween.interpolate_property(self ,"accelaration", 0.0, max_accelaration, is_active_time, Tween.TRANS_SINE, Tween.EASE_IN )
	accelaration_tween.start()

		
func _process(delta: float) -> void:
	
	time += 1.5 * delta # prirejeno, da je cirka sekunda na frejm
		
	transform.x = direction # random smer je določena ob štartu in ob deaktivaciji
	
	# pospeševanje ko je aktivna 
	if time < is_active_time:
		speed += 1 * accelaration
	
	# zaviranje ko propade 
	elif time >= is_active_time:
		
		is_active = false
		
		# Wigle
		var wiggle: Vector2  
		wiggle = transform.x.rotated(rand_range(wiggle_direction_range[0],wiggle_direction_range[1]))
		transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq)

		# upočasnitev
		speed -= 0.05 * deactivated_speed_drop_factor
		speed = clamp(speed, 0.0, speed)
		
		# pri kateri hitrosti izgine
		if speed <= 100:
			dissarm()

	position += direction * speed * delta# * accelaration
	
	# homming
	if is_homming == true:
		direction = lerp(direction, global_position.direction_to(target_location), homming_precision) 
		
	# add points to trail
	new_misile_trail.add_points(trail_position.global_position)


func dissarm(): # po pretečenem dometu
	
	# drop particles
	var new_drop_particles: CPUParticles2D = DropParticles.instance()
	new_drop_particles.global_position = drop_position.global_position
	new_drop_particles.set_emitting(true)
	AutoGlobal.effects_creation_parent.add_child(new_drop_particles)
	
	
func explode(): 
	
	# explosion particles
	var new_misile_explosion = MisileExplosion.instance()
	new_misile_explosion.global_position = global_position
	new_misile_explosion.set_one_shot(true)
	new_misile_explosion.set_emitting(true)
	AutoGlobal.effects_creation_parent.add_child(new_misile_explosion)
		
		
func _on_DetectArea_body_entered(body: Node) -> void:
	
	# čekiramo, da ni avtor
	if body.is_in_group("Players") && body.name != spawned_by:
		target_location = body.global_position
		is_homming = true


func _on_MisileArea_body_entered(body: Node) -> void:
	
	# čekiramo, da ni vtor
	if body.name != spawned_by:
		if body.has_method("on_hit_by_misile"): 
			explode()
			body.on_hit_by_misile()
		
		dissarm()
		new_misile_trail.start_decay()
#		print ("KUFRI - Misile")
		queue_free()
