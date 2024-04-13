extends Area2D


var drive_out_distance: float
onready var drive_out_line: Line2D = $DriveOutLine

func _ready() -> void:
	
	drive_out_distance = global_position.distance_to(drive_out_line.global_position)
	
	if not Set.debug_mode:
		drive_out_line.hide()
	
	
func _on_AreaFinish_body_entered(body: Node) -> void:
	# more bit ob prihodu, da ni možnosti, da greš ven na napačni strani in se šteje, da si prečkal
	if body.is_in_group(Ref.group_bolts):
		print("tuki")
		Ref.game_manager.on_finish_line_crossed(body)
	
 
