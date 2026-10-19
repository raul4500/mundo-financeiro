extends Node

const ParkQuizData = preload("res://scripts/park/park_quiz_data.gd")

# Diferença máxima, em palavras, entre a maior e a menor alternativa da mesma
# pergunta: acima disso o tamanho do texto começa a entregar a resposta.
const MAX_OPTION_WORD_SPREAD := 3
# Enunciado de situação, não de definição: precisa de contexto suficiente.
const MIN_STEM_WORDS := 20

func _words(text: String) -> int:
	return text.split(" ", false).size()

func _ready() -> void:
	print("=== Testando banco de perguntas do parque ===")

	var correct_positions := [0, 0, 0, 0]
	var correct_is_strictly_longest := 0
	var total := 0

	for week in range(1, 6):
		var questions: Array = ParkQuizData.get_questions(week)
		assert(questions.size() == 8, "Semana %d: 8 perguntas (há %d)" % [week, questions.size()])
		var positions_in_week := {}

		for i in range(questions.size()):
			var q: Dictionary = questions[i]
			var tag := "Semana %d, pergunta %d" % [week, i + 1]
			var options: Array = q.get("options", [])
			var explanations: Array = q.get("explanations", [])
			var correct := int(q.get("correct", -1))

			assert(options.size() == 4, "%s: 4 alternativas" % tag)
			assert(explanations.size() == 4, "%s: uma explicação por alternativa (há %d)" % [tag, explanations.size()])
			assert(correct >= 0 and correct < 4, "%s: gabarito dentro do intervalo" % tag)
			assert(_words(str(q.get("question", ""))) >= MIN_STEM_WORDS, "%s: o enunciado precisa ser uma situação (>= %d palavras)" % [tag, MIN_STEM_WORDS])

			var min_words := 1000
			var max_words := 0
			var seen := {}
			for j in range(4):
				var option := str(options[j])
				assert(option.strip_edges() != "", "%s: alternativa %d vazia" % [tag, j])
				assert(not seen.has(option), "%s: alternativas repetidas" % tag)
				seen[option] = true
				assert(str(explanations[j]).strip_edges() != "", "%s: explicação %d vazia" % [tag, j])
				var count := _words(option)
				min_words = mini(min_words, count)
				max_words = maxi(max_words, count)
			assert(max_words - min_words <= MAX_OPTION_WORD_SPREAD,
				"%s: alternativas de tamanhos muito diferentes (%d a %d palavras)" % [tag, min_words, max_words])

			# A certa não pode ser sempre a mais longa.
			var correct_words := _words(str(options[correct]))
			var strictly_longest := true
			for j in range(4):
				if j != correct and _words(str(options[j])) >= correct_words:
					strictly_longest = false
			if strictly_longest:
				correct_is_strictly_longest += 1

			correct_positions[correct] += 1
			positions_in_week[correct] = true
			total += 1

		assert(positions_in_week.size() >= 3, "Semana %d: o gabarito varia de posição" % week)
	print("  ok   40 perguntas: situação, 4 alternativas, 4 explicações cada")
	print("  ok   Alternativas com no máximo %d palavras de diferença entre si" % MAX_OPTION_WORD_SPREAD)

	assert(total == 40, "40 perguntas no total")
	for position in range(4):
		assert(correct_positions[position] >= 7, "A posição %d é a certa só %d vezes: o gabarito está viciado" % [position, correct_positions[position]])
	assert(correct_is_strictly_longest <= 16, "A certa é a mais longa em %d de 40 perguntas: o tamanho está entregando a resposta" % correct_is_strictly_longest)
	print("  ok   Gabarito distribuído %s; certa é a mais longa em %d/40" % [str(correct_positions), correct_is_strictly_longest])

	# Alerta de erro: explica a escolhida e mostra a certa, com o motivo.
	var q: Dictionary = ParkQuizData.get_questions(1)[0]
	var correct := int(q["correct"])
	var wrong := 0 if correct != 0 else 1
	var text := ParkQuizData.wrong_answer_feedback(q, wrong)
	assert(text.find(str(q["explanations"][wrong])) != -1, "O alerta traz a explicação da alternativa escolhida")
	assert(text.find(str(q["options"][correct])) != -1, "O alerta traz o texto da alternativa certa")
	assert(text.find(str(q["explanations"][correct])) != -1, "O alerta traz o motivo da alternativa certa")
	for j in range(4):
		if j != wrong and j != correct:
			assert(text.find(str(q["explanations"][j])) == -1, "O alerta não mistura a explicação de outras alternativas")
	# Índice inválido não derruba o alerta.
	assert(ParkQuizData.wrong_answer_feedback(q, -1).begins_with("Resposta incorreta."), "Índice inválido não quebra")
	print("  ok   Alerta de erro explica a escolhida e mostra a certa")

	print("=== Todos os testes do banco de perguntas passaram ===")
	get_tree().quit(0)
