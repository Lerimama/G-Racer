extends Camera2D


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	print ("Camera")
	print ("----------------------")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_TimeSlider_value_changed(value: float) -> void:
	Engine.time_scale = value # nedela
	print("time changed")
