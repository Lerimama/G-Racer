extends Line2D

export var limited_lifetime: bool = false
export var wildness: float = 0.1
export var min_spawn_distance: float = 10.0
export var gravity: = Vector2(0, -4)
export var gradient_col: Gradient = Gradient.new()
export var max_points: = 30
export var wind: Vector2 = Vector2(15, 5) # dodano za static
export var tick_speed: = 0.05	

var lifetime: Array = [1.2, 1.6]
var tick: = 0.0
var wild_speed: = 0.01
var point_age: = [0.0]

# dodano za static
var noise: OpenSimplexNoise = OpenSimplexNoise.new()
var wind_sway: = 0.0
var turbulence: = 1.0 # kontrola vetra
var tile_move_time: = 0.0 

onready var tween: = $Decay

func _ready() -> void:
	
	noise.octaves = 2 
	gradient = gradient_col
	set_as_toplevel(true)
	clear_points() # da se izogneš random bugu, ki se lahko pojavi
	
#	limited_lifetime = true
	if limited_lifetime:
		stop()
	
# ko se ustavi začne zginevat
func stop():
	
	tween.interpolate_property(self, "modulate:a", 1.0, 0.0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_CIRC, Tween.EASE_OUT) 
	tween.start()


func _process(delta: float) -> void:
	
	tile_move_time = wrapf(tile_move_time + delta * 20, 0, 2000) # wrepamo float vrednost večanja tile časa 
	
	if tick > tick_speed: # če je tik večji od hitrosti tika
		tick = 0 

		# grem čez vse pike (points[p]) in jim določimo ...
		for p in range (get_point_count()): 
			
			# preprečimo flickering na začetku ... tako da ne premikamo prve točke linije
			if p == get_point_count() - 1: # enačba za dobit index zadnje prizvedene točke
				continue
			
			point_age[p] += 5 * delta # staranje
			
			var noise_x = points[p].x + tile_move_time * turbulence # tile_move_time je da ni vedno na isti poziciji, turbulenca pa omogoča kontrolo moči efekta 
			var noise_y = points[p].y + tile_move_time * turbulence
			
			# implementacije noisa v veter oz gibanje dima
#			wind_sway = lerp(wind_sway, noise.get_noise_2d(noise_x, noise_y), 0.1) # lerpamo zato, da ne preskakuje, ker nosise trektura ni "tiled"
			wind_sway = lerp(wind_sway, noise.get_noise_2d(noise_x, noise_y) * (point_age[p] * 0.5), 0.2) # dodano staranje ("noisiniess"raste)
			
			var rand_vector: Vector2 = Vector2(rand_range(-wild_speed, wild_speed), rand_range(-wild_speed, wild_speed)) # dodam random vektor ki doda divjostz (random?)
			points[p] += gravity + (rand_vector * wildness * point_age[p]) + (wind * wind_sway) # gravitacija, rand vektor z wildness in starost ... plus veter

	else: # če ni večji, ga povečaj
		tick += delta
	
	
func add_points (point_pos: Vector2, at_pos: = -1): # za kontrolo dodajanja pik
	
	if get_point_count() > max_points:
		
		remove_point(0) # odstranimo pravo (tisto, ki je najbolj stara)
		point_age.pop_front()# potem premaknem starosti pik ... ne štekam najbolje
		return
	
	point_age.append(0.0) # v array starosti pik dodamo starost nove pike = 0
	
	add_point(point_pos, at_pos)
		
		
func _on_Decay_tween_all_completed() -> void:
	print("zbrisano")
	queue_free()
