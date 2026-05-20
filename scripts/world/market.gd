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

func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
