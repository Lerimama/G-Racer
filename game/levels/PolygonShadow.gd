extends Polygon2D


export (NodePath) var shadow_casting_polygon_path: String
export var node_height: float = 0 # debelina pomeni debelino sence
export var node_elevation: float = 30 # dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.5 

#export var shadow_direction = Vector2.ONE# setget _update_shadow
onready var shadow_casting_node: Node2D = get_node(shadow_casting_polygon_path)
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] # odvisno od igre


func _ready() -> void:
#	shadow_direction = Ref.game_manager.game_settings["shadows_direction"] 
	if shadow_casting_node:
#		node_height = shadow_casting_node.get_parent().height
#		node_elevation = shadow_casting_node.get_parent().elevation
		
		
		# naberem skrajne štiritočke iz katerih podem manipuliram senco
		var shadow_polygon: Array = inject_new_corners(shadow_casting_node.polygon)
		polygon = shadow_polygon
		
	else:
		printerr ("No shadow casting node on: ", self)
		
func inject_new_corners(polygon_to_upgrade: Array):
#		shadow_direction = Vector2 (-1,1)
		# če je poligon kvadrat (naredi še iskanje skrajnih točke, če ni 
		# štimam jo v smeri in na distanci
		position = shadow_direction * node_elevation
		
		# opredelim osnovno smer sence
		# DOWN RIGHT
		if shadow_direction.x >= 0 and shadow_direction.y >= 0:
			# apliciram nove pike v array pik in ga prenesem v polygon sence
			polygon_to_upgrade.insert(1, polygon_to_upgrade[1] - shadow_direction * node_elevation)
			polygon_to_upgrade.insert(5, polygon_to_upgrade[4] - shadow_direction * node_elevation) # pri indexu upoštevam že dodanega
		# DOWN LEFT
		elif shadow_direction.x < 0 and shadow_direction.y >= 0:
			polygon_to_upgrade.insert(1, polygon_to_upgrade[0] - shadow_direction * node_elevation)
			polygon_to_upgrade.insert(3, polygon_to_upgrade[3] - shadow_direction * node_elevation)
		# UP RIGHT
		elif shadow_direction.x >= 0 and shadow_direction.y < 0:
			polygon_to_upgrade.insert(3, polygon_to_upgrade[2] - shadow_direction * node_elevation)
			polygon_to_upgrade.insert(5, polygon_to_upgrade[0] - shadow_direction * node_elevation)
		# UP LEFT
		elif shadow_direction.x < 0 and shadow_direction.y < 0:
			polygon_to_upgrade.insert(2, polygon_to_upgrade[1] - shadow_direction * node_elevation)
			polygon_to_upgrade.insert(4, polygon_to_upgrade[4] - shadow_direction * node_elevation)
		
		
		return polygon_to_upgrade

	
#
#func _process(delta: float) -> void:
#
#	if shadow_casting_node:
#		var shadow_polygon: Array = inject_new_corners(shadow_casting_node.polygon)
#		polygon = shadow_polygon
#
#
#func _update_shadow(new_direction: Vector2):
#	if shadow_casting_node:
#
#		shadow_direction = new_direction
#
#		var shadow_polygon: Array = inject_new_corners(shadow_casting_node.polygon)
#		polygon = shadow_polygon
