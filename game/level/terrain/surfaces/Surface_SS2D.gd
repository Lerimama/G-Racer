extends Area2D
# vehicle zazna podlago in prilagodi vožnjo glede na tip poglage

#export (Pfs.SURFACE) var surface_type: int = 0
export var surface_type: int = 0 # preverim, da je isto kot v profilih SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}

var bodies_to_influence: Array = []
onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_addon = Pfs.surface_type_profiles[surface_type]["engine_power_addon"]


func _ready() -> void:
#	printt ("SURFACE", Pfs.SURFACE.keys()[surface_type])
	pass


func _on_Surface_body_entered(body: Node) -> void:

	if "motion_manager" in body and not body in bodies_to_influence:
		var power_to_add: float
		# če je med 0 in 10 množim z max power, drugače, seštevam
		if engine_power_addon > 0 and engine_power_addon < 10:
			power_to_add = - body.motion_manager.max_engine_power * (1 - engine_power_addon)
		else:
			power_to_add = engine_power_addon

		body.motion_manager.engine_power_addon += power_to_add

		printt("max", body.motion_manager.max_engine_power, power_to_add)


func _on_Surface_body_exited(body: Node) -> void:

	bodies_to_influence.erase(body)

	if "motion_manager" in body:

		var power_to_add: float
		# če je med 0 in 10 množim z max power, drugače, seštevam
		if engine_power_addon > 0 and engine_power_addon < 10:
			power_to_add = body.motion_manager.max_engine_power * (1 - engine_power_addon)
		else:
			power_to_add = - engine_power_addon

		body.motion_manager.engine_power_addon += power_to_add

		printt("max", body.motion_manager.max_engine_power, power_to_add)
