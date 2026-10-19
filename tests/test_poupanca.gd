extends Node

const BANK_SCENE = preload("res://scenes/world/places/bank.tscn")

func _fresh() -> void:
	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul_Poupanca"
	Global.player["money"] = 200.0
	Global.player["saldo"] = 200.0
	Global.player["poupanca"] = 0.0
	Global.player["poupanca_rendimento_total"] = 0.0
	Global.player["week"] = 3
	Global.player["day"] = 1
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	MissionManager.reset_progress()
	FIIManager.reset()

func _ready() -> void:
	print("=== Testando Sistema de Poupança (Renda Fixa - Semana 3) ===")

	# 1. Teste de Fundos Totais (total_funds)
	_fresh()
	Global.player["money"] = 100.0
	Global.player["saldo"] = 150.0
	Global.player["poupanca"] = 50.0
	assert(is_equal_approx(Global.total_funds(), 300.0), "total_funds deve somar carteira, saldo e poupança")
	print("  ok   Global.total_funds() inclui carteira + saldo + poupança")

	# 2. Teste de Aplicação e Resgate
	_fresh()
	Global.player["saldo"] = 200.0
	Global.player["poupanca"] = 0.0

	# Não pode aplicar mais do que tem no saldo
	var failed_apply = Global.apply_poupanca(250.0)
	assert(failed_apply == false, "Não deve permitir aplicar valor maior que saldo bancário")
	assert(Global.player["poupanca"] == 0.0, "Poupança deve continuar 0")

	# Aplica R$ 80 com sucesso
	var success_apply = Global.apply_poupanca(80.0)
	assert(success_apply == true, "Aplicação de R$ 80 deve ser bem-sucedida")
	assert(is_equal_approx(float(Global.player["saldo"]), 120.0), "Saldo deve cair para 120")
	assert(is_equal_approx(float(Global.player["poupanca"]), 80.0), "Poupança deve ir para 80")

	# Não pode resgatar mais do que tem na poupança
	var failed_withdraw = Global.withdraw_poupanca(100.0)
	assert(failed_withdraw == false, "Não deve permitir resgatar além do saldo da poupança")

	# Resgata R$ 30 com sucesso
	var success_withdraw = Global.withdraw_poupanca(30.0)
	assert(success_withdraw == true, "Resgate de R$ 30 deve ser bem-sucedido")
	assert(is_equal_approx(float(Global.player["poupanca"]), 50.0), "Poupança deve ficar em 50")
	assert(is_equal_approx(float(Global.player["saldo"]), 150.0), "Saldo deve voltar para 150")
	print("  ok   Aplicação e Resgate de Poupança funcionam corretamente")

	# 3. Teste de Liquidez Diária e Cobrança em Cascata (charge_funds)
	_fresh()
	Global.player["money"] = 50.0
	Global.player["saldo"] = 100.0
	Global.player["poupanca"] = 100.0
	# Total = 250.0. Cobrar 200.0 deve gastar 50 de money, 100 de saldo e 50 de poupanca
	var charged = Global.charge_funds(200.0)
	assert(charged == true, "Cobrança de 200 com fundos totais de 250 deve ter sucesso")
	assert(is_equal_approx(float(Global.player["money"]), 0.0), "Carteira deve zerar primeiro")
	assert(is_equal_approx(float(Global.player["saldo"]), 0.0), "Saldo do banco deve zerar em segundo")
	assert(is_equal_approx(float(Global.player["poupanca"]), 50.0), "Poupança cobre o restante (liquidez imediata)")

	# Tentativa de cobrar mais que o total restante (50) deve falhar sem alterar nada
	var overcharge = Global.charge_funds(60.0)
	assert(overcharge == false, "Cobrança superior ao total deve falhar")
	assert(is_equal_approx(float(Global.player["poupanca"]), 50.0), "Poupança não deve ser alterada se falhar")
	print("  ok   charge_funds() consome carteira -> saldo -> poupança sem falhar")

	# 4. Teste de Rendimento Diário (Juros Compostos 0.5% ao dia)
	_fresh()
	Global.player["poupanca"] = 200.0
	Global.player["poupanca_rendimento_total"] = 0.0

	# Dia 1 fechado: 200 * 0.005 = 1.00
	TimeManager._close_day(100.0)
	assert(is_equal_approx(float(Global.player["poupanca"]), 201.00), "Dia 1: R$ 200 a 0.5%% deve render R$ 1.00 -> 201.00")
	assert(is_equal_approx(float(Global.player["poupanca_rendimento_total"]), 1.00), "Rendimento total acumulado deve ser R$ 1.00")

	# Dia 2 fechado: 201 * 0.005 = 1.005 -> 1.01
	TimeManager._close_day(100.0)
	assert(is_equal_approx(float(Global.player["poupanca"]), 202.01), "Dia 2: juros compostos calculam sobre 201.00 -> 202.01")
	assert(is_equal_approx(float(Global.player["poupanca_rendimento_total"]), 2.01), "Rendimento total acumulado deve ser R$ 2.01")
	print("  ok   Rendimento diário com juros compostos funciona conforme previsto")

	# 5. Teste de Foto e Restauração de Semana (Snapshot/Restore)
	_fresh()
	Global.player["money"] = 150.0
	Global.player["saldo"] = 250.0
	Global.player["poupanca"] = 300.0
	Global.player["poupanca_rendimento_total"] = 5.0
	Global.snapshot_week_start()

	# Altera valores durante a semana
	Global.player["money"] = 10.0
	Global.player["saldo"] = 0.0
	Global.player["poupanca"] = 50.0
	Global.player["poupanca_rendimento_total"] = 12.0

	# Restaura semana
	Global.restore_week_start()
	assert(is_equal_approx(float(Global.player["money"]), 150.0), "Restaura carteira")
	assert(is_equal_approx(float(Global.player["saldo"]), 250.0), "Restaura saldo")
	assert(is_equal_approx(float(Global.player["poupanca"]), 300.0), "Restaura poupança")
	assert(is_equal_approx(float(Global.player["poupanca_rendimento_total"]), 5.0), "Restaura rendimento acumulado")
	print("  ok   snapshot_week_start() e restore_week_start() preservam a poupança")

	# 6. Teste de Missões da Semana 3 e Semana 4
	_fresh()
	Global.player["week"] = 3
	Global.player["poupanca"] = 20.0
	MissionManager.refresh_progress(true)
	assert(MissionManager.is_completed("aplicar_poupanca") == false, "Poupança com R$ 20 não cumpre meta de R$ 50")

	Global.player["poupanca"] = 50.0
	MissionManager.refresh_progress(true)
	assert(MissionManager.is_completed("aplicar_poupanca") == true, "Poupança com R$ 50 cumpre meta de R$ 50")

	# Missão de economizar 300 na semana 3 considera total_funds (money + saldo + poupanca)
	Global.player["money"] = 100.0
	Global.player["saldo"] = 150.0
	Global.player["poupanca"] = 50.0
	MissionManager.refresh_progress(true)
	assert(MissionManager.is_completed("economizar_300_s3") == true, "total_funds de R$ 300 cumpre economizar_300_s3")

	# Verifica missões da semana 4 (FIIs)
	Global.player["week"] = 4
	MissionManager.refresh_progress(true)
	var w4_missions = MissionManager.get_missions(4)
	assert(w4_missions.size() == 3, "Semana 4 tem 3 missões")
	assert(w4_missions[0]["id"] == "investir_fii", "Missão 1 da S4 é investir_fii")
	assert(w4_missions[1]["id"] == "diversificar", "Missão 2 da S4 é diversificar")
	assert(w4_missions[2]["id"] == "lucro_fii", "Missão 3 da S4 é lucro_fii")
	print("  ok   Missões da semana 3 (Poupança) e semana 4 (FIIs) validadas")

	# 7. Teste de Liberação de Abas no Banco
	_fresh()
	var bank: Control = BANK_SCENE.instantiate()
	add_child(bank)
	var tabs: TabContainer = bank.get_node("TabContainer")

	# Semana 1: Poupança (tab 3) desativada, FII-shop (tab 4) desativada, Portfolio (tab 5) desativada
	Global.player["week"] = 1
	bank._process(0.0)
	assert(tabs.is_tab_disabled(3) == true, "S1: Poupança deve estar bloqueada")
	assert(tabs.is_tab_disabled(4) == true, "S1: FII-shop deve estar bloqueada")
	assert(tabs.is_tab_disabled(5) == true, "S1: Portfolio deve estar bloqueada")

	# Semana 2: mesma coisa
	Global.player["week"] = 2
	bank._process(0.0)
	assert(tabs.is_tab_disabled(3) == true, "S2: Poupança deve estar bloqueada")
	assert(tabs.is_tab_disabled(4) == true, "S2: FII-shop deve estar bloqueada")
	assert(tabs.is_tab_disabled(5) == true, "S2: Portfolio deve estar bloqueada")

	# Semana 3: Poupança (tab 3) LIBERADA! FIIs continuam bloqueados até semana 4
	Global.player["week"] = 3
	bank._process(0.0)
	assert(tabs.is_tab_disabled(3) == false, "S3: Poupança DEVE ESTAR LIBERADA")
	assert(tabs.is_tab_disabled(4) == true, "S3: FII-shop continua bloqueada")
	assert(tabs.is_tab_disabled(5) == true, "S3: Portfolio continua bloqueada")

	# Semana 4: Tudo liberado
	Global.player["week"] = 4
	bank._process(0.0)
	assert(tabs.is_tab_disabled(3) == false, "S4: Poupança liberada")
	assert(tabs.is_tab_disabled(4) == false, "S4: FII-shop liberada")
	assert(tabs.is_tab_disabled(5) == false, "S4: Portfolio liberada")

	# Teste de transações na UI do Banco
	Global.player["saldo"] = 200.0
	Global.player["poupanca"] = 0.0
	bank.update_labels()

	# Simula clique no botão Aplicar
	bank._on_apply_poupanca_pressed()
	var input: LineEdit = bank.get_node("Transaction-panel/Panel/Input")
	var confirm: Button = bank.get_node("Transaction-panel/Panel/Confirm")
	input.text = "75"
	confirm.pressed.emit()
	assert(is_equal_approx(float(Global.player["poupanca"]), 75.0), "UI: Aplicou R$ 75 na poupança")
	assert(is_equal_approx(float(Global.player["saldo"]), 125.0), "UI: Saldo reduziu para R$ 125")

	# Simula clique no botão Resgatar
	bank._on_withdraw_poupanca_pressed()
	input.text = "25"
	confirm.pressed.emit()
	assert(is_equal_approx(float(Global.player["poupanca"]), 50.0), "UI: Resgatou R$ 25 da poupança")
	assert(is_equal_approx(float(Global.player["saldo"]), 150.0), "UI: Saldo voltou para R$ 150")

	remove_child(bank)
	bank.free()
	print("  ok   Abas do banco e transações de Poupança na UI funcionam perfeitamente")

	print("=== TODOS OS TESTES DE POUPANÇA PASSARAM COM SUCESSO! ===")
	get_tree().quit(0)
