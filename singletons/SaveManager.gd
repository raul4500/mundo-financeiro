extends Node

func save_game(data = Global.player):
	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func load_game():
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	return data
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("save loaded")
	#var pos = load_game()["player_position"]
	#player.global_position = Vector2(pos["x"], pos["y"])

func delete_save(caminho: String = "savegame.json") -> void:
	var dir = DirAccess.open("user://") # Substitua "res://" por "user://" se o arquivo estiver na pasta de usuário
	print(dir.get_files())
	if dir.file_exists(caminho):
		var erro = dir.remove(caminho)
		if erro == OK:
			print("Arquivo deletado com sucesso!")
		else:
			print("Erro ao tentar deletar o arquivo.")
	else:
		print("O arquivo não existe.")



var save_timer := 0.0
var save_interval := 300.0 # segundos (5 minutos)

func _process(delta):
	save_timer += delta
	if save_timer >= save_interval:
		print("game saved!")
		save_game()
		save_timer = 0
