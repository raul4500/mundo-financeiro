extends CanvasLayer

# Controla uma corrida do minigame de moedas do parque: spawna uma moeda por
# vez dentro do polígono da área do parque (ver park_minigame_trigger.gd),
# mostra o timer geral e o placar no topo da tela — com o resto do HUD
# escondido (Global.player_hud_hidden) — e a cada ParkMinigameManager.
# COINS_PER_QUIZ moedas pausa para um quiz (até MAX_QUIZZES_PER_SESSION por
# sessão). BACKSPACE sai da sessão a qualquer momento fora de um quiz, sem
# perder cupom/recompensa já ganhos (esses já estão em Global.player).
# Construída toda em código (mesmo padrão do AlertManager) para não depender
# de uma .tscn nova.

const UI_THEME = preload("res://themes/font_theme.tres")
const ParkQuizData = preload("res://scripts/park/park_quiz_data.gd")
const ParkCoinScene = preload("res://scenes/park/park_coin.tscn")

# Largura do quiz. Os enunciados são situações de várias linhas e as alternativas
# podem ter uma dezena de palavras: o texto quebra em vez de alargar a caixa.
const QUIZ_WIDTH := 560
# Altura da área de texto do alerta de resposta errada (padrão do alerta: 230).
const QUIZ_FEEDBACK_HEIGHT := 360
const ParkCoinScript = preload("res://scripts/park/park_coin.gd")

var _world: Node2D
var _spawn_polygon: PackedVector2Array
var _spawn_bounds_min: Vector2
var _spawn_bounds_max: Vector2
var _time_left: float
var _coins_collected := 0
var _quizzes_done := 0
var _asked_indices: Array = []
var _current_coin: Area2D
var _active := false
var _quiz_current_correct := -1
# A pergunta em tela inteira (não só o gabarito): ao errar, o alerta precisa das
# explicações de cada alternativa.
var _quiz_current_question: Dictionary = {}

var _timer_label: Label
var _score_label: Label
var _quiz_layer: Control
var _quiz_question_label: Label
var _quiz_option_buttons: Array = []
var _alerts_deferred := false

func start(world: Node2D, spawn_polygon: PackedVector2Array) -> void:
	_world = world
	_spawn_polygon = spawn_polygon
	_spawn_bounds_min = spawn_polygon[0]
	_spawn_bounds_max = spawn_polygon[0]
	for point in spawn_polygon:
		_spawn_bounds_min.x = min(_spawn_bounds_min.x, point.x)
		_spawn_bounds_min.y = min(_spawn_bounds_min.y, point.y)
		_spawn_bounds_max.x = max(_spawn_bounds_max.x, point.x)
		_spawn_bounds_max.y = max(_spawn_bounds_max.y, point.y)
	_time_left = ParkMinigameManager.SESSION_SECONDS
	_active = true
	Global.player_hud_hidden = true
	ParkMinigameManager.begin_session()
	AlertManager.defer_alerts()
	_alerts_deferred = true
	_build_ui()
	_spawn_next_coin()

func _build_ui() -> void:
	layer = 90

	# HUD em três cantos: moedas à esquerda, tempo restante no centro e a dica
	# de sair à direita. Uma linha (HBoxContainer) com três células de largura
	# igual: como as duas laterais têm o mesmo espaço, o tempo fica no centro
	# exato da tela, mesmo com textos laterais de tamanhos diferentes.
	var top := Control.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	top.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_score_label = _add_hud_cell(row, BoxContainer.ALIGNMENT_BEGIN, 20)
	_timer_label = _add_hud_cell(row, BoxContainer.ALIGNMENT_CENTER, 28)
	var exit_hint := _add_hud_cell(row, BoxContainer.ALIGNMENT_END, 16)
	exit_hint.text = "Pressione BACKSPACE para sair"

	_update_labels()
	_build_quiz_ui()

# Uma célula do HUD (expande igual às outras) com um Label dentro, no tema do
# jogo. A célula, e não o Label, é que expande: o Label do font_theme.tres tem
# fundo próprio (label_round.png) e, esticado, viraria uma faixa de um terço da
# tela. Devolve o Label.
func _add_hud_cell(row: HBoxContainer, alignment: int, font_size: int) -> Label:
	var cell := HBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.alignment = alignment
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cell)

	var label := Label.new()
	label.theme = UI_THEME
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)
	return label

func _update_labels() -> void:
	_timer_label.text = "%d s" % int(ceil(max(_time_left, 0.0)))
	_score_label.text = "Moedas: %d" % _coins_collected

func _process(delta: float) -> void:
	if not _active:
		return
	# Sair só é permitido fora do quiz: assim uma pergunta iniciada é sempre
	# respondida antes do jogador poder ir embora, e nenhuma sessão futura
	# herda um quiz "pela metade".
	if Global.gameplay_locked or _quiz_layer.visible:
		return
	if Input.is_key_pressed(KEY_BACKSPACE):
		_quit_session()
		return
	_time_left -= delta
	_update_labels()
	if _time_left <= 0.0:
		_end_session()

# =============================
# MOEDAS
# =============================
func _spawn_next_coin() -> void:
	if not _active:
		return
	var coin: Area2D = null
	if ParkCoinScene != null:
		coin = ParkCoinScene.instantiate() as Area2D
	if coin == null:
		coin = ParkCoinScript.new()
	coin.position = _random_point_in_spawn_polygon()
	coin.collected.connect(_on_coin_collected)
	coin.expired.connect(_on_coin_expired)
	_world.add_child(coin)
	_current_coin = coin

# Amostragem por rejeição: sorteia dentro do retângulo que envolve o polígono
# e descarta o que cair fora dele. Com um parque razoavelmente convexo isso
# converge em 1-2 tentativas; o limite de 30 e o fallback pro centroide só
# existem para não travar caso o polígono seja muito fino ou côncavo.
func _random_point_in_spawn_polygon() -> Vector2:
	for _attempt in range(30):
		var candidate := Vector2(
			randf_range(_spawn_bounds_min.x, _spawn_bounds_max.x),
			randf_range(_spawn_bounds_min.y, _spawn_bounds_max.y)
		)
		if Geometry2D.is_point_in_polygon(candidate, _spawn_polygon):
			return candidate
	var centroid := Vector2.ZERO
	for point in _spawn_polygon:
		centroid += point
	return centroid / _spawn_polygon.size()

func _on_coin_collected() -> void:
	_current_coin = null
	if not _active:
		return
	_coins_collected += 1
	_update_labels()
	if _coins_collected % ParkMinigameManager.COINS_PER_QUIZ == 0 and _quizzes_done < ParkMinigameManager.MAX_QUIZZES_PER_SESSION:
		_start_quiz()
	else:
		_spawn_next_coin()

func _on_coin_expired() -> void:
	_current_coin = null
	if _active:
		_spawn_next_coin()

# =============================
# QUIZ
# =============================
func _build_quiz_ui() -> void:
	_quiz_layer = Control.new()
	_quiz_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quiz_layer.visible = false
	_quiz_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_quiz_layer)

	var blocker := ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0.6)
	_quiz_layer.add_child(blocker)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quiz_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.theme = load("res://themes/font_theme.tres")
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	_quiz_question_label = Label.new()
	_quiz_question_label.custom_minimum_size = Vector2(QUIZ_WIDTH, 0)
	_quiz_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Enunciado de situação tem várias linhas: corpo menor que o padrão (24) para
	# a caixa inteira caber na tela junto das quatro alternativas.
	_quiz_question_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_quiz_question_label)

	_quiz_option_buttons.clear()
	for i in range(4):
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		# Button não quebra linha sozinho: sem autowrap e largura mínima, uma
		# alternativa longa alargaria a caixa inteira.
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(QUIZ_WIDTH, 0)
		btn.pressed.connect(_on_quiz_option_pressed.bind(i))
		box.add_child(btn)
		_quiz_option_buttons.append(btn)

func _start_quiz() -> void:
	var pool: Array = ParkMinigameManager.questions_for_current_week()
	if pool.is_empty():
		_spawn_next_coin()
		return
	var available: Array = []
	for i in range(pool.size()):
		if not _asked_indices.has(i):
			available.append(i)
	if available.is_empty():
		_asked_indices.clear()
		available = range(pool.size())
	var idx = available[randi() % available.size()]
	_asked_indices.append(idx)
	var q: Dictionary = pool[idx]
	_quiz_current_question = q

	_quiz_question_label.text = str(q.get("question", ""))
	var options: Array = q.get("options", [])
	for i in range(_quiz_option_buttons.size()):
		_quiz_option_buttons[i].text = str(options[i]) if i < options.size() else ""
	_quiz_current_correct = int(q.get("correct", -1))

	Global.play_time = false
	Global.lock_gameplay()
	_quiz_layer.visible = true

func _on_quiz_option_pressed(index: int) -> void:
	_quiz_layer.visible = false
	Global.unlock_gameplay()
	_quizzes_done += 1

	var correct := index == _quiz_current_correct
	var feedback := ""
	if correct:
		ParkMinigameManager.grant_quiz_reward()
		feedback = "Resposta certa! Você ganhou um cupom de %d%% de desconto no mercado." % int(ParkMinigameManager.QUIZ_REWARD_DISCOUNT * 100)
	else:
		# Explica por que a alternativa escolhida está errada e qual era a certa.
		feedback = ParkQuizData.wrong_answer_feedback(_quiz_current_question, index)
	# A explicação de erro é longa: altura própria para a resposta certa não
	# ficar escondida atrás de rolagem. Acerto usa a altura padrão.
	AlertManager.alert_immediate(feedback, false, Callable(self, "_on_quiz_feedback_closed"), 0, 0 if correct else QUIZ_FEEDBACK_HEIGHT)

func _on_quiz_feedback_closed() -> void:
	if _active:
		_spawn_next_coin()

# =============================
# FIM DE SESSÃO
# =============================
func _end_session() -> void:
	_active = false
	if is_instance_valid(_current_coin):
		_current_coin.queue_free()
	Global.player_hud_hidden = false
	ParkMinigameManager.end_session()
	AlertManager.alert_immediate("Tempo esgotado! Você coletou %d moeda(s)." % _coins_collected)
	if _alerts_deferred:
		_alerts_deferred = false
		AlertManager.resume_alerts()
	queue_free()

# Saída antecipada pelo próprio jogador (BACKSPACE). Só chamada fora do quiz
# (ver _process), então nunca corta uma pergunta pela metade. Cupom/desconto
# já concedidos ficam em Global.player — essa função só limpa o estado local
# da sessão (moeda em tela, HUD, trava de sessão ativa), igual _end_session().
func _quit_session() -> void:
	_active = false
	if is_instance_valid(_current_coin):
		_current_coin.queue_free()
	Global.player_hud_hidden = false
	ParkMinigameManager.end_session()
	AlertManager.alert_immediate("Você saiu do parque. Moedas coletadas: %d." % _coins_collected)
	if _alerts_deferred:
		_alerts_deferred = false
		AlertManager.resume_alerts()
	queue_free()

# Cobre a saída pelo menu de pausa (Sair troca de cena direto, sem passar por
# _end_session()/_quit_session()): sem isto a sessão ficava presa como "ativa"
# para sempre em ParkMinigameManager, e um quiz aberto na hora vazava o
# contador de Global.gameplay_locked, travando o jogo inteiro daí em diante.
func _exit_tree() -> void:
	if _active:
		_active = false
		ParkMinigameManager.end_session()
	Global.player_hud_hidden = false
	if _alerts_deferred:
		_alerts_deferred = false
		AlertManager.resume_alerts()
	if is_instance_valid(_quiz_layer) and _quiz_layer.visible:
		Global.unlock_gameplay()
