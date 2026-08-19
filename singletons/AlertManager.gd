extends CanvasLayer

var panel: Control      # raiz em tela cheia (transparente)
var dialog: Panel       # caixa central com o texto e o botão
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
	blocker.color = Color(0, 0, 0, 0.1) # fundo escuro transparente (10%)
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

	dialog = Panel.new()
	dialog.theme = panel_theme
	# Largura fixa; a altura acompanha o tamanho do texto.
	dialog.custom_minimum_size = Vector2(560, 160)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 0.0
	margin.offset_top = 0.0
	margin.offset_right = 0.0
	margin.offset_bottom = 0.0
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)

	# =============================
	# 🏷️ TEXTO
	# =============================
	alert_label = Label.new()
	alert_label.theme = load("res://themes/label.tres")
	# Largura de quebra fixa (560 do painel - 24 de margem de cada lado),
	# assim a altura do texto é calculada corretamente e nada estoura o painel.
	alert_label.custom_minimum_size = Vector2(512, 0)
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	box.add_child(alert_label)
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

	# 🔓 destrava jogo
	Global.play_time = true
	Global.unlock_gameplay()
	
	if next_step:
		TutorialManager.continue_tutorial_after_alert()
