extends Label

func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	_update_time()

func _exit_tree() -> void:
	if TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.disconnect(_on_time_changed)
	if TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.disconnect(_on_day_changed)

func _on_time_changed(_hour: int) -> void:
	_update_time()

func _on_day_changed(_day: int) -> void:
	_update_time()

func _update_time() -> void:
	text = "Dia %d • %02dh" % [
		TimeManager.current_day,
		TimeManager.current_hour
	]
