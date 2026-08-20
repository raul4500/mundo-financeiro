extends Node

signal enterprise_purchased(enterprise_id)
signal enterprise_updated(enterprise_id)
signal enterprise_operation_finished(enterprise_id, result)
signal enterprise_error(message)
signal enterprise_balance_changed(enterprise_id)

const RestaurantInfo = preload("res://scripts/enterprise/data/restaurant_info.gd")
const ArcadeInfo = preload("res://scripts/enterprise/data/arcade_info.gd")
const ShoppingInfo = preload("res://scripts/enterprise/data/shopping_info.gd")

var enterprises: Dictionary = {}

func _ready() -> void:
	enterprises = {
		"restaurant_small": RestaurantInfo.get_data(),
		"arcade_medium": ArcadeInfo.get_data(),
		"shopping_large": ShoppingInfo.get_data()
	}
	if Global.player != null:
		Global.ensure_player_state()

func _default_state() -> Dictionary:
	return {
		"owned": false,
		"level": 0,
		"cash_balance": 0.0,
		"stock": {},
		"equipment": {},
		"pending_bills": {},
		"daily_revenue": 0.0,
		"daily_expenses": 0.0,
		"total_revenue": 0.0,
		"total_expenses": 0.0,
		"total_profit": 0.0,
		"last_operation_day": 0,
		"last_operation_week": 0,
		"history": []
	}

func create_default_states() -> Dictionary:
	var states := {}
	for enterprise_id in enterprises.keys():
		states[enterprise_id] = _default_state()
	return states

func _ensure_states() -> void:
	if Global.player == null:
		return
	if not Global.player.has("enterprises") or typeof(Global.player["enterprises"]) != TYPE_DICTIONARY:
		Global.player["enterprises"] = create_default_states()
	for enterprise_id in enterprises.keys():
		if not Global.player["enterprises"].has(enterprise_id):
			Global.player["enterprises"][enterprise_id] = _default_state()

func get_enterprise_info(enterprise_id: String) -> Dictionary:
	return enterprises.get(enterprise_id, {}).duplicate(true)

func get_player_enterprise(enterprise_id: String) -> Dictionary:
	_ensure_states()
	return Global.player["enterprises"].get(enterprise_id, {}).duplicate(true)

func is_owned(enterprise_id: String) -> bool:
	return bool(get_player_enterprise(enterprise_id).get("owned", false))

func can_buy(enterprise_id: String) -> Dictionary:
	var info = get_enterprise_info(enterprise_id)
	if info.is_empty():
		return {"success": false, "message": "Empreendimento inexistente.", "reason": "invalid_id"}
	if is_owned(enterprise_id):
		return {"success": false, "message": "Você já possui este empreendimento.", "reason": "already_owned"}
	var price = float(info.get("purchase_price", 0.0))
	if float(Global.player.get("money", 0.0)) < price:
		return {"success": false, "message": "Dinheiro insuficiente para comprar este empreendimento.", "reason": "insufficient_money"}
	return {"success": true, "message": "Compra disponível.", "price": price}

func buy_enterprise(enterprise_id: String) -> Dictionary:
	var result = can_buy(enterprise_id)
	if not result.get("success", false):
		emit_signal("enterprise_error", result.get("message", "Não foi possível comprar."))
		return result
	var info = get_enterprise_info(enterprise_id)
	var state = Global.player["enterprises"][enterprise_id]
	var price = float(info["purchase_price"])
	Global.player["money"] = float(Global.player["money"]) - price
	state["owned"] = true
	state["level"] = 1
	state["history"].append(_history_entry("purchase", "Compra do empreendimento", -price))
	Global.player["enterprises"][enterprise_id] = state
	Global.register_expense(info["name"], "enterprise_purchase", price, int(Global.player["day"]), int(Global.player["week"]))
	emit_signal("enterprise_purchased", enterprise_id)
	emit_signal("enterprise_updated", enterprise_id)
	emit_signal("enterprise_balance_changed", enterprise_id)
	return {"success": true, "message": "%s comprado com sucesso." % info["name"], "money_spent": price}

func get_available_stock(enterprise_id: String) -> Array:
	return get_enterprise_info(enterprise_id).get("stock_items", []).duplicate(true)

func buy_stock(enterprise_id: String, item_id: String, quantity: int) -> Dictionary:
	if quantity <= 0:
		return _failure("A quantidade deve ser positiva.", "invalid_quantity")
	if not is_owned(enterprise_id):
		return _failure("Compre o empreendimento antes de comprar estoque.", "not_owned")
	var item = _find_item(get_available_stock(enterprise_id), item_id)
	if item.is_empty():
		return _failure("Item de estoque inexistente.", "invalid_item")
	var total = float(item["price"]) * quantity
	if float(Global.player["money"]) < total:
		return _failure("Dinheiro insuficiente para comprar estoque. Você precisa de R$ %.2f." % total, "insufficient_money")
	var state = Global.player["enterprises"][enterprise_id]
	var stock = state.get("stock", {})
	stock[item_id] = int(stock.get(item_id, 0)) + quantity * int(item.get("units", 1))
	state["stock"] = stock
	state["history"].append(_history_entry("stock", "Compra de estoque: %s" % item["name"], -total))
	Global.player["enterprises"][enterprise_id] = state
	Global.player["money"] = float(Global.player["money"]) - total
	Global.register_expense(item["name"], "enterprise_stock", total, int(Global.player["day"]), int(Global.player["week"]))
	emit_signal("enterprise_updated", enterprise_id)
	emit_signal("enterprise_balance_changed", enterprise_id)
	return {"success": true, "message": "Estoque comprado.", "money_spent": total, "quantity": stock[item_id]}

func get_pending_bills(enterprise_id: String) -> Array:
	var state = get_player_enterprise(enterprise_id)
	var bills: Array = []
	for bill_id in state.get("pending_bills", {}).keys():
		var bill = state["pending_bills"][bill_id]
		# Saves antigos marcavam a conta como paga em vez de removê-la.
		if bool(bill.get("paid", false)):
			continue
		var entry = bill.duplicate(true)
		entry["id"] = bill_id
		bills.append(entry)
	return bills

func generate_weekly_bills(enterprise_id: String) -> void:
	if not is_owned(enterprise_id):
		return
	var info = get_enterprise_info(enterprise_id)
	var state = Global.player["enterprises"][enterprise_id]
	var bills = state.get("pending_bills", {})
	var week = int(Global.player.get("week", 1))

	# Limpa resíduo de saves antigos: hoje a conta paga é removida do dicionário.
	for bill_id in bills.keys():
		if bool(bills[bill_id].get("paid", false)):
			bills.erase(bill_id)

	# A chave inclui a semana, então contas não pagas de semanas anteriores
	# continuam pendentes em vez de serem sobrescritas.
	_add_bill(bills, "water_%d" % week, "Conta de água (semana %d)" % week, float(info.get("water_bill", 0.0)), week)
	_add_bill(bills, "electricity_%d" % week, "Conta de luz (semana %d)" % week, float(info.get("electricity_bill", 0.0)), week)

	state["pending_bills"] = bills
	state["history"].append(_history_entry("bill", "Contas da semana %d geradas" % week, 0.0))
	Global.player["enterprises"][enterprise_id] = state
	emit_signal("enterprise_updated", enterprise_id)

func _add_bill(bills: Dictionary, bill_id: String, bill_name: String, amount: float, week: int) -> void:
	if bills.has(bill_id):
		return
	bills[bill_id] = {"name": bill_name, "amount": amount, "paid": false, "week": week}

func pay_bill(enterprise_id: String, bill_id: String) -> Dictionary:
	if not is_owned(enterprise_id):
		return _failure("Empreendimento não comprado.", "not_owned")
	var state = Global.player["enterprises"][enterprise_id]
	var bills = state.get("pending_bills", {})
	if not bills.has(bill_id) or bool(bills[bill_id].get("paid", false)):
		return _failure("Conta inexistente ou já paga.", "invalid_bill")
	var bill = bills[bill_id]
	var amount = float(bill.get("amount", 0.0))
	if float(Global.player.get("money", 0.0)) < amount:
		return _failure("Dinheiro insuficiente para pagar a conta.", "insufficient_money")
	Global.player["money"] = float(Global.player["money"]) - amount
	bills.erase(bill_id)
	state["pending_bills"] = bills
	state["total_expenses"] = float(state.get("total_expenses", 0.0)) + amount
	state["total_profit"] = float(state.get("total_profit", 0.0)) - amount
	state["history"].append(_history_entry("bill", "Conta paga: %s" % bill.get("name", bill_id), -amount))
	Global.player["enterprises"][enterprise_id] = state
	Global.register_expense(str(bill.get("name", bill_id)), "enterprise_bill", amount, int(Global.player["day"]), int(Global.player["week"]))
	emit_signal("enterprise_updated", enterprise_id)
	emit_signal("enterprise_balance_changed", enterprise_id)
	return {"success": true, "message": "Conta paga.", "money_spent": amount}

func buy_equipment(enterprise_id: String, equipment_id: String) -> Dictionary:
	if not is_owned(enterprise_id):
		return _failure("Compre o empreendimento antes de comprar equipamentos.", "not_owned")
	var item = _find_item(get_enterprise_info(enterprise_id).get("equipment_items", []), equipment_id)
	if item.is_empty():
		return _failure("Equipamento inexistente.", "invalid_item")
	var state = Global.player["enterprises"][enterprise_id]
	if state.get("equipment", {}).has(equipment_id):
		return _failure("Este equipamento já foi comprado.", "already_owned")
	if int(state.get("level", 1)) < int(item.get("level_required", 1)):
		return _failure("Nível insuficiente para este equipamento.", "level_required")
	var price = float(item["price"])
	if float(Global.player["money"]) < price:
		return _failure("Dinheiro insuficiente para comprar este equipamento. Você precisa de R$ %.2f." % price, "insufficient_money")
	Global.player["money"] = float(Global.player["money"]) - price
	state["equipment"][equipment_id] = true
	state["history"].append(_history_entry("equipment", "Compra de equipamento: %s" % item["name"], -price))
	Global.player["enterprises"][enterprise_id] = state
	Global.register_expense(item["name"], "enterprise_equipment", price, int(Global.player["day"]), int(Global.player["week"]))
	emit_signal("enterprise_updated", enterprise_id)
	emit_signal("enterprise_balance_changed", enterprise_id)
	return {"success": true, "message": "Equipamento comprado.", "money_spent": price}

func calculate_daily_revenue(enterprise_id: String) -> float:
	var info = get_enterprise_info(enterprise_id)
	var state = get_player_enterprise(enterprise_id)
	if not state.get("owned", false):
		return 0.0
	var level = max(1, int(state.get("level", 1)))
	var level_multiplier = [1.0, 1.2, 1.45, 1.75, 2.15][min(level - 1, 4)]
	var revenue = float(info.get("base_daily_revenue", 0.0)) * level_multiplier
	var has_stock := false
	for stock_amount in state.get("stock", {}).values():
		if int(stock_amount) > 0:
			has_stock = true
			break
	if not has_stock:
		revenue *= 0.35
	for item in info.get("equipment_items", []):
		if state.get("equipment", {}).has(item["id"]):
			revenue += float(item.get("revenue_bonus", 0.0))
	for item_id in state.get("stock", {}).keys():
		var stock_item = _find_item(info.get("stock_items", []), item_id)
		if not stock_item.is_empty() and int(state["stock"][item_id]) > 0:
			revenue += float(stock_item.get("revenue_bonus", 0.0))
	return revenue

func calculate_daily_expenses(enterprise_id: String) -> float:
	var info = get_enterprise_info(enterprise_id)
	var state = get_player_enterprise(enterprise_id)
	var expenses = float(info.get("base_daily_expenses", 0.0))
	for item in info.get("equipment_items", []):
		if state.get("equipment", {}).has(item["id"]):
			expenses += float(item.get("maintenance_cost", 0.0))
	return expenses

func calculate_daily_profit(enterprise_id: String) -> float:
	return calculate_daily_revenue(enterprise_id) - calculate_daily_expenses(enterprise_id)

func process_daily_operation(enterprise_id: String) -> Dictionary:
	if not is_owned(enterprise_id):
		return _failure("Empreendimento não comprado.", "not_owned")
	var state = Global.player["enterprises"][enterprise_id]
	var day = int(Global.player.get("day", 1))
	var week = int(Global.player.get("week", 1))
	if int(state.get("last_operation_day", 0)) == day and int(state.get("last_operation_week", 0)) == week:
		return _failure("A operação deste dia já foi processada.", "already_processed")
	var revenue = calculate_daily_revenue(enterprise_id)
	var expenses = calculate_daily_expenses(enterprise_id)
	var profit = revenue - expenses
	var stock = state.get("stock", {})
	for item_id in stock.keys():
		var item = _find_item(get_available_stock(enterprise_id), item_id)
		if not item.is_empty():
			stock[item_id] = max(0, int(stock[item_id]) - int(item.get("consumption", 1)))
	state["stock"] = stock
	state["daily_revenue"] = revenue
	state["daily_expenses"] = expenses
	state["total_revenue"] = float(state.get("total_revenue", 0.0)) + revenue
	state["total_expenses"] = float(state.get("total_expenses", 0.0)) + expenses
	state["total_profit"] = float(state.get("total_profit", 0.0)) + profit
	state["last_operation_day"] = day
	state["last_operation_week"] = week
	state["cash_balance"] = float(state.get("cash_balance", 0.0)) + profit
	state["history"].append(_history_entry("operation", "Operação diária", profit))
	Global.player["money"] = float(Global.player["money"]) + profit
	Global.player["enterprises"][enterprise_id] = state
	emit_signal("enterprise_operation_finished", enterprise_id, {"success": true, "revenue": revenue, "expenses": expenses, "profit": profit})
	emit_signal("enterprise_updated", enterprise_id)
	return {"success": true, "message": "Operação diária processada.", "revenue": revenue, "expenses": expenses, "profit": profit}

func process_all_daily_operations() -> void:
	_ensure_states()
	for enterprise_id in enterprises.keys():
		if is_owned(enterprise_id):
			process_daily_operation(enterprise_id)

func generate_all_weekly_bills() -> void:
	_ensure_states()
	for enterprise_id in enterprises.keys():
		if is_owned(enterprise_id):
			generate_weekly_bills(enterprise_id)

func get_dashboard_data(enterprise_id: String) -> Dictionary:
	var info = get_enterprise_info(enterprise_id)
	var state = get_player_enterprise(enterprise_id)
	return {
		"info": info,
		"state": state,
		"money": float(Global.player.get("money", 0.0)),
		"daily_revenue": calculate_daily_revenue(enterprise_id),
		"daily_expenses": calculate_daily_expenses(enterprise_id),
		"daily_profit": calculate_daily_profit(enterprise_id),
		"capacity": _calculate_capacity(enterprise_id),
		"stock": get_available_stock(enterprise_id),
		"equipment": info.get("equipment_items", [])
	}

func _calculate_capacity(enterprise_id: String) -> int:
	var info = get_enterprise_info(enterprise_id)
	var state = get_player_enterprise(enterprise_id)
	var capacity = int(info.get("starting_capacity", 0))
	for item in info.get("equipment_items", []):
		if state.get("equipment", {}).has(item["id"]):
			capacity += int(item.get("capacity_bonus", 0))
	return capacity

func _find_item(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == item_id:
			return item.duplicate(true)
	return {}

func _history_entry(entry_type: String, description: String, amount: float) -> Dictionary:
	return {"type": entry_type, "description": description, "amount": amount, "day": Global.player.get("day", 1), "week": Global.player.get("week", 1)}

func _failure(message: String, reason: String) -> Dictionary:
	emit_signal("enterprise_error", message)
	return {"success": false, "message": message, "reason": reason}
