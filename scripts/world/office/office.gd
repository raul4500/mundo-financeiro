extends Control

var levels_data: Array = [
	{
		"id": 1,
		"title": "Controle de gastos",
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
		"title": "Reserva de emergência",
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
				"name": "Eventos inesperados no jogo",
				"description": "A partir da semana 2, o jogo passa a sortear eventos inesperados: ocorrências financeiras que aparecem sem você pedir. Alguns são ruins, como o carro quebrar ou uma despesa médica. Outros são bons, como um trabalho freelance ou um bônus no trabalho.\n\nO ponto mais importante: o evento NÃO tira nem coloca dinheiro na sua conta na hora em que aparece. Ele vira uma pendência, e você decide quando resolver.\n\nAs contas a pagar e os bônus a resgatar ficam todos no BANCO, no painel \"Contas e bônus pendentes\", na parte de baixo da tela. Cada linha mostra o título, se é conta ou bônus, o valor e a semana em que apareceu. Ao lado, o botão \"Pagar\" ou \"Resgatar\".\n\nPor que isso importa: uma conta só sai do seu bolso quando você aperta Pagar, e para isso você precisa ter o dinheiro na mão. Se não tiver, a conta continua esperando. É exatamente aqui que a reserva de emergência do tópico anterior deixa de ser teoria: quem guardou dinheiro paga o imprevisto e segue em frente; quem gastou tudo fica com a conta pendurada.\n\nDica prática: sempre que passar no banco, olhe esse painel. Resgate os bônus (é dinheiro parado esperando por você) e pague as contas enquanto tem folga no orçamento."
			},
			{
				"name": "Juros",
				"description": "Juros são o custo de usar dinheiro ao longo do tempo. Quando você pega dinheiro emprestado, paga juros. Quando investe, recebe juros.\n\nPor exemplo: se você pega R$100 emprestados e precisa devolver R$120, os R$20 extras são os juros.\n\nOs juros podem trabalhar a seu favor ou contra você. Se você entra em dívidas, eles aumentam o valor que você deve. Se você investe, eles ajudam seu dinheiro a crescer.\n\nEntender juros é essencial para evitar armadilhas financeiras e aproveitar oportunidades."
			}
		]
	},
	{
		"id": 3,
		"title": "Investimentos básicos",
		"objective": "Apresentar as primeiras formas de fazer o dinheiro render com segurança e previsibilidade.",
		"topics": [
			{
				"name": "Poupança: o primeiro passo",
				"description": "A caderneta de poupança é a aplicação mais tradicional do país e o ponto de partida de quase todo investidor iniciante. Ela não cobra taxas de administração nem imposto de renda, conta com garantia e é muito simples de usar.\n\nPorém, ela esconde uma armadilha clássica: o rendimento costuma ser muito baixo. Em muitos momentos econômicos, a rentabilidade da poupança mal empata ou até perde para a inflação. Isso gera a ilusão de que o dinheiro está crescendo só porque o saldo na conta aumentou, enquanto na prática ele está perdendo poder de compra nas prateleiras dos supermercados.\n\nPense na poupança como as rodinhas de uma bicicleta infantil: são excelentes para dar os primeiros passos e aprender o hábito de guardar, mas devem ser deixadas para trás assim que você ganha confiança para buscar investimentos melhores."
			},
			{
				"name": "Renda fixa e títulos públicos",
				"description": "Investimentos de renda fixa funcionam como um contrato formal de empréstimo: você empresta o seu dinheiro para uma instituição e ela devolve o valor corrigido com juros em uma data futura pré-acordada.\n\nOs dois principais destinos na renda fixa são:\n• O Governo (Tesouro Direto): você financia obras públicas, saúde e educação do país. É considerado o investimento de menor risco de crédito de toda a economia nacional.\n• Os Bancos (CDBs, LCIs, LCAs): você empresta para instituições financeiras e conta com a proteção do FGC (Fundo Garantidor de Créditos) até o teto regulamentar.\n\nA grande vantagem é a previsibilidade: você já sabe com antecedência qual regra guiará seus rendimentos (seja uma taxa fixa acordada ou um índice como a taxa Selic/CDI), permitindo planejar o crescimento do patrimônio sem sustos."
			},
			{
				"name": "Juros compostos: o motor da riqueza",
				"description": "Enquanto os juros simples incidem apenas sobre o capital inicial, os juros compostos calculam o rendimento sobre o valor aplicado somado a todos os juros já gerados nos períodos anteriores. É o clássico efeito de juro sobre juro.\n\nO físico Albert Einstein costumava chamar os juros compostos de \"a oitava maravilha do mundo: quem entende, ganha; quem não entende, paga\".\n\nExemplo prático: se você aplicar R$ 1.000 a uma taxa de 10% ao ano:\n• No 1º ano, você ganha R$ 100 e fica com R$ 1.100.\n• No 2º ano, os 10% incidem sobre R$ 1.100, rendendo R$ 110 (totalizando R$ 1.210).\n• No 10º ano, o saldo terá mais que dobrado sem que você precise fazer nenhum esforço extra.\n\nCuriosidade: no início da jornada de investimentos, o valor que você guarda todo mês representa quase todo o seu patrimônio. Mas no longo prazo, o volume gerado pelos juros compostos ultrapassa o valor do seu próprio salário, criando uma verdadeira bola de neve a seu favor."
			},
			{
				"name": "Inflação: o ladrão invisível",
				"description": "A inflação é o aumento generalizado e contínuo dos preços de bens e serviços. Quando a inflação acontece, não são as coisas que sobem de valor por mágica; é o poder de compra da sua moeda que está encolhendo.\n\nSe uma compra básica de alimentos custava R$ 100 no ano passado e a inflação foi de 10%, hoje você precisa de R$ 110 para levar para casa exatamente os mesmos produtos. Por isso, deixar dinheiro parado na carteira, na conta-corrente ou embaixo do colchão é garantia de empobrecimento diário e silencioso.\n\nO conceito que todo investidor precisa dominar é o Ganho Real: se seu investimento rende 8% no ano e a inflação foi de 5%, o seu ganho real foi de aproximadamente 3%. Nunca avalie um rendimento isoladamente; compare-o sempre com a inflação para garantir que seu poder de compra está sendo protegido."
			},
			{
				"name": "Liquidez: ter o dinheiro na mão",
				"description": "Liquidez é a velocidade e a facilidade com que você consegue transformar um investimento de volta em dinheiro disponível para uso imediato, sem sofrer deságio ou penalidade financeira.\n\nOs investimentos se dividem essencialmente em dois perfis de liquidez:\n• Alta liquidez (diária ou imediata): você pede o resgate e o dinheiro cai na conta no mesmo dia (D+0) ou no próximo dia útil (D+1). Esse é o modelo obrigatório para a sua reserva de emergência e para os compromissos do mês.\n• Baixa liquidez (com prazo de carência): seu dinheiro fica retido por meses ou anos. Em troca de abrir mão da disponibilidade imediata, o emissor do título costuma pagar taxas de juros consideravelmente maiores.\n\nRegra prática: jamais aplique o dinheiro de pagar contas essenciais ou imprevistos em investimentos com prazo fechado. Tentar resgatar antes do vencimento pode resultar em perdas pesadas ou simplesmente ser recusado pelas regras do produto."
			}
		]
	},
	{
		"id": 4,
		"title": "Mercado financeiro",
		"objective": "Introduzir os fundamentos da renda variável, gestão de risco e geração de renda passiva.",
		"topics": [
			{
				"name": "Ações e Fundos Imobiliários (FIIs)",
				"description": "Na renda variável, você deixa de ser apenas um credor que empresta dinheiro e se torna coproprietário de ativos reais da economia.\n\n• Ações: representam frações do capital de uma empresa. Ao comprar uma ação na Bolsa de Valores, você se torna sócio do negócio, colhendo os frutos da expansão da empresa e da valorização das marcas.\n• Fundos Imobiliários (FIIs): reúnem milhares de investidores para adquirir grandes empreendimentos imobiliários, como galpões logísticos de e-commerce, shoppings e edifícios comerciais de alto padrão.\n\nNo Mundo Financeiro você investe diretamente em FIIs pelo menu do Banco. Em vez de precisar juntar centenas de milhares de reais para comprar um imóvel físico, arcar com reformas e cobrar inquilinos, você compra cotas acessíveis e recebe sua parte proporcional dos aluguéis gerados todos os meses."
			},
			{
				"name": "Risco e Retorno: a balança dos mercados",
				"description": "A regra mais universal do mercado financeiro afirma que não existe retorno elevado sem risco proporcional.\n\nAplicações ultrasseguras pagam rendimentos moderados, porém previsíveis. Já ativos de renda variável, como ações e fundos imobiliários, possuem potencial para multiplicar seu capital no longo prazo, mas com as cotas oscilando para cima e para baixo constantemente.\n\nSe alguém oferecer uma oportunidade de investimento prometendo lucros altos, garantidos e sem nenhum risco, desconfie na hora: matematicamente, isso não existe no mercado sério.\n\nO objetivo do investidor consciente não é fugir de todo e qualquer risco, mas sim conhecer seu perfil de tolerância (conservador, moderado ou arrojado) e assumir apenas riscos calculados e inteligentes, alinhados aos seus prazos."
			},
			{
				"name": "Diversificação: a regra dos ovos e da cesta",
				"description": "Um antigo ditado popular sintetiza a gestão de patrimônio: \"nunca coloque todos os seus ovos em uma única cesta\", pois uma simples queda quebra todos eles de uma só vez.\n\nO economista Harry Markowitz ganhou o Prêmio Nobel ao demonstrar matematicamente que a diversificação é o único \"almoço grátis\" dos investimentos. Ao espalhar seus recursos entre ativos de naturezas distintas que não reagem da mesma forma aos cenários econômicos, você diminui o risco geral da sua carteira sem sacrificar o potencial de retorno.\n\nNo jogo, você pratica isso na missão da Semana 4: concentrar todo o seu capital apenas em fundos de shopping centers deixa você vulnerável a crises de consumo. Mas ao diversificar adquirindo cotas de galpões logísticos e lajes corporativas, a estabilidade de um setor compensa as oscilações de outro."
			},
			{
				"name": "Proventos e Dividendos: renda passiva",
				"description": "Proventos são as fatias do lucro líquido que as empresas e os fundos imobiliários distribuem periodicamente aos seus acionistas e cotistas em dinheiro na conta.\n\nNo Brasil, os Fundos Imobiliários são obrigados por lei a distribuir no mínimo 95% do lucro semestral auferido. Na rotina dos mercados, quase todos pagam esses rendimentos todos os meses, caindo limpos e sem imposto de renda para a pessoa física.\n\nEssa é a definição autêntica de Renda Passiva: dinheiro trabalhando e gerando novos recursos para você de forma automática, sem exigir que você venda mais horas do seu dia.\n\nO segredo dos grandes investidores é o reinvestimento: usar os proventos recebidos para comprar novas cotas. No mês seguinte, mais cotas geram mais proventos, criando um ciclo perpétuo e acelerado de crescimento patrimonial."
			},
			{
				"name": "Volatilidade e o Efeito Manada",
				"description": "Volatilidade é a intensidade e a frequência com que os preços das cotas negociadas em Bolsa sobem e descem em curtos espaços de tempo. Ela é movida por notícias diárias, balanços trimestrais, taxas de juros e pelo comportamento emocional coletivo dos investidores.\n\nO maior adversário de quem ingressa no mercado de capitais não é a matemática, mas o descontrole emocional. O erro mais devastador é o \"efeito manada\": o investidor leigo compra cotas quando elas estão no topo porque todos estão eufóricos, e entra em pânico na primeira queda do mercado, vendendo seus ativos no fundo e consolidando um prejuízo real.\n\nLembre-se: oscilações no painel só se transformam em prejuízo de fato se você apertar o botão de vender na baixa. No jogo, vender cotas com prejuízo é penalizado com imposto sobre a perda. Paciência, disciplina e visão de longo prazo são as maiores virtudes de quem investe com sabedoria."
			}
		]
	},
	{
		"id": 5,
		"title": "Empreendedorismo",
		"objective": "Ensinar a administrar um negócio próprio usando as decisões reais disponíveis no jogo.",
		"topics": [
			{
				"name": "Escolher e comprar o negócio",
				"description": "Abrir um negócio começa por uma decisão de capital: você troca dinheiro que já tem por uma fonte de renda que ainda não existe.\n\nNo jogo existem três negócios, com portas próprias no mapa:\n\n• Restaurante Sabor da Praça — R$ 1.500\n• Fliperama Neon — R$ 12.000\n• Centro Comercial Mundo Mix — R$ 85.000\n\nO preço de compra é só a entrada. Depois dela você ainda precisa de dinheiro para estoque, contas e funcionários. Comprar um negócio com o caixa raspado é o erro mais comum de quem começa: o negócio abre e trava por falta de capital de giro.\n\nRegra prática: só compre quando sobrar dinheiro suficiente para operar as primeiras semanas sem depender do lucro."
			},
			{
				"name": "Como o negócio gera lucro",
				"description": "Todo dia que passa no jogo, cada negócio que você possui opera automaticamente e calcula:\n\nLucro do dia = Receita do dia − Despesas do dia\n\nA receita vem do movimento do negócio; as despesas são os custos de manter as portas abertas. O resultado entra (ou sai) direto do seu dinheiro.\n\nExemplo com o restaurante: receita de R$ 70 e despesa operacional de R$ 25 dão lucro de R$ 45 por dia, ou seja, R$ 315 na semana.\n\nMas atenção: esse cálculo diário não inclui as contas semanais nem a folha de pagamento. Um negócio pode ter lucro diário positivo e ainda assim fechar a semana no prejuízo. Sempre olhe o resultado da semana inteira, não só o do dia."
			},
			{
				"name": "Estoque e capital de giro",
				"description": "Estoque é o dinheiro que você transforma em mercadoria para poder vender. No jogo ele é comprado por lote e consumido um pouco por dia.\n\nO ponto crítico: um negócio sem nenhum estoque não fecha as portas, mas passa a render apenas 35% da receita normal. Ele continua pagando as despesas e quase não fatura — o pior dos dois mundos.\n\nExemplo no restaurante: um lote de ingredientes custa R$ 80 e rende 5 unidades, consumidas em 5 dias. Se você esquecer de repor, na sexta-feira a receita cai de R$ 70 para cerca de R$ 25.\n\nAlguns itens ainda dão bônus de receita: bebidas somam R$ 8 por dia enquanto houver estoque delas. Repor estoque não é gasto, é o que mantém o faturamento vivo."
			},
			{
				"name": "Custos fixos e custos variáveis",
				"description": "Essa é a distinção mais importante para não quebrar um negócio.\n\nCustos variáveis acompanham a operação. O estoque é o exemplo: se o movimento cai, você compra menos.\n\nCustos fixos chegam mesmo que você não venda nada. No jogo são três:\n\n• despesa operacional diária;\n• contas de água e luz, geradas toda semana;\n• folha de pagamento dos funcionários, também semanal.\n\nQuanto maior a fatia de custos fixos, mais frágil o negócio fica em uma semana ruim. É por isso que o Centro Comercial, com R$ 1.550 só de água e luz por semana, exige uma reserva muito maior que o restaurante, com R$ 50.\n\nAntes de assumir qualquer custo fixo novo, pergunte: se o faturamento cair pela metade, eu ainda consigo pagar isso?"
			},
			{
				"name": "Contas em atraso e inadimplência",
				"description": "No fim de cada semana o negócio recebe as contas de água e luz e, se você tiver equipe, a folha de pagamento. Elas ficam na lista de contas pendentes e você tem a semana seguinte inteira para pagar.\n\nSe passar desse prazo, a conta vira atraso — e atraso tem preço: a receita do negócio cai 25% enquanto existir qualquer conta vencida. Serviços são cortados, a estrutura piora e o cliente vai embora.\n\nPior ainda: a conta não desaparece. Ela continua na lista e as contas da semana seguinte se somam a ela. É assim que uma dívida pequena vira uma bola de neve que consome o negócio.\n\nPagar conta em dia não é burocracia, é proteção da receita. Na dúvida entre comprar estoque e pagar uma conta vencida, pague a conta: ela está cortando 25% de tudo que você fatura."
			},
			{
				"name": "Equipamentos: investir com manutenção",
				"description": "Equipamentos são investimentos que melhoram o negócio de forma permanente. Cada um aumenta a receita diária e a capacidade de atendimento.\n\nMas todo equipamento tem duas faces. O fogão industrial do restaurante custa R$ 350 uma única vez e traz R$ 18 de receita por dia — porém acrescenta R$ 8 de manutenção às despesas diárias, para sempre.\n\nO ganho líquido real é R$ 18 − R$ 8 = R$ 10 por dia. Nesse ritmo, o fogão se paga em 35 dias. Esse cálculo se chama payback, e é ele que separa um bom investimento de uma armadilha.\n\nAntes de comprar qualquer equipamento, calcule: quanto ele acrescenta de receita por dia, menos quanto ele acrescenta de manutenção, e em quantos dias o preço se paga."
			},
			{
				"name": "Capacidade: o gargalo do negócio",
				"description": "Um negócio não fatura mais do que sua estrutura consegue atender. No jogo isso é a capacidade, e ela define um teto de receita: por mais bônus que você acumule, a receita para nesse limite.\n\nÉ o gargalo clássico. Não adianta atrair mais clientes se não há mesa para sentar, máquina para jogar ou loja para entrar.\n\nExemplo: o restaurante começa com capacidade 10 e teto de receita de R$ 100 por dia. Se você comprar itens que somam R$ 130 de receita mas não aumentar a capacidade, você ainda vai faturar R$ 100 — e o dinheiro investido nos bônus foi desperdiçado.\n\nA capacidade cresce de duas formas: equipamentos e funcionários. Sempre confira o teto de receita na tela do negócio antes de investir em bônus: se a receita já está batendo no teto, o próximo investimento tem que ser em capacidade."
			},
			{
				"name": "Contratar funcionários",
				"description": "Contratar é assumir um custo fixo em troca de mais capacidade de produzir.\n\nCada funcionário do restaurante custa R$ 90 por semana de salário e traz R$ 18 de receita por dia, ou seja, R$ 126 na semana. O ganho líquido é de R$ 36 semanais — positivo, mas apertado. Ele também soma 3 de capacidade, o que muitas vezes vale mais que a receita direta, porque levanta o teto do negócio.\n\nO risco: o salário é cobrado toda semana, independente do movimento. Contratar demais em um negócio que ainda não fatura o suficiente é uma das formas mais rápidas de quebrar.\n\nContrate quando a receita estiver batendo no teto de capacidade e você tiver reserva para pagar a folha por algumas semanas mesmo em um período ruim. E lembre: demitir resolve o custo, mas derruba a capacidade junto."
			},
			{
				"name": "Aprimorar o nível do negócio",
				"description": "Cada negócio tem 5 níveis. O nível 1 vem com a compra; subir de nível exige investimento em dinheiro, não apenas tempo.\n\nAprimorar tem dois efeitos:\n\n• multiplica a receita base — nível 2 rende 1,2 vez, nível 3 rende 1,45 vez, e assim até 2,15 vez no nível 5;\n• desbloqueia equipamentos melhores, que exigem nível mínimo.\n\nNo restaurante, a geladeira maior só pode ser comprada a partir do nível 2 e as mesas confortáveis a partir do nível 3. Sem aprimorar, metade do catálogo de equipamentos fica inacessível para sempre.\n\nO aprimoramento é o principal caminho de crescimento de um negócio que você já domina. Antes de comprar um segundo negócio, pergunte se o dinheiro não renderia mais aprimorando o que você já tem."
			},
			{
				"name": "Reinvestimento e ponto de equilíbrio",
				"description": "O ponto de equilíbrio é o faturamento em que a receita cobre exatamente todos os custos: não há lucro nem prejuízo. Abaixo dele, o negócio consome seu dinheiro; acima, ele gera caixa.\n\nPara calcular no jogo, some tudo o que sai em uma semana: despesas diárias vezes 7, contas de água e luz, folha de pagamento e o estoque que você precisa repor. Compare com a receita da semana.\n\nSó depois de passar do ponto de equilíbrio com folga faz sentido reinvestir — usar parte do lucro para aprimorar, comprar equipamento ou contratar, em vez de gastar tudo.\n\nReinvestir cedo demais, antes do negócio se sustentar, é apostar dinheiro em uma estrutura que ainda não se paga. Reinvestir tarde demais é deixar o negócio estagnado enquanto o dinheiro fica parado."
			},
			{
				"name": "Escalar para negócios maiores",
				"description": "Os três negócios do jogo formam uma escada de risco e retorno, a mesma lógica dos investimentos.\n\nO restaurante custa R$ 1.500 e fatura pouco, mas erra barato: se algo der errado, o prejuízo é pequeno. O Centro Comercial custa R$ 85.000 e fatura R$ 2.600 por dia, mas só de água e luz consome R$ 1.550 por semana — um mês de descuido ali custa mais que o restaurante inteiro.\n\nEscalar não é só ter dinheiro para o preço de compra. É ter reserva para aguentar as semanas ruins de um negócio com custos fixos muito maiores.\n\nO caminho saudável é o mesmo de uma carteira de investimentos: comece pequeno, aprenda a administrar de verdade — estoque, contas, capacidade, equipe —, acumule reserva e só então suba um degrau. Empreender bem é menos sobre ter a ideia certa e mais sobre sobreviver ao tempo suficiente para ela dar resultado."
			}
		]
	}
]


var player_level: int = 1
var time_display: Label

@onready var level_container: VBoxContainer = $HBoxContainer/LevelPanel/Levels
@onready var topics_container: VBoxContainer = $HBoxContainer/TopicPanel/ScrollContainer/Topics
@onready var detail_label: RichTextLabel = $HBoxContainer/DetailPanel/ScrollContainer/RichTextLabel


func _ready() -> void:
	if not Global.is_any_tutorial_active():
		Global.play_time = true
	_create_time_display()
	_load_player_progress()
	_build_ui()
	_build_level_section()

func _create_time_display() -> void:
	time_display = preload("res://scripts/ui/time_display.gd").new()
	time_display.position = Vector2(24, 20)
	time_display.add_theme_font_size_override("font_size", 22)
	add_child(time_display)


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
	# Sair do escritório é o que destrava o resto da cidade no tutorial.
	TutorialManager.on_player_left_office()
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
