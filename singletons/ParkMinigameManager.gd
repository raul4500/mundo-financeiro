extends Node

# =============================================================
# MINIGAME DE MOEDAS DO PARQUE
#
# Corrida casual dentro do próprio mundo aberto (sem trocar de cena): moedas
# aparecem uma de cada vez no parque, o jogador tem 10s para achar cada uma
# antes dela sumir, e a sessão toda dura SESSION_SECONDS. A cada
# COINS_PER_QUIZ moedas o jogo pausa para um quiz sobre o conteúdo da semana
# atual (ver scripts/park/park_quiz_data.gd); acertar dá um cupom de desconto
# no mercado. Errar não penaliza — só não ganha o cupom.
# =============================================================

const ParkQuizData = preload("res://scripts/park/park_quiz_data.gd")

const MAX_PLAYS_PER_DAY := 2
const SESSION_SECONDS := 60.0
const COIN_LIFETIME := 10.0
const COINS_PER_QUIZ := 5
const MAX_QUIZZES_PER_SESSION := 2
const QUIZ_REWARD_DISCOUNT := 0.15

# Trava de acesso: só entra com as necessidades em dia e antes do fim de
# tarde. Depois das LATEST_START_HOUR o dia já está avançado demais para
# "perder tempo" brincando — o jogador deveria estar se preparando para dormir.
const MIN_STATUS_PERCENT := 50.0
const LATEST_START_HOUR := 16

# Só uma sessão por vez. Ver begin_session()/end_session().
var _session_active := false

static func default_progress() -> Dictionary:
	return {"day": 0, "plays_used": 0}

# Preenche chaves novas em saves antigos, no mesmo espírito de
# MinigameManager._progress().
func _progress() -> Dictionary:
	if not Global.player.has("park_minigame") or typeof(Global.player["park_minigame"]) != TYPE_DICTIONARY:
		Global.player["park_minigame"] = default_progress()
	var mp: Dictionary = Global.player["park_minigame"]
	for key in default_progress().keys():
		if not mp.has(key):
			mp[key] = default_progress()[key]
	return mp

func plays_left_today() -> int:
	var mp = _progress()
	if int(mp.get("day", 0)) != Global.get_absolute_day():
		return MAX_PLAYS_PER_DAY
	return max(0, MAX_PLAYS_PER_DAY - int(mp.get("plays_used", 0)))

func can_play() -> bool:
	if _session_active:
		return false
	if not _status_ok():
		return false
	if int(TimeManager.current_hour) >= LATEST_START_HOUR:
		return false
	return plays_left_today() > 0

func _status_ok() -> bool:
	return float(Global.player.get("hunger", 0.0)) >= MIN_STATUS_PERCENT \
		and float(Global.player.get("thirst", 0.0)) >= MIN_STATUS_PERCENT \
		and float(Global.player.get("stamina", 0.0)) >= MIN_STATUS_PERCENT

func lock_reason() -> String:
	if _session_active:
		return "Você já está brincando! Termine a corrida atual primeiro."
	if not _status_ok():
		return "Você precisa estar com fome, sede e stamina acima de 50% para jogar no parque."
	if int(TimeManager.current_hour) >= LATEST_START_HOUR:
		return "Já está tarde demais: o parque só recebe brincadeiras até as %dh." % LATEST_START_HOUR
	if plays_left_today() > 0:
		return ""
	return "Você já brincou o suficiente no parque hoje. Volte amanhã."

func is_session_active() -> bool:
	return _session_active

func begin_session() -> void:
	_session_active = true
	var mp = _progress()
	var today = Global.get_absolute_day()
	if int(mp.get("day", 0)) != today:
		mp["day"] = today
		mp["plays_used"] = 0
	mp["plays_used"] = int(mp.get("plays_used", 0)) + 1

func end_session() -> void:
	_session_active = false

func questions_for_current_week() -> Array:
	return ParkQuizData.get_questions(int(Global.player.get("week", 1)))

func grant_quiz_reward() -> void:
	Global.player["market_discount"] = QUIZ_REWARD_DISCOUNT
