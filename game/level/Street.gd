extends Area2D


export var street_shape_SSD_material: Resource # če je prazen ostane def material

var surface_type: int = Pro.SURFACE_TYPE.PLAIN

onready var street_shape: Node2D = $StreetSSD
onready var engine_power_factor = Pro.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
	
	# dodam glavni material
	if street_shape_SSD_material:
		street_shape.shape_material = street_shape_SSD_material
