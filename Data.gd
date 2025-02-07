extends Node

onready var label: Label = $Label


onready var save_file_path = "user://save/"
#onready var save_file_path = get_user_data_dir()
var save_file_name = "DriverSave.tres"

onready var driverData = PlayerData.new()

var playerData = Resource.new()



func _ready() -> void:

	_verify_directory(save_file_path)
	_update_label()


func _load_data():

	playerData = ResourceLoader.load(save_file_path + save_file_name).duplicate()
	_update_label()


func _save_data():

	ResourceSaver.save(playerData, save_file_path * save_file_name)
	_update_label()


func _update_resource_data():

	playerData.change_data_value("JOŽE")



func _verify_directory(save_file_path: String):

	var user_dir: Directory = Directory.new()
#	user_dir.dir_exists(save_file_path)

	user_dir.make_dir_recursive(save_file_path)


func _update_label():

	label.text = "NAME: " + str(playerData.driver_name)
