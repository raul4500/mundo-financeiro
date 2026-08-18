extends Node

signal show_message(text)
signal tutorial_finished
signal focus(point)

var step := 0
var pending_messages: Array = []

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
		"title": "Conclusão",
		"goal": "Encerrar o onboarding e liberar o jogador para explorar e evoluir.",
		"speaker_note": "A mensagem final é que o progresso vem de decisões consistentes e conscientes."
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

	"Parabéns! Você concluiu o minigame e recebeu seu primeiro salário. Agora é hora de começar a administrar melhor seu dinheiro e aprender a lidar com gastos, poupança e investimentos.",

	"O mundo do jogo oferece vários lugares estratégicos. Cada um deles tem um papel importante na sua rotina financeira e no seu desenvolvimento como jogador.",

	"No mercado, você pode comprar itens essenciais para o seu dia a dia. Cuidado para não gastar mais do que a sua renda permite e mantenha o equilíbrio entre necessidade e desejo.",

	"No banco, você pode guardar seu dinheiro, acompanhar o saldo e explorar oportunidades de investimento. Essa é a base para construir uma reserva financeira e tomar decisões mais inteligentes.",

	"No escritório de consultoria, você encontra conteúdos educativos, dicas e ferramentas para compreender melhor o mundo financeiro. Aproveite esses aprendizados para melhorar sua estratégia e evoluir no jogo.",

	"Lembre-se: gastar com consciência, economizar e investir são as chaves para o sucesso. Pequenas decisões bem tomadas ao longo do tempo fazem uma grande diferença no futuro.",

	"Agora é com você. Explore o mundo, cumpra suas missões, tome decisões inteligentes e construa uma vida financeira forte, estável e bem planejada!"
]

func get_presentation_guide() -> Array:
	return presentation_guide

func teste():
	emit_signal("show_message", messages[0])

func start_tutorial():
	step = 0
	pending_messages.clear()
	_next_step()

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
			queue_messages([messages[4], messages[5], messages[6]])

		# espera terminar minigame
		7:
			pass

		# pós minigame
		8:
			queue_messages([
				messages[7],
				messages[8],
				messages[9],
				messages[10],
				messages[11],
				messages[12],
				messages[13]
			])
			emit_signal("tutorial_finished")


# =============================
# 🎯 EVENTOS DO JOGO 
# =============================

func on_player_entered_school():
	if step == 5:
		_next_step()


func on_minigame_finished():
	if step == 7:
		_next_step()
