extends Node

signal show_message(text)
signal tutorial_finished
signal focus(point)

# Roteiro do onboarding:
#   1    boas-vindas ao jogo
#   2    objetivo principal e comandos/controles (movimentação, ações, missões, etc.)
#   3-4  importância da educação e impacto da formação no salário
#   5    foco na escola e espera o jogador entrar
#   6    explicacao dentro do minigame
#   7    espera o minigame terminar
#   8    apresenta o escritorio e o libera
#   9    espera o jogador entrar e sair do escritorio
#   10   apresenta o resto da cidade (casa, mercado, banco) e libera tudo
const FINAL_STEP := 10
const OFFICE_WAIT_STEP := 9

# Acima de FINAL_STEP o tutorial acabou — por conclusao ou por ter sido pulado.
# Precisa ser um valor proprio: enquanto "concluido" era o mesmo 8 do ultimo
# passo, main_game._ready() chamava resume_tutorial(8) e repetia o tour inteiro
# toda vez que o jogador voltava ao mundo. Global.LEGACY_TUTORIAL_DONE espelha
# este valor para migrar saves antigos.
const TUTORIAL_DONE := 11

var step := 0
var pending_messages: Array = []
var skipped := false
var is_displaying_tutorial_messages := false

func reset() -> void:
	step = 0
	pending_messages.clear()
	skipped = false
	is_displaying_tutorial_messages = false

# Mapeamento de mensagens para pontos de foco (nomes de nodes sob
# Camera-focusPoints). Índices referem-se a posições no array `messages`.
var message_focus_map := {
	11: "Market",
	12: "Bank",
	13: "Office",
	22: "Home",
	30: "Park"
}

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
		"title": "Objetivo principal e Controles",
		"goal": "Mostrar a proposta do jogo e ensinar os comandos (movimentação, interação, missões e atalhos).",
		"speaker_note": "Apresente as teclas de movimento (WASD/Setas), interação (Enter, Espaço), missões (M/F ou botão) e pause (ESC)."
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
		"title": "Conclusão do onboarding e Mapa",
		"goal": "Apresentar casa (estoque, descanso e sono), mercado, banco e parque e encerrar a introdução da semana 1.",
		"speaker_note": "Explique o papel da casa, mercado, banco e do parque (minigame casual de caça às moedas e quiz com cupom de desconto) e feche dizendo que o progresso vem de decisões consistentes. Os empreendimentos NÃO entram aqui: eles são o aviso da semana 5."
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
		"title": "Contas e reserva de emergência",
		"goal": "Explicar que despesas da casa e imprevistos viram pendências no banco.",
		"speaker_note": "Ligue o conteúdo do escritório nível 2 (reserva de emergência) às contas da casa e aos imprevistos: a reserva é o que permite pagá-los quando aparecem."
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

	"Agora é com você. Explore o mundo, cumpra suas missões, tome decisões inteligentes e construa uma vida financeira forte, estável e bem planejada!",

	# Mecânicas das fases 6-7. Ficam no fim do array de propósito: os índices
	# 0-15 são referenciados um a um em _next_step() e renumerar quebraria tudo.
	"Repare na barra de STAMINA. Ela começa cheia às 08:00 e se esgota ao longo do dia, chegando ao fim por volta da meia-noite. Stamina é o seu limite de energia diário: quando ela acaba, você ainda anda, mas o dia já cobrou o seu preço.",

	"O dia não termina sozinho. Às 18:00 você recebe um aviso de cansaço, mas quem encerra o dia é você: volte a pé até a sua casa e clique em DORMIR. Dormir devolve 100% da stamina e faz o próximo dia começar às 08:00.",

	"Se você virar a noite acordado, à meia-noite volta para casa à força, paga R$ 30 de café para aguentar o dia seguinte e acorda com apenas metade da stamina. Planejar a volta para casa faz parte do orçamento.",

	"No mercado, cada item mostra quanto ele repõe de fome e de sede. Comida barata repõe pouco e comida cara repõe muito: o pão custa R$ 4 e devolve 10% de fome, a carne custa R$ 70 e devolve 100%. As bebidas ficam na aba ao lado e cuidam da sede. Compare o preço por porcentagem antes de encher o carrinho.",

	"E cuidado com a fome: ela cai um pouco a cada dia que passa e só volta comendo. Se a fome chegar a zero, é game over. Manter comida no estoque de casa não é luxo, é sobrevivência.",

	# Passo 8. Fecha a apresentação do escritório, que é o único lugar liberado
	# nesse momento (ver Global.PLACE_UNLOCK_STAGE).
	"Por enquanto o escritório é o único lugar aberto para você. Vá até lá, veja o que a consultoria tem a dizer, e quando sair o resto da cidade estará liberado.",

	# Índices 22-27: a casa. O 22 entra no tour do mundo; os outros disparam na
	# primeira visita, em on_player_entered_home(). Como todo o resto deste
	# array, são append-only: os índices 0-21 são citados um a um em
	# _next_step(), _resume_step() e nas duas funções de fila.
	"Aquela é a sua casa. É o único lugar onde você recupera o que o dia gasta — comer, beber e descansar acontecem lá dentro — e o único lugar onde o dia termina, porque é onde fica a sua cama.",

	"Uma coisa importante sobre o mercado: comida e bebida que você compra NÃO são consumidas na hora da compra. Elas vão para o estoque da sua casa e ficam lá até você usar. O painel de estoque mostra quanto cada item repõe de fome e de sede.",

	"Os botões COMER e BEBER escolhem sozinhos o item mais eficiente que você tem guardado, e ele sai do estoque. Comer custa 30 minutos do seu dia e beber custa 15. Comer também devolve um pouco de stamina, mas pouco: quem recupera stamina de verdade é o sono.",

	"DESCANSAR e ASSISTIR TV devolvem stamina e custam 1 hora cada, mas gastam fome no processo. Servem para esticar um dia que está acabando, não para substituir o sono — e se você usá-los sem ter comida no estoque, só está trocando um problema por outro.",

	"DORMIR é o que encerra o dia: a stamina volta a 100 e o relógio pula para as 08:00 do dia seguinte. Antes das 18h o botão não deixa você dormir. E se você virar a noite acordado, à meia-noite volta para casa à força, paga R$ 30 de café e começa o dia seguinte com metade da stamina.",

	"Por último, a sede. Ela cai mais rápido que a fome — cerca de 14 pontos por dia contra 6 — e chegar a zero é game over, igual à fome. O que vale olhar no mercado é quanto você paga por ponto reposto: a água resolve 25% de sede por R$ 5, ou seja R$ 0,20 por ponto, enquanto a cerveja pede R$ 50 para repor 10% — R$ 5,00 por ponto, vinte e cinco vezes mais caro. É o \"necessidade x desejo\" do escritório, agora com um medidor.",

	# Índices 28-29: Controles e comandos básicos do jogo (ensinados logo após a introdução
	# e antes de apresentar a escola).
	"Antes de começar a explorar a cidade, conheça os comandos básicos:\n\n• Movimentação: use as teclas W, A, S, D ou as Setas do teclado para andar pelo mapa.\n• Interação: aproxime-se de portas de prédios ou de pessoas e pressione ENTER para entrar ou interagir.\n• Confirmação: use a barra de ESPAÇO para avançar alertas, diálogos e saltar obstáculos nos minigames.",

	"Fique atento à interface e aos atalhos do jogo:\n\n• Missões: clique no botão MISSÕES no topo da tela (ou use as teclas M ou F) para ver seus objetivos da semana. Cumprir missões é essencial para evoluir.\n• Relógio e Calendário: no topo você acompanha o dia atual, o horário e a semana em andamento.\n• Pausa e Salvamento: pressione ESC a qualquer momento para abrir o menu de pausa, salvar seu progresso ou sair do jogo com segurança.",

	# Índice 30: Apresentação do Parque e seu minigame durante o tour do mapa.
	"Aquele é o parque da cidade. Lá você encontra um minigame casual de caçar moedas contra o relógio. A cada 5 moedas coletadas, você responde a um quiz sobre os conteúdos da consultoria e pode ganhar um cupom de 15% de desconto no mercado! Para participar, mantenha suas necessidades (fome, sede e stamina) acima de 50% e venha antes das 16h (máximo de 2 partidas por dia)."
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
		"Semana 2. Sua casa também gera contas fixas: água, luz e moradia. Elas aparecem toda semana no banco, na aba \"Contas da casa\", e ficam pendentes até você decidir pagá-las.",

		"Receber uma conta não tira dinheiro do seu bolso automaticamente: a cobrança só acontece quando você aperta Pagar no banco. Planeje o orçamento para quitar as pendências antes do vencimento.",

		"A partir de agora também podem acontecer eventos inesperados: o carro quebra, aparece uma despesa médica, ou você recebe um bônus por um trabalho extra. Essas contas e bônus ficam na aba \"Eventos\" do banco. O nível 2 do escritório é sobre reserva de emergência: é ela que faz uma pendência virar só um susto."
	],
	3: [
		"Semana 3. O nível 3 do escritório abriu e é sobre investimentos básicos: poupança e renda fixa. Se você já tem uma reserva formada, é a hora de fazer o dinheiro parado começar a render.",

		"No banco você encontra os fundos imobiliários para investir. Leia o conteúdo do escritório antes de aplicar: investir sem entender o que se está comprando é como assinar um contrato sem ler."
	],
	4: [
		"Semana 4. O nível 4 do escritório destravou e fala sobre mercado financeiro. É o conteúdo que ajuda a entender por que o valor dos seus investimentos sobe e desce, e por que ninguém deve colocar tudo em um lugar só.",

		"Uma regra prática dos fundos imobiliários: vender na baixa custa caro. Se você vender uma cota por menos do que pagou por ela, ainda paga 10% de imposto sobre o prejuízo. Diversificar entre os três fundos e esperar a recuperação quase sempre sai mais barato do que vender no susto."
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
	is_displaying_tutorial_messages = false
	pending_messages.clear()
	# "Pular tutorial" pula o tutorial inteiro, não só o onboarding: marca
	# todas as semanas como já vistas. Vai para Global.player de propósito —
	# a variável `skipped` não é salva, então recarregar o jogo faria os
	# avisos semanais voltarem.
	var shown: Array = Global.player.get("tutorial_weeks_shown", [])
	for week in weekly_messages.keys():
		if not _week_already_shown(int(week), shown):
			shown.append(week)
	Global.player["tutorial_weeks_shown"] = shown
	# Mesma coisa para o bloco da casa: sem isto, quem pulou o tutorial tomaria
	# as cinco mensagens na cara ao entrar em casa pela primeira vez.
	Global.player["tutorial_home_shown"] = true
	# Marca o tutorial como concluído e abre a cidade inteira: quem pulou não
	# vai receber a apresentação do escritório que destravaria o resto.
	_finish_tutorial()
	# Em casos onde locks possam ter sido deixados por erro, garantir liberação
	# para que o jogador não fique travado permanentemente após pular.
	if has_node("/root/Global"):
		Global.force_release_all_gameplay_locks()
	if has_node("/root/Global") and not Global.gameplay_locked and not Global.in_school_minigame:
		Global.play_time = true

func resume_tutorial(saved_step: int) -> void:
	# Retoma o tutorial do passo que foi salvo. Chama quando o jogo carrega
	# e o tutorial ainda não foi completado (saved_step < FINAL_STEP).
	step = saved_step
	skipped = false
	pending_messages.clear()
	_resume_step(step)

func _resume_step(resume_step: int) -> void:
	# Continua o tutorial a partir do passo restaurado. Alguns passos são
	# "wait" states (ex.: esperar ir à escola), então pulamos para eles
	# sem fazer nada; outros mostram mensagens/foco logo.
	Global.player["tutorial_step"] = resume_step
	if is_any_tutorial_active() and has_node("/root/Global"):
		Global.play_time = false
	match resume_step:
		1:
			emit_signal("show_message", messages[0], true)
		2:
			queue_messages([messages[1], messages[28], messages[29]])
		3:
			emit_signal("show_message", messages[2], true)
		4:
			emit_signal("show_message", messages[3], true)
		5:
			# Passo 5 é só "foco na escola". Se o jogador recarregar aqui,
			# não repete o foco — apenas está no mapa esperando entrar na escola.
			pass
		6:
			# Passo 6 é dentro do minigame. Se o jogador salvou lá e recarregou,
			# o minigame restaura e as mensagens já foram mostradas. Não repita.
			pass
		7:
			# Passo 7 é "esperar minigame terminar". Não há mensagens.
			pass
		8:
			# Recarregou logo depois do minigame, antes de ver a apresentação
			# do escritório. Repete o passo 8 inteiro.
			Global.set_unlock_stage(Global.UNLOCK_OFFICE)
			_queue_office_intro()
		9:
			# Esperando a visita ao escritório. Nada a mostrar: o escritório
			# já está destravado e a mensagem já foi lida.
			pass
		10:
			# O jogador acabou de sair do escritório (ou recarregou aqui).
			# É neste ponto que o tour do resto da cidade acontece.
			_queue_world_tour()

# Passo 8. messages[13] tem foco "Office" em message_focus_map, então a câmera
# vai até o escritório antes desta mensagem aparecer.
func _queue_office_intro() -> void:
	queue_messages([
		messages[9],   # parabéns pelo primeiro salário
		messages[13],  # o que é o escritório de consultoria
		messages[21]   # é o único lugar aberto; vá até lá
	])

# Passo 10. Fecha o onboarding da semana 1 apresentando o resto do mapa. O
# bloco dos empreendimentos saiu daqui: virou o aviso da semana 5, quando o
# nível 5 do escritório destrava e o jogador tem chance de ter capital.
func _queue_world_tour() -> void:
	Global.player["tutorial_home_shown"] = true
	queue_messages([
		messages[10],
		# A casa é apresentada junto com o restante do mapa logo após a consultoria:
		# a câmera foca a casa (índice 22 em message_focus_map), e todas as
		# suas mecânicas (estoque, alimentação, descanso, sono e sede) são explicadas.
		messages[22],  # Aquela é a sua casa (foco em "Home")
		messages[23],  # Estoque da casa (compras do mercado ficam guardadas lá)
		messages[24],  # Botões COMER e BEBER
		messages[25],  # DESCANSAR e ASSISTIR TV
		messages[16],  # Barra de STAMINA
		messages[17],  # DORMIR encerra o dia (aviso das 18h)
		messages[18],  # Penalidade da meia-noite (R$ 30 e metade da stamina)
		messages[27],  # Sede, decaimento e custo-benefício
		messages[11],  # Mercado (foco em "Market")
		messages[19],  # O que cada item do mercado repõe de fome e sede
		messages[20],  # Fome zerada é game over
		messages[12],  # Banco (foco em "Bank")
		messages[30],  # Parque (foco em "Park")
		messages[14],  # Lembre-se: gastar com consciência, economizar e investir
		messages[15]   # Conclusão do onboarding: "Agora é com você..."
	])

# Passo 9. A apresentação do escritório terminou com a câmera parada lá
# (CameraManager.goto não volta sozinho). Traz a câmera de volta e devolve o
# controle: daqui o tutorial só continua quando o jogador sair do escritório.
func _return_camera_and_wait() -> void:
	await CameraManager.return_to_player()
	if has_node("/root/Global"):
		Global.force_release_all_gameplay_locks()

# Ponto único de encerramento: conclusão normal e "pular tutorial" passam aqui.
# É o que garante que main_game._ready() não vai repetir nada.
func _finish_tutorial() -> void:
	step = TUTORIAL_DONE
	is_displaying_tutorial_messages = false
	Global.player["tutorial_step"] = TUTORIAL_DONE
	Global.player["tutorial_home_shown"] = true
	# Garante que todos os status fiquem em 100% ao liberar o jogador para explorar o mundo
	Global.player["hunger"] = 100.0
	Global.player["thirst"] = 100.0
	Global.player["stamina"] = 110.0
	Global.set_unlock_stage(Global.UNLOCK_ALL)
	emit_signal("tutorial_finished")

func is_tutorial_active() -> bool:
	if skipped:
		return false
	if step >= TUTORIAL_DONE:
		return false
	if has_node("/root/Global"):
		return Global.is_tutorial_active()
	return step < TUTORIAL_DONE

func is_any_tutorial_active() -> bool:
	if is_tutorial_active():
		return true
	if is_displaying_tutorial_messages or not pending_messages.is_empty():
		return true
	return false

func _message_index(text: String) -> int:
	for i in range(messages.size()):
		if messages[i] == text:
			return i
	return -1

func queue_messages(list: Array) -> void:
	if list.is_empty():
		return
	is_displaying_tutorial_messages = true
	if has_node("/root/Global"):
		Global.play_time = false
	# Normalize para um Array de dicionários com {"text":..., "focus":...}
	pending_messages.clear()
	for item in list:
		var idx = _message_index(str(item))
		var focus_name = null
		if idx >= 0 and message_focus_map.has(idx):
			focus_name = message_focus_map[idx]
		pending_messages.append({"text": str(item), "focus": focus_name})
	_show_next_queued_message()

func _show_next_queued_message() -> void:
	if pending_messages.is_empty():
		return
	var entry = pending_messages.pop_front()
	var text = entry.get("text", "")
	var focus = entry.get("focus", null)
	# Se houver um foco, pede ao mundo para mover a câmera até ele e espera a
	# confirmação de chegada antes de mostrar a mensagem.
	if focus != null and focus != "":
		# Emite o sinal que a cena principal escuta (main_game._focus)
		emit_signal("focus", focus)
		# Espera a câmera chegar ao ponto — o CameraManager emite focus_arrived.
		var args = await CameraManager.focus_arrived
		# Se o foco chegado não for o esperado, apenas prossegue — não bloqueia.
		#if args.size() == 0 or str(args[0]) != str(focus):
			# aviso opcional
			#print("TutorialManager: focus_arrived mismatch: esperado %s, chegou %s" % [focus, args.size() > 0 ? str(args[0]) : "(nenhum)"])
		# Agora mostra a mensagem com o alerta normal
		emit_signal("show_message", text, true)
	else:
		# Sem foco, mostra imediatamente. Isso é importante ao trocar de cena
		# para o minigame: não pode depender de um sinal da câmera antiga.
		emit_signal("show_message", text, true)

func continue_tutorial_after_alert() -> void:
	if not pending_messages.is_empty():
		_show_next_queued_message()
		return
	is_displaying_tutorial_messages = false
	if step >= FINAL_STEP:
		if step == FINAL_STEP:
			_finish_tutorial()
			if CameraManager.is_cinematic and CameraManager.player != null:
				await CameraManager.return_to_player()
			if has_node("/root/Global"):
				Global.force_release_all_gameplay_locks()
		if has_node("/root/Global") and not is_any_tutorial_active() and not Global.gameplay_locked and not Global.in_school_minigame:
			Global.play_time = true
		return
	_next_step()

func _next_step():
	step += 1
	Global.player["tutorial_step"] = step
	if is_any_tutorial_active() and has_node("/root/Global"):
		Global.play_time = false

	match step:
		1:
			emit_signal("show_message", messages[0], true)
		2:
			queue_messages([messages[1], messages[28], messages[29]])
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

		# pós minigame: apresenta o escritório e o destrava
		8:
			Global.set_unlock_stage(Global.UNLOCK_OFFICE)
			_queue_office_intro()

		# espera o jogador entrar e sair do escritório
		9:
			_return_camera_and_wait()

		# O passo 10 (tour do resto da cidade) não passa por aqui: o tour usa
		# foco de câmera, que só existe em main_game, e o jogador está na cena
		# do escritório quando ele é destravado. Ver on_player_left_office().


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
# Chamado por home.gd ao entrar na casa. O bloco da casa nao e' um passo do
# onboarding: a primeira visita pode ser na semana 1 ou na 4, dependendo de
# quando o jogador entra. Por isso a trava e' uma flag persistida em
# Global.player, no mesmo espirito de tutorial_weeks_shown — `skipped` nao e'
# salvo, e recarregar o jogo faria o bloco voltar.
func on_player_entered_home() -> void:
	if bool(Global.player.get("tutorial_home_shown", false)):
		return
	# Nao atropela uma fila em andamento (ex.: o aviso semanal ainda na tela).
	if not pending_messages.is_empty():
		return
	Global.player["tutorial_home_shown"] = true
	queue_messages([
		messages[23],  # o estoque: o que se compra no mercado fica guardado aqui
		messages[24],  # COMER e BEBER
		messages[25],  # DESCANSAR e ASSISTIR TV
		messages[26],  # DORMIR encerra o dia
		messages[27]   # sede
	])

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


# Chamado por office.gd ao sair do escritório. Só avança o contador: o tour do
# passo 10 usa foco de câmera, que só existe em main_game, e neste momento o
# jogador ainda está na cena do escritório. Quando o mundo carregar,
# main_game._ready() chama resume_tutorial(10) e o tour roda lá.
func on_player_left_office() -> void:
	if step != OFFICE_WAIT_STEP:
		return
	step = FINAL_STEP
	Global.player["tutorial_step"] = FINAL_STEP
