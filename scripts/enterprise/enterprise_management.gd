extends Control

@export var enterprise_id: String = "restaurant_small"

var title_label: Label
var summary_label: Label
var status_label: Label
var stock_list: VBoxContainer
var bills_list: VBoxContainer
var equipment_list: VBoxContainer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_connect_manager()
	_refresh_ui()

func _connect_manager() -> void:
	if not EnterpriseManager.enterprise_updated.is_connected(_on_enterprise_updated):
		EnterpriseManager.enterprise_updated.connect(_on_enterprise_updated)
	if not EnterpriseManager.enterprise_error.is_connected(_on_enterprise_error):
		EnterpriseManager.enterprise_error.connect(_on_enterprise_error)

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	root.add_child(title_label)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(summary_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(status_label)

	var sections = HBoxContainer.new()
	sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 18)
	root.add_child(sections)

	var stock_panel = _create_section("Estoque")
	stock_list = stock_panel.get_meta("list")
	sections.add_child(stock_panel)

	var bills_panel = _create_section("Contas")
	bills_list = bills_panel.get_meta("list")
	sections.add_child(bills_panel)

	var equipment_panel = _create_section("Equipamentos")
	equipment_list = equipment_panel.get_meta("list")
	sections.add_child(equipment_panel)

	var exit_button = Button.new()
	exit_button.text = "Voltar"
	exit_button.custom_minimum_size = Vector2(160, 42)
	exit_button.pressed.connect(_on_exit_pressed)
	root.add_child(exit_button)

func _create_section(section_title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title = Label.new()
	title.text = section_title
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var list = VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	panel.set_meta("list", list)
	return panel

func _refresh_ui() -> void:
	var data = EnterpriseManager.get_dashboard_data(enterprise_id)
	var info = data.get("info", {})
	var state = data.get("state", {})
	if info.is_empty():
		status_label.text = "Empreendimento inválido: %s" % enterprise_id
		return

	title_label.text = "%s | Nível %d" % [info.get("name", enterprise_id), int(state.get("level", 0))]
	summary_label.text = "Dinheiro: R$ %.2f | Receita diária: R$ %.2f | Despesas: R$ %.2f | Lucro estimado: R$ %.2f | Capacidade: %d" % [float(data.get("money", 0.0)), float(data.get("daily_revenue", 0.0)), float(data.get("daily_expenses", 0.0)), float(data.get("daily_profit", 0.0)), int(data.get("capacity", 0))]
	status_label.text = "Contas pendentes: %d | Lucro acumulado: R$ %.2f" % [EnterpriseManager.get_pending_bills(enterprise_id).size(), float(state.get("total_profit", 0.0))]
	_render_stock(data.get("stock", []), state)
	_render_bills(EnterpriseManager.get_pending_bills(enterprise_id))
	_render_equipment(data.get("equipment", []), state)

func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

func _render_stock(items: Array, state: Dictionary) -> void:
	_clear_list(stock_list)
	var stock = state.get("stock", {})
	for item in items:
		var row = HBoxContainer.new()
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s | R$ %.2f por lote | Estoque: %d" % [item.get("name", item.get("id", "item")), float(item.get("price", 0.0)), int(stock.get(item.get("id", ""), 0))]
		row.add_child(label)
		var button = Button.new()
		button.text = "+ Comprar (R$ %.2f)" % float(item.get("price", 0.0))
		button.pressed.connect(_on_buy_stock.bind(str(item.get("id", ""))))
		row.add_child(button)
		stock_list.add_child(row)

func _render_bills(bills: Array) -> void:
	_clear_list(bills_list)
	if bills.is_empty():
		var empty = Label.new()
		empty.text = "Nenhuma conta pendente."
		bills_list.add_child(empty)
		return
	for bill in bills:
		var row = HBoxContainer.new()
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s: R$ %.2f" % [bill.get("name", "Conta"), float(bill.get("amount", 0.0))]
		row.add_child(label)
		var button = Button.new()
		button.text = "Pagar"
		button.pressed.connect(_on_pay_bill.bind(str(bill.get("id", ""))))
		row.add_child(button)
		bills_list.add_child(row)

func _render_equipment(items: Array, state: Dictionary) -> void:
	_clear_list(equipment_list)
	var equipment = state.get("equipment", {})
	for item in items:
		var row = HBoxContainer.new()
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var owned = equipment.has(item.get("id", ""))
		label.text = "%s%s" % [item.get("name", item.get("id", "item")), " (comprado)" if owned else " - R$ %.2f" % float(item.get("price", 0.0))]
		row.add_child(label)
		if not owned:
			var button = Button.new()
			button.text = "Comprar"
			button.pressed.connect(_on_buy_equipment.bind(str(item.get("id", ""))))
			row.add_child(button)
		equipment_list.add_child(row)

func _on_buy_stock(item_id: String) -> void:
	var result = EnterpriseManager.buy_stock(enterprise_id, item_id, 1)
	_show_result(result)

func _on_pay_bill(bill_id: String) -> void:
	var result = EnterpriseManager.pay_bill(enterprise_id, bill_id)
	_show_result(result)

func _on_buy_equipment(item_id: String) -> void:
	var result = EnterpriseManager.buy_equipment(enterprise_id, item_id)
	_show_result(result)

func _show_result(result: Dictionary) -> void:
	status_label.text = str(result.get("message", "Operação concluída."))
	_refresh_ui()
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível concluir a operação.")))

func _on_enterprise_updated(updated_id: String) -> void:
	if updated_id == enterprise_id:
		_refresh_ui()

func _on_enterprise_error(message: String) -> void:
	status_label.text = str(message)

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
