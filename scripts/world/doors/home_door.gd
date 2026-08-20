extends Area2D

var dentro_home = false

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	if Input.is_key_pressed(KEY_ENTER) and dentro_home == true:
		get_tree().change_scene_to_file("res://scenes/world/places/home.tscn")

func _on_body_shape_entered(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	dentro_home = true


func _on_body_shape_exited(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	dentro_home = false
