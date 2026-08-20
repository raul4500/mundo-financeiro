extends Control

@export var enterprise_id: String = "restaurant_small"

# =============================================================
# NODOS FIXOS DA CENA (scenes/world/ui/enterprise-view.tscn)
# O layout é definido no editor. Este script só preenche os
# containers dinâmicos (*-list) com o conteúdo do empreendimento.
# =============================================================
@onready var title_label: Label = $"Margin/VBoxContainer/Title-label"
@onready var summary_label: Label = $"Margin/VBoxContainer/Summary-label"
@onready var status_label: Label = $"Margin/VBoxContainer/Status-label"
@onready var business_list: VBoxContainer = $"Margin/VBoxContainer/Sections/Business-panel/VBoxContainer/Business-scroll/Business-list"
@onready var stock_list: VBoxContainer = $"Margin/VBoxContainer/Sections/Stock-panel/VBoxContainer/Stock-scroll/Stock-list"
@onready var bills_list: VBoxContainer = $"Margin/VBoxContainer/Sections/Bills-panel/VBoxContainer/Bills-scroll/Bills-list"
@onready var equipment_list: VBoxContainer = $"Margin/VBoxContainer/Sections/Equipment-panel/VBoxContainer/Equipment-scroll/Equipment-list"
@onready var exit_button: Button = $"Margin/VBoxContainer/Exit-button"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)
	_connect_manager()
	_refresh_ui()

func _connect_manager() -> void:
	if not EnterpriseManager.enterprise_updated.is_connected(_on_enterprise_updated):
		EnterpriseManager.enterprise_updated.connect(_on_enterprise_updated)
	if not EnterpriseManager.enterprise_error.is_connected(_on_enterprise_error):
		EnterpriseManager.enterprise_error.connect(_on_enterprise_error)

func _refresh_ui() -> void:
	var data = EnterpriseManager.get_dashboard_data(enterprise_id)
	var info = data.get("info", {})
	var state = data.get("state", {})
	if info.is_empty():
		status_label.text = "Empreendimento inválido: %s" % enterprise_id
		return

	title_label.text = "%s | Nível %d de %d" % [info.get("name", enterprise_id), int(state.get("level", 0)), int(info.get("max_level", 5))]
	summary_label.text = "Dinheiro: R$ %.2f | Receita diária: R$ %.2f | Despesas: R$ %.2f | Lucro estimado: R$ %.2f | Capacidade: %d (teto de receita R$ %.2f)" % [float(data.get("money", 0.0)), float(data.get("daily_revenue", 0.0)), float(data.get("daily_expenses", 0.0)), float(data.get("daily_profit", 0.0)), int(data.get("capacity", 0)), float(data.get("revenue_ceiling", 0.0))]
	status_label.text = "%s | Contas pendentes: %d (%d em atraso) | Folha semanal: R$ %.2f | Lucro acumulado: R$ %.2f" % [
		_status_text(str(data.get("status", "ok"))),
		EnterpriseManager.get_pending_bills(enterprise_id).size(),
		int(data.get("overdue_count", 0)),
		float(data.get("weekly_payroll", 0.0)),
		float(state.get("total_profit", 0.0))
	]
	_render_business(data, info, state)
	_render_stock(data.get("stock", []), state)
	_render_bills(EnterpriseManager.get_pending_bills(enterprise_id))
	_render_equipment(data.get("equipment", []), state)

func _status_text(status: String) -> String:
	match status:
		"closed":
			return "SITUAÇÃO CRÍTICA: sem estoque e com contas em atraso"
		"warning":
			return "ATENÇÃO: falta estoque ou há contas em atraso"
		"not_owned":
			return "Empreendimento não comprado"
		_:
			return "Operando normalmente"

func _render_business(data: Dictionary, info: Dictionary, state: Dictionary) -> void:
	_clear_list(business_list)

	# Aprimoramento de nível
	var upgrade_cost = float(data.get("upgrade_cost", 0.0))
	var upgrade_row = HBoxContainer.new()
	var upgrade_label = Label.new()
	upgrade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if upgrade_cost > 0.0:
		upgrade_label.text = "Aprimorar para o nível %d — desbloqueia equipamentos e aumenta a receita" % (int(state.get("level", 1)) + 1)
		var upgrade_button = Button.new()
		upgrade_button.text = "Aprimorar (R$ %.2f)" % upgrade_cost
		upgrade_button.pressed.connect(_on_upgrade_pressed)
		upgrade_row.add_child(upgrade_label)
		upgrade_row.add_child(upgrade_button)
	else:
		upgrade_label.text = "Nível máximo alcançado."
		upgrade_row.add_child(upgrade_label)
	business_list.add_child(upgrade_row)

	# Funcionários
	var staff_row = HBoxContainer.new()
	var staff_label = Label.new()
	staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	staff_label.text = "Funcionários: %d de %d | Salário: R$ %.2f por semana cada | +R$ %.2f de receita por dia cada" % [
		int(state.get("employees", 0)),
		int(info.get("max_employees", 0)),
		float(info.get("employee_salary", 0.0)),
		float(info.get("employee_revenue_bonus", 0.0))
	]
	staff_row.add_child(staff_label)

	var hire_button = Button.new()
	hire_button.text = "Contratar"
	hire_button.disabled = int(state.get("employees", 0)) >= int(info.get("max_employees", 0))
	hire_button.pressed.connect(_on_hire_pressed)
	staff_row.add_child(hire_button)

	var fire_button = Button.new()
	fire_button.text = "Demitir"
	fire_button.disabled = int(state.get("employees", 0)) <= 0
	fire_button.pressed.connect(_on_fire_pressed)
	staff_row.add_child(fire_button)

	business_list.add_child(staff_row)

# autowrap é obrigatório: sem ele o Label reporta a largura do texto inteiro
# como largura mínima e o painel se recusa a encolher, estourando a tela.
func _make_row_label() -> Label:
	var label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _clear_list(list: VBoxContainer) -> void:
	# remove_child antes do queue_free: sem isso, dois _refresh_ui() no mesmo
	# frame duplicariam as linhas, já que queue_free só libera no fim do frame.
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

func _render_stock(items: Array, state: Dictionary) -> void:
	_clear_list(stock_list)
	var stock = state.get("stock", {})
	for item in items:
		var row = HBoxContainer.new()
		var label = _make_row_label()
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
		var empty = _make_row_label()
		empty.text = "Nenhuma conta pendente."
		bills_list.add_child(empty)
		return
	for bill in bills:
		var row = HBoxContainer.new()
		var label = _make_row_label()
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
		var label = _make_row_label()
		var owned = equipment.has(item.get("id", ""))
		label.text = "%s%s" % [item.get("name", item.get("id", "item")), " (comprado)" if owned else " - R$ %.2f" % float(item.get("price", 0.0))]
		row.add_child(label)
		if not owned:
			var button = Button.new()
			button.text = "Comprar"
			button.pressed.connect(_on_buy_equipment.bind(str(item.get("id", ""))))
			row.add_child(button)
		equipment_list.add_child(row)

func _on_upgrade_pressed() -> void:
	_show_result(EnterpriseManager.upgrade_level(enterprise_id))

func _on_hire_pressed() -> void:
	_show_result(EnterpriseManager.hire_employee(enterprise_id))

func _on_fire_pressed() -> void:
	_show_result(EnterpriseManager.fire_employee(enterprise_id))

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
