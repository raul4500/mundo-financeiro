extends Node2D

var scene: Resource
var character: Node2D


func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	scene = load("res://scenes/players/player.tscn")
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	add_child(character)

func _on_tree_exited() -> void:
	Global.play_time = false
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y

func _on_tree_entered() -> void:
	Global.play_time = true
