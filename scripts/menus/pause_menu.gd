extends Control

var paused = false

func _ready():
	visible = false
	var vbox := get_node_or_null("VBoxContainer")
	if vbox != null and vbox.get_node_or_null("guia") == null:
		var guia_btn := Button.new()
		guia_btn.name = "guia"
		guia_btn.custom_minimum_size = Vector2(500, 70)
		guia_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		guia_btn.text = "Guia do Jogo"
		guia_btn.pressed.connect(_on_guia_pressed)
		vbox.add_child(guia_btn)
		vbox.move_child(guia_btn, 1)

func _on_guia_pressed() -> void:
	if paused:
		toggle_pause()
	if get_tree() != null and get_tree().current_scene != null:
		var nb = get_tree().current_scene.find_child("TutorialNotebook", true, false)
		if nb != null and nb.has_method("open_notebook"):
			nb.open_notebook()

func toggle_pause():
	if paused:
		Global.unlock_gameplay()
		if not Global.time_frozen_by_scene() and not Global.is_any_tutorial_active():
			Global.play_time = true
		paused = false
		visible = false
	elif not paused and Global.gameplay_locked:
		# Se há um bloqueador válido ativo (alerta modal, cutscene de câmera ou fade), não abre o pause
		var has_valid_blocker := false
		if CameraManager != null and CameraManager.is_cinematic:
			has_valid_blocker = true
		elif AlertManager != null and is_instance_valid(AlertManager.panel) and AlertManager.panel.visible:
			has_valid_blocker = true
		elif TransitionManager != null and TransitionManager.is_transitioning():
			has_valid_blocker = true

		if not has_valid_blocker:
			# Trava órfã detectada: recupera o estado e permite abrir o menu de pause
			Global.force_release_all_gameplay_locks()
			Global.lock_gameplay()
			Global.play_time = false
			paused = true
			visible = true
		return
	elif not paused and not Global.gameplay_locked:
		Global.lock_gameplay()
		Global.play_time = false
		paused = true
		visible = true
	return

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if CameraManager != null and CameraManager.is_cinematic:
		return
	if get_viewport() != null:
		get_viewport().set_input_as_handled()
	toggle_pause()



func _on_sair_pressed() -> void:
	visible = false
	paused = false
	Global.force_release_all_gameplay_locks()
	Global.play_time = false
	SaveManager.save_game()
	TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")

func _on_continuar_pressed() -> void:
	toggle_pause()
