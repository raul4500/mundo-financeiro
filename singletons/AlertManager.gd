extends Node

var panel: Panel
var alert_label: Label

func _create_alert_ui():
	panel = Panel.new()
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(420, 120)

	alert_label = Label.new()
	alert_label.text = ""
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.size = Vector2(400, 100)
	alert_label.position = Vector2(10, 10)
	alert_label.z_index = 10000

	alert_label.add_theme_font_size_override("font_size", 24)

	panel.add_child(alert_label)

	# 🔥 AQUI ESTÁ A CORREÇÃO
	get_tree().root.add_child(panel)

func alert(text: String):
	_create_alert_ui()

	panel.visible = true
	alert_label.visible = true
	alert_label.text = text

	await get_tree().create_timer(4.0).timeout

	panel.visible = false
	alert_label.visible = false
