extends Area2D


var surface_type: int = Pros.SURFACE_TYPE.CONCRETE

#onready var street_shape: Node2D = $StreetSSD
#onready var engine_power_factor = Pros.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
	pass
