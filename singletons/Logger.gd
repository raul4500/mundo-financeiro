extends Node

const PROJECT_LOG_PATH := "res://logs/game_runtime.log"
const USER_LOG_PATH := "user://logs/game_runtime.log"

var active_log_path: String = PROJECT_LOG_PATH

func _ready() -> void:
	_prepare_log_file()
	log_info("Logger inicializado")

func _prepare_log_file() -> void:
	var project_ok = _ensure_dir("res://logs")
	var user_ok = _ensure_dir("user://logs")

	if project_ok and _can_write_file(PROJECT_LOG_PATH):
		active_log_path = PROJECT_LOG_PATH
		_append_line("=== Sessão iniciada ===")
		return

	if user_ok and _can_write_file(USER_LOG_PATH):
		active_log_path = USER_LOG_PATH
		_append_line("=== Sessão iniciada ===")
		return

	print("[Logger] Falha ao preparar arquivo de log.")
	active_log_path = PROJECT_LOG_PATH

func _ensure_dir(path: String) -> bool:
	var error = DirAccess.make_dir_recursive_absolute(path)
	return error == OK or error == ERR_ALREADY_EXISTS

func _can_write_file(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.close()
	return true

func _append_line(message: String) -> void:
	var target_path = active_log_path
	if target_path.is_empty():
		target_path = PROJECT_LOG_PATH

	var file = FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		if target_path != USER_LOG_PATH:
			file = FileAccess.open(USER_LOG_PATH, FileAccess.WRITE)
		if file == null:
			print("[Logger] Não foi possível abrir o arquivo de log: %s" % target_path)
			return
		target_path = USER_LOG_PATH
		active_log_path = USER_LOG_PATH

	file.seek_end()
	var timestamp = Time.get_datetime_string_from_system(false)
	file.store_string("[%s] %s\n" % [timestamp, message])
	file.close()

func log_info(message: String) -> void:
	_append_line("[INFO] " + str(message))

func log_warning(message: String) -> void:
	_append_line("[WARN] " + str(message))

func log_error(message: String) -> void:
	_append_line("[ERROR] " + str(message))
	print("[ERROR] " + str(message))

func log_exception(message: String) -> void:
	_append_line("[EXCEPTION] " + str(message))
	print("[EXCEPTION] " + str(message))

func log_scene(message: String) -> void:
	_append_line("[SCENE] " + str(message))
