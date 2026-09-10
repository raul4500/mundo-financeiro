extends Node

func _ready() -> void:
	print("=== Testando Comandos de Debug (DebugCommands.gd) ===")
	
	# Inicializa jogador de teste
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul_TCC"
	Global.player["money"] = 100.0
	Global.player["hunger"] = 40.0
	Global.player["thirst"] = 50.0
	Global.player["stamina"] = 30.0
	Global.player["school_level"] = 1
	Global.player["salary"] = 300.0
	Global.player["week"] = 1
	Global.player["day"] = 2
	
	# 1. Teste de Injeção de Dinheiro ([4])
	var initial_money = float(Global.player["money"])
	DebugCommands._cmd_add_money()
	assert(Global.player["money"] == initial_money + 5000.0, "Falha ao adicionar dinheiro")
	print("  ok   [4] Injetar Dinheiro (+R$ 5.000)")
	
	# 2. Teste de God Mode ([6])
	DebugCommands._cmd_max_needs()
	assert(Global.player["hunger"] == 100.0, "Falha ao restaurar fome")
	assert(Global.player["thirst"] == 100.0, "Falha ao restaurar sede")
	assert(Global.player["stamina"] == 100.0, "Falha ao restaurar stamina")
	print("  ok   [6] God Mode (100% Fome, Sede, Stamina)")
	
	# 3. Teste de Escolaridade ([8])
	var initial_school = int(Global.player["school_level"])
	DebugCommands._cmd_level_up_school()
	assert(Global.player["school_level"] == initial_school + 1, "Falha ao subir escolaridade")
	assert(Global.player["minigame_progress"]["unlock_week"] == 1, "Falha ao resetar cooldown minigame")
	print("  ok   [8] Subir Escolaridade e Resetar Cooldown")
	
	# 4. Teste de Velocidade do Tempo ([1])
	var initial_speed = TimeManager.time_scale
	DebugCommands._cmd_speed_time()
	assert(TimeManager.time_scale != initial_speed, "Falha ao alternar velocidade")
	print("  ok   [1] Alternar Velocidade do Tempo")
	
	# 5. Teste de Destravar Tudo ([7])
	DebugCommands._cmd_unlock_all()
	assert(Global.unlock_stage() == Global.UNLOCK_ALL, "Falha ao destravar todo o mapa")
	print("  ok   [7] Destravar Tudo e Pular Tutorial")
	
	# 6. Teste de Missões da Semana ([5])
	DebugCommands._cmd_complete_missions()
	assert(MissionManager.verify_missions(1) == true, "Falha ao verificar missões da semana 1")
	print("  ok   [5] Completar Missões da Semana Atual")
	
	# 7. Teste de Setup de Restaurante ([0])
	DebugCommands._cmd_setup_enterprise()
	assert(EnterpriseManager.is_owned("restaurant_small") == true, "Falha ao comprar restaurante")
	print("  ok   [0] Setup Rápido do Restaurante")
	
	# 8. Teste de Avanço de Dia ([2])
	var day_before = int(Global.player["day"])
	DebugCommands._cmd_advance_day()
	assert(int(Global.player["day"]) == day_before + 1, "Falha ao avançar dia")
	print("  ok   [2] Avançar Dia")
	
	# 9. Teste de Avanço de Semana ([3])
	var week_before = int(Global.player["week"])
	DebugCommands._cmd_advance_week()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(int(Global.player["week"]) == week_before + 1, "Falha ao avançar semana")
	print("  ok   [3] Avançar Semana")

	# 10. Teste de Ajuda / Overlay (F1)
	DebugCommands._toggle_help_overlay()
	assert(DebugCommands._help_visible == true, "Falha ao abrir overlay de ajuda")
	DebugCommands._toggle_help_overlay()
	assert(DebugCommands._help_visible == false, "Falha ao fechar overlay de ajuda")
	print("  ok   [F1] Overlay de Ajuda Toggle")
	
	print("=== TODOS OS 10 COMANDOS DE DEBUG VALIDADOS COM SUCESSO! ===")
	get_tree().quit(0)
