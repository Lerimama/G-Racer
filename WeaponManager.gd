extends Node


var bullet = preload("res://weapons/Bullet.tscn")
var misile = preload("res://weapons/Misile.tscn")


func _ready() -> void:

	Global.weapon_manager = self


func create_bullet(shooting_player_index: int, shooting_player_color: Color, shooting_player_position: Vector2, shooting_player_rotation: float):

	var new_bullet = bullet.instance()
	new_bullet.set_name("p%s_owned" % shooting_player_index) # dodam, ker je potem lažje dodati skore
	new_bullet.bullet_color = shooting_player_color
	new_bullet.global_position = shooting_player_position
	new_bullet.global_rotation = shooting_player_rotation
	Global.node_creation_parent.add_child (new_bullet)


func create_misile(shooting_player_index: int, shooting_player_color: Color, shooting_player_position: Vector2, shooting_player_rotation: float):

	var new_misile = misile.instance()
	new_misile.set_name("p%s_owned" % shooting_player_index) # dodam, ker je potem lažje dodati skore
	new_misile.misile_color = shooting_player_color
	new_misile.global_position = shooting_player_position
	new_misile.global_rotation = shooting_player_rotation
	Global.node_creation_parent.add_child(new_misile)
