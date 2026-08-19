extends Control

var money_label: Label
var hunger_bar: ProgressBar
var happiness_bar: ProgressBar
var status_label: Label
var inventory_list: VBoxContainer
var history_list: VBoxContainer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.ensure_player_state()
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	var root = VBoxContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 20
	root.offset_right = -20
	root.offset_bottom = -20
	add_child(root)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)

	money_label = Label.new()
	money_label.text = "Dinheiro: R$0,00"
	money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var day_label = Label.new()
	day_label.text = "Dia %s - Semana %s" % [Global.player.get("day", 1), Global.player.get("week", 1)]
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	header.add_child(money_label)
	header.add_child(day_label)
	root.add_child(header)

	var bars_panel = Panel.new()
	bars_panel.custom_minimum_size = Vector2(0, 130)
	var bars_box = VBoxContainer.new()
	bars_box.add_theme_constant_override("separation", 10)
	bars_box.offset_left = 10
	bars_box.offset_top = 10
	bars_box.offset_right = -10
	bars_box.offset_bottom = -10

	var hunger_row = HBoxContainer.new()
	var hunger_label = Label.new()
	var hunger_value = Label.new()
	hunger_label.text = "Fome"
	hunger_bar = ProgressBar.new()
	hunger_bar.min_value = 0
	hunger_bar.max_value = 100
	hunger_bar.value = 100
	var hunger_box = VBoxContainer.new()
	hunger_box.add_child(hunger_label)
	hunger_box.add_child(hunger_bar)
	hunger_row.add_child(hunger_box)
	hunger_row.add_child(hunger_value)
	bars_box.add_child(hunger_row)

	var happiness_row = HBoxContainer.new()
	var happiness_label = Label.new()
	var happiness_value = Label.new()
	happiness_label.text = "Felicidade"
	happiness_bar = ProgressBar.new()
	happiness_bar.min_value = 0
	happiness_bar.max_value = 100
	happiness_bar.value = 100
	var happiness_box = VBoxContainer.new()
	happiness_box.add_child(happiness_label)
	happiness_box.add_child(happiness_bar)
	happiness_row.add_child(happiness_box)
	happiness_row.add_child(happiness_value)
	bars_box.add_child(happiness_row)
	bars_panel.add_child(bars_box)
	root.add_child(bars_panel)

	var actions_panel = Panel.new()
	actions_panel.custom_minimum_size = Vector2(0, 150)
	var action_box = VBoxContainer.new()
	var action_label = Label.new(); action_label.text = "Ações em casa"
	action_box.add_child(action_label)
	var action_buttons = HBoxContainer.new(); action_buttons.add_theme_constant_override("separation", 20)
	action_buttons.add_child(_make_button("Comer", Callable(self, "_on_eat_pressed")))
	action_buttons.add_child(_make_button("Descansar", Callable(self, "_on_rest_pressed")))
	action_buttons.add_child(_make_button("Assistir TV", Callable(self, "_on_tv_pressed")))
	action_buttons.add_child(_make_button("Sair", Callable(self, "_on_exit_pressed")))
	action_box.add_child(action_buttons)
	status_label = Label.new(); status_label.text = "Tudo em ordem."; status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	action_box.add_child(status_label)
	actions_panel.add_child(action_box)
	root.add_child(actions_panel)

	var content = HBoxContainer.new(); content.add_theme_constant_override("separation", 20)
	var inventory_panel = Panel.new(); inventory_panel.custom_minimum_size = Vector2(350, 0)
	var inventory_label = Label.new(); inventory_label.text = "Estoque da casa"
	inventory_list = VBoxContainer.new(); inventory_list.add_theme_constant_override("separation", 8)
	var inventory_scroll = ScrollContainer.new(); inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; inventory_scroll.add_child(inventory_list)
	inventory_panel.add_child(inventory_label); inventory_panel.add_child(inventory_scroll)

	var history_panel = Panel.new(); history_panel.custom_minimum_size = Vector2(350, 0)
	var history_label = Label.new(); history_label.text = "Histórico da casa"
	history_list = VBoxContainer.new(); history_list.add_theme_constant_override("separation", 8)
	var history_scroll = ScrollContainer.new(); history_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; history_scroll.add_child(history_list)
	history_panel.add_child(history_label); history_panel.add_child(history_scroll)

	content.add_child(inventory_panel)
	content.add_child(history_panel)
	root.add_child(content)

func _make_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	button.custom_minimum_size = Vector2(140, 40)
	return button

func _update_ui() -> void:
	Global.ensure_player_state()
	if money_label != null:
		money_label.text = "Dinheiro: R$%.2f" % float(Global.player.get("money", 0.0))
	if hunger_bar != null:
		hunger_bar.value = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
	if happiness_bar != null:
		happiness_bar.value = clampf(float(Global.player.get("happiness", 100.0)), 0.0, 100.0)
	_render_inventory()
	_render_history()

func _render_inventory() -> void:
	if inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	var items = Global.get_home_inventory_items()
	if items.is_empty():
		var empty_label = Label.new(); empty_label.text = "Você não tem itens no estoque."; inventory_list.add_child(empty_label)
		return
	for item in items:
		var row = HBoxContainer.new(); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label = Label.new(); label.text = "%s x%s" % [item.get("name", "Item"), str(item.get("quantity", 0))]; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var meta = Label.new(); meta.text = "Energia %.0f / Felicidade %.0f" % [float(item.get("energy", 0.0)), float(item.get("happiness", 0.0))]
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
		var empty_label = Label.new(); empty_label.text = "Nenhuma ação registrada."; history_list.add_child(empty_label)
		return
	for entry in entries.slice(-10, entries.size()):
		var label = Label.new();
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
