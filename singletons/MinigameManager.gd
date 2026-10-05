extends Node

# =============================================================
# TRAVAS DO MINIGAME
#
# A PRIMEIRA sessão é diferente das demais: é a corrida de formação
# inicial, sem limite de níveis. O jogador atravessa quantos
# checkpoints conseguir e a corrida só acaba quando ele bate.
# Depois dela, a escola trava até a semana seguinte.
#
# Da SEGUNDA sessão em diante vale o limite de 1 nível:
#   - alcançou o checkpoint -> sobe 1 nível, corrida acaba,
#     escola trancada até a semana seguinte;
#   - bateu antes disso     -> escola trancada por 2 dias de jogo.
# =============================================================

# Quantas semanas a subida de nível trava a escola.
const LEVEL_LOCK_WEEKS := 1
# Quantos dias de jogo a derrota trava a escola.
const FAIL_COOLDOWN_DAYS := 2
# Formação máxima. Casa com os 5 níveis do escritório e com os 4 checkpoints
# do mapa (Level1..Level4 levam do nível 1 ao 5). Sem este teto, um jogador no
# nível máximo nasceria depois do último checkpoint e correria até o fim do
# chão, caindo no vazio sem nada encerrar a corrida.
const MAX_SCHOOL_LEVEL := 5

# Uma corrida só conta enquanto esta flag estiver ligada, e o primeiro
# desfecho (checkpoint ou obstáculo) a desliga. É o que garante "no máximo 1
# nível por tentativa": um guard dentro de cada Area2D de checkpoint não
# serviria, porque cada área tem o seu, e o jogador subiria um nível em cada
# checkpoint que atravessasse na mesma corrida.
# Começa desligada de propósito: fora do minigame, e durante a tela de início,
# encostar numa área não deve valer nada.
var _session_active := false
var is_in_minigame: bool = false:
	set(val):
		is_in_minigame = val
		if Engine.has_singleton("Global") or Global != null:
			Global.in_school_minigame = val

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

static func default_progress() -> Dictionary:
	return {"unlock_week": 1, "unlock_day": 0, "sessions_played": 0}

# Preenche chaves novas em saves criados antes de elas existirem, no mesmo
# espírito de EnterpriseManager._normalize_state().
func _progress() -> Dictionary:
	if not Global.player.has("minigame_progress") or typeof(Global.player["minigame_progress"]) != TYPE_DICTIONARY:
		Global.player["minigame_progress"] = default_progress()
	var mp: Dictionary = Global.player["minigame_progress"]
	for key in default_progress().keys():
		if not mp.has(key):
			mp[key] = default_progress()[key]
	return mp

# A corrida de formação inicial: nenhuma sessão registrada ainda.
func is_first_session() -> bool:
	return int(_progress().get("sessions_played", 0)) == 0

func is_max_level() -> bool:
	return int(Global.player.get("school_level", 1)) >= MAX_SCHOOL_LEVEL

func can_play() -> bool:
	if is_max_level():
		return false
	var mp = _progress()
	var week_ok = int(Global.player.get("week", 1)) >= int(mp.get("unlock_week", 1))
	var day_ok = Global.get_absolute_day() >= int(mp.get("unlock_day", 0))
	return week_ok and day_ok

# =============================
# 🏁 CICLO DA SESSÃO
# =============================

# Chamado por minigame.gd quando a contagem termina e o jogador ganha controle.
func begin_session() -> void:
	_session_active = true

func end_session() -> void:
	_session_active = false

func is_session_active() -> bool:
	return _session_active

# Chamado por level.gd quando o jogador toca um checkpoint.
# Devolve true se a corrida deve TERMINAR aqui. Na primeira sessão devolve
# false: o jogador sobe de nível e continua correndo.
func on_checkpoint_reached() -> bool:
	if not _session_active:
		return false

	Global.player["school_level"] = int(Global.player.get("school_level", 1)) + 1
	Global.update_salary()
	_log_info("Minigame: checkpoint alcançado. Nível %d." % int(Global.player["school_level"]))

	# A corrida também acaba ao atingir a formação máxima, mesmo na primeira
	# sessão: depois do último checkpoint não há mais mapa pela frente.
	if is_first_session() and not is_max_level():
		# Formação inicial: sem limite de níveis, a corrida segue.
		return false

	_session_active = false
	_finish_session(true)
	return true

# Chamado por obstacle.gd quando o jogador bate. Devolve true se a corrida
# terminou aqui (false = já tinha terminado antes, ignore).
func on_obstacle_hit() -> bool:
	if not _session_active:
		return false
	# Na primeira sessão o jogador pode ter subido vários níveis antes de
	# bater; a trava por semana vale do mesmo jeito.
	var leveled_up = is_first_session()
	_session_active = false
	_finish_session(leveled_up)
	return true

func _finish_session(lock_by_week: bool) -> void:
	var mp = _progress()
	if lock_by_week:
		mp["unlock_week"] = int(Global.player.get("week", 1)) + LEVEL_LOCK_WEEKS
		# Zera a trava de dia: quem manda agora é a semana. Sem isso, um
		# cooldown de derrota anterior continuaria somando por cima.
		mp["unlock_day"] = 0
		_log_info("Minigame: sessão encerrada. Liberado na semana %d." % int(mp["unlock_week"]))
	else:
		mp["unlock_day"] = Global.get_absolute_day() + FAIL_COOLDOWN_DAYS
		# A semana atual já basta; a trava ativa passa a ser a de dias.
		mp["unlock_week"] = int(Global.player.get("week", 1))
		_log_info("Minigame: derrota. Liberado no dia absoluto %d." % int(mp["unlock_day"]))
	# Só aqui a sessão passa a contar como jogada: is_first_session() precisa
	# continuar verdadeiro durante toda a primeira corrida.
	mp["sessions_played"] = int(mp.get("sessions_played", 0)) + 1

# Texto curto para o painel da porta e para o alerta de porta trancada.
func lock_reason() -> String:
	if can_play():
		return ""
	if is_max_level():
		return "Você concluiu sua formação escolar. Não há mais o que estudar aqui."
	var mp = _progress()
	if int(Global.player.get("week", 1)) < int(mp.get("unlock_week", 1)):
		return "Escola fechada. Você volta a estudar na semana %d." % int(mp.get("unlock_week", 1))
	var days_left = int(mp.get("unlock_day", 0)) - Global.get_absolute_day()
	days_left = max(days_left, 1)
	if days_left == 1:
		return "Escola fechada. Você pode tentar de novo amanhã."
	return "Escola fechada. Você pode tentar de novo em %d dias." % days_left
