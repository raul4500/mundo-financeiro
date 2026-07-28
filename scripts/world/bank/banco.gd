extends Control

@onready var label_money = $"Account-info/Label_Money"
@onready var label_saldo = $"Account-info/Label-saldo"

@onready var input = $Input

@onready var btn_deposit = $Actions/Deposit
@onready var btn_withdraw = $Actions/Withdraw


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_labels()

	btn_deposit.pressed.connect(deposit)
	btn_withdraw.pressed.connect(withdraw)

	input.text_changed.connect(_only_numbers.bind(input))


func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])
	label_saldo.text = "Banco: $" + str(Global.player["saldo"])

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
