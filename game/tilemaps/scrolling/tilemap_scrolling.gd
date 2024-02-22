extends GameTilemap


var floor_cells_count_x: int = 0
var floor_cells_count_y: int

var floor_cells_count: Vector2 = Vector2.ZERO
var strays_in_top_area: Array = []
var stray_in_floor_area: Array = []

#func get_floor_width_and_height():
#
#	# odštejem robne tilete
#	floor_cells_count.x = get_used_rect().size.x - 2 # 40 fullskrin verzija
#	floor_cells_count.y = get_used_rect().size.y - 27 # samo spodnjega ... 20 fullskrin verzija
#
#	return floor_cells_count


func _on_TopArea_body_entered(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		strays_in_top_area.append(body)


func _on_TopArea_body_exited(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		strays_in_top_area.erase(body)
	

func _on_FloorArea_body_entered(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		stray_in_floor_area.append(body)

		
func _on_FloorArea_body_exited(body: Node) -> void:
	if body.is_in_group(Global.group_strays):
		stray_in_floor_area.erase(body)
		body.queue_free()
