extends Area2D

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	# Quem decide é o MinigameManager: ele sobe o nível e diz se a corrida
	# acaba aqui. Na primeira sessão (formação inicial) devolve false e o
	# jogador segue correndo para os próximos checkpoints.
	if not MinigameManager.on_checkpoint_reached():
		return

	# Mostra escolaridade e salário e só então volta ao mundo (ver
	# MinigameManager.show_result_and_return).
	MinigameManager.show_result_and_return("Você chegou ao checkpoint e concluiu a aula!")
