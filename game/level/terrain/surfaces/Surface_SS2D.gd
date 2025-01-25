extends Area2D
# bolt zazna podlago in prilagodi vožnjo glede na tip poglage

#export (Pfs.SURFACE) var surface_type: int = 0
export var surface_type: int = 0 # preverim, da je isto kot v profilih SURFACE {NONE, CONCRETE, NITRO, GRAVEL, HOLE, TRACKING}

var bodies_to_influence: Array = []
onready var surface_shape: Node2D = $SS2D_Shape_Closed
onready var engine_power_adon = Pfs.surface_type_profiles[surface_type]["engine_power_adon"]


func _ready() -> void:
#	printt ("SURFACE", Pfs.SURFACE.keys()[surface_type])
	pass


func _on_Surface_body_entered(body: Node) -> void:

	if "motion_manager" in body and not bodies_to_influence.has(body):
		body.motion_manager.engine_power_adon = engine_power_adon
		#		if body.is_in_group(Rfs.group_players):
		#			print ("surf", engine_power_adon)


func _on_Surface_body_exited(body: Node) -> void:

	bodies_to_influence.erase(body)

	if "motion_manager" in body:
		body.motion_manager.engine_power_adon = 0
