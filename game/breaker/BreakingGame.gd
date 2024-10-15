extends Node2D


# debug
var moving = true
onready var breaker: Node2D = $Breaker
onready var mouse_area: Area2D = $MouseArea
onready var shape_poly: Polygon2D = $MouseArea/Polygon2D
onready var collision_polygon_2d: CollisionPolygon2D = $MouseArea/CollisionPolygon2D


var power: float = 1
var breaking_bodiz: Array

func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("left_click"):
		# moving = not moving
		for body in breaking_bodiz:
#			body.on_hit(shape_poly.polygon, get_global_mouse_position())
			body.on_hit(shape_poly, get_global_mouse_position())
	elif Input.is_action_just_released("right_click"):
		# moving = not moving
		for body in breaking_bodiz:
#			body.on_hit(shape_poly.polygon, get_global_mouse_position())
			body.on_hit(shape_poly, get_global_mouse_position())


func _ready() -> void:
	for point in shape_poly.polygon:
		print (point)

func _process(delta: float) -> void:
	
	if Input.is_action_pressed("left_click"):
		shape_poly.scale += Vector2.ONE * delta
#		shape_poly.scale *= power
	elif Input.is_action_pressed("right_click"):
		shape_poly.scale -= Vector2.ONE * delta
#		shape_poly.scale -= delta * 0.1
#		shape_poly.scale *= power
	else:
		pass
	collision_polygon_2d.scale = shape_poly.scale
	if moving:
		breaker.global_position.x += 1
	
	mouse_area.position = get_global_mouse_position()
#	if not Input.is_action_pressed("left_click"):
#		print ("mouse pos", mouse_area.position)

func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		breaking_bodiz.append(body)
#		print("IN", body)


func _on_MouseArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit"):
		breaking_bodiz.erase(body)
#		print("OUT", body)
