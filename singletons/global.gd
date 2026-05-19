extends Node

var player: Dictionary
var data_model = {
		"name": "",
		"money": 0,
		"saldo": 0,
		"week": 1,
		"school_level": 0,
		"position": {
			"x": 500,
			"y": 200
			},
		"day": 1,
		"hour": 8,
		"minute": 0
	}

var play_time: bool = false

func new_game(name: String, money: float) -> void:
	player["name"] = name
	player["money"] = money
	player["saldo"] = 0
	player["school_level"] = 1
	player["position"]["x"] = 180
	player["position"]["y"] = 210
	player["day"] = 1
	player["hour"] = 8
	player["minute"] = 0
	TimeManager.update_time()
	
func load_data() -> void:
	if not SaveManager.load_game():
		player = data_model
	else:
		player = SaveManager.load_game()
		print("game loaded")

func _ready() -> void:
	load_data()
	print(player)
	
func _process(delta: float) -> void:
	pass
