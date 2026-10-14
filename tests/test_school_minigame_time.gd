extends Node

func _ready() -> void:
	print("=== Testando pausa do tempo no Minigame da Escola ===")

	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["stamina"] = 100.0
	Global.player["hour"] = 10
	Global.player["day"] = 1
	TimeManager.current_hour = 10
	TimeManager.current_minute = 0
	TimeManager.timer = 0.0
	TimeManager.day_end_pending = false
	AlertManager.reset()
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.set_unlock_stage(Global.UNLOCK_ALL)
	TutorialManager.skipped = true
	Global.force_release_all_gameplay_locks()

	# 1. Fora do minigame, o tempo roda normalmente quando play_time == true
	Global.in_school_minigame = false
	Global.play_time = true
	var timer_before = TimeManager.timer
	TimeManager._process(0.05)
	assert(TimeManager.timer > timer_before, "No jogo normal, o tempo deve avançar")
	print("  ok   Tempo avança normalmente fora do minigame")

	# 2. Entrando no minigame da escola
	MinigameManager.is_in_minigame = true
	Global.play_time = false
	assert(MinigameManager.is_in_minigame == true, "MinigameManager deve reportar is_in_minigame == true")
	assert(Global.in_school_minigame == true, "Global deve sincronizar in_school_minigame == true")
	assert(Global.play_time == false, "play_time deve ser false dentro do minigame")
	print("  ok   Entrada no minigame congela play_time e ativa flags")

	# 3. TimeManager não deve avançar mesmo se chamado no _process
	TimeManager.timer = 0.0
	var min_before = TimeManager.current_minute
	var stamina_before = float(Global.player["stamina"])
	TimeManager._process(1.0)
	assert(TimeManager.timer == 0.0, "Timer do TimeManager não deve avançar no minigame")
	assert(TimeManager.current_minute == min_before, "Minuto do TimeManager não deve avançar no minigame")
	assert(float(Global.player["stamina"]) == stamina_before, "Stamina não deve decair no minigame")
	print("  ok   TimeManager._process é interrompido no minigame")

	# 4. Fechar alerta dentro do minigame não pode religar play_time
	AlertManager.alert("Aviso de teste no minigame")
	assert(Global.gameplay_locked == true, "Alerta aberto deve travar gameplay")
	AlertManager._close_alert()
	assert(Global.gameplay_locked == false, "Fechar alerta destrava gameplay")
	assert(Global.play_time == false, "Fechar alerta NÃO pode religar play_time no minigame")
	print("  ok   AlertManager._close_alert mantém play_time desligado no minigame")

	# 5. Pausar e despausar dentro do minigame não pode religar play_time
	var pause_menu = preload("res://scenes/menus/pause_menu.tscn").instantiate()
	add_child(pause_menu)
	pause_menu.toggle_pause()
	assert(pause_menu.paused == true, "Pause menu deve pausar")
	assert(Global.play_time == false, "Pausa mantém play_time desligado")
	pause_menu.toggle_pause()
	assert(pause_menu.paused == false, "Pause menu deve despausar")
	assert(Global.play_time == false, "Despausar no minigame NÃO deve religar play_time")
	pause_menu.queue_free()
	print("  ok   Pause menu mantém play_time desligado no minigame")

	# 6. EventsManager não avança spawn_timer no minigame
	EventsManager.spawn_timer = 0.0
	EventsManager._process(1.0)
	assert(EventsManager.spawn_timer == 0.0, "EventsManager.spawn_timer não deve avançar no minigame")
	print("  ok   EventsManager não acumula tempo de sorteio no minigame")

	# 7. Saindo do minigame (volta para main_game)
	MinigameManager.is_in_minigame = false
	assert(MinigameManager.is_in_minigame == false, "is_in_minigame deve ser false ao sair")
	assert(Global.in_school_minigame == false, "Global.in_school_minigame deve ser false ao sair")

	# Simulando a retomada no main_game (onde _on_tree_entered religa o play_time)
	Global.play_time = true
	TimeManager._process(0.05)
	assert(TimeManager.timer > 0.0, "Após sair do minigame, o tempo deve voltar a correr")
	print("  ok   Retorno ao mundo retoma o fluxo de tempo")

	print("=== Todos os testes de pausa de tempo no minigame passaram ===")
	get_tree().quit(0)
