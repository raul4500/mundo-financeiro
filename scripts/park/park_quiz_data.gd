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
			{"question": "Qual é a principal desvantagem da caderneta de poupança?", "options": ["Ela cobra taxas muito altas", "O rendimento costuma ser baixo e pode perder para a inflação", "Ela não tem garantia nenhuma", "Só pode ser resgatada após 10 anos"], "correct": 1},
			{"question": "A poupança é uma opção recomendada principalmente para:", "options": ["Quem busca multiplicar o patrimônio rapidamente", "Iniciantes aprenderem o hábito de guardar dinheiro", "Investidores arrojados", "Quem não quer guardar nada"], "correct": 1},
			{"question": "O que caracteriza os investimentos de renda fixa?", "options": ["Você não sabe se receberá algo", "Previsibilidade: funcionam como um empréstimo com juros combinados", "Risco de perder todo o dinheiro", "São exclusivos de empresas de tecnologia"], "correct": 1},
			{"question": "Ao investir no Tesouro Direto, para quem você está emprestando dinheiro?", "options": ["Para um amigo", "Para o Governo financiar obras e serviços públicos", "Para uma empresa estrangeira", "Para uma corretora de apostas"], "correct": 1},
			{"question": "O que são juros compostos?", "options": ["Juros cobrados apenas uma única vez", "Rendimento calculado sobre o valor inicial e sobre os juros já acumulados", "Uma taxa fixa que não muda com o tempo", "Um desconto que você recebe ao comprar à vista"], "correct": 1},
			{"question": "Por que os juros compostos são chamados de efeito bola de neve no longo prazo?", "options": ["Porque eles derretem com o calor", "Porque o rendimento acumulado passa a crescer de forma exponencial", "Porque só funcionam no inverno", "Porque impedem o crescimento do dinheiro"], "correct": 1},
			{"question": "O que acontece com o seu dinheiro quando a inflação da economia sobe?", "options": ["O poder de compra diminui: você compra menos com a mesma quantia", "O poder de compra aumenta", "As notas de dinheiro dobram de valor", "Os juros caem para zero automaticamente"], "correct": 0},
			{"question": "O que significa dizer que um investimento tem 'alta liquidez diária'?", "options": ["Que ele só rende de dia", "Que você pode resgatar o dinheiro de volta na conta no mesmo dia sem penalidade", "Que ele não pode ser resgatado nunca", "Que ele tem alto risco de perda"], "correct": 1},
		],
		4: [
			{"question": "O que representa uma ação negociada na Bolsa de Valores?", "options": ["Uma dívida da empresa com você", "Uma pequena fração do capital social de uma empresa (sociedade)", "Um empréstimo com juros fixos", "Um imposto obrigatório"], "correct": 1},
			{"question": "O que são Fundos Imobiliários (FIIs)?", "options": ["Empréstimos bancários para obras", "Forma acessível de investir em grandes imóveis e receber aluguéis", "Um tipo de poupança estudantil", "Impostos sobre terrenos urbanos"], "correct": 1},
			{"question": "Qual é a relação fundamental entre risco e retorno nos investimentos?", "options": ["Quanto maior o risco, menor a chance de ganho", "Quanto maior o potencial de retorno, maior é o risco associado", "Não há qualquer ligação entre risco e retorno", "Investimentos seguros sempre rendem mais que os arriscados"], "correct": 1},
			{"question": "Qual a principal vantagem da diversificação de investimentos ('não pôr todos os ovos na mesma cesta')?", "options": ["Garantir lucro diário sem esforço", "Reduzir o risco da carteira espalhando o capital entre ativos diferentes", "Aumentar os custos de transação", "Concentrar todo o dinheiro no ativo mais arriscado"], "correct": 1},
			{"question": "No jogo, por que é recomendável investir em mais de um fundo imobiliário?", "options": ["Porque fundos diferentes não podem ser comprados", "Para proteger a carteira caso um setor específico tenha queda no rendimento", "Para pagar mais imposto de renda", "Porque o banco exige a compra de todos"], "correct": 1},
			{"question": "O que são proventos e dividendos em investimentos?", "options": ["Taxas que o investidor precisa pagar todo mês", "Fatias do lucro que empresas e FIIs distribuem aos acionistas e cotistas", "Dívidas contraídas na compra de ações", "Multas por resgate antecipado"], "correct": 1},
			{"question": "Por que reinvestir os proventos e dividendos recebidos é uma estratégia tão poderosa?", "options": ["Porque comprar novas cotas com os lucros acelera o crescimento patrimonial", "Porque evita que o banco confisque o dinheiro", "Porque dividendos perdem a validade se não forem reinvestidos", "Porque diminui o valor das cotas antigas"], "correct": 0},
			{"question": "Qual é um dos maiores erros comportamentais do investidor iniciante ao lidar com a volatilidade?", "options": ["Manter a calma e focar no longo prazo", "Vender na baixa em pânico e comprar na alta por euforia (efeito manada)", "Estudar o histórico da empresa antes de investir", "Diversificar a carteira em setores sólidos"], "correct": 1},
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
