extends Control

var levels_data: Array = [
	{
		"id": 1,
		"title": "Nível 1 – Controle de gastos",
		"objective": "Ensinar o jogador a controlar despesas básicas.",
		"topics": [
			{
				"name": "Necessidade x Desejo",
				"description": "Antes de gastar dinheiro, é fundamental entender a diferença entre necessidade e desejo. Necessidades são tudo aquilo que você precisa para viver e funcionar bem no dia a dia, como comida, moradia, transporte e saúde. Já os desejos são coisas que você quer, mas que não são essenciais, como um lanche extra, roupas novas sem necessidade ou itens de lazer.\n\nImagine que seu dinheiro é como um copo de água: se você usar tudo para matar a sede (necessidades), você se mantém bem. Mas se começar a desperdiçar com coisas não essenciais, pode faltar água quando realmente precisar.\n\nSaber diferenciar esses dois tipos de gasto ajuda você a tomar decisões mais inteligentes e evitar ficar sem dinheiro para o que realmente importa."
			},
			{
				"name": "Planejamento de gastos",
				"description": "Planejar seus gastos é como montar um mapa antes de viajar: você decide para onde quer ir e como chegar lá. Sem planejamento, você pode se perder e acabar sem recursos no meio do caminho.\n\nNa prática, isso significa olhar quanto dinheiro você tem e decidir com antecedência onde ele será usado. Por exemplo: separar valores para alimentação, transporte e lazer.\n\nSe você ganha R$500 na semana e já sabe que vai gastar R$200 no mercado e R$100 em transporte, você entende quanto sobra e evita surpresas. Quem não planeja costuma gastar primeiro e pensar depois — e isso quase sempre leva a problemas."
			},
			{
				"name": "Orçamento semanal",
				"description": "O orçamento semanal é uma forma simples e eficiente de controlar seu dinheiro. Em vez de pensar no mês inteiro, você divide o dinheiro em partes menores para cada semana.\n\nIsso ajuda a evitar um erro comum: gastar tudo nos primeiros dias e ficar sem dinheiro depois.\n\nPor exemplo: se você tem R$400 para o mês, pode separar R$100 por semana. Assim, mesmo que você queira gastar mais no começo, sabe que precisa se controlar para não comprometer os próximos dias.\n\nÉ como dividir comida ao longo da semana: se você comer tudo no primeiro dia, vai passar fome depois. O orçamento ajuda a manter equilíbrio."
			},
			{
				"name": "Importância de economizar",
				"description": "Economizar não significa deixar de viver, mas sim guardar uma parte do dinheiro para o futuro. Mesmo valores pequenos fazem diferença com o tempo.\n\nImagine que você guarda R$10 por semana. Pode parecer pouco, mas em 10 semanas já são R$100. Em um ano, isso pode virar uma quantia significativa.\n\nEconomizar também traz segurança. Se surgir um problema inesperado, você não precisa se desesperar ou entrar em dívida.\n\nPense como plantar uma árvore: no começo parece pequeno, mas com o tempo cresce e pode te proteger em momentos difíceis."
			}
		]
	},
	{
		"id": 2,
		"title": "Nível 2 – Reserva de emergência",
		"objective": "Mostrar a importância de guardar dinheiro para emergências.",
		"topics": [
			{
				"name": "Reserva financeira",
				"description": "A reserva de emergência é um dinheiro guardado exclusivamente para situações inesperadas. Não é um dinheiro para gastar com lazer ou compras, mas sim um fundo de segurança.\n\nImagine que sua vida é como dirigir um carro: a reserva de emergência é o cinto de segurança. Você não usa o tempo todo, mas quando precisa, faz toda a diferença.\n\nEla pode ser usada em situações como perda de renda, problemas de saúde ou despesas urgentes. Ter essa reserva evita que você precise pegar dinheiro emprestado ou entrar em dívidas."
			},
			{
				"name": "Imprevistos financeiros",
				"description": "Imprevistos financeiros são gastos que aparecem sem aviso, como um conserto inesperado, uma emergência médica ou qualquer situação que foge do seu planejamento.\n\nEles fazem parte da vida e não podem ser evitados, mas podem ser preparados.\n\nSem uma reserva, um imprevisto pode virar um grande problema. Com uma reserva, ele vira apenas um obstáculo temporário.\n\nÉ como ter um guarda-chuva: você não controla a chuva, mas pode evitar se molhar."
			},
			{
				"name": "Juros",
				"description": "Juros são o custo de usar dinheiro ao longo do tempo. Quando você pega dinheiro emprestado, paga juros. Quando investe, recebe juros.\n\nPor exemplo: se você pega R$100 emprestados e precisa devolver R$120, os R$20 extras são os juros.\n\nOs juros podem trabalhar a seu favor ou contra você. Se você entra em dívidas, eles aumentam o valor que você deve. Se você investe, eles ajudam seu dinheiro a crescer.\n\nEntender juros é essencial para evitar armadilhas financeiras e aproveitar oportunidades."
			}
		]
	},
	{
		"id": 3,
		"title": "Nível 3 – Investimentos básicos",
		"objective": "Apresentar as primeiras formas de fazer o dinheiro render.",
		"topics": [
			{
				"name": "Poupança",
				"description": "A poupança é uma forma simples de guardar dinheiro e receber um pequeno rendimento ao longo do tempo. Ela é considerada segura, mas geralmente rende pouco.\n\nÉ como guardar dinheiro em um cofre que, de vez em quando, adiciona algumas moedas a mais.\n\nApesar de não ser o melhor investimento, é um bom começo para quem está aprendendo, pois ensina o hábito de guardar e acompanhar o crescimento do dinheiro."
			},
			{
				"name": "Renda fixa",
				"description": "Investimentos de renda fixa são aqueles em que você já tem uma ideia de quanto vai ganhar. Eles funcionam como um acordo: você empresta seu dinheiro e recebe de volta com juros.\n\nPor exemplo: você investe R$100 e sabe que receberá R$110 após um período.\n\nSão considerados mais seguros e previsíveis, ideais para quem está começando.\n\nPense como emprestar dinheiro para alguém confiável com um contrato definido."
			}
		]
	},
	{
		"id": 4,
		"title": "Nível 4 – Mercado financeiro",
		"objective": "Introduzir conceitos de risco e retorno no mercado financeiro.",
		"topics": [
			{
				"name": "Ações e fundos imobiliários",
				"description": "Ações representam pequenas partes de uma empresa. Ao comprar uma ação, você se torna sócio dela e pode ganhar com o crescimento do negócio.\n\nFundos imobiliários permitem investir em imóveis sem precisar comprar um diretamente. Você recebe parte dos lucros gerados por esses imóveis.\n\nÉ como participar de um negócio em grupo: você não precisa fazer tudo sozinho, mas recebe parte dos resultados."
			},
			{
				"name": "Risco e retorno",
				"description": "No mundo dos investimentos, existe uma relação importante: quanto maior o potencial de ganho, maior o risco.\n\nInvestimentos mais seguros tendem a render menos, enquanto investimentos mais arriscados podem gerar grandes ganhos ou perdas.\n\nÉ como escolher entre um caminho seguro e um atalho perigoso: o atalho pode ser mais rápido, mas também pode dar errado.\n\nO segredo é equilibrar risco e retorno de acordo com seus objetivos."
			}
		]
	},
	{
		"id": 5,
		"title": "Nível 5 – Empreendedorismo",
		"objective": "Ensinar noções básicas de administração de um negócio próprio.",
		"topics": [
			{
				"name": "Investimento em negócios",
				"description": "Investir em um negócio significa usar dinheiro para criar ou expandir uma atividade que pode gerar lucro no futuro.\n\nPode ser abrir uma loja, vender produtos ou prestar serviços.\n\nÉ como plantar uma semente: você investe agora esperando colher resultados depois."
			},
			{
				"name": "Lucro e prejuízo",
				"description": "Lucro é o dinheiro que sobra depois de pagar todos os custos. Prejuízo acontece quando você gasta mais do que ganha.\n\nPor exemplo: se você vende um produto por R$50 e gastou R$30 para produzi-lo, seu lucro é R$20.\n\nEntender isso é essencial para manter qualquer negócio saudável."
			},
			{
				"name": "Reinvestimento",
				"description": "Reinvestir é usar parte do lucro para melhorar ou expandir o negócio, em vez de gastar tudo.\n\nPor exemplo: comprar mais produtos, melhorar equipamentos ou aumentar a produção.\n\nÉ como alimentar uma máquina para que ela produza ainda mais.\n\nNegócios que reinvestem tendem a crescer mais rápido ao longo do tempo."
			}
		]
	}
]


var player_level: int = 1

@onready var level_container: VBoxContainer = $HBoxContainer/LevelPanel/Levels
@onready var topics_container: VBoxContainer = $HBoxContainer/TopicPanel/ScrollContainer/Topics
@onready var detail_label: RichTextLabel = $HBoxContainer/DetailPanel/ScrollContainer/RichTextLabel


func _ready() -> void:
	_load_player_progress()
	_build_ui()
	_build_level_section()


# ---------------- PROGRESSO ----------------

func _load_player_progress() -> void:
	if Global and "player" in Global and Global.player and Global.player.has("week"):
		player_level = int(Global.player["week"])
	else:
		player_level = 1


# ---------------- UI ----------------

func _build_ui() -> void:
	detail_label.fit_content = true
	detail_label.bbcode_enabled = true
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_show_default_detail_message()


# ---------------- NÍVEIS ----------------

func _build_level_section() -> void:
	var i: int = 0
	
	for level_button in level_container.get_children():
		if not (level_button is Button):
			continue
		
		if i >= player_level:
			level_button.text = "🔒"
			level_button.disabled = true
		else:
			level_button.pressed.connect(build_topics_section.bind(i))
		
		i += 1


# ---------------- TÓPICOS ----------------

func build_topics_section(level: int) -> void:
	# Proteção contra erro
	if level < 0 or level >= levels_data.size():
		return
	
	# Limpa os tópicos antigos
	for t in topics_container.get_children():
		t.free()
	
	var topics = levels_data[level]["topics"]
	
	for topic in topics:
		var button = Button.new()
		button.text = topic["name"]
		button.custom_minimum_size = Vector2(0, 36)
		
		# Bind correto (sem índice desnecessário)
		button.pressed.connect(_on_topic_pressed.bind(topic))
		
		topics_container.add_child(button)


# ---------------- DETALHE ----------------

func _on_topic_pressed(topic: Dictionary) -> void:
	var text = "[color=black][b][font_size=22]%s[/font_size][/b]\n\n" % topic["name"]
	text += "%s" % topic["description"]

	detail_label.clear()
	detail_label.append_text(text)


func _show_default_detail_message() -> void:
	detail_label.clear()
	detail_label.append_text("[i]Selecione um tópico à esquerda para ver os detalhes aqui.[/i]")


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")
