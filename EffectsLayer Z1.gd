extends CanvasLayer

# tukaj so vsi efekti (partikli, lajne ...) ... plejerji, metki in bombe, ... ovire, pickables
# namenjeno elementom, ki senčke ne morejo producirati drugače kot prek screen šejderja na viewportu
func _ready() -> void:
	
	AutoGlobal.effects_creation_layer = self
	print ("Effects Lejer Z1")
