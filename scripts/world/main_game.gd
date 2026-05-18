extends Node2D

var characters = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

var scene: Resource
var character: Node2D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print(Global.player)
	var char_name = Global.player.get("name", "")
	if not characters.has(char_name):
		push_error("Personagem inválido")
		get_tree().quit()

	scene = load(characters[char_name])
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	add_child(character)



func _on_tree_exited() -> void:
	print("main")
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y
