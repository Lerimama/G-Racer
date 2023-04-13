extends CanvasLayer

# tukaj so vsa "fizična telesa" ... plejerji, metki in bombe, ... ovire, pickables
# "shadows" dodaja senčke (prekko original objekta)
# "colors" dodaja barvo orignal objekta prek senčke

func _ready() -> void:
	print ("Plejer Lejer Z2")
	Global.node_creation_parent = self

