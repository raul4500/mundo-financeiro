extends Control

var items: Dictionary = {
	"foods": [{
		"bread": {
			"price": 5
		},
		"rice": {
			"price": 20
		},
		"hamburger": {
			"price": 30
		},
		"apple": {
			"price": 4
		},
		"banana": {
			"price": 3
		},
		"milk": {
			"price": 8
		},
		"cheese": {
			"price": 12
		},
		"meat": {
			"price": 25
		},
		"egg": {
			"price": 6
		},
		"fish": {
			"price": 22
		}
	}],

	"drinks": [{
		"water": {
			"price": 2
		},
		"juice": {
			"price": 6
		},
		"coffee": {
			"price": 10
		},
		"soda": {
			"price": 8
		},
		"tea": {
			"price": 5
		},
		"energy_drink": {
			"price": 15
		},
		"beer": {
			"price": 12
		},
		"wine": {
			"price": 35
		},
		"milkshake": {
			"price": 18
		},
		"hot_chocolate": {
			"price": 14
		}
	}],

	"home": [{
		"soap": {
			"price": 5
		},
		"hygienic_paper": {
			"price": 3
		},
		"mop": {
			"price": 10
		},
		"detergent": {
			"price": 7
		},
		"trash_bag": {
			"price": 4
		},
		"broom": {
			"price": 9
		},
		"bucket": {
			"price": 11
		},
		"toothpaste": {
			"price": 6
		},
		"shampoo": {
			"price": 13
		},
		"towel": {
			"price": 20
		}
	}],

	"tools": [{
		"hammer": {
			"price": 25
		},
		"screwdriver": {
			"price": 15
		},
		"axe": {
			"price": 40
		},
		"pickaxe": {
			"price": 50
		},
		"shovel": {
			"price": 22
		},
		"pliers": {
			"price": 18
		},
		"saw": {
			"price": 28
		},
		"wrench": {
			"price": 16
		},
		"drill": {
			"price": 75
		},
		"toolbox": {
			"price": 60
		}
	}],

	"electronics": [{
		"flashlight": {
			"price": 18
		},
		"radio": {
			"price": 45
		},
		"battery": {
			"price": 12
		},
		"phone": {
			"price": 120
		},
		"tv": {
			"price": 300
		},
		"laptop": {
			"price": 500
		},
		"headphones": {
			"price": 80
		},
		"keyboard": {
			"price": 40
		},
		"mouse": {
			"price": 25
		},
		"speaker": {
			"price": 70
		}
	}]
}

@onready var tab_container = $TabContainer 
@onready var label_money = $Label_Money

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_labels()
	for group_name in items.keys():
		var vbox = VBoxContainer.new()
		vbox.name = group_name.capitalize() + "VBox"
		
		tab_container.add_child(vbox)
		
		var tab_index = tab_container.get_tab_count() - 1  # último índice
		tab_container.set_tab_title(tab_index, group_name.capitalize())

		var item_dict = items[group_name][0]		
		
		for item_name in item_dict.keys():
			var button = Button.new()
			var price = item_dict[item_name]["price"]
			button.text = "%s - $%d" % [item_name.capitalize(), price]
			button.pressed.connect(
				_on_buy_item.bind(group_name, item_name)
			)
			vbox.add_child(button)
			
func update_labels():
	label_money.text = "Dinheiro: $" + str(Global.player["money"])

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
	
func _on_buy_item(group_name: String, item_name: String):
	var price = items[group_name][0][item_name]["price"]
	if Global.player["money"] > price:
		print("Comprou:", item_name, "por", price)
		Global.player["money"] = int(Global.player["money"]-price)
		update_labels()
	else:
		print("Saldo insuficiente")
