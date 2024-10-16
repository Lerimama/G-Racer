extends Node2D


# debug
var moving = false
onready var breaker: Node2D = $Breaker
onready var slicer_area: Area2D = $SlicerArea
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D
onready var slicing_poly: Polygon2D = $SlicerArea/SlicingPoly


var power: float = 1
var breaking_bodiz: Array

func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("left_click"):
#		moving = not moving
		for body in breaking_bodiz:
			body.on_hit(slicing_poly, get_global_mouse_position())
	elif Input.is_action_just_released("right_click"):
#		moving = not moving
		for body in breaking_bodiz:
			body.on_hit(slicing_poly, get_global_mouse_position())


func _ready() -> void:
	for point in slicing_poly.polygon:
		print (point)

func _process(delta: float) -> void:
	
	if Input.is_action_pressed("left_click"):
		slicing_poly.scale += Vector2.ONE * delta
	elif Input.is_action_pressed("right_click"):
		slicing_poly.scale -= Vector2.ONE * delta
	collision_shape.scale = slicing_poly.scale
	
	if moving:
		breaker.global_position.x += 1
	slicer_area.position = get_global_mouse_position()

func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		breaking_bodiz.append(body)
#		print("IN", body)


func _on_MouseArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit"):
		breaking_bodiz.erase(body)
#		print("OUT", body)
