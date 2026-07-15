extends Control

# ============================================================
# ESTRUTURA DE CENA ESPERADA (ajuste os caminhos conforme sua cena):
#
# Control (este script)
# ├── Label_Money
# └── HBoxContainer
#     ├── CategoryPanel (Panel ou PanelContainer)
#     │   └── CategoryList (VBoxContainer)  -> botões de categoria
#     └── MainPanel (Panel ou PanelContainer)
#         └── ScrollContainer
#             └── ItemList (GridContainer, columns = 3)  -> botões de produtos
#
# Se sua árvore de nós tiver nomes diferentes, ajuste os caminhos
# nos @onready abaixo.
# ============================================================

var items: Dictionary = {
	"foods": {
		"bread": {"price": 5},
		"rice": {"price": 20},
		"hamburger": {"price": 30},
		"apple": {"price": 4},
		"banana": {"price": 3},
		"milk": {"price": 8},
		"cheese": {"price": 12},
		"meat": {"price": 25},
		"egg": {"price": 6},
		"fish": {"price": 22}
	},
	"drinks": {
		"water": {"price": 2},
		"juice": {"price": 6},
		"coffee": {"price": 10},
		"soda": {"price": 8},
		"tea": {"price": 5},
		"energy_drink": {"price": 15},
		"beer": {"price": 12},
		"wine": {"price": 35},
		"milkshake": {"price": 18},
		"hot_chocolate": {"price": 14}
	},
	"home": {
		"soap": {"price": 5},
		"hygienic_paper": {"price": 3},
		"mop": {"price": 10},
		"detergent": {"price": 7},
		"trash_bag": {"price": 4},
		"broom": {"price": 9},
		"bucket": {"price": 11},
		"toothpaste": {"price": 6},
		"shampoo": {"price": 13},
		"towel": {"price": 20}
	},
	"tools": {
		"hammer": {"price": 25},
		"screwdriver": {"price": 15},
		"axe": {"price": 40},
		"pickaxe": {"price": 50},
		"shovel": {"price": 22},
		"pliers": {"price": 18},
		"saw": {"price": 28},
		"wrench": {"price": 16},
		"drill": {"price": 75},
		"toolbox": {"price": 60}
	},
	"electronics": {
		"flashlight": {"price": 18},
		"radio": {"price": 45},
		"battery": {"price": 12},
		"phone": {"price": 120},
		"tv": {"price": 300},
		"laptop": {"price": 500},
		"headphones": {"price": 80},
		"keyboard": {"price": 40},
		"mouse": {"price": 25},
		"speaker": {"price": 70}
	}
}

@onready var category_list: VBoxContainer = $CategoryPanel/CategoryList
@onready var item_list: GridContainer = $MainPanel/ScrollContainer/ItemList
@onready var label_money: Label = $Label_Money

var current_category: String = ""


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	item_list.columns = 3
	update_labels()
	_build_category_buttons()

	# Abre a primeira categoria automaticamente
	if items.keys().size() > 0:
		_on_category_selected(items.keys()[0])


func _build_category_buttons() -> void:
	for group_name in items.keys():
		var button = Button.new()
		button.text = group_name.capitalize()
		button.pressed.connect(_on_category_selected.bind(group_name))
		category_list.add_child(button)


func _on_category_selected(group_name: String) -> void:
	current_category = group_name
	_populate_items(group_name)


func _populate_items(group_name: String) -> void:
	# Limpa os itens antigos do painel central
	for child in item_list.get_children():
		child.queue_free()

	var item_dict: Dictionary = items[group_name]
	for item_name in item_dict.keys():
		var price = item_dict[item_name]["price"]

		var button = Button.new()
		button.text = "%s - $%d" % [item_name.capitalize(), price]
		button.custom_minimum_size = Vector2(150, 60)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_buy_item.bind(group_name, item_name))
		item_list.add_child(button)


func update_labels() -> void:
	label_money.text = "Dinheiro: $" + str(Global.player["money"])


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")


func _on_buy_item(group_name: String, item_name: String) -> void:
	var price = items[group_name][item_name]["price"]
	if Global.player["money"] >= price:
		print("Comprou:", item_name, "por", price)
		Global.player["money"] = int(Global.player["money"] - price)
		update_labels()
	else:
		print("Saldo insuficiente")
