extends Node2D

var scene: Resource
var character: Node2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	scene = load("res://scenes/players/player.tscn")
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	add_child(character)



func _on_tree_exited() -> void:
	print("main")
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y
