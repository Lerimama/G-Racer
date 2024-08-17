extends Node2D


onready var owner_bolt: KinematicBody2D = get_parent()
onready var feature_selector: Control = $VBoxContainer/FeatureSelector
onready var icon_bullet: TextureRect = $VBoxContainer/FeatureSelector/Icons/IconBullet
onready var icon_misile: TextureRect = $VBoxContainer/FeatureSelector/Icons/IconMisile
onready var icon_mina: TextureRect = $VBoxContainer/FeatureSelector/Icons/IconMina
onready var icon_shocker: TextureRect = $VBoxContainer/FeatureSelector/Icons/IconShocker


func _ready() -> void:
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	
	if feature_selector.visible:
	
		icon_bullet.get_node("Label").text = "%02d" % owner_bolt.bolt_stats["bullet_count"]
		icon_misile.get_node("Label").text = "%02d" % owner_bolt.bolt_stats["misile_count"]
		icon_mina.get_node("Label").text = "%02d" % owner_bolt.bolt_stats["mina_count"]
		icon_shocker.get_node("Label").text = "%02d" % owner_bolt.bolt_stats["shocker_count"]
	
