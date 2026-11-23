extends Control

var paused = false

func _ready():
	visible = false

# O Guia do Jogo é irmão deste menu dentro do Player (ver player.gd).
func _notebook() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("TutorialNotebook", true, false)

func _on_guia_pressed() -> void:
	var nb = _notebook()
	if nb == null or not nb.has_method("open_notebook"):
		return
	if paused:
		toggle_pause()
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
	# Com o Guia aberto, o ESC é dele (fecha a janela). Se o menu de pausa
	# abrisse por cima, a trava órfã do toggle_pause() soltaria a trava do Guia.
	var nb = _notebook()
	if nb != null and bool(nb.get("is_open")):
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
