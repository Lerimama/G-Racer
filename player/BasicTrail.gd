extends Line2D

export var limited_lifetime: bool = false
export var wildness: float = 0.0
export var min_spawn_distance: float = 0

var gravity: = Vector2.ZERO
var lifetime: Array = [1.0,2.0]
var tick_speed: = 0.01
var tick: = 0.0
var wild_speed: = 0.5
var point_age: = [0.0]

var spawn_position: Vector2 = Vector2.ZERO setget change_position

onready var tween: = $Decay

func _ready() -> void:
	
	set_as_toplevel(true)
#	clear_points() # da se izogneš random bugu, ki se lahko pojavi
	if limited_lifetime:
		tween.interpolate_property(self, "modulate:a", 1.0, 0.0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_CIRC, Tween.EASE_OUT) 
		tween.start()
	$engine_particles.set_one_shot(true)
	$engine_particles.set_emitting(true)
	
	
	
func _process(delta: float) -> void:
	
	
	if tick > tick_speed: # če je tik večji od hitrosti tika
#		print("tik 0")
		tick = 0 

		# grem čez vse pike in jim določimo ...
		for p in range (get_point_count()): 
			point_age[p] += 5 * delta # staranje
			var rand_vector: Vector2 = Vector2(rand_range(-wild_speed, wild_speed), rand_range(-wild_speed, wild_speed)) # dodam random vektor ki doda divjostz (random?)
			points[p] += gravity + (rand_vector * wildness * point_age[p]) # gravitacija, rand vektor z wildness in starost

	else: # če ni večji, ga povečaj
		tick += delta
		print("tik majhen")
	
	add_points(global_position,-1)
	print("get_point_count()" )
	print(get_point_count() )

func change_position(bolt_position):
	spawn_position = bolt_position
	
	
func add_points (point_pos: Vector2, at_pos: = -1): # za kontrolo dodajanja pik
	
	print("nova pika")
	print(point_pos)
	
	# razdalja med pikami
	# če so pike prisotne in je hkrati razdalja med trenutno piko in eno piko nazaj (-1) manjša od minimalne željene, ne naredi nič
	if get_point_count() > 0 and point_pos.distance_to(points[get_point_count() - 1]) < min_spawn_distance:
		return

	point_age.append(0.0) # v array starosti pik dodamo starost nove pike = 0
	
	add_point(point_pos, at_pos)
	print(add_point(point_pos, at_pos))
		
func _on_Decay_tween_all_completed() -> void:
#	print("zbrisano")
	queue_free()
