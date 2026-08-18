extends Area2D

var dentro = false
@onready var label = $Minigame

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	if Input.is_key_pressed(KEY_ENTER) and dentro == true:
		# Tutorial: ao entrar na escola e após a explicação, o jogador pode avançar.
		TutorialManager.on_player_entered_school()
		get_tree().change_scene_to_file("res://scenes/minigame/minigame.tscn")

func _on_body_shape_entered(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	label.show()
	dentro = true
	
func _on_body_shape_exited(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	label.hide()
	dentro = false
	
