extends Control

var items: Dictionary = {
	"Comidas": {
		"bread": {"price": 20, "hunger_restore": 10, "thirst_restore": 0},
		"rice": {"price": 90, "hunger_restore": 70, "thirst_restore": 5},
		"hamburger": {"price": 60, "hunger_restore": 50, "thirst_restore": 0},
		"apple": {"price": 15, "hunger_restore": 15, "thirst_restore": 8},
		"banana": {"price": 12, "hunger_restore": 12, "thirst_restore": 3},
		"cheese": {"price": 35, "hunger_restore": 25, "thirst_restore": 0},
		"meat": {"price": 150, "hunger_restore": 100, "thirst_restore": 0},
		"egg": {"price": 18, "hunger_restore": 18, "thirst_restore": 0},
		"fish": {"price": 80, "hunger_restore": 65, "thirst_restore": 0}
	},
	"Bebidas": {
		"water": {"price": 5, "hunger_restore": 3, "thirst_restore": 25},
		"juice": {"price": 20, "hunger_restore": 15, "thirst_restore": 35},
		"coffee": {"price": 30, "hunger_restore": 10, "thirst_restore": 15},
		"milk": {"price": 25, "hunger_restore": 20, "thirst_restore": 15},
		"soda": {"price": 25, "hunger_restore": 12, "thirst_restore": 20},
		"tea": {"price": 15, "hunger_restore": 8, "thirst_restore": 30},
		"energy_drink": {"price": 45, "hunger_restore": 30, "thirst_restore": 20},
	},
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

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	_create_time_display()
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
	# Limpa os itens antigos do painel central
	for child in item_list.get_children():
		child.queue_free()

	var item_dict: Dictionary = items[group_name]
	for item_name in item_dict.keys():
		var price = item_dict[item_name]["price"]

		var product = Panel.new()
		var container = VBoxContainer.new()
		var product_name = Label.new()
		var button = Button.new()
	
	# Texto
		product_name.text = "%s\nR$ %d – %s" % [item_name.capitalize(), price, _restore_label(item_dict[item_name])]
		button.text = "Adicionar"
	
	# Tamanho do painel
		product.custom_minimum_size = Vector2(170, 200)
		product.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		product_name.custom_minimum_size = Vector2(130, 50)
	
	# 🔥 Container ocupa todo o painel
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.anchor_right = 1.0
		container.anchor_bottom = 1.0
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 🔥 Centralização
		container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 🔥 Alinhamento dos elementos
		product_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Conectar botão
		button.pressed.connect(_on_buy_item.bind(group_name, item_name))
	
	# Hierarquia correta
		container.add_child(product_name)
		container.add_child(button)
		product.add_child(container)
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
	remove_product.theme = load("res://themes/sell_button.tres")

	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 5)

	product_name.text = "%s - R$%d (%s)" % [item_name.capitalize(), int(price), _restore_label(item_data)]
	product_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	container.add_child(product_name)
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

	if float(Global.player["money"]) < total:
		print("Dinheiro insuficiente para finalizar a compra.")
		return

	for cart_entry in cart:
		var price = float(cart_entry["price"])
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

	cart.clear()
	for child in kart_list.get_children():
		child.queue_free()
	total = 0.0
	update_labels()
