extends CanvasLayer

@onready var mission_list = $Panel/MissionList
@onready var panel = $Panel
@onready var mission_button = $Open

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

func _process(_delta: float) -> void:
	if Global.player_hud_hidden:
		panel.visible = false
		mission_button.visible = false
		return
	var open := Input.is_key_pressed(KEY_F)
	panel.visible = open
	mission_button.visible = not open
	# Uma missão pode deixar de estar cumprida a qualquer momento (gastar o
	# dinheiro que a satisfazia, uma penalidade da meia-noite), e isso não
	# emite sinal nenhum — por isso reavalia sempre que o painel está aberto,
	# não só no instante em que F é pressionado.
	if open:
		_refresh_marks()
