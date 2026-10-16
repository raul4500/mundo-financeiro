extends Node

signal bills_updated

const DebtRules = preload("res://scripts/economy/debt_rules.gd")

const MAX_HISTORY_ENTRIES := 50

# A residência do jogador está sempre disponível no jogo. Se no futuro houver
# imóveis opcionais, esta lista pode receber uma condição de propriedade antes
# de gerar cada conta.
const HOUSE_BILL_TYPES := [
	{
		"type": "water",
		"title": "Conta de água",
		"description": "Despesa de água da residência.",
		"amount": 30.0
	},
	{
		"type": "electricity",
		"title": "Conta de luz",
		"description": "Despesa de energia elétrica da residência.",
		"amount": 45.0
	},
	{
		"type": "housing",
		"title": "Aluguel e condomínio",
		"description": "Custo semanal de moradia e manutenção da residência.",
		"amount": 75.0
	}
]

func _ready() -> void:
	if Global.player != null:
		ensure_state()

func ensure_state() -> void:
	if Global.player == null:
		return
	if typeof(Global.player.get("pending_house_bills", [])) != TYPE_ARRAY:
		Global.player["pending_house_bills"] = []
	if typeof(Global.player.get("house_bill_history", [])) != TYPE_ARRAY:
		Global.player["house_bill_history"] = []

func generate_weekly_bills() -> void:
	ensure_state()
	if Global.player == null:
		return

	var week := int(Global.player.get("week", 1))
	var pending: Array = Global.player["pending_house_bills"]
	var created_any := false
	for bill_type in HOUSE_BILL_TYPES:
		var bill_id := "house_bill_%d_%s" % [week, str(bill_type["type"])]
		if _bill_exists(bill_id, pending):
			continue
		pending.append({
			"id": bill_id,
			"title": str(bill_type["title"]),
			"description": str(bill_type["description"]),
			"amount": float(bill_type["amount"]),
			"week": week,
			# Vence no fim da semana seguinte à de geração (a conta aparece no
			# começo dela). limit_week: a conta é cobrada sozinha no fim dessa
			# semana, com os juros do atraso. Ver scripts/economy/debt_rules.gd.
			"due_week": week + 1,
			"limit_week": week + 2,
			"paid": false,
			"category": "house",
			"created_at_day": int(Global.player.get("day", 1)),
			"created_at_week": week
		})
		created_any = true

	Global.player["pending_house_bills"] = pending
	if created_any:
		bills_updated.emit()

func get_pending_bills() -> Array:
	ensure_state()
	if Global.player == null:
		return []
	var pending: Array = []
	for bill in Global.player["pending_house_bills"]:
		if typeof(bill) == TYPE_DICTIONARY and not bool(bill.get("paid", false)):
			pending.append(bill)
	return pending

# Contas de saves antigos não têm limit_week: assume a semana seguinte ao vencimento.
func bill_due_week(bill: Dictionary) -> int:
	return int(bill.get("due_week", int(bill.get("week", 1)) + 1))

func bill_limit_week(bill: Dictionary) -> int:
	return int(bill.get("limit_week", bill_due_week(bill) + 1))

# Valor com juros em `as_of_abs_day` (padrão: hoje). O `amount` gravado na conta
# é sempre o original; ver scripts/economy/debt_rules.gd.
func current_amount(bill: Dictionary, as_of_abs_day: int = -1) -> float:
	if as_of_abs_day < 0:
		as_of_abs_day = Global.get_absolute_day()
	var overdue := DebtRules.overdue_days(as_of_abs_day, bill_due_week(bill), Global.DAYS_PER_WEEK)
	return DebtRules.amount_with_interest(float(bill.get("amount", 0.0)), overdue)

func overdue_days_of(bill: Dictionary) -> int:
	return DebtRules.overdue_days(Global.get_absolute_day(), bill_due_week(bill), Global.DAYS_PER_WEEK)

# Soma das contas cuja data limite chegou até o fim de `week`, com os juros
# daquele momento. É o que a virada de semana cobra antes de liberar a próxima.
func total_due_through(week: int) -> float:
	var as_of := week * Global.DAYS_PER_WEEK
	var total := 0.0
	for bill in get_pending_bills():
		if bill_limit_week(bill) <= week:
			total += current_amount(bill, as_of)
	return snappedf(total, 0.01)

# Marca como quitadas as contas cuja data limite chegou. NÃO mexe no dinheiro:
# quem chama (TimeManager) já cobrou o total de total_due_through() dos fundos.
func settle_through(week: int) -> void:
	ensure_state()
	var as_of := week * Global.DAYS_PER_WEEK
	var remaining: Array = []
	for bill in Global.player["pending_house_bills"]:
		if typeof(bill) != TYPE_DICTIONARY or bool(bill.get("paid", false)) or bill_limit_week(bill) > week:
			remaining.append(bill)
			continue
		var amount := current_amount(bill, as_of)
		bill["paid"] = true
		bill["auto_paid"] = true
		bill["paid_amount"] = amount
		bill["paid_at_day"] = Global.DAYS_PER_WEEK
		bill["paid_at_week"] = week
		_append_history(bill)
		Global.register_expense(str(bill.get("title", "Conta da casa")), "house_bill", amount, Global.DAYS_PER_WEEK, week, false)
	Global.player["pending_house_bills"] = remaining
	bills_updated.emit()

func pay_bill(bill_id: String) -> Dictionary:
	ensure_state()
	if Global.player == null:
		return _failure("Estado do jogador não inicializado.", "no_player")

	var pending: Array = Global.player["pending_house_bills"]
	for index in range(pending.size()):
		var bill = pending[index]
		if typeof(bill) != TYPE_DICTIONARY or str(bill.get("id", "")) != bill_id:
			continue
		# Valor de hoje, com juros se já venceu. Paga da carteira e, se faltar,
		# do banco: o mesmo conjunto que a cobrança automática usa.
		var amount := current_amount(bill)
		if not Global.charge_funds(amount):
			return _failure("Dinheiro insuficiente (carteira + banco) para pagar esta conta da casa. Faltam R$ %.2f." % (amount - Global.total_funds()), "insufficient_money")

		pending.remove_at(index)
		Global.player["pending_house_bills"] = pending
		bill["paid_amount"] = amount
		bill["paid"] = true
		bill["paid_at_day"] = int(Global.player.get("day", 1))
		bill["paid_at_week"] = int(Global.player.get("week", 1))
		_append_history(bill)
		Global.register_expense(str(bill.get("title", "Conta da casa")), "house_bill", amount, int(Global.player.get("day", 1)), int(Global.player.get("week", 1)))
		# Pagamentos são uma decisão explícita do jogador; grave imediatamente
		# para que a pendência e o dinheiro não possam divergir após um reload.
		SaveManager.save_game()
		bills_updated.emit()
		return {"success": true, "message": "Conta da casa paga.", "money_spent": amount}

	return _failure("Conta da casa inexistente ou já paga.", "invalid_bill")

func _bill_exists(bill_id: String, pending: Array) -> bool:
	for bill in pending:
		if typeof(bill) == TYPE_DICTIONARY and str(bill.get("id", "")) == bill_id:
			return true
	for bill in Global.player.get("house_bill_history", []):
		if typeof(bill) == TYPE_DICTIONARY and str(bill.get("id", "")) == bill_id:
			return true
	return false

func _append_history(bill: Dictionary) -> void:
	var history: Array = Global.player.get("house_bill_history", [])
	history.append(bill)
	while history.size() > MAX_HISTORY_ENTRIES:
		history.pop_front()
	Global.player["house_bill_history"] = history

func _failure(message: String, reason: String) -> Dictionary:
	return {"success": false, "message": message, "reason": reason}
