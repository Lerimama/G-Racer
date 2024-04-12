extends Sprite


export var node_to_copy_name: String  = "NN"
var copied_node: Node2D
var shadow_direction: Vector2 = Vector2(1,0).rotated(deg2rad(-90)) # 0 levo, 180 desno, 90 gor, -90 dol  
var bolt_altitude = 30

func _ready() -> void:
	copied_node = get_parent().get_node(node_to_copy_name)
	texture = copied_node.texture

func _process(delta: float) -> void:
	
	global_position = copied_node.global_position - 30 * Vector2(1,0).rotated(deg2rad(-90))
	pass
