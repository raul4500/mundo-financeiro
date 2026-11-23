extends Control

var items: Dictionary = {
	"Comidas": {
		"Pão": {"price": 4, "hunger_restore": 10, "thirst_restore": 0},
		#"Arroz": {"price": 25, "hunger_restore": 70, "thirst_restore": 5},
		"Hamburger": {"price": 35, "hunger_restore": 50, "thirst_restore": 0},
		"Maçã": {"price": 7, "hunger_restore": 15, "thirst_restore": 8},
		"Banana": {"price": 6, "hunger_restore": 12, "thirst_restore": 3},
		"Queijo": {"price": 20, "hunger_restore": 25, "thirst_restore": 0},
		"Carne": {"price": 70, "hunger_restore": 100, "thirst_restore": 0},
		"Ovo": {"price": 8, "hunger_restore": 18, "thirst_restore": 0},
		"Peixe": {"price": 45, "hunger_restore": 65, "thirst_restore": 0}
	},
	"Bebidas": {
		"Água": {"price": 5, "hunger_restore": 3, "thirst_restore": 25},
		"Suco": {"price": 20, "hunger_restore": 15, "thirst_restore": 35},
		"Café": {"price": 30, "hunger_restore": 10, "thirst_restore": 15},
		"Leite": {"price": 15, "hunger_restore": 20, "thirst_restore": 15},
		#"Refrigerante": {"price": 25, "hunger_restore": 12, "thirst_restore": 20},
		"Chá": {"price": 15, "hunger_restore": 8, "thirst_restore": 30},
		"Energético": {"price": 45, "hunger_restore": 30, "thirst_restore": 20},
	},
}

const ITEM_ICONS := {
	"Pão": "res://assests/sprites/market/bread.png",
	"Hamburger": "res://assests/sprites/market/hamburguer.png",
	"Maçã": "res://assests/sprites/market/apple.png",
	"Banana": "res://assests/sprites/market/banana.png",
	"Queijo": "res://assests/sprites/market/cheese.png",
	"Carne": "res://assests/sprites/market/meat.png",
	"Ovo": "res://assests/sprites/market/egg.png",
	"Peixe": "res://assests/sprites/market/fish.png",
	"Arroz": "res://assests/sprites/market/rice.png",
	"Água": "res://assests/sprites/market/water_bottle.png",
	"Suco": "res://assests/sprites/market/juice_box.png",
	"Café": "res://assests/sprites/market/coffee.png",
	"Leite": "res://assests/sprites/market/milk.png",
	"Refrigerante": "res://assests/sprites/market/soda.png",
	"Chá": "res://assests/sprites/market/tea.png",
	"Energético": "res://assests/sprites/market/energy_drink.png",
}

@onready var category_list: VBoxContainer = $HBoxContainer/CategoryPanel/CategoryList
@onready var item_list: GridContainer = $HBoxContainer/MainPanel/ScrollContainer/ItemList
@onready var kart_list: VBoxContainer = $HBoxContainer/KartContainer/KartPanel/ScrollContainer/KartList
@onready var label_money: Label = $Label_Money
@onready var label_total: Label = $HBoxContainer/KartContainer/Panel/Label

var current_category: String = ""

var total: float = 0.00
var cart: Array = []
var time_display: Label

var _tooltip_panel: PanelContainer
var _tooltip_title: Label
var _tooltip_desc: Label

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	_create_time_display()
	_create_tooltip_ui()
	item_list.columns = 3
	update_labels()
	_build_category_buttons()

	# Abre a primeira categoria automaticamente
	if items.keys().size() > 0:
		_on_category_selected(items.keys()[0])

func _create_time_display() -> void:
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	add_child(time_display)


func _build_category_buttons() -> void:
	for group_name in items.keys():
		var button = Button.new()
		button.text = group_name.capitalize()
		button.pressed.connect(_on_category_selected.bind(group_name))
		category_list.add_child(button)


func _on_category_selected(group_name: String) -> void:
	current_category = group_name
	_populate_items(group_name)


func _create_tooltip_ui() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.theme = load("res://themes/font_theme.tres")
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50
	_tooltip_panel.visible = false
	add_child(_tooltip_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_tooltip_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_tooltip_title = Label.new()
	_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_title.theme = load("res://themes/label.tres")
	_tooltip_title.add_theme_font_size_override("font_size", 16)
	_tooltip_title.add_theme_color_override("font_color", Color(0.157, 0.087, 0.0, 1.0))
	vbox.add_child(_tooltip_title)

	_tooltip_desc = Label.new()
	_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_desc.theme = load("res://themes/label.tres")
	_tooltip_desc.add_theme_font_size_override("font_size", 14)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.129, 0.117, 0.101, 1.0))
	vbox.add_child(_tooltip_desc)

func _show_tooltip(for_node: Control, item_name: String, item_data: Dictionary) -> void:
	if not is_instance_valid(_tooltip_panel):
		return
	_tooltip_title.text = item_name.capitalize()
	_tooltip_desc.text = "Recupera: %s" % _restore_label(item_data)
	_tooltip_panel.visible = true
	_tooltip_panel.reset_size()

	# Posiciona dinamicamente ao lado do card
	var card_rect := for_node.get_global_rect()
	var tooltip_size := _tooltip_panel.size
	var target_x = card_rect.position.x + card_rect.size.x + 8
	var target_y = card_rect.position.y + 10

	# Se transbordar para a direita da tela (viewport 1152), exibe à esquerda do card
	if target_x + tooltip_size.x > 1140:
		target_x = card_rect.position.x - tooltip_size.x - 8

	_tooltip_panel.global_position = Vector2(target_x, target_y)

func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_panel):
		_tooltip_panel.visible = false

# "10% fome" / "25% sede" / "20% fome, 15% sede". Omite o que for zero para o
# card nao ficar poluido com "0% sede" na carne.
func _restore_label(item_data: Dictionary) -> String:
	var parts: Array = []
	var hunger_restore = int(item_data.get("hunger_restore", 0))
	var thirst_restore = int(item_data.get("thirst_restore", 0))
	if hunger_restore > 0:
		parts.append("%d%% fome" % hunger_restore)
	if thirst_restore > 0:
		parts.append("%d%% sede" % thirst_restore)
	if parts.is_empty():
		return "sem efeito"
	return ", ".join(parts)


func _populate_items(group_name: String) -> void:
	_hide_tooltip()
	# Limpa os itens antigos do painel central
	for child in item_list.get_children():
		child.queue_free()

	var item_dict: Dictionary = items[group_name]
	for item_name in item_dict.keys():
		var item_data: Dictionary = item_dict[item_name]
		var price = item_data["price"]

		var product = Panel.new()
		product.custom_minimum_size = Vector2(160, 190)
		product.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		product.mouse_filter = Control.MOUSE_FILTER_PASS

		var margin = MarginContainer.new()
		margin.anchor_right = 1.0
		margin.anchor_bottom = 1.0
		margin.mouse_filter = Control.MOUSE_FILTER_PASS
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		product.add_child(margin)

		var container = VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_theme_constant_override("separation", 8)
		container.mouse_filter = Control.MOUSE_FILTER_PASS
		margin.add_child(container)

		# Ícone do produto (16x16 exibido com escala nítida) ou fallback de texto
		var icon_path: String = ITEM_ICONS.get(item_name, "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			var icon_rect = TextureRect.new()
			icon_rect.texture = texture
			icon_rect.custom_minimum_size = Vector2(48, 48)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			container.add_child(icon_rect)
		else:
			var fallback_label = Label.new()
			fallback_label.text = item_name.capitalize()
			fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fallback_label.custom_minimum_size = Vector2(48, 48)
			fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fallback_label.mouse_filter = Control.MOUSE_FILTER_PASS
			container.add_child(fallback_label)

		# Preço
		var price_label = Label.new()
		price_label.text = "R$ %d,00" % int(price)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 16)
		price_label.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(price_label)

		# Botão Adicionar
		var button = Button.new()
		button.text = "Adicionar"
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_on_buy_item.bind(group_name, item_name))
		container.add_child(button)

		# Conecta sinais do hover para mostrar e esconder a tooltip
		product.mouse_entered.connect(_show_tooltip.bind(product, item_name, item_data))
		product.mouse_exited.connect(_hide_tooltip)

		item_list.add_child(product)


#container.anchor_left = 0.5
#container.anchor_right = 0.5
#container.anchor_top = 0.5
#container.anchor_bottom = 0.5
#container.offset_left = -80
#container.offset_right = 80
#container.offset_top = -50
#container.offset_bottom = 50


func update_labels() -> void:
	label_money.text = "Dinheiro: $" + str(Global.player["money"])
	var discount = float(Global.player.get("market_discount", 0.0))
	if discount > 0.0:
		label_total.text = "Total: R$%.2f  |  Cupom -%d%%: R$%.2f" % [total, int(discount * 100), total * (1.0 - discount)]
	else:
		label_total.text = "Total: R$" + str(total)


func _on_exit_pressed() -> void:
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")


func _on_buy_item(group_name: String, item_name: String) -> void:
	var item_data: Dictionary = items[group_name][item_name]
	var price = float(item_data["price"])
	var hunger_restore = item_data.get("hunger_restore", 0)
	var thirst_restore = item_data.get("thirst_restore", 0)

	var container = HBoxContainer.new()
	var product_name = Label.new()
	var remove_product = Button.new()
	
	kart_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	remove_product.text = "X"
	remove_product.custom_minimum_size = Vector2(40, 0)
	remove_product.theme = load("res://themes/sell_button.tres")

	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	product_name.text = "%s: R$ %d" % [item_name.capitalize(), int(price)]
	product_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	container.add_child(product_name)
	container.add_child(spacer)
	container.add_child(remove_product)
	kart_list.add_child(container)

	var cart_entry := {
		"group_name": group_name,
		"item_name": item_name,
		"price": price,
		"hunger_restore": hunger_restore,
		"thirst_restore": thirst_restore,
		"row": container
	}
	cart.append(cart_entry)
	remove_product.pressed.connect(_on_remove_from_cart.bind(cart_entry))

	total += price
	update_labels()


func _on_remove_from_cart(cart_entry: Dictionary) -> void:
	if not cart.has(cart_entry):
		return
	cart.erase(cart_entry)
	total = max(0.0, total - float(cart_entry["price"]))
	var row = cart_entry["row"]
	if is_instance_valid(row):
		row.queue_free()
	update_labels()


func _on_clean_kart_pressed() -> void:
	cart.clear()
	total = 0.00
	for child in kart_list.get_children():
		child.queue_free()
	update_labels()


func _on_finish_pressed() -> void:
	if cart.is_empty():
		print("Carrinho vazio")
		return

	var discount = float(Global.player.get("market_discount", 0.0))
	var final_total = total * (1.0 - discount)
	if float(Global.player["money"]) < final_total:
		print("Dinheiro insuficiente para finalizar a compra.")
		return

	for cart_entry in cart:
		var price = float(cart_entry["price"]) * (1.0 - discount)
		var group_name = cart_entry["group_name"]
		var item_name = cart_entry["item_name"]
		var hunger_restore = int(cart_entry.get("hunger_restore", 0))
		var thirst_restore = int(cart_entry.get("thirst_restore", 0))
		# Bebida tem categoria propria: e' o que separa o botao BEBER do COMER
		# na casa. Antes as duas caiam em "food" e bebida era comida ruim.
		var category = "item"
		if group_name == "Comidas":
			category = "food"
		elif group_name == "Bebidas":
			category = "drink"
		Global.player["money"] = float(Global.player["money"]) - price
		Global.register_expense(item_name.capitalize(), group_name, price, int(Global.player.get("day", 1)), int(Global.player.get("week", 1)))
		Global.add_home_inventory_item(item_name.capitalize(), 1, category, hunger_restore, thirst_restore)

	# Cupom e' de uso unico: some assim que aplicado numa compra, mesmo que o
	# jogador so' tenha levado um item.
	if discount > 0.0:
		Global.player["market_discount"] = 0.0

	cart.clear()
	for child in kart_list.get_children():
		child.queue_free()
	total = 0.0
	update_labels()
