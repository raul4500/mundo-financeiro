extends Node

signal time_changed(hour)
signal day_changed(day)
signal week_changed(week)

var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0

var time_scale: float = 7.0
var timer: float = 0.0
var day_end_pending := false

func update_time():
	if Global.player == null:
		return
	current_day = int(Global.player.get("day", 1))
	current_hour = int(Global.player.get("hour", 8))
	current_minute = 0
	emit_signal("time_changed", current_hour)
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
		if day_end_pending:
			break
		_add_minute()
	return {"success": true, "minutes": minutes_to_spend}

func _add_minute():
	if day_end_pending:
		return
	current_minute += 1
	
	# Apply stamina decay every minute
	# Stamina decays continuously: 100 points over 16 hours (960 minutes)
	# Base rate: 100 / 960 = ~0.104 per minute
	# After 18h: rate doubles
	# At each hour after 18h: rate increases by 10%
	_decay_stamina()
	
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 18 and current_hour < 24:
			_finish_day()
			return
		if current_hour >= 24:
			# Midnight: auto-teleport if awake, charge penalty
			_handle_midnight()
			return
		# Normal hour advancement (8-17, 19-23)
		Global.player["hour"] = current_hour
		emit_signal("time_changed", current_hour)

func _finish_day() -> void:
	current_minute = 0
	Global.player["hour"] = 18
	if float(Global.player.get("spend_today", 0.0)) == 0.0:
		Global.player["had_no_spend_day"] = true
		Global.player["no_spend_days_count"] = int(Global.player.get("no_spend_days_count", 0)) + 1
	EnterpriseManager.process_all_daily_operations()
	Global.decay_need_state()
	Global.player["positive_days_count"] = int(Global.player.get("positive_days_count", 0)) + 1
	day_end_pending = true
	Global.play_time = false
	emit_signal("time_changed", 18)
	AlertManager.alert(
		"O dia terminou. O horário de funcionamento é das 08:00 às 18:00.\n\nClique em OK para descansar e continuar no próximo dia.",
		false,
		Callable(self, "_advance_to_next_day")
	)

func _decay_stamina() -> void:
	# Stamina decays continuously throughout the day.
	# Base rate: 100 stamina / 960 minutes (16 hours) = 0.104 per minute
	# After 18h: rate doubles
	# Each additional hour after 18h: rate increases by 10%
	
	if Global.player == null:
		return
	
	var stamina = float(Global.player.get("stamina", 100.0))
	if stamina <= 0.0:
		return
	
	var decay_rate = 0.104  # Base rate per minute
	var hour = current_hour
	
	# After 18h, acceleration kicks in
	if hour >= 18:
		# From 18h onwards, decay rate doubles (2x)
		# Plus 10% increase per additional hour
		decay_rate = 0.208  # 2x base rate
		var hours_after_18 = hour - 18
		if hours_after_18 > 0:
			decay_rate *= (1.0 + (hours_after_18 * 0.1))
	
	stamina = clampf(stamina - decay_rate, 0.0, 100.0)
	Global.player["stamina"] = stamina
	
	# Check if stamina reached 0
	if stamina <= 0.0 and hour < 18:
		# Before 18h: stamina depleted, show alert (no game-over yet)
		AlertManager.alert("Você está muito cansado! Volte para casa para descansar.")
		Global.play_time = false
		Global.lock_gameplay()
	elif stamina <= 0.0 and hour >= 18:
		# After 18h: stamina depleted, accelerated decay continues
		# At midnight, will be handled by _handle_midnight()
		pass

func _handle_midnight() -> void:
	# Called at midnight (00h) if player is still awake
	var stamina = float(Global.player.get("stamina", 100.0))
	
	if stamina > 0.0:
		# Player still awake at midnight
		# Teleport to home, charge penalty, reduce stamina to 50%
		Global.player["position"] = {"x": 180.0, "y": 210.0}
		Global.player["money"] = float(Global.player.get("money", 0.0)) - 30.0
		Global.player["stamina"] = 50.0
		
		AlertManager.alert("Você passou a noite acordado e teve que comprar muito café para aguentar o dia! - R$ 30")
		# Force return to main game at home
		TransitionManager.change_scene("res://scenes/world/main_game.tscn")
	
	# Continue to next day
	current_hour = 0
	current_day += 1
	var week_rollover := current_day > 7
	if week_rollover:
		current_day = 1
	
	Global.player["day"] = current_day
	Global.player["hour"] = current_hour
	Global.player["spend_today"] = 0.0
	Global.player["positive_days_count"] = int(Global.player.get("positive_days_count", 0)) + 1
	
	emit_signal("day_changed", current_day)
	emit_signal("time_changed", current_hour)
	
	if week_rollover:
		call_deferred("_process_week_rollover")

func _advance_to_next_day() -> void:
	var week_rollover := current_day >= 7
	current_day = 1 if week_rollover else current_day + 1
	current_hour = 8
	current_minute = 0
	timer = 0.0
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
