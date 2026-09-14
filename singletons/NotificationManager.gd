extends CanvasLayer

# Toast de canto: aparece, some sozinho e NUNCA trava o gameplay.
# Para mensagens que exigem confirmação do jogador, use o AlertManager.
#
#     NotificationManager.notify("Missão concluída: Economize R$100")
#     NotificationManager.notify("Conta paga", 5.0)

const DEFAULT_DURATION := 3.0
const FADE := 0.25
# Acima disso o mais antigo sai para a pilha não escorrer para fora da tela.
const MAX_VISIBLE := 4
const WIDTH := 320
const STACK_HEIGHT := 420
# Começa abaixo do botão "MISSÕES (F)", que ocupa o topo direito até y = 65.
const TOP_MARGIN := 80.0
const SIDE_MARGIN := 16.0

var _stack: VBoxContainer


func _ready() -> void:
	# Abaixo do AlertManager (100) e do TransitionManager (200), acima dos HUDs.
	layer = 90
	# Um Tween segue o process_mode do nó dono: sem ALWAYS, uma notificação
	# aberta com a árvore pausada (menu de pausa) congelaria na tela para sempre.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_stack = VBoxContainer.new()
	_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stack.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stack.offset_left = -(WIDTH + SIDE_MARGIN)
	_stack.offset_right = -SIDE_MARGIN
	_stack.offset_top = TOP_MARGIN
	# Um Container distribui os filhos dentro do próprio retângulo: sem altura
	# real aqui, os toasts nasceriam com altura zero e não apareceriam.
	_stack.offset_bottom = TOP_MARGIN + STACK_HEIGHT
	_stack.add_theme_constant_override("separation", 8)
	# O toast é decorativo: não pode roubar o clique de nada que esteja embaixo.
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stack)


func notify(text: String, duration: float = DEFAULT_DURATION) -> void:
	if text.strip_edges() == "":
		return

	while _stack.get_child_count() >= MAX_VISIBLE:
		var oldest := _stack.get_child(0)
		_stack.remove_child(oldest)
		oldest.queue_free()

	var toast := PanelContainer.new()
	toast.theme = load("res://themes/font_theme.tres")
	toast.custom_minimum_size = Vector2(WIDTH, 0)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)

	# label.tres, e não o tema do painel: font_theme propaga
	# Label/styles/normal = label_round.png e corpo 24 para os descendentes.
	var label := Label.new()
	label.theme = load("res://themes/label.tres")
	label.add_theme_font_size_override("font_size", 16)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	margin.add_child(label)
	toast.add_child(margin)
	_stack.add_child(toast)

	# O tween nasce no toast, não no autoload: assim ele morre junto se o toast
	# for removido antes da hora pelo limite de MAX_VISIBLE.
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, FADE)
	tween.tween_interval(maxf(0.0, duration - FADE * 2.0))
	tween.tween_property(toast, "modulate:a", 0.0, FADE)
	tween.tween_callback(toast.queue_free)


func clear() -> void:
	for toast in _stack.get_children():
		_stack.remove_child(toast)
		toast.queue_free()
