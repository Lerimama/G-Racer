extends Polygon2D


export (int) var crack_width: float = 1 setget _change_crack_width
var cracker_color: Color = Color.white
var crack_color: Color = Color.black

onready var cracker_shape: Polygon2D = $CrackerShape
var animate_cracks: bool = true

func _ready() -> void:
	
	color = crack_color
	cracker_shape.color = cracker_color
	
	cracker_shape.polygon = polygon
#	animate_cracks()
	self.crack_width = crack_width
		
			
func animate_cracks():
	
	self.crack_width = 0
	var preset_width: float = crack_width
	var crack_tween = get_tree().create_tween()
	crack_tween.tween_property(self, "crack_width", 0.05, 1) # ne vem zakaj tukaj deluje širina bolj kot deleže in na px
	
	
func _change_crack_width(new_width: float):
	
	var inset_polygons: Array = Geometry.offset_polygon_2d(cracker_shape.polygon, - new_width)
	if inset_polygons.size() == 1:
		cracker_shape.polygon = inset_polygons[0]	
		crack_width = new_width
	else:
		printt("Error! Offset to big ... multiple inset_polygons result", new_width)	
	
#	cracker_shape.color = cracker_color
#	print (crack_width)
