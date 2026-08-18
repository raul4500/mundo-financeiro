extends CanvasLayer

var panel: Panel
var alert_label: Label
var confirm_button: Button
var blocker: ColorRect

var next_step: bool = false

func _ready():
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
	confirm_button = Button.new()
	confirm_button.z_index = 199
	confirm_button.text = "OK"
	confirm_button.focus_mode = Control.FOCUS_ALL
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_button.pressed.connect(_on_confirm_pressed)

	box.add_child(alert_label)
	box.add_child(confirm_button)

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
	confirm_button.grab_focus()

	# 🔒 trava jogo
	Global.play_time = false
	Global.gameplay_locked = true
	
	next_step = step


# =============================
# ✅ FECHAR ALERTA
# =============================
func _on_confirm_pressed():
	_close_alert()

# =============================
# ⌨️ APENAS ESPAÇO FUNCIONA
# =============================
func _unhandled_input(event):
	if not panel.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_close_alert()


func _close_alert():
	blocker.visible = false
	panel.visible = false

	# 🔓 destrava jogo
	Global.play_time = true
	Global.gameplay_locked = false
	
	if next_step:
		TutorialManager.continue_tutorial_after_alert()
