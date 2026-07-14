extends Node

var player: Dictionary
var data_model = {
		"name": "",
		"money": 0,
		"saldo": 0,
		"week": 1,
		"salary": 200,
		"school_level": 1,
		"position": {
			"x": 500,
			"y": 200
			},
		"day": 1,
		"hour": 8,
	}

var play_time: bool = false

func new_game(name: String, money: float) -> void:
	SaveManager.delete_save()
	player["name"] = name
	player["money"] = money
	player["saldo"] = 0
	player["week"] = 1
	player["school_level"] = 1
	player["salary"] = money
	player["position"]["x"] = 180
	player["position"]["y"] = 210
	player["day"] = 1
	player["hour"] = 8
	TimeManager.update_time()
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
	
func load_data() -> void:
	if not SaveManager.load_game():
		player = data_model
	else:
		player = SaveManager.load_game()
		print("game loaded")
		
func update_salary() -> void:
	player["salary"] = int(player["school_level"]*player["salary"]/1.5)
			
func get_paid() -> void:
	player["money"] += player["salary"]

func _ready() -> void:
	load_data()
	print(player)
	
func _process(delta: float) -> void:
	pass
