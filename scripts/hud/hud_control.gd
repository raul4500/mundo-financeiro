extends Control

@onready var money_label = $Label
@onready var hunger_bar: ProgressBar = $"Hunger/VBoxContainer/Hunger-bar"
@onready var thirst_bar: ProgressBar = $"Thirst/VBoxContainer/Thirst-bar"
@onready var stamina_bar: ProgressBar = $Stamina/VBoxContainer/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# O HUD cobre a tela inteira e é puramente informativo. Sem isso ele
	# engole todos os cliques do mouse (alertas, menus, etc.).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_needs_ui()

func _update_needs_ui() -> void:
	hunger_bar.value = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
	thirst_bar.value = clampf(float(Global.player.get("thirst", 100.0)), 0.0, 100.0)
	stamina_bar.value = clampf(float(Global.player.get("stamina", 100.0)), 0.0, 100.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	money_label.text = "R$ %.2f" % Global.player["money"]
	_update_needs_ui()
