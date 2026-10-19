extends Node

signal portfolio_updated
signal funds_updated

func _logger() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("/root/Logger")

func _log_warning(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_warning(message)
	else:
		print("[WARN] %s" % message)

func _log_error(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_error(message)
	else:
		print("[ERROR] %s" % message)

# Catálogo de fundos. O id (FII_*) é a chave gravada no save e na carteira: não
# renomear. O nome exibido NÃO leva a sigla "FII" (a tela já diz que são fundos
# imobiliários, e a sigla estourava o label do card).
#
# Yields subidos na auditoria de balanceamento (ECONOMY_BALANCE_PLAN.md,
# achado #4): com 0,8-1,2%/semana, a missão "lucro_200" da semana 4 exigia
# ~R$10-20 mil investidos, inatingível no ritmo normal de jogo.
#
# Risco e retorno andam juntos de propósito: quanto maior a volatilidade (variação
# máxima de preço por dia), maior o yield semanal. Recebíveis é o mais estável e
# paga menos; Hotéis é o mais instável e paga mais.
func _default_funds() -> Dictionary:
	return {
		"FII_SHOPPING": {
			"name": "Shopping",
			"price": 100.0,
			"dividend_yield": 0.025,
			"volatility": 0.02
		},
		"FII_LAJES": {
			"name": "Lajes Corporativas",
			"price": 120.0,
			"dividend_yield": 0.02,
			"volatility": 0.015
		},
		"FII_LOGISTICA": {
			"name": "Logística",
			"price": 90.0,
			"dividend_yield": 0.03,
			"volatility": 0.025
		},
		"FII_RECEBIVEIS": {
			"name": "Recebíveis",
			"price": 100.0,
			"dividend_yield": 0.019,
			"volatility": 0.008
		},
		"FII_RESIDENCIAL": {
			"name": "Residencial",
			"price": 85.0,
			"dividend_yield": 0.021,
			"volatility": 0.012
		},
		"FII_HOSPITAIS": {
			"name": "Hospitais",
			"price": 140.0,
			"dividend_yield": 0.023,
			"volatility": 0.017
		},
		"FII_AGRO": {
			"name": "Agro",
			"price": 110.0,
			"dividend_yield": 0.027,
			"volatility": 0.022
		},
		"FII_HOTEIS": {
			"name": "Hotéis",
			"price": 75.0,
			"dividend_yield": 0.032,
			"volatility": 0.03
		}
	}

var funds = _default_funds()

var portfolio = {}
# Preco medio pago por cota, por fundo. Separado de `portfolio` (que continua
# sendo so' {fund_id: quantidade}) para nao quebrar quem le' a carteira:
# portfolio.gd e fii_shop.gd.
var avg_price = {}
var total_invested: float = 0.0
var total_dividends_received: float = 0.0

# Imposto sobre o prejuizo ao vender uma cota abaixo do preco medio pago.
# Vender no vermelho custa dinheiro; segurar e esperar, nao (BUGFIX_PLAN 10.1).
const LOSS_TAX_RATE := 0.10

func update_prices():
	for key in funds.keys():
		var fund = funds[key]
		var change = randf_range(-fund["volatility"], fund["volatility"])
		fund["price"] += fund["price"] * change
		fund["price"] = max(fund["price"], 1.0)
	emit_signal("funds_updated")

func reset() -> void:
	# Reseta o estado do FIIManager para os valores iniciais.
	# Chamado por Global.new_game() para garantir que um novo jogo não herda
	# a carteira do jogo anterior.
	portfolio = {}
	avg_price = {}
	total_invested = 0.0
	total_dividends_received = 0.0
	funds = _default_funds()
	emit_signal("portfolio_updated")
	emit_signal("funds_updated")

func buy_fund(fund_id: String, amount: int):
	if not funds.has(fund_id):
		return false
	if amount <= 0:
		return false
	var price = float(funds[fund_id]["price"])
	var total_cost = price * float(amount)
	if Global.player == null:
		_log_error("FIIManager.buy_fund falhou: Global.player nulo")
		return false
	if not Global.charge_funds(total_cost):
		_log_warning("Dinheiro insuficiente para comprar FII: %s" % fund_id)
		return false
	if not portfolio.has(fund_id):
		portfolio[fund_id] = 0
	# Preco medio ponderado, calculado antes de somar as cotas novas.
	var held := int(portfolio[fund_id])
	var previous_cost := float(avg_price.get(fund_id, price)) * float(held)
	portfolio[fund_id] = held + amount
	avg_price[fund_id] = (previous_cost + total_cost) / float(portfolio[fund_id])
	total_invested += total_cost
	print("Comprou %d cotas de %s" % [amount, fund_id])
	emit_signal("portfolio_updated")
	emit_signal("funds_updated")
	return true

func sell_fund(fund_id: String, amount: int):
	if not portfolio.has(fund_id):
		_log_warning("Tentativa de vender FII inexistente: %s" % fund_id)
		return false
	if amount <= 0:
		_log_warning("Tentativa de vender quantidade inválida de FII: %s" % fund_id)
		return false
	if portfolio[fund_id] < amount:
		_log_warning("Você não tem cotas suficientes para vender %s" % fund_id)
		return false
	var price = float(funds[fund_id]["price"])
	var total_gain = price * float(amount)
	var cost_basis = float(avg_price.get(fund_id, price)) * float(amount)
	# Vender abaixo do preco medio pago paga imposto sobre o prejuizo.
	var loss_tax = 0.0
	if total_gain < cost_basis:
		loss_tax = (cost_basis - total_gain) * LOSS_TAX_RATE
	portfolio[fund_id] -= amount
	if portfolio[fund_id] <= 0:
		portfolio.erase(fund_id)
		avg_price.erase(fund_id)
	Global.player["money"] = float(Global.player["money"]) + total_gain - loss_tax
	total_invested -= cost_basis
	print("Vendeu %d cotas de %s" % [amount, fund_id])
	if loss_tax > 0.0:
		Global.register_expense(
			"Imposto sobre prejuízo - %s" % str(funds[fund_id]["name"]),
			"fii_loss_tax",
			loss_tax,
			int(Global.player.get("day", 1)),
			int(Global.player.get("week", 1))
		)
		AlertManager.alert(
			"Você vendeu %s no prejuízo.\n\nPreço médio pago: R$ %.2f por cota\nPreço de venda: R$ %.2f por cota\n\nImposto sobre o prejuízo (%d%%): - R$ %.2f\n\nVender na baixa custa caro. Diversificar e esperar a recuperação costuma sair mais barato." % [
				str(funds[fund_id]["name"]),
				cost_basis / float(amount),
				price,
				int(LOSS_TAX_RATE * 100.0),
				loss_tax
			]
		)
	emit_signal("portfolio_updated")
	emit_signal("funds_updated")
	return true

func pay_dividends():
	var dividends_paid = 0.0
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		var dividend = float(fund["price"]) * float(fund["dividend_yield"]) * float(quantity)
		dividends_paid += dividend
	Global.player["money"] = float(Global.player["money"]) + dividends_paid
	total_dividends_received += dividends_paid
	print("Dividendos recebidos: R$%.2f" % dividends_paid)

func get_portfolio_value() -> float:
	var total = 0.0
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		total += float(fund["price"]) * float(quantity)
	return total

func get_profit() -> float:
	return get_portfolio_value() + total_dividends_received - total_invested

func save_data():
	if Global.player == null:
		return
	Global.player["investments"] = {
		"fiis": {
			"portfolio": portfolio,
			"avg_price": avg_price,
			"funds_data": funds,
			"total_invested": total_invested,
			"total_dividends_received": total_dividends_received
		}
	}

# O save grava o dicionário inteiro de fundos, então um save antigo só conhece os
# fundos da época, com nomes e taxas da época. Completa os que faltam e
# reaplica o que é catálogo (nome, yield, volatilidade), preservando só o preço
# salvo, que é estado de jogo. Sem isso fundos novos nunca apareceriam para
# quem já tem save, e um ajuste de yield só valeria em partida nova.
func _merge_default_funds() -> void:
	var defaults := _default_funds()
	for fund_id in defaults.keys():
		if not funds.has(fund_id):
			funds[fund_id] = defaults[fund_id]
			continue
		for key in ["name", "dividend_yield", "volatility"]:
			funds[fund_id][key] = defaults[fund_id][key]

func load_data():
	if Global.player == null:
		return
	var data = Global.player.get("investments", {}).get("fiis", {})
	if data.has("portfolio"):
		portfolio = data["portfolio"]
	if data.has("avg_price"):
		avg_price = data["avg_price"]
	if data.has("funds_data"):
		funds = data["funds_data"]
	_merge_default_funds()
	# Save antigo, sem preco medio: adota o preco atual como base de custo, para
	# uma carteira herdada nao ser taxada por um prejuizo que nunca existiu.
	for fund_id in portfolio.keys():
		if not avg_price.has(fund_id) and funds.has(fund_id):
			avg_price[fund_id] = float(funds[fund_id]["price"])
	total_invested = float(data.get("total_invested", 0.0))
	total_dividends_received = float(data.get("total_dividends_received", 0.0))
