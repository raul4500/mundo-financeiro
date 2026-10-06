extends CanvasLayer

## Módulo temporário de comandos rápidos (cheats) para apresentação e testes (TCC).
## Para desativar/remover pós-TCC, basta remover este autoload em project.godot e excluir este arquivo.

const CHEATS_ENABLED: bool = true

const SPEED_PRESETS: Array[float] = [7.0, 35.0, 140.0]
var _speed_index: int = 0

var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween

var _help_panel: PanelContainer
var _help_visible: bool = false

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()

func _create_ui() -> void:
	# Toast Notification (Topo da tela)
	_toast_panel = PanelContainer.new()
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_left = -260.0
	_toast_panel.offset_right = 260.0
	_toast_panel.offset_top = 16.0
	_toast_panel.offset_bottom = 56.0
	
	var toast_style = StyleBoxFlat.new()
	toast_style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	toast_style.border_color = Color(0.2, 0.7, 1.0, 0.9)
	toast_style.border_width_bottom = 2
	toast_style.border_width_left = 2
	toast_style.border_width_right = 2
	toast_style.border_width_top = 2
	toast_style.corner_radius_bottom_left = 8
	toast_style.corner_radius_bottom_right = 8
	toast_style.corner_radius_top_left = 8
	toast_style.corner_radius_top_right = 8
	_toast_panel.add_theme_stylebox_override("panel", toast_style)
	
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_panel.add_child(_toast_label)
	add_child(_toast_panel)
	
	# Painel de Ajuda / Cola de Comandos (Canto Superior Direito)
	_help_panel = PanelContainer.new()
	_help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_help_panel.visible = false
	_help_panel.anchor_left = 1.0
	_help_panel.anchor_right = 1.0
	_help_panel.anchor_top = 0.0
	_help_panel.anchor_bottom = 0.0
	_help_panel.offset_left = -390.0
	_help_panel.offset_right = -12.0
	_help_panel.offset_top = 12.0
	_help_panel.offset_bottom = 330.0
	
	var help_style = StyleBoxFlat.new()
	help_style.bg_color = Color(0.05, 0.06, 0.09, 0.94)
	help_style.border_color = Color(0.4, 0.8, 0.5, 0.9)
	help_style.border_width_bottom = 2
	help_style.border_width_left = 2
	help_style.border_width_right = 2
	help_style.border_width_top = 2
	help_style.corner_radius_bottom_left = 8
	help_style.corner_radius_bottom_right = 8
	help_style.corner_radius_top_left = 8
	help_style.corner_radius_top_right = 8
	_help_panel.add_theme_stylebox_override("panel", help_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_help_panel.add_child(margin)
	
	var help_label = Label.new()
	help_label.text = """[DEBUG CHEATS - GUIA TCC]
[1] Vel. Tempo (Normal / 5x / 20x)
[2] Avançar Dia (+1 Dia às 08h)
[3] Avançar Semana (Com Salário/Contas)
[4] Injetar Dinheiro (+R$ 5.000)
[5] Concluir Missões da Semana
[6] God Mode (Fome/Sede/Stamina 100%)
[7] Destravar Tudo (Pular Tutorial/Portas)
[8] Escolaridade (+1 Nível & Cooldown)
[9] Gerar Evento Inesperado (Banco)
[0] Setup Rápido: Restaurante
[F1] ou [H] Mostrar/Ocultar esta ajuda"""
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	margin.add_child(help_label)
	
	add_child(_help_panel)

func _show_toast(message: String) -> void:
	if _toast_panel == null or _toast_label == null:
		return
	_toast_label.text = "[DEBUG] " + message
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(Callable(_toast_panel, "hide"))

func _toggle_help_overlay() -> void:
	_help_visible = not _help_visible
	_help_panel.visible = _help_visible
	if _help_visible:
		_show_toast("Ajuda de comandos ativada.")

func _unhandled_input(event: InputEvent) -> void:
	if not CHEATS_ENABLED:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	var code := key_event.keycode
	var pcode := key_event.physical_keycode
	
	# Ajuda (F1 ou H)
	if code == KEY_F1 or pcode == KEY_F1 or code == KEY_H or pcode == KEY_H:
		_toggle_help_overlay()
		return
	
	# Somente executa cheats se o jogo estiver inicializado com jogador válido
	if Global.player == null or str(Global.player.get("name", "")) == "":
		return

	if _matches_key(code, pcode, KEY_1, KEY_KP_1):
		_cmd_speed_time()
	elif _matches_key(code, pcode, KEY_2, KEY_KP_2):
		_cmd_advance_day()
	elif _matches_key(code, pcode, KEY_3, KEY_KP_3):
		_cmd_advance_week()
	elif _matches_key(code, pcode, KEY_4, KEY_KP_4):
		_cmd_add_money()
	elif _matches_key(code, pcode, KEY_5, KEY_KP_5):
		_cmd_complete_missions()
	elif _matches_key(code, pcode, KEY_6, KEY_KP_6):
		_cmd_max_needs()
	elif _matches_key(code, pcode, KEY_7, KEY_KP_7):
		_cmd_unlock_all()
	elif _matches_key(code, pcode, KEY_8, KEY_KP_8):
		_cmd_level_up_school()
	elif _matches_key(code, pcode, KEY_9, KEY_KP_9):
		_cmd_spawn_event()
	elif _matches_key(code, pcode, KEY_0, KEY_KP_0):
		_cmd_setup_enterprise()

func _matches_key(code: int, pcode: int, k1: int, k2: int) -> bool:
	return code == k1 or pcode == k1 or code == k2 or pcode == k2

# =============================================================
# COMANDOS DE DEBUG (0 a 9)
# =============================================================

# [1] Velocidade do Tempo
func _cmd_speed_time() -> void:
	_speed_index = (_speed_index + 1) % SPEED_PRESETS.size()
	var new_speed: float = SPEED_PRESETS[_speed_index]
	TimeManager.time_scale = new_speed
	var label := "Normal (7x)"
	if _speed_index == 1:
		label = "Rápido (35x)"
	elif _speed_index == 2:
		label = "Ultra-Rápido (140x)"
	_show_toast("Tempo: Velocidade %s" % label)

# [2] Avançar Dia
func _cmd_advance_day() -> void:
	TimeManager.current_day = int(Global.player.get("day", 1))
	TimeManager.current_hour = int(Global.player.get("hour", 8))
	# Fecha o dia contabilmente com stamina restaurada
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	var day_num := int(Global.player.get("day", 1))
	_show_toast("Dia avançado para o Dia %d (08:00)" % day_num)

# [3] Avançar Semana
func _cmd_advance_week() -> void:
	_fulfill_missions_data()
	var cur_w := int(Global.player.get("week", 1))
	TimeManager.current_day = Global.DAYS_PER_WEEK
	Global.player["day"] = Global.DAYS_PER_WEEK
	TimeManager._close_day(100.0)
	TimeManager._advance_to_next_day()
	_show_toast("Semana avançada! Agora na Semana %d" % int(Global.player.get("week", cur_w + 1)))

# [4] Injetar Dinheiro (+R$ 5.000)
func _cmd_add_money() -> void:
	var bonus := 5000.0
	var cur := float(Global.player.get("money", 0.0))
	Global.player["money"] = cur + bonus
	_show_toast("+R$ 5.000,00 adicionados! Total: R$ %.2f" % Global.player["money"])

# [5] Completar Missões da Semana Atual
func _cmd_complete_missions() -> void:
	_fulfill_missions_data()
	_show_toast("Missões da Semana %d cumpridas!" % int(Global.player.get("week", 1)))

# [6] God Mode: Max Fome, Sede e Stamina
func _cmd_max_needs() -> void:
	Global.player["hunger"] = 100.0
	Global.player["thirst"] = 100.0
	Global.player["stamina"] = 100.0
	TimeManager._exhaustion_alert_shown = false
	TimeManager._no_stamina_alert_shown = false
	Global._game_over = false
	_show_toast("God Mode: Fome 100%, Sede 100%, Stamina 100%!")

# [7] Destravar Tudo e Pular Tutorial
func _cmd_unlock_all() -> void:
	TutorialManager.skip_tutorial()
	Global.set_unlock_stage(Global.UNLOCK_ALL)
	Global.force_release_all_gameplay_locks()
	_show_toast("Mapa 100% liberado! Tutorial pulado.")

# [8] Escolaridade (+1 Nível & Salário & Cooldown)
func _cmd_level_up_school() -> void:
	var lvl := int(Global.player.get("school_level", 1))
	if lvl < 5:
		lvl += 1
		Global.player["school_level"] = lvl
		Global.player["salary"] = lvl * 350.0
	
	# Zera travas do minigame para poder jogar à vontade
	Global.player["minigame_progress"] = {
		"unlock_week": 1,
		"unlock_day": 0,
		"sessions_played": 1
	}
	_show_toast("Escolaridade Nível %d | Salário: R$ %.2f | Escola Liberada" % [lvl, float(Global.player.get("salary", 350.0))])

# [9] Gerar Evento Inesperado
func _cmd_spawn_event() -> void:
	var event = EventsManager.trigger_evento()
	if not event.is_empty():
		_show_toast("Evento disparado: '%s'!" % str(event.get("titulo", "Imprevisto")))
	else:
		_show_toast("Nenhum evento disponível no momento.")

# [0] Setup Rápido de Empreendimento (Restaurante)
func _cmd_setup_enterprise() -> void:
	var ent_id := "restaurant_small"
	if not EnterpriseManager.is_owned(ent_id):
		# Garante dinheiro para a compra
		if float(Global.player.get("money", 0.0)) < 2000.0:
			Global.player["money"] = float(Global.player.get("money", 0.0)) + 2000.0
		EnterpriseManager.buy_enterprise(ent_id)
	
	# Compra estoque se disponível
	var stock_items = EnterpriseManager.get_available_stock(ent_id)
	if not stock_items.is_empty():
		var first_item_id = stock_items[0].get("id", "ingredients")
		if float(Global.player.get("money", 0.0)) < 500.0:
			Global.player["money"] = float(Global.player.get("money", 0.0)) + 500.0
		EnterpriseManager.buy_stock(ent_id, first_item_id, 2)
	
	# Contrata 1 funcionário se houver vaga
	var ent_state = EnterpriseManager.get_player_enterprise(ent_id)
	if int(ent_state.get("employees", 0)) == 0:
		EnterpriseManager.hire_employee(ent_id)
		
	_show_toast("Restaurante configurado (comprado, com estoque e funcionário)!")

# Helper para garantir que todas as missões da semana atual sejam satisfeitas
func _fulfill_missions_data() -> void:
	var week := int(Global.player.get("week", 1))
	Global.player["money"] = max(float(Global.player.get("money", 0.0)), 2000.0)
	Global.player["saldo"] = max(float(Global.player.get("saldo", 0.0)), 200.0)
	Global.player["had_no_spend_day"] = true
	Global.player["no_spend_days_count"] = Global.DAYS_PER_WEEK
	Global.player["positive_days_count"] = Global.DAYS_PER_WEEK
	
	# Garante ao menos 1 registro de despesa para missões de análise/registro
	var expenses: Array = Global.player.get("expense_history", [])
	if expenses.is_empty():
		Global.register_expense("Mercado (Debug)", "food", 15.0, int(Global.player.get("day", 1)), week)
	
	# Se semana 2: resolver evento pendente
	var events: Array = Global.player.get("pending_events", [])
	var found_event := false
	for ev in events:
		if int(ev.get("week_generated", -1)) == week:
			ev["status"] = "paid"
			found_event = true
	if not found_event:
		Global.player["pending_events"].append({
			"id": "cheat_event_%d" % week,
			"title": "Imprevisto Resolvido",
			"description": "Resolvido via comando de debug",
			"week_generated": week,
			"amount": 50.0,
			"is_bonus": false,
			"status": "paid",
			"location": "bank",
			"source_id": "cheat"
		})
	
	# Se semana 3 ou 4: garantir investimentos em fundos
	if FIIManager.get_portfolio_value() <= 0.0 or FIIManager.portfolio.keys().size() < 2:
		FIIManager.portfolio["FII_SHOPPING"] = 5
		FIIManager.portfolio["FII_LOGISTICA"] = 5
		FIIManager.total_invested = 1000.0
		FIIManager.total_dividends_received = 250.0
		FIIManager.emit_signal("portfolio_updated")
	
	# Se semana 5: garantir restaurante comprado, estoque e sem contas pendentes
	if week >= 5:
		if not EnterpriseManager.is_owned("restaurant_small"):
			if float(Global.player.get("money", 0.0)) < 2000.0:
				Global.player["money"] = float(Global.player.get("money", 0.0)) + 2000.0
			EnterpriseManager.buy_enterprise("restaurant_small")
		var stock_items = EnterpriseManager.get_available_stock("restaurant_small")
		if not stock_items.is_empty():
			var item_id = stock_items[0].get("id", "ingredients")
			EnterpriseManager.buy_stock("restaurant_small", item_id, 1)
		var ent_state = Global.player["enterprises"].get("restaurant_small", {})
		ent_state["pending_bills"] = {}
