extends Resource
class_name PlayerData


#var default_driver_profile: Dictionary = {
#	"driver_avatar": preload("res://home/avatar_david.tres"),
#	"driver_color": Rfs.color_blue, # color_yellow, color_green, color_red ... pomembno da se nalagajo za Settingsi
#	"controller_type": CONTROLLER_TYPE.ARROWS,
#	"agent_type": AGENT.BASIC,
#	"driver_type": DRIVER_TYPE.PLAYER,
#}

export var driver_nm: String = "res drajver"
#export var driver_avatar: Texture = preload("res://home/avatar_david.tres")
#export var driver_color: Color = Color.palevioletred
#export var driver_controller: int = 0
#export var driver_type: int = 0

func change_data_value(data_value):

	driver_nm = data_value
