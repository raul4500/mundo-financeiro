extends Control

@onready var money_label = $Label
@onready var hunger_bar: HBoxContainer = $"VBoxContainer/Hunger/Hunger-bar"
@onready var thirst_bar: HBoxContainer = $"VBoxContainer/Thirst/Thirst-bar"
@onready var stamina_bar: HBoxContainer = $"VBoxContainer/Stamina/Stamina-bar"

var empty_left = TextureRect.new()
var empty_center = TextureRect.new()
var empty_right = TextureRect.new()

var stamina_left = TextureRect.new()
var stamina_center = TextureRect.new()
var stamina_right = TextureRect.new()

var hunger_left = TextureRect.new()
var hunger_center = TextureRect.new()
var hunger_right = TextureRect.new()

var thirst_left = TextureRect.new()
var thirst_center = TextureRect.new()
var thirst_right = TextureRect.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_needs_ui()

func _update_needs_ui() -> void:
	
	empty_left.texture = load("res://assests/sprites/status-bars/empty/1.png")
	empty_center.texture = load("res://assests/sprites/status-bars/empty/2.png")
	empty_right.texture = load("res://assests/sprites/status-bars/empty/3.png")
	hunger_bar.add_child(empty_left)
	for i in range(8):
		hunger_bar.add_child(empty_center)
	hunger_bar.add_child(empty_right)
		
	
		
	
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
