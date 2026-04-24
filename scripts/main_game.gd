extends Node2D

var characters = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var char_name = Global.player.get("name", "")

	if not characters.has(char_name):
		push_error("Personagem inválido")
		return

	var scene = load(characters[char_name])
	var character = scene.instantiate()
	character.global_position.x = 500
	character.global_position.y = 200
	add_child(character)
