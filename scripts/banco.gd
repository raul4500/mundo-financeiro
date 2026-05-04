extends Control

@onready var label_money = $Label_Money
@onready var label_saldo = $Label_Saldo

@onready var input_deposit = $LineEdit_Deposit
@onready var input_withdraw = $LineEdit_Withdraw

@onready var btn_deposit = $Button_Deposit
@onready var btn_withdraw = $Button_Withdraw


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_labels()

	btn_deposit.pressed.connect(deposit)
	btn_withdraw.pressed.connect(withdraw)

	input_deposit.text_changed.connect(_only_numbers.bind(input_deposit))
	input_withdraw.text_changed.connect(_only_numbers.bind(input_withdraw))


# ------------------------
# 💰 Atualização da UI
# ------------------------
func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])
	label_saldo.text = "Banco: $" + str(Global.player["saldo"])


# ------------------------
# 💸 Depositar
# ------------------------
func deposit():
	var value = int(input_deposit.text)

	if value <= 0:
		return

	if value > Global.player["money"]:
		print("Dinheiro insuficiente")
		return

	Global.player["money"] -= value
	Global.player["saldo"] += value

	input_deposit.text = ""
	update_labels()


# ------------------------
# 🏦 Sacar
# ------------------------
func withdraw():
	var value = int(input_withdraw.text)

	if value <= 0:
		return

	if value > Global.player["saldo"]:
		print("Saldo insuficiente")
		return

	Global.player["saldo"] -= value
	Global.player["money"] += value

	input_withdraw.text = ""
	update_labels()


# ------------------------
# 🔢 Permitir apenas números
# ------------------------
func _only_numbers(new_text, line_edit: LineEdit):
	var filtered = ""

	for char in new_text:
		if char.is_valid_int():
			filtered += char

	if filtered != new_text:
		line_edit.text = filtered


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
