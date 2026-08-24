extends Node2D

const COUNTDOWN_SECONDS := 3.0
const UI_THEME = preload("res://themes/font_theme.tres")
const LABEL_THEME = preload("res://themes/label.tres")

# Ponto de partida de cada nível de escolaridade: o índice 0 é o nível 1.
# Cada marcador fica logo depois do checkpoint anterior, para o jogador não
# reconquistar um nível que já tem.
const SPAWN_MARKERS := [
	"map/levels/Marker_1",         # nível 1 — início do mapa
	"map/levels/Level1/Marker_2",  # nível 2 — depois do Level1
	"map/levels/Marker_3",         # nível 3 — depois do Level2
	"map/levels/Marker_4"          # nível 4 — depois do Level3
]
# A câmera nasce um pouco à frente do jogador, como nos marcadores originais
# (jogador 170 / câmera 212 no nível 1).
const CAMERA_OFFSET := Vector2(42, -32)

@onready var player = $"raul-minigame"
@onready var camera = $Camera2D
@onready var level_label = $Camera2D/Level

var time_display: Label
var curr_level = Global.player["school_level"]

# Tela de início: o jogo fica travado até o jogador apertar "Começar" e a
# contagem de 3 segundos terminar.
var start_layer: CanvasLayer
var start_countdown_label: Label
var start_button: Button
var countdown_left := 0.0
var counting := false
var started := false

func notify_tutorial_minigame_finished() -> void:
	TutorialManager.on_minigame_finished()

func _ready() -> void:
	Global.play_time = true
	_create_time_display()
	_place_player()
	_create_start_screen()
	# Trava até o jogador começar. O contador de Global convive com o lock do
	# alerta de tutorial, que pode estar aberto neste momento.
	Global.lock_gameplay()

func _exit_tree() -> void:
	# Encerra a sessão ao sair da cena por qualquer caminho, para nenhuma
	# sessão "aberta" sobrar e valer na próxima entrada no minigame.
	MinigameManager.end_session()
	# Se a cena for abandonada antes de começar (o menu de pausa permite voltar
	# ao menu principal), o lock precisa ser devolvido, senão o contador fica
	# preso e o jogo inteiro continua travado.
	if not started:
		started = true
		Global.unlock_gameplay()

# Posiciona jogador e câmera no trecho do mapa correspondente à escolaridade.
func _place_player() -> void:
	var index = clamp(curr_level - 1, 0, SPAWN_MARKERS.size() - 1)
	var marker = get_node_or_null(SPAWN_MARKERS[index])
	if marker == null:
		push_error("minigame: marcador de spawn não encontrado: %s" % SPAWN_MARKERS[index])
		return
	player.global_position = marker.global_position
	camera.global_position = marker.global_position + CAMERA_OFFSET

func _create_time_display() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	layer.add_child(time_display)

# =============================
# 🎬 TELA DE INÍCIO
# =============================
func _create_start_screen() -> void:
	# layer 50: acima do display de tempo (5), abaixo do AlertManager (100),
	# para as mensagens de tutorial continuarem por cima desta caixa.
	start_layer = CanvasLayer.new()
	start_layer.layer = 50
	add_child(start_layer)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_layer.add_child(center)

	var box_panel = PanelContainer.new()
	box_panel.theme = UI_THEME
	center.add_child(box_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	box_panel.add_child(margin)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	box.add_child(_make_label("Aula de hoje", 26))
	var info = _make_label("Desvie dos obstáculos até o próximo checkpoint. Você sobe no máximo 1 nível por tentativa.", 16)
	info.custom_minimum_size = Vector2(460, 0)
	box.add_child(info)

	start_countdown_label = _make_label("", 40)
	start_countdown_label.custom_minimum_size = Vector2(0, 52)
	box.add_child(start_countdown_label)

	start_button = Button.new()
	start_button.theme = UI_THEME
	start_button.text = "Começar"
	start_button.custom_minimum_size = Vector2(200, 48)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_start_pressed)
	box.add_child(start_button)

# label.tres nos textos: o Label do font_theme.tres tem fundo próprio
# (label_round.png) e corpo 24, que empilhados viram caixas dentro da caixa.
func _make_label(text: String, font_size: int) -> Label:
	var label = Label.new()
	label.theme = LABEL_THEME
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text = text
	return label

func _on_start_pressed() -> void:
	if counting or started:
		return
	counting = true
	countdown_left = COUNTDOWN_SECONDS
	start_button.visible = false

func _process_start_screen(delta: float) -> void:
	if counting:
		countdown_left -= delta
		if countdown_left <= 0.0:
			_begin_game()
			return
		start_countdown_label.text = str(int(ceil(countdown_left)))
		return

	# Enquanto houver mensagem de tutorial na tela ou na fila, o botão fica
	# escondido: a caixa de início só aparece depois das explicações.
	var tutorial_busy = AlertManager.panel.visible or not TutorialManager.pending_messages.is_empty()
	start_button.visible = not tutorial_busy

func _begin_game() -> void:
	if started:
		return
	started = true
	start_layer.visible = false
	# A corrida só passa a valer aqui. Antes disso o jogador está parado na
	# tela de início, e nos níveis 2+ ele nasce colado no checkpoint — sem
	# esta ordem, a área dispararia antes de ele sequer poder jogar.
	MinigameManager.begin_session()
	Global.unlock_gameplay()

func _process(delta: float) -> void:
	if not started:
		_process_start_screen(delta)
		return

	if Global.gameplay_locked:
		return

	camera.global_position.x += 1.6666666
	level_label.text = str(int(Global.player["school_level"]))
