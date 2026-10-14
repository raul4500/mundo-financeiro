extends Node

func _ready() -> void:
	print("=== Testando Exclusão de Save e Bloqueio de Continuar ao Morrer de Fome ===")
	
	# Cenário 1: Jogo com save válido
	Global.player["name"] = "RaulTeste"
	Global.player["hunger"] = 100.0
	Global.player["thirst"] = 100.0
	SaveManager.save_game()
	assert(SaveManager.has_save() == true, "Save deve existir após save_game")
	print("  ok   Save criado com sucesso no disco")
	
	# Verifica menu principal com save ativo
	var menu_scene = load("res://scenes/menus/main_menu.tscn")
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	var continue_btn = menu_instance.get_node("GridContainer/start")
	assert(continue_btn.visible == true, "Botão Continuar deve estar visível quando há save válido")
	print("  ok   Botão Continuar visível no menu principal com save válido")
	menu_instance.queue_free()
	
	# Cenário 2: Personagem morre de fome
	Global.player["hunger"] = 0.0
	Global.trigger_game_over("Você morreu de fome!")
	assert(Global.is_game_over() == true, "Global.is_game_over() deve ser true")
	assert(SaveManager.has_save() == false, "Save deve ter sido apagado imediatamente no trigger_game_over")
	print("  ok   Save apagado do disco imediatamente ao morrer de fome")
	
	# Cenário 3: Tentativa de autosave durante game over não deve ressuscitar o save
	SaveManager.save_game()
	assert(SaveManager.has_save() == false, "save_game() durante game over NÃO deve recriar o arquivo")
	print("  ok   save_game() bloqueado durante game over")
	
	# Cenário 4: Callback do modal de Game Over retornando ao menu inicial
	# Simula a chamada do callback de fechamento do alerta
	Global._return_to_main_menu()
	assert(Global.player["name"] == "", "Nome do jogador em memória deve ser resetado para vazio")
	assert(Global.player["hunger"] == 100.0, "Fome em memória deve ser resetada para o padrão do modelo")
	assert(Global.is_game_over() == false, "_game_over deve voltar a false")
	assert(SaveManager.has_save() == false, "Save continua não existindo")
	print("  ok   Estado em memória totalmente resetado após retorno ao menu")
	
	# Cenário 5: Verificação do Menu Principal após a morte
	var menu_after_death = menu_scene.instantiate()
	add_child(menu_after_death)
	var continue_btn_after = menu_after_death.get_node("GridContainer/start")
	assert(continue_btn_after.visible == false, "Botão Continuar NÃO deve aparecer após a morte")
	print("  ok   Botão Continuar oculto no menu após a morte do personagem")
	
	# Cenário 6: Se tentar chamar start(), não deve entrar no jogo
	menu_after_death.start()
	assert(SaveManager.has_save() == false, "start() não deve fazer nada sem save")
	print("  ok   start() bloqueado sem save válido")
	menu_after_death.queue_free()
	
	# Cenário 7: Proteção contra save legado corrompido com fome zerada
	# Cria intencionalmente um save com fome = 0 no disco para testar a proteção do load_game
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string('{"name": "Zumbi", "hunger": 0.0, "thirst": 50.0}')
	f.close()
	assert(SaveManager.has_save() == true, "Arquivo de teste gravado")
	var loaded = SaveManager.load_game()
	assert(loaded == false, "load_game deve rejeitar save com fome zerada")
	assert(SaveManager.has_save() == false, "load_game deve ter excluído o save do zumbi")
	print("  ok   load_game rejeita e exclui save com personagem morto")
	
	print("=== Todos os testes de exclusão de save na morte de fome passaram com sucesso! ===")
	get_tree().quit(0)
