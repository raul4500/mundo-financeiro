extends "res://scripts/world/doors/enterprise_door.gd"

func _ready() -> void:
	enterprise_id = "shopping_large"
	destination_scene = "res://scenes/world/places/shopping.tscn"
	super._ready()
