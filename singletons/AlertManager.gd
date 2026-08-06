extends Node

var overlay: ColorRect
var alert_label: Label
var confirm_button: Button

func _ready() -> void:
	TutorialManager.show_message.connect(alert)
	_create_alert_ui()
	
	
func _create_alert_ui():
		# =============================
	# 🌫️ FUNDO ESCURO / MODAL (FULLSCREEN)
	# =============================
	# Usamos um ColorRect para ocupar toda a tela com uma cor semitransparente
	overlay = ColorRect.new()
	overlay.visible = false
	overlay.z_index = 4090
	
	# Define a cor preta com 60% de opacidade (R, G, B, A)
	overlay.color = Color(0, 0, 0, 0.6)
	
	# Faz o fundo ocupar 100% da tela dinamicamente
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	
	# =============================
	# 🎯 CENTER CONTAINER (Centraliza o Modal)
	# =============================
	# O CenterContainer posiciona qualquer filho exatamente no meio do fundo
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	
	# =============================
	# 📜 PAINEL (MODAL)
	# =============================
	var panel = Panel.new()
	# Usamos custom_minimum_size para o CenterContainer respeitar as dimensões
	panel.custom_minimum_size = Vector2(450, 180)
	
	# =============================
	# 🧱 CONTAINER CONTEÚDO
	# =============================
	var container = VBoxContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	# =============================
	# 🏷️ LABEL
	# =============================
	alert_label = Label.new()
	alert_label.text = ""
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	alert_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alert_label.add_theme_font_size_override("font_size", 20)
	
	# =============================
	# 🔘 BOTÃO
	# =============================
	confirm_button = Button.new()
	confirm_button.text = "OK"
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# =============================
	# 📦 HIERARQUIA
	# =============================
	container.add_child(alert_label)
	container.add_child(confirm_button)
	
	panel.add_child(container)
	center_container.add_child(panel)
	overlay.add_child(center_container)
	
	# Adicionamos a overlay inteira no root
	get_tree().root.add_child.call_deferred(overlay)

# =============================
# 🚨 MOSTRAR ALERTA
# =============================
func alert(text: String):
	overlay.visible = true
	alert_label.text = text

	# 🔒 trava o jogo
	Global.play_time = false
	Global.gameplay_locked = true


# =============================
# ✅ FECHAR ALERTA
# =============================
func _on_confirm_pressed():
	overlay.visible = false

	# 🔓 destrava o jogo
	Global.play_time = true
	Global.gameplay_locked = false
