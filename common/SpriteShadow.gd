extends Sprite


export (NodePath) var shadow_casting_node_path: String
export var node_height: float = 0 # debelina pomeni debelino sence
export var node_elevation: float = 30 # dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.5 

onready var shadow_casting_node: Node2D = get_node(shadow_casting_node_path)
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] # odvisno od igre


func _ready() -> void:
	
	if shadow_casting_node:
		node_height = shadow_casting_node.get_parent().height
		node_elevation = shadow_casting_node.get_parent().elevation
		
		texture = shadow_casting_node.texture
		if shadow_casting_node.region_enabled: # za atlas teksture
			region_enabled = true
			region_rect = shadow_casting_node.region_rect
	else:
		printerr ("No shadow casting node on: ", self)
	
	
func _process(delta: float) -> void:
	
	if shadow_casting_node:
		global_position = shadow_casting_node.global_position - node_elevation * shadow_direction.rotated(deg2rad(180)) 
		# rotated je zato, da je LEFT res levo

