extends Area2D


export var surface_shape_SSD_material: Resource # če je prazen ostane def material

var surface_type: int = Pro.SURFACE_TYPE.NITRO

onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_factor = Pro.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
	
	# dodam glavni material
	if surface_shape_SSD_material:
		surface_shape.shape_material = surface_shape_SSD_material
