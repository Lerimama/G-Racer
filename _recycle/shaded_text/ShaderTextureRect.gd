extends TextureRect


func _on_TerrainTextureRect_item_rect_changed() -> void:
	
	if material:
		material.set_shader_param("node_size", rect_size)
		printt("%s resized to: " % self.name, rect_size, material.get_shader_param("node_size"))
