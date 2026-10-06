extends Node

func _ready() -> void:
	print("=== Testando ciclo semanal de 5 dias ===")

	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 1000.0
	Global.player["stamina"] = 100.0
	Global.player["day"] = 1
	Global.player["week"] = 1
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	TimeManager.current_day = 1
	TimeManager.current_hour = 8
	TimeManager.current_minute = 0
	TimeManager.day_end_pending = false
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	# 1. Checar constante DAYS_PER_WEEK
	assert(Global.DAYS_PER_WEEK == 5, "Global.DAYS_PER_WEEK deve ser 5")
	assert(TimeManager.DAYS_PER_WEEK == 5, "TimeManager.DAYS_PER_WEEK deve ser 5")
	print("  ok   Constante DAYS_PER_WEEK == 5")

	# 2. Testar cálculo de dias absolutos (5 dias por semana)
	Global.player["week"] = 1
	Global.player["day"] = 1
	assert(Global.get_absolute_day() == 1, "Semana 1, Dia 1 deve ser dia absoluto 1")
	Global.player["day"] = 5
	assert(Global.get_absolute_day() == 5, "Semana 1, Dia 5 deve ser dia absoluto 5")
	Global.player["week"] = 2
	Global.player["day"] = 1
	assert(Global.get_absolute_day() == 6, "Semana 2, Dia 1 deve ser dia absoluto 6 (1 * 5 + 1)")
	Global.player["week"] = 3
	Global.player["day"] = 5
	assert(Global.get_absolute_day() == 15, "Semana 3, Dia 5 deve ser dia absoluto 15 (2 * 5 + 5)")
	print("  ok   get_absolute_day calcula corretamente com base de 5 dias")

	# 3. Testar ciclo de dias 1 a 5 sem virar semana
	TimeManager.current_day = 1
	Global.player["day"] = 1
	Global.player["week"] = 1
	TimeManager.day_end_pending = false

	# Avançar do dia 1 para o dia 2
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	assert(TimeManager.current_day == 2, "Dia deve avançar para 2")
	assert(int(Global.player["day"]) == 2, "player['day'] deve ser 2")
	assert(int(Global.player["week"]) == 1, "Semana deve continuar 1")

	# Avançar do dia 2 para o dia 3
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	assert(TimeManager.current_day == 3, "Dia deve avançar para 3")

	# Avançar do dia 3 para o dia 4
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	assert(TimeManager.current_day == 4, "Dia deve avançar para 4")

	# Avançar do dia 4 para o dia 5
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	assert(TimeManager.current_day == 5, "Dia deve avançar para 5")
	assert(int(Global.player["day"]) == 5, "player['day'] deve ser 5")
	assert(int(Global.player["week"]) == 1, "Semana deve continuar 1 no 5º dia")
	print("  ok   Dias 1 a 5 avançam sem virar a semana")

	# 4. Avançar a partir do 5º dia deve disparar virada de semana (rollover)
	# Preenche requisitos de missão para passar a semana
	Global.player["had_no_spend_day"] = true
	Global.register_expense("Pão", "food", 4.0, 5, 1)

	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	# Dá 2 frames para a chamada deferred _process_week_rollover rodar
	await get_tree().process_frame
	await get_tree().process_frame

	assert(TimeManager.current_day == 1, "Após o dia 5, o dia deve resetar para 1")
	assert(int(Global.player["day"]) == 1, "player['day'] deve resetar para 1")
	assert(int(Global.player["week"]) == 2, "Semana deve avançar para 2 após o dia 5")
	print("  ok   Virada de semana ocorre exatamente após o 5º dia")

	print("=== Todos os testes do ciclo de 5 dias passaram ===")
	get_tree().quit(0)
