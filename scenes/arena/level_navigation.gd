extends Node2D

onready var navigation_line: Line2D = $NavigationPath
onready var enemy = $Enemy


func _ready() -> void:
	pass
	Signals.connect("navigation_completed", self, "_on_Edge_navigation_completed")
#	Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
	
func _physics_process(delta: float) -> void:
	pass
	

func _on_Enemy_path_changed(path) -> void:
	navigation_line.points = path
	

func _on_Edge_navigation_completed(floor_cells: Array) -> void:
	call_deferred("pass_on", floor_cells) # če ni te poti, pride do erorja pri nalaganju  ... vsami igri verjetno tega ne bo
	print("JA")
	
func pass_on(floor_cells):
	enemy.navigation_cells = floor_cells


