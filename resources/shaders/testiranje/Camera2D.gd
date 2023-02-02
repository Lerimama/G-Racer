extends Camera2D


onready var target: Sprite = $ViewportShader

func _ready() -> void:
	print ("Yo")

	set_process(true)

func _process(delta: float) -> void:
	
	# preverjamo, če target spoloh obstaja, da ne kličemo brezveze
	if target == null:
		return
	global_position = target.global_position
	print(target.global_position)
