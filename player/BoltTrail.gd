extends Line2D


signal BoltTrail_is_gone

var min_spawn_distance: float = 3

# points aging
var point_age: Array = [0.0] # array v katerega spravljamo starosti ob kreaciji
var point_aging_speed: int = 5 
var point_aging_limit: int = 7 # kontrola koliko stare pike odstranimo

# trail decay
var decay_time: float = 0.5 # time to disapear
var points_count_before: int
var points_count_after: int
var points_count_decay_start: int = 30 # limita kdaj se štarta decay tween

onready var decay_tween = $Decay


func _ready() -> void:
	
#	set_as_toplevel(true)
	clear_points() # da ne bo kakšnega errorja


func _process(delta: float) -> void:
		
	# POINT AGING
	
	# "points" array je array "vec2" pozicij pik, ki nima pripisane "starosti"
	# "point_age" je array v katerem ob vsaki kreaciji nove pike, na konec dodamo novo "0" starost ... ostale vrednosti povečamo za "faktor staranja"
	# "point_age" že po diofoltu vsebuje "0" vrednost (če je ni, se pojavlja error ker ni pike) ... to bi lahko zaobšel, pa nima smisla
	# "point_age" ima tako vedno eno vrednost več kot "points" array (vrednost 0) ... logično, saj 0 starost pomeni, da pika ne obstaja
	# skrbimo za usklajenost "point_age" s "points" array (difolt array, ki vsebuje vse pike)
	# "points_age" in "points" sta si obratna ... najstarejša pika je na koncu svojega arraya, najstarejša starost je na začetku svojega arraya
		
	# polnenje "point_age" arraya
	for p in range (get_point_count()): # toliko starosti, kot je pik
	
		# povečaj vsako vrednost v "points_age" za "stara starost + hitrost staranja * delta"
		point_age[p] += point_aging_speed * delta
		
		# odstranjevanje najstarejših pik
		if point_age[p] >= point_aging_limit:
			
			points_count_before = get_point_count()
			remove_point(0) # odstrani prvo nastalo piko (najstarejša)
			point_age.pop_front() # odstranimo sprednjo vrednost v arrayu ... zadnja dodana, torej "najstarejša" ... pop_front removes and returns the first element of the array.
			points_count_after = get_point_count()
					
			# dodajanje kaosa na pike
			# points[p] = points[p] + rand_vector * chaos_level * point_age[p]
		
			return # ta return je pomemben ... prepreči error ... nisem ziher zakaj ...
			# Exits a function and returns an optional value.
			# Ends the execution of a function and returns control to the calling function. Optionally, it can return a Variant value.

#	# ko se število točk zmanjšuje in je količina točk manjša od ... in 			
#	if points_count_after < points_count_before &&  get_point_count() < points_count_decay_start:
#		start_decay()
	pass
	

func start_decay():
#	modulate = Color.red
	decay_tween.interpolate_property(self ,"modulate:a", null, 0, decay_time, Tween.TRANS_EXPO, Tween.EASE_OUT )
	decay_tween.start()
	
	
func add_points(current_position, at_pos: =  -1): # dodaj piko na pozicijo bolta in na začetek arraya
	
	# minimalni razmak med pikami ... če je razdalja med trenutno piko in eno piko nazaj (-1) manjša od minimalne željene
	if get_point_count() > 0 and current_position.distance_to(points[get_point_count() - 1]) < min_spawn_distance: 
		return # vrni se na začetek fuinkcije ... posledično ne pride do add point kode
		
	point_age.append(0.0) # ob vsaki dodani piki, dodamo tudi novo starost "0" na konec "points_age"
	add_point(current_position, at_pos)


func _on_Decay_tween_all_completed() -> void:
#	emit_signal("BoltTrail_is_gone")
	
#	print ("KUFRI - Bolt Trail")
	queue_free()
	
