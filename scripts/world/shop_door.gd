extends Area2D

var dentro = false
@onready var label = $buy

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and dentro == true:
		if Global.player["money"] > 0:
			Global.player["money"] -= 10


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	label.show()
	dentro = true


func _on_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	label.hide()
	dentro = false
