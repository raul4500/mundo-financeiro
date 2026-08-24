extends Control

const EVENT_LABEL_THEME = preload("res://themes/label.tres")

@onready var label_money = $"Account-info/Label_Money"
@onready var label_saldo = $"Account-info/Label-saldo"
@onready var transaction_panel: Panel = $"Transaction-panel"
@onready var input: LineEdit = $"Transaction-panel/Input"
@onready var confirm_button: Button = $"Transaction-panel/Confirm"
@onready var cancel_button: Button = $"Transaction-panel/Cancel"
@onready var btn_deposit = $Actions/Deposit
@onready var btn_withdraw = $Actions/Withdraw
# Painel de contas/bônus pendentes: layout fixo na cena, conteúdo no script.
@onready var events_list: VBoxContainer = $"Investimentos/Eventos/Margin/VBoxContainer/Events-scroll/Events-list"

var history_panel: Panel
var history_list: VBoxContainer
var time_display: Label
var transaction_type: String = ""

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	Global.ensure_player_state()
	_create_time_display()
	_build_history_panel()
	# Redesenha quando uma pendência nasce ou é resolvida em qualquer lugar.
	if not EventsManager.events_updated.is_connected(render_events):
		EventsManager.events_updated.connect(render_events)
	update_labels()
	btn_deposit.pressed.connect(deposit)
	btn_withdraw.pressed.connect(withdraw)
	confirm_button.pressed.connect(_confirm_transaction)
	cancel_button.pressed.connect(_cancel_transaction)
	input.text_changed.connect(_only_numbers.bind(input))

func _create_time_display() -> void:
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	add_child(time_display)

func _build_history_panel() -> void:
	if history_panel != null:
		return
	history_panel = Panel.new()
	history_panel.position = Vector2(710, 25)
	history_panel.size = Vector2(390, 590)

	var title = Label.new()
	title.text = "Histórico de despesas"
	title.position = Vector2(10, 10)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 40)
	scroll.size = Vector2(370, 520)

	history_list = VBoxContainer.new()
	history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_list.add_theme_constant_override("separation", 6)
	scroll.add_child(history_list)
	history_panel.add_child(title)
	history_panel.add_child(scroll)
	add_child(history_panel)
	render_history()

func render_history() -> void:
	if history_list == null:
		return
	# remove_child antes do queue_free, mesmo motivo de render_events().
	for child in history_list.get_children():
		history_list.remove_child(child)
		child.queue_free()
	var entries = Global.player.get("expense_history", [])
	if entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nenhuma compra registrada."
		history_list.add_child(empty_label)
		return
	for index in range(entries.size() - 1, -1, -1):
		var entry = entries[index]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s - R$%.2f - Dia %s" % [str(entry.get("item", "-")), float(entry.get("price", 0.0)), str(entry.get("day", 1))]
		row.add_child(label)
		history_list.add_child(row)

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
		events_list.add_child(_make_event_label("Nenhuma conta ou bônus pendente."))
		return

	for ev in entries:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var is_bonus = bool(ev.get("is_bonus", false))
		var label = _make_event_label("%s | %s de R$ %.2f | semana %d" % [
			str(ev.get("title", "-")),
			"Bônus" if is_bonus else "Conta",
			abs(float(ev.get("amount", 0.0))),
			# int() é obrigatório: depois de um load, o JSON devolve números
			# como float e o texto sairia "semana 3.0".
			int(ev.get("week_generated", 0))
		])
		label.tooltip_text = str(ev.get("description", ""))
		row.add_child(label)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 36)
		if is_bonus:
			btn.text = "Resgatar"
			btn.pressed.connect(_on_collect_pressed.bind(str(ev.get("id", ""))))
		else:
			btn.text = "Pagar"
			btn.pressed.connect(_on_pay_pressed.bind(str(ev.get("id", ""))))
		row.add_child(btn)
		events_list.add_child(row)

# label.tres em vez do tema do painel: o Label do font_theme.tres tem fundo
# (label_round.png) e corpo 24, que numa lista densa viram caixas gigantes.
func _make_event_label(text: String) -> Label:
	var label = Label.new()
	label.theme = EVENT_LABEL_THEME
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.text = text
	return label

func _on_pay_pressed(event_id: String) -> void:
	_handle_event_result(EventsManager.pay_event(event_id))

func _on_collect_pressed(event_id: String) -> void:
	_handle_event_result(EventsManager.collect_event(event_id))

# Sem isto, falhar por saldo insuficiente ficava só num print no console e o
# jogador clicava em "Pagar" sem entender por que nada acontecia.
func _handle_event_result(result: Dictionary) -> void:
	update_labels()
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível concluir a operação.")))

func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])
	label_saldo.text = "Banco: $" + str(Global.player["saldo"])
	if history_panel != null:
		render_history()
	render_events()

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
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
