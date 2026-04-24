extends Control

func start() -> void:
	if Global.player["name"] == "":
		get_tree().change_scene_to_file("res://scenes/choose_character.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_start_pressed() -> void:
	start()
	
func _on_novo_jogo_pressed() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("savegame.json")
	Global.load_data()
	start()


func _on_sair_do_jogo_pressed() -> void:
	get_tree().quit()
