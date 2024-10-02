extends Sprite


export (NodePath) var shadow_casting_node_path: String
export var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 7 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence
export var shadow_color: Color = Color.black

onready var shadow_casting_node: Node2D = get_node(shadow_casting_node_path)
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] # odvisno od igre


func _ready() -> void:
	
	if shadow_casting_node:
		texture = shadow_casting_node.texture
		if shadow_casting_node.region_enabled: # za atlas teksture
			region_enabled = true
			region_rect = shadow_casting_node.region_rect
	else:
		hide()
	
	
func _process(delta: float) -> void:
	
	if shadow_casting_node and visible:
		update_shadows()
#		shadow_direction = Ref.game_manager.shadows_direction
#		global_position = shadow_casting_node.global_position - 10 * shadow_direction.rotated(deg2rad(180)) 
		# rotated je zato, da je LEFT res levo


func update_shadows():
	
	if node_height == 0 and node_elevation == 0:
		if visible:
			hide()
	else:
		modulate = shadow_color
		node_height = owner.height
		node_elevation = owner.elevation
		shadow_direction = Ref.game_manager.shadows_direction
		global_position = shadow_casting_node.global_position - node_elevation * shadow_direction.rotated(deg2rad(180)) 
		if not visible:
			show()
