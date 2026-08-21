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
var skip_button: Button
var blocker: ColorRect

var next_step: bool = false

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
	confirm_button.text = "OK"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.pressed.connect(_on_confirm_pressed)

	box.add_child(text_scroll)
	box.add_child(confirm_button)

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
func alert(text: String, step: bool = false):
	blocker.visible = true
	panel.visible = true

	alert_label.text = text
	# Sem isto, uma mensagem longa deixa o scroll no meio e a próxima abre
	# já rolada, escondendo o começo do texto.
	text_scroll.scroll_vertical = 0
	skip_button.visible = TutorialManager.can_skip()

	# 🔒 trava jogo
	Global.play_time = false
	Global.lock_gameplay()
	
	next_step = step


# =============================
# ✅ FECHAR ALERTA
# =============================
func _on_confirm_pressed():
	_close_alert()

func _on_skip_pressed():
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		# Consome o evento para o Espaço não vazar para o gameplay (pulo, etc.).
		get_viewport().set_input_as_handled()
		_close_alert()


func _close_alert():
	blocker.visible = false
	panel.visible = false
	skip_button.visible = false

	# 🔓 destrava jogo. O tempo só volta a correr se nada mais estiver
	# travando o gameplay (cutscene de câmera, diálogo de compra, etc.).
	Global.unlock_gameplay()
	if not Global.gameplay_locked:
		Global.play_time = true
	
	if next_step:
		TutorialManager.continue_tutorial_after_alert()
