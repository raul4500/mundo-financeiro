extends Area2D

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	# Quem decide é o MinigameManager: ele sobe o nível e diz se a corrida
	# acaba aqui. Na primeira sessão (formação inicial) devolve false e o
	# jogador segue correndo para os próximos checkpoints.
	if not MinigameManager.on_checkpoint_reached():
		return

	TutorialManager.on_minigame_finished()
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
