extends CanvasLayer

# Guia do Jogo: consulta permanente das regras (tecla J, botão GUIA no topo ou
# botão "Guia do Jogo" do menu de pausa).
#
# O botão GUIA mora em player.tscn, ao lado do MISSÕES, e é ligado por
# MissionsUi (scripts/hud/missions_ui.gd): assim os dois botões do topo têm o
# mesmo tamanho, a mesma camada e somem juntos sob o painel de missões. Este
# script cuida só da janela.
#
# Visual: tudo vem de themes/font_theme.tres. Painel e botões do tema, texto
# preto (RichTextLabel/default_color) sobre o papel creme, tópico escolhido no
# estado "pressed" do botão. Nenhuma cor fica solta no código.

const UI_THEME := preload("res://themes/font_theme.tres")
const LABEL_THEME := preload("res://themes/label.tres")
const DebtRules = preload("res://scripts/economy/debt_rules.gd")

const DIALOG_SIZE := Vector2(860, 500)
const TOPICS_WIDTH := 230.0
const CLOSE_BUTTON_WIDTH := 120.0
const BODY_FONT_SIZE := 18
const HEADING_FONT_SIZE := 26

# Cada tópico: título do botão, título do texto e a lista de itens. Os números
# entre chaves ({...}) vêm das constantes do jogo (ver _tokens), então o guia
# não fica desatualizado quando uma regra muda de valor.
const TOPICS := [
	{
		"title": "Controles e atalhos",
		"heading": "Comandos do jogo",
		"items": [
			"Andar: W, A, S, D ou as Setas do teclado.",
			"Entrar nos lugares: chegue perto da porta e pressione ENTER.",
			"Confirmar alertas e avançar diálogos: ESPAÇO ou ENTER.",
			"Minigame da escola: ESPAÇO pula os obstáculos.",
			"Parque: BACKSPACE sai da corrida de moedas.",
			"Missões da semana: botão MISSÕES ou tecla M (ou F).",
			"Este guia: botão GUIA ou tecla J (ou G).",
			"Pausar, salvar e sair: ESC.",
		],
	},
	{
		"title": "Rotina e casa",
		"heading": "Rotina diária e sobrevivência",
		"items": [
			"Relógio: o dia começa às 08h. Às 18h chega o aviso de cansaço, mas o dia só termina quando você dorme em casa.",
			"Stamina: cai ao longo do dia. DORMIR em casa (liberado a partir das 18h) recupera 100%. DESCANSAR e ASSISTIR TV recuperam só um pouco.",
			"Virar a noite: à meia-noite você volta para casa à força, paga R$ {midnight_cost} de café e acorda com apenas metade da stamina.",
			"Fome, sede e stamina: se qualquer uma chegar a zero, você desmaia, paga R$ {midnight_cost} de socorro e perde o resto do dia.",
			"Estoque da casa: o que você compra no Mercado vai para a Casa. Abra as abas COMIDAS ou BEBIDAS e use COMER ou BEBER no item escolhido.",
		],
	},
	{
		"title": "Escola e carreira",
		"heading": "Formação escolar e salário",
		"items": [
			"Corrida: na Escola seu personagem corre sozinho e você pula os obstáculos com ESPAÇO.",
			"Checkpoints: cada checkpoint alcançado sobe 1 nível de escolaridade, até o Doutorado, e aumenta seu salário semanal.",
			"Primeira corrida: é a formação inicial. Você sobe quantos níveis conseguir, até esbarrar em um obstáculo.",
			"Corridas seguintes: cada tentativa vale no máximo 1 nível, e a escola só reabre na semana seguinte. A porta avisa quando.",
			"Se bater antes do checkpoint, a escola fecha por {fail_days} dias.",
		],
	},
	{
		"title": "Locais da cidade",
		"heading": "Guia dos estabelecimentos",
		"items": [
			"Consultoria Financeira: aulas semanais sobre finanças, com o relógio parado. Na Semana 1, leia todos os tópicos e clique em 'Concluir aula' para liberar a cidade.",
			"Mercado: comidas e bebidas. Compare o preço por ponto de fome ou sede antes de comprar (necessidade x desejo).",
			"Banco: guarde dinheiro, pague as contas da casa e os eventos pendentes, use a poupança e invista em fundos.",
			"Parque: corrida de moedas de {park_seconds} segundos, até {park_plays} vezes por dia, aberta até as {park_hour} e só com fome, sede e stamina acima de {park_status}%. A cada {park_coins} moedas vem uma pergunta: acertando, você ganha {park_discount}% de desconto na próxima compra do mercado.",
			"Empreendimentos: Restaurante, Fliperama e Centro Comercial, para compra e gestão avançada.",
		],
	},
	{
		"title": "Finanças e investimentos",
		"heading": "Educação financeira na prática",
		"items": [
			"Missões: cumpra as metas da semana até o 5º dia. Se alguma falhar, a semana se repete e seu dinheiro volta ao valor do início dela.",
			"Contas e eventos (Semana 2+): ficam no Banco, com vencimento e data limite. Depois do vencimento a conta cresce {interest}% ao dia, com juros sobre juros. Na data limite o jogo cobra sozinho, da carteira e do banco.",
			"Reserva de emergência: mantenha dinheiro guardado no Banco para pagar imprevistos sem atrasar.",
			"Poupança (Semana 3+): rende {savings_rate}% ao dia dormido, com juros compostos e resgate imediato.",
			"Fundos imobiliários (Semana 4+): pagam dividendos, mas as cotas oscilam. Vender abaixo do preço médio pago cobra {fii_tax}% de imposto sobre o prejuízo. Diversifique entre vários fundos.",
		],
	},
]

var blocker: ColorRect
var panel: Control
var topics_box: VBoxContainer
var title_label: Label
var content_label: RichTextLabel
var content_scroll: ScrollContainer
var is_open := false
var current_topic_index := 0

# Grupo de botões: só um tópico fica "pressed" por vez, e o tema desenha esse
# estado (button_pressed.png) sem precisar tingir o botão por código.
var _topic_group := ButtonGroup.new()

func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	select_topic(0)

func _build_ui() -> void:
	# Mesma película escura do AlertManager, lida de lá para as duas janelas
	# escurecerem o jogo por igual.
	blocker = ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = AlertManager.DIM_COLOR
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.visible = false
	add_child(blocker)

	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	add_child(panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var dialog := PanelContainer.new()
	dialog.theme = UI_THEME
	dialog.custom_minimum_size = DIALOG_SIZE
	center.add_child(dialog)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(root_vbox)

	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	# label.tres: o Label do font_theme tem fundo próprio (pílula marrom) e
	# texto branco; aqui o título é texto solto sobre o papel.
	title_label = Label.new()
	title_label.theme = LABEL_THEME
	title_label.text = "Guia do Jogo"
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	# Altura vem do tema, como o FECHAR do painel de missões.
	var close_btn := Button.new()
	close_btn.text = "FECHAR"
	close_btn.custom_minimum_size = Vector2(CLOSE_BUTTON_WIDTH, 0)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close_notebook)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(body)

	topics_box = VBoxContainer.new()
	topics_box.custom_minimum_size = Vector2(TOPICS_WIDTH, 0)
	topics_box.add_theme_constant_override("separation", 8)
	body.add_child(topics_box)

	for i in range(TOPICS.size()):
		var btn := Button.new()
		btn.text = str(TOPICS[i]["title"])
		btn.toggle_mode = true
		btn.button_group = _topic_group
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(TOPICS_WIDTH, 0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(select_topic.bind(i))
		topics_box.add_child(btn)

	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(content_scroll)

	# RichTextLabel por causa da lista com recuo: a segunda linha de um item
	# alinha com o texto, não com a bolinha. A cor padrão (preto) vem do tema.
	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.scroll_active = false
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)
	content_label.add_theme_constant_override("line_separation", 6)
	content_scroll.add_child(content_label)

# Valores de regras que aparecem no texto. Lidos das constantes dos singletons:
# se uma regra mudar, o guia acompanha.
func _tokens() -> Dictionary:
	return {
		"{midnight_cost}": str(int(TimeManager.MIDNIGHT_PENALTY)),
		"{fail_days}": str(MinigameManager.FAIL_COOLDOWN_DAYS),
		"{park_seconds}": str(int(ParkMinigameManager.SESSION_SECONDS)),
		"{park_plays}": str(ParkMinigameManager.MAX_PLAYS_PER_DAY),
		"{park_hour}": "%02dh" % ParkMinigameManager.LATEST_START_HOUR,
		"{park_status}": str(int(ParkMinigameManager.MIN_STATUS_PERCENT)),
		"{park_coins}": str(ParkMinigameManager.COINS_PER_QUIZ),
		"{park_discount}": _percent(ParkMinigameManager.QUIZ_REWARD_DISCOUNT),
		"{interest}": _percent(DebtRules.INTEREST_PER_DAY),
		"{fii_tax}": _percent(FIIManager.LOSS_TAX_RATE),
		"{savings_rate}": _percent(TimeManager.DAILY_POUPANCA_RATE),
	}

# 0.15 -> "15", 0.005 -> "0,5" (vírgula, como o resto do jogo).
func _percent(rate: float) -> String:
	var value := rate * 100.0
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return ("%.1f" % value).replace(".", ",")

func _resolve(text: String) -> String:
	var resolved := text
	var tokens := _tokens()
	for token in tokens.keys():
		resolved = resolved.replace(str(token), str(tokens[token]))
	return resolved

# Texto do tópico em BBCode: título maior e a lista de itens.
func topic_text(index: int) -> String:
	var topic: Dictionary = TOPICS[index]
	var items: Array = []
	for item in topic["items"]:
		items.append(_resolve(str(item)))
	return "[font_size=%d]%s[/font_size]\n\n[ul]%s[/ul]" % [HEADING_FONT_SIZE, str(topic["heading"]), "\n".join(items)]

func select_topic(index: int) -> void:
	if index < 0 or index >= TOPICS.size():
		return
	current_topic_index = index
	content_label.text = topic_text(index)
	if content_scroll != null:
		content_scroll.scroll_vertical = 0
	var btn := topics_box.get_child(index) as Button
	if btn != null:
		btn.button_pressed = true

func open_notebook() -> void:
	if is_open or Global.player_hud_hidden:
		return
	is_open = true
	blocker.visible = true
	panel.visible = true
	Global.play_time = false
	Global.lock_gameplay()

func close_notebook() -> void:
	if not is_open:
		return
	is_open = false
	blocker.visible = false
	panel.visible = false
	Global.unlock_gameplay()
	if not Global.gameplay_locked and not Global.time_frozen_by_scene() and not Global.is_any_tutorial_active():
		Global.play_time = true

# Com o HUD escondido (minigame do parque) o guia fecha junto.
func _process(_delta: float) -> void:
	if Global.player_hud_hidden and is_open:
		close_notebook()

func _input(event: InputEvent) -> void:
	if Global.player_hud_hidden:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var is_toggle_key: bool = event.keycode == KEY_J or event.keycode == KEY_G
		if is_open and (event.is_action_pressed("ui_cancel") or is_toggle_key):
			close_notebook()
			get_viewport().set_input_as_handled()
		elif not is_open and not Global.gameplay_locked and is_toggle_key:
			open_notebook()
			get_viewport().set_input_as_handled()
