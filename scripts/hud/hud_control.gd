extends Control

@onready var money_label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print(Global.player)

func _process(delta: float) -> void:
	visible = not Global.player_hud_hidden
	if not visible:
		return
	money_label.text = "R$ %.2f" % Global.player["money"]
