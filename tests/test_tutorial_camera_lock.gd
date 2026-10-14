extends Node

func _ready() -> void:
	print("=== Testando Câmera e Trava de Gameplay no Passo 5 (Correção) ===")
	
	# =========================================================================
	# TESTE 1: Fluxo Completo Normal (sem pular câmera)
	# =========================================================================
	print("\n--- Teste 1: Fluxo normal completo (passos 1 ao 5) ---")
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["week"] = 1
	Global.player["day"] = 1
	Global.player["hour"] = 8
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.step = 0
	TutorialManager.skipped = false
	TutorialManager.pending_messages.clear()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	
	var main_scene = load("res://scenes/world/main_game.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert(TutorialManager.step == 1, "Deveria estar no passo 1")
	assert(AlertManager.panel.visible == true, "Painel de alerta do passo 1 deve estar visível")
	
	var space_ev = InputEventKey.new()
	space_ev.keycode = KEY_SPACE
	space_ev.pressed = true
	space_ev.echo = false

	# Fecha Passo 1
	AlertManager._input(space_ev)
	await get_tree().process_frame

	# Fecha messages[1], messages[28], messages[29] (Passo 2)
	AlertManager._input(space_ev)
	await get_tree().process_frame
	AlertManager._input(space_ev)
	await get_tree().process_frame
	AlertManager._input(space_ev)
	await get_tree().process_frame

	# Fecha Passo 3
	AlertManager._input(space_ev)
	await get_tree().process_frame

	# Fecha Passo 4 -> Dispara foco da câmera na Escola (Passo 5)
	AlertManager._input(space_ev)
	await get_tree().process_frame

	assert(TutorialManager.step == 5, "Deve estar no passo 5 (espera ir para a escola)")
	assert(CameraManager.is_cinematic == true, "Câmera deve estar em modo cinematográfico no passo 5")
	assert(Global.gameplay_locked == true, "Gameplay deve estar travado durante o movimento da câmera")
	print("  ok   Passo 5 iniciado: câmera em movimento e gameplay travado")

	# Aguarda conclusão normal do foco (move_time 2.0 + wait_time 1.0 + move_time 2.0 = 5.0)
	print("  Aguardando câmera voltar ao personagem normalmente...")
	for i in range(12):
		await get_tree().create_timer(0.5).timeout

	assert(CameraManager.is_cinematic == false, "Modo cinematográfico deve ter sido desativado")
	assert(Global.gameplay_locked == false, "Gameplay NÃO pode estar travado após retorno da câmera")
	assert(Global._gameplay_lock_count == 0, "Contador de locks deve ser 0")
	print("  ok   Câmera retornou normalmente: gameplay destravado e lock_count = 0")

	# =========================================================================
	# TESTE 2: Pular movimento da câmera pressionando ESC
	# =========================================================================
	print("\n--- Teste 2: Pular cutscene da câmera com ESC ---")
	# Re-dispara foco na escola
	TutorialManager.emit_signal("focus", "School")
	await get_tree().process_frame
	assert(CameraManager.is_cinematic == true, "Câmera deve entrar em cinematográfico novamente")
	assert(Global.gameplay_locked == true, "Gameplay travado")

	# Simula ESC após 0.2 segundos de movimento
	await get_tree().create_timer(0.2).timeout
	var esc_ev = InputEventKey.new()
	esc_ev.keycode = KEY_ESCAPE
	esc_ev.pressed = true
	esc_ev.echo = false
	
	# CameraManager captura o ESC e pula
	CameraManager._input(esc_ev)
	await get_tree().process_frame
	await get_tree().process_frame

	assert(CameraManager.is_cinematic == false, "ESC durante câmera deve encerrar cutscene imediatamente")
	assert(Global.gameplay_locked == false, "ESC durante câmera deve destravar gameplay")
	assert(Global._gameplay_lock_count == 0, "lock_count deve ser 0 após pular câmera com ESC")
	
	var pause_menu = main_scene.find_child("pause_menu", true, false)
	assert(pause_menu != null and pause_menu.paused == false, "Pular câmera não deve abrir o menu de pause acidentalmente")
	print("  ok   ESC pulou a animação da câmera instantaneamente sem travar o jogo")

	# =========================================================================
	# TESTE 3: Pular movimento da câmera pressionando ESPAÇO
	# =========================================================================
	print("\n--- Teste 3: Pular cutscene da câmera com ESPAÇO ---")
	TutorialManager.emit_signal("focus", "School")
	await get_tree().process_frame
	assert(CameraManager.is_cinematic == true, "Câmera em modo cinematográfico")
	
	# Simula ESPAÇO durante o movimento
	await get_tree().create_timer(0.2).timeout
	CameraManager._input(space_ev)
	await get_tree().process_frame
	await get_tree().process_frame

	assert(CameraManager.is_cinematic == false, "ESPAÇO deve encerrar a cutscene imediatamente")
	assert(Global.gameplay_locked == false, "Gameplay destravado")
	assert(Global._gameplay_lock_count == 0, "lock_count zerado")
	print("  ok   ESPAÇO pulou a animação da câmera instantaneamente")

	# =========================================================================
	# TESTE 4: Abertura e fechamento normal do Pause Menu via ESC
	# =========================================================================
	print("\n--- Teste 4: Teste de Pause Menu com ESC após o tutorial ---")
	pause_menu._input(esc_ev)
	assert(pause_menu.paused == true, "ESC deve pausar o jogo")
	assert(pause_menu.visible == true, "Menu de pause deve ficar visível")
	assert(Global.gameplay_locked == true, "Menu de pause aberto trava gameplay")
	
	# Segundo ESC despausa
	pause_menu._input(esc_ev)
	assert(pause_menu.paused == false, "Segundo ESC deve despausar")
	assert(pause_menu.visible == false, "Menu de pause deve ficar oculto")
	assert(Global.gameplay_locked == false, "Despausar deve liberar gameplay")
	assert(Global._gameplay_lock_count == 0, "lock_count zerado após despausar")
	print("  ok   Pause menu abre e fecha normalmente pelo ESC")

	# =========================================================================
	# TESTE 5: Auto-recuperação de trava órfã caso algum sistema falhe
	# =========================================================================
	print("\n--- Teste 5: Recuperação de trava órfã via ESC no Pause Menu ---")
	Global.lock_gameplay() # Trava artificial sem blocker
	assert(Global.gameplay_locked == true, "Gameplay travado artificialmente")
	
	# Pressiona ESC com trava órfã ativa
	pause_menu._input(esc_ev)
	assert(pause_menu.paused == true, "ESC deve detectar trava órfã e abrir o menu de pause para recuperação")
	
	# Despausa para recuperar controle total
	pause_menu._input(esc_ev)
	assert(Global.gameplay_locked == false, "Após despausar, controle total deve ser restabelecido")
	assert(Global._gameplay_lock_count == 0, "lock_count totalmente limpo")
	print("  ok   Trava órfã recuperada com sucesso pelo menu de pause")

	print("\n=== TODOS OS TESTES PASSARAM COM SUCESSO! ===")
	get_tree().quit(0)
