extends Panel

# Carteira: um card por fundo em que o jogador tem cotas. O grid é da cena
# (bank.tscn, nó Holdings-grid).

const BankCard = preload("res://scripts/world/bank/bank_card.gd")

const CARD_MIN_HEIGHT := 120

@onready var portfolio_list: GridContainer = $"ScrollContainer/Holdings-grid"

func _ready() -> void:
	FIIManager.portfolio_updated.connect(_on_portfolio_updated)
	load_portfolio()

func _on_portfolio_updated() -> void:
	load_portfolio()

func load_portfolio() -> void:
	# remove_child antes do queue_free: ver fii_shop.load_funds().
	for child in portfolio_list.get_children():
		portfolio_list.remove_child(child)
		child.queue_free()

	for fund_id in FIIManager.portfolio.keys():
		var quantity := int(FIIManager.portfolio[fund_id])
		if quantity <= 0:
			continue
		# Um id que o catálogo não conhece mais (save antigo) não pode derrubar a aba.
		if not FIIManager.funds.has(fund_id):
			continue
		var fund: Dictionary = FIIManager.funds[fund_id]

		var parts := BankCard.new_card(CARD_MIN_HEIGHT)
		var box: VBoxContainer = parts["box"]
		box.add_child(BankCard.make_label(str(fund["name"]), 20))
		box.add_child(BankCard.make_label("Cotas: %d" % quantity, 16))
		box.add_child(BankCard.make_label("Valor: R$ %.2f" % (float(fund["price"]) * quantity), 16))
		portfolio_list.add_child(parts["card"])

	if portfolio_list.get_child_count() == 0:
		portfolio_list.add_child(BankCard.new_empty_card("Você ainda não possui cotas de nenhum fundo."))
