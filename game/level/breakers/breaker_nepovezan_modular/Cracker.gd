extends Polygon2D


export (int) var crack_width: float = 1.5 setget _change_crack_width

var cracker_color: Color = Color.white
var crack_color: Color = Color.black

onready var crack: Polygon2D = $Crack


func _ready() -> void:

	color = cracker_color
	crack.color = crack_color

	crack.polygon = polygon
	self.crack_width = crack_width


func animate_cracks():

	self.crack_width = 0
	var preset_width: float = crack_width
	var crack_tween = get_tree().create_tween()
	crack_tween.tween_property(self, "crack_width", 0.05, 1) # ne vem zakaj tukaj deluje širina bolj kot deleže in na px


func _change_crack_width(new_width: float):

	var offset_polygons: Array = Geometry.offset_polygon_2d(crack.polygon, new_width)
	if offset_polygons.size() == 1:
		crack.polygon = offset_polygons[0]
		crack_width = new_width
	else:
		crack_width = new_width / 2
		#		printt("Cracker offset to big ... multiple inset_polygons result", crack_width)

#	cracker_shape.color = cracker_color
#	print (crack_width)
