extends Area2D


export var surface_shape_SSD_material: Resource # če je prazen ostane def material

var surface_type: int = Pro.LEVEL_AREA.AREA_TRACKING

onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var rear_ang_damp = Pro.surface_type_profiles[surface_type]["rear_ang_damp"]
onready var engine_power_factor = Pro.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
	
	# dodam glavni material
	if surface_shape_SSD_material:
		surface_shape.shape_material = surface_shape_SSD_material
