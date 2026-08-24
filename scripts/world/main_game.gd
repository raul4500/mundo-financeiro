extends Node2D

var scene: Resource
var character: Node2D

@onready var player_node = $Player
@onready var poles = $"Light-poles"

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	TutorialManager.focus.connect(_focus)
	scene = load("res://scenes/players/player.tscn")
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	player_node.add_child(character)
	CameraManager.register_player(character)
	
	for pole in poles.get_children():
		pole.offset = Vector2(0, -17)
		pole.global_position.y += 17
	
	match Global.player["tutorial_step"]:
		1: 
			TutorialManager.start_tutorial()
		2:
			pass

func _on_tree_exited() -> void:
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y

func _on_tree_entered() -> void:
	Global.play_time = true
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_page_down"):
		get_tree().change_scene_to_file("res://scenes/world/places/restaurant.tscn")
	if Input.is_action_just_pressed("ui_page_up"):
		get_tree().change_scene_to_file("res://scenes/world/places/market.tscn")
	if Input.is_action_just_pressed("ui_end"):
		Global.player["money"] += 10000
		
func _focus(point: String) -> void:
	var target_node = get_node("Camera-focusPoints/" + point)
	await CameraManager.focus(target_node)
