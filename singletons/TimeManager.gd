extends Node

signal time_changed(hour, minute)
signal day_changed(day)
signal week_changed(week)

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0

var time_scale: float = 5.0
var timer: float = 0.0

func update_time():
	if Global.player == null:
		return
	current_day = int(Global.player.get("day", 1))
	current_hour = int(Global.player.get("hour", 8))
	current_minute = 0
	emit_signal("time_changed", current_hour, current_minute)
	emit_signal("day_changed", current_day)

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
	if Global.player == null:
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
		_add_minute()
	return {"success": true, "minutes": minutes_to_spend}

func _add_minute():
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			var week_rollover := current_day > 7
			if week_rollover:
				current_day = 1
			# Sincroniza antes de qualquer sistema que leia Global.player["day"],
			# senão a operação diária é registrada com o dia anterior.
			Global.player["day"] = current_day
			Global.player["hour"] = current_hour
			Global.decay_need_state()
			Global.player["positive_days_count"] = int(Global.player.get("positive_days_count", 0)) + 1
			EnterpriseManager.process_all_daily_operations()
			if week_rollover:
				var week = int(Global.player.get("week", 1))
				EnterpriseManager.generate_all_weekly_bills()
				Global.evaluate_week_status()
				FIIManager.pay_dividends()
				if MissionManager.verify_missions(week):
					Global.player["week"] = week + 1
					Global.get_paid()
					emit_signal("week_changed", Global.player["week"])
					# Aviso do tutorial daquela semana, se houver. Vem antes
					# do sorteio de evento para o jogador ler a explicação
					# antes de receber a primeira conta inesperada.
					TutorialManager.on_week_changed(int(Global.player["week"]))
					# Eventos inesperados começam na semana 2: o próprio
					# maybe_spawn_events() decide se a semana já permite.
					EventsManager.maybe_spawn_events(int(Global.player["week"]))
				else:
					return
		Global.player["day"] = current_day
		Global.player["hour"] = current_hour
		emit_signal("day_changed", current_day)
	Global.player["hour"] = current_hour
	emit_signal("time_changed", current_hour, current_minute)
