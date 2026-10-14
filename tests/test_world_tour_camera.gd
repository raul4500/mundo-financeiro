extends Node

func _ready() -> void:
	print("=== Testando Tour do Mundo (Passo 10) ===")
	
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["week"] = 1
	Global.player["day"] = 1
	Global.player["hour"] = 8
	Global.player["tutorial_step"] = 10
	Global.player["unlock_stage"] = Global.UNLOCK_OFFICE
	TutorialManager.step = 10
	TutorialManager.skipped = false
	TutorialManager.pending_messages.clear()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	var main_scene = load("res://scenes/world/main_game.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	print("Iniciando tour do mundo... Total de mensagens na fila: %d" % TutorialManager.pending_messages.size())
	
	var space_ev = InputEventKey.new()
	space_ev.keycode = KEY_SPACE
	space_ev.pressed = true
	space_ev.echo = false

	var count = 0
	while not TutorialManager.pending_messages.is_empty() or AlertManager.panel.visible:
		count += 1
		if count > 30:
			print("FALHA: Loop infinito ou fila travada!")
			break
		
		# Se a câmera estiver em movimento, aguarda um pouco
		if CameraManager.is_cinematic:
			print("  [Passo %d] Câmera em movimento... is_cinematic = true" % count)
			await get_tree().create_timer(0.1).timeout
			# Simula pular o movimento com espaço
			CameraManager._input(space_ev)
			await get_tree().process_frame
			await get_tree().process_frame
		
		if AlertManager.panel.visible:
			var txt = AlertManager.alert_label.text.substr(0, 40).replace("\n", " ")
			print("  [Alerta %d] '%s...' (is_cinematic: %s)" % [count, txt, CameraManager.is_cinematic])
			AlertManager._input(space_ev)
			await get_tree().process_frame
			await get_tree().process_frame
		else:
			await get_tree().create_timer(0.05).timeout

	assert(count <= 30, "O tour do mundo não pode travar em loop infinito")
	assert(CameraManager.is_cinematic == false, "Modo cinematográfico deve ser desativado após o tour")
	assert(Global.gameplay_locked == false, "Gameplay deve estar destravado")
	assert(Global._gameplay_lock_count == 0, "Contador de locks deve ser 0")
	if CameraManager.player != null and CameraManager.player_camera != null:
		assert(CameraManager.player_camera.position == Vector2.ZERO, "A câmera deve voltar exatamente à posição do jogador")
	print("=== Todos os testes do tour do mundo passaram com sucesso! ===")
	get_tree().quit(0)

