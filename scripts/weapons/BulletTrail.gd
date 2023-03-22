extends Line2D


var min_spawn_distance: float = 1
var max_points: int = 70
var remove_point_interval: float = 0.005 # faktor izginjanja ... manjši pomeni, da bo hitreje ... uravnoteže s številom pik
var max_width: float

onready var decay_tween = $Decay


func _ready() -> void:
	
	clear_points()
	randomize()
	
	
func start_decay(current_bullet_position, at_pos: =  -1): # kličem iz parenta
	
	add_point(current_bullet_position, at_pos)
	
	for p in get_point_count():
		
		# remove points
		if get_point_count() > 0:
			yield(get_tree().create_timer(remove_point_interval / get_point_count()), "timeout")
			remove_point(0)	
		else:
			print("KUFRI - BlastTrail")
			queue_free()
	
	
func add_points(current_bullet_position, at_pos: =  -1): # same arguments kot v originalni add_point funkciji
	
	if get_point_count() > 0 and current_bullet_position.distance_to(points[get_point_count() - 1]) < min_spawn_distance: 
		return
	
	# maksimalno število pik
	if get_point_count() > max_points:
		remove_point(0) # odstranimo prvo narejeno piklo (tisto, ki je najbolj stara)
		
	add_point(current_bullet_position, at_pos)


func _on_Decay_tween_all_completed() -> void:
#	print ("KUFRI - Bullet trail")
#	queue_free()
	pass
