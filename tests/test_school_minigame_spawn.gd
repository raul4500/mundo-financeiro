extends Node

func _ready() -> void:
	print("=== Testando Spawn e Checkpoints do Minigame da Escola ===")

	# Inicializa dados básicos do jogador
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	var scene = preload("res://scenes/minigame/minigame.tscn")

	# 1. Testar posicionamento em cada nível (1 a 5)
	var expected_positions = {
		1: Vector2(5, -43),
		2: Vector2(465, -43),
		3: Vector2(1926, -43),
		4: Vector2(3250, -40),
		5: Vector2(4554, -43)
	}

	for lvl in expected_positions.keys():
		Global.player["school_level"] = lvl
		var inst = scene.instantiate()
		add_child(inst)

		var expected_pos: Vector2 = expected_positions[lvl]
		var player_node = inst.get_node("Player-minigame")
		var cam_node = inst.get_node("Camera2D")
		var label_node = inst.get_node("Camera2D/Level")

		assert(player_node.global_position == expected_pos,
			"Nível %d: jogador deveria estar em %s, mas está em %s" % [lvl, expected_pos, player_node.global_position])
		assert(cam_node.global_position == expected_pos + inst.CAMERA_OFFSET,
			"Nível %d: câmera deveria estar em %s, mas está em %s" % [lvl, expected_pos + inst.CAMERA_OFFSET, cam_node.global_position])
		assert(label_node.text == "Level %d" % lvl,
			"Nível %d: label deveria mostrar 'Level %d', mas mostra '%s'" % [lvl, lvl, label_node.text])

		print("  ok   Nível %d spawna corretamente em %s" % [lvl, expected_pos])
		inst.queue_free()
		await get_tree().process_frame

	# 2. Testar comportamento da 2ª sessão após perda no nível 3
	# Simula que o jogador já completou a primeira corrida (formação inicial) e agora está no nível 3
	Global.player["school_level"] = 3
	Global.player["minigame_progress"] = {
		"unlock_week": 1,
		"unlock_day": 0,
		"sessions_played": 1
	}

	assert(not MinigameManager.is_first_session(), "Deve ser a segunda sessão ou posterior")

	var game_inst = scene.instantiate()
	add_child(game_inst)

	var p = game_inst.get_node("Player-minigame")
	assert(p.global_position == Vector2(1926, -43), "Jogador no nível 3 deve spawnar no Marker_3 (1926, -43)")
	print("  ok   Jogador de nível 3 não começa mais no início do mapa")

	# 3. Testar início da corrida (run-in)
	game_inst._on_start_pressed()
	assert(game_inst.run_in_active == true, "Run-in deve estar ativo após pressionar começar")
	assert(not MinigameManager.is_session_active(), "Sessão NÃO pode estar ativa durante o run-in")
	assert(p.global_position.x == 1926.0 - game_inst.RUN_IN_PADDING,
		"Jogador deve recuar RUN_IN_PADDING para fazer a corrida de entrada")
	print("  ok   Run-in posiciona o jogador para correr sem ativar colisão prévia")

	# Simular chegada ao marcador (fim do run-in)
	p.global_position.x = 1926.0
	game_inst._process_run_in()
	assert(game_inst.run_in_active == false, "Run-in deve ser desativado após alcançar o marcador")
	assert(game_inst.started == true, "Corrida deve estar iniciada")
	assert(MinigameManager.is_session_active() == true, "Sessão deve ser ativada ao chegar ao marcador")
	print("  ok   Ao atingir o marcador de nível 3, a sessão é ativada corretamente")

	# 4. Simular colisão com o próximo checkpoint (Level3 em x=3227)
	# Na segunda sessão em diante, alcançar o checkpoint sobe 1 nível e encerra a sessão
	var reached_ended = MinigameManager.on_checkpoint_reached()
	assert(reached_ended == true, "Na segunda sessão, alcançar checkpoint deve encerrar a corrida")
	assert(int(Global.player["school_level"]) == 4, "Escolaridade deve ter subido de 3 para 4")
	assert(int(Global.player["minigame_progress"]["unlock_week"]) == int(Global.player["week"]) + 1,
		"Escola deve ser trancada por 1 semana após subir de nível")
	print("  ok   Avanço de nível e trava semanal funcionando perfeitamente")

	game_inst.queue_free()
	await get_tree().process_frame

	print("=== Todos os testes de spawn e checkpoints do minigame passaram! ===")
	get_tree().quit(0)
