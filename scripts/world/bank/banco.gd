extends Control

@onready var label_money = $"Account-info/Label_Money"
@onready var label_saldo = $"Account-info/Label-saldo"
@onready var input = $Input
@onready var btn_deposit = $Actions/Deposit
@onready var btn_withdraw = $Actions/Withdraw

var history_panel: Panel
var history_list: VBoxContainer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.ensure_player_state()
	_build_history_panel()
	update_labels()
	btn_deposit.pressed.connect(deposit)
	btn_withdraw.pressed.connect(withdraw)
	input.text_changed.connect(_only_numbers.bind(input))

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
	for child in history_list.get_children():
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

func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])
	label_saldo.text = "Banco: $" + str(Global.player["saldo"])
	if history_panel != null:
		render_history()

func deposit():
	var value = int(input.text)
	if value <= 0:
		return
	if value > Global.player["money"]:
		print("Dinheiro insuficiente")
		return
	Global.player["money"] -= value
	Global.player["saldo"] += value
	input.text = ""
	update_labels()

func withdraw():
	var value = int(input.text)
	if value <= 0:
		return
	if value > Global.player["saldo"]:
		print("Saldo insuficiente")
		return
	Global.player["saldo"] -= value
	Global.player["money"] += value
	input.text = ""
	update_labels()

func _only_numbers(new_text, line_edit: LineEdit):
	var filtered = ""
	for char in new_text:
		if char.is_valid_int():
			filtered += char
	if filtered != new_text:
		line_edit.text = filtered

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
