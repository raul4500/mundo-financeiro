extends Node

signal mission_completed(mission)

# As missões são derivadas do estado do jogador (dinheiro, carteira, estoque),
# e não de eventos. Em vez de instrumentar cada sistema que pode cumprir uma,
# reavaliamos as três missões da semana neste intervalo — o custo é desprezível
# e nenhuma forma de cumprir a missão passa despercebida.
const CHECK_INTERVAL := 0.5

var _check_timer := 0.0
# mission_id -> bool. Espelha o resultado de _check_mission(), então uma missão
# pode voltar a ficar em aberto (gastar o dinheiro que a cumpria). É de
# propósito: o check do painel tem de contar a mesma verdade que a validação
# do fim de semana, senão o jogador vê ✓ e reprova mesmo assim.
var _completed: Dictionary = {}
# -1 força a primeira varredura a semear em silêncio, já no primeiro frame —
# e não no _ready(), quando FIIManager e EnterpriseManager ainda não existem.
var _tracked_week := -1

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
			"description": "Tenha pelo menos R$80,00 até o fim da semana",
			"type": "money_min",
			"value": 80
		},
		{
			"id": "sem_gastar",
			"description": "Não gaste dinheiro por 1 dia",
			"type": "no_spend_day"
		},
		{
			"id": "registrar_gastos",
			"description": "Faça uma compra no mercado",
			"type": "log_expense"
		}
	],
	2: [
		{
			"id": "construir_reserva",
			"description": "Construa uma reserva de emergência (guarde R$120,00 no banco)",
			"type": "bank_min",
			"value": 120
		},
		{
			"id": "economizar_300",
			"description": "Economize R$ 50",
			"type": "money_min",
			"value": 50
		},
		{
			"id": "resolver_evento",
			"description": "Resolva um evento inesperado (pague ou resgate no banco)",
			"type": "pending_event_resolve"
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
			"description": "Analise seus gastos da semana no banco",
			"type": "analyze"
		},
		{
			"id": "economizar_300_s3",
			"description": "Tenha pelo menos R$300,00 até o fim da semana",
			"type": "money_min",
			"value": 300
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
			"id": "lucro_fii",
			"description": "Ganhe R$20 com investimentos",
			"type": "profit",
			"value": 20
		}
	],
	5: [
		{
			"id": "comprar_empreeendimento",
			"description": "Compre pelo menos um empreendimento",
			"type": "buy_any_enterprise"
		},
		{
			"id": "pagar_contas_emp",
			"description": "Pague as contas pendentes do seu empreendimento",
			"type": "pay_enterprise_bill"
		},
		{
			"id": "repor_estoque",
			"description": "Reponha o estoque de um empreendimento",
			"type": "replenish_stock"
		}
	]
}

func get_missions(week: int) -> Array:
	return missions_data.get(week, [])

func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0
	refresh_progress(true)

func is_completed(mission_id: String) -> bool:
	return bool(_completed.get(mission_id, false))

# Zera o acompanhamento para a partida nova não herdar o que já foi anunciado.
func reset_progress() -> void:
	_completed.clear()
	_tracked_week = -1

# Reavalia as missões da semana atual. `notify` liga o aviso na tela; ele é
# desligado sozinho quando a semana vira ou a partida acabou de ser carregada,
# senão uma missão que já nasce cumprida (o dinheiro que sobrou da semana
# anterior) anunciaria uma conquista que o jogador não acabou de fazer.
func refresh_progress(notify: bool = false) -> void:
	if Global.player.is_empty():
		return
	var week := int(Global.player.get("week", 1))
	if week != _tracked_week:
		_tracked_week = week
		_completed.clear()
		notify = false
	for mission in get_missions(week):
		var id := str(mission.get("id", ""))
		var was_done := bool(_completed.get(id, false))
		var done := _check_mission(mission)
		_completed[id] = done
		if done and not was_done and notify:
			_announce(mission)

func _announce(mission: Dictionary) -> void:
	var text := "Missão concluída: %s" % str(mission.get("description", mission.get("id", "")))
	_log_info(text)
	if has_node("/root/NotificationManager"):
		NotificationManager.notify(text)
	emit_signal("mission_completed", mission)

func verify_missions(week: int) -> bool:
	var missions = get_missions(week)
	if missions.is_empty():
		return true
	var failed: Array = []
	for mission in missions:
		if not _check_mission(mission):
			failed.append(mission)
	if failed.size() == 0:
		_log_info("Missões da semana concluídas com sucesso")
		# Alerta de sucesso
		var msg = "Parabéns! Você completou todas as missões desta semana.\n\nVocê será levado para a próxima semana."
		if has_node("/root/AlertManager"):
			AlertManager.alert(msg)
		return true
	else:
		# Montar mensagem listando missões não concluídas
		var text = "Você não completou todas as missões desta semana.\n\nMissões não cumpridas:\n"
		for m in failed:
			text += " - %s\n" % str(m.get("description", m.get("id", "missao")))
		text += "\nVocê precisará repetir a semana até completar todas as missões para avançar. Boa sorte!"
		_log_warning("Missões falharam: %s" % text)
		if has_node("/root/AlertManager"):
			AlertManager.alert(text)
		return false


func _check_mission(mission: Dictionary) -> bool:
	var player = Global.player
	if player == null:
		return false
	match mission["type"]:
		"money_min":
			return float(player.get("money", 0.0)) >= float(mission.get("value", 0.0))
		"bank_min":
			return float(player.get("saldo", 0.0)) >= float(mission.get("value", 0.0))
		"no_spend_day":
			return bool(player.get("had_no_spend_day", false))
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
		"pending_event_resolve":
			# Verifica se o jogador resolveu (pagou ou resgatou) ao menos um evento pendente
			# produzido nesta semana. Só contam eventos com week_generated == semana atual.
			var events = player.get("pending_events", [])
			var current_week = int(player.get("week", 1))
			for ev in events:
				var ev_week = int(ev.get("week_generated", -1))
				if ev_week == current_week and str(ev.get("status", "pending")) != "pending":
					return true
			return false
		"buy_any_enterprise":
			# Checa se o jogador possui qualquer empreendimento
			for ent_id in EnterpriseManager.enterprises.keys():
				if EnterpriseManager.is_owned(ent_id):
					return true
			return false
		"pay_enterprise_bill":
			# Se fornecido enterprise_id, checa essa; caso contrário, checa se existe algum empreendimento sem pendências
			var eid = mission.get("enterprise_id", "")
			if eid != "":
				if not EnterpriseManager.is_owned(eid):
					return false
				return EnterpriseManager.get_pending_bills(eid).size() == 0
			# any owned enterprise with no pending bills
			for ent_id in EnterpriseManager.enterprises.keys():
				if EnterpriseManager.is_owned(ent_id) and EnterpriseManager.get_pending_bills(ent_id).size() == 0:
					return true
			return false
		"replenish_stock":
			# Verifica se em algum empreendimento possuído há estoque maior que zero
			for ent_id in EnterpriseManager.enterprises.keys():
				if not EnterpriseManager.is_owned(ent_id):
					continue
				var state = EnterpriseManager.get_player_enterprise(ent_id)
				for v in state.get("stock", {}).values():
					if int(v) > 0:
						return true
			return false
		_:
			_log_warning("Tipo de missão não implementado: %s" % mission["type"])
			return true

func _game_over():
	_log_warning("Game Over acionado")
	var name = Global.player.get("name", "Player")
	var money = Global.player.get("salary", 0)
	Global.new_game(name, money)
