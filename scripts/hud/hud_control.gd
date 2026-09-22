extends Control

@onready var money_label = $Label
@onready var hunger_bar: HBoxContainer = $"VBoxContainer/Hunger/Hunger-bar"
@onready var thirst_bar: HBoxContainer = $"VBoxContainer/Thirst/Thirst-bar"
@onready var stamina_bar: HBoxContainer = $"VBoxContainer/Stamina/Stamina-bar"

const empty_textures = [preload("res://assests/sprites/status-bars/empty/1.png"),preload("res://assests/sprites/status-bars/empty/2.png"),preload("res://assests/sprites/status-bars/empty/3.png")]

const stamina_textures = [preload("res://assests/sprites/status-bars/stamina/1.png"), preload("res://assests/sprites/status-bars/stamina/2.png"), preload("res://assests/sprites/status-bars/stamina/3.png")]
const hunger_textures = [preload("res://assests/sprites/status-bars/hunger/1.png"), preload("res://assests/sprites/status-bars/hunger/2.png"), preload("res://assests/sprites/status-bars/hunger/3.png")]
const thirst_textures = [preload("res://assests/sprites/status-bars/thirst/1.png"), preload("res://assests/sprites/status-bars/thirst/2.png"), preload("res://assests/sprites/status-bars/thirst/3.png")]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print(Global.player)
	_update_needs_ui()

func _update_needs_ui() -> void:
	var bars = [stamina_bar, hunger_bar, thirst_bar]
	var textures = [stamina_textures, hunger_textures, thirst_textures]
	
	var stats = ["stamina", "hunger", "thirst"]
	for i in stats.size():
		fill_bars(bars[i], int(Global.player[stats[i]]/10), textures[i])
		complete_empty_bars(bars[i], 10 - int(Global.player[stats[i]]/10))
	
func fill_bars(bar, qtd, texture):
	for node in bar.get_children():
			node.queue_free()
	if qtd <= 0:
		return
	var left = TextureRect.new()
	left.texture = texture[0]
	bar.add_child(left)
	for i in range(qtd-2):
		var center = TextureRect.new()
		center.texture = texture[1]
		bar.add_child(center)
	if qtd == 10:
		var right = TextureRect.new()
		right.texture = texture[2]
		bar.add_child(right)

func complete_empty_bars(bar: HBoxContainer, qtd) -> void:
	if qtd <= 0:
		return
	if qtd == 10:
		var empty_left = TextureRect.new()
		empty_left.texture = empty_textures[0]
		bar.add_child(empty_left)
	for i in range(qtd-1):
		var empty_center = TextureRect.new()
		empty_center.texture = empty_textures[1]
		bar.add_child(empty_center)
	var empty_right = TextureRect.new()
	empty_right.texture = empty_textures[2]
	bar.add_child(empty_right)
	
	
	
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
