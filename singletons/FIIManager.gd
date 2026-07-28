extends Node

signal portfolio_updated
signal funds_updated

# =============================
# 📦 FUNDOS DISPONÍVEIS
# =============================
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

# =============================
# 👤 CARTEIRA DO JOGADOR
# =============================
var portfolio = {
	# "FII_SHOPPING": quantidade
}

# =============================
# 📈 ATUALIZAR PREÇOS (chamar por dia)
# =============================
func update_prices():
	for key in funds.keys():
		var fund = funds[key]
		
		var change = randf_range(-fund["volatility"], fund["volatility"])
		fund["price"] += fund["price"] * change
		fund["price"] = max(fund["price"], 1.0)
	emit_signal("funds_updated")
# =============================
# 💸 COMPRAR COTA
# =============================
func buy_fund(fund_id: String, amount: int):
	if not funds.has(fund_id):
		return false
	
	var price = funds[fund_id]["price"]
	var total_cost = price * amount
	
	if Global.player["money"] < total_cost:
		print("Dinheiro insuficiente!")
		return false
	
	Global.player["money"] -= total_cost
	
	if not portfolio.has(fund_id):
		portfolio[fund_id] = 0
	
	portfolio[fund_id] += amount
	
	print("Comprou %d cotas de %s" % [amount, fund_id])
	
	emit_signal("portfolio_updated")
	emit_signal("funds_updated")
	
	return true

# =============================
# 💰 VENDER COTA
# =============================
func sell_fund(fund_id: String, amount: int):
	if not portfolio.has(fund_id):
		return false
	
	if portfolio[fund_id] < amount:
		print("Você não tem cotas suficientes!")
		return false
	
	var price = funds[fund_id]["price"]
	var total_gain = price * amount
	
	portfolio[fund_id] -= amount
	Global.player["money"] += total_gain
	
	print("Vendeu %d cotas de %s" % [amount, fund_id])

	emit_signal("portfolio_updated")
	emit_signal("funds_updated")
	
	return true

# =============================
# 💵 PAGAR DIVIDENDOS
# =============================
func pay_dividends():
	var total_dividends = 0
	
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		
		var dividend = fund["price"] * fund["dividend_yield"] * quantity
		total_dividends += dividend
	
	Global.player["money"] += total_dividends
	
	print("Dividendos recebidos: R$%.2f" % total_dividends)

# =============================
# 📊 VALOR TOTAL DA CARTEIRA
# =============================
func get_portfolio_value() -> float:
	var total = 0
	
	for fund_id in portfolio.keys():
		var fund = funds[fund_id]
		var quantity = portfolio[fund_id]
		
		total += fund["price"] * quantity
	
	return total


func save_data():
	Global.player["investments"] = {
		"fiis": {
			"portfolio": portfolio,
			"funds_data": funds
		}
	}
	
func load_data():
	var data = Global.player.get("investments", {}).get("fiis", {})
	
	if data.has("portfolio"):
		portfolio = data["portfolio"]
	
	if data.has("funds_data"):
		funds = data["funds_data"]
