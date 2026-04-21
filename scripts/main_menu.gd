extends Control

func _ready() -> void:
	print(Data.data)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_novo_jogo_pressed() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("savegame.json")
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
