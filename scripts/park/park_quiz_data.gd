extends RefCounted

# Banco de perguntas do quiz do minigame do parque: 8 por semana (1 a 5),
# alinhadas ao conteúdo de scripts/world/office/office.gd (levels_data) para
# reforçar o que o jogador está estudando naquela semana.
static func _bank() -> Dictionary:
	return {
		1: [
			{"question": "O que é uma necessidade, e não um desejo?", "options": ["Um lanche extra", "Comida para se alimentar", "Roupa nova sem necessidade", "Item de lazer"], "correct": 1},
			{"question": "Qual desses é um exemplo de desejo, não de necessidade?", "options": ["Moradia", "Transporte para o trabalho", "Um jogo novo", "Remédio necessário"], "correct": 2},
			{"question": "Por que é importante planejar os gastos antes de gastar?", "options": ["Para gastar tudo rápido", "Para saber quanto sobra para cada gasto", "Porque planejamento não muda nada", "Para não precisar guardar dinheiro"], "correct": 1},
			{"question": "Você ganha R$500 na semana e vai gastar R$200 no mercado e R$100 no transporte. Quanto sobra?", "options": ["R$100", "R$200", "R$300", "R$500"], "correct": 1},
			{"question": "Qual a vantagem de dividir o dinheiro em orçamento semanal em vez de pensar só no mês?", "options": ["Não faz diferença", "Evita gastar tudo nos primeiros dias", "Aumenta os gastos", "Elimina a necessidade de planejar"], "correct": 1},
			{"question": "Você tem R$400 para o mês, dividido em 4 semanas iguais. Quanto separa por semana?", "options": ["R$50", "R$100", "R$150", "R$400"], "correct": 1},
			{"question": "Qual o benefício de economizar, mesmo guardando pouco por vez?", "options": ["Nenhum, é melhor gastar tudo", "Cresce com o tempo e dá segurança", "Só funciona com valores altos", "Impede qualquer gasto futuro"], "correct": 1},
			{"question": "Se você guarda R$10 por semana, quanto terá em 10 semanas?", "options": ["R$10", "R$50", "R$100", "R$1000"], "correct": 2},
		],
		2: [
			{"question": "Para que serve a reserva de emergência?", "options": ["Para gastar com lazer", "Para cobrir situações inesperadas", "Para investir em ações arriscadas", "Ela não tem uso definido"], "correct": 1},
			{"question": "A reserva de emergência deve ser usada para:", "options": ["Comprar roupas novas", "Viajar de férias", "Uma emergência médica", "Comprar itens de luxo"], "correct": 2},
			{"question": "O que é um imprevisto financeiro?", "options": ["Um gasto planejado com antecedência", "Um gasto que aparece sem aviso", "Um tipo de investimento", "Um bônus garantido todo mês"], "correct": 1},
			{"question": "Sem uma reserva, um imprevisto financeiro tende a:", "options": ["Resolver-se sozinho", "Virar um grande problema", "Não afetar as finanças", "Gerar mais economia"], "correct": 1},
			{"question": "No jogo, quando um evento inesperado aparece, o que acontece com seu dinheiro na hora?", "options": ["É debitado ou creditado na hora", "Nada muda até você decidir resolver", "Você perde metade do saldo", "O evento é cancelado automaticamente"], "correct": 1},
			{"question": "Onde ficam as contas e bônus pendentes de eventos no jogo?", "options": ["Na escola", "No banco", "No mercado", "Na casa"], "correct": 1},
			{"question": "O que são juros?", "options": ["Um imposto fixo", "O custo de usar dinheiro ao longo do tempo", "Um tipo de reserva", "Um bônus sem custo"], "correct": 1},
			{"question": "Você pega R$100 emprestados e devolve R$120. Quanto foram os juros?", "options": ["R$0", "R$20", "R$100", "R$120"], "correct": 1},
		],
		3: [
			{"question": "O que caracteriza a poupança como investimento?", "options": ["Alto risco e alto retorno", "Segurança, mas rendimento baixo", "Rendimento garantido alto", "Só serve para emergências médicas"], "correct": 1},
			{"question": "A poupança é uma boa opção para quem:", "options": ["Quer o maior retorno possível", "Está começando a aprender a investir", "Não quer guardar dinheiro", "Busca alto risco"], "correct": 1},
			{"question": "Qual é uma vantagem da poupança?", "options": ["Rende mais que qualquer investimento", "Ensina o hábito de guardar dinheiro", "Não pode ser resgatada", "É proibida para iniciantes"], "correct": 1},
			{"question": "A poupança pode ser comparada a:", "options": ["Um cofre que só perde dinheiro", "Um cofre que soma pequenas moedas com o tempo", "Um empréstimo sem juros", "Uma dívida"], "correct": 1},
			{"question": "Em um investimento de renda fixa, você:", "options": ["Não sabe quanto vai receber", "Já tem uma ideia de quanto vai ganhar", "Perde dinheiro garantido", "Só pode investir uma vez"], "correct": 1},
			{"question": "Investir R$100 em renda fixa e receber R$110 depois é um exemplo de:", "options": ["Prejuízo", "Retorno de renda fixa", "Poupança obrigatória", "Erro financeiro"], "correct": 1},
			{"question": "Renda fixa é considerada, em geral:", "options": ["Mais arriscada que ações", "Mais segura e previsível", "Impossível de calcular", "Igual a não investir"], "correct": 1},
			{"question": "Investir em renda fixa é parecido com:", "options": ["Apostar em loteria", "Emprestar dinheiro com contrato definido", "Gastar tudo de uma vez", "Doar dinheiro sem retorno"], "correct": 1},
		],
		4: [
			{"question": "O que é uma ação?", "options": ["Uma dívida da empresa", "Uma pequena parte de uma empresa", "Um tipo de poupança", "Um imposto sobre lucro"], "correct": 1},
			{"question": "Ao comprar uma ação, você se torna:", "options": ["Funcionário da empresa", "Sócio da empresa", "Credor do governo", "Dono de um imóvel"], "correct": 1},
			{"question": "O que são fundos imobiliários (FIIs)?", "options": ["Empréstimos bancários", "Forma de investir em imóveis sem comprar um diretamente", "Um tipo de poupança escolar", "Ações do governo"], "correct": 1},
			{"question": "Ao investir em um FII, você recebe:", "options": ["Nada, é só especulação", "Parte dos lucros gerados pelos imóveis", "Um imóvel físico imediato", "Um salário fixo"], "correct": 1},
			{"question": "Qual a relação entre risco e retorno nos investimentos?", "options": ["Quanto maior o risco, menor o retorno possível", "Quanto maior o potencial de ganho, maior o risco", "Risco e retorno não têm relação", "Investimentos seguros sempre rendem mais"], "correct": 1},
			{"question": "Investimentos mais arriscados tendem a:", "options": ["Render sempre pouco e garantido", "Poder gerar grandes ganhos ou perdas", "Ser proibidos para iniciantes", "Nunca perder dinheiro"], "correct": 1},
			{"question": "Escolher entre um investimento seguro e um arriscado é como:", "options": ["Escolher entre dois caminhos iguais", "Escolher entre um caminho seguro e um atalho perigoso", "Não ter escolha nenhuma", "Sempre escolher o mais caro"], "correct": 1},
			{"question": "O segredo para investir bem, segundo risco e retorno, é:", "options": ["Buscar sempre o maior risco", "Equilibrar risco e retorno conforme seus objetivos", "Nunca correr nenhum risco", "Investir tudo em um único lugar"], "correct": 1},
		],
		5: [
			{"question": "Antes de comprar um negócio, você deve garantir que sobra dinheiro para:", "options": ["Nada, o preço de compra já é suficiente", "Operar as primeiras semanas sem depender do lucro", "Comprar outro negócio imediatamente", "Pagar apenas o dono anterior"], "correct": 1},
			{"question": "Como se calcula o lucro diário de um negócio no jogo?", "options": ["Receita do dia + Despesas do dia", "Receita do dia − Despesas do dia", "Só a receita do dia", "Só as despesas do dia"], "correct": 1},
			{"question": "O que acontece com um negócio sem nenhum estoque?", "options": ["Ele fecha imediatamente", "Continua com despesas mas rende muito menos", "Passa a render mais que o normal", "Nada muda"], "correct": 1},
			{"question": "Qual a diferença entre custo fixo e custo variável?", "options": ["Não existe diferença", "Custo fixo chega mesmo sem vender nada; variável acompanha a operação", "Custo variável é sempre maior", "Custo fixo só existe em negócios grandes"], "correct": 1},
			{"question": "O que acontece quando uma conta do negócio vence sem ser paga?", "options": ["Nada, ela some sozinha", "A receita do negócio cai enquanto houver conta vencida", "O negócio fecha na hora", "Você ganha um bônus"], "correct": 1},
			{"question": "Ao avaliar um equipamento novo, o que é o \"payback\"?", "options": ["O preço de compra do equipamento", "Em quantos dias o investimento se paga com o ganho líquido", "O imposto sobre o equipamento", "O tempo de garantia"], "correct": 1},
			{"question": "O que representa a capacidade de um negócio?", "options": ["O lucro total acumulado", "O teto de receita que a estrutura consegue atender", "O número de funcionários demitidos", "O preço de venda do negócio"], "correct": 1},
			{"question": "Antes de contratar um funcionário, é importante verificar se:", "options": ["A receita já está no teto de capacidade e há reserva para pagar o salário", "O negócio está fechado", "Não há clientes nenhum", "O funcionário aceita trabalhar de graça"], "correct": 1},
		],
	}

# Semanas além da última com conteúdo (5) reaproveitam o banco da semana 5.
static func get_questions(week: int) -> Array:
	var bank = _bank()
	var clamped = clampi(week, 1, 5)
	return bank.get(clamped, [])
