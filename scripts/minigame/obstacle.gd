extends Area2D

@onready var game_over = $"../../../Camera2D/Game_Over"

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	# Devolve false se a corrida já tinha acabado (outro obstáculo no mesmo
	# frame, ou checkpoint final numa sessão com limite de nível).
	if not MinigameManager.on_obstacle_hit():
		return

	TutorialManager.on_minigame_finished()
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
