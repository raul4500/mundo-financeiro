extends Control

func _ready():
	visible = false

func toggle_pause():
	var paused = get_tree().paused

	get_tree().paused = !paused
	visible = !visible

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func _on_sair_pressed() -> void:
	get_tree().paused = false
	visible = false
	SaveManager.save_game()
	TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")


func _on_continuar_pressed() -> void:
	get_tree().paused = false
	visible = false
