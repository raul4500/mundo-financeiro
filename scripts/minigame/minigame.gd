extends Node2D

@onready var player = $"raul-minigame"
@onready var camera = $Camera2D
@onready var level_label = $Camera2D/Level
@onready var marker1 = $map/levels/Marker_1
@onready var marker2 = $map/levels/Level1/Marker_2
@onready var marker3 = $cam_marker
@onready var marker4 = $cam_marker2

var curr_level = Global.player["school_level"]

func notify_tutorial_minigame_finished() -> void:
	TutorialManager.on_minigame_finished()

func _ready() -> void:
	if curr_level == 1:
		player.global_position = marker1.global_position
		camera.global_position = marker3.global_position
	elif curr_level >= 2:
		# Níveis 3+ ainda não têm marcadores próprios: reutiliza os do nível 2
		# até que novos obstáculos/checkpoints sejam adicionados para eles.
		player.global_position = marker2.global_position
		camera.global_position = marker4.global_position

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	camera.global_position.x += 1.6666666
	level_label.text = str(int(Global.player["school_level"]))
