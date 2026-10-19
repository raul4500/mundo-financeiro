extends CanvasLayer

@onready var mission_list = $Overlay/Panel/MissionList
@onready var panel = $Overlay
@onready var open_button: Button = $Open

var opened = false

# Override de cor, e não modulate: o label.tres do painel pinta a fonte de
# preto, e modulate multiplica — preto vezes verde continua preto.
const DONE_COLOR := Color(0.1, 0.5, 0.15)

# [{ "id": String, "description": String, "label": Label }]
var _entries: Array = []


func _ready():
	load_missions(Global.player["week"])
	TimeManager.connect("week_changed", Callable(self, "load_missions"))
	MissionManager.mission_completed.connect(_on_mission_completed)

func load_missions(phase: int):
	# limpa lista
	for child in mission_list.get_children():
		child.queue_free()
	_entries.clear()

	var missions = MissionManager.get_missions(phase)

	if missions.is_empty() and phase > MissionManager.missions_data.keys().max():
		var label = Label.new()
		label.text = "Todas as missões foram concluídas!"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_list.add_child(label)
		return

	for m in missions:
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mission_list.add_child(label)
		_entries.append({
			"id": str(m.get("id", "")),
			"description": str(m.get("description", "")),
			"label": label
		})

	_refresh_marks()

func _refresh_marks() -> void:
	for entry in _entries:
		var label = entry["label"]
		if not is_instance_valid(label):
			continue
		var done: bool = MissionManager.is_completed(entry["id"])
		label.text = ("✓ " if done else "- ") + entry["description"]
		if done:
			label.add_theme_color_override("font_color", DONE_COLOR)
		else:
			label.remove_theme_color_override("font_color")

func _on_mission_completed(_mission: Dictionary) -> void:
	_refresh_marks()

# Com o HUD do personagem escondido (minigame do parque, ver
# Global.player_hud_hidden) o botão de missões some junto, e um painel que
# estivesse aberto fecha. Dá para abrir por M/F também, mas _unhandled_input
# e _on_open_pressed já ignoram o atalho nesse estado.
func _process(_delta: float) -> void:
	var hud_hidden := Global.player_hud_hidden
	open_button.visible = not hud_hidden
	if hud_hidden and panel.visible:
		panel.visible = false

func _on_open_pressed() -> void:
	if Global.player_hud_hidden:
		return	
	panel.visible = true
	_refresh_marks()

func _on_close_pressed() -> void:
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if Global.player_hud_hidden or Global.gameplay_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M or event.keycode == KEY_F:
			if panel.visible:
				_on_close_pressed()
			else:
				_on_open_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel") and panel.visible:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

