extends CanvasLayer

@onready var clock_label = $ClockLabel
@onready var day_label = $DayLabel

func _ready():
	# Conectar ao TimeManager
	TimeManager.connect("time_changed", Callable(self, "_on_time_changed"))
	TimeManager.connect("day_changed", Callable(self, "_on_day_changed"))
	
	# Atualizar imediatamente ao iniciar
	_update_clock(Global.player["hour"])
	_update_day(Global.player["day"])

func _on_time_changed(hour):
	_update_clock(hour)

func _update_clock(hour):
	var h = int(hour)
	clock_label.text = " %d" %h

func _on_day_changed(day):
	_update_day(day)

func _update_day(day):
	day_label.text = "Dia " + str(day)
