extends Node

var player: Dictionary

var data_model = {
	"name": "",
	"money": 0.0,
	"saldo": 0.0,
	"week": 1,
	"salary": 200,
	"school_level": 1,
	"position": {
		"x": 180.0,
		"y": 210.0
	},
	"day": 1,
	"hour": 8,
	"tutorial_step": 1,
	"investments": {},
	"enterprises": {},
	"expense_history": [],
	"spend_today": 0.0,
	"positive_days_count": 0,
	"hunger": 100.0,
	"happiness": 100.0,
	"home_inventory": {},
	"home_actions_log": [],
	"pending_events": [],
	"last_week_status": {
		"hunger": 100.0,
		"happiness": 100.0
	}
}

var play_time := false
var gameplay_locked := false
var _gameplay_lock_count := 0

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
	# Also ensure game time resumes
	play_time = true
	print("Global: force released all gameplay locks")

func _new_player_data() -> Dictionary:
	var new_player = data_model.duplicate(true)
	new_player["position"] = data_model["position"].duplicate(true)
	new_player["last_week_status"] = data_model["last_week_status"].duplicate(true)
	return new_player

func ensure_player_state() -> void:
	if player == null:
		player = _new_player_data()
	for key in ["money", "saldo", "week", "salary", "school_level", "day", "hour", "tutorial_step", "hunger", "happiness", "spend_today", "positive_days_count"]:
		if not player.has(key):
			player[key] = data_model.get(key, 0)
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
	# Inicializa lista de eventos pendentes (contas / bônus) se não existir
	if not player.has("pending_events"):
		player["pending_events"] = []
	if not player.has("last_week_status"):
		player["last_week_status"] = {"hunger": 100.0, "happiness": 100.0}
	player["money"] = float(player.get("money", 0.0))
	player["saldo"] = float(player.get("saldo", 0.0))
	player["hunger"] = clampf(float(player.get("hunger", 100.0)), 0.0, 100.0)
	player["happiness"] = clampf(float(player.get("happiness", 100.0)), 0.0, 100.0)
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
		normalized[normalized_key] = {
			"name": item_name,
			"quantity": int(max(0, item.get("quantity", 0))),
			"category": str(item.get("category", "food")),
			"energy": float(item.get("energy", 0.0)),
			"happiness": float(item.get("happiness", 0.0))
		}
	player["home_inventory"] = normalized

func new_game(name: String, money: float) -> void:
	SaveManager.delete_save()
	player = _new_player_data()
	player["name"] = name
	player["money"] = float(money)
	player["saldo"] = 0.0
	player["week"] = 1
	player["school_level"] = 1
	player["salary"] = max(200, int(money))
	player["position"]["x"] = 180.0
	player["position"]["y"] = 210.0
	player["day"] = 1
	player["hour"] = 8
	player["tutorial_step"] = 1
	player["investments"] = {}
	player["expense_history"] = []
	player["spend_today"] = 0.0
	player["positive_days_count"] = 0
	player["hunger"] = 100.0
	player["happiness"] = 100.0
	player["home_inventory"] = {}
	player["home_actions_log"] = []
	player["pending_events"] = []
	player["last_week_status"] = {"hunger": 100.0, "happiness": 100.0}

	TimeManager.update_time()
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")

func load_data() -> void:
	var saved_data = SaveManager.load_game()
	if saved_data is Dictionary and not saved_data.is_empty():
		player = saved_data
		ensure_player_state()
		print("game loaded")
	else:
		player = _new_player_data()
		ensure_player_state()
		print("game loaded")

func update_salary() -> void:
	var base_salary = 200.0
	player["salary"] = int(base_salary * (1.0 + (float(player["school_level"]) - 1.0) * 0.5))

func get_paid() -> void:
	player["money"] = float(player["money"]) + float(player["salary"])

func register_expense(item_name: String, category: String, price: float, day: int, week: int) -> void:
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
	player["spend_today"] = float(player.get("spend_today", 0.0)) + float(price)

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

func add_home_inventory_item(item_name: String, quantity: int = 1, category: String = "food") -> void:
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
			"happiness": 0.0
		}
	var item = entry[key]
	var base_price = 10.0
	if category == "food":
		base_price = max(5.0, float(item.get("price", 10.0)))
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

func consume_food() -> Dictionary:
	if player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	var inventory = player.get("home_inventory", {})
	var chosen_name = ""
	var chosen_item = null
	for key in inventory.keys():
		var item = inventory[key]
		if item.get("quantity", 0) <= 0:
			continue
		if item.get("category", "food") != "food":
			continue
		if chosen_item == null or float(item.get("energy", 0.0)) > float(chosen_item.get("energy", 0.0)):
			chosen_name = key
			chosen_item = item
	if chosen_item == null:
		return {"success": false, "message": "SEM COMIDA NO ESTOQUE."}
	inventory[chosen_name]["quantity"] = int(inventory[chosen_name].get("quantity", 0)) - 1
	if inventory[chosen_name]["quantity"] <= 0:
		inventory.erase(chosen_name)
	player["home_inventory"] = inventory
	var energy_gain = float(chosen_item.get("energy", 15.0))
	var happiness_gain = float(chosen_item.get("happiness", 5.0))
	player["hunger"] = clampf(float(player.get("hunger", 100.0)) + energy_gain, 0.0, 100.0)
	player["happiness"] = clampf(float(player.get("happiness", 100.0)) + happiness_gain * 0.35, 0.0, 100.0)
	player["home_actions_log"] = player.get("home_actions_log", [])
	player["home_actions_log"].append({
		"type": "eat",
		"item": chosen_item.get("name", chosen_name),
		"day": player.get("day", 1),
		"week": player.get("week", 1),
		"hunger": player["hunger"],
		"happiness": player["happiness"]
	})
	TimeManager.spend_hours(0.5)
	return {"success": true, "message": "Você comeu %s." % chosen_item.get("name", chosen_name), "item": chosen_item.get("name", chosen_name)}

func apply_home_action(action_name: String, hunger_delta: float, happiness_delta: float, time_cost: float = 0.0) -> Dictionary:
	if player == null:
		return {"success": false, "message": "Estado do jogador não inicializado."}
	player["hunger"] = clampf(float(player.get("hunger", 100.0)) + float(hunger_delta), 0.0, 100.0)
	player["happiness"] = clampf(float(player.get("happiness", 100.0)) + float(happiness_delta), 0.0, 100.0)
	var log = player.get("home_actions_log", [])
	log.append({
		"type": action_name,
		"day": player.get("day", 1),
		"week": player.get("week", 1),
		"hunger": player["hunger"],
		"happiness": player["happiness"],
		"time_cost": float(time_cost)
	})
	player["home_actions_log"] = log
	TimeManager.spend_hours(time_cost)
	return {"success": true, "message": "%s" % action_name}

func decay_need_state() -> void:
	if player == null:
		return
	player["hunger"] = clampf(float(player.get("hunger", 100.0)) - 6.0, 0.0, 100.0)
	player["happiness"] = clampf(float(player.get("happiness", 100.0)) - 4.0, 0.0, 100.0)
	if player["hunger"] <= 25.0:
		player["happiness"] = clampf(float(player.get("happiness", 100.0)) - 6.0, 0.0, 100.0)
	if player["happiness"] <= 20.0:
		player["hunger"] = clampf(float(player.get("hunger", 100.0)) - 4.0, 0.0, 100.0)

func evaluate_week_status() -> Dictionary:
	if player == null:
		return {"penalty": 0.0, "message": "Sem avaliação"}
	var hunger = float(player.get("hunger", 100.0))
	var happiness = float(player.get("happiness", 100.0))
	player["last_week_status"] = {"hunger": hunger, "happiness": happiness}
	var penalty = 0.0
	if hunger < 35.0 or happiness < 35.0:
		penalty = 25.0
		player["money"] = float(player.get("money", 0.0)) - penalty
		player["hunger"] = clampf(hunger + 10.0, 0.0, 100.0)
		player["happiness"] = clampf(happiness + 10.0, 0.0, 100.0)
	return {"penalty": penalty, "message": "Status da semana avaliado."}

func _ready() -> void:
	ensure_player_state()
	load_data()
	FIIManager.load_data()
	print(player)

func _process(delta: float) -> void:
	pass
