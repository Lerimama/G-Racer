extends Path2D


export var is_enabled: bool = true
export (int, 0, 5) var checkpoints_count: int = 1 # 1 je ok tudi za 1 krog,  0 je samo, če res rabiš

var drivers_to_follow_count: int = 0
onready var tracker_template: PathFollow2D = $Tracker


func spawn_new_tracker(driver_to_follow: RigidBody2D):

	var tracker_new_color: Color = driver_to_follow.vehicle_color
	var new_tracker: PathFollow2D

	if drivers_to_follow_count == 0: # pomeni, da je notri samo original in ni bil še dupliciran
		tracker_template.tracking_target = driver_to_follow
		tracker_template.modulate = tracker_new_color
		tracker_template.checkpoints_count = checkpoints_count
		new_tracker = tracker_template
	else:
		new_tracker = tracker_template.duplicate()
		new_tracker.tracking_target = driver_to_follow
		new_tracker.modulate = tracker_new_color
		#		new_tracker.checkpoints_count = checkpoints_count ... vzame od templejta
		add_child(new_tracker)

	drivers_to_follow_count += 1

	return new_tracker
