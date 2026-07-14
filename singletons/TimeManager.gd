extends Node

signal time_changed(hour, minute)
signal day_changed(day)

var current_day: int
var current_hour: int
var current_minute: int

var time_scale: float = 60.0
var timer: float = 0.0

func update_time():
	current_day = Global.player["day"]
	current_minute = 0
	current_hour = Global.player["hour"]

func _ready() -> void:
	update_time()

func _process(delta):
	if Global.play_time == true:
		timer += delta * time_scale * 1000
		if timer >= 60:
			timer = 0
			_add_minute()


func _add_minute():
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			Global.player["day"] = current_day
			emit_signal("day_changed", current_day)
		if current_day >= 6:
			Global.player["day"] = 0
			emit_signal("day_changed", 1)
			emit_signal("week_changed")
			update_time()
			if MissionManager.verificate_missons(Global.player["week"]):
				Global.player["week"] += 1
				Global.get_paid()
	Global.player["hour"] = current_hour
	emit_signal("time_changed", current_hour)
