extends Area2D

@onready var game_over = $"../../../Camera2D/Game_Over"
var end = false

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
