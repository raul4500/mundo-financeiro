extends Node

var _announced: Array = []

func _ready() -> void:
	print("=== Testando notificações de missão ===")

	Global.player = Global._new_player_data()
	Global.player["week"] = 1
	Global.player["money"] = 0.0
	Global.player["expense_history"] = []
	Global.player["had_no_spend_day"] = false
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.reset_progress()

	# 1. Primeira varredura semeia em silêncio: nada é anunciado nem marcado.
	MissionManager.refresh_progress(true)
	assert(_announced.is_empty(), "A primeira varredura não deveria anunciar nada")
	assert(MissionManager.is_completed("economizar_100") == false, "Sem dinheiro, a missão não está cumprida")
	print("  ok   Primeira varredura semeia em silêncio")

	# 2. Missão já cumprida ao semear não vira notificação — é estado antigo,
	#    não uma conquista que o jogador acabou de fazer.
	MissionManager.reset_progress()
	Global.player["money"] = 500.0
	MissionManager.refresh_progress(true)
	assert(_announced.is_empty(), "Missão já cumprida ao semear não deveria anunciar")
	assert(MissionManager.is_completed("economizar_100") == true, "Com R$500 a missão deveria constar cumprida")
	print("  ok   Missão já cumprida ao semear não notifica")

	# 3. Transição de não-cumprida para cumprida anuncia uma única vez.
	MissionManager.reset_progress()
	Global.player["money"] = 0.0
	MissionManager.refresh_progress(true)
	_announced.clear()
	Global.player["money"] = 150.0
	MissionManager.refresh_progress(true)
	assert(_announced.size() == 1, "Deveria anunciar exatamente 1 missão, veio %d" % _announced.size())
	assert(_announced[0] == "economizar_100", "Missão anunciada errada: %s" % _announced[0])
	MissionManager.refresh_progress(true)
	assert(_announced.size() == 1, "Missão já anunciada não deveria anunciar de novo")
	print("  ok   Transição anuncia uma vez só")

	# 4. Gastar o dinheiro desmarca o check: ele tem de contar a mesma verdade
	#    que a validação do fim de semana, senão o jogador vê o check e reprova.
	Global.player["money"] = 10.0
	MissionManager.refresh_progress(true)
	assert(MissionManager.is_completed("economizar_100") == false, "Sem o dinheiro, o check deveria sumir")
	_announced.clear()
	Global.player["money"] = 200.0
	MissionManager.refresh_progress(true)
	assert(_announced.size() == 1, "Cumprir de novo deveria anunciar de novo")
	print("  ok   Check acompanha o estado real e reanuncia ao recuperar")

	# 5. Virada de semana semeia em silêncio: o dinheiro que sobrou da semana
	#    anterior não vale como conquista da semana nova.
	_announced.clear()
	Global.player["week"] = 2
	Global.player["money"] = 1000.0
	MissionManager.refresh_progress(true)
	assert(_announced.is_empty(), "A virada de semana não deveria anunciar")
	assert(MissionManager.is_completed("construir_reserva") == true, "Com R$1000 a reserva já está cumprida")
	assert(MissionManager.is_completed("economizar_100") == false, "Missão de outra semana não deveria continuar marcada")
	print("  ok   Virada de semana semeia em silêncio")

	# 6. refresh_progress() sem argumento nunca notifica.
	MissionManager.reset_progress()
	Global.player["week"] = 1
	Global.player["money"] = 0.0
	MissionManager.refresh_progress()
	_announced.clear()
	Global.player["money"] = 999.0
	MissionManager.refresh_progress()
	assert(_announced.is_empty(), "refresh_progress() sem notify não deveria anunciar")
	print("  ok   refresh_progress() silencioso por padrão")

	print("=== Todos os testes de notificação de missão passaram ===")

func _on_mission_completed(mission: Dictionary) -> void:
	_announced.append(str(mission.get("id", "")))
