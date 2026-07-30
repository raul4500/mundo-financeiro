extends Node2D

var scene: Resource
var character: Node2D

@onready var player_node = $Player

@onready var poles = $"Light-poles"

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	scene = load("res://scenes/players/player.tscn")
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	player_node.add_child(character)
	
	for pole in poles.get_children():
		pole.offset = Vector2(0, -17)
		pole.global_position.y += 17

func _on_tree_exited() -> void:
	Global.play_time = false
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y

func _on_tree_entered() -> void:
	Global.play_time = true
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_page_down"):
		get_tree().change_scene_to_file("res://scenes/world/places/bank.tscn")
	if Input.is_action_just_pressed("ui_page_up"):
		get_tree().change_scene_to_file("res://scenes/world/places/market.tscn")
	if Input.is_action_just_pressed("ui_end"):
		get_tree().change_scene_to_file("res://scenes/world/places/office.tscn")
