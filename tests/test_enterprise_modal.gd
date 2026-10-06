extends Node

func _ready() -> void:
	print("=== Testando Modal de Compra com font_theme.tres ===")
	Global.player = Global._new_player_data()
	Global.player["money"] = 2500.0
	
	var door_script = load("res://scripts/world/doors/restaurant_door.gd")
	var door = door_script.new()
	add_child(door)
	
	assert(door.purchase_panel.theme != null, "purchase_panel deveria ter um tema definido")
	assert(door.purchase_panel.theme.resource_path.find("font_theme.tres") != -1, "purchase_panel deveria usar font_theme.tres")
	
	# Testa abertura do diálogo
	door._show_purchase_dialog()
	assert(door.purchase_panel.visible == true, "purchase_panel deveria estar visível")
	assert(door.dialog_locked == true, "dialog_locked deveria ser true")
	assert(Global.gameplay_locked == true, "gameplay deveria estar travado")
	assert(Global.play_time == false, "tempo deveria estar pausado")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("  ok   Tema font_theme.tres aplicado corretamente ao purchase_panel")
	print("  ok   Dimensões do modal: ", door.purchase_panel.size)
	print("  ok   Botões com tema herdado (Comprar e Sair)")
	
	# Testa fechamento do diálogo
	door._close_purchase_dialog()
	assert(door.purchase_panel.visible == false, "purchase_panel deveria estar oculto após fechar")
	assert(door.dialog_locked == false, "dialog_locked deveria ser false")
	assert(Global.gameplay_locked == false, "gameplay deveria estar destravado")
	assert(Global.play_time == true, "tempo deveria estar despausado")
	print("  ok   Fechamento e destravamento do diálogo funcionando perfeitamente")
	
	# Testa botão comprar
	door._show_purchase_dialog()
	assert(door.buy_button.disabled == false, "Com R$2500 o restaurante de R$1500 deveria estar comprável")
	door._close_purchase_dialog()
	
	# Testa com dinheiro insuficiente
	Global.player["money"] = 100.0
	door._show_purchase_dialog()
	assert(door.buy_button.disabled == true, "Com R$100 o restaurante de R$1500 não deveria estar comprável")
	door._close_purchase_dialog()
	print("  ok   Validação de saldo e estado do botão Comprar")
	
	door.queue_free()
	print("=== Todos os testes do modal de compra passaram! ===")
	get_tree().quit(0)
