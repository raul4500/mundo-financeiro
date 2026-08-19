extends Node

func _logger() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("/root/Logger")

func _log_info(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_info(message)
	else:
		print("[INFO] %s" % message)

func _log_warning(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_warning(message)
	else:
		print("[WARN] %s" % message)

var missions_data: Dictionary = {
	1: [
		{
			"id": "economizar_100",
			"description": "Economize R$100",
			"type": "money_min",
			"value": 100
		},
		{
			"id": "sem_gastar",
			"description": "Não gaste dinheiro por 1 dia",
			"type": "no_spend_day"
		},
		{
			"id": "registrar_gastos",
			"description": "Registre seus gastos",
			"type": "log_expense"
		}
	],
	2: [
		{
			"id": "poupanca",
			"description": "Guarde dinheiro na poupança",
			"type": "invest"
		},
		{
			"id": "economizar_300",
			"description": "Economize R$300",
			"type": "money_min",
			"value": 300
		},
		{
			"id": "evitar_impulso",
			"description": "Evite compras impulsivas",
			"type": "no_impulse"
		}
	],
	3: [
		{
			"id": "investir_fundo",
			"description": "Invista em um fundo",
			"type": "invest"
		},
		{
			"id": "analise_gastos",
			"description": "Analise seus gastos da semana",
			"type": "analyze"
		},
		{
			"id": "economizar_500",
			"description": "Economize R$500",
			"type": "money_min",
			"value": 500
		}
	],
	4: [
		{
			"id": "investir_acoes",
			"description": "Invista em ações",
			"type": "invest"
		},
		{
			"id": "diversificar",
			"description": "Diversifique investimentos",
			"type": "diversify"
		},
		{
			"id": "lucro_200",
			"description": "Ganhe R$200 com investimentos",
			"type": "profit",
			"value": 200
		}
	],
	5: [
		{
			"id": "carteira",
			"description": "Monte uma carteira completa",
			"type": "portfolio"
		},
		{
			"id": "alcancar_2000",
			"description": "Alcance R$2000",
			"type": "money_min",
			"value": 2000
		},
		{
			"id": "saldo_positivo",
			"description": "Mantenha saldo positivo por 7 dias",
			"type": "positive_days",
			"value": 7
		}
	]
}

func get_missions(week: int) -> Array:
	return missions_data.get(week, [])

func verify_missions(week: int) -> bool:
	var missions = get_missions(week)
	if missions.is_empty():
		return true
	for mission in missions:
		if not _check_mission(mission):
			_log_warning("Missão falhou: %s" % mission["description"])
			_game_over()
			return false
	_log_info("Missões da semana concluidas com sucesso")
	return true

func _check_mission(mission: Dictionary) -> bool:
	var player = Global.player
	if player == null:
		return false
	match mission["type"]:
		"money_min":
			return float(player.get("money", 0.0)) >= float(mission.get("value", 0.0))
		"no_spend_day":
			return float(player.get("spend_today", 0.0)) == 0.0
		"log_expense":
			return player.get("expense_history", []).size() > 0
		"no_impulse":
			return float(player.get("spend_today", 0.0)) <= float(player.get("salary", 0.0)) * 0.5
		"invest":
			return FIIManager.get_portfolio_value() > 0.0
		"analyze":
			return player.get("expense_history", []).size() > 0
		"diversify":
			return FIIManager.portfolio.keys().size() > 1
		"profit":
			return FIIManager.get_profit() >= float(mission.get("value", 0.0))
		"portfolio":
			return FIIManager.get_portfolio_value() > 0.0
		"positive_days":
			return int(player.get("positive_days_count", 0)) >= int(mission.get("value", 0))
		_:
			_log_warning("Tipo de missão não implementado: %s" % mission["type"])
			return true

func _game_over():
	_log_warning("Game Over acionado")
	var name = Global.player.get("name", "Player")
	var money = Global.player.get("salary", 0)
	Global.new_game(name, money)
