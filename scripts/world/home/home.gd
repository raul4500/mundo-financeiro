extends Control

const UI_THEME = preload("res://themes/font_theme.tres")

var money_label: Label
var hunger_bar: ProgressBar
var hunger_value_label: Label
var happiness_bar: ProgressBar
var happiness_value_label: Label
var status_label: Label
var inventory_list: VBoxContainer
var history_list: VBoxContainer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.ensure_player_state()
	_build_ui()
	_update_ui()

func _apply_theme(node: Control) -> void:
	if node == null:
		return
	node.theme = UI_THEME
	if node is Container:
		if node.has_method("add_theme_constant_override"):
			node.add_theme_constant_override("separation", 12)

func _make_panel() -> Panel:
	var panel = Panel.new()
	panel.theme = UI_THEME
	return panel

func _make_box_container(vertical: bool) -> BoxContainer:
	var box = VBoxContainer.new() if vertical else HBoxContainer.new()
	_apply_theme(box)
	box.add_theme_constant_override("separation", 12)
	return box

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.name = "Root"
	root.theme = UI_THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 24
	root.offset_right = -24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var header = _make_box_container(false)
	header.add_theme_constant_override("separation", 18)

	money_label = Label.new()
	money_label.text = "Dinheiro: R$0,00"
	money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_label.theme = UI_THEME
	money_label.custom_minimum_size = Vector2(0, 36)

	var day_label = Label.new()
	day_label.text = "Dia %s - Semana %s" % [Global.player.get("day", 1), Global.player.get("week", 1)]
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	day_label.theme = UI_THEME
	day_label.custom_minimum_size = Vector2(0, 36)

	header.add_child(money_label)
	header.add_child(day_label)
	root.add_child(header)

	var bars_panel = _make_panel()
	bars_panel.custom_minimum_size = Vector2(0, 160)
	var bars_box = _make_box_container(true)
	bars_box.offset_left = 16
	bars_box.offset_top = 16
	bars_box.offset_right = -16
	bars_box.offset_bottom = -16

	var hunger_row = _make_box_container(false)
	var hunger_label = Label.new(); hunger_label.text = "Fome"; hunger_label.theme = UI_THEME
	hunger_value_label = Label.new(); hunger_value_label.text = "100%"; hunger_value_label.theme = UI_THEME
	hunger_bar = ProgressBar.new(); _apply_theme(hunger_bar)
	hunger_bar.min_value = 0
	hunger_bar.max_value = 100
	hunger_bar.value = 100
	hunger_bar.custom_minimum_size = Vector2(0, 26)
	var hunger_box = _make_box_container(true)
	hunger_box.add_child(hunger_label)
	hunger_box.add_child(hunger_bar)
	hunger_row.add_child(hunger_box)
	hunger_row.add_child(hunger_value_label)
	bars_box.add_child(hunger_row)

	var happiness_row = _make_box_container(false)
	var happiness_label = Label.new(); happiness_label.text = "Felicidade"; happiness_label.theme = UI_THEME
	happiness_value_label = Label.new(); happiness_value_label.text = "100%"; happiness_value_label.theme = UI_THEME
	happiness_bar = ProgressBar.new(); _apply_theme(happiness_bar)
	happiness_bar.min_value = 0
	happiness_bar.max_value = 100
	happiness_bar.value = 100
	happiness_bar.custom_minimum_size = Vector2(0, 26)
	var happiness_box = _make_box_container(true)
	happiness_box.add_child(happiness_label)
	happiness_box.add_child(happiness_bar)
	happiness_row.add_child(happiness_box)
	happiness_row.add_child(happiness_value_label)
	bars_box.add_child(happiness_row)
	bars_panel.add_child(bars_box)
	root.add_child(bars_panel)

	var actions_panel = _make_panel()
	actions_panel.custom_minimum_size = Vector2(0, 180)
	var action_box = _make_box_container(true)
	var action_label = Label.new(); action_label.text = "Ações em casa"; action_label.theme = UI_THEME
	action_box.add_child(action_label)
	var action_buttons = _make_box_container(false); action_buttons.add_theme_constant_override("separation", 18)
	action_buttons.add_child(_make_button("Comer", Callable(self, "_on_eat_pressed")))
	action_buttons.add_child(_make_button("Descansar", Callable(self, "_on_rest_pressed")))
	action_buttons.add_child(_make_button("Assistir TV", Callable(self, "_on_tv_pressed")))
	action_buttons.add_child(_make_button("Sair", Callable(self, "_on_exit_pressed")))
	action_box.add_child(action_buttons)
	status_label = Label.new(); status_label.text = "Tudo em ordem."; status_label.autowrap_mode = TextServer.AUTOWRAP_WORD; status_label.theme = UI_THEME; status_label.custom_minimum_size = Vector2(0, 56)
	action_box.add_child(status_label)
	actions_panel.add_child(action_box)
	root.add_child(actions_panel)

	var content = _make_box_container(false); content.add_theme_constant_override("separation", 20)
	var inventory_panel = _make_panel(); inventory_panel.custom_minimum_size = Vector2(420, 0)
	var inventory_label = Label.new(); inventory_label.text = "Estoque da casa"; inventory_label.theme = UI_THEME
	inventory_list = VBoxContainer.new(); _apply_theme(inventory_list); inventory_list.add_theme_constant_override("separation", 10)
	var inventory_scroll = ScrollContainer.new(); _apply_theme(inventory_scroll); inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; inventory_scroll.add_child(inventory_list)
	inventory_panel.add_child(inventory_label); inventory_panel.add_child(inventory_scroll)

	var history_panel = _make_panel(); history_panel.custom_minimum_size = Vector2(420, 0)
	var history_label = Label.new(); history_label.text = "Histórico da casa"; history_label.theme = UI_THEME
	history_list = VBoxContainer.new(); _apply_theme(history_list); history_list.add_theme_constant_override("separation", 10)
	var history_scroll = ScrollContainer.new(); _apply_theme(history_scroll); history_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; history_scroll.add_child(history_list)
	history_panel.add_child(history_label); history_panel.add_child(history_scroll)

	content.add_child(inventory_panel)
	content.add_child(history_panel)
	root.add_child(content)

func _make_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.theme = UI_THEME
	button.text = text
	button.pressed.connect(callback)
	button.custom_minimum_size = Vector2(150, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _update_ui() -> void:
	Global.ensure_player_state()
	if money_label != null:
		money_label.text = "Dinheiro: R$%.2f" % float(Global.player.get("money", 0.0))
	var hunger_value = 0.0
	if hunger_bar != null:
		hunger_value = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
		hunger_bar.value = hunger_value
	if hunger_value_label != null:
		hunger_value_label.text = "%d%%" % int(round(hunger_value))
	var happiness_value = 0.0
	if happiness_bar != null:
		happiness_value = clampf(float(Global.player.get("happiness", 100.0)), 0.0, 100.0)
		happiness_bar.value = happiness_value
	if happiness_value_label != null:
		happiness_value_label.text = "%d%%" % int(round(happiness_value))
	_render_inventory()
	_render_history()

func _render_inventory() -> void:
	if inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	var items = Global.get_home_inventory_items()
	if items.is_empty():
		var empty_label = Label.new(); empty_label.text = "Você não tem itens no estoque."; empty_label.theme = UI_THEME; inventory_list.add_child(empty_label)
		return
	for item in items:
		var row = HBoxContainer.new(); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.theme = UI_THEME
		var label = Label.new(); label.text = "%s x%s" % [item.get("name", "Item"), str(item.get("quantity", 0))]; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; label.theme = UI_THEME
		var meta = Label.new(); meta.text = "Energia %.0f / Felicidade %.0f" % [float(item.get("energy", 0.0)), float(item.get("happiness", 0.0))]; meta.theme = UI_THEME
		row.add_child(label)
		row.add_child(meta)
		inventory_list.add_child(row)

func _render_history() -> void:
	if history_list == null:
		return
	for child in history_list.get_children():
		child.queue_free()
	var entries = Global.player.get("home_actions_log", [])
	if entries.is_empty():
		var empty_label = Label.new(); empty_label.text = "Nenhuma ação registrada."; empty_label.theme = UI_THEME; history_list.add_child(empty_label)
		return
	for entry in entries.slice(-10, entries.size()):
		var label = Label.new();
		label.theme = UI_THEME
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.text = "%s - Dia %s / Semana %s" % [str(entry.get("type", "ação")).capitalize(), str(entry.get("day", 1)), str(entry.get("week", 1))]
		history_list.add_child(label)

func _on_eat_pressed() -> void:
	var result = Global.consume_food()
	status_label.text = result.get("message", "Você comeu.")
	_update_ui()

func _on_rest_pressed() -> void:
	var result = Global.apply_home_action("rest", -12.0, 18.0, 1.0)
	status_label.text = result.get("message", "Você descansou.")
	_update_ui()

func _on_tv_pressed() -> void:
	var result = Global.apply_home_action("watch_tv", -6.0, 14.0, 1.0)
	status_label.text = result.get("message", "Você assistiu TV.")
	_update_ui()

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
