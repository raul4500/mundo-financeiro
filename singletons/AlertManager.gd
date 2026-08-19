extends CanvasLayer

var panel: Panel
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
	blocker.color = Color(0, 0, 0, 0.4) # fundo escuro transparente
	blocker.visible = false
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP # 🚨 ESSENCIAL
	
	add_child(blocker)

	# =============================
	# 🎴 PANEL CENTRAL
	# =============================
	panel = Panel.new()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 10

	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)

	# =============================
	# 🏷️ TEXTO
	# =============================
	alert_label = Label.new()
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
	confirm_button.z_index = 199
	confirm_button.text = "OK"
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_button.pressed.connect(_on_confirm_pressed)

	skip_button = Button.new()
	skip_button.z_index = 199
	skip_button.text = "Pular tutorial"
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.visible = false
	skip_button.pressed.connect(_on_skip_pressed)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)
	button_row.add_child(confirm_button)
	button_row.add_child(skip_button)

	box.add_child(alert_label)
	box.add_child(button_row)

	center_container.add_child(box)
	panel.add_child(center_container)

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
