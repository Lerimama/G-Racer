extends Area2D
# bolt zazna podlago in prilagodi vožnjo glede na tip poglage

#export (Pros.SURFACE) var surface_type: int = 0
export var surface_type: int = 0 # preverim, da je isto kot v profilih SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}

onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_factor = Pros.surface_type_profiles[surface_type]["engine_power_factor"]


func _ready() -> void:
#	printt ("SURFACE", Pros.SURFACE.keys()[surface_type])
	pass
