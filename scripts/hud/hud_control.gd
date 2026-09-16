extends Control

@onready var money_label = $Label
@onready var hunger_bar: HBoxContainer = $"VBoxContainer/Hunger/Hunger-bar"
@onready var thirst_bar: HBoxContainer = $"VBoxContainer/Thirst/Thirst-bar"
@onready var stamina_bar: HBoxContainer = $"VBoxContainer/Stamina/Stamina-bar"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# O HUD cobre a tela inteira e é puramente informativo. Sem isso ele
	# engole todos os cliques do mouse (alertas, menus, etc.).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_needs_ui()

func _update_needs_ui() -> void:
	var h_value = int(Global.player.get("hunger"))
	for i in range(int(h_value/10)):
		hunger_bar.get_child(i).visible = true
		
	var t_value = int(Global.player.get("thirst"))
	for i in range(int(t_value/10)):
		thirst_bar.get_child(i).visible = true
		
	var s_value = int(Global.player.get("stamina"))
	for i in range(int(s_value/10)):
		stamina_bar.get_child(i).visible = true
		
	
	#hunger_bar.value = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
	#thirst_bar.value = clampf(float(Global.player.get("thirst", 100.0)), 0.0, 100.0)
	#stamina_bar.value = clampf(float(Global.player.get("stamina", 100.0)), 0.0, 100.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	visible = not Global.player_hud_hidden
	if not visible:
		return
	money_label.text = "R$ %.2f" % Global.player["money"]
	_update_needs_ui()
