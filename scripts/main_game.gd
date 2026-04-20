extends Node2D

@onready var player = $raul

func save_game(position_x = player.global_position.x, position_y = player.global_position.y):
	var data = {
		"player_name": "Raul",
		"score": 1500,
		"level": 3,
		"player_position": {
			"x": position_x,
			"y": position_y
			}
	}

	var json_string = JSON.stringify(data)
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func load_game():
	if not FileAccess.file_exists("user://savegame.json"):
		print("Save não encontrado")
		save_game(0, 0)
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	return data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(player.global_position)
	var pos = load_game()["player_position"]
	player.global_position = Vector2(pos["x"], pos["y"])

var save_timer := 0.0
var save_interval := 10.0 # segundos

func _process(delta):
	save_timer += delta
	if save_timer >= save_interval:
		print("game saved!")
		save_game()
		save_timer = 0
