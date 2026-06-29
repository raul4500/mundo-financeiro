extends Control

func _ready():
	visible = false

func toggle_pause():
	var paused = get_tree().paused

	get_tree().paused = !paused
	visible = !visible

	if !paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func _on_sair_pressed() -> void:
	get_tree().paused = false
	visible = false
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _on_continuar_pressed() -> void:
	get_tree().paused = false
	visible = false
