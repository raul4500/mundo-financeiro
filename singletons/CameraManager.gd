extends Node


var player: Node2D = null
var player_camera: Camera2D = null


var is_cinematic := false

signal focus_arrived(point)
signal focus_returned()


# Chamado quando o Player é criado
func register_player(new_player: Node2D):
	player = new_player
	player_camera = player.get_node("Camera2D")
	print("CameraManager: Player registrado")


# Executa uma introdução cinematográfica (mantém comportamento legado)
func focus(target: Node2D, move_time := 2.0, wait_time := 1.0):
	# Mantém a API existente: move até o alvo, espera e volta ao jogador.
	if player == null:
		push_error("CameraManager: nenhum jogador registrado")
		return
	if player_camera == null:
		push_error("CameraManager: câmera não encontrada")
		return
	is_cinematic = true
	# bloqueia gameplay
	Global.lock_gameplay()
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
	Global.unlock_gameplay()
	is_cinematic = false


# Move a câmera até um alvo e PARA LÁ (não volta automaticamente). Emite
# focus_arrived quando alcançado.
func goto(target: Node2D, move_time := 2.0) -> void:
	if player == null:
		push_error("CameraManager.goto: nenhum jogador registrado")
		return
	if player_camera == null:
		push_error("CameraManager.goto: câmera não encontrada")
		return
	is_cinematic = true
	Global.lock_gameplay()
	player_camera.start_cinematic()
	await player_camera.move_to(target.global_position, move_time)
	emit_signal("focus_arrived", str(target.name))


# Retorna a câmera para o jogador e sai do modo cinematográfico.
func return_to_player(move_time := 2.0) -> void:
	if player == null:
		push_error("CameraManager.return_to_player: nenhum jogador registrado")
		return
	if player_camera == null:
		push_error("CameraManager.return_to_player: câmera não encontrada")
		return
	# move de volta para o jogador
	await player_camera.move_to(player.global_position, move_time)
	player_camera.stop_cinematic()
	Global.unlock_gameplay()
	is_cinematic = false
	emit_signal("focus_returned")
