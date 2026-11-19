extends Node

signal show_message(text)
signal tutorial_finished
signal focus(point)
signal missions_preview_requested(show_panel)

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
		"goal": "Explicar a corrida de obstáculos, o uso da tecla Espaço e o avanço por checkpoints.",
		"speaker_note": "Mostre que o personagem corre sozinho, o jogador salta com Espaço e cada checkpoint aumenta a escolaridade e o salário semanal."
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
		"title": "Primeiros investimentos e Poupança",
		"goal": "Apresentar a Poupança no banco e o conceito de Renda Fixa após estudar o nível 3.",
		"speaker_note": "Reforce a ordem: estudar no escritório primeiro, aplicar na poupança depois."
	},
	{
		"week": 4,
		"title": "Mercado financeiro e Fundos Imobiliários",
		"goal": "Apresentar as cotas de FIIs no banco, diversificação e dividendos após o nível 4.",
		"speaker_note": "Contextualize a volatilidade e o perigo de vender na baixa; FIIs liberados no banco."
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
	"Bem-vindo(a) ao Mundo Financeiro! Gerencie seu dinheiro, cumpra as missões da semana e construa sua independência financeira.",

	"Seu objetivo na Semana 1 é simples: qualificar-se na Escola, estudar na Consultoria e cumprir as 3 metas semanais.",

	"Primeiro passo: vá até a Escola e participe da corrida de formação para definir seu nível de escolaridade.",

	"Quanto maior a sua escolaridade, maior será o salário que você recebe toda semana!",

	"Bem-vindo(a) à sua formação escolar! O seu personagem corre automaticamente: pressione ESPAÇO no momento certo para pular os obstáculos pelo caminho.",

	"Cada checkpoint ultrapassado garante um nível a mais de escolaridade e aumenta o seu salário semanal. Nesta primeira corrida, vá o mais longe que conseguir sem bater!",

	"Nas próximas semanas, cada aula permitirá avançar 1 nível por vez. Se esbarrar antes do checkpoint, será preciso aguardar 2 dias para tentar novamente.",

	"Esta primeira corrida é a sua formação inicial: vá o mais longe que conseguir. Cada checkpoint que você atravessar vale um nível de escolaridade, sem limite; a corrida só termina quando você bater em um obstáculo.",

	"Das próximas vezes a regra muda: cada tentativa vale no máximo 1 nível. Alcançou o checkpoint, sobe de nível e a aula acaba ali, e a escola só reabre na semana seguinte. Bateu antes de chegar nele, precisa esperar 2 dias para tentar de novo. Repare no aviso da porta: ele diz quando a escola volta a abrir.",

	"Parabéns! Você concluiu o minigame e recebeu seu primeiro salário. Agora vamos conhecer a Consultoria Financeira.",

	"A cidade possui locais essenciais para a sua rotina e evolução financeira.",

	"No Mercado você compra comidas e bebidas para abastecer o estoque da sua casa. Nunca deixe fome ou sede chegarem a zero para não desmaiar (custo de R$ 30)!",

	"No Banco você guarda seu dinheiro, aplica na poupança, investe em fundos e paga as contas da semana.",

	"Ali fica o Escritório de Consultoria: leia todos os tópicos da aula da semana e clique em 'Concluir Aula' para destravar o restante da cidade.",

	"Lembre-se: gastar com consciência, economizar e investir são as chaves para o sucesso.",

	"Tudo pronto! Cumpra suas Missões (tecla M) e consulte o Guia do Jogo (tecla J) sempre que tiver dúvidas. Bom jogo!",

	# Mecânicas das fases 6-7. Ficam no fim do array de propósito: os índices
	# 0-15 são referenciados um a um em _next_step() e renumerar quebraria tudo.
	"A barra de STAMINA começa cheia às 08:00 e cai ao longo do dia. Volte para casa e durma para recuperá-la.",

	"Às 18:00 você recebe um aviso de cansaço. Volte até a sua casa e clique em DORMIR para recuperar 100% da stamina e iniciar o próximo dia às 08:00.",

	"Se virar a noite acordado (00:00), você volta para casa à força, paga R$ 30 de café e acorda com apenas metade da stamina.",

	"No mercado, cada item mostra quanto repõe de fome e sede. Compare o custo-benefício antes de comprar.",

	"Cuidado com a fome e a sede: se chegarem a zero, você desmaia, paga R$ 30 de socorro e perde o resto do dia.",

	# Passo 8. Fecha a apresentação do escritório, que é o único lugar liberado
	# nesse momento (ver Global.PLACE_UNLOCK_STAGE).
	"Por enquanto apenas a Consultoria está aberta. Entre lá, leia os tópicos da aula e clique em 'Concluir Aula' para liberar a cidade!",

	# Índices 22-27: a casa. O 22 entra no tour do mundo; os outros disparam na
	# primeira visita, em on_player_entered_home(). Como todo o resto deste
	# array, são append-only: os índices 0-21 são citados um a um em
	# _next_step(), _resume_step() e nas duas funções de fila.
	"Aquela é a sua Casa: onde você come, bebe e dorme. Compras do mercado vão para o estoque de casa. Volte antes da meia-noite e clique em DORMIR para recuperar 100% da stamina!",

	"Comidas e bebidas compradas no mercado vão para o estoque da sua casa. As abas COMIDAS e BEBIDAS mostram seus itens guardados e quanto repõem.",

	"Abra a aba COMIDAS ou BEBIDAS e clique em COMER (30 min) ou BEBER (15 min) no item desejado.",

	"DESCANSAR e ASSISTIR TV recuperam um pouco de stamina (custam 1h e gastam fome), mas apenas DORMIR recupera 100%.",

	"DORMIR encerra o dia (liberado a partir das 18h) e restaura sua stamina. Virar a noite cobra R$ 30 e reduz sua energia no dia seguinte.",

	"A sede cai mais rápido que a fome. No mercado, compare o preço por ponto reposto (água é necessidade barata; bebidas caras são desejos).",

	# Índices 28-29: Controles e comandos básicos do jogo (ensinados logo após a introdução
	# e antes de apresentar a escola).
	"Comandos básicos:\n• Andar: W, A, S, D ou Setas.\n• Interagir / Entrar: ENTER.\n• Confirmar alertas e pular no minigame: ESPAÇO ou ENTER.",

	"Fique atento às suas MISSÕES da Semana 1 (painel aberto na tela, botão MISSÕES ou tecla M):\n• Cumpra todas as metas até o 5º dia para avançar de semana.\n• Pressione ESC para pausar/salvar e J para abrir o Guia.",

	# Índice 30: Apresentação do Parque e seu minigame durante o tour do mapa.
	"No Parque você joga o minigame de caçar moedas (até as 16h, com status acima de 50%). A cada 5 moedas, acerte o quiz para ganhar 15% de desconto no mercado!"
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
		"Semana 2. Sua casa também gera contas fixas: água, luz e moradia. Elas aparecem toda semana no banco, na aba \"Contas da casa\", e ficam pendentes até você pagá-las.",

		"Cada conta tem dois prazos. Pague até o fim da semana do vencimento e custa o valor original. Depois, ela cresce 10% ao dia, com juros sobre juros. E no fim da semana da data limite o jogo cobra sozinho, tirando do seu dinheiro e do banco: se não der para cobrir tudo, você perde a semana e a recomeça com o dinheiro que tinha no início dela. Pague antes de vencer.",

		"A partir de agora também podem acontecer eventos inesperados: o carro quebra, aparece uma despesa médica, ou você recebe um bônus por um trabalho extra. Essas contas e bônus ficam na aba \"Eventos\" do banco. O nível 2 do escritório é sobre reserva de emergência: é ela que faz uma pendência virar só um susto."
	],
	3: [
		"Semana 3. O nível 3 do escritório abriu e é sobre investimentos básicos: poupança, renda fixa, juros compostos e liquidez diária. Se você já tem uma reserva formada, é a hora de fazer o dinheiro parado começar a render com segurança.",

		"No banco você agora tem acesso à aba \"Poupança\". Você pode transferir valores do seu saldo em conta para a poupança, onde eles rendem juros compostos a cada dia dormido. E com liquidez imediata (D+0), você pode resgatar para o saldo a qualquer momento se precisar pagar contas."
	],
	4: [
		"Semana 4. O nível 4 do escritório destravou e fala sobre mercado financeiro, ações, fundos imobiliários (FIIs) e volatilidade. É o momento de dar o próximo passo rumo à renda variável!",

		"No banco agora estão liberadas as abas \"FII-shop\" e \"Portfolio\". Você pode comprar cotas de fundos e receber dividendos no fim de semana. Mas atenção: diversifique seus ativos e nunca venda cotas na baixa no susto, pois há penalidade sobre prejuízos."
	],
	5: [
		"ATENÇÃO: existe uma parte avançada do jogo, os empreendimentos. São três prédios que você pode comprar para virar dono do próprio negócio. Não tenha pressa: essa é a etapa mais difícil e mais arriscada do Mundo Financeiro, porque exige investir um valor alto e assumir despesas fixas que chegam toda semana, com ou sem lucro.",

		"Todo negócio funciona da mesma forma por dentro. Você compra estoque para manter as vendas, paga as contas de água e luz antes do vencimento, contrata funcionários que aumentam a receita e a capacidade de atendimento, e sobe do nível 1 ao nível 5 para liberar equipamentos melhores. Ficar sem estoque derruba a receita para 35%, e deixar uma conta vencer corta outros 25%.",

		"O primeiro é o Restaurante Sabor da Praça, por R$ 1.000. É o negócio de entrada: atende 10 clientes por dia, precisa de ingredientes, bebidas e itens de limpeza no estoque, e as contas somam apenas R$ 50 por semana. É o lugar certo para aprender a rotina de um negócio errando pouco dinheiro.",

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
	emit_signal("missions_preview_requested", true)
	# Em casos onde locks possam ter sido deixados por erro, garantir liberação
	# para que o jogador não fique travado permanentemente após pular.
	if has_node("/root/Global"):
		Global.force_release_all_gameplay_locks()
	if has_node("/root/Global") and not Global.gameplay_locked and not Global.time_frozen_by_scene():
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
			emit_signal("missions_preview_requested", false)
			emit_signal("show_message", messages[2], true)
		4:
			emit_signal("show_message", messages[3], true)
		5:
			# Passo 5 é só "foco na escola". Se o jogador recarregar aqui,
			# não repete o foco — apenas está no mapa esperando entrar na escola.
			Global.force_release_all_gameplay_locks()
		6, 7:
			# Passos 6 e 7 são dentro do minigame. Se o jogador recarregou no mapa
			# principal, volta para 5 (se ainda não jogou) ou avança para 8.
			var played := int(Global.player.get("minigame_progress", {}).get("sessions_played", 0))
			if played > 0:
				step = 8
				_resume_step(8)
			else:
				step = 5
				Global.player["tutorial_step"] = 5
				Global.force_release_all_gameplay_locks()
		8:
			# Recarregou logo depois do minigame, antes de ver a apresentação
			# do escritório. Repete o passo 8 inteiro.
			Global.set_unlock_stage(Global.UNLOCK_OFFICE)
			_queue_office_intro()
		9:
			# Esperando a visita ao escritório. Nada a mostrar: o escritório
			# já está destravado e a mensagem já foi lida.
			Global.force_release_all_gameplay_locks()
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
		messages[10],  # Intro curta do tour
		messages[22],  # Casa (foco em "Home")
		messages[11],  # Mercado (foco em "Market")
		messages[12],  # Banco (foco em "Bank")
		messages[30],  # Parque (foco em "Park")
		messages[15]   # Conclusão do onboarding
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
	Global.player["office_study_confirmed"] = true
	# Garante que todos os status fiquem em 100% ao liberar o jogador para explorar o mundo
	Global.player["hunger"] = 110.0
	Global.player["thirst"] = 110.0
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
		if text == messages[29]:
			emit_signal("missions_preview_requested", true)
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
		if has_node("/root/Global") and not is_any_tutorial_active() and not Global.gameplay_locked and not Global.time_frozen_by_scene():
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
			emit_signal("missions_preview_requested", false)
			emit_signal("show_message", messages[2], true)
		4:
			emit_signal("show_message", messages[3], true)

		# espera ir pra escola
		5:
			emit_signal("focus", "School")

		# minigame explicação (dentro do minigame)
		6:
			queue_messages([messages[4], messages[5], messages[6]])

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
		messages[24],  # abas COMIDAS e BEBIDAS
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
