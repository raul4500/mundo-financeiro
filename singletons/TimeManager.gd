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
# sem isto, um jogador que morresse de fome/sede carregava day_end_pending
# preso em true para a partida nova inteira, porque só _advance_to_next_day()
# zera essa flag e ela nunca roda no caminho de morte (ver _close_day()).
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
	if Global.player == null or Global.in_school_minigame:
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
				_faint()
	
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
	AlertManager.alert("Já está tarde! Volte para casa para dormir.\n\nSe virar a noite acordado, vai pagar caro por isso.")

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
		Global.player["hunger"] = 100.0
		Global.player["thirst"] = 100.0
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
	# Morreu de fome no fechamento: o alerta de game-over ja' esta' na tela e
	# nao pode ser sobrescrito pelo alerta do sono (o AlertManager mostra uma
	# caixa por vez, sem fila).
	if not _close_day(100.0):
		return {"success": true, "message": "VOCÊ MORREU DE FOME."}
	AlertManager.alert(
		"Você dormiu e recuperou toda a stamina.\n\nUm novo dia começa às 08:00.",
		false,
		Callable(self, "_advance_to_next_day")
	)
	return {"success": true, "message": "VOCÊ DORMIU."}

func _faint():
	Global.player["money"] = max(0.0, float(Global.player.get("money", 0.0)) - MIDNIGHT_PENALTY)
	if not _close_day(MIDNIGHT_STAMINA):
		return
	AlertManager.alert(
		"Você desmaiou de exaustão e foi socorrido por uma ambulância! - R$ %d" % int(MIDNIGHT_PENALTY),
		false,
		Callable(self, "_advance_to_next_day")
	)

# Meia-noite sem ter dormido: volta para casa a força, paga o café e acorda
# com metade da stamina.
func _handle_midnight() -> void:
	if day_end_pending:
		return
	if Global.is_tutorial_active():
		Global.player["stamina"] = 110.0
		Global.player["hunger"] = 100.0
		Global.player["thirst"] = 100.0
		return
	# Nao precisa mexer na posicao: _advance_to_next_day() liga
	# return_home_next_day e main_game._ready() poe o jogador na porta de casa.
	# Piso em zero: sem isto a penalidade empurrava o saldo cada vez mais fundo
	# no negativo em noites seguidas, sem caminho de recuperação.
	Global.player["money"] = max(0.0, float(Global.player.get("money", 0.0)) - MIDNIGHT_PENALTY)
	if not _close_day(MIDNIGHT_STAMINA):
		return
	AlertManager.alert(
		"Você passou a noite acordado e teve que comprar muito café para aguentar o dia! - R$ %d" % int(MIDNIGHT_PENALTY),
		false,
		Callable(self, "_advance_to_next_day")
	)

# Fechamento contabil comum aos dois caminhos. Nao avanca o dia: isso acontece
# em _advance_to_next_day(), depois que o jogador fecha o alerta.
# Devolve false se o jogador morreu de fome no fechamento.
func _close_day(restored_stamina: float) -> bool:
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
		Global.player["hunger"] = 100.0
		Global.player["thirst"] = 100.0
	else:
		Global.player["stamina"] = clampf(restored_stamina, 0.0, 110.0)
	Global.player["positive_days_count"] = int(Global.player.get("positive_days_count", 0)) + 1
	day_end_pending = true
	Global.play_time = false
	# Por ultimo: se a fome zerou, decay_need_state abre o alerta de game-over.
	# O alerta do fim de dia so' e' aberto depois, por quem chamou, e apenas
	# quando o jogador sobreviveu.
	return Global.decay_need_state()

func _advance_to_next_day() -> void:
	# Morreu de fome no fechamento: o game-over ja' esta' na tela, nao ha'
	# proximo dia para avancar.
	Global.reestore_speed()
	if Global.is_game_over():
		return
	var week_rollover := current_day >= 7
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
	# Verify missions FIRST. Only if they pass should we process the week.
	# If missions fail, the player repeats the week without generating bills,
	# dividends, or applying penalties.
	if MissionManager.verify_missions(week):
		# Missions passed. Process the week.
		EnterpriseManager.generate_all_weekly_bills()
		HouseBillsManager.generate_weekly_bills()
		Global.evaluate_week_status()
		FIIManager.pay_dividends()
		Global.player["week"] = week + 1
		Global.player["no_spend_days_count"] = 0
		Global.player["had_no_spend_day"] = false
		Global.get_paid()
		emit_signal("week_changed", Global.player["week"])
		TutorialManager.on_week_changed(int(Global.player["week"]))
		EventsManager.maybe_spawn_events(int(Global.player["week"]))
	else:
		# Semana repetida: os dias 1-7 vão rodar de novo com o mesmo número de
		# semana. Sem isto, o guard de "já processado" dos empreendimentos
		# barrava a operação diária pela semana inteira (ver
		# EnterpriseManager.reset_operation_guards()), e o "sem gastar" da
		# tentativa fracassada sobrava de graça na repetição.
		EnterpriseManager.reset_operation_guards()
		Global.player["no_spend_days_count"] = 0
		Global.player["had_no_spend_day"] = false
