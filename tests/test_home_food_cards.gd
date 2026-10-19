extends Node

const HOME_SCENE = preload("res://scenes/world/places/home.tscn")

const TABS_PATH := "HBoxContainer/VBoxContainer/Food-tabs"
const FOOD_GRID := "HBoxContainer/VBoxContainer/Food-tabs/Comidas/ScrollContainer/Food-grid"
const DRINK_GRID := "HBoxContainer/VBoxContainer/Food-tabs/Bebidas/ScrollContainer/Drink-grid"

func _fresh() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 100.0
	Global.player["hunger"] = 50.0
	Global.player["thirst"] = 50.0
	Global.player["stamina"] = 100.0
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	Global.player["tutorial_home_shown"] = true
	TimeManager.current_day = 1
	TimeManager.current_hour = 8
	TimeManager.current_minute = 0
	TimeManager.day_end_pending = false
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	Global.add_home_inventory_item("Pão", 3, "food", 10, 0)
	Global.add_home_inventory_item("Maçã", 1, "food", 15, 8)
	Global.add_home_inventory_item("Água", 2, "drink", 3, 25)

# card > margin > box
func _box(card: Node) -> VBoxContainer:
	return card.get_child(0).get_child(0)

func _label_texts(card: Node) -> Array:
	var texts: Array = []
	for child in _box(card).get_children():
		if child is Label:
			texts.append(child.text)
	return texts

func _button(card: Node) -> Button:
	var box := _box(card)
	return box.get_child(box.get_child_count() - 1)

func _ready() -> void:
	print("=== Testando abas Comidas/Bebidas da casa ===")

	# 1. Consumo direto de um item escolhido.
	_fresh()
	assert(not Global.consume_specific_item("nao-existe")["success"], "Item que não existe falha sem consumir nada")
	var drink: Dictionary = Global.consume_specific_item("água")
	assert(drink["success"], "Beber a água escolhida funciona")
	assert(str(drink["message"]) == "Você bebeu Água.", "Item de bebida usa a mensagem de beber (veio '%s')" % drink["message"])
	assert(int(Global.player["home_inventory"]["água"]["quantity"]) == 1, "Gastou 1 das 2 águas")
	assert(float(Global.player["thirst"]) > 70.0, "A sede subiu com os 25% da água")
	var bread_before := int(Global.player["home_inventory"]["pão"]["quantity"])
	var eat: Dictionary = Global.consume_specific_item("pão")
	assert(eat["success"] and str(eat["message"]) == "Você comeu Pão.", "Item de comida usa a mensagem de comer")
	assert(int(Global.player["home_inventory"]["pão"]["quantity"]) == bread_before - 1, "Gastou 1 pão")
	# Escolher o pão NÃO pode gastar a maçã, que seria o "melhor" item (15 > 10).
	assert(int(Global.player["home_inventory"]["maçã"]["quantity"]) == 1, "Comer o pão não toca na maçã")
	Global.player["hunger"] = 110.0
	var full: Dictionary = Global.consume_specific_item("maçã")
	assert(not full["success"] and str(full["message"]) == "Você não está com fome.", "Fome cheia bloqueia comer")
	assert(int(Global.player["home_inventory"]["maçã"]["quantity"]) == 1, "Bloqueado: a maçã continua no estoque")
	print("  ok   consume_specific_item gasta exatamente o item escolhido")

	# 2. Casa: sem botões COMER/BEBER; duas abas com os itens em cards.
	_fresh()
	var home: Control = HOME_SCENE.instantiate()
	add_child(home)

	var tabs: TabContainer = home.get_node(TABS_PATH)
	assert(tabs.get_tab_count() == 2, "Duas abas")
	assert(tabs.get_tab_title(0) == "Comidas" and tabs.get_tab_title(1) == "Bebidas", "Abas Comidas e Bebidas")
	for button in home.actions_box.get_children():
		if button is Button:
			assert(button.text != "COMER" and button.text != "BEBER", "Os botões COMER e BEBER saíram da lista de ações")

	var food: Node = home.get_node(FOOD_GRID)
	var drinks: Node = home.get_node(DRINK_GRID)
	assert(food is GridContainer and drinks is GridContainer, "Cada aba tem um grid")
	assert(food.get_child_count() == 2, "Duas comidas no estoque, dois cards (há %d)" % food.get_child_count())
	assert(drinks.get_child_count() == 1, "Uma bebida no estoque, um card")
	for card in food.get_children():
		assert(card is PanelContainer, "Todo item do grid é um card")

	var texts := _label_texts(food.get_child(0))
	assert(texts[0] == "Maçã" or texts[0] == "Pão", "O card mostra o nome do item")
	var apple_card: Node = null
	var bread_card: Node = null
	for card in food.get_children():
		if _label_texts(card)[0] == "Maçã":
			apple_card = card
		elif _label_texts(card)[0] == "Pão":
			bread_card = card
	assert(_label_texts(bread_card).has("Fome +10%"), "Pão: repõe 10% de fome")
	assert(_label_texts(apple_card).has("Fome +15% / Sede +8%"), "Maçã: mostra fome e sede")
	assert(_label_texts(bread_card).has("Estoque: 3"), "O card mostra a quantidade em estoque")
	assert(_button(bread_card).text == "COMER", "Botão de comida é COMER")
	var water_card: Node = drinks.get_child(0)
	assert(_label_texts(water_card).has("Fome +3% / Sede +25%"), "Água: sede 25% e fome 3%")
	assert(_button(water_card).text == "BEBER", "Botão de bebida é BEBER")
	# O primeiro filho é o ícone (o mercado tem sprite para o Pão).
	assert(_box(bread_card).get_child(0) is TextureRect, "O card tem o ícone do item")
	print("  ok   Duas abas, cards com ícone, nome, estoque, % de fome/sede e botão")

	# 3. Clicar no botão do card consome aquele item e redesenha o grid.
	var hunger_before := float(Global.player["hunger"])
	_button(bread_card).pressed.emit()
	assert(float(Global.player["hunger"]) > hunger_before + 8.0, "Comer o pão subiu a fome")
	assert(int(Global.player["home_inventory"]["pão"]["quantity"]) == 2, "Estoque do pão caiu para 2")
	assert(home.status_label.text == "Você comeu Pão.", "A mensagem de status mostra o que foi comido")
	var new_bread_card: Node = null
	for card in home.get_node(FOOD_GRID).get_children():
		if _label_texts(card)[0] == "Pão":
			new_bread_card = card
	assert(_label_texts(new_bread_card).has("Estoque: 2"), "O card foi redesenhado com o novo estoque")

	# Acabando o estoque o card some e a aba mostra o aviso.
	_button(home.get_node(DRINK_GRID).get_child(0)).pressed.emit()
	_button(home.get_node(DRINK_GRID).get_child(0)).pressed.emit()
	var empty_drinks := home.get_node(DRINK_GRID)
	assert(empty_drinks.get_child_count() == 1, "Aba de bebidas vazia: só o card de aviso")
	assert(_label_texts(empty_drinks.get_child(0))[0] == "Você não tem bebidas no estoque.", "Aviso de bebidas vazias")
	print("  ok   Botão do card consome o item, redesenha e mostra aviso quando acaba")

	print("=== Todos os testes das abas da casa passaram ===")
	get_tree().quit(0)
