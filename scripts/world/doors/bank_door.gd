extends Area2D

var dentro_banco = false
# Painel de informação da porta: fica escondido na cena e só aparece
# enquanto o jogador estiver dentro da Area2D.
@onready var info_panel: Panel = $"Info-panel"

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	if Input.is_key_pressed(KEY_ENTER) and dentro_banco == true:
		get_tree().change_scene_to_file("res://scenes/world/places/bank.tscn")

func _on_body_shape_entered(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	info_panel.show()
	dentro_banco = true
	
func _on_body_shape_exited(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	info_panel.hide()
	dentro_banco = false
