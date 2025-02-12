extends Path2D


var agents_to_follow_count: int = 0

onready var orig_agent_tracker: PathFollow2D = $AgentTracker


func set_new_tracker(agent_to_follow: RigidBody2D):

	var tracker_new_color: Color = agent_to_follow.agent_color
	var new_tracker: PathFollow2D

	if agents_to_follow_count == 0: # pomeni, da je notri samo original in ni bil še dupliciran
		orig_agent_tracker.tracking_target = agent_to_follow
		orig_agent_tracker.modulate = tracker_new_color
		new_tracker = orig_agent_tracker
	else:
		new_tracker = orig_agent_tracker.duplicate()
		new_tracker.tracking_target = agent_to_follow
		new_tracker.modulate = tracker_new_color
		add_child(new_tracker)

	agents_to_follow_count += 1

	return new_tracker
