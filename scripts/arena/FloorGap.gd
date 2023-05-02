extends Area2D

signal bolt_detected (Bolt)


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_FloorGap_body_entered(body: Node) -> void:
	emit_signal("bolt_detected", body) # pošljem
	if body is Bolt:
		body.modulate = Color.red
		body.engine_power = body.engine_power/2


func _on_FloorGap_body_exited(body: Node) -> void:
	if body is Bolt:
		body.modulate = Color.white
