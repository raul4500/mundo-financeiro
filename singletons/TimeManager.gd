extends Node

signal time_changed(hour)
signal day_changed(day)
signal week_changed(week)

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0

var time_scale: float = 7.0
var timer: float = 0.0
# Trava o relogio entre o fim de um dia e o inicio do proximo. Enquanto ligada,
# _add_minute() e spend_hours() nao avancam nada.
var day_end_pending := false

# Hora em que o dia comeca e hora em que o jogo avisa que e' preciso descansar.
# O dia NAO acaba sozinho as 18h: o jogador precisa ir ate a casa e dormir.
const DAY_START_HOUR := 8
const EXHAUSTION_HOUR := 18
const MIDNIGHT_HOUR := 24
const DAYS_PER_WEEK := 5

# 100 de stamina divididos pelas 960 horas-jogo entre 08h e 24h (16h = 960 min).
const STAMINA_DECAY_PER_MINUTE := 110.0 / 960.0
# Depois das 19h a queda dobra e ganha mais 10% por hora (ver BUGFIX_PLAN 7.2).
const ACCEL_START_HOUR := 19
const MIDNIGHT_PENALTY := 30.0
const MIDNIGHT_STAMINA := 50.0

# Um aviso por dia. Sem isto o alerta reabriria a cada minuto de jogo.
var _exhaustion_alert_shown := false
var _no_stamina_alert_shown := false

func update_time():
	if Global.player == null:
		return
	current_day = int(Global.player.get("day", 1))
	current_hour = int(Global.player.get("hour", 8))
	current_minute = 0
	emit_signal("time_changed", current_hour)
	emit_signal("day_changed", current_day)

# Chamado por Global.new_game(). TimeManager é autoload e sobrevive a um game
# over (o processo continua rodando, só a cena troca para o menu principal):
# sem isto, day_end_pending preso em true (só _advance_to_next_day() zera essa
# flag, e ela não roda quando um game over interrompe o fechamento do dia)
# travava o relógio da partida nova inteira.
func reset() -> void:
	day_end_pending = false
	timer = 0.0
	_exhaustion_alert_shown = false
	_no_stamina_alert_shown = false

func _logger() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("/root/Logger")

func _ready() -> void:
	var logger = _logger()
	if logger != null:
		logger.log_info("TimeManager inicializado")
	update_time()

func _process(delta):
	if Global.player == null or Global.time_frozen_by_scene() or Global.is_any_tutorial_active():
		return
	if Global.play_time == true:
		timer += delta * time_scale
		if timer >= 1.0:
			timer = 0.0
			_add_minute()

func spend_hours(hours: float) -> Dictionary:
	if hours <= 0.0:
		return {"success": false, "message": "O tempo precisa ser maior que zero."}
	if Global.player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	if Global.is_any_tutorial_active():
		return {"success": true, "minutes": 0}

	var minutes_to_spend := int(round(hours * 60.0))
	for _minute in range(minutes_to_spend):
		if day_end_pending:
			break
		_add_minute()
	return {"success": true, "minutes": minutes_to_spend}

func _add_minute():
	if day_end_pending:
		return
	current_minute += 1
	
	var no_stamina = _decay_stamina()
	if no_stamina:
		var no_speed = Global.lose_speed()
		if no_speed:
			_faint("exaustão")
			return

	Global.decay_need_state()
	# Fome ou sede em zero: mesmo desfecho da exaustão total.
	if collapse_if_needs_depleted() != "":
		return

	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
		if current_hour >= MIDNIGHT_HOUR:
			_handle_midnight()
			return
		Global.player["hour"] = current_hour
		emit_signal("time_changed", current_hour)
		if current_hour >= EXHAUSTION_HOUR:
			_warn_exhaustion()

# Aviso das 18h. O dia continua correndo: quem encerra o dia e' o jogador,
# indo ate a casa e clicando em DORMIR (home.gd), ou a meia-noite.
func _warn_exhaustion() -> void:
	if _exhaustion_alert_shown:
		return
	if Global.is_tutorial_active():
		return
	_exhaustion_alert_shown = true
	AlertManager.alert("Já está tarde! Lembre-se de dormir.\n\nSe virar a noite acordado, vai pagar caro por isso.")

# =============================================================
# QUEDA DE STAMINA
# Base: 100 pontos em 16 horas de jogo (08h -> 24h).
# Ate as 18h a taxa e' a base. A partir das 19h ela dobra e ganha mais 10%
# por hora: 19h = 2.0x, 20h = 2.2x, 21h = 2.4x, ...
# =============================================================
func _decay_stamina() -> bool:
	if Global.player == null:
		return false
	if Global.is_tutorial_active():
		Global.player["stamina"] = 110.0
		Global.player["hunger"] = 110.0
		Global.player["thirst"] = 110.0
		return false
		
	var stamina := float(Global.player.get("stamina", 110.0))

	var decay_rate := STAMINA_DECAY_PER_MINUTE
	if current_hour >= ACCEL_START_HOUR:
		decay_rate *= 2.0 * (1.0 + float(current_hour - ACCEL_START_HOUR) * 0.1)

	stamina = clampf(stamina - decay_rate, 0.0, 110.0)
	
	if stamina < 10.0:
		if not _no_stamina_alert_shown:
			NotificationManager.notify("Você está exausto, volte para casa imediatamente!")
			_no_stamina_alert_shown = true
		Global.player["stamina"] = stamina
		return true
		
	Global.player["stamina"] = stamina
	return false
	

# =============================================================
# FIM DO DIA
# Dois caminhos: dormir em casa (stamina cheia) ou virar a noite (penalidade).
# Ambos passam pelo mesmo fechamento contabil.
# =============================================================

# Chamado pelo botao DORMIR da casa (scripts/world/home/home.gd).
func sleep() -> Dictionary:
	if Global.player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	if day_end_pending:
		return {"success": false, "message": "O dia já terminou."}
	# Sem esta trava o jogador dormiria as 08h01 sete vezes seguidas e viraria
	# a semana — com salario e dividendos — pagando so' a fome de sete dias.
	# ponytail: "stamina <= 0 libera dormir cedo" e' inatingivel hoje (a queda
	# passiva tira no maximo ~62 de 100 ate' as 18h) — se uma acao futura
	# drenar stamina mais rapido, reabrir esse caminho como exploit.
	if current_hour < EXHAUSTION_HOUR and float(Global.player.get("stamina", 110.0)) > 0.0:
		return {
			"success": false,
			"message": "AINDA É CEDO PARA DORMIR. VOLTE DEPOIS DAS %02dH." % EXHAUSTION_HOUR
		}
	_close_day(110.0)
	AlertManager.alert(
		"Você dormiu e recuperou toda a stamina.\n\nUm novo dia começa às 08:00.",
		false,
		Callable(self, "_advance_to_next_day")
	)
	return {"success": true, "message": "VOCÊ DORMIU."}

# Desmaio: cobra a penalidade, fecha o dia e leva o jogador para casa no dia
# seguinte (via _advance_to_next_day, quando ele fecha o alerta). `cause` é só o
# texto: "exaustão", "fome", "sede" ou "fome e sede". Piso em zero no dinheiro:
# sem dinheiro a cobrança não deixa o saldo negativo nem trava o resgate.
func _faint(cause: String) -> String:
	Global.player["money"] = max(0.0, float(Global.player.get("money", 0.0)) - MIDNIGHT_PENALTY)
	_close_day(MIDNIGHT_STAMINA)
	var message := "Você desmaiou de %s e foi socorrido por uma ambulância! - R$ %d" % [cause, int(MIDNIGHT_PENALTY)]
	AlertManager.alert(message, false, Callable(self, "_advance_to_next_day"))
	return message

# Fome ou sede zeradas não matam: o jogador desmaia, igual à exaustão total.
# Devolve o texto do desmaio, ou "" se nada estava zerado. Chamada por
# _add_minute() e por quem muda fome/sede de uma vez (Global.apply_home_action).
func collapse_if_needs_depleted() -> String:
	if day_end_pending or Global.player == null:
		return ""
	var depleted := Global.depleted_needs()
	if depleted.is_empty():
		return ""
	var cause := "fome e sede"
	if depleted.size() == 1:
		cause = "fome" if depleted[0] == "hunger" else "sede"
	return _faint(cause)

# Meia-noite sem ter dormido: volta para casa a força, paga o café e acorda
# com metade da stamina.
func _handle_midnight() -> void:
	if day_end_pending:
		return
	if Global.is_tutorial_active():
		Global.player["stamina"] = 110.0
		Global.player["hunger"] = 110.0
		Global.player["thirst"] = 110.0
		return
	# Nao precisa mexer na posicao: _advance_to_next_day() liga
	# return_home_next_day e main_game._ready() poe o jogador na porta de casa.
	# Piso em zero: sem isto a penalidade empurrava o saldo cada vez mais fundo
	# no negativo em noites seguidas, sem caminho de recuperação.
	Global.player["money"] = max(0.0, float(Global.player.get("money", 0.0)) - MIDNIGHT_PENALTY)
	_close_day(MIDNIGHT_STAMINA)
	AlertManager.alert(
		"Você passou a noite acordado e teve que comprar muito café para aguentar o dia! - R$ %d" % int(MIDNIGHT_PENALTY),
		false,
		Callable(self, "_advance_to_next_day")
	)

# Fechamento contabil comum aos dois caminhos. Nao avanca o dia: isso acontece
# em _advance_to_next_day(), depois que o jogador fecha o alerta.
func _close_day(restored_stamina: float) -> void:
	current_minute = 0
	if float(Global.player.get("spend_today", 0.0)) == 0.0:
		Global.player["had_no_spend_day"] = true
		Global.player["no_spend_days_count"] = int(Global.player.get("no_spend_days_count", 0)) + 1
	EnterpriseManager.process_all_daily_operations()
	# Preço de FII muda por dia, no mesmo fechamento que já processa os
	# empreendimentos — sem isto update_prices() nunca era chamado por ninguém
	# e a "volatilidade" dos fundos ficava só no papel.
	FIIManager.update_prices()
	if Global.is_tutorial_active():
		Global.player["stamina"] = 110.0
		Global.player["hunger"] = 110.0
		Global.player["thirst"] = 110.0
	else:
		Global.player["stamina"] = clampf(restored_stamina, 0.0, 110.0)
		# Quem desmaiou de fome/sede acorda com a necessidade em MIDNIGHT_STAMINA
		# (mesmo valor da stamina de quem desmaia), senão desmaiaria de novo no
		# primeiro minuto do dia seguinte, em loop.
		Global.restore_depleted_needs(MIDNIGHT_STAMINA)
	Global.player["positive_days_count"] = int(Global.player.get("positive_days_count", 0)) + 1
	day_end_pending = true
	Global.play_time = false
	Global.decay_need_state()

func _advance_to_next_day() -> void:
	Global.reestore_speed()
	# Game over em curso (trigger_game_over): nao ha' proximo dia para avancar.
	if Global.is_game_over():
		return
	var week_rollover := current_day >= DAYS_PER_WEEK
	current_day = 1 if week_rollover else current_day + 1
	current_hour = DAY_START_HOUR
	current_minute = 0
	timer = 0.0
	_exhaustion_alert_shown = false
	_no_stamina_alert_shown = false
	Global.player["day"] = current_day
	Global.player["hour"] = current_hour
	Global.player["spend_today"] = 0.0
	Global.player["return_home_next_day"] = true
	day_end_pending = false
	Global.play_time = false
	emit_signal("day_changed", current_day)
	emit_signal("time_changed", current_hour)
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
	if week_rollover:
		call_deferred("_process_week_rollover")

func _process_week_rollover() -> void:
	var week := int(Global.player.get("week", 1))
	# Dividendos da semana pagos antes da verificação: contam para a missão de lucro de investimentos.
	FIIManager.pay_dividends()

	# Missões primeiro: só se passarem a semana é processada. Se falharem, o
	# jogador repete a semana sem gerar contas nem penalidades.
	#
	# Passando, antes de liberar a próxima semana o jogo cobra sozinho as contas
	# (da casa e eventos) cuja data limite chegou. O salário entra antes da
	# cobrança, então ele conta para cobrir as contas. Sem fundos suficientes
	# (carteira + banco + salário) a semana se repete. Essa checagem vem ANTES de
	# verify_missions() para o "Parabéns, você vai para a próxima semana" não
	# aparecer logo antes de um "você perdeu a semana".
	var debts_due := _debts_due_through(week)
	# A penalidade de semana com necessidade crítica sai da carteira DEPOIS desta
	# checagem (evaluate_week_status), então entra na conta aqui.
	var funds_with_salary := Global.total_funds() + float(Global.player.get("salary", 0)) - Global.week_status_penalty_preview()
	if debts_due > funds_with_salary + 0.001 and MissionManager.all_passed(week):
		AlertManager.alert(
			"Você completou as missões, mas não tem dinheiro suficiente para quitar as contas que chegaram à data limite.\n\nContas a cobrar: R$ %.2f\nDisponível (carteira + banco + salário): R$ %.2f\n\nVocê perdeu esta semana: ela recomeça com o dinheiro que você tinha no início dela." % [debts_due, funds_with_salary]
		)
		_repeat_week()
		return
	if not MissionManager.verify_missions(week):
		_repeat_week()
		# O jogador trabalhou os 5 dias desta tentativa: recebe o salário pelo trabalho realizado,
		# permitindo acumular capital caso precise repetir a semana para juntar dinheiro.
		var salary := float(Global.player.get("salary", 200))
		Global.player["money"] = float(Global.player.get("money", 0.0)) + salary
		Global.snapshot_week_start()
		return

	EnterpriseManager.generate_all_weekly_bills()
	HouseBillsManager.generate_weekly_bills()
	Global.evaluate_week_status()
	Global.player["week"] = week + 1
	Global.player["no_spend_days_count"] = 0
	Global.player["had_no_spend_day"] = false
	Global.get_paid()
	_settle_debts_through(week, debts_due)
	if debts_due > 0.0:
		NotificationManager.notify("Contas vencidas cobradas automaticamente: R$ %.2f" % debts_due, 5.0)
	emit_signal("week_changed", Global.player["week"])
	TutorialManager.on_week_changed(int(Global.player["week"]))
	EventsManager.maybe_spawn_events(int(Global.player["week"]))
	# Por último: eventos já nasceram, então a foto inclui tudo o que o jogador
	# encontra ao começar a semana nova. É para onde ele volta se repetir.
	Global.snapshot_week_start()

func _debts_due_through(week: int) -> float:
	return snappedf(HouseBillsManager.total_due_through(week) + EventsManager.total_due_through(week), 0.01)

func _settle_debts_through(week: int, total: float) -> void:
	# O total já foi checado contra os fundos em _process_week_rollover().
	Global.charge_funds(total)
	HouseBillsManager.settle_through(week)
	EventsManager.settle_through(week)

# Semana repetida: os dias 1-5 vão rodar de novo com o mesmo número de semana.
func _repeat_week() -> void:
	# Sem isto, o guard de "já processado" dos empreendimentos barrava a
	# operação diária pela semana inteira (ver
	# EnterpriseManager.reset_operation_guards()), e o "sem gastar" da
	# tentativa fracassada sobrava de graça na repetição.
	EnterpriseManager.reset_operation_guards()
	Global.player["no_spend_days_count"] = 0
	Global.player["had_no_spend_day"] = false
	# Dinheiro, banco e contas voltam ao que eram no início da semana.
	Global.restore_week_start()
