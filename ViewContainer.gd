extends ViewportContainer

# vsakič ko se plejer id zamenja apdejta kamero
var player_id:int setget update_camera 

func update_camera(id):
	
	var target_id
	
	match id:
		1:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_1
		2:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_2
	
