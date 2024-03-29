extends Area2D


func _on_AreaFinish_body_entered(body: Node) -> void:
	# more bit ob prihodu, da ni možnosti, da greš ven na napačni strani in se šteje, da si prečkal
	
	if body.is_in_group(Ref.group_bolts):
		Ref.game_manager.on_finish_line_crossed(body)
	
 
