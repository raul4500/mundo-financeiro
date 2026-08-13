extends Node

signal show_message(text)
signal tutorial_finished

signal focus(point)

var step := 0

var messages = [
	"Bem-vindo ao Mundo Financeiro! Neste jogo, você vai aprender a cuidar do seu dinheiro, tomar decisões importantes e construir uma vida financeira saudável. Cada escolha que você fizer terá consequências, então pense bem antes de agir!",

	"Seu objetivo aqui é simples: aprender a ganhar, economizar e investir seu dinheiro da melhor forma possível. Ao longo do jogo, você vai desbloquear novos conhecimentos e enfrentar desafios que simulam a vida real.",

	"Para começar sua jornada, vá até a escola. Lá você participará de um minigame que definirá seu nível de escolaridade.",

	"O seu nível de escolaridade influencia diretamente o seu salário. Quanto maior sua formação, maiores serão suas oportunidades e sua renda semanal dentro do jogo.",

	"Antes de começar, preste atenção: suas escolhas no minigame vão impactar o quanto você ganha. Pense com calma e faça boas decisões!",

	"Neste minigame, você precisará responder corretamente e tomar decisões relacionadas à sua formação. Cada acerto aumenta seu nível de escolaridade, enquanto erros podem limitar suas oportunidades.",

	"O objetivo é alcançar o melhor nível possível, garantindo um salário maior no jogo. Boa sorte!",

	"Parabéns! Você concluiu o minigame e já recebeu seu primeiro salário. Agora é hora de começar a administrar seu dinheiro!",

	"No mundo do jogo, você pode visitar diferentes lugares importantes. Cada um deles tem um papel fundamental na sua vida financeira.",

	"No mercado, você poderá comprar itens essenciais para o seu dia a dia. Tome cuidado para não gastar mais do que deveria!",

	"No banco, você poderá guardar dinheiro, fazer investimentos e organizar melhor suas finanças.",

	"No escritório de consultoria, você encontrará conteúdos educativos e dicas importantes para melhorar suas decisões financeiras.",

	"Lembre-se: gastar bem, economizar e investir são as chaves para o sucesso no jogo. Suas escolhas vão definir seu futuro!",

	"Agora é com você. Explore o mundo, cumpra suas missões e construa sua vida financeira!"
]

func teste():
	emit_signal("show_message", messages[0])

func start_tutorial():
	step = 0
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
			emit_signal("show_message", messages[4], true)
			emit_signal("show_message", messages[5], true)
			emit_signal("show_message", messages[6], true)
		
		# espera terminar minigame
		7:
			pass
		
		# pós minigame
		8:
			emit_signal("show_message", messages[7], true)
			emit_signal("show_message", messages[8], true)
			emit_signal("show_message", messages[9], true)
			emit_signal("show_message", messages[10], true)
			emit_signal("show_message", messages[11], true)
			emit_signal("show_message", messages[12], true)
			emit_signal("show_message", messages[13])
			
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
