extends Area2D

var dentro = false

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ENTER) and dentro == true:
		print("cliclou enter")
		get_tree().change_scene_to_file("res://scenes/minigame.tscn")

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	dentro = true
	
func _on_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	dentro = false
	
