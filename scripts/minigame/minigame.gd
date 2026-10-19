extends Node2D

const UI_THEME = preload("res://themes/font_theme.tres")
const LABEL_THEME = preload("res://themes/label.tres")

# Ponto de partida de cada nível de escolaridade: o índice 0 é o nível 1.
# Cada marcador fica logo depois do checkpoint anterior, para o jogador não
# reconquistar um nível que já tem.
const SPAWN_MARKERS := [
	"Map/levels/Marker_1",         # nível 1 — início do mapa
	"Map/levels/Marker_2",         # nível 2 — depois do Level1
	"Map/levels/Marker_3",         # nível 3 — depois do Level2
	"Map/levels/Marker_4",         # nível 4 — depois do Level3
	"Map/levels/Marker_5"          # nível 5 — depois do Level4
]
# A câmera nasce um pouco à frente do jogador, como nos marcadores originais
# (jogador 170 / câmera 212 no nível 1).
const CAMERA_OFFSET := Vector2(42, -32)
# Distância que o jogador recua para fazer a entrada correndo. Com zoom 4 a
# meia-tela é 144px, então 300px atrás do marcador o deixa fora do campo de
# visão; a 100px/s (raul_minigame.SPEED) são ~3s até chegar, o que substitui a
# contagem regressiva.
const RUN_IN_PADDING := 300.0

@onready var player = $"Player-minigame"
@onready var camera = $Camera2D
# HUD de nível e salário. Vive num CanvasLayer (nó Hud), não na Camera2D: filho
# da câmera é desenhado no mundo e herda o zoom 4, então um texto de 8 px era
# renderizado pequeno e esticado 4x, ficando embaçado. No CanvasLayer o texto é
# rasterizado no tamanho final da tela, sem mexer em zoom nem em escalas.
@onready var level_label: Label = $Hud/Margin/Box/Level
@onready var salary_label: Label = $Hud/Margin/Box/Salary

var curr_level = Global.player["school_level"]
# Último valor mostrado no HUD. Evita reescrever o texto todo quadro e deixa o
# HUD se atualizar sozinho quando o nível sobe no meio da corrida.
var _hud_level := -1
var _hud_salary := -1

# Tela de início: o jogo fica travado até o jogador apertar "Começar" e a
# contagem de 3 segundos terminar.
var start_layer: CanvasLayer
var start_button: Button
var started := false

# Entrada correndo: o jogador nasce atras do marcador, fora da tela, e corre
# ate ele. A camera fica parada ate a chegada, entao ele "entra em cena".
#
# A corrida so passa a valer quando ele chega (begin_session no fim do run-in,
# nunca antes). E isso que torna o recuo seguro: recuar 300px passa por cima do
# checkpoint anterior (Marker_3 x=1926 / Level2 x=1899) e, no nivel 3, do
# obstacle8 em x=1779 -- mas com a sessao inativa o MinigameManager ignora as
# duas areas. Chamar begin_session antes do run-in era o bug 8.2: o obstaculo
# no caminho encerrava a corrida no mesmo instante.
var run_in_active := false
var run_in_target_x := 0.0

# A cena pega um lock em _ready() e o devolve ao comecar a correr. Sem esta
# flag, sair no meio do run-in devolveria o mesmo lock duas vezes.
var lock_released := false
var alerts_deferred := false

func notify_tutorial_minigame_finished() -> void:
	TutorialManager.on_minigame_finished()

func _ready() -> void:
	MinigameManager.is_in_minigame = true
	Global.play_time = false
	curr_level = int(Global.player.get("school_level", 1))
	_place_player()
	_refresh_hud()
	_create_start_screen()
	# Trava até o jogador começar. O contador de Global convive com o lock do
	# alerta de tutorial, que pode estar aberto neste momento.
	Global.lock_gameplay()

func _exit_tree() -> void:
	MinigameManager.is_in_minigame = false
	# Encerra a sessão ao sair da cena por qualquer caminho, para nenhuma
	# sessão "aberta" sobrar e valer na próxima entrada no minigame.
	MinigameManager.end_session()
	if alerts_deferred:
		alerts_deferred = false
		AlertManager.resume_alerts()
	# Se a cena for abandonada antes de começar (o menu de pausa permite voltar
	# ao menu principal), o lock precisa ser devolvido, senão o contador fica
	# preso e o jogo inteiro continua travado.
	if not lock_released:
		lock_released = true
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
	_refresh_hud()

# Mostra nível e salário atuais. Lê de Global.player (que o MinigameManager
# atualiza ao subir de nível, junto com update_salary()) e só mexe no texto
# quando o valor mudou.
func _refresh_hud() -> void:
	var level := int(Global.player.get("school_level", 1))
	if level != _hud_level:
		_hud_level = level
		level_label.text = MinigameManager.LEVEL_LABELS[clampi(level - 1, 0, MinigameManager.LEVEL_LABELS.size() - 1)]
	var salary := int(Global.player.get("salary", 0))
	if salary != _hud_salary:
		_hud_salary = salary
		salary_label.text = "Salário: R$ %d" % salary

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
	var info = _make_label("Desvie dos obstáculos até o próximo checkpoint.", 16)
	info.custom_minimum_size = Vector2(460, 0)
	box.add_child(info)

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
	if started or run_in_active:
		return
	start_layer.visible = false
	start_button.visible = false

	# O ponto onde a câmera volta a seguir o jogador. Mesma fórmula do follow
	# em _process, para a troca de câmera parada -> câmera seguindo não dar salto.
	run_in_target_x = camera.global_position.x - CAMERA_OFFSET.x
	player.global_position.x = run_in_target_x - RUN_IN_PADDING
	run_in_active = true

	# raul_minigame.gd já aplica velocity.x = SPEED todo frame; destravar o
	# gameplay é o que basta para ele sair correndo.
	lock_released = true
	Global.unlock_gameplay()

	# Adia alertas externos (18h, eventos inesperados) para não interromper os saltos
	AlertManager.defer_alerts()
	alerts_deferred = true

# A corrida só passa a valer quando o jogador chega ao marcador. Ver o comentário
# de run_in_active: é isto que impede o obstáculo do caminho de encerrar a
# tentativa antes de o jogador ter controle.
func _process_run_in() -> void:
	if player.global_position.x < run_in_target_x:
		return
	run_in_active = false
	started = true
	MinigameManager.begin_session()

func _process_start_screen(delta: float) -> void:
	var tutorial_busy = AlertManager.panel.visible or not TutorialManager.pending_messages.is_empty()
	start_button.visible = not tutorial_busy

func _process(delta: float) -> void:
	# Antes dos early-returns: o checkpoint trava o gameplay no mesmo quadro em
	# que o nível sobe, e o HUD ainda precisa mostrar o nível e o salário novos.
	_refresh_hud()
	if not started:
		# Durante o run-in a câmera fica parada onde _place_player() a deixou:
		# é o que faz o jogador aparecer vindo de fora da tela.
		if run_in_active:
			_process_run_in()
		else:
			_process_start_screen(delta)
		return

	if Global.gameplay_locked:
		return

	# Segue o jogador apenas no eixo X, mantendo a coordenada Y atual da câmera.
	# Não há smoothing — posição é atualizada diretamente.
	var target_x = player.global_position.x + CAMERA_OFFSET.x
	camera.global_position = Vector2(target_x, camera.global_position.y)
