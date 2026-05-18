extends Control


func _ready():
	$HBoxContainer/raul.pressed.connect(func(): select_character("Raul", 1.1))
	$HBoxContainer/matheus.pressed.connect(func(): select_character("Matheus", 1.3))
	$HBoxContainer/phillip.pressed.connect(func(): select_character("Phillip", 1))
	$HBoxContainer/melissa.pressed.connect(func(): select_character("Melissa", 1.1))
	$HBoxContainer/enzo.pressed.connect(func(): select_character("Enzo", 0.9))

func select_character(name: String, k: float) -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("savegame.json")
	Global.new_game(name, k*200)
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
