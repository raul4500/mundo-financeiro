extends Control

var paused = false

func _ready():
	visible = false

func toggle_pause():
	if paused:
		Global.unlock_gameplay()
		Global.play_time = true
		paused = false
		visible = false
	elif not paused and Global.gameplay_locked:
		return
	elif not paused and not Global.gameplay_locked:
		Global.lock_gameplay()
		Global.play_time = false
		paused = true
		visible = true
	return

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func _on_sair_pressed() -> void:
	visible = false
	Global.play_time = false
	SaveManager.save_game()
	TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")

func _on_continuar_pressed() -> void:
	toggle_pause()
