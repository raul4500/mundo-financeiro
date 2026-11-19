extends Node2D

var scene: Resource
var character: Node2D

@onready var player_node = $Player
@onready var poles = $"Light-poles"

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	TutorialManager.focus.connect(_focus)
	scene = load("res://scenes/players/player.tscn")
	character = scene.instantiate()
	var pos = Global.player["position"]
	character.global_position = Vector2(pos["x"], pos["y"])
	player_node.add_child(character)
	if Global.player.get("return_home_next_day", false):
		var home_collision = get_node_or_null("Doors/Home_door/CollisionShape2D")
		if home_collision != null:
			character.global_position = home_collision.global_position + Vector2(0, 10)
			Global.player["position"]["x"] = character.global_position.x
			Global.player["position"]["y"] = character.global_position.y
		Global.player["return_home_next_day"] = false
	CameraManager.register_player(character)
	
	for pole in poles.get_children():
		pole.offset = Vector2(0, -17)
		pole.global_position.y += 17
	
	# Faixa em vez de lista de passos: acima de FINAL_STEP o tutorial acabou (ou
	# foi pulado) e nada deve ser repetido. Enquanto isto era um match com o
	# último passo dentro da lista, o tour do mundo voltava toda vez que o
	# jogador entrava aqui — vindo do mercado, do banco ou do minigame.
	var tutorial_step := int(Global.player.get("tutorial_step", 1))
	if tutorial_step == 1:
		TutorialManager.start_tutorial()
	elif tutorial_step <= TutorialManager.FINAL_STEP:
		TutorialManager.resume_tutorial(tutorial_step)
	elif not TransitionManager.is_transitioning() and not AlertManager.panel.visible:
		Global.force_release_all_gameplay_locks()

func _on_tree_exited() -> void:
	Global.player["position"]["x"] = character.global_position.x
	Global.player["position"]["y"] = character.global_position.y

func _on_tree_entered() -> void:
	if not Global.is_any_tutorial_active():
		Global.play_time = true
	
func _process(delta: float) -> void:
	pass
		
func _focus(point: String) -> void:
	# Busca o nó de foco sob Camera-focusPoints; se não existir, faz return.
	var path = "Camera-focusPoints/" + point
	if not has_node(path):
		push_warning("main_game._focus: foco não encontrado: %s" % path)
		return
	var target_node = get_node(path)
	# Se há mensagens enfileiradas no TutorialManager, usamos goto() — isto
	# move a câmera até o ponto e a mantém lá; o TutorialManager aguardará
	# CameraManager.focus_arrived antes de exibir o alerta.
	# Se não há mensagens (ex.: passo 5, ir para a escola), usamos o comportamento
	# legado focus() que move para o ponto, espera e retorna a câmera ao jogador
	# automaticamente para evitar travar o jogo aguardando que o jogador entre.
	if not TutorialManager.pending_messages.is_empty():
		await CameraManager.goto(target_node)
	else:
		# Mantém compatibilidade com fluxo antigo (vai e volta)
		await CameraManager.focus(target_node)
		if has_node("/root/Global"):
			Global.force_release_all_gameplay_locks()

