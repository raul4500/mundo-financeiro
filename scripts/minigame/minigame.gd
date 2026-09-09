extends Node2D

const COUNTDOWN_SECONDS := 3.0
const UI_THEME = preload("res://themes/font_theme.tres")
const LABEL_THEME = preload("res://themes/label.tres")

# Ponto de partida de cada nível de escolaridade: o índice 0 é o nível 1.
# Cada marcador fica logo depois do checkpoint anterior, para o jogador não
# reconquistar um nível que já tem.
const SPAWN_MARKERS := [
	"map/levels/Marker_1",         # nível 1 — início do mapa
	"map/levels/Marker_2",  # nível 2 — depois do Level1
	"map/levels/Marker_3",         # nível 3 — depois do Level2
	"map/levels/Marker_4",         # nível 4 — depois do Level3
	"map/levels/Marker_5"
]
# A câmera nasce um pouco à frente do jogador, como nos marcadores originais
# (jogador 170 / câmera 212 no nível 1).
const CAMERA_OFFSET := Vector2(42, -32)

@onready var player = $"raul-minigame"
@onready var camera = $Camera2D
@onready var level_label = $Camera2D/Level

# Label que mostra o salário atual na câmera
@onready var salary_label = null

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

# O jogador comeca parado no marcador do seu nivel e sai correndo dali.
#
# Havia aqui uma "entrada correndo": ao apertar Começar, o jogador era
# teletransportado 300px PARA TRAS do marcador e corria em auto-run ate ele.
# Os marcadores ficam logo depois do checkpoint anterior (Marker_3 x=1926,
# Level2 x=1899), entao recuar 300px jogava o jogador atras do checkpoint que
# ele ja' tinha conquistado e, no nivel 3+, em cima de obstaculos
# (obstacle8 x=1779). Como begin_session() era chamado antes do auto-run, o
# primeiro obstaculo no caminho encerrava a corrida no mesmo instante: era o
# "minigame da semana 2 trava / game-over imediato" (bug 8.2).

func notify_tutorial_minigame_finished() -> void:
	TutorialManager.on_minigame_finished()

func _ready() -> void:
	Global.play_time = true
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
	# Desliga smoothing da câmera do minigame — o comportamento desejado é seguir
	# apenas no eixo X sem suavização e manter Y fixo mesmo durante pulos.
	camera.position_smoothing_enabled = false

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
	start_layer.visible = false
	start_button.visible = false
	started = true
	MinigameManager.begin_session()
	Global.unlock_gameplay()

func _process_start_screen(delta: float) -> void:
	# Enquanto houver mensagem de tutorial na tela ou na fila, o botão fica
	# escondido: a caixa de início só aparece depois das explicações.
	var tutorial_busy = AlertManager.panel.visible or not TutorialManager.pending_messages.is_empty()
	start_button.visible = not tutorial_busy

func _process(delta: float) -> void:
	if not started:
		_process_start_screen(delta)
		return

	if Global.gameplay_locked:
		return

	# Segue o jogador apenas no eixo X, mantendo a coordenada Y atual da câmera.
	# Não há smoothing — posição é atualizada diretamente.
	var target_x = player.global_position.x + CAMERA_OFFSET.x
	camera.global_position = Vector2(target_x, camera.global_position.y)
	level_label.text = "Level %s" %str(int(Global.player["school_level"]))
	# Atualiza o label de salário
	if salary_label != null:
		salary_label.text = "Salário: R$ %d" % int(Global.player.get("salary", 0))
