extends GridContainer


func _ready() -> void:
	for i in get_child_count():
		get_child(i).player_id = i+1
