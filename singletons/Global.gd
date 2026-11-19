extends Node

var player: Dictionary

# Fome perdida por dia dormido. Comer no mercado/casa e' o que repoe.
const HUNGER_DECAY_PER_MINUTE := 0.02
# Sede perdida por dia dormido. Cai mais rapido que a fome de proposito: zera
# em ~7 dias contra ~17 da fome, e e' o que da' utilidade a's bebidas do
# mercado. Com agua a R$ 5 repondo 25%, sao ~R$ 20/semana.
const THIRST_DECAY_PER_MINUTE := 0.07

# Espelha os thirst_restore de market.gd["Bebidas"]. Serve para migrar saves
# gravados antes da sede existir, onde a bebida entrou como "food" e sem valor
# de sede. Fonte da verdade continua sendo o mercado; se as bebidas virarem
# dados externos, ler a lista de lá em vez de repetir aqui.
# ponytail: duplicacao aceita porque a alternativa e' o Global depender de uma
# cena de UI. Um teste em tests/test_mechanics.gd compara as duas listas.
const DRINK_THIRST := {
	"Água": 25, "Suco": 35, "Café": 15, "Leite": 15, "Chá": 30, "Energético": 20
}

# =============================================================
# PROGRESSAO DE LIBERACAO DOS LUGARES
# O jogo comeca com so' a escola aberta. O escritorio abre depois do minigame
# e o resto da cidade depois da primeira visita ao escritorio. Pular o
# tutorial vai direto para UNLOCK_ALL (ver TutorialManager.skip_tutorial).
# =============================================================
const UNLOCK_SCHOOL_ONLY := 0
const UNLOCK_OFFICE := 1
const UNLOCK_ALL := 2

# Estagio minimo que libera cada lugar. O que nao esta aqui exige UNLOCK_ALL,
# entao um lugar novo ja' nasce trancado ate' o fim do tutorial.
const PLACE_UNLOCK_STAGE := {
	"school": UNLOCK_SCHOOL_ONLY,
	"office": UNLOCK_OFFICE
}

# Espelha TutorialManager.TUTORIAL_DONE. Duplicado porque ensure_player_state()
# roda durante Global._ready(), antes de TutorialManager entrar na arvore.
const LEGACY_TUTORIAL_DONE := 11
# Fracao do % de fome de um alimento que tambem vira stamina.
const STAMINA_PER_FOOD_ENERGY := 0.25

var data_model = {
	"name": "",
	"money": 0.0,
	"saldo": 0.0,
	"poupanca": 0.0,
	"poupanca_rendimento_total": 0.0,
	"week": 1,
	"salary": 200,
	"school_level": 1,
	"position": {
		"x": 180.0,
		"y": 210.0
	},
	"day": 1,
	"hour": 8,
	"return_home_next_day": false,
	"tutorial_step": 1,
	# Ver UNLOCK_* acima. Novo jogo comeca com so' a escola liberada.
	"unlock_stage": UNLOCK_SCHOOL_ONLY,
	# Semanas cujo aviso semanal do tutorial já foi mostrado, para um reload
	# não repetir o que o jogador já leu. Ver TutorialManager.weekly_messages.
	"tutorial_weeks_shown": [],
	# O bloco do tutorial que explica a casa dispara na primeira visita, que
	# pode ser em qualquer semana. Persistido pelo mesmo motivo de
	# tutorial_weeks_shown: `skipped` nao e' salvo, e recarregar traria o
	# bloco de volta. Ver TutorialManager.on_player_entered_home().
	"tutorial_home_shown": false,
	"investments": {},
	"enterprises": {},
	"expense_history": [],
	"spend_today": 0.0,
	"had_no_spend_day": false,
	"no_spend_days_count": 0,
	"positive_days_count": 0,
	"hunger": 110.0,
	"thirst": 110.0,
	"stamina": 110.0,
	"speed": 70.0,
	"home_inventory": {},
	"home_actions_log": [],
	"pending_house_bills": [],
	"house_bill_history": [],
	"pending_events": [],
	# Travas do minigame. Valores padrão já satisfeitos, então a primeira
	# partida começa com a escola liberada. `sessions_played` distingue a
	# corrida de formação inicial (sem limite de níveis) das demais.
	# Espelha MinigameManager.default_progress(), que normaliza saves antigos.
	"minigame_progress": {
		"unlock_week": 1,
		"unlock_day": 0,
		"sessions_played": 0
	},
	# Trava do minigame de moedas do parque (2x/dia). Espelha
	# ParkMinigameManager.default_progress().
	"park_minigame": {
		"day": 0,
		"plays_used": 0
	},
	# Cupom de desconto (0.0 a 1.0) ganho ao acertar o quiz do minigame do
	# parque. Consumido de uma vez na próxima compra do mercado.
	"market_discount": 0.0,
	# Foto do início da semana atual (dinheiro, banco e contas). É o que volta se
	# a semana for repetida. Ver snapshot_week_start()/restore_week_start().
	"week_snapshot": {},
	"last_week_status": {
		"hunger": 110.0,
		"thirst": 110.0,
		"stamina": 110.0
	}
}

var play_time := false
var gameplay_locked := false
var _gameplay_lock_count := 0
var in_school_minigame := false
# Ligada enquanto o jogador está dentro do escritório de consultoria: o relógio
# não corre lá, para dar tempo de ler sem pressa de voltar para casa.
var in_office := false
# Liga durante o minigame do parque: os HUDs (dinheiro/necessidades, relogio,
# missoes) se escondem enquanto isto for true, sobrando so' o timer da sessao.
# Nao e' salvo, igual gameplay_locked: e' estado de execucao, nao de save.
var player_hud_hidden := false
# Ligada por trigger_game_over(). Fome e sede zeradas NÃO chamam mais isso: elas
# desmaiam o jogador (TimeManager.collapse_if_needs_depleted). A trava continua
# aqui para qualquer game over futuro; ela impede que o fluxo do fim de dia siga
# por cima da tela de game-over. Zerada ao comecar/carregar uma partida.
var _game_over := false

func is_game_over() -> bool:
	return _game_over

# Cenas em que o relógio fica parado de propósito. Ponto único: quem religa
# play_time (fechar alerta, despausar, soltar travas) consulta aqui.
func time_frozen_by_scene() -> bool:
	return in_school_minigame or in_office

func lock_gameplay() -> void:
	_gameplay_lock_count += 1
	gameplay_locked = true

func unlock_gameplay() -> void:
	_gameplay_lock_count = max(0, _gameplay_lock_count - 1)
	gameplay_locked = _gameplay_lock_count > 0

# For situations where a lock/unlock pairing may be missed (e.g., during complex
# tutorial flows or unexpected errors), this helper force-releases all locks.
# Use sparingly: prefer pairwise lock_gameplay()/unlock_gameplay(), but calling
# this during the end of the tutorial ensures the player isn't permanently
# prevented from moving.
func force_release_all_gameplay_locks() -> void:
	_gameplay_lock_count = 0
	gameplay_locked = false
	# Also ensure game time resumes if not in a frozen-time scene and not in tutorial
	if not time_frozen_by_scene() and not is_any_tutorial_active():
		play_time = true
	print("Global: force released all gameplay locks")

func unlock_stage() -> int:
	if player == null:
		return UNLOCK_SCHOOL_ONLY
	return int(player.get("unlock_stage", UNLOCK_SCHOOL_ONLY))

func is_tutorial_active() -> bool:
	if player == null or typeof(player) != TYPE_DICTIONARY:
		return false
	if has_node("/root/TutorialManager"):
		var tm = get_node("/root/TutorialManager")
		if tm != null and tm.skipped:
			return false
	return int(player.get("tutorial_step", 1)) < LEGACY_TUTORIAL_DONE and unlock_stage() < UNLOCK_ALL

func is_any_tutorial_active() -> bool:
	if is_tutorial_active():
		return true
	if has_node("/root/TutorialManager"):
		var tm = get_node("/root/TutorialManager")
		if tm != null and tm.has_method("is_any_tutorial_active"):
			return tm.is_any_tutorial_active()
	return false

# So' avanca. Um evento fora de ordem nao pode retrancar o que ja' abriu.
func set_unlock_stage(stage: int) -> void:
	if player == null:
		return
	player["unlock_stage"] = max(unlock_stage(), stage)

func is_place_unlocked(place_id: String) -> bool:
	return unlock_stage() >= int(PLACE_UNLOCK_STAGE.get(place_id, UNLOCK_ALL))

# Texto mostrado no painel da porta e no alerta de porta trancada.
func place_lock_reason(place_id: String) -> String:
	if is_place_unlocked(place_id):
		return ""
	if int(PLACE_UNLOCK_STAGE.get(place_id, UNLOCK_ALL)) == UNLOCK_OFFICE:
		return "Ainda não. Termine sua formação na escola primeiro."
	if unlock_stage() == UNLOCK_SCHOOL_ONLY:
		return "Ainda não. Comece pela escola."
	return "Ainda não. Visite o escritório de consultoria primeiro."

func _new_player_data() -> Dictionary:
	var new_player = data_model.duplicate(true)
	new_player["position"] = data_model["position"].duplicate(true)
	new_player["last_week_status"] = data_model["last_week_status"].duplicate(true)
	return new_player

func ensure_player_state() -> void:
	if player == null:
		player = _new_player_data()
	for key in ["name", "money", "saldo", "poupanca", "poupanca_rendimento_total", "week", "salary", "school_level", "day", "hour", "tutorial_step", "hunger", "thirst", "stamina", "speed", "spend_today", "had_no_spend_day", "no_spend_days_count", "positive_days_count", "tutorial_home_shown", "market_discount"]:
		if not player.has(key):
			player[key] = data_model.get(key, 0)
	if float(player.get("speed", 70.0)) <= 0.0:
		player["speed"] = 70.0
	# Save anterior a' progressao de lugares: nao tem "unlock_stage". Trancar a
	# cidade de quem ja' estava jogando pareceria um bug, entao esses saves
	# entram com tudo aberto e o tutorial dado por encerrado.
	if not player.has("unlock_stage"):
		player["unlock_stage"] = UNLOCK_ALL
		# 8 era o FINAL_STEP de quando o tutorial acabava no tour do mundo, e
		# esse valor ficava salvo. Hoje 8 e' a apresentacao do escritorio, entao
		# sem isto um save antigo repetiria o tutorial. Numero literal de
		# proposito: TutorialManager e' autoload posterior a Global e ainda nao
		# existe quando esta funcao roda.
		if int(player.get("tutorial_step", 1)) >= 8:
			player["tutorial_step"] = LEGACY_TUTORIAL_DONE
			player["tutorial_home_shown"] = true
	# Durante o tutorial inicial, os status ficam travados em 100% até a liberação do mapa
	if is_tutorial_active():
		player["hunger"] = 110.0
		player["thirst"] = 110.0
		player["stamina"] = 110.0
	if not player.has("position") or typeof(player["position"]) != TYPE_DICTIONARY:
		player["position"] = {"x": 180.0, "y": 210.0}
	if not player.has("investments"):
		player["investments"] = {}
	if not player.has("enterprises"):
		player["enterprises"] = {}
	if not player.has("expense_history"):
		player["expense_history"] = []
	if not player.has("home_inventory"):
		player["home_inventory"] = {}
	if not player.has("home_actions_log"):
		player["home_actions_log"] = []
	if not player.has("pending_house_bills") or typeof(player["pending_house_bills"]) != TYPE_ARRAY:
		player["pending_house_bills"] = []
	if not player.has("house_bill_history") or typeof(player["house_bill_history"]) != TYPE_ARRAY:
		player["house_bill_history"] = []
	# Inicializa lista de eventos pendentes (contas / bônus) se não existir
	if not player.has("pending_events"):
		player["pending_events"] = []
	if not player.has("minigame_progress") or typeof(player["minigame_progress"]) != TYPE_DICTIONARY:
		player["minigame_progress"] = MinigameManager.default_progress()
	if not player.has("park_minigame") or typeof(player["park_minigame"]) != TYPE_DICTIONARY:
		player["park_minigame"] = ParkMinigameManager.default_progress()
	if not player.has("tutorial_weeks_shown") or typeof(player["tutorial_weeks_shown"]) != TYPE_ARRAY:
		player["tutorial_weeks_shown"] = []
	if not player.has("last_week_status"):
		player["last_week_status"] = {"hunger": 110.0, "thirst": 110.0, "stamina": 110.0}
	player["money"] = float(player.get("money", 0.0))
	player["saldo"] = float(player.get("saldo", 0.0))
	player["poupanca"] = float(player.get("poupanca", 0.0))
	player["poupanca_rendimento_total"] = float(player.get("poupanca_rendimento_total", 0.0))
	player["hunger"] = clampf(float(player.get("hunger", 110.0)), 0.0, 110.0)
	player["thirst"] = clampf(float(player.get("thirst", 110.0)), 0.0, 110.0)
	player["stamina"] = clampf(float(player.get("stamina", 110.0)), 0.0, 110.0)
	# Save anterior à foto da semana: adota o estado de agora como "início",
	# melhor do que deixar uma semana repetida sem ter para onde voltar.
	if typeof(player.get("week_snapshot", null)) != TYPE_DICTIONARY or player["week_snapshot"].is_empty():
		snapshot_week_start()
	normalize_home_inventory()

func normalize_home_inventory() -> void:
	if player == null:
		return
	var normalized := {}
	for key in player.get("home_inventory", {}).keys():
		var item = player["home_inventory"][key]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var item_name = str(item.get("name", key)).strip_edges()
		if item_name == "":
			item_name = str(key)
		var normalized_key = item_name.to_lower()
		var category = str(item.get("category", "food"))
		var thirst = float(item.get("thirst", 0.0))
		# Migracao de saves anteriores a' sede: as bebidas eram gravadas como
		# "food" e sem valor de sede, entao ficavam presas como comida ruim e o
		# botao BEBER nao acharia nada. Remapeadas por nome uma vez aqui.
		# O item e' gravado com name.capitalize(), que troca "_" por espaco
		# ("hot_chocolate" -> "Hot Chocolate"), entao a chave volta a ter "_"
		# para casar com DRINK_THIRST, que espelha market.gd.
		var drink_key = normalized_key.replace(" ", "_")
		for dname in DRINK_THIRST.keys():
			if dname.to_lower() == normalized_key or dname.to_lower() == drink_key:
				category = "drink"
				if thirst <= 0.0:
					thirst = float(DRINK_THIRST[dname])
				break
		normalized[normalized_key] = {
			"name": item_name,
			"quantity": int(max(0, item.get("quantity", 0))),
			"category": category,
			# ATENCAO: esta funcao reconstroi cada item do zero, e roda em
			# add_home_inventory_item(), get_home_inventory_items() e
			# ensure_player_state(). Todo campo novo do item precisa ser
			# repetido aqui, senao e' apagado silenciosamente.
			"energy": float(item.get("energy", 0.0)),
			"thirst": thirst,
			"happiness": float(item.get("happiness", 0.0))
		}
	player["home_inventory"] = normalized

func new_game(name: String, money: float) -> void:
	SaveManager.delete_save()
	_game_over = false
	in_school_minigame = false
	in_office = false
	player = _new_player_data()
	player["name"] = name
	player["money"] = float(money)
	player["saldo"] = 0.0
	player["poupanca"] = 0.0
	player["poupanca_rendimento_total"] = 0.0
	player["week"] = 1
	player["school_level"] = 1
	player["salary"] = max(200, int(money))
	player["position"]["x"] = 180.0
	player["position"]["y"] = 210.0
	player["day"] = 1
	player["hour"] = 8
	player["tutorial_step"] = 1
	player["tutorial_weeks_shown"] = []
	player["unlock_stage"] = UNLOCK_SCHOOL_ONLY
	player["investments"] = {}
	player["expense_history"] = []
	player["spend_today"] = 0.0
	player["no_spend_days_count"] = 0
	player["positive_days_count"] = 0
	player["hunger"] = 110.0
	player["thirst"] = 110.0
	player["stamina"] = 110.0
	player["speed"] = 70.0
	player["home_inventory"] = {}
	player["home_actions_log"] = []
	player["pending_house_bills"] = []
	player["house_bill_history"] = []
	player["pending_events"] = []
	player["minigame_progress"] = MinigameManager.default_progress()
	player["park_minigame"] = ParkMinigameManager.default_progress()
	player["market_discount"] = 0.0
	player["tutorial_home_shown"] = false
	player["last_week_status"] = {"hunger": 110.0, "thirst": 110.0, "stamina": 110.0}
	snapshot_week_start()

	# Reset FIIManager state to ensure new game doesn't inherit old portfolio
	FIIManager.reset()
	MissionManager.reset_progress()
	# TimeManager é autoload e sobrevive a um game over: sem isto, day_end_pending
	# preso em true (deixado por uma morte de fome/sede) travava o relógio da
	# partida nova inteira.
	TimeManager.reset()
	AlertManager.reset()
	TutorialManager.reset()

	TimeManager.update_time()
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")

func load_data() -> void:
	_game_over = false
	var saved_data = SaveManager.load_game()
	if saved_data is Dictionary and not saved_data.is_empty():
		player = saved_data
		ensure_player_state()
		print("game loaded")
	else:
		player = _new_player_data()
		ensure_player_state()
		print("game loaded")

const DAYS_PER_WEEK := 5

# Dia absoluto desde o começo da partida. player["day"] vai de 1 a 5 e reseta
# na virada de semana, então não serve para cooldown: um cooldown de 2 dias
# iniciado no dia 4 precisa continuar valendo no dia 1 da semana seguinte.
func get_absolute_day() -> int:
	return (int(player.get("week", 1)) - 1) * DAYS_PER_WEEK + int(player.get("day", 1))

func update_salary() -> void:
	var base_salary = 200.0
	player["salary"] = int(base_salary * (1.0 + (float(player["school_level"]) - 1.0) * 0.5))

func get_paid() -> void:
	player["money"] = float(player["money"]) + float(player["salary"])

# count_as_daily_spend = false para cobranças automáticas da virada de semana:
# elas acontecem já no dia 1 da semana nova e não podem estragar o "dia sem
# gastar" (missão sem_gastar) de um dia que o jogador ainda nem jogou.
func register_expense(item_name: String, category: String, price: float, day: int, week: int, count_as_daily_spend: bool = true) -> void:
	if player == null:
		return
	var history = player.get("expense_history", [])
	history.append({
		"item": item_name,
		"category": category,
		"price": float(price),
		"day": day,
		"week": week
	})
	player["expense_history"] = history
	if count_as_daily_spend:
		player["spend_today"] = float(player.get("spend_today", 0.0)) + float(price)

# =============================================================
# FUNDOS: dinheiro na mão + saldo no banco + poupança
# =============================================================
func total_funds() -> float:
	return float(player.get("money", 0.0)) + float(player.get("saldo", 0.0)) + float(player.get("poupanca", 0.0))

# Cobra `amount` tirando primeiro da carteira, depois do saldo no banco e por
# fim da poupança (alta liquidez diária D+0, conforme ensinado no nível 3 do
# escritório). Devolve false (sem mexer em nada) se os fundos totais não cobrem.
func charge_funds(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if total_funds() + 0.001 < amount:
		return false
	var remaining := amount
	var money := float(player.get("money", 0.0))
	var from_wallet := minf(money, remaining)
	player["money"] = snappedf(money - from_wallet, 0.01)
	remaining -= from_wallet

	if remaining > 0.0001:
		var saldo := float(player.get("saldo", 0.0))
		var from_saldo := minf(saldo, remaining)
		player["saldo"] = snappedf(saldo - from_saldo, 0.01)
		remaining -= from_saldo

	if remaining > 0.0001:
		var poupanca := float(player.get("poupanca", 0.0))
		var from_poupanca := minf(poupanca, remaining)
		player["poupanca"] = snappedf(poupanca - from_poupanca, 0.01)
		remaining -= from_poupanca

	return true

# Transfere dinheiro do saldo em conta para a poupança
func apply_poupanca(amount: float) -> bool:
	if amount <= 0.0:
		return false
	var saldo := float(player.get("saldo", 0.0))
	if saldo + 0.001 < amount:
		return false
	player["saldo"] = snappedf(saldo - amount, 0.01)
	player["poupanca"] = snappedf(float(player.get("poupanca", 0.0)) + amount, 0.01)
	return true

# Resgata dinheiro da poupança de volta para o saldo em conta corrente
func withdraw_poupanca(amount: float) -> bool:
	if amount <= 0.0:
		return false
	var poupanca := float(player.get("poupanca", 0.0))
	if poupanca + 0.001 < amount:
		return false
	player["poupanca"] = snappedf(poupanca - amount, 0.01)
	player["saldo"] = snappedf(float(player.get("saldo", 0.0)) + amount, 0.01)
	return true

# =============================================================
# FOTO DO INÍCIO DA SEMANA
# Repetir uma semana (missão falhada ou contas que o jogador não consegue
# quitar) devolve o jogador ao que ele tinha ao começar a semana: dinheiro,
# banco e o estado das contas. As contas entram na foto porque, sem elas,
# pagar uma conta na tentativa fracassada devolveria o dinheiro E deixaria a
# conta paga — dívida perdoada de graça.
# Compras (estoque, FIIs, empreendimentos) NÃO voltam: ver ECONOMY_BALANCE_PLAN.
# =============================================================
func snapshot_week_start() -> void:
	if player == null:
		return
	player["week_snapshot"] = {
		"money": float(player.get("money", 0.0)),
		"saldo": float(player.get("saldo", 0.0)),
		"poupanca": float(player.get("poupanca", 0.0)),
		"poupanca_rendimento_total": float(player.get("poupanca_rendimento_total", 0.0)),
		"pending_house_bills": player.get("pending_house_bills", []).duplicate(true),
		"house_bill_history": player.get("house_bill_history", []).duplicate(true),
		"pending_events": player.get("pending_events", []).duplicate(true),
		"home_inventory": player.get("home_inventory", {}).duplicate(true)
	}

func restore_week_start() -> void:
	if player == null:
		return
	var snap = player.get("week_snapshot", {})
	if typeof(snap) != TYPE_DICTIONARY or snap.is_empty():
		return
	player["money"] = float(snap.get("money", player.get("money", 0.0)))
	player["saldo"] = float(snap.get("saldo", player.get("saldo", 0.0)))
	player["poupanca"] = float(snap.get("poupanca", player.get("poupanca", 0.0)))
	player["poupanca_rendimento_total"] = float(snap.get("poupanca_rendimento_total", player.get("poupanca_rendimento_total", 0.0)))
	player["pending_house_bills"] = snap.get("pending_house_bills", []).duplicate(true)
	player["house_bill_history"] = snap.get("house_bill_history", []).duplicate(true)
	player["pending_events"] = snap.get("pending_events", []).duplicate(true)
	if snap.has("home_inventory") and typeof(snap["home_inventory"]) == TYPE_DICTIONARY:
		player["home_inventory"] = snap["home_inventory"].duplicate(true)
		normalize_home_inventory()

func _food_energy_for(item_name: String, base_price: float) -> float:
	var price_factor = clamp(base_price / 20.0, 0.5, 3.0)
	var item_name_lower = item_name.to_lower()
	if "milk" in item_name_lower or "bread" in item_name_lower or "rice" in item_name_lower or "apple" in item_name_lower or "banana" in item_name_lower:
		return 18.0 * price_factor
	if "meat" in item_name_lower or "fish" in item_name_lower or "hamburger" in item_name_lower:
		return 26.0 * price_factor
	if "juice" in item_name_lower or "coffee" in item_name_lower or "tea" in item_name_lower or "milkshake" in item_name_lower:
		return 14.0 * price_factor
	return 12.0 * price_factor

func _food_happiness_for(item_name: String, base_price: float) -> float:
	var price_factor = clamp(base_price / 25.0, 0.5, 3.0)
	var item_name_lower = item_name.to_lower()
	if "cake" in item_name_lower or "milkshake" in item_name_lower or "beer" in item_name_lower or "wine" in item_name_lower:
		return 18.0 * price_factor
	if "bread" in item_name_lower or "apple" in item_name_lower or "banana" in item_name_lower or "rice" in item_name_lower:
		return 10.0 * price_factor
	return 12.0 * price_factor

func add_home_inventory_item(item_name: String, quantity: int = 1, category: String = "food", hunger_restore: int = 0, thirst_restore: int = 0) -> void:
	if player == null:
		return
	var safe_name = str(item_name).strip_edges()
	if safe_name == "":
		return
	var entry = player.get("home_inventory", {})
	var key = safe_name.to_lower()
	if not entry.has(key):
		entry[key] = {
			"name": safe_name,
			"quantity": 0,
			"category": category,
			"energy": 0.0,
			"thirst": 0.0,
			"happiness": 0.0
		}
	var item = entry[key]
	var base_price = 10.0
	# Comida e bebida guardam os dois restauros: e' o item que carrega quanto
	# repoe de cada necessidade, e consume_item() aplica os dois.
	if category == "food" or category == "drink":
		base_price = max(5.0, float(item.get("price", 10.0)))
		if thirst_restore > 0:
			item["thirst"] = float(thirst_restore)
		if hunger_restore > 0:
			# Use provided hunger_restore value
			item["energy"] = float(hunger_restore)
			item["happiness"] = float(hunger_restore) * 0.1  # Small mood bonus based on food quality
		else:
			# Calculate from name and price (backwards compatibility)
			item["energy"] = _food_energy_for(safe_name, base_price)
			item["happiness"] = _food_happiness_for(safe_name, base_price)
	item["name"] = safe_name
	item["category"] = category
	item["quantity"] = int(item.get("quantity", 0)) + int(quantity)
	entry[key] = item
	player["home_inventory"] = entry
	normalize_home_inventory()

func get_home_inventory_items() -> Array:
	if player == null:
		return []
	normalize_home_inventory()
	var items = []
	for key in player.get("home_inventory", {}).keys():
		var item = player["home_inventory"][key]
		if typeof(item) == TYPE_DICTIONARY and int(item.get("quantity", 0)) > 0:
			items.append(item)
	items.sort_custom(func(a, b): return str(a.get("name", "")).nocasecmp_to(str(b.get("name", ""))) < 0)
	return items

# Consumo de um item do estoque da casa. Uma funcao para comer e beber: o que
# muda entre as duas e' a categoria filtrada e a necessidade que decide qual
# item e' o "melhor". Os ganhos aplicados sao sempre os DOIS do item, porque
# leite mata um pouco de sede e milkshake mata um pouco de fome; quem escolhe
# a categoria e' o botao da casa.
#
# need_key: "hunger" (campo "energy" do item) ou "thirst" (campo "thirst").
const _NEED_FIELD := {"hunger": "energy", "thirst": "thirst"}

func consume_item(category: String, need_key: String, action: Dictionary) -> Dictionary:
	if player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	# >= e nao ==: depois de um restauro parcial o valor fica em 99.999997 e a
	# comparacao exata de float nunca casaria.
	if float(player.get(need_key, 110.0)) >= 110.0:
		return {"success": false, "message": str(action["already_full"])}

	var rank_field = str(_NEED_FIELD[need_key])
	var inventory = player.get("home_inventory", {})
	var chosen_name = ""
	var chosen_item = null
	for key in inventory.keys():
		var item = inventory[key]
		if int(item.get("quantity", 0)) <= 0:
			continue
		if str(item.get("category", "food")) != category:
			continue
		if chosen_item == null or float(item.get(rank_field, 0.0)) > float(chosen_item.get(rank_field, 0.0)):
			chosen_name = key
			chosen_item = item
	if chosen_item == null:
		return {"success": false, "message": str(action["empty_stock"])}
	return _consume_chosen(chosen_name, action)

# Consome exatamente o item escolhido pelo jogador (card da casa), em vez do
# "melhor" que consume_item() escolhe sozinha. `item_key` é a chave do estoque
# (nome em minúsculas, ver normalize_home_inventory). A categoria do item decide
# se conta como comer ou beber: tempo gasto, mensagens e qual necessidade já
# cheia bloqueia o consumo.
func consume_specific_item(item_key: String) -> Dictionary:
	if player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	var inventory = player.get("home_inventory", {})
	if not inventory.has(item_key) or int(inventory[item_key].get("quantity", 0)) <= 0:
		return {"success": false, "message": "Você não tem mais este item."}
	var is_drink := str(inventory[item_key].get("category", "food")) == "drink"
	var action: Dictionary = DRINK_ACTION if is_drink else EAT_ACTION
	var need_key := "thirst" if is_drink else "hunger"
	if float(player.get(need_key, 110.0)) >= 110.0:
		return {"success": false, "message": str(action["already_full"])}
	return _consume_chosen(item_key, action)

# Tira 1 unidade do estoque, aplica os ganhos do item e gasta o tempo da ação.
# Parte comum de consume_item() e consume_specific_item().
func _consume_chosen(chosen_name: String, action: Dictionary) -> Dictionary:
	var inventory = player.get("home_inventory", {})
	var chosen_item = inventory[chosen_name]
	inventory[chosen_name]["quantity"] = int(inventory[chosen_name].get("quantity", 0)) - 1
	if inventory[chosen_name]["quantity"] <= 0:
		inventory.erase(chosen_name)
	player["home_inventory"] = inventory

	# "energy" guarda o % de fome que o item repoe e "thirst" o % de sede (ver
	# market.gd). A stamina ganha um quarto da fome: comer ajuda, mas quem
	# recupera stamina e' dormir.
	var hunger_gain = float(chosen_item.get("energy", 0.0))
	var thirst_gain = float(chosen_item.get("thirst", 0.0))
	player["hunger"] = clampf(float(player.get("hunger", 110.0)) + hunger_gain, 0.0, 110.0)
	player["thirst"] = clampf(float(player.get("thirst", 110.0)) + thirst_gain, 0.0, 110.0)
	player["stamina"] = clampf(float(player.get("stamina", 110.0)) + hunger_gain * STAMINA_PER_FOOD_ENERGY, 0.0, 110.0)

	var item_label = str(chosen_item.get("name", chosen_name))
	player["home_actions_log"] = player.get("home_actions_log", [])
	player["home_actions_log"].append({
		"type": str(action["log_type"]),
		"item": item_label,
		"day": player.get("day", 1),
		"week": player.get("week", 1),
		"hunger": player["hunger"],
		"thirst": player["thirst"],
		"stamina": player["stamina"]
	})
	TimeManager.spend_hours(float(action["time_cost"]))
	return {"success": true, "message": str(action["done"]) % item_label, "item": item_label}

# Fachadas. consume_food() e' mantida porque home.gd e tests/test_mechanics.gd
# ja' a chamam.
const EAT_ACTION := {
	"already_full": "Você não está com fome.",
	"empty_stock": "Sem comida no estoque.",
	"done": "Você comeu %s.",
	"log_type": "eat",
	"time_cost": 0.5
}

const DRINK_ACTION := {
	"already_full": "Você não está com sede.",
	"empty_stock": "Sem bebida no estoque.",
	"done": "Você bebeu %s.",
	"log_type": "drink",
	# Beber custa metade do tempo de comer.
	"time_cost": 0.25
}

func consume_food() -> Dictionary:
	return consume_item("food", "hunger", EAT_ACTION)

func consume_drink() -> Dictionary:
	return consume_item("drink", "thirst", DRINK_ACTION)

func apply_home_action(action_name: String, hunger_delta: float, stamina_delta: float, time_cost: float = 0.0, thirst_delta: float = 0.0) -> Dictionary:
	if player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	if is_tutorial_active():
		player["hunger"] = 110.0
		player["thirst"] = 110.0
		player["stamina"] = 110.0
		return {"success": true, "message": "%s" % action_name}

	var current_hunger := float(player.get("hunger", 110.0))
	if hunger_delta < 0.0 and abs(hunger_delta) > current_hunger:
		return {"success": false, "message": "Você está com muita fome para realizar esta ação."}

	var current_thirst := float(player.get("thirst", 110.0))
	if thirst_delta < 0.0 and abs(thirst_delta) > current_thirst:
		return {"success": false, "message": "Você está com muita sede para realizar esta ação."}

	player["hunger"] = clampf(current_hunger + float(hunger_delta), 0.0, 110.0)
	if thirst_delta != 0.0:
		player["thirst"] = clampf(current_thirst + float(thirst_delta), 0.0, 110.0)
	player["stamina"] = clampf(float(player.get("stamina", 110.0)) + float(stamina_delta), 0.0, 110.0)
	var log = player.get("home_actions_log", [])
	log.append({
		"type": action_name,
		"day": player.get("day", 1),
		"week": player.get("week", 1),
		"hunger": player["hunger"],
		"thirst": player.get("thirst", 110.0),
		"stamina": player["stamina"],
		"time_cost": float(time_cost)
	})
	player["home_actions_log"] = log
	TimeManager.spend_hours(time_cost)
	# A ação pode ter zerado fome/sede (o guard acima só recusa quando o custo
	# passa do que há, e custo igual ao que há deixa em zero). Zerar não mata:
	# o jogador desmaia, como na exaustão (TimeManager.collapse_if_needs_depleted).
	var collapse_message := TimeManager.collapse_if_needs_depleted()
	if collapse_message != "":
		return {"success": false, "message": collapse_message}
	return {"success": true, "message": "%s" % action_name}

# Cai fome e sede (uma fatia por minuto de jogo, chamada por TimeManager). Não
# mata: quando uma chega a zero, quem decide é TimeManager.collapse_if_needs_depleted(),
# que desmaia o jogador. Devolve false se alguma necessidade está zerada.
func decay_need_state() -> bool:
	if player == null:
		return true
	if is_tutorial_active():
		player["hunger"] = 110.0
		player["thirst"] = 110.0
		player["stamina"] = 110.0
		return true
	player["hunger"] = clampf(float(player.get("hunger", 110.0)) - HUNGER_DECAY_PER_MINUTE, 0.0, 110.0)
	player["thirst"] = clampf(float(player.get("thirst", 110.0)) - 	THIRST_DECAY_PER_MINUTE, 0.0, 110.0)
	return depleted_needs().is_empty()

# Necessidades zeradas agora: "hunger" e/ou "thirst". Vazio durante o tutorial,
# em que elas ficam travadas em 110.
func depleted_needs() -> Array:
	var result: Array = []
	if player == null or is_tutorial_active():
		return result
	if float(player.get("hunger", 110.0)) <= 0.0:
		result.append("hunger")
	if float(player.get("thirst", 110.0)) <= 0.0:
		result.append("thirst")
	return result

# Devolve as necessidades zeradas a `value`. Sem isto o jogador acordaria no dia
# seguinte ainda com a necessidade em zero e desmaiaria de novo no primeiro minuto.
func restore_depleted_needs(value: float) -> void:
	for need in depleted_needs():
		player[need] = value

# Ponto unico de game-over. O alerta so' e' aberto uma vez: sem a trava, um
# chamador em _process reabriria a caixa a cada quadro e o botao OK nunca
# pareceria funcionar (era o bug 8.1).
func trigger_game_over(message: String) -> void:
	if _game_over:
		return
	_game_over = true
	play_time = false
	SaveManager.delete_save()
	AlertManager.alert(message, false, Callable(self, "_return_to_main_menu"))

const WEEK_STATUS_PENALTY := 25.0

# Quanto evaluate_week_status() tiraria agora, sem aplicar. A cobrança automática
# de contas precisa contar com isso ao checar se os fundos cobrem tudo; senão a
# penalidade, que roda depois da checagem, deixaria o saldo curto na hora de
# cobrar.
func week_status_penalty_preview() -> float:
	if player == null or is_tutorial_active():
		return 0.0
	if float(player.get("hunger", 110.0)) < 35.0 or float(player.get("thirst", 110.0)) < 35.0 or float(player.get("stamina", 110.0)) < 35.0:
		return WEEK_STATUS_PENALTY
	return 0.0

func evaluate_week_status() -> Dictionary:
	if player == null:
		return {"penalty": 0.0, "message": "Sem avaliação"}
	if is_tutorial_active():
		player["hunger"] = 110.0
		player["thirst"] = 110.0
		player["stamina"] = 110.0
		player["last_week_status"] = {"hunger": 110.0, "thirst": 110.0, "stamina": 110.0}
		return {"penalty": 0.0, "message": "Sem avaliação durante o tutorial"}
	var hunger = float(player.get("hunger", 110.0))
	var thirst = float(player.get("thirst", 110.0))
	var stamina = float(player.get("stamina", 110.0))
	player["last_week_status"] = {"hunger": hunger, "thirst": thirst, "stamina": stamina}
	var penalty = 0.0
	if hunger < 35.0 or thirst < 35.0 or stamina < 35.0:
		penalty = WEEK_STATUS_PENALTY
		# Piso em zero: sem isto a penalidade empurrava o saldo cada vez mais
		# fundo no negativo, sem nenhum caminho de recuperação além do salário.
		player["money"] = max(0.0, float(player.get("money", 0.0)) - penalty)
		player["hunger"] = clampf(hunger + 10.0, 0.0, 110.0)
		player["thirst"] = clampf(thirst + 10.0, 0.0, 110.0)
		player["stamina"] = clampf(stamina + 10.0, 0.0, 110.0)
	return {"penalty": penalty, "message": "Status da semana avaliado."}

func reset_game_state_to_menu() -> void:
	_game_over = false
	in_school_minigame = false
	in_office = false
	player_hud_hidden = false
	play_time = false
	force_release_all_gameplay_locks()
	player = _new_player_data()
	FIIManager.reset()
	MissionManager.reset_progress()
	TimeManager.reset()
	AlertManager.reset()
	TutorialManager.reset()

func _return_to_main_menu() -> void:
	SaveManager.delete_save()
	reset_game_state_to_menu()
	if get_tree() != null:
		TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")
		
func lose_speed() -> bool :
	player["speed"] -= 0.35
	if player["speed"] < 0:
		player["speed"] = 0.0
		return true
	return false

func reestore_speed() -> void:
	player["speed"] = 70.0
	
func _ready() -> void:
	ensure_player_state()
	load_data()
	FIIManager.load_data()
