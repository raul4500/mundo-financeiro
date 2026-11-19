extends CanvasLayer

const UI_THEME := preload("res://themes/font_theme.tres")
const LABEL_THEME := preload("res://themes/label.tres")

const TOPICS := [
	{
		"title": "Controles e Atalhos",
		"content": "COMANDOS DO JOGO\n\n• Movimentação: use as teclas W, A, S, D ou as Setas do teclado para caminhar pela cidade.\n• Interação: aproxime-se da porta de um prédio e pressione ENTER para entrar.\n• Confirmação: pressione ESPAÇO ou ENTER para fechar alertas e avançar diálogos.\n• Minigame da Escola: pressione ESPAÇO para pular os obstáculos.\n• Missões da Semana: clique em MISSÕES no topo da tela ou pressione M (ou F).\n• Guia do Jogo: clique em GUIA no topo da tela ou pressione J.\n• Pausa e Salvamento: pressione ESC para pausar, salvar ou sair."
	},
	{
		"title": "Rotina, Stamina e Casa",
		"content": "ROTINA DIÁRIA E SOBREVIVÊNCIA\n\n• Relógio: o dia começa às 08h. Às 18h surge o aviso de cansaço, mas o dia só termina quando você dorme na sua Casa.\n• Stamina: sua energia diária cai ao longo do dia. Dormir na sua Casa recupera 100% da stamina.\n• Virar a noite: se chegar à meia-noite (00h) acordado, você volta para casa à força, paga R$ 30 de café e acorda com apenas metade da stamina.\n• Fome e Sede: caem continuamente. Se qualquer uma chegar a zero, você desmaia, paga R$ 30 de socorro e perde o resto do dia.\n• Estoque da Casa: comidas e bebidas compradas no Mercado vão para o estoque da Casa. Entre em casa, abra as abas COMIDAS ou BEBIDAS e clique em COMER ou BEBER."
	},
	{
		"title": "Escola e Carreira",
		"content": "FORMAÇÃO ESCOLAR E SALÁRIO\n\n• Corrida de Obstáculos: na Escola seu personagem corre automaticamente e você salta os obstáculos com ESPAÇO.\n• Níveis e Salário: cada checkpoint alcançado sobe seu nível de escolaridade (até o nível 5) e aumenta seu salário semanal.\n• Primeira Corrida: na formação inicial você pode subir quantos níveis conseguir até esbarrar em um obstáculo.\n• Aulas Semanais: nas tentativas seguintes, você sobe até 1 nível por semana. Se bater antes do checkpoint, a escola entra em espera de 2 dias."
	},
	{
		"title": "Locais da Cidade",
		"content": "GUIA DOS ESTABELECIMENTOS\n\n• Consultoria Financeira: traz aulas semanais sobre finanças. Na Semana 1, leia todos os tópicos e clique em 'Concluir Aula' para liberar a cidade.\n• Mercado: vende alimentos e bebidas. Compare o custo por ponto de fome ou sede antes de comprar (necessidade x desejo).\n• Banco: guarde seu dinheiro, pague contas fixas da casa, resolva eventos inesperados e invista.\n• Parque da Cidade: minigame de caçar moedas (aberto até as 16h, exige status acima de 50%, até 2x por dia). A cada 5 moedas, acerte o quiz para ganhar cupom de 15% de desconto no mercado.\n• Empreendimentos: Restaurante, Fliperama e Centro Comercial (disponíveis para compra e gestão avançada)."
	},
	{
		"title": "Finanças e Investimentos",
		"content": "EDUCAÇÃO FINANCEIRA NA PRÁTICA\n\n• Missões Semanais: cumpra as 3 metas da semana até o 5º dia para avançar. Se falhar, a semana é repetida.\n• Contas e Eventos (Semana 2+): contas de água, luz, moradia e imprevistos ficam no Banco. Pague até o vencimento para evitar juros de 10% ao dia.\n• Reserva de Emergência: mantenha saldo guardado no Banco para quitar imprevistos sem atrasar.\n• Poupança (Semana 3+): rende juros compostos a cada dia dormido com resgate imediato.\n• Fundos Imobiliários / FIIs (Semana 4+): pagam dividendos semanais, mas as cotas variam. Evite vender na baixa, pois há imposto de 10% sobre o prejuízo."
	}
]

var open_button: Button
var blocker: ColorRect
var panel: Control
var topics_box: VBoxContainer
var title_label: Label
var content_label: Label
var content_scroll: ScrollContainer
var is_open := false
var current_topic_index := 0

func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	select_topic(0)

func _build_ui() -> void:
	open_button = Button.new()
	open_button.name = "OpenGuide"
	open_button.theme = UI_THEME
	open_button.text = "GUIA"
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.offset_left = 875.0
	open_button.offset_top = 13.0
	open_button.offset_right = 995.0
	open_button.offset_bottom = 65.0
	open_button.pressed.connect(open_notebook)
	add_child(open_button)

	blocker = ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0.5)
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
	dialog.custom_minimum_size = Vector2(820, 470)
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

	title_label = Label.new()
	title_label.theme = LABEL_THEME
	title_label.text = "Caderno de Tutorial e Guia da Cidade"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_btn := Button.new()
	close_btn.theme = UI_THEME
	close_btn.text = "FECHAR"
	close_btn.custom_minimum_size = Vector2(130, 42)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(close_notebook)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(body)

	topics_box = VBoxContainer.new()
	topics_box.custom_minimum_size = Vector2(230, 0)
	topics_box.add_theme_constant_override("separation", 8)
	body.add_child(topics_box)

	for i in range(TOPICS.size()):
		var btn := Button.new()
		btn.theme = UI_THEME
		btn.text = str(TOPICS[i]["title"])
		btn.custom_minimum_size = Vector2(220, 46)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(select_topic.bind(i))
		topics_box.add_child(btn)

	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(content_scroll)

	content_label = Label.new()
	content_label.theme = LABEL_THEME
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(content_label)

func select_topic(index: int) -> void:
	if index < 0 or index >= TOPICS.size():
		return
	current_topic_index = index
	content_label.text = str(TOPICS[index]["content"])
	if content_scroll != null:
		content_scroll.scroll_vertical = 0
	for i in range(topics_box.get_child_count()):
		var btn := topics_box.get_child(i) as Button
		if btn != null:
			btn.modulate = Color(1.25, 1.2, 0.6) if i == index else Color.WHITE

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

func _process(_delta: float) -> void:
	var hud_hidden := Global.player_hud_hidden
	if open_button != null:
		open_button.visible = not hud_hidden
	if hud_hidden and is_open:
		close_notebook()

func _input(event: InputEvent) -> void:
	if Global.player_hud_hidden:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if is_open and (event.is_action_pressed("ui_cancel") or event.keycode == KEY_J or event.keycode == KEY_G):
			close_notebook()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
		elif not is_open and not Global.gameplay_locked and (event.keycode == KEY_J or event.keycode == KEY_G):
			open_notebook()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
