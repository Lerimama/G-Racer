
extends StaticBody2D

# shadows
export var height: float = 50 setget _change_shape_height
export var elevation: float = 0
export var transparency: float = 1
export var shadow_alpha: float = 0.2
export var shadow_color: Color = Color.black

var use_shader_shadow: bool = false
# terrain je vedno na tleh
#export var shape_on_floor: bool =  true
# shadow shader ma napako, ker se izrisuje samo za vidno ... če objekt ni na ekranu, senčke sploh ni
#export var shadow_casting_color: Color = Color.green
var shadow_casting_color: Color = Color.green

#var shadow_color:
onready var object_shape: Node2D = $ObjectShapeSSD
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var shadow_direction: Vector2 = Refs.game_manager.game_settings["shadows_direction"] setget _change_shadow_dir # poberi iz igre
onready var shadow_shader_rect: ColorRect = $ShadowShader


func _ready() -> void:
	pass


func _change_shape_height(new_height: float):

	height = new_height
	if has_node("Shadow"): # start error prevent
		get_node("Shadow").position = shadow_direction * height
		if new_height == 0:
			get_node("Shadow").modulate.a = 0
		else:
			get_node("Shadow").modulate.a = shadow_alpha


func _change_shadow_dir(new_direction: Vector2):

	shadow_direction = new_direction
	if has_node("Shadow"):
		get_node("Shadow").position = shadow_direction * height
	elif use_shader_shadow:
		shadow_shader_rect.material.set_shader_param("shadow_direction", shadow_direction)


func _on_EdgeShadows_resized() -> void:
	$ShadowShader.material.set_shader_param("node_size", $ShadowShader.rect_size)
	pass # Replace with function body.
