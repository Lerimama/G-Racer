extends Area2D


export var surface_shape_SSD_material: Resource # če je prazen ostane def material

var old_surface_type: int = Pros.SURFACE.HOLE
export (Pros.SURFACE) var surface_type: int = 0

onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_factor = Pros.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
	printt ("SURFACE", Pros.SURFACE.keys()[surface_type])
	# dodam glavni material
	if surface_shape_SSD_material:
		surface_shape.shape_material = surface_shape_SSD_material
