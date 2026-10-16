extends Node

const BANK_SCENE = preload("res://scenes/world/places/bank.tscn")

const HISTORY_PATH := "TabContainer/Histórico/Margin/VBoxContainer/House-bills-scroll/History-list"
const EVENTS_PATH := "TabContainer/Eventos/Margin/VBoxContainer/Events-scroll/Events-list"
const BILLS_PATH := "TabContainer/Contas da casa/Margin/VBoxContainer/House-bills-scroll/House-bills-list"
const SHOP_PATH := "TabContainer/FII-shop/ScrollContainer/Fund-grid"
const PORTFOLIO_PATH := "TabContainer/Portfolio/ScrollContainer/Holdings-grid"

func _fresh() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 1000.0
	Global.player["week"] = 3
	Global.player["day"] = 1
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	FIIManager.reset()

# card > margin > box
func _box(card: Node) -> VBoxContainer:
	return card.get_child(0).get_child(0)

func _open_bank() -> Control:
	var bank: Control = BANK_SCENE.instantiate()
	add_child(bank)
	return bank

func _assert_all_cards(grid: Node, expected: int, what: String) -> void:
	assert(grid is GridContainer, "%s deve ser um GridContainer" % what)
	assert(grid.get_child_count() == expected, "%s: esperava %d card(s), há %d" % [what, expected, grid.get_child_count()])
	for child in grid.get_children():
		assert(child is PanelContainer, "%s: todo item deve ser um card (PanelContainer)" % what)

func _ready() -> void:
	print("=== Testando abas do banco em cards ===")

	# 1. Abas vazias: um card de aviso em cada, no lugar de um Label solto.
	_fresh()
	var bank := _open_bank()
	_assert_all_cards(bank.get_node(HISTORY_PATH), 1, "Histórico vazio")
	_assert_all_cards(bank.get_node(EVENTS_PATH), 1, "Eventos vazio")
	_assert_all_cards(bank.get_node(BILLS_PATH), 1, "Contas da casa vazio")
	_assert_all_cards(bank.get_node(PORTFOLIO_PATH), 1, "Carteira vazia")
	assert(_box(bank.get_node(EVENTS_PATH).get_child(0)).get_child(0).text == "Nenhuma conta ou bônus pendente.", "Texto do aviso de eventos vazio")
	# free() imediato, não queue_free(): o banco velho ficaria vivo até o fim do
	# frame, ainda ligado aos mesmos sinais do banco novo.
	remove_child(bank)
	bank.free()
	print("  ok   Abas vazias mostram um card de aviso")

	# 2. Abas com dados: um card por registro.
	_fresh()
	Global.player["expense_history"] = [
		{"item": "Pão", "category": "food", "price": 4.0, "day": 1, "week": 1},
		{"item": "Água", "category": "food", "price": 5.0, "day": 2, "week": 1}
	]
	Global.player["pending_house_bills"] = [{
		"id": "t_bill", "title": "Conta de luz", "description": "", "amount": 100.0,
		"week": 2, "due_week": 3, "limit_week": 4, "paid": false
	}]
	EventsManager.create_pending_event({"id": "t_conta", "titulo": "Carro quebrou", "descricao": ""}, {"dinheiro": -200})
	EventsManager.create_pending_event({"id": "t_bonus", "titulo": "Freelance", "descricao": ""}, {"dinheiro": 300})
	FIIManager.buy_fund("FII_AGRO", 2)
	bank = _open_bank()

	var history := bank.get_node(HISTORY_PATH)
	_assert_all_cards(history, 2, "Histórico")
	assert(_box(history.get_child(0)).get_child(0).text == "Água", "Histórico: o mais recente vem primeiro")

	var events := bank.get_node(EVENTS_PATH)
	_assert_all_cards(events, 2, "Eventos")
	var button_texts: Array = []
	for card in events.get_children():
		var box := _box(card)
		var last := box.get_child(box.get_child_count() - 1)
		assert(last is Button, "Todo card de evento termina com o botão de ação")
		button_texts.append(last.text)
	assert(button_texts.has("Pagar") and button_texts.has("Resgatar"), "Conta tem Pagar, bônus tem Resgatar")

	var bills := bank.get_node(BILLS_PATH)
	_assert_all_cards(bills, 1, "Contas da casa")
	var bill_box := _box(bills.get_child(0))
	assert(bill_box.get_child(0).text == "Conta de luz", "Card da conta: título primeiro")
	assert(bill_box.get_child(bill_box.get_child_count() - 1).text == "Pagar", "Card da conta: botão Pagar")

	_assert_all_cards(bank.get_node(SHOP_PATH), 8, "Loja de FIIs")
	var portfolio := bank.get_node(PORTFOLIO_PATH)
	_assert_all_cards(portfolio, 1, "Carteira")
	assert(_box(portfolio.get_child(0)).get_child(1).text == "Cotas: 2", "Carteira mostra a quantidade de cotas")
	print("  ok   Um card por registro em histórico, eventos, contas, loja e carteira")

	# 3. Os botões dos cards funcionam: pagar a conta tira o dinheiro e o card some.
	var money_before := float(Global.player["money"])
	var pay_button: Button = bill_box.get_child(bill_box.get_child_count() - 1)
	pay_button.pressed.emit()
	assert(is_equal_approx(float(Global.player["money"]), money_before - 100.0), "Pagar a conta da casa debitou R$ 100")
	_assert_all_cards(bank.get_node(BILLS_PATH), 1, "Contas da casa depois de pagar")
	assert(_box(bank.get_node(BILLS_PATH).get_child(0)).get_child(0).text == "Nenhuma conta da casa pendente.", "Sem contas: volta o card de aviso")
	print("  ok   Botão Pagar do card quita a conta e redesenha a aba")

	print("=== Todos os testes das abas do banco passaram ===")
	get_tree().quit(0)
