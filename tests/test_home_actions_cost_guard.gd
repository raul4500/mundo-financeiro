extends Node

func _ready() -> void:
	print("=== Testando Bloqueio de Ações na Casa com Gasto Maior que Nível Atual ===")
	
	# Garante player limpo e fora do tutorial para testar a mecânica de sobrevivência
	Global.player["name"] = "Raul"
	Global.player["tutorial_step"] = Global.LEGACY_TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	Global._game_over = false
	
	# Cenário 1: Descansar custa 12 de fome. Jogador tem 10 de fome. (12 > 10)
	Global.player["hunger"] = 10.0
	Global.player["stamina"] = 50.0
	var res1 = Global.apply_home_action("VOCÊ DESCANSOU.", -12.0, 18.0, 1.0)
	assert(res1["success"] == false, "Descansar deve falhar quando gasto (12) > fome atual (10)")
	assert(Global.player["hunger"] == 10.0, "Fome não deve ser deduzida quando ação é proibida")
	assert(Global.player["stamina"] == 50.0, "Stamina não deve ser alterada quando ação é proibida")
	assert(not Global.is_game_over(), "Game over NÃO deve ser disparado")
	print("  ok   Descansar bloqueado quando gasto (12) > fome (10)")
	
	# Cenário 2: Assistir TV custa 6 de fome. Jogador tem 4 de fome. (6 > 4)
	Global.player["hunger"] = 4.0
	var res2 = Global.apply_home_action("VOCÊ ASSISTIU TV.", -6.0, 14.0, 1.0)
	assert(res2["success"] == false, "Assistir TV deve falhar quando gasto (6) > fome atual (4)")
	assert(Global.player["hunger"] == 4.0, "Fome não deve mudar")
	assert(not Global.is_game_over(), "Game over NÃO deve ser disparado")
	print("  ok   Assistir TV bloqueado quando gasto (6) > fome (4)")
	
	# Cenário 3: Jogador tem fome suficiente (20 de fome, gasta 12)
	Global.player["hunger"] = 20.0
	Global.player["stamina"] = 50.0
	var res3 = Global.apply_home_action("VOCÊ DESCANSOU.", -12.0, 18.0, 1.0)
	assert(res3["success"] == true, "Descansar deve ser permitido quando fome (20) >= gasto (12)")
	# 20 - 12 (ação) - 1.2 (decaimento de 1h de descanso a 0.02/min) = 6.8
	assert(is_equal_approx(float(Global.player["hunger"]), 6.8), "Fome deve cair para ~6.8 após ação e 1h de descanso")
	assert(Global.player["stamina"] > 50.0, "Stamina líquida deve ter aumentado")
	assert(not Global.is_game_over(), "Game over NÃO deve ser disparado")
	print("  ok   Descansar permitido normalmente quando jogador tem fome suficiente")
	
	# Cenário 4: Gasto de sede maior do que a sede atual (gasta 10 de sede, tem 5)
	Global.player["thirst"] = 5.0
	var res4 = Global.apply_home_action("AÇÃO DE TESTE SEDE", 0.0, 10.0, 1.0, -10.0)
	assert(res4["success"] == false, "Ação que consome sede deve falhar quando gasto (10) > sede atual (5)")
	assert(Global.player["thirst"] == 5.0, "Sede não deve mudar quando ação é proibida")
	assert(not Global.is_game_over(), "Game over NÃO deve ser disparado")
	print("  ok   Ação com gasto de sede bloqueada quando gasto (10) > sede (5)")
	
	# Cenário 5: Gasto de sede permitido quando jogador tem sede suficiente (tem 25, gasta 10)
	Global.player["thirst"] = 25.0
	var res5 = Global.apply_home_action("AÇÃO DE TESTE SEDE", 0.0, 10.0, 1.0, -10.0)
	assert(res5["success"] == true, "Ação com sede permitida quando sede (25) >= gasto (10)")
	# 25 - 10 (ação) - 4.2 (decaimento de 1h a 0.07/min) = 10.8
	assert(is_equal_approx(float(Global.player["thirst"]), 10.8), "Sede deve cair para ~10.8 após ação e 1h de tempo")
	assert(not Global.is_game_over(), "Game over NÃO deve ser disparado")
	print("  ok   Ação com gasto de sede permitida quando jogador tem sede suficiente")
	
	# Cenário 6: Integração com a UI da casa (home.gd)
	var home_scene = load("res://scenes/world/places/home.tscn")
	var home_instance = home_scene.instantiate()
	add_child(home_instance)
	Global.player["hunger"] = 5.0
	home_instance._on_rest_pressed()
	var status_msg = home_instance.status_label.text
	assert(status_msg == "Você está com muita fome para realizar esta ação.", "Mensagem de feedback na UI da casa deve informar que está com muita fome")
	assert(Global.player["hunger"] == 5.0, "Fome permanece em 5.0")
	home_instance.queue_free()
	print("  ok   UI da casa reflete mensagem de bloqueio corretamente")
	
	print("=== Todos os testes de bloqueio de ações na casa passaram com sucesso! ===")
	get_tree().quit(0)
