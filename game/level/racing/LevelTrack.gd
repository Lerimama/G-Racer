extends Path2D


var drivers_to_follow_count: int = 0

onready var orig_tracker: PathFollow2D = $Tracker


func set_new_tracker(driver_to_follow: RigidBody2D):

	var tracker_new_color: Color = driver_to_follow.vehicle_color
	var new_tracker: PathFollow2D

	if drivers_to_follow_count == 0: # pomeni, da je notri samo original in ni bil še dupliciran
		orig_tracker.tracking_target = driver_to_follow
		orig_tracker.modulate = tracker_new_color
		new_tracker = orig_tracker
	else:
		new_tracker = orig_tracker.duplicate()
		new_tracker.tracking_target = driver_to_follow
		new_tracker.modulate = tracker_new_color
		add_child(new_tracker)

	drivers_to_follow_count += 1

	return new_tracker
