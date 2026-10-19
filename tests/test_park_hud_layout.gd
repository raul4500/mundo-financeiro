extends Node

const SessionScript = preload("res://scripts/park/park_minigame_session.gd")
const MissionsScript = preload("res://scripts/hud/missions_ui.gd")
const UI_THEME = preload("res://themes/font_theme.tres")

# Monta a casca que player.tscn fornece ao script de missões:
# CanvasLayer > Open (Button) e Overlay (Panel) > Panel > MissionList.
func _make_missions_ui() -> CanvasLayer:
	var ui := CanvasLayer.new()
	ui.set_script(MissionsScript)
	var open := Button.new()
	open.name = "Open"
	ui.add_child(open)
	var overlay := Panel.new()
	overlay.name = "Overlay"
	overlay.visible = false
	var inner := Panel.new()
	inner.name = "Panel"
	var list := VBoxContainer.new()
	list.name = "MissionList"
	inner.add_child(list)
	overlay.add_child(inner)
	ui.add_child(overlay)
	add_child(ui)
	return ui

func _ready() -> void:
	print("=== Testando HUD do minigame do parque ===")

	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	Global.player_hud_hidden = false
	ParkMinigameManager.end_session()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	# 1. Botão de missões some com o HUD do personagem escondido, e volta depois.
	var missions := _make_missions_ui()
	var open: Button = missions.get_node("Open")
	var overlay: Control = missions.get_node("Overlay")
	missions._process(0.0)
	assert(open.visible, "Com o HUD normal o botão de missões aparece")
	overlay.visible = true

	Global.player_hud_hidden = true
	missions._process(0.0)
	assert(not open.visible, "Com o HUD escondido (minigame do parque) o botão de missões some")
	assert(not overlay.visible, "Um painel de missões aberto fecha junto")

	Global.player_hud_hidden = false
	missions._process(0.0)
	assert(open.visible, "Ao sair do minigame o botão volta")
	print("  ok   Botão de missões some durante o minigame e volta depois")

	# 2. HUD da sessão: moedas à esquerda, tempo no centro, dica à direita, tudo no font_theme.
	var world := Node2D.new()
	add_child(world)
	var session := CanvasLayer.new()
	session.set_script(SessionScript)
	add_child(session)
	session.start(world, PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)]))
	assert(Global.player_hud_hidden, "A sessão esconde o HUD do personagem")

	await get_tree().process_frame
	await get_tree().process_frame

	var coins: Label = session._score_label
	var timer: Label = session._timer_label
	var hint: Label = null
	var row: Node = session.get_child(0).get_child(0).get_child(0)
	for cell in row.get_children():
		for child in cell.get_children():
			if child is Label and child != coins and child != timer:
				hint = child
	assert(hint != null, "A dica de sair existe")
	assert(hint.text == "Pressione BACKSPACE para sair", "Texto da dica")

	var width := get_viewport().get_visible_rect().size.x
	var coins_rect := coins.get_global_rect()
	var timer_rect := timer.get_global_rect()
	var hint_rect := hint.get_global_rect()
	assert(coins_rect.position.x < 40.0, "Moedas no canto esquerdo (x = %.0f)" % coins_rect.position.x)
	assert(absf(timer_rect.get_center().x - width / 2.0) < 2.0, "Tempo no centro (centro em %.0f, tela %.0f)" % [timer_rect.get_center().x, width])
	assert(hint_rect.end.x > width - 40.0, "Dica no canto direito (borda em %.0f, tela %.0f)" % [hint_rect.end.x, width])
	assert(coins_rect.position.y < 30.0 and timer_rect.position.y < 30.0 and hint_rect.position.y < 30.0, "Os três no topo da tela")
	assert(coins.theme == UI_THEME and timer.theme == UI_THEME and hint.theme == UI_THEME, "Os três labels usam o font_theme.tres")
	print("  ok   Moedas à esquerda, tempo ao centro, dica à direita, todos no font_theme")

	# 3. Os valores aparecem.
	assert(coins.text == "Moedas: 0", "Texto das moedas (veio '%s')" % coins.text)
	assert(timer.text.ends_with(" s"), "Texto do tempo (veio '%s')" % timer.text)
	print("  ok   Textos de moedas e tempo")

	session._quit_session()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()
	print("=== Todos os testes do HUD do parque passaram ===")
	get_tree().quit(0)
