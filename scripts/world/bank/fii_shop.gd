extends Panel

# Loja de fundos imobiliários. O grid (colunas, espaçamento) é da cena
# (bank.tscn, nó Fund-grid); aqui só se criam os cards, um por fundo:
#   nome / preço atual / volatilidade / quantidade / Comprar | Vender

const BankCard = preload("res://scripts/world/bank/bank_card.gd")

const CARD_MIN_HEIGHT := 210

@onready var fund_list: GridContainer = $"ScrollContainer/Fund-grid"

func _ready() -> void:
	# buy_fund/sell_fund/reset emitem funds_updated, então este sinal cobre também
	# o estado do botão Vender (que depende da carteira).
	FIIManager.funds_updated.connect(_on_funds_updated)
	load_funds()

func _on_funds_updated() -> void:
	load_funds()

func load_funds() -> void:
	# remove_child antes do queue_free: queue_free só libera no fim do frame, e
	# dois rebuilds no mesmo frame empilhariam cards velhos com os novos.
	for child in fund_list.get_children():
		fund_list.remove_child(child)
		child.queue_free()

	for fund_id in FIIManager.funds.keys():
		fund_list.add_child(_make_card(str(fund_id), FIIManager.funds[fund_id]))

func _make_card(fund_id: String, fund: Dictionary) -> PanelContainer:
	var parts := BankCard.new_card(CARD_MIN_HEIGHT)
	var box: VBoxContainer = parts["box"]

	box.add_child(BankCard.make_label(str(fund["name"]), 20))
	box.add_child(BankCard.make_label("R$ %.2f" % float(fund["price"]), 18))
	# volatility é a variação máxima de preço por dia (update_prices sorteia entre
	# -volatility e +volatility), então "±x% ao dia".
	box.add_child(BankCard.make_label("Volatilidade: ±%.1f%% ao dia" % (float(fund["volatility"]) * 100.0), 14))

	var input := SpinBox.new()
	input.min_value = 1
	input.max_value = 100
	input.step = 1
	input.value = 1
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(input)

	var buttons := HBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 6)
	box.add_child(buttons)

	var buy_btn := BankCard.make_button("Comprar")
	buy_btn.pressed.connect(_on_buy.bind(fund_id, input))
	buttons.add_child(buy_btn)

	var sell_btn := BankCard.make_button("Vender")
	sell_btn.pressed.connect(_on_sell.bind(fund_id, input))
	# Sem cotas deste fundo não há o que vender.
	if int(FIIManager.portfolio.get(fund_id, 0)) <= 0:
		sell_btn.disabled = true
		sell_btn.tooltip_text = "Você não possui cotas deste fundo."
	buttons.add_child(sell_btn)

	return parts["card"]


# =============================
# 💸 AÇÕES
# =============================
# A tela se redesenha sozinha: buy_fund/sell_fund emitem funds_updated quando
# dão certo, e quando recusam (sem dinheiro, sem cotas) nada mudou para redesenhar.
func _on_buy(fund_id: String, input: SpinBox) -> void:
	var success = FIIManager.buy_fund(fund_id, int(input.value))
	if not success:
		AlertManager.alert("Fundos insuficientes para comprar cotas deste fundo imobiliário.")

func _on_sell(fund_id: String, input: SpinBox) -> void:
	var success = FIIManager.sell_fund(fund_id, int(input.value))
	if not success:
		AlertManager.alert("Não foi possível vender cotas deste fundo.")
