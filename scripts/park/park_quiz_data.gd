extends RefCounted

# Banco de perguntas do quiz do minigame do parque: 8 por semana (1 a 5),
# alinhadas ao conteúdo de scripts/world/office/office.gd (levels_data) para
# reforçar o que o jogador está estudando naquela semana.
#
# Formato de cada pergunta:
#   question     - enunciado em forma de situação: o jogador interpreta o caso e
#                  aplica o que aprendeu, em vez de repetir uma definição.
#   options      - 4 alternativas, com quantidade de palavras parecida entre si
#                  (a diferença de tamanho não pode entregar a resposta).
#   correct      - índice da alternativa certa. A posição varia de propósito.
#   explanations - 4 textos, um por alternativa, NA MESMA ORDEM de options. Para
#                  as erradas, explicam por que estão erradas; para a certa,
#                  explicam por que está certa. Quando o jogador erra, o alerta
#                  mostra a explicação da que ele escolheu e a da correta (ver
#                  wrong_answer_feedback).
#
# Escritas à mão, uma a uma: ao editar uma alternativa, revise a explicação do
# mesmo índice. tests/test_park_quiz_data.gd confere a estrutura, o tamanho das
# alternativas e a distribuição do gabarito.
static func _bank() -> Dictionary:
	return {
		1: [
			{
				"question": "Marina recebeu o pagamento da semana. Na mesa estão duas opções: reabastecer a geladeira com comida ou comprar um fone de ouvido novo que está em promoção. O dinheiro só cobre uma delas sem faltar no resto da semana. Qual escolha segue a regra de priorizar necessidades?",
				"options": [
					"Comprar o fone agora, porque a promoção termina hoje",
					"Dividir o dinheiro igualmente entre as duas coisas",
					"Reabastecer a geladeira e deixar o fone para depois",
					"Escolher a opção mais barata, seja ela qual for",
				],
				"correct": 2,
				"explanations": [
					"Promoção não transforma um desejo em necessidade. O fone pode esperar ou voltar a ser vendido depois, mas a comida da semana não pode faltar.",
					"Dividir ao meio faria faltar comida e ainda não pagaria o fone inteiro. Quando o dinheiro cobre só uma coisa, a necessidade vem primeiro, sem meio-termo.",
					"Certo. Comida é necessidade: sem ela a semana inteira fica comprometida. O fone é desejo e pode esperar o próximo pagamento ou uma sobra do orçamento.",
					"O preço não define a prioridade. Uma opção barata pode ser um desejo, e uma necessidade pode custar mais. O critério é o que você precisa para viver bem.",
				],
			},
			{
				"question": "Carlos precisa cortar um gasto do orçamento deste mês sem prejudicar sua rotina. Ele olhou a lista de despesas e quer eliminar apenas o que é desejo, mantendo as necessidades. Qual item da lista ele pode cortar?",
				"options": [
					"A assinatura de um segundo serviço de streaming",
					"A passagem do ônibus que o leva ao trabalho",
					"A parcela do aluguel da casa onde ele mora",
					"O remédio de uso contínuo prescrito pelo médico",
				],
				"correct": 0,
				"explanations": [
					"Certo. Um segundo streaming é conforto, não necessidade: viver, trabalhar e se manter saudável não dependem dele, então cortar não prejudica a rotina.",
					"O ônibus é como ele chega ao trabalho, que gera sua renda. Cortar esse gasto atrapalharia o próprio ganho de dinheiro, então é necessidade.",
					"Moradia é uma necessidade básica. Cortar o aluguel significaria ficar sem casa, e isso não é economia: é um problema maior.",
					"Remédio de uso contínuo protege a saúde e é necessidade. Cortá-lo pode gerar gastos médicos bem maiores depois.",
				],
			},
			{
				"question": "Ana ganha R$ 800 por semana e sempre chega na quinta-feira sem dinheiro, sem saber onde gastou. A amiga Júlia sugere que Ana anote quanto vai destinar a cada gasto antes de gastar. Qual é o principal benefício dessa prática?",
				"options": [
					"Fazer o dinheiro render mais sem guardar nada",
					"Eliminar todos os gastos que Ana considera chatos",
					"Garantir que o salário aumente no mês seguinte",
					"Saber quanto sobra para cada gasto da semana",
				],
				"correct": 3,
				"explanations": [
					"Planejar não faz o dinheiro render sozinho: rendimento vem de investir. Planejar mostra para onde o dinheiro vai, e isso exige guardar uma parte de propósito.",
					"O plano não elimina gastos por serem chatos; ele distribui o dinheiro entre eles. Gastos necessários continuam existindo, só ficam dentro de um limite.",
					"O salário depende do trabalho e da formação, não de anotar gastos. Planejar controla o que já entra, sem mudar o valor recebido.",
					"Certo. Ao definir antes quanto cada gasto pode custar, Ana enxerga o que sobra para o resto da semana e evita chegar na quinta sem dinheiro.",
				],
			},
			{
				"question": "Rafael recebe R$ 500 por semana. Neste período ele já separou R$ 200 para o mercado e R$ 100 para o transporte, e quer saber quanto sobra para o resto das despesas e para guardar. Qual é esse valor?",
				"options": [
					"Sobram R$ 100 na semana",
					"Sobram R$ 200 na semana",
					"Sobram R$ 300 na semana",
					"Sobram R$ 500 na semana",
				],
				"correct": 1,
				"explanations": [
					"R$ 100 seria a sobra se ele tivesse gasto R$ 400. Mas os gastos são R$ 200 + R$ 100 = R$ 300, e R$ 500 − R$ 300 não dá 100.",
					"Certo. Os gastos somam R$ 200 + R$ 100 = R$ 300, e R$ 500 − R$ 300 = R$ 200 sobram para as demais despesas e para guardar.",
					"R$ 300 é o total gasto, não a sobra. A sobra é o que resta depois de tirar esse total do salário: R$ 500 − R$ 300.",
					"R$ 500 é tudo o que ele recebeu. Se sobrasse tudo, ele não teria gasto nada, mas R$ 300 já estão comprometidos com mercado e transporte.",
				],
			},
			{
				"question": "Beatriz recebe o salário do mês inteiro de uma vez e costuma ficar sem dinheiro na segunda semana. Um colega sugere dividir o valor em quatro partes iguais, uma por semana. Qual vantagem essa divisão traz para Beatriz?",
				"options": [
					"Faz o salário do mês aumentar naturalmente",
					"Dispensa Beatriz de anotar qualquer gasto do mês",
					"Evita gastar quase tudo logo nos primeiros dias",
					"Obriga Beatriz a gastar o valor semanal inteiro",
				],
				"correct": 2,
				"explanations": [
					"Dividir o salário não muda o quanto Beatriz recebe no mês: o total continua o mesmo. O que muda é a forma de distribuir esse valor ao longo das semanas.",
					"O orçamento semanal exige acompanhar os gastos, não dispensar. Sem anotar, Beatriz não saberia se está respeitando o limite de cada semana.",
					"Certo. Com um limite por semana, o dinheiro do mês não some nos primeiros dias, e Beatriz chega à última semana ainda com recursos.",
					"O limite semanal é um teto, não uma obrigação de gastar. O que sobrar de uma semana pode ser guardado ou usado na seguinte.",
				],
			},
			{
				"question": "Pedro recebeu R$ 400 de mesada para o mês todo e quer fazê-los durar quatro semanas, gastando o mesmo valor em cada uma. Ao montar o orçamento, quanto ele deve separar para cada semana?",
				"options": [
					"Separar R$ 100 por semana",
					"Separar R$ 50 por semana",
					"Separar R$ 150 por semana",
					"Separar R$ 400 por semana",
				],
				"correct": 0,
				"explanations": [
					"Certo. R$ 400 divididos por 4 semanas dá R$ 100 por semana, e quatro semanas de R$ 100 voltam a somar os R$ 400 da mesada.",
					"R$ 50 por semana rende só R$ 200 em quatro semanas. Sobrariam R$ 200 que Pedro não planejou usar, metade da mesada.",
					"R$ 150 por semana somaria R$ 600 em quatro semanas, mais do que os R$ 400 que Pedro tem. O dinheiro acabaria na terceira semana.",
					"R$ 400 é o valor do mês inteiro. Gastar isso em uma semana deixaria Pedro sem nada nas outras três.",
				],
			},
			{
				"question": "Lúcia acha que guardar R$ 5 por semana não vale a pena, já que é pouco. O irmão dela discorda e diz que o hábito, mesmo com valores pequenos, traz resultados. Quem tem razão, e por quê?",
				"options": [
					"Lúcia, porque valores pequenos nunca chegam a somar algo relevante",
					"Lúcia, porque guardar só faz sentido com valores muito altos",
					"O irmão, porque guardar pouco impede qualquer gasto no futuro",
					"O irmão, porque o valor guardado cresce e traz segurança",
				],
				"correct": 3,
				"explanations": [
					"Valores pequenos somam sim: R$ 5 por semana viram R$ 260 em um ano, sem contar o hábito criado. Dizer que nunca somam ignora a regularidade.",
					"Guardar não depende de valores altos. O hábito pesa mais que o tamanho do depósito, e quem espera ter muito para começar costuma nunca começar.",
					"Guardar pouco não impede gastos futuros: o dinheiro guardado pode ser usado quando necessário. A ideia é ter uma reserva, não ficar sem poder gastar.",
					"Certo. Guardar com regularidade, mesmo pouco, faz o total crescer e dá segurança para imprevistos, além de criar o hábito de poupar.",
				],
			},
			{
				"question": "Davi guarda R$ 10 toda semana, sem falhar, para comprar uma bicicleta usada de R$ 100. Ele não conta nenhum rendimento sobre o valor guardado. Depois de 10 semanas, quanto Davi terá guardado?",
				"options": [
					"Terá R$ 10 guardados",
					"Terá R$ 50 guardados",
					"Terá R$ 100 guardados",
					"Terá R$ 1000 guardados",
				],
				"correct": 2,
				"explanations": [
					"R$ 10 é só o valor de uma semana. Davi repete o depósito dez vezes, então precisa multiplicar, não parar no primeiro depósito.",
					"R$ 50 seria o total de apenas cinco semanas. Com 10 semanas, são mais cinco depósitos de R$ 10, chegando ao dobro disso.",
					"Certo. 10 semanas × R$ 10 = R$ 100, exatamente o preço da bicicleta, sem precisar de rendimento nenhum.",
					"R$ 1000 exigiria guardar R$ 100 por semana. Davi guarda R$ 10, então 10 × R$ 10 = R$ 100, dez vezes menos que o valor escolhido.",
				],
			},
		],
		2: [
			{
				"question": "O notebook de Camila, que ela usa para trabalhar, quebrou numa segunda-feira e o conserto custa R$ 400, valor que ela não tinha previsto. Camila mantém uma reserva de emergência guardada. Para que essa reserva serve numa situação como essa?",
				"options": [
					"Pagar uma viagem de férias com as amigas",
					"Cobrir o conserto sem desorganizar o resto do orçamento",
					"Comprar ações de empresas que estão em alta",
					"Gastar com lazer sempre que sobrar vontade",
				],
				"correct": 1,
				"explanations": [
					"Uma viagem é um gasto de lazer planejável, não um imprevisto. Usar a reserva nisso a esvazia justamente antes de uma emergência de verdade.",
					"Certo. É exatamente para imprevistos como o conserto do notebook que a reserva existe: Camila paga sem atrasar contas nem pegar empréstimo.",
					"Ações oscilam e podem perder valor. A reserva precisa estar segura e disponível na hora da emergência, o que um investimento arriscado não garante.",
					"Lazer é desejo e deve sair do orçamento normal. Se a reserva paga o lazer, ela some e Camila volta a ficar exposta a imprevistos.",
				],
			},
			{
				"question": "Rodrigo tem R$ 1.500 na reserva de emergência. No mesmo mês surgiram quatro ideias para usar o dinheiro, e uma delas é uma consulta urgente com exames que o plano de saúde não cobre. Qual uso respeita a finalidade da reserva?",
				"options": [
					"Trocar de celular porque o modelo ficou antigo",
					"Comprar roupas novas para uma festa de família",
					"Reservar uma viagem de fim de semana na praia",
					"Pagar a consulta urgente e os exames necessários",
				],
				"correct": 3,
				"explanations": [
					"Trocar de celular por estar antigo é desejo: o aparelho atual ainda funciona. Reserva é para o que não dá para adiar nem prever.",
					"Roupa para festa é gasto planejável e adiável. Gastar a reserva nisso a reduz e deixa Rodrigo desprotegido na próxima emergência.",
					"Viagem é lazer escolhido, não imprevisto. Dá para juntar esse valor separadamente, sem gastar a proteção que a reserva representa.",
					"Certo. Saúde urgente é imprevisto que não pode esperar, exatamente a situação para a qual a reserva foi criada.",
				],
			},
			{
				"question": "Fernanda separou no orçamento o aluguel, a luz e o mercado. No meio do mês, o carro dela quebrou e ela teve que pagar um conserto que ninguém esperava. Entre as descrições abaixo, qual define melhor esse tipo de gasto?",
				"options": [
					"Um gasto que aparece sem aviso no orçamento",
					"Um gasto planejado com meses de antecedência",
					"Um investimento que rende todo mês sem risco",
					"Um bônus garantido pago pela empresa todo ano",
				],
				"correct": 0,
				"explanations": [
					"Certo. Imprevisto é o gasto que surge sem aviso e fora do orçamento, como o conserto do carro de Fernanda.",
					"Gasto planejado é o contrário de imprevisto: ele entra no orçamento com antecedência. O conserto do carro não estava no plano de Fernanda.",
					"Investimento é dinheiro aplicado para render, não um gasto que aparece de surpresa. O conserto saiu do bolso e não rende nada.",
					"Bônus é dinheiro que entra, e um bônus garantido nem seria surpresa. O conserto é uma saída de dinheiro inesperada.",
				],
			},
			{
				"question": "Lucas e Marta ganham o mesmo salário. Lucas não tem reserva de emergência; Marta tem. Ambos enfrentam uma despesa médica inesperada de R$ 600 no meio do mês. O que tende a acontecer com Lucas?",
				"options": [
					"O problema se resolve sozinho com o tempo",
					"As finanças dele não sofrem efeito relevante",
					"Ele atrasa contas ou pega dinheiro emprestado",
					"Ele passa a economizar mais do que Marta",
				],
				"correct": 2,
				"explanations": [
					"Despesa não paga não desaparece. Sem dinheiro guardado, ela continua ali e ainda pode crescer com multas e juros se Lucas atrasar.",
					"Uma despesa de R$ 600 sem reserva pesa bastante. Lucas precisa tirá-la de contas já planejadas, então as finanças sofrem sim.",
					"Certo. Sem reserva, Lucas precisa atrasar contas ou pegar emprestado, e isso gera dívida, enquanto Marta paga com o dinheiro guardado.",
					"Sem reserva, Lucas fica apertado e tende a economizar menos. Já Marta paga com a reserva e segue o plano normal.",
				],
			},
			{
				"question": "No jogo, você abre o banco e vê o aviso 'Problema no carro: conta de R$ 500'. Seu dinheiro em mãos continua igual ao de antes do aviso. O que isso significa?",
				"options": [
					"O valor já foi descontado, mas a tela atrasou",
					"O evento foi cancelado automaticamente pelo próprio jogo",
					"Metade do saldo foi descontada como multa imediata",
					"A conta virou pendência no banco, com prazo definido",
				],
				"correct": 3,
				"explanations": [
					"O jogo não debita na hora: o evento só cria uma pendência. O dinheiro só sai quando você paga, ou na cobrança automática da data limite.",
					"Eventos não se cancelam sozinhos. A conta continua pendente no banco e, se você ignorar, ela cresce com juros e é cobrada à força.",
					"Não existe multa imediata sobre o saldo. O que existe são prazos: depois do vencimento a conta passa a acumular juros, mas nada é tirado na hora.",
					"Certo. O evento vira pendência no banco com vencimento e data limite. Pagar antes de vencer custa o valor original; atrasar traz juros.",
				],
			},
			{
				"question": "Depois de um evento inesperado no mapa, você quer pagar a conta ou resgatar um bônus. Onde fica a lista de contas e bônus pendentes que o jogo criou para você?",
				"options": [
					"Na escola, dentro do painel de aulas",
					"No banco, nas abas de eventos e contas",
					"No mercado, ao lado do carrinho de compras",
					"Na casa, dentro do painel do estoque",
				],
				"correct": 1,
				"explanations": [
					"A escola é onde você faz o minigame de formação e sobe de nível. Ela não guarda contas nem bônus de eventos.",
					"Certo. Pendências de eventos e contas da casa ficam no banco, onde você paga, resgata e acompanha vencimentos.",
					"O mercado serve para comprar comida e bebida. Contas e bônus não aparecem no carrinho, só os produtos escolhidos.",
					"A casa mostra seu estoque e as ações de descansar, assistir TV e dormir. As pendências financeiras ficam no banco, não lá.",
				],
			},
			{
				"question": "Paulo vai a uma loja e pode pagar um aparelho à vista por R$ 1.000 ou parcelado em 10 vezes de R$ 120. Ele tenta entender de onde vem a diferença no total pago. O que representa essa diferença?",
				"options": [
					"O custo de usar dinheiro ao longo do tempo",
					"Um desconto concedido por pagar em muitas parcelas",
					"Um imposto fixo que a loja sempre precisa recolher",
					"Uma reserva que a loja guarda para o cliente",
				],
				"correct": 0,
				"explanations": [
					"Certo. A diferença de R$ 200 (R$ 1.200 − R$ 1.000) são juros: o preço de usar o aparelho agora e pagar aos poucos.",
					"Pagar mais no total não é desconto. Desconto reduz o preço, e aqui o parcelado custa R$ 200 a mais que o à vista.",
					"Imposto já está embutido nos dois preços. A diferença entre à vista e parcelado vem do custo de parcelar, os juros.",
					"A loja não guarda reserva para o cliente. O valor extra fica com a loja como pagamento pelo prazo concedido.",
				],
			},
			{
				"question": "Sabrina pegou R$ 100 emprestados com uma financeira e, um mês depois, devolveu R$ 120. Ela quer calcular quanto pagou de juros nessa operação. Qual é o valor?",
				"options": [
					"Pagou R$ 0 de juros",
					"Pagou R$ 100 de juros",
					"Pagou R$ 20 de juros",
					"Pagou R$ 120 de juros",
				],
				"correct": 2,
				"explanations": [
					"Se não houvesse juros, Sabrina devolveria exatamente os R$ 100 emprestados. Como devolveu R$ 120, houve um custo extra pelo empréstimo.",
					"R$ 100 é o valor emprestado, o principal. Os juros são só o que ela pagou além disso: R$ 120 − R$ 100.",
					"Certo. Os juros são a diferença entre o que devolveu e o que pegou: R$ 120 − R$ 100 = R$ 20.",
					"R$ 120 é o total devolvido, que inclui os R$ 100 do empréstimo. Os juros são só a parte que passou do valor emprestado.",
				],
			},
		],
		3: [
			{
				"question": "Helena deixou R$ 10.000 na poupança durante um ano em que a inflação foi maior que o rendimento da conta. No fim do ano ela comparou o saldo com os preços das coisas. Qual é a principal desvantagem da poupança vista nesse caso?",
				"options": [
					"Ela cobra tarifas altas sobre todo o saldo",
					"Ela não oferece qualquer garantia ao investidor",
					"Ela só permite resgate depois de dez anos",
					"O rendimento baixo pode perder para a inflação",
				],
				"correct": 3,
				"explanations": [
					"A poupança não cobra tarifas sobre o saldo; o problema dela é o rendimento modesto, não custos. Isso não explica a perda que Helena percebeu.",
					"A poupança tem proteção: é garantida pelo FGC até certo valor. O risco para Helena foi outro, o rendimento ficar abaixo da inflação.",
					"Na poupança o resgate é possível a qualquer momento, sem prazo de dez anos. O que a prejudica é o rendimento baixo.",
					"Certo. Se o rendimento é menor que a inflação, o dinheiro cresce em reais mas compra menos coisas: Helena perde poder de compra.",
				],
			},
			{
				"question": "Gustavo nunca guardou dinheiro e quer começar com algo simples, sem precisar estudar produtos complicados. A irmã sugere uma opção segura que ele pode abrir com pouco dinheiro. Para esse perfil, a poupança é recomendada principalmente para quê?",
				"options": [
					"Multiplicar o patrimônio rapidamente com alto retorno",
					"Aprender o hábito de guardar dinheiro com segurança",
					"Investir como um investidor arrojado em busca de risco",
					"Evitar completamente qualquer necessidade de planejar o futuro",
				],
				"correct": 1,
				"explanations": [
					"A poupança rende pouco, então não multiplica patrimônio rápido. Quem busca alto retorno precisa olhar outras opções, aceitando mais risco.",
					"Certo. Segura e simples, a poupança ajuda quem está começando a criar o hábito de guardar, mesmo rendendo pouco.",
					"Investidor arrojado aceita risco para ganhar mais, e a poupança é conservadora. O perfil de Gustavo e o da poupança são o oposto disso.",
					"Poupar não dispensa planejamento. Guardar dinheiro faz parte do planejamento, e o futuro continua exigindo decisões.",
				],
			},
			{
				"question": "Isabela quer aplicar R$ 5.000 e saber desde o início quanto o dinheiro vai render até o vencimento, sem surpresas. Um gerente explica que esse tipo de investimento funciona como um empréstimo com juros combinados. O que caracteriza a renda fixa?",
				"options": [
					"Você nunca sabe se receberá algo de volta",
					"Há risco de perder todo o dinheiro investido",
					"A previsibilidade vem de juros combinados desde o início",
					"Só empresas de tecnologia podem emitir esses títulos",
				],
				"correct": 2,
				"explanations": [
					"Na renda fixa as regras são combinadas antes. Isabela sabe a taxa e o prazo, então não é verdade que nunca saberá se receberá algo.",
					"Perder todo o dinheiro é risco típico de investimentos variáveis. Na renda fixa o retorno é combinado, e o risco costuma ser bem menor.",
					"Certo. Na renda fixa a taxa de juros é combinada de início, e isso dá previsibilidade, como num empréstimo feito a quem emite o título.",
					"Quem emite renda fixa vai de governo a bancos e empresas de vários setores. Não é exclusividade de empresas de tecnologia.",
				],
			},
			{
				"question": "Bruno comprou um título do Tesouro Direto e quer entender para quem está emprestando o seu dinheiro. Ele sabe que o título tem rendimento definido e baixo risco. Quem recebe esse empréstimo?",
				"options": [
					"O Governo, que financia obras e serviços públicos",
					"Uma empresa estrangeira indicada pela própria corretora",
					"Um amigo próximo que pediu dinheiro emprestado",
					"Uma casa de apostas ligada à corretora",
				],
				"correct": 0,
				"explanations": [
					"Certo. No Tesouro Direto você empresta ao Governo federal, que usa o dinheiro para financiar obras e serviços públicos e depois devolve com juros.",
					"O Tesouro Direto não envolve empresa estrangeira. A corretora só intermedeia a compra, e quem emite o título é o Governo.",
					"Amigos não participam do Tesouro Direto. É um programa do Governo, com regras, prazos e rendimentos definidos para cada título.",
					"Casas de apostas não têm relação com o Tesouro. Título público é dívida do Governo, bem diferente de jogo de azar.",
				],
			},
			{
				"question": "Marina aplicou R$ 1.000 a 10% ao ano. Depois do primeiro ano, em vez de retirar os R$ 100 de juros, deixou tudo aplicado. No segundo ano, o rendimento foi calculado sobre R$ 1.100. Como se chama esse mecanismo?",
				"options": [
					"Juros simples, calculados só sobre o valor inicial",
					"Juros compostos, calculados também sobre os juros acumulados",
					"Uma taxa fixa que nunca muda com o tempo",
					"Um desconto pago ao comprar sempre à vista",
				],
				"correct": 1,
				"explanations": [
					"Juros simples incidem só sobre os R$ 1.000 iniciais, dando R$ 100 todo ano. Aqui o segundo ano rendeu sobre R$ 1.100, então não são simples.",
					"Certo. Juros compostos incidem sobre o capital e sobre os juros já acumulados: no segundo ano Marina ganhou 10% de R$ 1.100, ou R$ 110.",
					"A taxa de 10% é fixa, mas o que o enunciado descreve é o cálculo sobre o valor crescente. Isso é juros compostos, não só taxa fixa.",
					"Desconto na compra à vista não tem relação com rendimento de aplicação. Aqui o dinheiro está rendendo, não comprando algo.",
				],
			},
			{
				"question": "Dois amigos aplicam por 30 anos: Tiago retira todo mês os juros recebidos, e Lívia deixa tudo reinvestido. Ao final, Lívia tem muito mais do que Tiago. Por que os juros compostos são chamados de 'bola de neve' no longo prazo?",
				"options": [
					"Porque derretem com o calor e perdem valor",
					"Porque só funcionam em países de clima frio",
					"Porque impedem que o dinheiro cresça com o tempo",
					"Porque o rendimento acumulado passa a crescer cada vez mais",
				],
				"correct": 3,
				"explanations": [
					"O nome é uma metáfora de crescimento, não de temperatura. Juros compostos não derretem: quanto mais tempo, maior o valor acumulado.",
					"Clima não influencia juros. A comparação com a neve vem de a bola crescer ao rolar, e vale para qualquer economia.",
					"É o contrário: os juros compostos aceleram o crescimento. Lívia reinvestiu e por isso acumulou mais que Tiago.",
					"Certo. Como os juros passam a render juros, o crescimento acelera, igual a uma bola de neve que aumenta a cada volta.",
				],
			},
			{
				"question": "Leandro guardou R$ 100 no colchão e, um ano depois, o pacote de arroz que custava R$ 20 passou a custar R$ 25. Ele ainda tem os mesmos R$ 100. O que a alta da inflação provocou no dinheiro dele?",
				"options": [
					"Reduziu o poder de compra com a mesma quantia",
					"Aumentou o poder de compra das notas guardadas",
					"Dobrou automaticamente o valor das notas guardadas",
					"Zerou os juros da economia de uma vez",
				],
				"correct": 0,
				"explanations": [
					"Certo. Com R$ 100 ele comprava 5 pacotes e agora compra 4: a quantia é a mesma, mas o poder de compra caiu com a inflação.",
					"Inflação é alta de preços; com preços maiores, as notas compram menos, não mais. O poder de compra diminui, não aumenta.",
					"Notas não dobram de valor sozinhas. O valor de R$ 100 continua R$ 100, só que o que se compra com ele diminuiu.",
					"A inflação não zera juros. Ela corrói o ganho real: um investimento que rende menos que a inflação perde poder de compra.",
				],
			},
			{
				"question": "Priscila precisa de um investimento onde possa sacar o dinheiro no mesmo dia, sem perder rendimento, caso aconteça uma emergência. Ao conversar com o gerente, ele diz que a opção tem 'alta liquidez diária'. O que isso significa para ela?",
				"options": [
					"O investimento só rende durante o período diurno",
					"O dinheiro nunca pode ser resgatado antes do fim",
					"Ela pode resgatar o valor no mesmo dia, sem penalidade",
					"O investimento tem alto risco de perda de capital",
				],
				"correct": 2,
				"explanations": [
					"Liquidez não tem a ver com horário. 'Diária' quer dizer que o resgate está disponível todos os dias, não que o rendimento só ocorra de dia.",
					"É o oposto: liquidez alta é facilidade de resgatar. Um investimento que não pode ser sacado até o fim tem liquidez baixa.",
					"Certo. Alta liquidez diária significa transformar o investimento em dinheiro na conta no mesmo dia, sem perder valor, ideal para emergências.",
					"Liquidez e risco são conceitos diferentes. Um investimento pode ter risco baixo e liquidez alta, ou o contrário; liquidez é só a rapidez do resgate.",
				],
			},
		],
		4: [
			{
				"question": "Carla comprou 10 ações de uma empresa de supermercados na Bolsa. Um amigo diz que agora ela é 'sócia' da empresa, ainda que em proporção pequena. O que uma ação representa?",
				"options": [
					"Uma pequena fração do capital social de uma empresa",
					"Uma dívida que a empresa tem com Carla",
					"Um empréstimo com juros fixos garantidos pelo Governo",
					"Um imposto obrigatório cobrado de todo investidor",
				],
				"correct": 0,
				"explanations": [
					"Certo. Ação é uma pequena parte do capital social: Carla vira sócia e acompanha os resultados da empresa, para o bem ou para o mal.",
					"Quem tem dívida com Carla seria um devedor, e ações não funcionam assim. Carla é sócia, não credora: o retorno depende dos lucros.",
					"Empréstimo com juros fixos descreve a renda fixa, como o Tesouro. Ação não tem retorno garantido nem garantia do Governo.",
					"Imposto é cobrado por lei e não rende nada. Ação é um ativo que Carla escolhe comprar, e pode lhe trazer ganhos.",
				],
			},
			{
				"question": "Eduardo tem R$ 500 e quer receber uma renda mensal ligada a imóveis, mas não tem dinheiro para comprar um prédio inteiro. Um amigo recomenda uma opção que reúne o dinheiro de vários investidores. O que são os Fundos Imobiliários (FIIs)?",
				"options": [
					"Empréstimos de bancos usados para construir obras",
					"Um tipo de poupança criada para estudantes jovens",
					"Forma acessível de investir em imóveis e receber aluguéis",
					"Impostos cobrados sobre terrenos em áreas urbanas",
				],
				"correct": 2,
				"explanations": [
					"Empréstimo para obras é crédito bancário, não FII. Os fundos reúnem investidores para comprar imóveis e dividir os resultados.",
					"Poupança de estudante não existe com esse nome nem finalidade. FII é um investimento em imóveis, não uma conta de poupança.",
					"Certo. Com FIIs, Eduardo compra cotas, entra no negócio de imóveis com pouco dinheiro e recebe uma parte dos aluguéis.",
					"Imposto sobre terrenos é o IPTU, que o dono paga. FII é um investimento que rende, justo o contrário de um imposto.",
				],
			},
			{
				"question": "Duas amigas comparam investimentos. Ana quer ganhos muito maiores que os da poupança; Bia prefere dormir tranquila sem ver o saldo oscilar. O gerente diz que a escolha de cada uma obedece à relação entre risco e retorno. Qual é essa relação?",
				"options": [
					"Maior risco sempre significa menor chance de ganho",
					"Maior potencial de retorno costuma trazer maior risco",
					"Risco e retorno não têm qualquer ligação entre si",
					"Investimentos seguros sempre rendem mais que os arriscados",
				],
				"correct": 1,
				"explanations": [
					"Aceitar mais risco significa chance de ganhar mais, mas também de perder. Dizer que o risco reduz a chance de ganho inverte a relação.",
					"Certo. Retorno potencial alto costuma vir com risco alto: Ana pode ganhar mais, mas aceita oscilar; Bia escolhe segurança e rende menos.",
					"Há ligação direta: os mercados pagam mais a quem aceita incerteza. Ignorar isso leva a acreditar em lucro alto sem risco, quase sempre golpe.",
					"Opções seguras costumam render menos. Se rendessem mais, ninguém aceitaria o risco das arriscadas, e o mercado não funcionaria assim.",
				],
			},
			{
				"question": "Fábio colocou todas as economias em ações de uma única empresa de turismo. Quando uma crise afetou o setor, ele perdeu boa parte do capital. Um amigo investidor diz que a diversificação teria ajudado. Qual é a principal vantagem dela?",
				"options": [
					"Garantir lucro diário sem nenhum esforço do investidor",
					"Aumentar os custos de transação para ganhar mais",
					"Concentrar tudo no ativo mais arriscado do mercado",
					"Reduzir o risco espalhando o capital entre ativos diferentes",
				],
				"correct": 3,
				"explanations": [
					"Nenhuma estratégia garante lucro diário. A diversificação não elimina oscilações, só diminui o efeito que um único ativo ruim tem sobre o todo.",
					"Custos de transação não ajudam a ganhar mais. Eles diminuem o retorno, e diversificar não busca aumentá-los.",
					"Concentrar tudo em um ativo arriscado é o oposto de diversificar, e foi exatamente o erro de Fábio na crise do turismo.",
					"Certo. Espalhando o capital em ativos de setores diferentes, uma queda em um deles pesa menos e a carteira fica mais protegida.",
				],
			},
			{
				"question": "No jogo, você tem R$ 400 para investir nos fundos. Um colega coloca tudo no fundo de Hotéis, que paga mais, e você divide entre Hotéis, Recebíveis e Shopping. Depois de uma semana difícil para o setor de hotéis, os dois comparam o resultado. Por que dividir foi mais prudente?",
				"options": [
					"Porque fundos diferentes não podem ser comprados juntos",
					"Porque o banco obriga a comprar todos os fundos",
					"Porque uma queda em um setor pesa menos na carteira",
					"Porque investir em vários fundos reduz o imposto devido",
				],
				"correct": 2,
				"explanations": [
					"Não há restrição: dá para comprar vários fundos ao mesmo tempo, e o jogo estimula isso. A divisão foi uma escolha de proteção.",
					"O banco não obriga ninguém a comprar todos os fundos. Você escolhe quanto colocar em cada um, e foi isso que protegeu a carteira.",
					"Certo. Com o dinheiro dividido, a queda de Hotéis atingiu só uma parte do total, e os outros fundos amorteceram a perda.",
					"A quantidade de fundos não muda o imposto do jogo, que incide apenas sobre vendas no prejuízo. A proteção veio da diversificação.",
				],
			},
			{
				"question": "Rita possui cotas de um fundo imobiliário e, todo mês, recebe um valor na conta sem vender nenhuma cota. A corretora chama esse dinheiro de provento. O que são proventos e dividendos?",
				"options": [
					"Fatias do lucro distribuídas a acionistas e cotistas",
					"Taxas que o investidor precisa pagar todo mês",
					"Dívidas assumidas ao comprar ações ou cotas",
					"Multas cobradas por resgatar o investimento antes",
				],
				"correct": 0,
				"explanations": [
					"Certo. Proventos e dividendos são partes do lucro que empresas e fundos repassam a quem tem ações ou cotas, como Rita.",
					"Taxas saem do bolso do investidor; Rita recebeu dinheiro, não pagou. Proventos entram na conta, o contrário de uma cobrança mensal.",
					"Comprar ações ou cotas não gera dívida: é compra de participação. O valor que Rita recebe é um ganho, não algo que ela deve.",
					"Multa por resgate antecipado existe em alguns títulos, mas não é provento. Rita não resgatou nada: o dinheiro veio como ganho.",
				],
			},
			{
				"question": "Caio recebe R$ 200 de dividendos por mês. Um amigo gasta tudo; Caio usa o valor para comprar novas cotas todo mês. Depois de alguns anos, a carteira de Caio cresce bem mais. Por que reinvestir os proventos é uma estratégia tão poderosa?",
				"options": [
					"Porque dividendos perdem a validade se ficarem parados",
					"Porque o banco confisca valores que ficam na conta",
					"Porque comprar novas cotas reduz o valor das antigas",
					"Porque novas cotas geram mais proventos, acelerando o crescimento",
				],
				"correct": 3,
				"explanations": [
					"Dividendos não têm prazo de validade; o dinheiro é de Caio e fica disponível. O benefício de reinvestir vem do crescimento, não de evitar perdas.",
					"Bancos não confiscam saldo parado. Deixar o valor na conta não gera prejuízo, só deixa de aproveitar o efeito de acumular cotas.",
					"Comprar novas cotas não reduz o valor das antigas. O que acontece é Caio ter mais cotas e, portanto, receber mais proventos.",
					"Certo. As novas cotas também pagam proventos, que compram mais cotas ainda: é o efeito dos juros compostos aplicado aos dividendos.",
				],
			},
			{
				"question": "Sandro viu a cota de um fundo cair 12% em uma semana e, com medo, vendeu tudo. Dias depois o preço se recuperou. O colega dele comprou novas cotas justamente na alta, animado com a euforia do mercado. Qual erro de comportamento os dois cometeram?",
				"options": [
					"Manter a calma e focar apenas no longo prazo",
					"Vender por pânico na baixa e comprar por euforia",
					"Estudar o histórico do ativo antes de investir",
					"Diversificar a carteira entre setores diferentes e sólidos",
				],
				"correct": 1,
				"explanations": [
					"Manter a calma é o comportamento correto, não um erro. Quem foca no longo prazo evita decisões movidas por medo ou empolgação.",
					"Certo. Vender na queda trava o prejuízo, e comprar na euforia paga caro: seguir a manada faz o investidor errar o momento.",
					"Estudar o histórico é boa prática. Sandro e o colega erraram justamente por agir pela emoção, sem analisar o ativo.",
					"Diversificar protege a carteira e é boa prática. O erro dos dois foi agir por impulso diante da oscilação do preço.",
				],
			},
		],
		5: [
			{
				"question": "Tatiana tem exatamente R$ 1.000 e encontrou um restaurante à venda pelo mesmo valor. O vendedor diz que ela pode comprar hoje e começar a lucrar na semana seguinte. O que Tatiana deve garantir antes de fechar negócio?",
				"options": [
					"Nada, pois o preço de compra já basta",
					"Comprar outro negócio imediatamente depois do primeiro",
					"Dinheiro sobrando para operar sem depender do lucro",
					"Pagar somente o valor combinado com o dono anterior",
				],
				"correct": 2,
				"explanations": [
					"O preço de compra é só o começo: estoque, contas de água e luz e equipe começam a cobrar logo. Sem caixa extra, Tatiana trava na primeira semana.",
					"Comprar um segundo negócio dobraria despesas sem o primeiro estar de pé. É o oposto de garantir caixa: aumenta o risco.",
					"Certo. O negócio gera custos antes de o lucro se estabilizar. Ter dinheiro de sobra evita quebrar nas primeiras semanas.",
					"Pagar o dono anterior é a compra em si. Não resolve o que vem depois: estoque, contas e salários dependem de caixa.",
				],
			},
			{
				"question": "Em um dia de movimento, o restaurante de Otávio faturou R$ 400 e teve R$ 150 de despesas do dia. Ele quer saber quanto sobrou de lucro nesse dia. Qual é o cálculo correto?",
				"options": [
					"Somar a receita com as despesas do dia",
					"Considerar somente a receita total do dia",
					"Considerar somente as despesas totais do dia",
					"Subtrair as despesas da receita do dia",
				],
				"correct": 3,
				"explanations": [
					"Somar receita e despesas dá R$ 550, valor sem sentido como lucro. Despesas reduzem o que sobra, não aumentam.",
					"Receita é tudo o que entrou (R$ 400), sem descontar custos. Lucro é o que sobra depois de pagar as despesas.",
					"Despesas (R$ 150) são só o que saiu. Sozinhas não dizem quanto sobrou: é preciso compará-las com o que entrou.",
					"Certo. Lucro = receita − despesas: R$ 400 − R$ 150 = R$ 250 de lucro nesse dia.",
				],
			},
			{
				"question": "Na sexta-feira, Marcela esqueceu de repor o estoque de ingredientes do restaurante. Ela imagina que, sem ingredientes, nada funciona mais. O que realmente acontece com um negócio sem nenhum estoque?",
				"options": [
					"Continua com despesas, mas rende muito menos que antes",
					"Fecha as portas imediatamente até o próximo estoque",
					"Passa a render mais do que no dia anterior",
					"Nada muda, pois o estoque não afeta as vendas",
				],
				"correct": 0,
				"explanations": [
					"Certo. No jogo, o negócio sem estoque não fecha: continua pagando despesas, mas a receita cai bastante, o pior dos dois mundos.",
					"O negócio não fecha sozinho. Ele continua aberto e gastando, só que vendendo pouco, o que costuma ser até pior que fechar.",
					"Sem estoque não há o que vender, então a receita cai. Render mais seria o contrário do que acontece.",
					"O estoque afeta e muito: sem ele a receita despenca, enquanto as despesas seguem iguais. Repor estoque mantém o faturamento vivo.",
				],
			},
			{
				"question": "Léo avalia o restaurante numa semana ruim: quase não vendeu, mas as contas de água, luz e o salário do funcionário chegaram do mesmo jeito, enquanto a compra de ingredientes foi menor. Qual é a diferença entre custo fixo e custo variável?",
				"options": [
					"Não existe diferença prática relevante entre os dois custos",
					"O fixo chega sem vendas; o variável acompanha a operação",
					"O variável é sempre maior que o custo fixo",
					"O custo fixo só existe em negócios muito grandes",
				],
				"correct": 1,
				"explanations": [
					"A diferença é decisiva: o custo fixo pesa mesmo sem vender nada, e o variável cai quando a operação diminui. Foi o que Léo viu na semana ruim.",
					"Certo. Água, luz e salário são fixos e chegam de qualquer jeito; ingredientes são variáveis e diminuíram junto com as vendas.",
					"Não há regra de que o variável seja maior. Em semana fraca ele cai, e o fixo, que não muda, pode pesar mais.",
					"Custo fixo existe em qualquer negócio, até no menor: toda loja tem alguma conta que chega mesmo sem vender.",
				],
			},
			{
				"question": "Vânia não pagou a conta de luz do seu negócio no prazo e achou que ela ia sumir com o tempo. Na semana seguinte, notou que o faturamento caiu. O que acontece quando uma conta do negócio vence sem ser paga?",
				"options": [
					"A receita do negócio cai enquanto houver conta vencida",
					"A conta some sozinha depois de alguns dias",
					"O negócio fecha na hora e perde o estoque",
					"Você ganha um bônus por esperar mais tempo",
				],
				"correct": 0,
				"explanations": [
					"Certo. Enquanto houver conta vencida, a receita do negócio cai (no jogo, 25%). A conta não some e ainda acumula com as seguintes.",
					"Conta vencida não desaparece sozinha: continua pendente e se soma às contas da semana seguinte. Esperar só aumenta o problema.",
					"O negócio não fecha na hora nem perde o estoque. O castigo é a queda de receita enquanto a conta continuar vencida.",
					"Não existe bônus por atrasar. Atraso tem preço: a receita cai, e esperar mais só amplia o prejuízo.",
				],
			},
			{
				"question": "Gabriel pensa em comprar um fogão industrial por R$ 350 que aumenta o ganho líquido do restaurante em R$ 10 por dia. Ele quer saber em quanto tempo o equipamento se paga. O que é o 'payback'?",
				"options": [
					"O preço de compra do equipamento novo",
					"O imposto cobrado sobre qualquer equipamento comprado",
					"Em quantos dias o ganho paga o equipamento",
					"O prazo de garantia oferecido pelo fabricante",
				],
				"correct": 2,
				"explanations": [
					"O preço (R$ 350) é o investimento, não o payback. Payback mede quanto tempo leva para esse preço voltar em forma de ganho.",
					"Imposto é um custo da compra, não uma medida de retorno. Payback compara o ganho extra com o que foi gasto.",
					"Certo. Com ganho líquido de R$ 10 por dia, o fogão se paga em 350 ÷ 10 = 35 dias. Esse prazo é o payback.",
					"Garantia é o tempo de cobertura contra defeitos. Ela nada diz sobre quando o equipamento se paga, que é o que o payback mede.",
				],
			},
			{
				"question": "O restaurante de Helena atende no máximo 10 clientes por dia, mesmo quando mais gente aparece. Ela contrata um funcionário, e o limite sobe um pouco. O que representa a capacidade de um negócio?",
				"options": [
					"O lucro total que o negócio acumulou até hoje",
					"O teto de receita que a estrutura consegue atender",
					"O número de funcionários que já foram demitidos",
					"O preço pelo qual o negócio poderia ser vendido",
				],
				"correct": 1,
				"explanations": [
					"Lucro acumulado é o resultado passado. A capacidade é um limite atual da estrutura, que existe mesmo antes do primeiro lucro.",
					"Certo. Capacidade é o teto de receita que a estrutura atende: acima dele, os clientes extras não geram dinheiro novo.",
					"Demissões não medem capacidade. O que aumenta o limite são estrutura, equipamentos e funcionários contratados, não os desligados.",
					"O preço de venda depende de mercado e de resultados. Capacidade mede quanto o negócio consegue atender por dia.",
				],
			},
			{
				"question": "O restaurante de Rodrigo vende bem, e ele está pensando em contratar um funcionário, que custa um salário por semana. Antes de contratar, o que ele deve verificar?",
				"options": [
					"Se o negócio já está fechado há semanas",
					"Se não há nenhum cliente passando pela porta",
					"Se o funcionário aceita trabalhar de graça",
					"Se a receita atingiu o teto e há reserva",
				],
				"correct": 3,
				"explanations": [
					"Negócio fechado não precisa de funcionário. A decisão de contratar vem de um negócio funcionando e com demanda sobrando.",
					"Sem clientes não há o que atender, e um funcionário só traria mais custo fixo. Contratar faz sentido quando a demanda já supera a estrutura.",
					"Funcionário de graça não existe no jogo: o salário é semanal e chega com as outras contas. Esse custo precisa caber no caixa.",
					"Certo. Se a receita já está no teto, o funcionário aumenta a capacidade, e a reserva garante o pagamento do salário nas semanas fracas.",
				],
			},
		],
	}

# Semanas além da última com conteúdo (5) reaproveitam o banco da semana 5.
static func get_questions(week: int) -> Array:
	var bank = _bank()
	var clamped = clampi(week, 1, 5)
	return bank.get(clamped, [])

# Texto do alerta quando o jogador erra. Mostra por que a alternativa que ele
# escolheu está errada e qual era a certa (com o motivo), usando as explicações
# escritas à mão em cada pergunta.
static func wrong_answer_feedback(question: Dictionary, chosen: int) -> String:
	var options: Array = question.get("options", [])
	var explanations: Array = question.get("explanations", [])
	var correct := int(question.get("correct", -1))
	var text := "Resposta incorreta.\n\n%s\n\nA resposta certa era: %s\n%s" % [
		_item(explanations, chosen),
		_item(options, correct),
		_item(explanations, correct)
	]
	return text

# Índice fora do intervalo devolve vazio em vez de derrubar o alerta.
static func _item(list: Array, index: int) -> String:
	if index < 0 or index >= list.size():
		return ""
	return str(list[index])
