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

var funds = {
	"FII_SHOPPING": {
		"name": "FII Shopping",
		"price": 100.0,
		"dividend_yield": 0.01,
		"volatility": 0.02
	},
	"FII_LAJES": {
		"name": "FII Lajes Corporativas",
		"price": 120.0,
		"dividend_yield": 0.008,
		"volatility": 0.015
	},
	"FII_LOGISTICA": {
		"name": "FII Logística",
		"price": 90.0,
		"dividend_yield": 0.012,
		"volatility": 0.025
	}
}

var portfolio = {}

func update_prices():
	for key in funds.keys():
		var fund = funds[key]
		var change = randf_range(-fund["volatility"], fund["volatility"])
		fund["price"] += fund["price"] * change
		fund["price"] = max(fund["price"], 1.0)
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
	if float(Global.player["money"]) < total_cost:
		_log_warning("Dinheiro insuficiente para comprar FII: %s" % fund_id)
		return false
	Global.player["money"] = float(Global.player["money"]) - total_cost
	if not portfolio.has(fund_id):
		portfolio[fund_id] = 0
	portfolio[fund_id] += amount
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
	portfolio[fund_id] -= amount
	if portfolio[fund_id] <= 0:
		portfolio.erase(fund_id)
	Global.player["money"] = float(Global.player["money"]) + total_gain
	print("Vendeu %d cotas de %s" % [amount, fund_id])
	emit_signal("portfolio_updated")
	emit_signal("funds_updated")
	return true

func pay_dividends():
	var total_dividends = 0.0
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		var dividend = float(fund["price"]) * float(fund["dividend_yield"]) * float(quantity)
		total_dividends += dividend
	Global.player["money"] = float(Global.player["money"]) + total_dividends
	print("Dividendos recebidos: R$%.2f" % total_dividends)

func get_portfolio_value() -> float:
	var total = 0.0
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		total += float(fund["price"]) * float(quantity)
	return total

func save_data():
	if Global.player == null:
		return
	Global.player["investments"] = {
		"fiis": {
			"portfolio": portfolio,
			"funds_data": funds
		}
	}

func load_data():
	if Global.player == null:
		return
	var data = Global.player.get("investments", {}).get("fiis", {})
	if data.has("portfolio"):
		portfolio = data["portfolio"]
	if data.has("funds_data"):
		funds = data["funds_data"]
