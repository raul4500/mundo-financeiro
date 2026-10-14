extends Node


var player: Node2D = null
var player_camera: Camera2D = null


var is_cinematic := false
var _skip_requested := false

signal focus_arrived(point)
signal focus_returned()


# Chamado quando o Player é criado
func register_player(new_player: Node2D):
	player = new_player
	if player != null:
		player_camera = player.get_node_or_null("Camera2D")
	print("CameraManager: Player registrado")


func _input(event: InputEvent) -> void:
	if not is_cinematic:
		return
	# Se um alerta estiver aberto ou cena estiver transicionando, não consome os inputs
	if AlertManager != null and is_instance_valid(AlertManager.panel) and AlertManager.panel.visible:
		return
	if TransitionManager != null and TransitionManager.is_transitioning():
		return
	# Permite pular a movimentação cinematográfica da câmera pressionando ESC ou ESPAÇO
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		_skip_requested = true
		if player_camera != null and player_camera.has_method("cancel_movement"):
			player_camera.cancel_movement()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


# Executa uma introdução cinematográfica (mantém comportamento legado)
func focus(target: Node2D, move_time := 2.0, wait_time := 1.0):
	# Mantém a API existente: move até o alvo, espera e volta ao jogador.
	if player == null:
		push_error("CameraManager: nenhum jogador registrado")
		return
	if player_camera == null:
		push_error("CameraManager: câmera não encontrada")
		return
	if is_cinematic:
		return
	is_cinematic = true
	_skip_requested = false
	# bloqueia gameplay
	Global.lock_gameplay()
	# pega a posição atual do jogador
	var start_position = player.global_position
	# entra no modo cinematográfico
	player_camera.start_cinematic()
	# move até o objetivo
	if not _skip_requested:
		await player_camera.move_to(
			target.global_position,
			move_time
		)
	# espera olhando o ponto (ou pula se solicitado)
	if not _skip_requested:
		var elapsed := 0.0
		while elapsed < wait_time and not _skip_requested:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
	# volta para o jogador
	if not _skip_requested:
		await player_camera.move_to(
			start_position,
			move_time
		)
	# retorna ao modo normal e garante liberação limpa dos bloqueios
	player_camera.stop_cinematic()
	Global.force_release_all_gameplay_locks()
	is_cinematic = false
	_skip_requested = false
	emit_signal("focus_returned")


# Move a câmera até um alvo e PARA LÁ (não volta automaticamente). Emite
# focus_arrived quando alcançado.
func goto(target: Node2D, move_time := 2.0) -> void:
	if player == null:
		push_error("CameraManager.goto: nenhum jogador registrado")
		return
	if player_camera == null:
		push_error("CameraManager.goto: câmera não encontrada")
		return
	if not is_cinematic:
		is_cinematic = true
		Global.lock_gameplay()
		player_camera.start_cinematic()
	_skip_requested = false
	if not _skip_requested:
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
	if not _skip_requested:
		await player_camera.move_to(player.global_position, move_time)
	player_camera.stop_cinematic()
	Global.force_release_all_gameplay_locks()
	is_cinematic = false
	_skip_requested = false
	emit_signal("focus_returned")

