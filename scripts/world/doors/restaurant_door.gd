extends "res://scripts/world/doors/enterprise_door.gd"

func _ready() -> void:
	enterprise_id = "restaurant_small"
	destination_scene = "res://scenes/world/places/restaurant.tscn"
	super._ready()
