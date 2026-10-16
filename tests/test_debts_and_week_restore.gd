extends Node

const DebtRules = preload("res://scripts/economy/debt_rules.gd")

func _fresh() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 500.0
	Global.player["saldo"] = 0.0
	Global.player["salary"] = 200
	Global.player["week"] = 3
	Global.player["day"] = 1
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	Global.in_office = false
	Global.in_school_minigame = false
	TimeManager.day_end_pending = false
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

func _bill(week_generated: int, amount: float) -> Dictionary:
	return {
		"id": "t_%d_%d" % [week_generated, int(amount)],
		"title": "Conta teste",
		"description": "",
		"amount": amount,
		"week": week_generated,
		"due_week": week_generated + 1,
		"limit_week": week_generated + 2,
		"paid": false
	}

func _ready() -> void:
	print("=== Testando juros, cobrança automática, foto da semana e escritório ===")

	# 1. Juros: dia do vencimento sem juros, depois 10% ao dia composto.
	var dpw: int = Global.DAYS_PER_WEEK
	assert(DebtRules.overdue_days(3 * dpw, 3, dpw) == 0, "No dia do vencimento não há atraso")
	assert(DebtRules.overdue_days(2 * dpw + 4, 3, dpw) == 0, "Antes de vencer não há atraso")
	assert(DebtRules.overdue_days(3 * dpw + 1, 3, dpw) == 1, "Primeiro dia da semana seguinte = 1 dia de atraso")
	assert(is_equal_approx(DebtRules.amount_with_interest(100.0, 0), 100.0), "Sem atraso, valor original")
	assert(is_equal_approx(DebtRules.amount_with_interest(100.0, 1), 110.0), "1 dia: +10%")
	assert(is_equal_approx(DebtRules.amount_with_interest(100.0, 2), 121.0), "2 dias: composto (121, não 120)")
	assert(is_equal_approx(DebtRules.amount_with_interest(100.0, 5), 161.05), "5 dias: 100 * 1,1^5")
	print("  ok   Juros de 10% ao dia, compostos, a partir do dia seguinte ao vencimento")

	# 2. Conta da casa: vencimento no fim da semana 3, limite no fim da semana 4.
	_fresh()
	Global.player["week"] = 2
	HouseBillsManager.generate_weekly_bills()
	var bills: Array = HouseBillsManager.get_pending_bills()
	assert(bills.size() == 3, "Deveria gerar 3 contas da casa")
	for b in bills:
		assert(HouseBillsManager.bill_due_week(b) == 3, "Conta gerada na semana 2 vence na 3")
		assert(HouseBillsManager.bill_limit_week(b) == 4, "Conta gerada na semana 2 tem limite na 4")
	var base_total := 30.0 + 45.0 + 75.0
	assert(HouseBillsManager.total_due_through(3) == 0.0, "Fim da semana 3 ainda não é a data limite")
	assert(HouseBillsManager.total_due_through(4) > base_total, "No limite, o total inclui juros")
	var expected := 0.0
	for amount in [30.0, 45.0, 75.0]:
		expected += DebtRules.amount_with_interest(amount, dpw)
	assert(is_equal_approx(HouseBillsManager.total_due_through(4), snappedf(expected, 0.01)), "Limite = valor com 5 dias de juros")
	print("  ok   Contas da casa: vencimento na semana 3, limite na 4, juros acumulados")

	# 3. Evento: vence no fim da semana em que nasceu, limite na seguinte; bônus fora.
	_fresh()
	Global.player["week"] = 3
	EventsManager.create_pending_event({"id": "t_conta", "titulo": "Conta", "descricao": ""}, {"dinheiro": -200})
	EventsManager.create_pending_event({"id": "t_bonus", "titulo": "Bônus", "descricao": ""}, {"dinheiro": 300})
	var debt: Dictionary = {}
	for ev in EventsManager.get_pending_events("bank"):
		if not bool(ev.get("is_bonus", false)):
			debt = ev
	assert(EventsManager.event_due_week(debt) == 3 and EventsManager.event_limit_week(debt) == 4, "Evento: vence 3, limite 4")
	assert(EventsManager.total_due_through(3) == 0.0, "Evento ainda não chegou ao limite na semana 3")
	assert(EventsManager.total_due_through(4) == DebtRules.amount_with_interest(200.0, dpw), "Bônus não entra na cobrança")
	print("  ok   Evento vence na semana de origem; bônus nunca é cobrado")

	# 4. Fundos: carteira primeiro, depois banco; falta de fundos não mexe em nada.
	_fresh()
	Global.player["money"] = 100.0
	Global.player["saldo"] = 50.0
	assert(Global.total_funds() == 150.0, "Fundos = carteira + banco")
	assert(Global.charge_funds(120.0), "120 cabem em 150")
	assert(is_equal_approx(Global.player["money"], 0.0) and is_equal_approx(Global.player["saldo"], 30.0), "Tira da carteira antes do banco")
	assert(not Global.charge_funds(31.0), "31 não cabem em 30")
	assert(is_equal_approx(Global.player["money"], 0.0) and is_equal_approx(Global.player["saldo"], 30.0), "Recusa não altera nada")
	print("  ok   charge_funds usa carteira e depois banco, e recusa sem alterar")

	# 5. Pagar manualmente uma conta vencida custa o valor com juros.
	_fresh()
	Global.player["week"] = 4
	Global.player["day"] = 1
	Global.player["pending_house_bills"] = [_bill(2, 100.0)]
	var manual := HouseBillsManager.pay_bill("t_2_100")
	assert(manual["success"], "Deveria pagar")
	assert(is_equal_approx(Global.player["money"], 500.0 - 110.0), "Dia 1 da semana 4 = 1 dia de atraso = R$110")
	print("  ok   Pagamento manual de conta vencida inclui juros")

	# 6. Cobrança automática marca as contas e NÃO conta como gasto do dia.
	_fresh()
	Global.player["week"] = 4
	Global.player["pending_house_bills"] = [_bill(2, 100.0), _bill(3, 50.0)]
	Global.player["spend_today"] = 0.0
	var due := HouseBillsManager.total_due_through(4)
	assert(due == DebtRules.amount_with_interest(100.0, dpw), "Só a conta com limite na semana 4 entra; a outra ainda tem prazo")
	HouseBillsManager.settle_through(4)
	assert(HouseBillsManager.get_pending_bills().size() == 1, "A conta com limite posterior continua pendente")
	assert(Global.player["house_bill_history"].size() == 1, "A quitada vai para o histórico")
	assert(float(Global.player.get("spend_today", 0.0)) == 0.0, "Cobrança automática não estraga o dia sem gastar")
	print("  ok   Cobrança automática quita só o que chegou ao limite")

	# 7. Foto da semana: dinheiro, banco e contas voltam; pagar na tentativa não perdoa a dívida.
	_fresh()
	Global.player["money"] = 500.0
	Global.player["saldo"] = 80.0
	Global.player["pending_house_bills"] = [_bill(2, 100.0)]
	Global.snapshot_week_start()
	Global.player["money"] = 200.0
	Global.player["saldo"] = 0.0
	HouseBillsManager.pay_bill("t_2_100")
	assert(HouseBillsManager.get_pending_bills().is_empty(), "Conta paga na tentativa")
	TimeManager._repeat_week()
	assert(Global.player["money"] == 500.0 and Global.player["saldo"] == 80.0, "Dinheiro total volta ao início da semana")
	assert(HouseBillsManager.get_pending_bills().size() == 1, "A conta paga na tentativa volta a ficar pendente")
	print("  ok   Semana repetida restaura carteira, banco e contas")

	# 8. Save antigo sem foto adota o estado atual em vez de ficar sem volta.
	_fresh()
	Global.player["week_snapshot"] = {}
	Global.player["money"] = 321.0
	Global.ensure_player_state()
	assert(Global.player["week_snapshot"]["money"] == 321.0, "Foto criada a partir do estado atual")
	print("  ok   Save sem foto da semana recebe uma")

	# 8b. A penalidade de semana ruim é prevista para a checagem de fundos.
	_fresh()
	Global.player["hunger"] = 100.0
	Global.player["thirst"] = 100.0
	Global.player["stamina"] = 100.0
	assert(Global.week_status_penalty_preview() == 0.0, "Necessidades em dia: sem penalidade")
	Global.player["thirst"] = 20.0
	assert(Global.week_status_penalty_preview() == Global.WEEK_STATUS_PENALTY, "Sede crítica: penalidade prevista")
	print("  ok   Penalidade da semana é prevista antes da cobrança automática")

	# 9. Escritório: relógio parado, e nada religa play_time lá dentro.
	_fresh()
	Global.in_office = true
	Global.play_time = false
	assert(Global.time_frozen_by_scene(), "Escritório congela o tempo")
	AlertManager.alert("teste dentro do escritório")
	AlertManager._close_alert()
	assert(Global.play_time == false, "Fechar alerta no escritório NÃO religa play_time")
	Global.force_release_all_gameplay_locks()
	assert(Global.play_time == false, "Soltar travas no escritório NÃO religa play_time")
	var minute_before := TimeManager.current_minute
	TimeManager._process(10.0)
	assert(TimeManager.current_minute == minute_before, "TimeManager não avança dentro do escritório")
	Global.in_office = false
	assert(not Global.time_frozen_by_scene(), "Fora do escritório o tempo volta a poder correr")
	print("  ok   Tempo congelado dentro do escritório")

	print("=== Todos os testes de contas/semana/escritório passaram ===")
	get_tree().quit(0)
