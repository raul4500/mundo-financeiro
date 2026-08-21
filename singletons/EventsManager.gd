extends Node

signal evento_ocorreu(evento)
# Emitido quando a lista de pendências muda (criação, pagamento, resgate).
# A UI do banco escuta este sinal para se redesenhar sem precisar de polling.
signal events_updated

# =============================================================
# EVENTOS INESPERADOS
# Refatorado: um evento NUNCA mexe direto em Global.player["money"].
# Ele cria uma pendência (conta a pagar ou bônus a resgatar) em
# Global.player["pending_events"], e o dinheiro só muda quando o
# jogador aciona Pagar/Resgatar no banco.
# =============================================================

# Semana a partir da qual os eventos começam a aparecer.
const FIRST_EVENT_WEEK := 2
# Intervalo do sorteio periódico, em segundos de tempo real. Mantido igual ao
# comportamento original para não alterar a frequência de eventos do jogo.
const SPAWN_INTERVAL := 100.0
# Pendências resolvidas continuam na lista como histórico, mas limitadas para
# o save não crescer sem limite em partidas longas.
const MAX_RESOLVED_EVENTS := 30

var eventos: Array = []
var spawn_timer := 0.0

func _ready() -> void:
	eventos = UnexpectedEvents.unexpected_events["eventos"]
	var event_ui_scene = load("res://scenes/ui/event_message.tscn")
	add_child(event_ui_scene.instantiate())

# =============================
# 🪵 LOG
# =============================
func _logger() -> Node:
	if get_tree() == null or get_tree().root == null:
		return null
	return get_tree().root.get_node_or_null("/root/Logger")

func _log_info(message: String) -> void:
	var logger = _logger()
	if logger != null:
		logger.log_info(message)
	else:
		print("[INFO] %s" % message)

# =============================
# ⏱ SORTEIO PERIÓDICO
# =============================
func _process(delta: float) -> void:
	# O sorteio só corre enquanto o jogador está de fato jogando. Sem esta
	# guarda o timer continuava contando no menu inicial e na escolha de
	# personagem, porque este script é um autoload e nunca sai da árvore.
	if not Global.play_time or Global.gameplay_locked:
		return
	spawn_timer += delta
	if spawn_timer < SPAWN_INTERVAL:
		return
	spawn_timer = 0.0
	maybe_spawn_events(int(Global.player.get("week", 1)))

# Ponto único de entrada da geração de eventos: usado pelo timer acima e pelo
# avanço de semana em TimeManager. A regra da semana mínima vive só aqui.
func maybe_spawn_events(current_week: int) -> Dictionary:
	if current_week < FIRST_EVENT_WEEK:
		return {}
	return trigger_evento()

# =============================
# 🎲 SORTEAR EVENTO
# =============================
func sortear_evento() -> Dictionary:
	for evento in eventos:
		if randf() < float(evento.get("probabilidade", 0.1)):
			return evento
	return {}

# =============================
# ⚡ DISPARAR EVENTO
# =============================
func trigger_evento() -> Dictionary:
	var evento = sortear_evento()
	if evento.is_empty():
		return {}

	_log_info("Evento sorteado: %s" % str(evento.get("titulo", "?")))
	emit_signal("evento_ocorreu", evento)

	# Eventos com escolha não geram pendência agora: quem decide é o jogador,
	# em event_ui.gd, e só a opção escolhida vira conta ou bônus.
	if evento.has("escolhas"):
		return evento

	create_pending_event(evento, evento.get("impacto", {}))
	return evento

# =============================
# 🗂 PENDÊNCIAS (contas e bônus)
# =============================

# Arrays em GDScript são referência, então mutar o retorno muta o save.
func _pending_list() -> Array:
	if not Global.player.has("pending_events") or typeof(Global.player["pending_events"]) != TYPE_ARRAY:
		Global.player["pending_events"] = []
	return Global.player["pending_events"]

func create_pending_event(evento: Dictionary, impacto: Dictionary) -> Dictionary:
	var raw_amount = float(impacto.get("dinheiro", 0.0))
	if is_zero_approx(raw_amount):
		# Escolhas sem custo (ex.: "Não comprar") não geram conta nem bônus.
		return {}

	var source_id = str(evento.get("id", "evento"))
	# Evita empilhar a mesma pendência: enquanto a anterior não for resolvida,
	# um novo sorteio do mesmo evento é descartado. Sem isso o sorteio a cada
	# 100s encheria o banco de contas idênticas.
	if has_pending_from_source(source_id):
		_log_info("Evento '%s' descartado: já existe pendência do mesmo tipo." % source_id)
		return {}

	var is_bonus = raw_amount > 0.0
	var list = _pending_list()
	var ev = {
		"id": "%s_%d_%d" % [source_id, int(Time.get_unix_time_from_system()), list.size()],
		"title": str(evento.get("titulo", "Evento")),
		"description": str(evento.get("descricao", "")),
		"week_generated": int(Global.player.get("week", 1)),
		# amount é sempre positivo: o sinal vive em is_bonus. Guardar o valor
		# negativo fazia pay_event() creditar o jogador em vez de debitar.
		"amount": abs(raw_amount),
		"is_bonus": is_bonus,
		"status": "pending",
		"location": "bank",
		"source_id": source_id
	}
	list.append(ev)
	_prune_resolved(list)
	SaveManager.save_game()
	emit_signal("events_updated")
	_log_info("Pendência criada: %s (%s de R$ %.2f)" % [ev["title"], "bônus" if is_bonus else "conta", ev["amount"]])
	return ev

func has_pending_from_source(source_id: String) -> bool:
	for ev in _pending_list():
		if str(ev.get("source_id", "")) == source_id and str(ev.get("status", "")) == "pending":
			return true
	return false

# location vazio devolve todas as pendências abertas, de qualquer lugar.
func get_pending_events(location: String = "") -> Array:
	var result: Array = []
	for ev in _pending_list():
		if str(ev.get("status", "")) != "pending":
			continue
		if location != "" and str(ev.get("location", "bank")) != location:
			continue
		result.append(ev)
	return result

func _find_event(event_id: String) -> Dictionary:
	for ev in _pending_list():
		if str(ev.get("id", "")) == event_id:
			return ev
	return {}

func pay_event(event_id: String) -> Dictionary:
	var ev = _find_event(event_id)
	if ev.is_empty():
		return {"success": false, "message": "Conta não encontrada."}
	if str(ev.get("status", "")) != "pending":
		return {"success": false, "message": "Esta pendência já foi resolvida."}
	if bool(ev.get("is_bonus", false)):
		return {"success": false, "message": "Isto é um bônus: use Resgatar."}

	# abs(): o sinal vive em is_bonus. Blinda contra saves gravados antes da
	# correção, que guardavam o valor negativo para contas.
	var amount = abs(float(ev.get("amount", 0.0)))
	var money = float(Global.player.get("money", 0.0))
	if money < amount:
		return {"success": false, "message": "Dinheiro insuficiente. Faltam R$ %.2f." % (amount - money)}

	Global.player["money"] = money - amount
	ev["status"] = "paid"
	SaveManager.save_game()
	emit_signal("events_updated")
	_log_info("Conta paga: %s (R$ %.2f)" % [str(ev.get("title", "?")), amount])
	return {"success": true, "message": "Conta paga: R$ %.2f." % amount}

func collect_event(event_id: String) -> Dictionary:
	var ev = _find_event(event_id)
	if ev.is_empty():
		return {"success": false, "message": "Bônus não encontrado."}
	if str(ev.get("status", "")) != "pending":
		return {"success": false, "message": "Esta pendência já foi resolvida."}
	if not bool(ev.get("is_bonus", false)):
		return {"success": false, "message": "Isto é uma conta: use Pagar."}

	# abs(): o sinal vive em is_bonus. Blinda contra saves gravados antes da
	# correção, que guardavam o valor negativo para contas.
	var amount = abs(float(ev.get("amount", 0.0)))
	Global.player["money"] = float(Global.player.get("money", 0.0)) + amount
	ev["status"] = "collected"
	SaveManager.save_game()
	emit_signal("events_updated")
	_log_info("Bônus resgatado: %s (R$ %.2f)" % [str(ev.get("title", "?")), amount])
	return {"success": true, "message": "Bônus resgatado: R$ %.2f." % amount}

# Mantém todas as pendências abertas e só as resoluções mais recentes.
func _prune_resolved(list: Array) -> void:
	var resolved: Array = []
	for i in range(list.size()):
		if str(list[i].get("status", "")) != "pending":
			resolved.append(i)
	var excess = resolved.size() - MAX_RESOLVED_EVENTS
	if excess <= 0:
		return
	# De trás para frente entre os que serão removidos, para os índices
	# menores não se deslocarem antes da hora.
	for i in range(excess - 1, -1, -1):
		list.remove_at(resolved[i])
