extends Node2D

@onready var tree_list = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for tree in tree_list.get_children():
		if tree is Sprite2D:
			tree.global_position.y += 20
			tree.offset.y -= 20
