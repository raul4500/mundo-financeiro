extends Node

const MINIGAME_SCENE = preload("res://scenes/minigame/minigame.tscn")

func _fresh(level: int, salary: int) -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["school_level"] = level
	Global.player["salary"] = salary
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	# Segunda sessão em diante: alcançar o checkpoint encerra a corrida.
	Global.player["minigame_progress"] = {"unlock_week": 1, "unlock_day": 0, "sessions_played": 1}
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

func _shown_text() -> String:
	return AlertManager.alert_label.text

func _ready() -> void:
	print("=== Testando alerta de resultado do minigame da escola ===")

	# 1. O texto mostra a escolaridade e o salário ATUAIS.
	_fresh(3, 400)
	var text := MinigameManager.result_text("Fim da aula.")
	assert(text == "Fim da aula.\n\nEscolaridade: Ensino médio\nSalário: R$ 400", "Texto do resultado (veio '%s')" % text)
	print("  ok   Texto traz escolaridade e salário atuais")

	# 2. Abre mesmo com os alertas adiados da corrida, e a volta ao mundo espera a confirmação.
	_fresh(3, 400)
	AlertManager.defer_alerts()
	MinigameManager.show_result_and_return("Fim da aula.")
	assert(AlertManager.panel.visible, "O alerta abre na hora, mesmo com alertas adiados")
	assert(_shown_text().find("Escolaridade: Ensino médio") != -1 and _shown_text().find("Salário: R$ 400") != -1, "O alerta mostra escolaridade e salário")
	var callback: Callable = AlertManager.on_confirm_callback
	assert(callback.is_valid() and callback.get_object() == MinigameManager and callback.get_method() == "_return_to_world",
		"Confirmar chama a volta ao mundo (a troca de cena só acontece depois do OK)")
	assert(Global.gameplay_locked, "Enquanto o alerta está aberto o jogador fica parado")
	print("  ok   Alerta abre na hora, trava o jogador e só volta ao mundo ao confirmar")

	# 3. O espaço que o jogador ainda está martelando (pulo) não fecha o alerta ao abrir.
	var space_ev := InputEventKey.new()
	space_ev.keycode = KEY_SPACE
	space_ev.pressed = true
	space_ev.echo = false
	AlertManager._input(space_ev)
	assert(AlertManager.panel.visible, "Espaço logo ao abrir não fecha o alerta de resultado")
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	print("  ok   Espaço logo ao abrir é ignorado")

	# 4. Os dois desfechos reais disparam o alerta: bater no obstáculo e alcançar o checkpoint.
	_fresh(2, 300)
	var game: Node = MINIGAME_SCENE.instantiate()
	add_child(game)
	MinigameManager.begin_session()
	game.get_node("Map/obstacles/obstacle2")._on_body_shape_entered(RID(), null, 0, 0)
	assert(not MinigameManager.is_session_active(), "A batida encerrou a corrida")
	assert(AlertManager.panel.visible, "Bater num obstáculo abre o alerta de resultado")
	assert(_shown_text().find("bateu em um obstáculo") != -1, "Alerta de derrota (veio '%s')" % _shown_text())
	assert(_shown_text().find("Escolaridade: Fundamental") != -1 and _shown_text().find("Salário: R$ 300") != -1, "Derrota mostra escolaridade e salário")
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	_fresh(2, 300)
	MinigameManager.begin_session()
	game.get_node("Map/levels/Level1")._on_body_shape_entered(RID(), null, 0, 0)
	assert(AlertManager.panel.visible, "Alcançar o checkpoint abre o alerta de resultado")
	assert(_shown_text().find("checkpoint") != -1, "Alerta de checkpoint (veio '%s')" % _shown_text())
	# O checkpoint subiu o nível 2 -> 3 antes do alerta: o texto já traz o novo.
	assert(_shown_text().find("Escolaridade: Ensino médio") != -1 and _shown_text().find("Salário: R$ 400") != -1, "Checkpoint mostra a escolaridade e o salário novos")
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	remove_child(game)
	game.free()
	print("  ok   Obstáculo e checkpoint abrem o alerta com os valores atuais")

	print("=== Todos os testes do alerta de resultado passaram ===")
	get_tree().quit(0)
