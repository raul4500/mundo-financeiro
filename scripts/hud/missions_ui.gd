extends CanvasLayer

@onready var mission_list = $Overlay/Panel/MissionList
@onready var panel = $Overlay
@onready var open_button: Button = $Open
# Botão GUIA, vizinho do MISSÕES. Abre a janela do Guia do Jogo
# (scripts/ui/tutorial_notebook.gd), que é irmã deste nó dentro do Player.
@onready var guide_button: Button = $OpenGuide

var opened = false
var _pulse_tween: Tween

# Missão cumprida troca a variação do tema (LabelDone, em font_theme.tres): a
# pílula marrom vira verde, como o botão de comprar. Nada de cor solta no código.
const DONE_VARIATION := &"LabelDone"

# Pulso do botão MISSÕES durante o tutorial (ver _start_pulse).
const PULSE_SCALE := Vector2(1.08, 1.08)
const PULSE_SECONDS := 0.45

# [{ "id": String, "description": String, "label": Label }]
var _entries: Array = []


func _ready():
	load_missions(Global.player["week"])
	TimeManager.connect("week_changed", Callable(self, "load_missions"))
	MissionManager.mission_completed.connect(_on_mission_completed)
	if not TutorialManager.missions_preview_requested.is_connected(_on_tutorial_missions_preview):
		TutorialManager.missions_preview_requested.connect(_on_tutorial_missions_preview)

func load_missions(phase: int):
	_stop_pulse()
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
		label.text = ("✓ " if done else "• ") + entry["description"]
		label.theme_type_variation = DONE_VARIATION if done else &""

func _on_mission_completed(_mission: Dictionary) -> void:
	_refresh_marks()

# Com o HUD do personagem escondido (minigame do parque, ver
# Global.player_hud_hidden) o botão de missões some junto, e um painel que
# estivesse aberto fecha. Dá para abrir por M/F também, mas _unhandled_input
# e _on_open_pressed já ignoram o atalho nesse estado.
func _process(_delta: float) -> void:
	var hud_hidden := Global.player_hud_hidden
	open_button.visible = not hud_hidden
	guide_button.visible = not hud_hidden
	if hud_hidden and panel.visible:
		panel.visible = false

func _on_guide_pressed() -> void:
	var notebook = get_parent().get_node_or_null("TutorialNotebook")
	if notebook != null and notebook.has_method("open_notebook"):
		notebook.open_notebook()

func _on_open_pressed() -> void:
	if Global.player_hud_hidden:
		return
	# Abrir o painel é o que o tutorial pedia: o pulso cumpriu o papel.
	_stop_pulse()
	panel.visible = true
	_refresh_marks()

func _on_close_pressed() -> void:
	panel.visible = false

# O tutorial não abre mais o painel por conta própria: a caixa de alerta, no
# centro da tela, cobria o painel inteiro e o jogador só via uma faixa dele
# embaixo do texto. Quem lista as missões é o próprio alerta (ver
# TutorialManager.missions_intro_text); aqui o botão MISSÕES pulsa, sem mudar de
# cor, até o jogador abrir o painel (clique, M ou F).
func _on_tutorial_missions_preview(highlight: bool) -> void:
	if highlight:
		_start_pulse()
	elif panel.visible:
		_on_close_pressed()

func _start_pulse() -> void:
	if not is_instance_valid(open_button):
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		return
	open_button.pivot_offset = open_button.size / 2.0
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(open_button, "scale", PULSE_SCALE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(open_button, "scale", Vector2.ONE, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	if is_instance_valid(open_button):
		open_button.scale = Vector2.ONE

func is_pulsing() -> bool:
	return _pulse_tween != null and _pulse_tween.is_valid()

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

