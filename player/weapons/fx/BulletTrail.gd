extends Line2D


var lifetime: Array = [2.0, 3.0] # vsaka linija bo imela lajfatjm v tem razponu
var min_spawn_distance: float = 3
var max_width: Array = [2,2] 
var max_points: int = 32
var pause_too_free: int
var trail_active: bool

onready var decay_tween = $Decay

#func _process(delta: float) -> void:
#
#	if trail_active == false:
		


func _ready() -> void:
	
	clear_points()
	trail_active = true
	randomize()
	
	
	
func start_decay():
	trail_active = false
	print("decay")
	# ko se ustavi grejo točke stran
	for p in get_point_count():
		remove_point(0)	
		print(get_point_count())
	if get_point_count() == 0:
		pass
#		print("KUEFRI - BlastTrail")
#		queue_free()
		modulate.a = 0
	
	var random_lifetime: float = rand_range(lifetime[0], lifetime[1])
	decay_tween.interpolate_property(self ,"modulate:a", null, 0, 1, Tween.TRANS_EXPO, Tween.EASE_OUT )
	decay_tween.start()

	
func add_points(current_blast_position, at_pos: =  -1): # same arguments kot v originalni add_point funkciji
	
	if get_point_count() > 0 and current_blast_position.distance_to(points[get_point_count() - 1]) < min_spawn_distance: 
		return
	
	# maksimalno število pik
	if get_point_count() > max_points:
		remove_point(0) # odstranimo prvo narejeno piklo (tisto, ki je najbolj stara)
#		return 
		
	add_point(current_blast_position, at_pos)


func _on_Decay_tween_all_completed() -> void:
	print ("KUEFRI - Bullet trail")
	queue_free()
