extends CanvasLayer

# Largura de quebra do texto e altura visível antes de começar a rolar.
# A caixa tem tamanho fixo de propósito: assim ela não muda de tamanho de uma
# mensagem para a outra, e textos longos rolam em vez de esticar a caixa.
# Calibrado para a maior mensagem do tutorial (380 caracteres, ~6 linhas no
# corpo 23 do label.tres) caber sem precisar rolar; a rolagem é a rede de
# segurança para textos maiores que venham a ser adicionados.
const TEXT_WIDTH := 700
const TEXT_VISIBLE_HEIGHT := 230

var panel: Control          # raiz em tela cheia (transparente)
var dialog: PanelContainer  # caixa central com o texto e o botão
var text_scroll: ScrollContainer
var alert_label: Label
var confirm_button: Button
var choice_box: VBoxContainer  # botões de escolha, no lugar do OK
var skip_button: Button
var blocker: ColorRect

var next_step: bool = false
var on_confirm_callback: Callable

# Fila de alertas. A virada de semana dispara missões, tutorial e evento
# inesperado em sequência: sem fila, o último alerta apagava o texto dos
# anteriores e — pior — o contador de `gameplay_locked` ficava preso, porque
# eram N travas (uma por chamada) para um único destravamento (o clique).
var _queue: Array = []

# Fila de alertas adiados. Usada quando _defer_count > 0 (ex.: durante minigames).
# Alertas não-imediatos são retidos aqui em vez de interromper a jogabilidade.
var _defer_count: int = 0
# Instante em que o alerta atual abriu, e quanto tempo o atalho de espaço fica
# ignorado depois disso (ver _input).
const SPACE_GRACE_MSEC := 500
var _shown_at_msec := 0
var _space_grace_msec := 0
var _deferred_queue: Array = []

func defer_alerts() -> void:
	_defer_count += 1

func resume_alerts() -> void:
	_defer_count = max(0, _defer_count - 1)
	if _defer_count == 0 and not _deferred_queue.is_empty():
		for entry in _deferred_queue:
			_queue.append(entry)
		_deferred_queue.clear()
		if not panel.visible:
			_show_next()

func is_deferring() -> bool:
	return _defer_count > 0

func reset() -> void:
	_queue.clear()
	_deferred_queue.clear()
	_defer_count = 0
	_clear_choices()
	if is_instance_valid(panel):
		panel.visible = false
	if is_instance_valid(blocker):
		blocker.visible = false
	if is_instance_valid(skip_button):
		skip_button.visible = false
	on_confirm_callback = Callable()
	next_step = false


func _ready():
	# Autoloads entram na árvore antes da cena atual, então qualquer CanvasLayer
	# da cena (HUD, missões, pause) ficaria por cima do alerta e roubaria os
	# cliques. Uma layer alta garante que o alerta fique sempre no topo.
	layer = 100
	TutorialManager.show_message.connect(alert)
	_create_alert_ui()


func _create_alert_ui():
	# =============================
	# 🔒 BLOQUEADOR DE INPUT (FULL SCREEN)
	# =============================
	blocker = ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0.5) # fundo escuro transparente (50%)
	blocker.visible = false
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP # 🚨 ESSENCIAL

	add_child(blocker)

	# =============================
	# 🎴 RAIZ EM TELA CHEIA (transparente)
	# =============================
	panel = Control.new()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 10

	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	# =============================
	# 🎴 CAIXA CENTRAL DO ALERTA
	# =============================
	var panel_theme = load("res://themes/font_theme.tres")

	# PanelContainer, e não Panel: um Panel não é container, não lê o tamanho
	# mínimo dos filhos e ficava travado em 560x160 enquanto o texto crescia
	# para fora dele. O PanelContainer se dimensiona pelo conteúdo.
	dialog = PanelContainer.new()
	dialog.theme = panel_theme
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)

	# =============================
	# 🏷️ TEXTO (com rolagem)
	# =============================
	# O scroll é quem define o tamanho da área de texto. Com o scroll
	# horizontal desabilitado, o Label recebe a largura do scroll e quebra
	# nela; com o vertical habilitado, textos muito longos rolam em vez de
	# esticar a caixa para fora da tela.
	text_scroll = ScrollContainer.new()
	text_scroll.custom_minimum_size = Vector2(TEXT_WIDTH, TEXT_VISIBLE_HEIGHT)
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	text_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	alert_label = Label.new()
	alert_label.theme = load("res://themes/label.tres")
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	alert_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# IGNORE para a roda do mouse chegar ao ScrollContainer e rolar o texto.
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_scroll.add_child(alert_label)

	# =============================
	# 🔘 BOTÃO
	# =============================
	# focus_mode = FOCUS_NONE: um botão com foco é acionado pela ação "ui_accept",
	# que inclui Enter por padrão. Sem foco, só o clique do mouse aciona o botão
	# e o Espaço continua sendo tratado manualmente em _input().
	confirm_button = Button.new()
	confirm_button.theme = panel_theme
	confirm_button.z_index = 199
	confirm_button.custom_minimum_size = Vector2(250, 0)
	confirm_button.text = "OK"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.pressed.connect(_on_confirm_pressed)

	# =============================
	# 🔀 ESCOLHAS (substituem o OK)
	# =============================
	choice_box = VBoxContainer.new()
	choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_box.add_theme_constant_override("separation", 8)
	choice_box.visible = false

	box.add_child(text_scroll)
	box.add_child(confirm_button)
	box.add_child(choice_box)

	margin.add_child(box)
	dialog.add_child(margin)
	center_container.add_child(dialog)
	panel.add_child(center_container)

	# =============================
	# ⏭️ PULAR TUTORIAL (canto superior direito)
	# =============================
	skip_button = Button.new()
	skip_button.theme = panel_theme
	skip_button.z_index = 199
	skip_button.text = "Pular tutorial"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.visible = false
	skip_button.pressed.connect(_on_skip_pressed)

	# Ancorado no canto superior direito, com 20px de margem.
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_button.offset_left = -220.0
	skip_button.offset_top = 20.0
	skip_button.offset_right = -20.0
	skip_button.offset_bottom = 72.0

	panel.add_child(skip_button)

	add_child(panel)


# =============================
# 🚨 MOSTRAR ALERTA
# =============================
# space_grace_msec > 0: nesse tempo depois de abrir, o atalho de espaço é ignorado
# (só o clique fecha). Para alertas que abrem enquanto o jogador ainda está
# martelando espaço, como o resultado do minigame; 0 = comportamento normal.
#
# text_height > 0: altura da área de texto só para este alerta (padrão:
# TEXT_VISIBLE_HEIGHT). Para textos longos que precisam aparecer inteiros, sem
# rolagem, como a explicação de uma resposta errada do quiz do parque.
func alert(text: String, step: bool = false, callback: Callable = Callable(), immediate: bool = false, space_grace_msec: int = 0, text_height: int = 0):
	var entry = {"text": text, "step": step, "callback": callback, "choices": [], "space_grace_msec": space_grace_msec, "text_height": text_height}
	if _defer_count > 0 and not immediate:
		_deferred_queue.append(entry)
		return
	_queue.append(entry)
	if not panel.visible:
		_show_next()

func alert_immediate(text: String, step: bool = false, callback: Callable = Callable(), space_grace_msec: int = 0, text_height: int = 0) -> void:
	alert(text, step, callback, true, space_grace_msec, text_height)


# =============================
# 🔀 ALERTA COM ESCOLHAS
# =============================
# Cada escolha é {"text": String, "callback": Callable}. O jogador é obrigado a
# clicar numa opção: o OK some e a barra de espaço não fecha, senão a decisão
# sumiria da tela sem virar nada.
func alert_choice(text: String, choices: Array, immediate: bool = false):
	if choices.is_empty():
		alert(text, false, Callable(), immediate)
		return
	var entry = {"text": text, "step": false, "callback": Callable(), "choices": choices}
	if _defer_count > 0 and not immediate:
		_deferred_queue.append(entry)
		return
	_queue.append(entry)
	if not panel.visible:
		_show_next()



func _show_next() -> void:
	if _queue.is_empty():
		return
	var entry = _queue.pop_front()
	_clear_choices()

	blocker.visible = true
	panel.visible = true

	alert_label.text = str(entry["text"])
	next_step = bool(entry["step"])
	on_confirm_callback = entry["callback"]
	confirm_button.visible = true
	confirm_button.text = "Continuar" if on_confirm_callback.is_valid() else "OK"
	# Sem isto, uma mensagem longa deixa o scroll no meio e a próxima abre
	# já rolada, escondendo o começo do texto.
	text_scroll.scroll_vertical = 0
	skip_button.visible = TutorialManager.can_skip()

	var choices: Array = entry["choices"]
	if not choices.is_empty():
		confirm_button.visible = false
		# Pular o tutorial no meio de uma decisão deixaria o evento sem resposta.
		skip_button.visible = false
		_build_choices(choices)

	_shown_at_msec = Time.get_ticks_msec()
	_space_grace_msec = int(entry.get("space_grace_msec", 0))
	# Sempre reatribui: um alerta alto não pode deixar a caixa alta para o próximo.
	var text_height := int(entry.get("text_height", 0))
	text_scroll.custom_minimum_size = Vector2(TEXT_WIDTH, text_height if text_height > 0 else TEXT_VISIBLE_HEIGHT)

	# 🔒 trava jogo. Uma trava por alerta EXIBIDO, não por chamada: é o que
	# mantém o par com o único unlock_gameplay() de _close_alert().
	Global.play_time = false
	Global.lock_gameplay()


func _build_choices(choices: Array) -> void:
	var panel_theme = load("res://themes/font_theme.tres")
	for choice in choices:
		var button = Button.new()
		button.theme = panel_theme
		button.z_index = 199
		button.text = str(choice.get("text", "Escolher"))
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_on_choice_pressed.bind(choice.get("callback", Callable())))
		choice_box.add_child(button)
	choice_box.visible = true


func _clear_choices() -> void:
	# remove_child antes do queue_free: queue_free só libera no fim do frame, e
	# dois alertas no mesmo frame empilhariam os botões antigos com os novos.
	for button in choice_box.get_children():
		choice_box.remove_child(button)
		button.queue_free()
	choice_box.visible = false


func _on_choice_pressed(callback: Callable) -> void:
	# Reaproveita o caminho do callback de confirmação: _close_alert() já chama
	# o callback e depois puxa o próximo da fila, na ordem certa.
	on_confirm_callback = callback
	next_step = false
	_close_alert()


# =============================
# ✅ FECHAR ALERTA
# =============================
func _on_confirm_pressed():
	if not panel.visible:
		return
	_close_alert()

func _on_skip_pressed():
	if not panel.visible:
		return
	TutorialManager.skip_tutorial()
	# Impede que _close_alert() avance o tutorial que acabou de ser pulado.
	next_step = false
	_close_alert()

# =============================
# ⌨️ APENAS ESPAÇO FUNCIONA
# =============================
func _input(event):
	if not panel.visible:
		return
	if TransitionManager.is_transitioning():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		# Consome o evento para o Espaço não vazar para o gameplay (pulo, etc.).
		get_viewport().set_input_as_handled()
		# Com escolhas na tela não há atalho: fechar pelo teclado descartaria a
		# decisão sem criar conta nem bônus.
		if choice_box.visible:
			return
		# Alertas que pediram graça (ver alert()): um aperto de espaço logo ao abrir
		# é o jogador ainda martelando o pulo, não uma confirmação. O clique no
		# botão continua valendo.
		if _space_grace_msec > 0 and Time.get_ticks_msec() - _shown_at_msec < _space_grace_msec:
			return
		_close_alert()


func _close_alert():
	if not panel.visible and not blocker.visible:
		return
	_clear_choices()
	blocker.visible = false
	panel.visible = false
	skip_button.visible = false


	# 🔓 destrava jogo. O tempo só volta a correr se nada mais estiver
	# travando o gameplay (cutscene de câmera, diálogo de compra, etc.).
	Global.unlock_gameplay()
	if not Global.gameplay_locked and not Global.time_frozen_by_scene() and not Global.is_any_tutorial_active():
		Global.play_time = true

	var callback = on_confirm_callback
	var was_step = next_step
	on_confirm_callback = Callable()
	next_step = false
	confirm_button.text = "OK"
	if callback.is_valid():
		callback.call()
	elif was_step:
		TutorialManager.continue_tutorial_after_alert()

	# Só depois do callback: ele pode enfileirar outro alerta (é assim que o
	# tutorial encadeia as mensagens) e a fila tem de sair em ordem.
	if not panel.visible:
		_show_next()
