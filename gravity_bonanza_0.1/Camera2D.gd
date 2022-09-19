extends Camera2D

var target

func _process(delta: float) -> void:
	
	# preverjamo, če target spoloh obstaja, da ne kličemo brezveze
	if target == null:
		return
	position = target.position
