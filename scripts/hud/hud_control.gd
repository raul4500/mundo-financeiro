extends Control

@onready var money_label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# O HUD cobre a tela inteira e é puramente informativo. Sem isso ele
	# engole todos os cliques do mouse (alertas, menus, etc.).
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	money_label.text = "Semana %d" %Global.player["week"] + "\nR$ %s" %Global.player["money"]
