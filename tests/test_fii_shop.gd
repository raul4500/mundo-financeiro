extends Node

const FiiShopScript = preload("res://scripts/world/bank/fii_shop.gd")

func _fresh() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 100000.0
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	FIIManager.reset()

# Monta a casca que a cena bank.tscn fornece ao script: Panel > ScrollContainer > Fund-grid.
func _make_shop() -> Panel:
	var shop := Panel.new()
	shop.set_script(FiiShopScript)
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	var grid := GridContainer.new()
	grid.name = "Fund-grid"
	grid.columns = 2
	scroll.add_child(grid)
	shop.add_child(scroll)
	add_child(shop)
	return shop

func _sell_button(card: Node) -> Button:
	# card > margin > box > [nome, preço, volatilidade, input, botões] ; botões > [Comprar, Vender]
	return card.get_child(0).get_child(0).get_child(4).get_child(1)

func _ready() -> void:
	print("=== Testando catálogo e loja de FIIs ===")

	# 1. Catálogo: 3 originais + 5 novos, sem a sigla FII no nome exibido.
	_fresh()
	assert(FIIManager.funds.size() == 8, "Deveria haver 8 fundos, há %d" % FIIManager.funds.size())
	for fund_id in FIIManager.funds.keys():
		var fund: Dictionary = FIIManager.funds[fund_id]
		assert(str(fund["name"]).find("FII") == -1, "Nome sem a sigla FII: %s" % fund["name"])
		assert(float(fund["price"]) > 0.0 and float(fund["dividend_yield"]) > 0.0 and float(fund["volatility"]) > 0.0, "Fundo %s com dado inválido" % fund_id)
		assert(str(fund_id).begins_with("FII_"), "O id continua com o prefixo (é a chave do save)")
	print("  ok   8 fundos, nomes sem a sigla FII")

	# 2. Save antigo: fundos faltantes entram, catálogo é reaplicado, o preço salvo fica.
	_fresh()
	FIIManager.funds = {
		"FII_SHOPPING": {"name": "FII Shopping", "price": 123.0, "dividend_yield": 0.01, "volatility": 0.02}
	}
	FIIManager._merge_default_funds()
	assert(FIIManager.funds.size() == 8, "Save antigo ganha os fundos que faltam")
	assert(FIIManager.funds["FII_SHOPPING"]["name"] == "Shopping", "Nome antigo com FII é atualizado")
	assert(is_equal_approx(float(FIIManager.funds["FII_SHOPPING"]["dividend_yield"]), 0.025), "Yield do catálogo é reaplicado")
	assert(float(FIIManager.funds["FII_SHOPPING"]["price"]) == 123.0, "O preço salvo é preservado")
	print("  ok   Save antigo recebe fundos novos e nomes/yields atuais sem perder o preço")

	# 3. Cards: um por fundo; volatilidade logo abaixo do preço; Vender desligado sem cotas.
	_fresh()
	var shop := _make_shop()
	var grid: GridContainer = shop.get_node("ScrollContainer/Fund-grid")
	assert(grid.get_child_count() == 8, "Um card por fundo")
	var first_card := grid.get_child(0)
	var box := first_card.get_child(0).get_child(0)
	assert(box.get_child(0).text == "Shopping", "Primeiro item do card é o nome")
	assert(box.get_child(1).text.begins_with("R$"), "Segundo item é o preço atual")
	assert(box.get_child(2).text.begins_with("Volatilidade"), "Terceiro item, logo abaixo do preço, é a volatilidade")
	assert(box.get_child(3) is SpinBox, "Depois vem o input de quantidade")
	for card in grid.get_children():
		assert(_sell_button(card).disabled, "Sem cotas, o botão Vender fica desativado")
	print("  ok   Cards na ordem nome, preço, volatilidade, input; Vender desligado sem cotas")

	# 4. Comprar liga o Vender só daquele fundo; vender tudo desliga de novo.
	FIIManager.buy_fund("FII_SHOPPING", 3)
	grid = shop.get_node("ScrollContainer/Fund-grid")
	var ids: Array = FIIManager.funds.keys()
	for i in range(grid.get_child_count()):
		var owned: bool = ids[i] == "FII_SHOPPING"
		assert(_sell_button(grid.get_child(i)).disabled != owned, "Vender liga só no fundo que o jogador possui (%s)" % ids[i])
	FIIManager.sell_fund("FII_SHOPPING", 3)
	for card in grid.get_children():
		assert(_sell_button(card).disabled, "Vendeu tudo: Vender desliga de novo")
	print("  ok   Botão Vender acompanha a carteira")

	print("=== Todos os testes da loja de FIIs passaram ===")
	get_tree().quit(0)
