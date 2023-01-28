extends Viewport

# assuming it's a child of a ViewportContainer
onready var parent_viewport: Viewport = get_parent().get_viewport()

func _process(delta: float) -> void:
    canvas_transform = parent_viewport.canvas_transform
