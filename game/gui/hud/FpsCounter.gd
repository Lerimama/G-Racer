extends Label


var frame_second: float = 1	
var frames_per_second: int = 0
var frame_time: float = 0.016667


func _process(delta: float) -> void:
	
	if frame_second > 0:
		frame_second -= delta
		frames_per_second += 1
	else:
#		text = "FPS " + str(frames_per_second)
		text = "FPS real " + str(OS.get_screen_refresh_rate())
		frame_second = 1
		frames_per_second = 0	
