extends Path2D


var bolts_to_follow_count: int = 0

onready var orig_bolt_tracker: PathFollow2D = $BoltTracker


func set_new_bolt_tracker(bolt_to_follow: KinematicBody2D):
	
	if bolts_to_follow_count == 0: # pomeni, da je notri samo original in ni bil še dupliciran
		orig_bolt_tracker.tracker_target = bolt_to_follow
	else:
		var new_tracker: PathFollow2D = orig_bolt_tracker.duplicate()
		new_tracker.tracker_target = bolt_to_follow
		add_child(new_tracker)
	bolts_to_follow_count += 1
	
