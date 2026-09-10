extends CanvasLayer

@onready var clock_label = $"Clock-label"
@onready var week_label = $"Week-label"

func _ready():
	# Conectar ao TimeManager
	TimeManager.connect("time_changed", Callable(self, "_on_time_changed"))
	TimeManager.connect("day_changed", Callable(self, "_on_day_changed"))
	
	# Atualizar imediatamente ao iniciar
	_update_clock(TimeManager.current_hour)
	_update_day()

func _on_time_changed(hour):
	_update_clock(hour)

func _update_clock(hour):
	var h = int(hour)
	clock_label.text = "Dia %d  -  %02dh" % [TimeManager.current_day, h]

func _on_day_changed(day):
	_update_day()

func _process(_delta: float) -> void:
	visible = not Global.player_hud_hidden

func _update_day():
	week_label.text = "Semana %d" %Global.player["week"]
