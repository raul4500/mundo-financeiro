extends Control

@onready var money_label = $Label

var needs_panel: PanelContainer
var hunger_bar: ProgressBar
var happiness_bar: ProgressBar
var hunger_value_label: Label
var happiness_value_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# O HUD cobre a tela inteira e é puramente informativo. Sem isso ele
	# engole todos os cliques do mouse (alertas, menus, etc.).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_needs_panel()
	_update_needs_ui()

func _build_needs_panel() -> void:
	needs_panel = PanelContainer.new()
	needs_panel.position = Vector2(20, 16)
	needs_panel.size = Vector2(250, 126)
	needs_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(needs_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	needs_panel.add_child(margin)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title = Label.new()
	title.text = "Status do jogador"
	box.add_child(title)

	var hunger_row = _create_need_row("Fome", box)
	hunger_bar = hunger_row[0]
	hunger_value_label = hunger_row[1]

	var happiness_row = _create_need_row("Felicidade", box)
	happiness_bar = happiness_row[0]
	happiness_value_label = happiness_row[1]

func _create_need_row(title_text: String, parent: VBoxContainer) -> Array:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	parent.add_child(row)

	var header = HBoxContainer.new()
	row.add_child(header)

	var title = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var value_label = Label.new()
	header.add_child(value_label)

	var bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	return [bar, value_label]

func _update_needs_ui() -> void:
	if hunger_bar == null or happiness_bar == null:
		return
	var hunger = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
	var happiness = clampf(float(Global.player.get("happiness", 100.0)), 0.0, 100.0)
	hunger_bar.value = hunger
	happiness_bar.value = happiness
	hunger_value_label.text = "%d%%" % int(round(hunger))
	happiness_value_label.text = "%d%%" % int(round(happiness))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	money_label.text = "Semana %d" %Global.player["week"] + "\nR$ %s" %Global.player["money"]
	_update_needs_ui()
