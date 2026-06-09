extends Control



@onready var label_money = $Label_Money

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_labels()
			
func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
