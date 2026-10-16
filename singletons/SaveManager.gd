extends Node

func _logger() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("/root/Logger")

func _log_info(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_info(message)
	else:
		print("[INFO] %s" % message)

func _log_warning(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_warning(message)
	else:
		print("[WARN] %s" % message)

func _log_error(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_error(message)
	else:
		print("[ERROR] %s" % message)

func save_game():
	if Global.player == null or Global.player.get("name", "") == "" or Global.is_game_over():
		return

	FIIManager.save_data()
	var data = Global.player.duplicate(true)
	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file == null:
		_log_error("Erro ao salvar o jogo: %s" % FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()

func load_game():
	var save_path = "user://savegame.json"
	if not FileAccess.file_exists(save_path):
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_log_error("Erro ao carregar o jogo: %s" % FileAccess.get_open_error())
		return false
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if data is Dictionary:
		# Fome/sede em zero NÃO é mais morte (o jogador desmaia, ver
		# TimeManager.collapse_if_needs_depleted): um save assim é válido e
		# desmaia no primeiro minuto, em vez de ser apagado.
		_log_info("save loaded")
		return data
	_log_warning("save inválido")
	return false

func has_save(caminho: String = "savegame.json") -> bool:
	var save_path = "user://%s" % caminho
	return FileAccess.file_exists(save_path)

func _ready() -> void:
	pass

func delete_save(caminho: String = "savegame.json") -> void:
	var save_path = "user://%s" % caminho
	if not FileAccess.file_exists(save_path):
		_log_warning("O arquivo de save não existe: %s" % save_path)
		return
	var error = DirAccess.remove_absolute(save_path)
	if error == OK:
		_log_info("Arquivo deletado com sucesso: %s" % save_path)
	else:
		_log_error("Erro ao tentar deletar o arquivo: %s" % error)

var save_timer := 0.0
var save_interval := 300.0

func _process(delta):
	save_timer += delta
	if save_timer >= save_interval:
		print("game saved!")
		save_game()
		save_timer = 0
