extends Area2D

var dentro = false
# Painel de informação da porta: fica escondido na cena e só aparece
# enquanto o jogador estiver dentro da Area2D.
@onready var info_panel: Panel = $"Info-panel"

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	if Input.is_key_pressed(KEY_ENTER) and dentro == true:
		# Tutorial: ao entrar na escola e após a explicação, o jogador pode avançar.
		TutorialManager.on_player_entered_school()
		get_tree().change_scene_to_file("res://scenes/minigame/minigame.tscn")

func _on_body_shape_entered(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	info_panel.show()
	dentro = true
	
func _on_body_shape_exited(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	info_panel.hide()
	dentro = false
