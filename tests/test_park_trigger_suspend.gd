extends Node

const TriggerScript = preload("res://scripts/park/park_minigame_trigger.gd")

# Monta a casca que main_game.tscn fornece ao script do gatilho do parque:
# Area2D > Info-panel (Panel) > Margin > VBoxContainer > Hint (Label).
func _make_trigger() -> Area2D:
	var trigger := Area2D.new()
	trigger.set_script(TriggerScript)
	var panel := Panel.new()
	panel.name = "Info-panel"
	panel.visible = false
	var margin := MarginContainer.new()
	margin.name = "Margin"
	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	var hint := Label.new()
	hint.name = "Hint"
	box.add_child(hint)
	margin.add_child(box)
	panel.add_child(margin)
	trigger.add_child(panel)
	add_child(trigger)
	return trigger

func _ready() -> void:
	print("=== Testando gatilho do parque durante o minigame ===")

	Global.player = Global._new_player_data()
	Global.player["name"] = "Raul"
	Global.player["tutorial_step"] = TutorialManager.TUTORIAL_DONE
	Global.player["unlock_stage"] = Global.UNLOCK_ALL
	ParkMinigameManager.end_session()
	AlertManager.reset()
	Global.force_release_all_gameplay_locks()

	var trigger := _make_trigger()
	var panel: Panel = trigger.get_node("Info-panel")

	# 1. Antes da sessão o gatilho funciona: entrar na área mostra o painel.
	trigger._on_body_shape_entered(RID(), null, 0, 0)
	assert(panel.visible, "Entrar na área mostra o painel")
	assert(trigger.player_inside, "player_inside liga ao entrar")
	print("  ok   Fora da sessão o painel aparece ao entrar na área")

	# 2. Sessão ativa: o gatilho se desativa (painel some, área para de monitorar).
	ParkMinigameManager.begin_session()
	trigger._process(0.0)
	assert(not panel.visible, "Com a sessão ativa o painel some")
	assert(not trigger.player_inside, "player_inside zera: sair durante a sessão não gera body_shape_exited")
	await get_tree().process_frame
	assert(not trigger.monitoring, "A área para de monitorar durante a sessão")

	# Um evento de entrada que chegue já desativado não pode reabrir o painel.
	trigger._on_body_shape_entered(RID(), null, 0, 0)
	assert(not panel.visible, "Entrada durante a sessão não mostra o painel")
	print("  ok   Durante a sessão o painel fica escondido e a área desligada")

	# 3. Sessão encerrada: o gatilho volta sozinho.
	ParkMinigameManager.end_session()
	trigger._process(0.0)
	await get_tree().process_frame
	assert(trigger.monitoring, "A área volta a monitorar quando a sessão acaba")
	trigger._on_body_shape_entered(RID(), null, 0, 0)
	assert(panel.visible, "Depois da sessão o painel volta a aparecer ao entrar")
	print("  ok   Depois da sessão o gatilho volta ao normal")

	print("=== Todos os testes do gatilho do parque passaram ===")
	get_tree().quit(0)
