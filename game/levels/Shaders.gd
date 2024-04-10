extends Node2D


onready var texture_rect: TextureRect = $TextureRect
var floor_w: float # = texture_rect.rect_size.x
var floor_h: float

func _ready() -> void:


#	var floor_w: float = texture_rect.rect_size.x
#	var floor_h: float = texture_rect.rect_size.y
		
#	texture_rect.material.set_shader_param("node_w", texture_rect.rect_size.x)
#	texture_rect.material.set_shader_param("node_h", texture_rect.rect_size.y)

	# postavi shader rect
#	texture_rect.rect_position.x = get_parent().tilemap_floor.get_used_rect().position.x
#	texture_rect.rect_position.y = get_parent().tilemap_floor.get_used_rect().position.y
#	floor_w = get_parent().tilemap_floor.get_used_rect().size.x
#	floor_h = get_parent().tilemap_floor.get_used_rect().size.y
#	texture_rect.rect_size.x = floor_w
#	texture_rect.rect_size.y = floor_h
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#	texture_rect.material.set_shader_param("node_w", texture_rect.rect_size.x)
#	texture_rect.material.set_shader_param("node_h", texture_rect.rect_size.y)
#	texture_rect.material.set_shader_param("node_w", floor_w)
#	texture_rect.material.set_shader_param("node_h", floor_h)
	pass

#func size_to_level(pos: Vector2, size: Vector2):
#
##	texture_rect.rect_position = Vector2(1000,0)
#	texture_rect.rect_position = pos
#	texture_rect.rect_size = size	
##
#	texture_rect.material.set_shader_param("node_w", texture_rect.rect_size.x)
#	texture_rect.material.set_shader_param("node_h", texture_rect.rect_size.y)
#
#	pass
func _on_TextureRect_resized() -> void:
	
	texture_rect.material.set_shader_param("node_texture_size_x", texture_rect.rect_size.x)
	texture_rect.material.set_shader_param("node_texture_size_y", texture_rect.rect_size.y)
