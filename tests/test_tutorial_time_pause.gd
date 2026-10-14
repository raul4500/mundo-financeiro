extends Node

func _ready() -> void:
	print("=== Testando Congelamento de Tempo Durante os Tutoriais ===")

	# 1. Configuração inicial de novo jogo (Semana 1)
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["week"] = 1
	Global.player["day"] = 1
	Global.player["hour"] = 8
	Global.player["stamina"] = 100.0
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.step = 1
	TutorialManager.skipped = false
	TutorialManager.pending_messages.clear()
	TimeManager.current_hour = 8
	TimeManager.current_minute = 0
	TimeManager.timer = 0.0
	TimeManager.day_end_pending = false
	AlertManager.reset()

	# Durante o onboarding, o tutorial está ativo e play_time deve ser false
	assert(Global.is_any_tutorial_active() == true, "O tutorial inicial deve ser reconhecido como ativo")
	assert(TutorialManager.is_any_tutorial_active() == true, "TutorialManager deve confirmar que o tutorial está ativo")

	# Força liberação de travas (como se o jogo estivesse pronto no mapa)
	Global.force_release_all_gameplay_locks()
	assert(Global.play_time == false, "force_release_all_gameplay_locks NÃO deve religar play_time durante tutorial")
	print("  ok   Início de jogo: tutorial ativo e play_time desativado")

	# 2. TimeManager não deve avançar o relógio durante o tutorial
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Timer não pode avançar durante o tutorial")
	assert(TimeManager.current_minute == 0, "Minuto não pode avançar durante o tutorial")
	assert(TimeManager.current_hour == 8, "Hora não pode avançar durante o tutorial")
	print("  ok   TimeManager._process não avança o tempo durante o tutorial")

	# 3. TimeManager.spend_hours não deve gastar tempo durante o tutorial
	var spend_res = TimeManager.spend_hours(1.0)
	assert(spend_res.get("minutes", -1) == 0, "spend_hours não pode consumir tempo durante o tutorial")
	assert(TimeManager.current_minute == 0, "Minuto deve permanecer inalterado")
	print("  ok   spend_hours não consome tempo no tutorial")

	# 4. EventsManager não deve acumular tempo nem sortear eventos no tutorial
	EventsManager.spawn_timer = 0.0
	EventsManager._process(1.0)
	assert(EventsManager.spawn_timer == 0.0, "EventsManager não pode avançar timer no tutorial")
	print("  ok   EventsManager congelado no tutorial")

	# 5. Passo 5: Espera ir para a escola (jogador se move, mas tempo fica parado)
	TutorialManager.step = 5
	Global.player["tutorial_step"] = 5
	Global.force_release_all_gameplay_locks()
	assert(Global.gameplay_locked == false, "No passo 5 o jogador deve ter liberdade para andar")
	assert(Global.is_any_tutorial_active() == true, "No passo 5 o tutorial continua ativo")
	assert(Global.play_time == false, "No passo 5 o tempo continua congelado")
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Tempo permanece congelado enquanto o jogador caminha até a escola")
	print("  ok   Passo 5 (ir para a escola): movimentação livre e tempo congelado")

	# 6. Passo 9: Espera visita ao escritório (jogador se move e lê, mas tempo fica parado)
	TutorialManager.step = 9
	Global.player["tutorial_step"] = 9
	Global.force_release_all_gameplay_locks()
	assert(Global.gameplay_locked == false, "No passo 9 o jogador deve ter liberdade para andar e entrar no escritório")
	assert(Global.is_any_tutorial_active() == true, "No passo 9 o tutorial continua ativo")
	assert(Global.play_time == false, "No passo 9 o tempo continua congelado")
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Tempo permanece congelado enquanto o jogador visita a consultoria")
	print("  ok   Passo 9 (visita ao escritório): movimentação livre e tempo congelado")

	# 7. Fechar alerta durante o tutorial não religa o tempo
	AlertManager.alert("Aviso de teste no tutorial")
	AlertManager._close_alert()
	assert(Global.play_time == false, "Fechar alerta no tutorial NÃO deve religar play_time")
	print("  ok   AlertManager._close_alert preserva o congelamento do tempo no tutorial")

	# 8. Pausar e despausar no tutorial não religa o tempo
	var pause_menu = preload("res://scenes/menus/pause_menu.tscn").instantiate()
	add_child(pause_menu)
	pause_menu.toggle_pause()
	assert(pause_menu.paused == true, "Pause menu pausa")
	pause_menu.toggle_pause()
	assert(pause_menu.paused == false, "Pause menu despausa")
	assert(Global.play_time == false, "Despausar no tutorial NÃO deve religar play_time")
	pause_menu.queue_free()
	print("  ok   Pause menu preserva o congelamento do tempo no tutorial")

	# 9. Pular o tutorial deve destravar o tempo imediatamente
	TutorialManager.step = 1
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.skip_tutorial()
	assert(TutorialManager.skipped == true, "Tutorial deve estar marcado como skipped")
	assert(Global.is_any_tutorial_active() == false, "Nenhum tutorial deve estar ativo após pular")
	assert(Global.play_time == true, "play_time deve ser religado após pular o tutorial")
	TimeManager.timer = 0.0
	TimeManager._process(0.05)
	assert(TimeManager.timer > 0.0, "O tempo deve voltar a correr após pular o tutorial")
	print("  ok   Pular tutorial ativa o tempo e permite avanço normal do relógio")

	# 10. Teste dos avisos semanais (Semana 2, 3, 4, 5)
	# Simula um save onde o onboarding já passou e a semana 2 acabou de começar
	TutorialManager.skipped = false
	TutorialManager.step = TutorialManager.TUTORIAL_DONE
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	Global.player["tutorial_weeks_shown"] = []
	Global.play_time = true

	# Virada para semana 2: dispara aviso semanal
	TutorialManager.on_week_changed(2)
	assert(TutorialManager.is_any_tutorial_active() == true, "Aviso da semana 2 deve ativar o estado de tutorial")
	assert(Global.play_time == false, "Aviso da semana 2 deve pausar o tempo")
	TimeManager.timer = 0.0
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Tempo não corre enquanto o jogador lê o aviso da semana 2")
	print("  ok   Aviso da semana 2 congela o tempo para leitura sem pressa")

	# Consumir as mensagens da semana 2 simulando o clique do jogador em cada alerta
	while AlertManager.panel.visible or not TutorialManager.pending_messages.is_empty():
		AlertManager._close_alert()

	assert(TutorialManager.is_any_tutorial_active() == false, "Após ler todas as mensagens da semana 2, tutorial fecha")
	assert(Global.play_time == true, "Após concluir aviso da semana 2, o tempo volta a correr")
	TimeManager._process(0.05)
	assert(TimeManager.timer > 0.0, "Tempo avança normalmente após o aviso da semana 2")
	print("  ok   Tempo retoma automaticamente após ler o aviso da semana 2")

	# 11. Teste do tutorial da casa (on_player_entered_home)
	Global.player["tutorial_home_shown"] = false
	TutorialManager.on_player_entered_home()
	assert(TutorialManager.is_any_tutorial_active() == true, "Tutorial da casa deve ativar estado de tutorial")
	assert(Global.play_time == false, "Tutorial da casa deve pausar o tempo")
	TimeManager.timer = 0.0
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Tempo congelado durante tutorial da casa")

	# Consumir mensagens da casa simulando o clique do jogador em cada alerta
	while AlertManager.panel.visible or not TutorialManager.pending_messages.is_empty():
		AlertManager._close_alert()

	assert(TutorialManager.is_any_tutorial_active() == false, "Tutorial da casa concluído")
	assert(Global.play_time == true, "Tempo religado após tutorial da casa")
	print("  ok   Tutorial da casa congela tempo durante leitura e retoma ao encerrar")

	print("=== Todos os testes de congelamento de tempo em tutoriais passaram! ===")
	get_tree().quit(0)
