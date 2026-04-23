extends Control


func _ready():
	$HBoxContainer/raul.pressed.connect(func(): select_character(1))
	$HBoxContainer/matheus.pressed.connect(func(): select_character(2))
	$HBoxContainer/phillip.pressed.connect(func(): select_character(3))
	$HBoxContainer/melissa.pressed.connect(func(): select_character(4))
	$HBoxContainer/enzo.pressed.connect(func(): select_character(5))

func select_character(id: int) -> void:
	Global.selected_character = id
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
