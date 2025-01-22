extends Area2D
# bolt zazna podlago in prilagodi vožnjo glede na tip poglage

#export (Pfs.SURFACE) var surface_type: int = 0
export var surface_type: int = 0 # preverim, da je isto kot v profilih SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}

onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_factor = Pfs.surface_type_profiles[surface_type]["max_engine_power_factor"]


func _ready() -> void:
#	printt ("SURFACE", Pfs.SURFACE.keys()[surface_type])
	pass

func _on_Surface_body_entered(body: Node) -> void:

	if "max_engine_power_factor" in body:
		body.max_engine_power_factor = engine_power_factor
		if body.is_in_group(Rfs.group_players):
			print ("surf", engine_power_factor, body.max_engine_power_factor)


func _on_Surface_body_exited(body: Node) -> void:
	if "max_engine_power_factor" in body:
		body.max_engine_power_factor = 1
		if body.is_in_group(Rfs.group_players):
			print ("de surf", engine_power_factor, body.max_engine_power_factor)
