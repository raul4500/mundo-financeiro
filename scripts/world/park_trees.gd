extends Node2D

@onready var tree_list = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for tree in tree_list.get_children():
		tree.global_position.y += 20
		tree.offset.y -= 20
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
