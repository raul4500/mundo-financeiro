extends "res://scripts/world/doors/enterprise_door.gd"

func _ready() -> void:
	enterprise_id = "arcade_medium"
	destination_scene = "res://scenes/world/places/arcade.tscn"
	super._ready()
