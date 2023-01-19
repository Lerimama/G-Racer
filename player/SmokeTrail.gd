extends Line2D

export var limited_lifetime: bool = false
export var wildness: float = 3.0
export var min_spawn_distance: float = 10.0
export var gravity: = Vector2.ZERO
export var gradient_col: Gradient = Gradient.new()


var lifetime: Array = [1.0, 2.0]
var tick_speed: = 0.5	
var tick: = 0.0
var wild_speed: = 0.1
var point_age: = [0.0]

onready var tween: = $Decay

var stopped: = false # za kontrolo po zadeku

func _ready() -> void:
	
	
	gradient = gradient_col
	set_as_toplevel(true)
	clear_points() # da se izogneš random bugu, ki se lahko pojavi
	
#	limited_lifetime = true
	if limited_lifetime:
		stop()
	
# ko se ustavi začne zginevat
func stop():
	stopped = true
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_CIRC, Tween.EASE_OUT) 
	tween.start()

func start():
	stopped = false
	gradient = gradient_col
	modulate.a = 1.0
	
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_CIRC, Tween.EASE_OUT) 
	tween.start()


func _process(delta: float) -> void:
	
#	print(stopped)
	
	if tick > tick_speed: # če je tik večji od hitrosti tika
		tick = 0 

		# grem čez vse pike in jim določimo ...
		for p in range (get_point_count()): 
			point_age[p] += 5 * delta # staranje
			var rand_vector: Vector2 = Vector2(rand_range(-wild_speed, wild_speed), rand_range(-wild_speed, wild_speed)) # dodam random vektor ki doda divjostz (random?)
			points[p] += gravity + (rand_vector * wildness * point_age[p]) # gravitacija, rand vektor z wildness in starost
		
		if stopped == true: # barve ob zadetku gradienta se spremenijo ... nastavi gradient "local to scene"
			gradient.offsets[2] = clamp(gradient.offsets[2] + 0.04, 0.0, 0.99)
			gradient.offsets[1] = clamp(gradient.offsets[1] + 0.04, 0.0, 0.98)
			gradient.colors[2] = lerp(gradient.colors[2], gradient.colors[1], 0.1)
			gradient.colors[3] = lerp(gradient.colors[3], gradient.colors[0], 0.2)
			
			width += 5
			
			
	else: # če ni večji, ga povečaj
		tick += delta
	
	
func add_points (point_pos: Vector2, at_pos: = -1): # za kontrolo dodajanja pik
	
	# razdalja med pikami
	# če so pike prisotne in je hkrati razdalja med trenutno piko in eno piko nazaj (-1) manjša od minimalne željene, ne naredi nič
	if get_point_count() > 0 and point_pos.distance_to(points[get_point_count() - 1]) < min_spawn_distance:
		return
	
	point_age.append(0.0) # v array starosti pik dodamo starost nove pike = 0
	
	add_point(point_pos, at_pos)
		
		
func _on_Decay_tween_all_completed() -> void:
#	print("zbrisano")
	queue_free()
	pass
