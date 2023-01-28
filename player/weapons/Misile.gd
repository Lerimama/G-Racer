extends Node2D


signal Get_hit (hit_location, misile_velocity, misile_owner)

const MASS: = 10

var speed: float = 140.00
var accelaration: float = 0.8 # pospešek
var time: float
export var domet: float = 3

var start_direction_range: Array = [-0.1, 0.1] # variacija smeri ob izstrelitvi (trenutno jo upošteva tekom celega leta
var start_direction: Vector2 # variacija smeri ob izstrelitvi

var wiggle: Vector2 # variacija smeri med letom
var wiggle_range: Array = [-0.3, 0.3] 
var wiggle_freq: float = 0.5

var target: Object = null # null je zato ker je še nenastavljen
var target_location: Vector2 = Vector2(400,170)
var homming_precision: float = 0.01 # natančnost sledenja, lerp weight ... manjša ko je, manj je natančna

# states
var is_dead: = false # zadetek ali domet
var is_homming: bool = false # sledilka mode (ko zagleda tarčo v dometu)

onready var MisileTrail = $MisileTrail
onready var TrailPosition = $TrailPosition


func _ready() -> void:
	
	add_to_group("Misiles")
	set_as_toplevel(true)
	
	target = Global.node_creation_parent.get_node("Target")
	
	# random shoot direction 
	var random_range = rand_range(start_direction_range[0],start_direction_range[1]) # oblika variable zato, da isto rotiramo tudi misilo
	start_direction = transform.x.rotated(random_range) # rotacija smeri
	rotation = random_range # rotacija misile
	
		
func _process(delta: float) -> void:
	
	
	time += 1 * delta
	
	# če je raketa živa 
	if is_dead == false:
		
		transform.x = start_direction # misila gre smeri štartne smeri
		speed += 1 * accelaration
		position += transform.x * speed * delta
		
		# wiggle on
#		wiggle = transform.x.rotated(rand_range(wiggle_range[0],wiggle_range[1])) # izračun 
#		transform.x = lerp(wiggle, global_position.direction_to(position), wiggle_freq) # aplikacija v let
		
		# _temp za sprožanje homing efekta
		if Input.is_action_just_pressed("ui_down"):
			is_homming = true
		
		# homming on
		if is_homming:
			start_direction = lerp(start_direction, global_position.direction_to(target_location), homming_precision) 
		
		MisileTrail.add_points(TrailPosition.global_position)
		
		if time > domet:
			die()


func _on_MisileArea_body_entered(body: Node) -> void:
	
	return
	if body != owner and is_dead == false: # če telo ni od avtorja 
		die()
		
func die():

	is_dead = true
#	queue_free()
#	body.queue_free()
#	modulate.a = 0
	MisileTrail.stop()
	speed = 0.0
	
#	$AnimationPlayer.play("explosion")

	#kill the bullet but check for existance
#	if is_dead == false:
#		is_dead = true
#		MisileTrail.stop()
#		speed = 0.0
##		$AnimationPlayer.play("explosion")
