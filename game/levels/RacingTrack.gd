extends Path2D


var bolts_to_follow_count: int = 0

onready var orig_bolt_follower: PathFollow2D = $BoltFollower


func set_new_bolt_follower(bolt_to_follow: KinematicBody2D):
	
	if bolts_to_follow_count == 0: # pomeni, da je notri samo original in ni bil še dupliciran
		orig_bolt_follower.follower_target = bolt_to_follow
	else:
		var new_follower: PathFollow2D = orig_bolt_follower.duplicate()
		new_follower.follower_target = bolt_to_follow
		add_child(new_follower)
	bolts_to_follow_count += 1
	
