extends CanvasLayer

@onready var mission_list = $Panel/VBoxContainer/MissionList
@onready var panel = $Panel
@onready var mission_button = $Open


func _ready():
	load_missions(Global.player["week"])
	TimeManager.connect("week_changed", Callable(self, "load_missions"))

func load_missions(phase: int):
	# limpa lista
	for child in mission_list.get_children():
		child.queue_free()
	
	var missions = MissionManager.missions_data[phase]
	print(missions)
	
	for m in missions:
		var label = Label.new()
		label.text = "- " + m
		mission_list.add_child(label)

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_F):
		panel.visible = true
		mission_button.visible = false
	else:
		panel.visible = false
		mission_button.visible = true
