extends Control


enum TutorialStage {MISSION = 1, TRAVELING, BURSTING, SKILLING, STACKING, WINLOSE}
var current_tutorial_stage: int

var tutorial_finished: bool = false

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var hud_guide: Control = $HudGuide
onready var mission_panel: Control = $MissionPanel
onready var controls: Control = $Controls
onready var checkpoints: Control = $Checkpoints
onready var traveling_content: Control = $Checkpoints/TravelingContent
onready var bursting_content: Control = $Checkpoints/BurstingContent
onready var skilling_content: Control = $Checkpoints/SkillingContent
onready var stacking_content: Control = $Checkpoints/StackingContent
onready var winlose_content: Control = $Checkpoints/WinLoseContent


func _input(event: InputEvent) -> void:
	
	if current_tutorial_stage == TutorialStage.MISSION: # namesto menija
		if Input.is_action_just_pressed("ui_accept"):
			Global.sound_manager.play_gui_sfx("btn_confirm")
			animation_player.play("tutorial_start")
			
			current_tutorial_stage = 0 # anti dablklik
			Global.sound_manager.play_music("game_music")
			Global.sound_manager.skip_track() # skipa prvi komad in zapleja drugega
			
	elif current_tutorial_stage == TutorialStage.TRAVELING:
		if Input.is_action_pressed("ui_up"):
			traveling_directions.erase(Vector2.UP)
		elif Input.is_action_pressed("ui_down"):
			traveling_directions.erase(Vector2.DOWN)
		elif Input.is_action_pressed("ui_left"):
			traveling_directions.erase(Vector2.LEFT)
		elif Input.is_action_pressed("ui_right"):
			traveling_directions.erase(Vector2.RIGHT)
		
		if traveling_directions.empty():
			finish_traveling()	
			
	
func _ready() -> void:
	
	Global.tutorial_gui = self # za statse iz GMja
	visible = false
	
	mission_panel.visible = true
	hud_guide.visible = true
	hud_guide.modulate.a = 0
		
	traveling_content.visible = false
	bursting_content.visible = false
	skilling_content.visible = false
	stacking_content.visible = false
	winlose_content.visible = false


func _process(delta: float) -> void:
	
	if Global.game_manager.strays_in_game_count == 0 and not tutorial_finished:
		if current_tutorial_stage > 3 and current_tutorial_stage < 6: # spucano v skilling or stacking 
			tutorial_finished = true
			finish_unfinished_tutorial()
		elif current_tutorial_stage == 6: # spucano v winlose
			tutorial_finished = true
			finish_tutorial()


func open_tutorial(): # kliče se z GM
	
	visible = true
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	animation_player.play("mission_in")
	

func start_tutorial():

	current_tutorial_stage = TutorialStage.TRAVELING
	
	Global.hud.game_timer.start_timer()
	Global.game_manager.game_on = true
	
	open_stage(traveling_content)
	
	var show_controls = get_tree().create_tween()
	show_controls.tween_callback(controls, "show")
	show_controls.tween_property(controls, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)	
	
	get_tree().call_group(Global.group_players, "set_physics_process", true)
	

# STAGES ------------------------------------------------------------------------------------------------------------------	


func finish_traveling():
	if not current_tutorial_stage == TutorialStage.TRAVELING:
		return	
	change_stage(traveling_content, bursting_content, TutorialStage.BURSTING)
	
	yield(get_tree().create_timer(2), "timeout")
	Global.game_manager.set_strays()
	
	
func finish_bursting():
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
	change_stage(bursting_content, skilling_content, TutorialStage.SKILLING)		


func finish_skilling():
	
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	change_stage(skilling_content, stacking_content, TutorialStage.STACKING)		
	
	
func finish_stacking():
	
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	change_stage(stacking_content, winlose_content, TutorialStage.WINLOSE)		

	
func finish_tutorial():
	
	if not current_tutorial_stage == TutorialStage.WINLOSE:
		return
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	
	var fadeout_delay: float = 3  # čaka končanje GO animacijo plejerja
	var close_final_stage = get_tree().create_tween()
	close_final_stage.tween_callback(Global.game_manager, "game_over", [Global.game_manager.GameoverReason.CLEANED])
	close_final_stage.tween_property(checkpoints, "modulate:a", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(fadeout_delay)
	close_final_stage.parallel().tween_property(controls, "modulate:a", 0, 1).set_ease(Tween.EASE_IN).set_delay(fadeout_delay)	


func finish_unfinished_tutorial():
	
	var close_final_stage = get_tree().create_tween()
	close_final_stage.tween_property(checkpoints, "modulate:a", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)#.set_delay(fadeout_delay)
	close_final_stage.parallel().tween_property(controls, "modulate:a", 0, 1).set_ease(Tween.EASE_IN)#.set_delay(fadeout_delay)
	close_final_stage.tween_callback(Global.game_manager, "game_over", [Global.game_manager.GameoverReason.LIFE])


# UTILITI ------------------------------------------------------------------------------------------------------------------	


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_enum: int):
	
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	current_tutorial_stage = next_stage_enum
	
	yield(get_tree().create_timer(1), "timeout")
	
	var close_stage = get_tree().create_tween()
	close_stage.tween_property(stage_to_hide, "modulate:a", 0, 0.5)#.set_delay(2)
	close_stage.tween_callback(stage_to_hide, "hide")
	close_stage.tween_callback(self, "open_stage", [next_stage])
	

func open_stage(stage_to_show: Control):
	
	var open_stage = get_tree().create_tween()
	open_stage.tween_callback(stage_to_show, "show")
	open_stage.tween_property(stage_to_show, "modulate:a", 1, 0.5).from(0.0).set_ease(Tween.EASE_IN)


func skill_done(skill: String):
	
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return	
	
	all_skills.erase(skill)
	if all_skills.empty():
		finish_skilling()
		
		
# SIGNALS ------------------------------------------------------------------------------------------------------------------	

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"mission_in":
			current_tutorial_stage = TutorialStage.MISSION
		"tutorial_start":
			var show_player = get_tree().create_tween()
			show_player.tween_callback(self, "start_tutorial")#.set_delay(1)
