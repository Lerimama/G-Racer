extends KinematicBody2D

onready var navAgent = $NavigationAgent2D
onready var line = get_node("../Line2D")

var velocity = Vector2.ZERO
var _path: Array = []
	
	
func navigate(path: Array) -> void:
	_path = path
	if path.size(): # če pot obstaja 
		navAgent.set_target_location(path[0]) # target je prva točka
#	print("navigate")
#	print(path)
	
func _physics_process(delta: float) -> void:

	if _path.size() > 0:
		var current_pos= global_position
		var target = navAgent.get_next_location()
		velocity = current_pos.direction_to(target) * 100
		navAgent.set_velocity(velocity)
		
		if current_pos.distance_to(target) < 1: # v tem prmeru smo dovolj blizu
			_path.remove(0)
			line.points = _path
			if _path.size(): # če kaj ostane notri je cilj preostala točka
				navAgent.set_target_location(_path[0]) 
			velocity = Vector2.ZERO
#	move_and_slide(velocity)			
	
func get_agent_rid() -> RID:
	return navAgent.get_navigation_map()


func _on_NavigationAgent2D_velocity_computed(safe_velocity: Vector2) -> void:
#	var velocity = move_and_slide(safe_velocity)
	move_and_slide(safe_velocity)
