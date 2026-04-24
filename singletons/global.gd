extends Node

var player: Dictionary

var data_model = {
		"name": "",
		"money": 0,
		"week": 1,
		"school_level": 0,
		"position": {
			"x": 500,
			"y": 200
			}
	}
	
func new_game(name: String, money: float) -> void:
	player["name"] = name
	player["money"] = money
	player["position"]["x"] = 500
	player["position"]["y"] = 200
	
func load_data() -> void:
	if not SaveManager.load_game():
		player = data_model
	else:
		player = SaveManager.load_game()

func _ready() -> void:
	load_data()
	print("global loaded")
	print(player)
	
func _process(delta: float) -> void:
	pass
