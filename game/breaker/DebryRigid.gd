extends RigidBody2D


enum ACTION {EXPLODE, FALL, SLIDE, SHATTER, DISSOLVE, DISINTEGRATE}
var debry_action: int = ACTION.FALL

var debry_polygon: PoolVector2Array # na spawn
var break_origin: Vector2 # na spawn
	
var debry_color: Color =Color.blue
var debry_center: Vector2

onready var debry_shape: Polygon2D = $DebryShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var outline_line: Line2D = $EdgeLine
onready var animation_player: AnimationPlayer = $AnimationPlayer

var anima_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	
	# copy points
	debry_shape.polygon = debry_polygon
	outline_line.points = debry_shape.polygon
	collision_shape.polygon = debry_shape.polygon
	
	# props
	debry_shape.color = debry_color
	debry_center = get_debry_center()
#	position += debry_center
#	debry_shape.position -=  debry_center
#	print(debry_center)
	return	
	match debry_action:
		ACTION.FALL:
			var fall_tween = get_tree().create_tween()
#			fall_tween.tween_property(debry_shape, "scale", Vector2.ONE * 3, 1)
#			fall_tween.tween_property(self, "debry_shape", Vector2.ONE * 1, 1)
			fall_tween.tween_property(self, "position", debry_center - break_origin, 1)
			fall_tween.tween_property(self, "modulate:a", 0, 1)
#			var fall: Animation = animation_player.get_animation("fall")
#			fall.track_set_key_value(0, 1, Vector2.ONE * 3)
#			animation_player.play("fall")
			

func get_properties():
	
	pass


func get_debry_center():
	
	# poiščem 4 skrajne točke oblike
	var max_left_point: Vector2
	var max_right_point: Vector2
	var max_up_point: Vector2
	var max_down_point: Vector2
	for point in debry_shape.polygon:
		if point.x > max_right_point.x or max_right_point.x == 0:
			max_right_point = point
		elif point.x < max_left_point.x or max_left_point.x == 0:
			max_left_point = point
		if point.y > max_down_point.y or max_down_point.y == 0:
			max_down_point = point
		elif point.y < max_up_point.y or max_up_point.y == 0:
			max_up_point = point
			
	var center_position: Vector2 = Vector2.ZERO
	for point in [max_left_point, max_up_point, max_right_point, max_down_point]:
		center_position += point
	center_position /= 4
	
	return center_position
	
		
				
#	var twiner = get_tree().create_tween()
#	twiner.tween_property(self, "modulate:a", 0, 0.5)
#	yield(twiner, "finished")
#	queue_free()
