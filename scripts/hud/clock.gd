extends CanvasLayer

@onready var clock_label = $ClockLabel
@onready var day_label = $DayLabel

func _ready():
	# Conectar ao TimeManager
	TimeManager.connect("time_changed", Callable(self, "_on_time_changed"))
	TimeManager.connect("day_changed", Callable(self, "_on_day_changed"))
	
	# Atualizar imediatamente ao iniciar
	_update_clock(Global.player["hour"], Global.player["minute"])
	_update_day(TimeManager.current_day)

func _on_time_changed(hour, minute):
	_update_clock(hour, minute)

func _update_clock(hour, minute):
	var h = str(hour).pad_zeros(2)
	var m = str(minute).pad_zeros(2)
	clock_label.text = h + ":" + m

func _on_day_changed(day):
	_update_day(day)

func _update_day(day):
	day_label.text = "Dia " + str(day)
