extends Line2D


var lifetime: Array = [2.0, 3.0] # vsaka linija bo imela lajfatjm v tem razponu
var min_spawn_distance: float = 2
var max_width: Array = [2,2] 
var max_points: int = 20

var stopped: bool = false

onready var decay_tween = $Decay


func _ready() -> void:
	
	set_as_toplevel(true)
	clear_points()
	
	 
func _process(delta: float) -> void:
	
	pass
	
	
func stop():
	stopped = true
	var random_lifetime: float = rand_range(lifetime[0], lifetime[1])
	decay_tween.interpolate_property(self ,"modulate", null, Color("#00000000"), random_lifetime, Tween.TRANS_EXPO, Tween.EASE_OUT )
#	decay_tween.interpolate_property(self ,"width", null, rand_range(max_width[0], max_width[1]), random_lifetime, Tween.TRANS_LINEAR, Tween.EASE_IN )
#	decay_tween.interpolate_property(self ,"modulate.a", 1, 0, rand_range(lifetime[0], lifetime[1]), Tween.TRANS_EXPO, Tween.EASE_OUT )
	decay_tween.start()
	
	
func add_points(current_bullet_position, at_pos: =  -1): # same arguments kot v originalni add_point funkciji
	
	# minimalni razmak med pikami
	# če je razdalja med trenutno piko in eno piko nazaj (-1) manjša od minimalne željene ... 
	if get_point_count() > 0 and current_bullet_position.distance_to(points[get_point_count() - 1]) < min_spawn_distance: 
		return
	
	# maksimalno število pik
	if get_point_count() > max_points:
		remove_point(0) # odstranimo pravo (tisto, ki je najbolj stara)
#		return 
		
	add_point(current_bullet_position, at_pos)


func _on_Decay_tween_all_completed() -> void:
	queue_free()
