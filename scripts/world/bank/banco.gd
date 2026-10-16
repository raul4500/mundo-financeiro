extends Control

const BankCard = preload("res://scripts/world/bank/bank_card.gd")

# Alturas mínimas dos cards (o PanelContainer cresce se o texto pedir mais).
const HISTORY_CARD_HEIGHT := 100
const DEBT_CARD_HEIGHT := 170

@onready var label_money = $"Account-info/Label_Money"
@onready var label_saldo = $"Account-info/Label-saldo"
@onready var transaction_panel: Panel = $"Transaction-panel"
@onready var input: LineEdit = $"Transaction-panel/Panel/Input"
@onready var confirm_button: Button = $"Transaction-panel/Panel/Confirm"
@onready var cancel_button: Button = $"Transaction-panel/Panel/Cancel"
@onready var btn_deposit = $Actions/Deposit
@onready var btn_withdraw = $Actions/Withdraw
@onready var events_list: GridContainer = $"TabContainer/Eventos/Margin/VBoxContainer/Events-scroll/Events-list"
@onready var house_bills_list: GridContainer = $"TabContainer/Contas da casa/Margin/VBoxContainer/House-bills-scroll/House-bills-list"
@onready var history_panel: Panel = $"TabContainer/Histórico"
@onready var history_list: GridContainer = $"TabContainer/Histórico/Margin/VBoxContainer/House-bills-scroll/History-list"
@onready var tab_container: TabContainer = $"TabContainer"



var time_display: Label
var transaction_type: String = ""

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	Global.ensure_player_state()
	_create_time_display()
	render_history()
	# Redesenha quando uma pendência nasce ou é resolvida em qualquer lugar.
	if not EventsManager.events_updated.is_connected(render_events):
		EventsManager.events_updated.connect(render_events)
	if not HouseBillsManager.bills_updated.is_connected(render_house_bills):
		HouseBillsManager.bills_updated.connect(render_house_bills)
	update_labels()
	btn_deposit.pressed.connect(deposit)
	btn_withdraw.pressed.connect(withdraw)
	confirm_button.pressed.connect(_confirm_transaction)
	cancel_button.pressed.connect(_cancel_transaction)
	input.text_changed.connect(_only_numbers.bind(input))

func _process(delta: float) -> void:
	var is_disabled = Global.player["week"] < 4
	tab_container.set_tab_disabled(3, is_disabled)
	tab_container.set_tab_disabled(4, is_disabled)

func _create_time_display() -> void:
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	add_child(time_display)

func render_history() -> void:
	if history_list == null:
		return
	# remove_child antes do queue_free, mesmo motivo de render_events().
	for child in history_list.get_children():
		history_list.remove_child(child)
		child.queue_free()
	var entries = Global.player.get("expense_history", [])
	if entries.is_empty():
		history_list.add_child(BankCard.new_empty_card("Nenhuma compra registrada."))
		return
	# Mais recente primeiro.
	for index in range(entries.size() - 1, -1, -1):
		var entry = entries[index]
		var parts := BankCard.new_card(HISTORY_CARD_HEIGHT)
		var box: VBoxContainer = parts["box"]
		box.add_child(BankCard.make_label(str(entry.get("item", "-")), 18))
		box.add_child(BankCard.make_label("R$ %.2f" % float(entry.get("price", 0.0)), 16))
		# int(): depois de um load o JSON devolve números como float ("dia 3.0").
		box.add_child(BankCard.make_label("Semana %d - Dia %d" % [int(entry.get("week", 1)), int(entry.get("day", 1))], 13))
		history_list.add_child(parts["card"])

# O painel é fixo na cena (bank.tscn). Aqui só preenchemos a lista.
func render_events() -> void:
	if events_list == null:
		return
	# remove_child antes do queue_free: sem isso, dois renders no mesmo frame
	# duplicam as linhas, porque queue_free só libera no fim do frame.
	for child in events_list.get_children():
		events_list.remove_child(child)
		child.queue_free()

	var entries = EventsManager.get_pending_events("bank")
	if entries.is_empty():
		events_list.add_child(BankCard.new_empty_card("Nenhuma conta ou bônus pendente."))
		return

	for ev in entries:
		var is_bonus = bool(ev.get("is_bonus", false))
		var parts := BankCard.new_card(DEBT_CARD_HEIGHT)
		var box: VBoxContainer = parts["box"]
		var card: PanelContainer = parts["card"]
		card.tooltip_text = str(ev.get("description", ""))

		box.add_child(BankCard.make_label(str(ev.get("title", "-")), 18))
		var button: Button
		if is_bonus:
			box.add_child(BankCard.make_label("Bônus: R$ %.2f" % abs(float(ev.get("amount", 0.0))), 16))
			# int() é obrigatório: depois de um load, o JSON devolve números
			# como float e o texto sairia "semana 3.0".
			box.add_child(BankCard.make_label("Gerado na semana %d" % int(ev.get("week_generated", 0)), 13))
			button = BankCard.make_button("Resgatar")
			button.pressed.connect(_on_collect_pressed.bind(str(ev.get("id", ""))))
		else:
			var overdue: int = EventsManager.overdue_days_of(ev)
			box.add_child(BankCard.make_label("Conta: %s" % _debt_amount_text(EventsManager.current_amount(ev), abs(float(ev.get("amount", 0.0))), overdue), 16))
			box.add_child(BankCard.make_label(_debt_deadline_text(EventsManager.event_due_week(ev), EventsManager.event_limit_week(ev), overdue), 13))
			button = BankCard.make_button("Pagar")
			button.pressed.connect(_on_pay_pressed.bind(str(ev.get("id", ""))))
		box.add_child(button)
		events_list.add_child(card)

# "R$ 45.00" em dia; "R$ 59.99 (R$ 45.00 + 3 dias de juros)" depois de vencer.
func _debt_amount_text(current: float, original: float, overdue_days: int) -> String:
	if overdue_days <= 0:
		return "R$ %.2f" % current
	return "R$ %.2f (R$ %.2f + %d dia(s) de juros)" % [current, original, overdue_days]

func _debt_deadline_text(due_week: int, limit_week: int, overdue_days: int) -> String:
	if overdue_days > 0:
		return "VENCIDA. Cobrança automática no fim da semana %d." % limit_week
	return "Vence no fim da semana %d. Cobrança automática no fim da semana %d." % [due_week, limit_week]

func _on_pay_pressed(event_id: String) -> void:
	_handle_event_result(EventsManager.pay_event(event_id))

func _on_collect_pressed(event_id: String) -> void:
	_handle_event_result(EventsManager.collect_event(event_id))

# O painel também é fixo na cena. As contas da casa têm um armazenamento
# próprio para não se misturarem a eventos inesperados ou empreendimentos.
func render_house_bills() -> void:
	if house_bills_list == null:
		return
	for child in house_bills_list.get_children():
		house_bills_list.remove_child(child)
		child.queue_free()

	var bills := HouseBillsManager.get_pending_bills()
	if bills.is_empty():
		house_bills_list.add_child(BankCard.new_empty_card("Nenhuma conta da casa pendente."))
		return

	for bill in bills:
		var overdue := HouseBillsManager.overdue_days_of(bill)
		var parts := BankCard.new_card(DEBT_CARD_HEIGHT)
		var box: VBoxContainer = parts["box"]
		var card: PanelContainer = parts["card"]
		card.tooltip_text = str(bill.get("description", ""))

		box.add_child(BankCard.make_label(str(bill.get("title", "Conta da casa")), 18))
		box.add_child(BankCard.make_label(_debt_amount_text(HouseBillsManager.current_amount(bill), float(bill.get("amount", 0.0)), overdue), 16))
		box.add_child(BankCard.make_label(_debt_deadline_text(HouseBillsManager.bill_due_week(bill), HouseBillsManager.bill_limit_week(bill), overdue), 13))
		var button := BankCard.make_button("Pagar")
		button.pressed.connect(_on_house_bill_pay_pressed.bind(str(bill.get("id", ""))))
		box.add_child(button)
		house_bills_list.add_child(card)

func _on_house_bill_pay_pressed(bill_id: String) -> void:
	var result := HouseBillsManager.pay_bill(bill_id)
	update_labels()
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível pagar a conta da casa.")))

# Sem isto, falhar por saldo insuficiente ficava só num print no console e o
# jogador clicava em "Pagar" sem entender por que nada acontecia.
func _handle_event_result(result: Dictionary) -> void:
	update_labels()
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível concluir a operação.")))

func update_labels():
	label_money.text = "Dinheiro: $" + "%.2f" % Global.player["money"]
	label_saldo.text = "Banco: $" + "%.2f" % Global.player["saldo"]
	if history_panel != null:
		render_history()
	render_events()
	render_house_bills()

func deposit():
	_open_transaction("deposit")

func withdraw():
	_open_transaction("withdraw")

func _open_transaction(type: String) -> void:
	transaction_type = type
	input.clear()
	input.placeholder_text = "Valor para depositar" if type == "deposit" else "Valor para sacar"
	transaction_panel.visible = true
	input.grab_focus()

func _confirm_transaction() -> void:
	var value = int(input.text)
	if value <= 0:
		transaction_panel.visible = false
		return
	if transaction_type == "deposit":
		if value > Global.player["money"]:
			transaction_panel.visible = false
			AlertManager.alert("Dinheiro insuficiente para realizar este depósito.")
			return
		Global.player["money"] -= value
		Global.player["saldo"] += value
	else:
		if value > Global.player["saldo"]:
			transaction_panel.visible = false
			AlertManager.alert("Saldo insuficiente para realizar este saque.")
			return
		Global.player["saldo"] -= value
		Global.player["money"] += value
	_cancel_transaction()
	update_labels()

func _cancel_transaction() -> void:
	transaction_type = ""
	input.clear()
	transaction_panel.visible = false

func _only_numbers(new_text, line_edit: LineEdit):
	var filtered = ""
	for char in new_text:
		if char.is_valid_int():
			filtered += char
	if filtered != new_text:
		line_edit.text = filtered

func _on_exit_pressed() -> void:
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
