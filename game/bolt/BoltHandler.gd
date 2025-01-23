extends Node

enum MOTION {ENGINES_OFF, IDLE, FWD, REV, DISARRAY, TILT, FREE_ROTATE, DRIFT, GLIDE} # DIZZY, DYING glede na moč motorja
#enum MOTION {ENGINES_OFF, IDLE, FWD, REV, TILT, FREE_ROTATE, DRIFT, GLIDE, DISARRAY} # DIZZY, DYING glede na moč motorja
var motion: int = MOTION.IDLE setget _change_motion
#var free_motion_type: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke
var free_motion_type: int = MOTION.FREE_ROTATE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.DRIFT # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.GLIDE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.TILT # presetan motion, ko imaš samo smerne tipke

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass



func _motion_machine():
	pass
func _change_motion(new_motion: int):
	pass
#
