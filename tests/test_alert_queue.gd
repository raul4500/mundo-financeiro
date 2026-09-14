extends Node

func _ready() -> void:
	print("=== Testando fila de alertas e alerta com escolhas ===")

	Global.player = Global._new_player_data()
	# Determinístico: zera o que o boot possa ter enfileirado (tutorial, etc.),
	# senão as asserções de texto abaixo leriam a mensagem errada.
	AlertManager._queue.clear()
	AlertManager._clear_choices()
	AlertManager.panel.visible = false
	AlertManager.blocker.visible = false
	Global.force_release_all_gameplay_locks()

	# 1. Três alertas em sequência (é o que a virada de semana faz: missões,
	#    tutorial e evento) saem um por vez. O bug que isto protege: eram N
	#    lock_gameplay() para 1 unlock_gameplay(), então o contador nunca
	#    voltava a zero e o jogador ficava preso sem conseguir se mover.
	AlertManager.alert("primeiro")
	AlertManager.alert("segundo")
	AlertManager.alert("terceiro")
	assert(AlertManager.panel.visible == true, "O primeiro alerta deveria estar na tela")
	assert(AlertManager.alert_label.text == "primeiro", "Deveria mostrar 'primeiro', veio '%s'" % AlertManager.alert_label.text)
	assert(Global.gameplay_locked == true, "Alerta aberto deveria travar o gameplay")

	AlertManager._close_alert()
	assert(AlertManager.alert_label.text == "segundo", "Fechar deveria puxar 'segundo', veio '%s'" % AlertManager.alert_label.text)
	assert(Global.gameplay_locked == true, "Ainda há alerta na tela")

	AlertManager._close_alert()
	assert(AlertManager.alert_label.text == "terceiro", "Fechar deveria puxar 'terceiro', veio '%s'" % AlertManager.alert_label.text)

	AlertManager._close_alert()
	assert(AlertManager.panel.visible == false, "Fila vazia deveria fechar o alerta")
	assert(Global.gameplay_locked == false, "Fila vazia deveria destravar o gameplay")
	print("  ok   Fila mostra um por vez e o lock fecha em zero")

	# 2. Alerta com escolhas troca o OK por N botões.
	var escolhido: Array = []
	AlertManager.alert_choice("decida", [
		{"text": "A", "callback": func(): escolhido.append("A")},
		{"text": "B", "callback": func(): escolhido.append("B")}
	])
	assert(AlertManager.choice_box.visible == true, "Os botões de escolha deveriam aparecer")
	assert(AlertManager.choice_box.get_child_count() == 2, "Deveria haver 2 botões de escolha")
	assert(AlertManager.confirm_button.visible == false, "O botão OK não aparece com escolhas")
	assert(Global.gameplay_locked == true, "Alerta de escolha deveria travar o gameplay")
	print("  ok   Escolhas substituem o botão OK")

	# 3. Clicar numa opção roda só o callback dela, fecha e limpa os botões.
	AlertManager.choice_box.get_child(0).emit_signal("pressed")
	assert(escolhido == ["A"], "Deveria ter rodado o callback de A, veio %s" % str(escolhido))
	assert(AlertManager.panel.visible == false, "Escolher deveria fechar o alerta")
	assert(Global.gameplay_locked == false, "Escolher deveria destravar o gameplay")
	assert(AlertManager.choice_box.get_child_count() == 0, "Os botões deveriam ter sido limpos")
	print("  ok   Escolha roda o callback, fecha e limpa os botões")

	# 4. Escolha que enfileira outro alerta (é o que o evento faz ao confirmar a
	#    conta gerada): o segundo tem de aparecer e o lock continuar pareado.
	AlertManager.alert_choice("decida de novo", [
		{"text": "Comprar", "callback": func(): AlertManager.alert("conta criada")}
	])
	AlertManager.choice_box.get_child(0).emit_signal("pressed")
	assert(AlertManager.panel.visible == true, "O alerta enfileirado pelo callback deveria abrir")
	assert(AlertManager.alert_label.text == "conta criada", "Deveria mostrar o alerta do callback, veio '%s'" % AlertManager.alert_label.text)
	assert(Global.gameplay_locked == true, "O alerta encadeado deveria manter o gameplay travado")
	AlertManager._close_alert()
	assert(Global.gameplay_locked == false, "Depois de tudo fechado o gameplay deveria destravar")
	print("  ok   Callback pode encadear outro alerta sem furar o lock")

	# 5. alert_choice() sem opções cai no alerta normal, com OK de volta.
	AlertManager.alert_choice("sem opções", [])
	assert(AlertManager.confirm_button.visible == true, "Sem escolhas, o OK volta")
	assert(AlertManager.choice_box.visible == false, "Sem escolhas, a caixa de botões fica escondida")
	AlertManager._close_alert()
	assert(Global.gameplay_locked == false, "O gameplay deveria terminar destravado")
	print("  ok   alert_choice() sem opções vira alerta comum")

	print("=== Todos os testes de alerta passaram ===")
