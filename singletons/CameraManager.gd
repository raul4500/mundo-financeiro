extends Node


var player: Node2D = null
var player_camera: Camera2D = null


var is_cinematic := false



# Chamado quando o Player é criado
func register_player(new_player: Node2D):

	player = new_player
	
	player_camera = player.get_node("Camera2D")

	print("CameraManager: Player registrado")


# Executa uma introdução cinematográfica
func focus(target: Node2D, move_time := 2.0, wait_time := 1.0):

	if player == null:
		push_error("CameraManager: nenhum jogador registrado")
		return


	if player_camera == null:
		push_error("CameraManager: câmera não encontrada")
		return


	is_cinematic = true


	# bloqueia gameplay
	Global.gameplay_locked = true


	# pega a posição atual do jogador
	var start_position = player.global_position


	# entra no modo cinematográfico
	player_camera.start_cinematic()


	# move até o objetivo
	await player_camera.move_to(
		target.global_position,
		move_time
	)


	# espera olhando o ponto
	await get_tree().create_timer(wait_time).timeout



	# volta para o jogador
	await player_camera.move_to(
		start_position,
		move_time
	)



	# retorna ao modo normal
	player_camera.stop_cinematic()



	Global.gameplay_locked = false


	is_cinematic = false
