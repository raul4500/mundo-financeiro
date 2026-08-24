extends Node

signal bills_updated

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
			"due_week": week + 1,
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

func pay_bill(bill_id: String) -> Dictionary:
	ensure_state()
	if Global.player == null:
		return _failure("Estado do jogador não inicializado.", "no_player")

	var pending: Array = Global.player["pending_house_bills"]
	for index in range(pending.size()):
		var bill = pending[index]
		if typeof(bill) != TYPE_DICTIONARY or str(bill.get("id", "")) != bill_id:
			continue
		var amount := float(bill.get("amount", 0.0))
		if float(Global.player.get("money", 0.0)) < amount:
			return _failure("Dinheiro insuficiente para pagar esta conta da casa.", "insufficient_money")

		Global.player["money"] = float(Global.player["money"]) - amount
		pending.remove_at(index)
		Global.player["pending_house_bills"] = pending
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
