extends PathFollow2D


var tracking_target: Vehicle = null
var checkpoints_count: int = 0 # track na spawn

var all_checkpoints: Array
var checked_checkpoints: Array
var all_checkpoints_reached: bool = false
#var checked_unit_positions: Array


func _ready() -> void:

	for count in checkpoints_count: # 1 je 0 in je cilj in ne čekpoint
		var checkpoint_unit_on_curve: float = 1 * (count + 1) / float(checkpoints_count + 1)
		all_checkpoints.append(checkpoint_unit_on_curve)


func _physics_process(delta: float) -> void:

	if tracking_target and is_instance_valid(tracking_target):
		var racing_curve: Curve2D = get_parent().get_curve()
		var target_offset: float = racing_curve.get_closest_offset(tracking_target.global_position)
		offset = target_offset

	for checkpoint in all_checkpoints:
		if unit_offset > checkpoint:
			if not checkpoint in checked_checkpoints:
				checked_checkpoints.append(checkpoint)


	all_checkpoints_reached = true
	for checkpoint in all_checkpoints:
		if not checkpoint in checked_checkpoints:
			all_checkpoints_reached = false
	#	if all_checkpoints_reached:
	#		checked_checkpoints.clear() ... cleara GM na finish crossed
