extends Node

# Auto-teste das mecanicas das fases 6-10. Roda sozinho, sem framework:
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/test_mechanics.tscn
# Sai com codigo 0 se tudo passar, 1 se algum assert falhar.
#
# Cobre so' o que e' calculo puro (curva de stamina, fechamento do dia, imposto
# sobre prejuizo em FII). O que depende de cena — andar ate a casa, clicar em
# DORMIR, o minigame — continua sendo teste manual.

var failures: Array = []

func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   %s" % description)
	else:
		print("  FALHA %s" % description)
		failures.append(description)

func _fresh_player() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["money"] = 1000.0
	Global.player["hunger"] = 110.0
	Global.player["thirst"] = 110.0
	Global.player["stamina"] = 110.0
	Global.player["day"] = 1
	Global.player["hour"] = 8
	# Para testes de mecânicas gerais (stamina, sono, game over, FIIs), o jogador
	# já concluiu o tutorial para avaliar o loop normal de gameplay.
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	TimeManager.current_day = 1
	TimeManager.current_hour = 8
	TimeManager.current_minute = 0
	TimeManager.day_end_pending = false
	TimeManager._exhaustion_alert_shown = false
	TimeManager._no_stamina_alert_shown = false

# Avanca minutos de jogo parando antes da meia-noite, para o teste nao disparar
# a transicao de cena de _handle_midnight().
func _run_until(hour: int, minute: int) -> void:
	while TimeManager.current_hour < hour or (TimeManager.current_hour == hour and TimeManager.current_minute < minute):
		if TimeManager.current_hour >= 23 and TimeManager.current_minute >= 59:
			return
		TimeManager._add_minute()

# =============================================================
func test_stamina_dura_o_dia_inteiro() -> void:
	print("stamina: 110 -> 0 entre 08h e 24h")
	_fresh_player()
	_run_until(18, 0)
	var at_18 := float(Global.player["stamina"])
	# 10 horas a 110/960 por minuto = 68.75 gastos. Sobra 41.25.
	_check(abs(at_18 - 41.25) < 0.5, "as 18h sobra ~41.25 de stamina (obtido %.2f)" % at_18)
	_check(TimeManager._exhaustion_alert_shown, "o aviso das 18h foi disparado")
	_check(not TimeManager.day_end_pending, "o dia NAO acabou sozinho as 18h (fase 7.1)")

	_run_until(19, 0)
	var at_19 := float(Global.player["stamina"])
	# 11 horas a 110/960 por minuto = 75.625 gastos. Sobra 34.375.
	_check(abs(at_19 - 34.38) < 0.5, "as 19h sobra ~34.38 (taxa ainda base, obtido %.2f)" % at_19)

	# 19h em diante: 2x, +10% por hora. A stamina zera por volta das 21h20.
	_run_until(21, 0)
	_check(float(Global.player["stamina"]) > 0.0, "as 21h ainda ha' stamina")
	_run_until(21, 40)
	_check(float(Global.player["stamina"]) == 0.0, "as 21h40 a stamina zerou")
	_check(TimeManager._no_stamina_alert_shown, "o aviso de stamina zerada foi disparado")
	_check(not Global.is_game_over(), "stamina zerada NAO e' game-over (fase 7.3)")

func test_dormir_fecha_o_dia() -> void:
	print("dormir: stamina cheia, fome -6, dia trancado ate' o alerta fechar (fase 7.1)")
	_fresh_player()
	_run_until(20, 0)
	var hunger_before := float(Global.player["hunger"])
	var result: Dictionary = TimeManager.sleep()
	_check(bool(result["success"]), "sleep() aceitou")
	_check(float(Global.player["hunger"]) <= hunger_before,
		"a fome não aumentou no fechamento")
	_check(TimeManager.day_end_pending, "o dia ficou trancado esperando o alerta")
	_check(not bool(TimeManager.sleep()["success"]), "dormir duas vezes no mesmo dia nao vale")

func test_fome_zerada_desmaia_em_vez_de_game_over() -> void:
	print("fome zerada: desmaia (-R$30, dia fecha, acorda com 50 por cento) e NAO e' game-over")
	_fresh_player()
	Global._game_over = false
	Global.player["money"] = 100.0
	Global.player["hunger"] = 0.0
	var message := TimeManager.collapse_if_needs_depleted()
	_check(message.find("fome") != -1 and message.find("sede") == -1, "o desmaio cita so' a fome")
	_check(not Global.is_game_over(), "nao e' game-over")
	_check(is_equal_approx(float(Global.player["money"]), 70.0), "cobrou R$ 30")
	_check(TimeManager.day_end_pending, "o dia fechou (avanca quando o jogador fecha o alerta)")
	_check(float(Global.player["hunger"]) > 45.0, "acorda com a fome restaurada, nao em zero")
	# Sem isto, o primeiro minuto do dia seguinte desmaiaria de novo, em loop.
	_check(TimeManager.collapse_if_needs_depleted() == "", "nao desmaia duas vezes no mesmo dia")
	_check(is_equal_approx(float(Global.player["money"]), 70.0), "sem segunda cobranca")
	AlertManager.reset()

func test_sede_zerada_desmaia() -> void:
	print("sede zerada: mesmo desfecho da fome; as duas juntas citam as duas")
	_fresh_player()
	Global._game_over = false
	Global.player["thirst"] = 0.0
	var message := TimeManager.collapse_if_needs_depleted()
	_check(message.find("sede") != -1 and message.find("fome") == -1, "o desmaio cita so' a sede")
	_check(float(Global.player["thirst"]) > 45.0, "sede restaurada")
	AlertManager.reset()

	_fresh_player()
	Global.player["hunger"] = 0.0
	Global.player["thirst"] = 0.0
	message = TimeManager.collapse_if_needs_depleted()
	_check(message.find("fome e sede") != -1, "as duas zeradas: 'fome e sede'")
	_check(float(Global.player["hunger"]) > 45.0 and float(Global.player["thirst"]) > 45.0, "as duas restauradas")
	AlertManager.reset()

	# Sem dinheiro a cobranca nao deixa o saldo negativo.
	_fresh_player()
	Global.player["money"] = 10.0
	Global.player["thirst"] = 0.0
	TimeManager.collapse_if_needs_depleted()
	_check(float(Global.player["money"]) == 0.0, "cobranca para em zero, sem saldo negativo")
	AlertManager.reset()

func test_fome_que_zera_no_decaimento_desmaia() -> void:
	print("fome: o minuto de jogo que zera a fome dispara o desmaio")
	_fresh_player()
	Global._game_over = false
	Global.player["hunger"] = Global.HUNGER_DECAY_PER_MINUTE
	TimeManager._add_minute()
	_check(TimeManager.day_end_pending, "o dia fechou no minuto em que a fome zerou")
	_check(not Global.is_game_over(), "sem game-over")
	AlertManager.reset()

func test_imposto_sobre_prejuizo_em_fii() -> void:
	print("FII: vender abaixo do preco medio paga 10%% sobre o prejuizo (fase 10.1)")
	_fresh_player()
	Global.player["money"] = 5000.0
	FIIManager.reset()
	FIIManager.funds["FII_SHOPPING"]["price"] = 100.0
	_check(FIIManager.buy_fund("FII_SHOPPING", 10), "comprou 10 cotas a R$100")
	_check(abs(float(FIIManager.avg_price["FII_SHOPPING"]) - 100.0) < 0.01, "preco medio = 100")

	# Segunda compra mais barata puxa o preco medio para baixo.
	FIIManager.funds["FII_SHOPPING"]["price"] = 50.0
	FIIManager.buy_fund("FII_SHOPPING", 10)
	_check(abs(float(FIIManager.avg_price["FII_SHOPPING"]) - 75.0) < 0.01,
		"preco medio ponderado = 75 (obtido %.2f)" % float(FIIManager.avg_price["FII_SHOPPING"]))

	# Vender as 20 cotas a 50 com media 75: prejuizo 500, imposto 50.
	var money_before := float(Global.player["money"])
	FIIManager.sell_fund("FII_SHOPPING", 20)
	var received := float(Global.player["money"]) - money_before
	_check(abs(received - 950.0) < 0.01, "recebeu 1000 - 50 de imposto = 950 (obtido %.2f)" % received)
	_check(not FIIManager.avg_price.has("FII_SHOPPING"), "zerou a posicao e o preco medio junto")

	# Vender no lucro nao paga imposto nenhum.
	FIIManager.funds["FII_LOGISTICA"]["price"] = 100.0
	FIIManager.buy_fund("FII_LOGISTICA", 5)
	FIIManager.funds["FII_LOGISTICA"]["price"] = 130.0
	money_before = float(Global.player["money"])
	FIIManager.sell_fund("FII_LOGISTICA", 5)
	_check(abs((float(Global.player["money"]) - money_before) - 650.0) < 0.01, "venda no lucro sai limpa")

func test_comida_do_mercado_repoe_fome() -> void:
	print("mercado: o item repoe exatamente o %% de fome anunciado (fase 6.3)")
	_fresh_player()
	Global.player["hunger"] = 20.0
	Global.player["stamina"] = 20.0
	Global.add_home_inventory_item("Bread", 1, "food", 10)
	var result: Dictionary = Global.consume_food()
	_check(bool(result["success"]), "comeu o pao")
	# consume_food() gasta 30 min, decaindo 30 * 0.02 = 0.6 de fome: 20 + 10 - 0.6 = 29.4
	_check(abs(float(Global.player["hunger"]) - 29.40) < 0.01,
		"fome 20 + 10%% - 0.6 (30 min) = 29.4 (obtido %.2f)" % float(Global.player["hunger"]))
	# consume_food() gasta 30 minutos de jogo, que ja' descontam stamina:
	# 20 + (10 * 0.25) - (30 * 110/960)
	var expected_stamina := 20.0 + 10.0 * Global.STAMINA_PER_FOOD_ENERGY - 30.0 * TimeManager.STAMINA_DECAY_PER_MINUTE
	_check(abs(float(Global.player["stamina"]) - expected_stamina) < 0.01,
		"stamina = %.3f apos o bonus e a meia hora gasta (obtido %.3f)" % [expected_stamina, float(Global.player["stamina"])])

func test_beber_escolhe_bebida_e_repoe_sede() -> void:
	print("sede: BEBER pega bebida, COMER pega comida, e o item aplica os dois restauros")
	_fresh_player()
	Global.player["thirst"] = 40.0
	Global.player["hunger"] = 50.0
	Global.player["home_inventory"] = {}
	Global.add_home_inventory_item("Water", 2, "drink", 3, 25)
	Global.add_home_inventory_item("Bread", 1, "food", 10, 0)

	var result: Dictionary = Global.consume_drink()
	_check(bool(result["success"]), "bebeu")
	_check(str(result.get("item", "")) == "Water", "escolheu a agua, e nao o pao")
	# consume_drink() gasta 15 min: sede decai 15 * 0.07 = 1.05. 40 + 25 - 1.05 = 63.95
	_check(abs(float(Global.player["thirst"]) - 63.95) < 0.01,
		"sede 40 + 25%% - 1.05 (15 min) = 63.95 (obtido %.2f)" % float(Global.player["thirst"]))
	# A agua tambem tem 3% de fome: decai 15 * 0.02 = 0.3. 50 + 3 - 0.3 = 52.70
	_check(abs(float(Global.player["hunger"]) - 52.70) < 0.01,
		"fome 50 + 3%% da agua - 0.3 = 52.70 (obtido %.2f)" % float(Global.player["hunger"]))
	_check(Global.player["home_inventory"].has("bread"), "o pao continua no estoque")
	_check(int(Global.player["home_inventory"]["water"]["quantity"]) == 1, "sobrou 1 agua")

	_check(bool(Global.consume_food().get("success", false)), "COMER ainda acha a comida")
	_check(not Global.player["home_inventory"].has("bread"), "o pao foi consumido")

func test_bebida_de_save_antigo_e_migrada() -> void:
	print("sede: bebida gravada como comida em save antigo vira 'drink' com valor de sede")
	_fresh_player()
	# Formato anterior a' sede: category "food" e sem campo "thirst".
	Global.player["home_inventory"] = {
		"suco": {"name": "Suco", "quantity": 1, "category": "food", "energy": 15.0, "happiness": 1.0}
	}
	Global.normalize_home_inventory()
	var juice: Dictionary = Global.player["home_inventory"]["suco"]
	_check(str(juice["category"]) == "drink", "suco migrado para 'drink'")
	_check(abs(float(juice["thirst"]) - 35.0) < 0.01, "suco recebeu os 35%% de sede da tabela")

func test_mercado_e_migracao_nao_divergem() -> void:
	print("sede: Global.DRINK_THIRST espelha market.gd['Bebidas']")
	var market = load("res://scripts/world/market/market.gd").new()
	var drinks: Dictionary = market.items["Bebidas"]
	var diff: Array = []
	for key in drinks.keys():
		if not Global.DRINK_THIRST.has(key):
			diff.append("falta em DRINK_THIRST: %s" % key)
		elif int(Global.DRINK_THIRST[key]) != int(drinks[key]["thirst_restore"]):
			diff.append("valor divergente: %s" % key)
	for key in Global.DRINK_THIRST.keys():
		if not drinks.has(key):
			diff.append("sobra em DRINK_THIRST: %s" % key)
	market.free()
	_check(diff.is_empty(), "as duas tabelas batem (%s)" % str(diff))

# =============================================================
# TUTORIAL E LIBERACAO SEQUENCIAL DOS LUGARES
# =============================================================

# Reproduz o que main_game._ready() faz ao carregar a cena do mundo.
func _enter_world() -> void:
	var tutorial_step := int(Global.player.get("tutorial_step", 1))
	if tutorial_step == 1:
		TutorialManager.start_tutorial()
	elif tutorial_step <= TutorialManager.FINAL_STEP:
		TutorialManager.resume_tutorial(tutorial_step)

func test_novo_jogo_so_libera_a_escola() -> void:
	print("liberacao: novo jogo abre so' a escola")
	_fresh_player()
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	_check(Global.unlock_stage() == Global.UNLOCK_SCHOOL_ONLY, "estagio inicial = so' a escola")
	_check(Global.is_place_unlocked("school"), "escola aberta")
	for place in ["office", "bank", "market", "home", "restaurant_small", "arcade_medium", "shopping_large"]:
		_check(not Global.is_place_unlocked(place), "%s trancado" % place)
		_check(Global.place_lock_reason(place) != "", "%s tem motivo de trava" % place)

func test_pular_tutorial_libera_tudo_e_nao_volta() -> void:
	print("pular tutorial: libera tudo e nao reaparece (item 1)")
	_fresh_player()
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.start_tutorial()
	_check(TutorialManager.can_skip(), "o botao de pular aparece no passo 1")
	TutorialManager.skip_tutorial()

	_check(Global.unlock_stage() == Global.UNLOCK_ALL, "pulou: cidade inteira liberada")
	for place in ["school", "office", "bank", "market", "home", "shopping_large"]:
		_check(Global.is_place_unlocked(place), "%s aberto depois de pular" % place)

	_check(int(Global.player["tutorial_step"]) == TutorialManager.TUTORIAL_DONE,
		"tutorial_step = concluido, nao o ultimo passo")

	# Era exatamente isto que falhava: voltar do minigame recarregava main_game,
	# que chamava resume_tutorial() e mostrava o tour de novo.
	TutorialManager.pending_messages.clear()
	_enter_world()
	_check(TutorialManager.pending_messages.is_empty(), "voltar ao mundo nao reabre o tutorial")

	# Nenhum aviso semanal deve escapar.
	for week in TutorialManager.weekly_messages.keys():
		TutorialManager.pending_messages.clear()
		TutorialManager.on_week_changed(int(week))
		_check(TutorialManager.pending_messages.is_empty(),
			"aviso da semana %d nao aparece depois de pular" % int(week))

func test_ordem_escritorio_depois_o_resto() -> void:
	print("liberacao sequencial: minigame -> escritorio -> resto (itens 2 e 3)")
	_fresh_player()
	Global.player["tutorial_step"] = 7
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.step = 7
	TutorialManager.skipped = false
	TutorialManager.pending_messages.clear()

	# Fim do minigame: o passo 8 apresenta o escritorio e so' ele abre.
	TutorialManager.on_minigame_finished()
	_check(TutorialManager.step == 8, "avancou para o passo 8")
	_check(Global.unlock_stage() == Global.UNLOCK_OFFICE, "escritorio liberado")
	_check(Global.is_place_unlocked("office"), "porta do escritorio aberta")
	_check(not Global.is_place_unlocked("bank"), "banco continua trancado")
	_check(not Global.is_place_unlocked("market"), "mercado continua trancado")
	_check(TutorialManager.pending_messages.size() > 0, "mensagens do escritorio na fila")

	# A camera precisa parar no escritorio antes da mensagem que o apresenta.
	var has_office_focus := false
	for entry in TutorialManager.pending_messages:
		if str(entry.get("focus", "")) == "Office":
			has_office_focus = true
	_check(has_office_focus, "a camera foca o escritorio nessa fila")

	# Sair do escritorio antes da hora nao pode adiantar nada.
	TutorialManager.on_player_left_office()
	_check(TutorialManager.step == 8, "sair do escritorio no passo 8 nao avanca")

	# Passo 9: esperando a visita. Recarregar aqui nao repete mensagem.
	TutorialManager.step = TutorialManager.OFFICE_WAIT_STEP
	Global.player["tutorial_step"] = TutorialManager.OFFICE_WAIT_STEP
	TutorialManager.pending_messages.clear()
	_enter_world()
	_check(TutorialManager.pending_messages.is_empty(), "recarregar esperando a visita nao repete nada")
	_check(not Global.is_place_unlocked("bank"), "banco ainda trancado enquanto espera")

	# Saiu do escritorio: o tour do resto da cidade roda ao voltar ao mundo.
	TutorialManager.on_player_left_office()
	_check(TutorialManager.step == TutorialManager.FINAL_STEP, "avancou para o tour final")
	_enter_world()
	_check(TutorialManager.pending_messages.size() > 0, "o tour do mundo entrou na fila")

	var has_home_focus := false
	var has_market_focus := false
	var has_bank_focus := false
	var has_park_focus := false
	for entry in TutorialManager.pending_messages:
		var foc: String = str(entry.get("focus", ""))
		if foc == "Home":
			has_home_focus = true
		elif foc == "Market":
			has_market_focus = true
		elif foc == "Bank":
			has_bank_focus = true
		elif foc == "Park":
			has_park_focus = true
	_check(has_home_focus, "o tour foca a casa")
	_check(has_market_focus, "o tour foca o mercado")
	_check(has_bank_focus, "o tour foca o banco")
	_check(has_park_focus, "o tour foca o parque")

	# O tour termina quando a fila esvazia.
	var guard := 0
	while not TutorialManager.pending_messages.is_empty() and guard < 50:
		TutorialManager.pending_messages.pop_front()
		guard += 1
	# CameraManager vai reclamar de "nenhum jogador registrado": e' esperado,
	# nao ha' cena de mundo aqui. O que importa e' o estado depois da chamada.
	TutorialManager.continue_tutorial_after_alert()
	_check(int(Global.player["tutorial_step"]) == TutorialManager.TUTORIAL_DONE, "tutorial concluido")
	_check(Global.unlock_stage() == Global.UNLOCK_ALL, "cidade inteira liberada no fim")
	_check(bool(Global.player.get("tutorial_home_shown", false)), "tutorial da casa marcado como visto")

	TutorialManager.pending_messages.clear()
	TutorialManager.on_player_entered_home()
	_check(TutorialManager.pending_messages.is_empty(), "entrar em casa depois do tour nao repete o tutorial")

	TutorialManager.pending_messages.clear()
	_enter_world()
	_check(TutorialManager.pending_messages.is_empty(), "tutorial concluido nao se repete")

func test_tutorial_fluxo_inicial_controles_e_escola() -> void:
	print("tutorial: intro -> controles -> escola")
	_fresh_player()
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	TutorialManager.start_tutorial()
	_check(TutorialManager.step == 1, "inicia no passo 1 (boas-vindas)")
	_check(TutorialManager.can_skip(), "pode pular no passo 1")

	# Avanca do passo 1 para o 2: o passo 2 enfileira objetivo principal e controles
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.step == 2, "avancou para o passo 2")
	_check(not TutorialManager.can_skip(), "nao pode pular no passo 2")
	_check(TutorialManager.pending_messages.size() == 2, "2 mensagens de controles pendentes na fila do passo 2")

	# Consome os alertas de controles
	var preview_events: Array = []
	var on_preview := func(v: bool): preview_events.append(v)
	TutorialManager.missions_preview_requested.connect(on_preview)
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.pending_messages.size() == 1, "1 mensagem de controles restante")
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.pending_messages.is_empty(), "fila de controles esvaziada")
	_check(preview_events.has(true), "tutorial abre preview do painel de missoes no passo 2")

	# Proxima confirmacao avanca para a escola (passo 3)
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.step == 3, "passo 3 apresenta a escola apos os controles")
	_check(preview_events.has(false), "tutorial fecha preview do painel de missoes ao ir para passo 3")
	TutorialManager.missions_preview_requested.disconnect(on_preview)

	# Avanca para o passo 4 (impacto no salario)
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.step == 4, "passo 4 explica salario e formacao")

	# Avanca para o passo 5 (espera entrar na escola)
	TutorialManager.continue_tutorial_after_alert()
	_check(TutorialManager.step == 5, "passo 5 foca na escola e aguarda jogador")

	# Entrar na escola avanca para o passo 6
	TutorialManager.on_player_entered_school()
	_check(TutorialManager.step == 6, "entrou na escola: avancou para o minigame")

func test_status_travados_em_100_durante_tutorial() -> void:
	print("tutorial: status (fome, sede, stamina) travados em 110 ate concluir ou pular")
	_fresh_player()
	Global.player["tutorial_step"] = 1
	Global.player["unlock_stage"] = Global.UNLOCK_SCHOOL_ONLY
	_check(Global.is_tutorial_active(), "tutorial ativo no inicio")

	# Avanca tempo com o tutorial ativo: stamina nao cai, 18h nao dispara alerta
	_run_until(18, 0)
	_check(float(Global.player["stamina"]) == 110.0, "stamina continua 110 as 18h no tutorial")
	_check(not TimeManager._exhaustion_alert_shown, "aviso das 18h nao dispara durante o tutorial")

	# Fim do dia / decay_need_state nao reduz fome nem sede
	var survived: bool = Global.decay_need_state()
	_check(survived, "decay_need_state durante tutorial nao mata")
	_check(float(Global.player["hunger"]) == 110.0, "fome continua 110 no tutorial")
	_check(float(Global.player["thirst"]) == 110.0, "sede continua 110 no tutorial")

	# Pular tutorial libera o mundo e destrava o decaimento normal
	TutorialManager.start_tutorial()
	TutorialManager.skip_tutorial()
	_check(not Global.is_tutorial_active(), "tutorial inativo apos pular")
	_check(float(Global.player["stamina"]) == 110.0, "stamina continua 110 logo apos pular")
	_check(float(Global.player["hunger"]) == 110.0, "fome continua 110 logo apos pular")
	_check(float(Global.player["thirst"]) == 110.0, "sede continua 110 logo apos pular")

	# Agora que o tutorial acabou, o decaimento de stamina funciona normalmente
	TimeManager.current_hour = 8
	TimeManager.current_minute = 0
	_run_until(18, 0)
	_check(float(Global.player["stamina"]) < 110.0, "apos tutorial, stamina decai normalmente")

func test_save_antigo_nao_retranca_a_cidade() -> void:
	print("save antigo: sem unlock_stage entra com tudo aberto")
	Global.player = Global._new_player_data()
	Global.player.erase("unlock_stage")
	Global.player["tutorial_step"] = 8  # era o "concluido" do formato anterior
	Global.ensure_player_state()
	_check(Global.unlock_stage() == Global.UNLOCK_ALL, "save antigo entra com tudo liberado")
	_check(int(Global.player["tutorial_step"]) == TutorialManager.TUTORIAL_DONE,
		"o 8 antigo vira concluido, e nao a apresentacao do escritorio")

# =============================================================
# Testes da auditoria: cada um cobre um bug que travava o jogo permanentemente
# ou deixava dinheiro/estado incoerente sem nenhum aviso.
# =============================================================

func test_reset_de_time_manager_destrava_partida_nova() -> void:
	print("auditoria: TimeManager.reset() limpa day_end_pending preso por uma morte anterior")
	_fresh_player()
	# Simula o estado que uma morte de fome/sede deixava para tras: _close_day()
	# trava day_end_pending ANTES de checar se o jogador sobreviveu, e o
	# caminho de morte nunca chamava _advance_to_next_day() (o unico lugar que
	# destravava). Sem TimeManager.reset(), isso sobrevivia para a partida nova.
	TimeManager.day_end_pending = true
	TimeManager.reset()
	_check(not TimeManager.day_end_pending, "day_end_pending volta a false")
	TimeManager._add_minute()
	_check(Global.player["hunger"] >= 0.0 and TimeManager.current_minute == 1,
		"o relogio volta a andar depois do reset (nao fica mais preso em no-op)")

func test_semana_repetida_reprocessa_empreendimento() -> void:
	print("auditoria: semana repetida (missao falhada) reseta o guard de operacao diaria do empreendimento")
	_fresh_player()
	Global.player["money"] = 5000.0
	EnterpriseManager._ensure_states()
	var eid := "restaurant_small"
	var bought: Dictionary = EnterpriseManager.buy_enterprise(eid)
	_check(bool(bought.get("success", false)), "compra do restaurante ok para o teste")
	Global.player["day"] = 3
	Global.player["week"] = 2
	var first: Dictionary = EnterpriseManager.process_daily_operation(eid)
	_check(bool(first.get("success", false)), "primeira operacao do dia processa")
	var repeat: Dictionary = EnterpriseManager.process_daily_operation(eid)
	_check(str(repeat.get("reason", "")) == "already_processed",
		"reprocessar o mesmo dia+semana e' bloqueado (comportamento normal)")
	# Semana falhou e repete: TimeManager.week nao muda, os dias 1-7 rodam de
	# novo com os MESMOS numeros. Sem reset_operation_guards(), o guard acima
	# bloquearia a receita/despesa da semana inteira em silencio.
	EnterpriseManager.reset_operation_guards()
	var after_reset: Dictionary = EnterpriseManager.process_daily_operation(eid)
	_check(bool(after_reset.get("success", false)),
		"depois do reset, o mesmo dia+semana processa de novo na semana repetida")

func test_penalidades_tem_piso_em_zero() -> void:
	print("auditoria: penalidades da meia-noite e da semana ruim nao deixam o saldo negativo")
	_fresh_player()
	Global.player["money"] = 10.0
	TimeManager._handle_midnight()
	_check(float(Global.player["money"]) == 0.0, "penalidade da meia-noite para em zero, nao vai a -20")

	_fresh_player()
	Global.player["money"] = 10.0
	Global.player["hunger"] = 20.0  # abaixo de 35 -> penalidade de semana ruim
	Global.evaluate_week_status()
	_check(float(Global.player["money"]) == 0.0, "penalidade de semana ruim para em zero, nao vai a -15")

func test_descansar_com_fome_zerando_e_game_over_na_hora() -> void:
	print("auditoria: Descansar/TV com gasto maior que a fome atual e' bloqueado sem disparar game-over")
	_fresh_player()
	Global._game_over = false
	Global.player["hunger"] = 10.0
	var result: Dictionary = Global.apply_home_action("VOCÊ DESCANSOU.", -12.0, 18.0, 1.0)
	_check(float(Global.player["hunger"]) == 10.0, "a fome nao caiu porque a acao foi bloqueada")
	_check(not Global.is_game_over(), "game-over nao disparou porque a acao foi bloqueada")
	_check(not bool(result.get("success", true)), "apply_home_action reporta falha quando o gasto excede a fome")

func test_ensure_player_state_recupera_o_nome() -> void:
	print("auditoria: ensure_player_state() recupera a chave 'name' ausente")
	Global.player = Global._new_player_data()
	Global.player.erase("name")
	Global.ensure_player_state()
	_check(Global.player.has("name"), "'name' volta a existir depois de ensure_player_state()")

func test_continuar_jogo_destrava_movimento() -> void:
	print("continuar jogo: restaura speed e libera travas residuais")
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["speed"] = 0.0
	Global.ensure_player_state()
	_check(float(Global.player.get("speed", 0.0)) == 70.0, "speed zerado e' restaurado para 70.0")

	Global.lock_gameplay()
	Global.lock_gameplay()
	TutorialManager.resume_tutorial(5)
	_check(not Global.gameplay_locked, "resume_tutorial(5) libera locks orfaos")

	Global.lock_gameplay()
	Global.player["minigame_progress"] = {"unlock_week": 1, "unlock_day": 0, "sessions_played": 0}
	TutorialManager.resume_tutorial(6)
	_check(TutorialManager.step == 5 and not Global.gameplay_locked, "resume_tutorial(6) no mapa volta ao passo 5 destravado")

func test_confirmacao_leitura_consultoria() -> void:
	print("consultoria: exige leitura dos topicos e confirmacao antes de liberar saida no tutorial")
	_fresh_player()
	Global.player["tutorial_step"] = TutorialManager.OFFICE_WAIT_STEP
	Global.player["unlock_stage"] = Global.UNLOCK_OFFICE
	Global.player["office_study_confirmed"] = false
	TutorialManager.step = TutorialManager.OFFICE_WAIT_STEP

	var office_scene: Control = load("res://scenes/world/places/office.tscn").instantiate()
	add_child(office_scene)

	_check(office_scene.confirm_button != null and office_scene.confirm_button.disabled, "botao Concluir Aula nasce desabilitado")
	office_scene._on_exit_pressed()
	_check(TutorialManager.step == TutorialManager.OFFICE_WAIT_STEP, "sair sem confirmar leitura nao avanca o tutorial")
	AlertManager._close_alert()

	for topic in office_scene.levels_data[0]["topics"]:
		office_scene._on_topic_pressed(topic)
	_check(not office_scene.confirm_button.disabled, "ler todos os topicos habilita o botao Concluir Aula")

	office_scene._on_confirm_study_pressed()
	AlertManager._close_alert()
	_check(bool(Global.player.get("office_study_confirmed", false)), "confirmar aula grava office_study_confirmed = true")

	remove_child(office_scene)
	office_scene.free()

func test_caderno_tutorial_guia_ingame() -> void:
	print("caderno de tutorial: abre, pausa tempo, navega topicos e fecha destravando")
	_fresh_player()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	var nb: CanvasLayer = load("res://scenes/ui/tutorial_notebook.tscn").instantiate()
	add_child(nb)

	_check(not nb.is_open, "caderno nasce fechado")
	nb.open_notebook()
	_check(nb.is_open and nb.panel.visible, "open_notebook abre o painel do guia")
	_check(Global.gameplay_locked and not Global.play_time, "abrir o guia trava gameplay e pausa o tempo")

	for i in range(nb.TOPICS.size()):
		nb.select_topic(i)
		_check(nb.content_label.text.length() > 20, "topico %d carrega conteudo" % i)

	nb.close_notebook()
	_check(not nb.is_open and not nb.panel.visible, "close_notebook fecha o painel")
	_check(not Global.gameplay_locked, "fechar o guia destrava o gameplay")

	remove_child(nb)
	nb.free()

func _ready() -> void:
	print("=== auto-teste das mecanicas ===")
	test_stamina_dura_o_dia_inteiro()
	test_dormir_fecha_o_dia()
	test_fome_zerada_desmaia_em_vez_de_game_over()
	test_sede_zerada_desmaia()
	test_fome_que_zera_no_decaimento_desmaia()
	test_imposto_sobre_prejuizo_em_fii()
	test_comida_do_mercado_repoe_fome()
	test_beber_escolhe_bebida_e_repoe_sede()
	test_bebida_de_save_antigo_e_migrada()
	test_mercado_e_migracao_nao_divergem()
	test_novo_jogo_so_libera_a_escola()
	test_pular_tutorial_libera_tudo_e_nao_volta()
	test_ordem_escritorio_depois_o_resto()
	test_tutorial_fluxo_inicial_controles_e_escola()
	test_status_travados_em_100_durante_tutorial()
	test_save_antigo_nao_retranca_a_cidade()
	test_reset_de_time_manager_destrava_partida_nova()
	test_semana_repetida_reprocessa_empreendimento()
	test_penalidades_tem_piso_em_zero()
	test_descansar_com_fome_zerando_e_game_over_na_hora()
	test_ensure_player_state_recupera_o_nome()
	test_continuar_jogo_destrava_movimento()
	test_confirmacao_leitura_consultoria()
	test_caderno_tutorial_guia_ingame()

	print("=== %d falha(s) ===" % failures.size())
	for f in failures:
		print("  - %s" % f)
	get_tree().quit(1 if failures.size() > 0 else 0)
