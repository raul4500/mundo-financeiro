extends Node

signal show_message(text)
signal tutorial_finished
signal focus(point)

const FINAL_STEP := 8

var step := 0
var pending_messages: Array = []
var skipped := false

# =============================
# 🧭 ROTEIRO DE APRESENTAÇÃO DO TUTORIAL
# =============================
# Serve como guia para quem estiver apresentando o jogo e para a sequência de onboarding.
var presentation_guide = [
	{
		"step": 1,
		"title": "Boas-vindas",
		"goal": "Apresentar o jogo e explicar a proposta de aprendizagem financeira.",
		"speaker_note": "Diga que o jogador vai aprender a ganhar, economizar, investir e tomar decisões com consequência."
	},
	{
		"step": 2,
		"title": "Objetivo principal",
		"goal": "Mostrar que o objetivo é construir uma vida financeira saudável.",
		"speaker_note": "Explique que cada ação no jogo afeta o futuro financeiro do personagem."
	},
	{
		"step": 3,
		"title": "Primeiro passo: escola",
		"goal": "Levar o jogador até a escola para iniciar o processo de formação.",
		"speaker_note": "A escola é o primeiro ponto de avanço do jogo e define a base do salário."
	},
	{
		"step": 4,
		"title": "Escolaridade e salário",
		"goal": "Conectar educação com renda e oportunidades financeiras.",
		"speaker_note": "Destaque que o nível escolar influencia diretamente o salário do personagem."
	},
	{
		"step": 5,
		"title": "Minigame de formação",
		"goal": "Explicar como o jogador será avaliado e qual o impacto das decisões.",
		"speaker_note": "Mostre que cada acerto melhora a formação e cada erro pode limitar a renda futura."
	},
	{
		"step": 6,
		"title": "Pós-minigame",
		"goal": "Entregar o primeiro salário e iniciar a gestão financeira real.",
		"speaker_note": "Agora o jogador tem dinheiro em mãos e precisa aprender a administrar cada gasto e investimento."
	},
	{
		"step": 7,
		"title": "Exploração do mundo",
		"goal": "Apresentar os locais importantes do jogo: mercado, banco e consultoria.",
		"speaker_note": "Explique que cada local tem uma função estratégica na vida financeira do personagem."
	},
	{
		"step": 8,
		"title": "Conclusão do onboarding",
		"goal": "Apresentar mercado, banco e escritório e encerrar a introdução da semana 1.",
		"speaker_note": "Explique o papel de cada local e feche dizendo que o progresso vem de decisões consistentes. Os empreendimentos NÃO entram aqui: eles são o aviso da semana 5."
	}
]

# =============================
# 📅 GUIA DOS AVISOS SEMANAIS
# =============================
# Complementa o roteiro acima: depois do onboarding, o tutorial continua em
# doses, uma por semana, sempre sobre o que acabou de destravar.
var weekly_guide = [
	{
		"week": 2,
		"title": "Eventos inesperados e reserva",
		"goal": "Explicar que imprevistos viram contas/bônus pendentes no banco.",
		"speaker_note": "Ligue o conteúdo do escritório nível 2 (reserva de emergência) com a mecânica: a reserva é o que permite pagar a conta quando ela aparece."
	},
	{
		"week": 3,
		"title": "Primeiros investimentos",
		"goal": "Apontar o jogador para os FIIs no banco, depois de ler o nível 3.",
		"speaker_note": "Reforce a ordem: estudar primeiro, investir depois."
	},
	{
		"week": 4,
		"title": "Mercado financeiro",
		"goal": "Contextualizar a variação de valor dos investimentos.",
		"speaker_note": "Aviso curto; o conteúdo em si está no escritório nível 4."
	},
	{
		"week": 5,
		"title": "Empreendimentos",
		"goal": "Apresentar os três negócios como etapa avançada do jogo.",
		"speaker_note": "É o bloco mais longo do tutorial. Destaque que exige capital, gera despesas fixas semanais, e que o nível 5 do escritório é pré-requisito prático."
	}
]

# Lista de mensagens usadas em cada alerta do jogo.
var messages = [
	"Bem-vindo(a) ao Mundo Financeiro! Neste jogo, você vai aprender a cuidar do seu dinheiro, tomar decisões importantes e construir uma vida financeira saudável. Cada escolha que fizer terá consequência, então pense com calma antes de agir.",

	"Seu objetivo aqui é simples: aprender a ganhar, economizar e investir seu dinheiro de forma inteligente. Ao longo da jornada, você vai desenvolver conhecimento financeiro e enfrentar desafios que simulam a vida real.",

	"Antes de tudo, você precisa começar pela educação. Vá até a escola e participe do minigame inicial. Ali, sua formação será definida e isso vai influenciar diretamente sua renda futura.",

	"Sua escolaridade define o nível do seu salário. Quanto maior for sua formação, maiores serão as oportunidades dentro do jogo e melhor será o seu rendimento semanal.",

	"Preste atenção: suas escolhas no minigame vão impactar sua vida financeira. Cada acerto aumenta seu potencial, enquanto erros podem limitar seu crescimento e reduzir suas oportunidades.",

	"Neste minigame, você precisará responder corretamente e tomar decisões relacionadas à sua formação. Foque nos conhecimentos essenciais e tente alcançar o melhor desempenho possível.",

	"O objetivo é melhorar seu nível de escolaridade para conquistar um salário maior no futuro. Sempre pense em como cada decisão pode abrir ou fechar portas para suas metas financeiras.",

	"Esta primeira corrida é a sua formação inicial: vá o mais longe que conseguir. Cada checkpoint que você atravessar vale um nível de escolaridade, sem limite — a corrida só termina quando você bater em um obstáculo.",

	"Das próximas vezes a regra muda: cada tentativa vale no máximo 1 nível. Alcançou o checkpoint, sobe de nível e a aula acaba ali, e a escola só reabre na semana seguinte. Bateu antes de chegar nele, precisa esperar 2 dias para tentar de novo. Repare no aviso da porta: ele diz quando a escola volta a abrir.",

	"Parabéns! Você concluiu o minigame e recebeu seu primeiro salário. Agora é hora de começar a administrar melhor seu dinheiro e aprender a lidar com gastos, poupança e investimentos.",

	"O mundo do jogo oferece vários lugares estratégicos. Cada um deles tem um papel importante na sua rotina financeira e no seu desenvolvimento como jogador.",

	"No mercado, você pode comprar itens essenciais para o seu dia a dia. Cuidado para não gastar mais do que a sua renda permite e mantenha o equilíbrio entre necessidade e desejo.",

	"No banco, você pode guardar seu dinheiro, acompanhar o saldo e explorar oportunidades de investimento. Essa é a base para construir uma reserva financeira e tomar decisões mais inteligentes.",

	"No escritório de consultoria, você encontra conteúdos educativos, dicas e ferramentas para compreender melhor o mundo financeiro. Aproveite esses aprendizados para melhorar sua estratégia e evoluir no jogo.",

	"Lembre-se: gastar com consciência, economizar e investir são as chaves para o sucesso. Pequenas decisões bem tomadas ao longo do tempo fazem uma grande diferença no futuro.",

	"Agora é com você. Explore o mundo, cumpra suas missões, tome decisões inteligentes e construa uma vida financeira forte, estável e bem planejada!"
]

# =============================
# 📅 AVISOS SEMANAIS
# =============================
# Cada semana ensina só a mecânica que acabou de destravar naquela semana, em
# vez de despejar tudo no fim do onboarding. As semanas escolhidas acompanham
# o que o resto do jogo já libera: eventos inesperados começam na semana 2
# (EventsManager.FIRST_EVENT_WEEK) e cada nível do escritório destrava na
# semana de mesmo número (office.gd usa player_level = week).
var weekly_messages = {
	2: [
		"Semana 2. A partir de agora podem acontecer eventos inesperados: o carro quebra, aparece uma despesa médica, ou você recebe um bônus por um trabalho extra. Eles não tiram nem colocam dinheiro na sua conta na hora — viram uma pendência que fica esperando por você.",

		"Todas essas contas e bônus ficam no banco, no painel \"Contas e bônus pendentes\". Uma conta só sai do seu bolso quando você aperta Pagar, e para isso precisa ter o dinheiro na mão. Por isso o nível 2 do escritório, liberado agora, é sobre reserva de emergência: é ela que faz um imprevisto virar só um susto."
	],
	3: [
		"Semana 3. O nível 3 do escritório abriu e é sobre investimentos básicos: poupança e renda fixa. Se você já tem uma reserva formada, é a hora de fazer o dinheiro parado começar a render.",

		"No banco você encontra os fundos imobiliários para investir. Leia o conteúdo do escritório antes de aplicar: investir sem entender o que se está comprando é como assinar um contrato sem ler."
	],
	4: [
		"Semana 4. O nível 4 do escritório destravou e fala sobre mercado financeiro. É o conteúdo que ajuda a entender por que o valor dos seus investimentos sobe e desce, e por que ninguém deve colocar tudo em um lugar só."
	],
	5: [
		"ATENÇÃO: existe uma parte avançada do jogo, os empreendimentos. São três prédios que você pode comprar para virar dono do próprio negócio. Não tenha pressa: essa é a etapa mais difícil e mais arriscada do Mundo Financeiro, porque exige investir um valor alto e assumir despesas fixas que chegam toda semana, com ou sem lucro.",

		"Todo negócio funciona da mesma forma por dentro. Você compra estoque para manter as vendas, paga as contas de água e luz antes do vencimento, contrata funcionários que aumentam a receita e a capacidade de atendimento, e sobe do nível 1 ao nível 5 para liberar equipamentos melhores. Ficar sem estoque derruba a receita para 35%, e deixar uma conta vencer corta outros 25%.",

		"O primeiro é o Restaurante Sabor da Praça, por R$ 1.500. É o negócio de entrada: atende 10 clientes por dia, precisa de ingredientes, bebidas e itens de limpeza no estoque, e as contas somam apenas R$ 50 por semana. É o lugar certo para aprender a rotina de um negócio errando pouco dinheiro.",

		"O segundo é o Fliperama Neon, por R$ 12.000. Um negócio de porte médio: começa atendendo 25 clientes e a receita é bem maior, mas as contas sobem para R$ 300 por semana e cada funcionário custa R$ 420 por semana. Aqui você aprende a equilibrar equipe, equipamentos e caixa sem ficar no vermelho.",

		"O terceiro é o Centro Comercial Mundo Mix, por R$ 85.000. É o maior desafio do jogo: atende 100 clientes desde o início e gera uma receita alta, mas só as contas de água e luz custam R$ 1.550 por semana e os aprimoramentos vão de R$ 60.000 a R$ 400.000. Só compre depois de já ter dominado os negócios menores.",

		"Um aviso importante: antes de comprar qualquer empreendimento, estude no escritório de consultoria. O nível 5 do conteúdo, liberado nesta semana, é dedicado ao empreendedorismo e explica capacidade, giro de estoque, folha de pagamento, contas em atraso e o retorno de cada equipamento. Sem esse conhecimento, é muito fácil comprar um negócio e vê-lo dar prejuízo."
	]
}

func get_presentation_guide() -> Array:
	return presentation_guide

func teste():
	emit_signal("show_message", messages[0])

func start_tutorial():
	step = 0
	skipped = false
	pending_messages.clear()
	_next_step()

# O botão de pular só aparece junto à primeira mensagem de boas-vindas.
# Os avisos semanais não têm botão de pular de propósito: são curtos (1-2
# mensagens) e, como passam pelo mesmo AlertManager que todos os alertas do
# jogo, liberar o botão fora do passo 1 o faria aparecer em alertas que não
# têm nada a ver com tutorial.
func can_skip() -> bool:
	return not skipped and step == 1

func skip_tutorial() -> void:
	if skipped:
		return
	skipped = true
	pending_messages.clear()
	step = FINAL_STEP
	Global.player["tutorial_step"] = FINAL_STEP
	# "Pular tutorial" pula o tutorial inteiro, não só o onboarding: marca
	# todas as semanas como já vistas. Vai para Global.player de propósito —
	# a variável `skipped` não é salva, então recarregar o jogo faria os
	# avisos semanais voltarem.
	var shown: Array = Global.player.get("tutorial_weeks_shown", [])
	for week in weekly_messages.keys():
		if not _week_already_shown(int(week), shown):
			shown.append(week)
	Global.player["tutorial_weeks_shown"] = shown
	emit_signal("tutorial_finished")
	# Em casos onde locks possam ter sido deixados por erro, garantir liberação
	# para que o jogador não fique travado permanentemente após pular.
	if has_node("/root/Global"):
		Global.force_release_all_gameplay_locks()

func queue_messages(list: Array) -> void:
	if list.is_empty():
		return
	pending_messages = list.duplicate()
	_show_next_queued_message()

func _show_next_queued_message() -> void:
	if pending_messages.is_empty():
		return
	var text = pending_messages.pop_front()
	emit_signal("show_message", text, true)

func continue_tutorial_after_alert() -> void:
	if not pending_messages.is_empty():
		_show_next_queued_message()
		return
	_next_step()

func _next_step():
	step += 1
	Global.player["tutorial_step"] += 1

	match step:
		1:
			emit_signal("show_message", messages[0], true)
		2:
			emit_signal("show_message", messages[1], true)
		3:
			emit_signal("show_message", messages[2], true)
		4:
			emit_signal("show_message", messages[3], true)

		# espera ir pra escola
		5:
			emit_signal("focus", "School")

		# minigame explicação (dentro do minigame)
		6:
			queue_messages([messages[4], messages[5], messages[6], messages[7], messages[8]])

		# espera terminar minigame
		7:
			pass

		# pós minigame
		8:
			# Fecha o onboarding da semana 1 apresentando os locais do mapa.
			# O bloco dos empreendimentos saiu daqui: agora é o aviso da
			# semana 5, quando o nível 5 do escritório destrava e o jogador
			# tem alguma chance de ter capital para pensar nisso.
			queue_messages([
				messages[9],
				messages[10],
				messages[11],
				messages[12],
				messages[13],
				messages[14],
				messages[15]
			])
			emit_signal("tutorial_finished")
			# Garantir liberação de locks ao finalizar o tutorial
			if has_node("/root/Global"):
				Global.force_release_all_gameplay_locks()


# =============================
# 🎯 EVENTOS DO JOGO 
# =============================

# Chamado por TimeManager a cada virada de semana. Mostra o aviso daquela
# semana uma única vez por partida — Global.player["tutorial_weeks_shown"]
# guarda o que já foi visto, então recarregar o save não repete.
func on_week_changed(week: int) -> void:
	if not weekly_messages.has(week):
		return
	var shown: Array = Global.player.get("tutorial_weeks_shown", [])
	if _week_already_shown(week, shown):
		return
	# Não atropela uma fila em andamento (ex.: o fechamento da semana 1 ainda
	# na tela quando a semana vira).
	if not pending_messages.is_empty():
		return
	shown.append(week)
	Global.player["tutorial_weeks_shown"] = shown
	queue_messages(weekly_messages[week])

# int() em cada item: depois de salvar e carregar, o JSON devolve os números
# como float, e comparar 2 com 2.0 direto no Array.has() é frágil.
func _week_already_shown(week: int, shown: Array) -> bool:
	for shown_week in shown:
		if int(shown_week) == week:
			return true
	return false


func on_player_entered_school():
	if step == 5:
		_next_step()


func on_minigame_finished():
	if step == 7:
		_next_step()
