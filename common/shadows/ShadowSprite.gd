extends Sprite


export (NodePath) var shadow_owner_shape_path: String
export var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 7 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence
export var shadow_color: Color = Color.black

onready var shadow_owner_shape: Node2D# = get_node(shadow_owner_shape_path)
onready var shadow_owner: Node2D = get_parent()
onready var shadow_direction: Vector2 = Refs.game_manager.game_shadows_direction # odvisno od igre

# neu
var imitate_3d: bool = false

func _ready() -> void:

	add_to_group(Refs.group_shadows)

	if shadow_owner_shape_path:
		shadow_owner_shape = get_node(shadow_owner_shape_path)

	if shadow_owner_shape:
		texture = shadow_owner_shape.texture
		if shadow_owner_shape.region_enabled: # za atlas teksture
			region_enabled = true
			region_rect = shadow_owner_shape.region_rect
	else:
		hide()


func _process(delta: float) -> void:

	if shadow_owner_shape and visible:
		update_shadows()
#		shadow_direction = Refs.game_manager.game_shadows_direction
#		global_position = shadow_owner_shape.global_position - 10 * shadow_direction.rotated(deg2rad(180))
		# rotated je zato, da je LEFT res levo


func update_shadows():

	if node_height == 0 and node_elevation == 0:
		if visible:
			hide()
	else:
		modulate = shadow_color
		node_height = shadow_owner.height
		node_elevation = shadow_owner.elevation
		shadow_direction = Refs.game_manager.game_shadows_direction
		global_position = shadow_owner_shape.global_position - node_elevation * shadow_direction.rotated(deg2rad(180))
		if not visible:
			show()
