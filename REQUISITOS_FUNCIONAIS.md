# Especificação de Requisitos Funcionais (RF) — Mundo Financeiro

Este documento consolida a especificação completa de Requisitos Funcionais do jogo **Mundo Financeiro** (Godot 4). Os requisitos estão organizados por módulos de negócio e sistemas do jogo.

---

## 1. Gestão do Jogador, Estado e Personagens

- **RF001 - Seleção de Personagem**: O jogo deve permitir ao jogador escolher entre diferentes avatares/personagens disponíveis (ex.: Raul, Matheus, Phillip, Melissa, Enzo) ao iniciar uma nova partida.
- **RF002 - Inicialização de Saldo**: O jogo deve definir o saldo financeiro inicial do jogador com base no personagem selecionado e seus parâmetros de inicialização.
- **RF003 - Centralização do Estado**: Todas as propriedades vitais, financeiras e de progresso do jogador devem ser mantidas de forma reativa e centralizada em uma estrutura única (Global.player).
- **RF004 - Normalização de Estado**: O sistema deve garantir integridade e retrocompatibilidade de estado (ensure_player_state), criando chaves ausentes ou com tipos incompatíveis ao carregar ou iniciar jogos.
- **RF005 - Piso Mínimo de Dinheiro**: Deduções financeiras e penalidades não devem reduzir o dinheiro disponível abaixo de R$ 0,00 (max(0.0, saldo)).

---

## 2. Sistema de Tempo e Ciclo de Vida

- **RF006 - Passagem do Tempo**: O jogo deve simular a passagem de minutos, horas (00h a 23h), dias (1 a 5) e semanas progressivas.
- **RF007 - Controle de Fluxo Temporal**: O tempo deve avançar somente quando a flag de execução estiver ativa (Global.play_time), pausando durante a exibição de menus, alertas modais, cutscenes e transições.
- **RF008 - Pausa Fora do Mapa**: O relógio do jogo deve pausar a contagem de tempo quando o jogador estiver fora do mapa principal ou em cenas de interior que operem com tempo suspenso.
- **RF009 - Virada de Dia e Rotinas Noturnas**: Ao concluir 24 horas (ou ao acionar a ação de dormir), o sistema deve fechar o dia, processar a degradação de necessidades diárias, operações de empreendimentos e registrar estatísticas de gastos diários.
- **RF010 - Fechamento Semanal (Rollover)**: Ao final de 5 dias, o sistema deve executar a rotina de encerramento da semana:
  - Pagar proventos e dividendos de investimentos em FIIs;
  - Gerar as contas fixas da residência para a semana vencida;
  - Gerar despesas e contas dos empreendimentos ativos;
  - Acionar a validação semanal de missões do jogador.

---

## 3. Necessidades Vitais e Sobrevivência (Fome, Sede e Stamina)

- **RF011 - Medidores de Necessidade**: O jogador deve possuir três medidores independentes, variando de 0 a 100:
  - Fome (hunger);
  - Sede (	hirst);
  - Stamina/Energia (stamina).
- **RF012 - Decaimento Diário de Fome e Sede**: A fome e a sede devem decair a cada dia completado, com a sede decaindo a uma taxa mais rápida que a fome.
- **RF013 - Decaimento Contínuo de Stamina**: A stamina deve decair minuto a minuto ao longo do dia, consumindo 100% da carga em 16 horas de jogo (960 minutos de jogo).
- **RF014 - Aceleração Noturna de Stamina**: A taxa de consumo de stamina deve aumentar progressivamente após as 18h de jogo, dobrando a taxa a partir das 19h.
- **RF015 - Game Over por Fome ou Sede**: Se o medidor de fome ou o medidor de sede atingir 0, o sistema deve acionar o estado de *Game Over*, exibindo alerta modal explicativo e direcionando o jogador de volta ao menu principal.
- **RF016 - Esgotamento de Stamina Diurno**: Se a stamina atingir 0 antes das 18h, o jogo não deve aplicar Game Over imediato, mas deve exibir alerta avisando que o jogador está exausto e precisa descansar em casa.
- **RF017 - Penalidade da Meia-Noite (Madrugada Acordado)**: Se o jogador alcançar as 00h sem ter dormido em casa:
  - Deve ser teletransportado automaticamente para a residência;
  - Deve sofrer uma dedução financeira (custo de café/remédios de emergência de R$ 30,00);
  - Deve reiniciar o dia seguinte com stamina reduzida (50%).

---

## 4. Ambiente Doméstico (Casa)

- **RF018 - Navegação e Renderização do Avatar**: A cena da casa deve renderizar visualmente o personagem escolhido pelo jogador, com suas devidas escalas e compensações de alinhamento visual.
- **RF019 - Ação de Comer**: O jogador deve poder consumir itens do tipo alimento armazenados no estoque da casa, restaurando a fome (e recuperando proporcionalmente parcela da stamina).
- **RF020 - Ação de Beber**: O jogador deve poder consumir bebidas do estoque, restaurando o medidor de sede (e parcela de fome correspondente, se houver).
- **RF021 - Ação de Descansar / Assistir TV**: O jogador deve poder realizar ações de repouso leve na casa que consumam frações de tempo em troca de benefícios imediatos de humor/descanso, verificando o risco de zerar a fome.
- **RF022 - Ação de Dormir**: A ação de dormir deve estar disponível em horários apropriados para avançar o dia de forma controlada, restaurando a stamina para 100% e acionando o fechamento do dia.
- **RF023 - Histórico de Ações Domésticas**: A casa deve manter um registro visual das últimas ações realizadas (alimentação, repouso, consumo).
- **RF024 - Visualização de Estoque Residencial**: A interface da casa deve exibir a lista de suprimentos comprados disponíveis para consumo, com suas respectivas quantidades e atributos restauradores.

---

## 5. Mercado e Carrinho de Compras

- **RF025 - Catálogo Categorizado**: O mercado deve exibir produtos divididos em categorias (Alimentos, Bebidas, Casa, Ferramentas, Eletrônicos), com preço unitário e descrição do efeito nas necessidades.
- **RF026 - Relação Custo-Benefício Real**: Os itens devem apresentar proporção financeira coerente (ex.: itens básicos como pão e água devem ter menor custo por ponto recuperado do que itens supérfluos).
- **RF027 - Carrinho de Compras Temporário**: Ao selecionar um produto, o item deve ser adicionado ao carrinho sem débito imediato de saldo.
- **RF028 - Manipulação do Carrinho**: O jogador deve poder remover itens individuais do carrinho ou esvaziar o carrinho por completo.
- **RF029 - Checkout com Validação de Saldo**: A compra só deve ser efetivada ao clicar em finalizar, validando se o saldo do jogador é suficiente para cobrir o total do carrinho.
- **RF030 - Aplicação de Cupom de Desconto**: Caso o jogador possua um cupom de desconto ativo (obtido no minigame do parque), o desconto percentual deve ser aplicado sobre o valor total do carrinho no checkout, consumindo o cupom em seguida.
- **RF031 - Entrega ao Estoque e Extrato**: Ao finalizar a compra, os produtos devem ser creditados no estoque da residência e o gasto deve ser registrado no histórico financeiro sob a categoria de mercado.

---

## 6. Sistema Bancário, Extratos e Contas

- **RF032 - Consulta de Extrato e Histórico de Gastos**: O banco deve listar todas as movimentações financeiras do jogador, categorizadas por tipo de despesa, dia e semana.
- **RF033 - Geração de Contas Fixas Domésticas**: Ao final de cada semana, o sistema deve gerar automaticamente as contas de consumo da residência (Água, Luz e Aluguel/Condomínio) com vencimento para a semana subsequente.
- **RF034 - Pagamento de Contas Domésticas**: O banco deve disponibilizar uma aba com as contas pendentes da residência, permitindo ao jogador quitá-las individualmente mediante saldo disponível.
- **RF035 - Histórico de Contas Quitadas**: As contas pagas devem ser arquivadas no histórico financeiro, impedindo duplicações de cobrança.

---

## 7. Eventos Inesperados (Imprevistos e Bônus)

- **RF036 - Sorteio Periódico de Eventos**: A partir da Semana 2, o sistema deve sortear eventos inesperados por intervalo de tempo ou na virada de semana.
- **RF037 - Não Débito Automático (Geração de Pendência)**: Eventos desfavoráveis (contas inesperadas, consertos) ou favoráveis (bônus, reembolsos) não devem alterar o saldo do jogador silenciosamente; devem gerar pendências registradas para resolução posterior no banco.
- **RF038 - Eventos com Escolha**: Quando o evento envolver uma tomada de decisão, deve exibir alerta modal com opções de escolha; a pendência gerada no banco deve corresponder exclusivamente à opção escolhida.
- **RF039 - Prevenção de Duplicação de Eventos**: O sistema deve impedir que o mesmo evento imprevisto seja acumulado repetidamente caso a pendência anterior idêntica ainda esteja em aberto.
- **RF040 - Quitação e Resgate no Banco**: O jogador deve poder quitar as pendências negativas ou resgatar bonificações pendentes diretamente pela interface bancária.

---

## 8. Mercado de Investimentos (FIIs)

- **RF041 - Catálogo de Fundos Imobiliários**: O sistema deve disponibilizar cotas de fundos (ex.: FII Shopping, FII Lajes Corporativas, FII Logística) com cotação, indicador de volatilidade e dividend yield semanal.
- **RF042 - Flutuação Diária de Preços**: A cotação dos fundos imobiliários deve oscilar a cada dia com base na volatilidade de cada ativo.
- **RF043 - Operação de Compra e Venda de Cotas**: O jogador deve poder adquirir e alienar cotas dos fundos disponíveis, respeitando o saldo em conta e a quantidade possuída.
- **RF044 - Pagamento de Dividendos**: Ao final de cada semana, o sistema deve creditar proventos proporcionais ao número de cotas e rendimento percentual de cada fundo diretamente na conta do jogador.
- **RF045 - Cálculo de Rentabilidade da Carteira**: O sistema deve calcular o valor total da carteira de investimentos e o lucro líquido acumulado (patrimônio + dividendos recebidos - valor aportado).
- **RF046 - Penalidade por Realização de Prejuízo**: Caso o jogador venda cotas de FII abaixo do preço médio de aquisição, deve ser cobrada taxa/imposto proporcional sobre o prejuízo realizado.

---

## 9. Sistema de Empreendimentos (Negócios)

- **RF047 - Catálogo de Empreendimentos**: O jogo deve disponibilizar 3 portes de negócio para aquisição:
  - Restaurante Pequeno (*Restaurante Sabor da Praça*);
  - Fliperama Médio (*Fliperama Neon*);
  - Centro Comercial Grande (*Centro Comercial Mundo Mix*).
- **RF048 - Proposta e Aquisição**: O jogador deve poder inspecionar a proposta de compra nas portas dos empreendimentos no mapa e comprá-los caso possua capital disponível.
- **RF049 - Interface Unificada de Gestão**: A gestão de qualquer empreendimento deve operar sob uma interface padrão em abas (Negócio, Estoque, Contas, Equipamentos) e cabeçalho de indicadores de desempenho.
- **RF050 - Gestão de Nível e Aprimoramento**: O jogador deve poder expandir o nível do empreendimento mediante pagamento dos custos de upgrade, destravando novos multiplicadores de receita e equipamentos avançados.
- **RF051 - Gestão de Funcionários e Folha de Pagamento**: O jogador deve poder contratar e demitir funcionários até o teto suportado pelo negócio, agregando bônus de capacidade/receita e gerando compromisso semanal de folha salarial.
- **RF052 - Aquisição de Equipamentos**: O jogador deve poder comprar equipamentos específicos do negócio que aumentem a capacidade e a receita diária, respeitando os requisitos de nível.
- **RF053 - Reposição de Estoque por Lote**: O jogador deve poder adquirir insumos operacionais em lotes fixos; o estoque deve ser consumido na operação diária para viabilizar o faturamento pleno.
- **RF054 - Operação e Lucro Diário**: Ao final de cada dia, o sistema deve processar a operação dos negócios ativos, apurando receita (limitada pelo teto de capacidade), deduzindo custos operacionais e creditando o lucro diário ao jogador.
- **RF055 - Contas Operacionais e Inadimplência**: Contas semanais de água, luz e folha devem ser emitidas para cada negócio. Caso vençam sem pagamento, o negócio deve entrar em situação de inadimplência, sofrendo penalidade de 25% na receita diária até que sejam quitadas.

---

## 10. Sistema de Missões e Conexão Educativa

- **RF056 - Missões Semanais Baseadas em Estado**: O jogo deve definir missões por semana que avaliem variáveis reais de estado (saldo mínimo, retenção de gastos, diversificação de carteira, resolução de pendências, posse de empreendimento).
- **RF057 - Verificação em Tempo Real no HUD**: O HUD deve exibir e atualizar em tempo real o status de cumprimento das missões correntes da semana via atalho ou painel de missões.
- **RF058 - Notificações de Conquista (Toasts)**: Ao completar o critério de uma missão durante a partida, o jogo deve emitir notificação visual temporária na tela.
- **RF059 - Validação Obrigatória de Virada de Semana**: Ao término do 5º dia da semana, o sistema deve avaliar se todas as metas foram cumpridas:
  - Se aprovado: concede bônus/salário semanal e avança para a semana seguinte;
  - Se reprovado: exibe alerta de reprovação e repete a semana atual para nova tentativa.

---

## 11. Conteúdo Educacional (Escritório)

- **RF060 - Navegação de Conteúdo Teórico**: O escritório deve disponibilizar módulos educativos estruturados em tópicos didáticos divididos por nível (Nível 1 a 5).
- **RF061 - Destravamento Progressivo por Semana**: Os tópicos e módulos educativos do escritório devem ser liberados gradualmente conforme a semana do jogador avança.
- **RF062 - Alinhamento Numérico Teoria-Prática**: Os valores, custos, taxas de retorno e regras de negócio ensinados nos textos educativos do escritório devem refletir com exatidão as fórmulas e tabelas de dados utilizadas na simulação prática do jogo.

---

## 12. Minigame da Escola (Progressão Profissional)

- **RF063 - Corrida de Obstáculos (Runner)**: O jogador deve poder entrar na escola e participar de uma corrida de salto e desvio de obstáculos com física lateral.
- **RF064 - Elevação de Nível Educacional / Salário**: Ultrapassar os checkpoints do percurso deve elevar o school_level do jogador (até o nível 5), incrementando permanentemente o salário semanal recebido.
- **RF065 - Formação Inicial Sem Limites**: Na primeira sessão de jogo na escola, o jogador deve poder progredir por quantos checkpoints conseguir até a primeira colisão com obstáculo.
- **RF066 - Travas e Cooldown da Escola**: Nas sessões seguintes, alcançar 1 checkpoint encerra a corrida e trava a escola até a semana seguinte; colidir com um obstáculo antes de pontuar deve aplicar um cooldown de 2 dias de jogo.
- **RF067 - Indicador de Acesso na Porta**: A porta da escola no mapa deve sinalizar claramente no painel se o acesso está liberado ou indicar a razão e o tempo restante do bloqueio.

---

## 13. Minigame do Parque (Caça-Moedas e Quiz)

- **RF068 - Atividade em Mapa Aberto**: O jogador deve poder acionar o minigame do parque interagindo com a zona demarcada do parque sem necessidade de carregar nova cena.
- **RF069 - Critérios de Acesso ao Parque**: A entrada no minigame deve exigir:
  - Horário de início anterior às 16h;
  - Fome, sede e stamina em nível seguro (todos ≥ 50%);
  - Limite máximo de 2 sessões por dia.
- **RF070 - Coleta de Moedas Temporizadas**: O jogo deve spawnar moedas sequenciais (uma por vez, vida útil de 10 segundos) dentro do polígono do parque durante uma rodada total de 120 segundos.
- **RF071 - Quiz Educativo Temático**: A cada 5 moedas coletadas (até 2 vezes por sessão), o jogo deve pausar a corrida e exibir pergunta de múltipla escolha baseada no conteúdo da semana atual.
- **RF072 - Recompensa por Acerto**: Responder corretamente à questão do quiz deve premiar o jogador com um cupom de 15% de desconto a ser aplicado no checkout do mercado.
- **RF073 - Saída Voluntária**: O jogador deve poder abandonar a sessão do parque antecipadamente por tecla de atalho dedicada (BACKSPACE), mantendo eventuais cupons obtidos.

---

## 14. Persistência de Dados e Gerenciamento de Saves

- **RF074 - Serialização Completa de Dados**: O sistema deve serializar e restaurar todo o estado do jogador (Global.player), incluindo posições, dinheiro, necessidades vitais, estoque da casa, históricos de despesas, carteira de investimentos, empreendimentos e cooldowns.
- **RF075 - Autosave Periódico**: O jogo deve salvar automaticamente o progresso do jogador em segundo plano em intervalos pré-determinados durante o gameplay ativo.
- **RF076 - Suporte a Múltiplos Slots de Save (5 Slots)**:
  - O sistema deve suportar até 5 slots de jogo independentes (save_1.json a save_5.json);
  - O jogador deve poder criar novas partidas sem sobrescrever slots ocupados existentes;
  - O jogador deve poder listar, selecionar e carregar qualquer um dos slots disponíveis;
  - O jogador deve poder excluir slots individuais mediante caixa de confirmação de exclusão;
  - Bloqueio de novos jogos quando os 5 slots estiverem preenchidos.
- **RF077 - Isolamento de Estado Entre Sessões e Slots**: Ao carregar um slot ou iniciar nova partida, o sistema deve resetar singletons e estados em memória (como carteiras de FIIs e cooldowns de minigames), impedindo contaminação de dados entre saves.
- **RF078 - Migração de Saves Legados**: O sistema deve detectar automaticamente saves legados de arquivo único (savegame.json) e migrá-los de forma transparente para o Slot 1.
- **RF079 - Tolerância a Falhas e Saves Corrompidos**: Arquivos de save malformados ou incompletos não devem travar a inicialização do jogo; devem ser sinalizados na interface de seleção permitindo apenas sua exclusão.

---

## 15. Interface do Usuário (HUD), Alertas e Transições

- **RF080 - HUD Principal do Personagem**: A tela do mundo deve exibir relógio em tempo real (dia, hora, semana), saldo de dinheiro e barras de progresso visuais com percentual das três necessidades (Fome, Sede, Stamina).
- **RF081 - Painéis Informativos de Portas no Mundo**: As portas e pontos de entrada de edifícios devem exibir painéis flutuantes no espaço de mundo indicando nome do local, descrição e comando de interação.
- **RF082 - Ocultação do HUD em Eventos Especiais**: O HUD geral do personagem deve ser ocultado automaticamente durante minigames (como a sessão do parque) ou telas em que UIs especializadas assumam a tela.
- **RF083 - Sistema de Alertas Modais em Fila**: Alertas importantes do jogo devem travar o gameplay de forma acumulativa, exibindo mensagens sequenciais em caixa de diálogo modal com confirmação exclusiva via barra de espaço ou botões de escolha.
- **RF084 - Sistema de Notificações Rápidas (Toasts)**: Avisos informativos secundários (ex.: conclusão de metas, avisos leves) devem aparecer no topo da tela sem pausar o jogo, desaparecendo automaticamente após alguns segundos.
- **RF085 - Transições Suaves entre Cenas**: Toda mudança de cenário deve ser intermediada por transição gradual de esmaecimento (fade-in / fade-out) via gerenciador centralizado (TransitionManager).
- **RF086 - Menu de Pausa e Retorno**: O jogador deve poder abrir o menu de pausa a qualquer momento durante a exploração com a tecla de cancelamento/ESC, permitindo retomar a partida ou retornar com segurança ao menu principal.
