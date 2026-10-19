extends Node

const ParkQuizData = preload("res://scripts/park/park_quiz_data.gd")

func _ready() -> void:
	print("=== Testando Minigame de Moedas do Parque ===")

	Global.player = Global._new_player_data()
	Global.player["week"] = 1
	Global.player["day"] = 1
	# Determinístico: os testes de horário abaixo dependem de um valor
	# conhecido, não do que sobrou de execuções anteriores do jogo.
	TimeManager.current_hour = 8

	# 1. Banco de perguntas: 8 por semana, semanas 1 a 5, gabarito válido.
	for week in range(1, 6):
		var questions = ParkQuizData.get_questions(week)
		assert(questions.size() == 8, "Semana %d deveria ter 8 perguntas" % week)
		for q in questions:
			assert(q.get("options", []).size() == 4, "Pergunta sem 4 alternativas")
			var correct = int(q.get("correct", -1))
			assert(correct >= 0 and correct < 4, "Gabarito fora do intervalo")
	# Semana além da 5 reaproveita o banco da semana 5.
	assert(ParkQuizData.get_questions(9) == ParkQuizData.get_questions(5), "Semana 9 deveria repetir o banco da semana 5")
	print("  ok   Banco de perguntas (8 por semana, gabarito válido)")

	# 2. Cooldown: 2 sessões por dia, depois trava até o próximo dia.
	assert(ParkMinigameManager.can_play() == true, "Deveria poder jogar no início")
	ParkMinigameManager.begin_session()
	ParkMinigameManager.end_session()
	assert(ParkMinigameManager.can_play() == true, "Deveria sobrar 1 tentativa no mesmo dia")
	ParkMinigameManager.begin_session()
	ParkMinigameManager.end_session()
	assert(ParkMinigameManager.can_play() == false, "Não deveria poder jogar após 2 sessões no dia")
	Global.player["day"] = 2
	assert(ParkMinigameManager.can_play() == true, "Cooldown deveria resetar em um novo dia")
	print("  ok   Cooldown de 2 sessões por dia")

	# 3. Sessão ativa bloqueia uma segunda sessão simultânea.
	ParkMinigameManager.begin_session()
	assert(ParkMinigameManager.can_play() == false, "Não deveria poder iniciar 2 sessões ao mesmo tempo")
	ParkMinigameManager.end_session()
	print("  ok   Sessão ativa impede sobreposição")

	# 4. Recompensa do quiz aplica cupom de desconto consumível no mercado.
	Global.player["market_discount"] = 0.0
	ParkMinigameManager.grant_quiz_reward()
	assert(float(Global.player["market_discount"]) == ParkMinigameManager.QUIZ_REWARD_DISCOUNT, "Cupom não foi aplicado")
	print("  ok   Recompensa do quiz aplica cupom de desconto")

	# 5. Trava de status: precisa de fome/sede/stamina >= 50%.
	Global.player["hunger"] = 100.0
	Global.player["thirst"] = 100.0
	Global.player["stamina"] = 100.0
	assert(ParkMinigameManager.can_play() == true, "Deveria poder jogar com status em dia")
	Global.player["stamina"] = 40.0
	assert(ParkMinigameManager.can_play() == false, "Não deveria poder jogar com stamina abaixo de 50%")
	assert(ParkMinigameManager.lock_reason().find("50%") != -1, "Motivo do bloqueio deveria citar o status")
	Global.player["stamina"] = 100.0
	assert(ParkMinigameManager.can_play() == true, "Deveria poder jogar de novo após repor a stamina")
	print("  ok   Trava de status (fome/sede/stamina >= 50%)")

	# 6. Trava de horário: só antes das 16h.
	TimeManager.current_hour = 15
	assert(ParkMinigameManager.can_play() == true, "Deveria poder jogar às 15h")
	TimeManager.current_hour = 16
	assert(ParkMinigameManager.can_play() == false, "Não deveria poder jogar às 16h")
	TimeManager.current_hour = 20
	assert(ParkMinigameManager.can_play() == false, "Não deveria poder jogar à noite")
	TimeManager.current_hour = 8
	assert(ParkMinigameManager.can_play() == true, "Deveria poder jogar de novo pela manhã")
	print("  ok   Trava de horário (antes das 16h)")

	print("=== Todos os testes do minigame do parque passaram ===")
	get_tree().quit(0)
