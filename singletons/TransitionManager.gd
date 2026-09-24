extends CanvasLayer

# =============================================================
# TRANSIÇÕES ENTRE CENAS
# Ponto único de troca de cena do jogo. Faz fade-out, troca e
# fade-in, para nenhum lugar precisar repetir o efeito.
#
# IMPORTANTE: quem chama NÃO deve usar await. Ao trocar de cena o
# nó que chamou é liberado; se ele estivesse esperando a corrotina,
# retomaria já morto. A corrotina vive aqui, que é autoload e
# sobrevive à troca.
#     TransitionManager.change_scene(caminho)        # certo
#     await TransitionManager.change_scene(caminho)  # errado
# =============================================================

const FADE_DURATION := 0.35

var fade_rect: ColorRect
var _transitioning := false

func _ready() -> void:
	# 200 fica acima do AlertManager (100) e do diálogo de compra das portas
	# (90), para o fade cobrir a tela inteira, inclusive alertas abertos.
	layer = 200
	# ALWAYS: um Tween segue o process_mode do nó dono. Se uma transição
	# começasse com a árvore pausada (menu de pausa), o tween congelaria, o
	# await nunca voltaria e o jogo ficaria travado com _transitioning = true.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_fade_rect()

func _create_fade_rect() -> void:
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.modulate.a = 0.0
	fade_rect.visible = false
	# STOP durante a transição bloqueia clique em botões da cena que está
	# saindo; como o nó fica invisível fora da transição, não atrapalha.
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fade_rect)

func change_scene(path: String) -> void:
	# As portas usam Input.is_key_pressed dentro de _process, que é verdadeiro
	# todo frame enquanto a tecla está segurada. Sem esta guarda, um fade de
	# 0.35s viraria dezenas de chamadas seguidas.
	if _transitioning:
		return
	_transitioning = true
	Global.lock_gameplay()

	await _fade_to(1.0)

	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("TransitionManager: falha ao carregar '%s' (erro %d)." % [path, error])
	else:
		# Um frame para a nova cena entrar na árvore antes de clarear.
		await get_tree().process_frame

	await _fade_to(0.0)

	# Sempre destrava, inclusive quando a cena falha ao carregar: senão o
	# contador de gameplay_locked fica preso e o jogo trava de vez.
	fade_rect.visible = false
	Global.unlock_gameplay()
	_transitioning = false

func _fade_to(target_alpha: float) -> void:
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, FADE_DURATION)
	await tween.finished

func is_transitioning() -> bool:
	return _transitioning

