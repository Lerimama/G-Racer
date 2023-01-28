extends Viewport

# assuming it's a child of a ViewportContainer
onready var child_viewport: Viewport = $Arena.get_texture().get_viewport()

func _process(delta: float) -> void:
    canvas_transform = child_viewport.canvas_transform
