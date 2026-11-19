extends Control

# "Sections" carrega font_theme.tres, cujo Label tem fundo (label_round.png) e
# corpo 24. Herdado pelas linhas criadas em runtime, isso viraria uma pilha de
# caixas gigantes. As linhas usam label.tres, igual aos labels de cabeçalho
# que a cena já define à mão.
const ROW_LABEL_THEME := preload("res://themes/label.tres")

@export var enterprise_id: String = "restaurant_small"

# =============================================================
# NODOS FIXOS DA CENA (scenes/world/ui/enterprise-view.tscn)
# O layout é definido no editor. Este script só preenche os
# containers dinâmicos (*-list) com o conteúdo do empreendimento.
# =============================================================
const HEADER := "Margin/VBoxContainer/Business-panel/VBoxContainer"
const TABS := "Margin/VBoxContainer/Sections"

@onready var title_label := _find(HEADER + "/Title-label") as Label
@onready var status_label := _find(HEADER + "/Status-label") as Label
@onready var message_label := _find(HEADER + "/Message-label") as Label

# Um label por indicador, dispostos em Stats-grid (3 colunas × 3 linhas).
@onready var money_label := _find(HEADER + "/Stats-grid/Money-label") as Label
@onready var revenue_label := _find(HEADER + "/Stats-grid/Revenue-label") as Label
@onready var expenses_label := _find(HEADER + "/Stats-grid/Expenses-label") as Label
@onready var profit_label := _find(HEADER + "/Stats-grid/Profit-label") as Label
@onready var capacity_label := _find(HEADER + "/Stats-grid/Capacity-label") as Label
@onready var ceiling_label := _find(HEADER + "/Stats-grid/Ceiling-label") as Label
@onready var bills_label := _find(HEADER + "/Stats-grid/Bills-label") as Label
@onready var payroll_label := _find(HEADER + "/Stats-grid/Payroll-label") as Label
@onready var total_profit_label := _find(HEADER + "/Stats-grid/Total-profit-label") as Label

# As quatro seções são abas de um TabContainer: só uma aparece por vez. O nome
# do nó de cada aba é o título que o jogador lê, então eles estão em português.
@onready var business_list := _find(TABS + "/Negócio/Business-list") as VBoxContainer
@onready var stock_list := _find(TABS + "/Estoque/Stock-list") as VBoxContainer
@onready var bills_list := _find(TABS + "/Contas/Bills-list") as VBoxContainer
@onready var equipment_list := _find(TABS + "/Equipamentos/Equipment-list") as VBoxContainer
@onready var exit_button := _find("Margin/VBoxContainer/Exit-button") as Button
var time_display: Label

# O layout desta tela já foi reorganizado várias vezes e cada troca de pai
# quebrava os caminhos fixos, derrubando a cena com "Node not found". Aqui o
# caminho esperado é só a via rápida: se o nó mudou de lugar, ele é encontrado
# pelo nome na árvore inteira e o aviso diz o que atualizar.
func _find(path: String) -> Node:
	var node := get_node_or_null(path)
	if node != null:
		return node
	var wanted := path.get_file()
	var found := find_child(wanted, true, false)
	if found == null:
		push_error("enterprise_management: nó '%s' não existe na cena (esperado em %s)." % [wanted, path])
	else:
		push_warning("enterprise_management: '%s' saiu de '%s'. Atualize o caminho no script." % [wanted, path])
	return found

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	_create_time_display()
	if not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)
	_connect_manager()
	_refresh_ui()

func _create_time_display() -> void:
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	add_child(time_display)

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

	var status = str(data.get("status", "ok"))
	status_label.text = _status_text(status)
	status_label.add_theme_color_override("font_color", _status_color(status))

	var overdue = int(data.get("overdue_count", 0))
	money_label.text = "Dinheiro: R$ %.2f" % float(data.get("money", 0.0))
	revenue_label.text = "Receita diária: R$ %.2f" % float(data.get("daily_revenue", 0.0))
	expenses_label.text = "Despesas diárias: R$ %.2f" % float(data.get("daily_expenses", 0.0))
	profit_label.text = "Lucro estimado: R$ %.2f" % float(data.get("daily_profit", 0.0))
	capacity_label.text = "Capacidade: %d clientes" % int(data.get("capacity", 0))
	ceiling_label.text = "Teto de receita: R$ %.2f" % float(data.get("revenue_ceiling", 0.0))
	bills_label.text = "Contas pendentes: %d (%d em atraso)" % [
		EnterpriseManager.get_pending_bills(enterprise_id).size(),
		overdue
	]
	payroll_label.text = "Folha semanal: R$ %.2f" % float(data.get("weekly_payroll", 0.0))
	total_profit_label.text = "Lucro acumulado: R$ %.2f" % float(state.get("total_profit", 0.0))

	# Contas em atraso cortam 25% da receita, então o número ganha destaque.
	bills_label.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1) if overdue > 0 else Color(0, 0, 0))

	_render_business(data, info, state)
	_render_stock(data.get("stock", []), state)
	_render_bills(EnterpriseManager.get_pending_bills(enterprise_id))
	_render_equipment(data.get("equipment", []), state)

# Agora que a situação tem label próprio, a cor carrega a urgência sem
# depender de o jogador ler a frase inteira.
func _status_color(status: String) -> Color:
	match status:
		"closed":
			return Color(0.6, 0.1, 0.1)
		"warning":
			return Color(0.65, 0.4, 0.0)
		_:
			return Color(0, 0, 0)

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
	var upgrade_label = _make_row_label()
	if upgrade_cost > 0.0:
		upgrade_label.text = "Aprimorar para o nível %d: desbloqueia equipamentos e aumenta a receita" % (int(state.get("level", 1)) + 1)
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
	var staff_label = _make_row_label()
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
	label.theme = ROW_LABEL_THEME
	# label.tres usa corpo 23, grande demais para linhas densas de lista.
	label.add_theme_font_size_override("font_size", 16)
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
		label.text = "%s%s" % [item.get("name", item.get("id", "item")), " (comprado)" if owned else ": R$ %.2f" % float(item.get("price", 0.0))]
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
	# A mensagem vai depois do _refresh_ui(): antes, ela era escrita no
	# status_label e o próprio refresh a sobrescrevia no mesmo frame.
	_refresh_ui()
	message_label.text = str(result.get("message", "Operação concluída."))
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível concluir a operação.")))

func _on_enterprise_updated(updated_id: String) -> void:
	if updated_id == enterprise_id:
		_refresh_ui()

func _on_enterprise_error(message: String) -> void:
	message_label.text = str(message)

func _on_exit_pressed() -> void:
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
