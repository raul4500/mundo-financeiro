extends Node2D

@onready var player = $"raul-minigame"
@onready var camera = $Camera2D
@onready var level_label = $Camera2D/Level
@onready var marker1 = $map/levels/Marker_1
@onready var marker2 = $map/levels/Level1/Marker_2
@onready var marker3 = $cam_marker
@onready var marker4 = $cam_marker2

var time_display: Label
var curr_level = Global.player["school_level"]

func notify_tutorial_minigame_finished() -> void:
	TutorialManager.on_minigame_finished()

func _ready() -> void:
	Global.play_time = true
	_create_time_display()
	if curr_level == 1:
		player.global_position = marker1.global_position
		camera.global_position = marker3.global_position
	elif curr_level >= 2:
		# Níveis 3+ ainda não têm marcadores próprios: reutiliza os do nível 2
		# até que novos obstáculos/checkpoints sejam adicionados para eles.
		player.global_position = marker2.global_position
		camera.global_position = marker4.global_position

func _create_time_display() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	layer.add_child(time_display)

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	camera.global_position.x += 1.6666666
	level_label.text = str(int(Global.player["school_level"]))
