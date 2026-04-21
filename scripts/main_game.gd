extends Node2D

@onready var player = $raul

func _ready() -> void:
	Global.player = player
