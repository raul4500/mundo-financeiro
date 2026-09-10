extends CanvasLayer

@onready var mission_list = $Panel/MissionList
@onready var panel = $Panel
@onready var mission_button = $Open


func _ready():
	load_missions(Global.player["week"])
	TimeManager.connect("week_changed", Callable(self, "load_missions"))

func load_missions(phase: int):
	# limpa lista
	for child in mission_list.get_children():
		child.queue_free()

	var missions = MissionManager.get_missions(phase)

	if missions.is_empty() and phase > MissionManager.missions_data.keys().max():
		var label = Label.new()
		label.text = "Todas as missões foram concluídas!"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_list.add_child(label)
		return

	for m in missions:
		var label = Label.new()
		label.text = "- " + m["description"]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_list.add_child(label)

func _process(delta: float) -> void:
	if Global.player_hud_hidden:
		panel.visible = false
		mission_button.visible = false
		return
	if Input.is_key_pressed(KEY_F):
		panel.visible = true
		mission_button.visible = false
	else:
		panel.visible = false
		mission_button.visible = true
