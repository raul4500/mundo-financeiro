# Catálogo de Regras de Negócio (RN) — Mundo Financeiro

Este documento consolida as Regras de Negócio (RN) que regem o comportamento econômico, pedagógico, temporal e de sobrevivência do jogo **Mundo Financeiro**.

---

## 1. Regras de Sobrevivência e Necessidades Humanas

- **RN001 - Autonomia das Três Necessidades Vitais**:
  - O jogador possui três parâmetros vitais que operam independentemente: Fome (hunger), Sede (	hirst) e Stamina (stamina), com escala de 0 a 100 pontos.
- **RN002 - Condição de Game Over por Inanição ou Desidratação**:
  - Se o medidor de fome ou o medidor de sede atingir o valor zero (0), ocorre Game Over imediato. O jogador não perde o jogo por falta de dinheiro, mas perde por negligência com a saúde física.
- **RN003 - Prioridade e Velocidade de Consumo de Sede**:
  - A sede decai a uma taxa de 14 pontos por dia dormido, esgotando-se em aproximadamente 7 dias de jogo sem ingestão de líquidos.
  - A fome decai a uma taxa de 6 pontos por dia dormido, esgotando-se em aproximadamente 17 dias sem ingestão de alimentos.
- **RN004 - Orçamento Diurno de Stamina (16 Horas)**:
  - A stamina inicia em 100 pontos no início do dia e decai continuamente à taxa básica de aproximadamente 0,104 pontos por minuto de jogo, totalizando 100 pontos consumidos em exatamente 16 horas de atividade (960 minutos).
- **RN005 - Sobrecarga Noturna de Cansaço**:
  - Entre 18h e 19h o decaimento segue a taxa normal (1x).
  - A partir das 19h até as 23h59, a taxa de perda de stamina dobra (2x, 0,208 pontos/min) e se intensifica a cada hora adicional, forçando o retorno voluntário do jogador à residência.
- **RN006 - Penalidade da Meia-Noite (Privação de Sono)**:
  - Caso o jogador permaneça fora da residência até a meia-noite (00h00), o sistema encerra o dia forçadamente, teletransporta o personagem para casa, debita automaticamente **R$ 30,00** a título de custo com estimulantes/remédios e restaura a stamina inicial do dia seguinte para apenas 50%.
- **RN007 - Descanso Perfeito via Sono Domiciliar**:
  - Dormir na residência antes da meia-noite restaura a stamina para 100% sem custos adicionais. A ação de dormir só é autorizada caso o relógio marque horário de repouso apropriado (a partir das 18h ou quando a stamina estiver baixa).
- **RN008 - Efeito Bidirecional de Alimentos e Bebidas**:
  - Alimentos recuperam prioritariamente a fome, mas comidas nutritivas restauram adicionalmente 25% do seu valor em stamina (STAMINA_PER_FOOD_ENERGY).
  - Bebidas recuperam prioritariamente a sede, e bebidas encorpadas (ex.: achocolatados, leites) fornecem recuperação residual de fome.
- **RN009 - Relação Econômica de Custo por Ponto de Necessidade**:
  - No mercado, bens essenciais e simples devem possuir o menor custo por ponto de atributo restaurado (ex.: Água a R$ 0,20 por ponto de sede vs. Vinho a R$ 15,00 por ponto), ensinando o conceito prático de "Necessidade versus Desejo".

---

## 2. Regras de Economia, Gastos e Contas Fixas

- **RN010 - Bloqueio de Saldo Negativo (Proteção contra Dívida Infinita)**:
  - Nenhuma cobrança administrativa, penalidade temporal ou compra pode forçar o saldo financeiro em mãos (Global.player["money"]) a valores inferiores a R$ 0,00.
- **RN011 - Contas Semanais Obrigatórias da Casa**:
  - Ao final de cada ciclo semanal completo, são emitidas as contas fixas da residência relativas à semana encerrada:
    - Conta de Água: R$ 30,00;
    - Conta de Energia Elétrica: R$ 45,00;
    - Aluguel / Condomínio: R$ 75,00.
- **RN012 - Prazos de Vencimento de Contas**:
  - Toda conta doméstica ou empresarial gerada na semana W recebe vencimento para a semana seguinte (due_week = W + 1), concedendo 7 dias completos para pagamento sem sanções imediatas.
- **RN013 - Quitação Proativa via Sistema Bancário**:
  - As contas domésticas e despesas inesperadas nunca são debitadas diretamente na conta corrente no ato do vencimento; exigem que o jogador compareça à instituição bancária e autorize manualmente o pagamento com saldo suficiente.
- **RN014 - Extrato Financeiro e Classificação de Despesas**:
  - Todo desembolso financeiro deve ser classificado em categorias contábeis padronizadas (ood, drink, house_bill, enterprise_bill, investment, unexpected_event), registrando carimbo de dia e semana para consulta no banco.

---

## 3. Regras de Imprevistos e Eventos Financeiros

- **RN015 - Carência Inicial para Imprevistos**:
  - O sorteio de eventos inesperados só é habilitado a partir da **Semana 2**, assegurando que o jogador domine a mecânica básica de sobrevivência e fluxo de caixa na primeira semana.
- **RN016 - Impossibilidade de Duplicidade de Pendências Ativas**:
  - Um novo evento imprevisto sorteado não pode ser instaurado se já existir uma pendência aberta não resolvida originada da mesma fonte (source_id).
- **RN017 - Vinculação Irrevogável de Escolhas em Eventos**:
  - Em eventos que oferecem tomada de decisão (ex.: conserto imediato vs. reparo paliativo), a opção escolhida pelo jogador gera imediatamente o compromisso financeiro correspondente; fechar o jogo ou cancelar não anula a opção registrada.

---

## 4. Regras de Investimentos em Fundos Imobiliários (FIIs)

- **RN018 - Liquidação e Compra Fracionária**:
  - O jogador pode adquirir cotas de FIIs disponíveis desde que possua saldo integral em conta para liquidar a quantidade solicitada multiplicada pela cotação do momento.
- **RN019 - Volatilidade e Oscilação Diária de Mercado**:
  - Os preços das cotas sofrem flutuação diária percentual com base no fator de volatilidade de cada classe de fundo ao final de cada dia de jogo.
- **RN020 - Proventos e Pagamento Semanal de Dividendos**:
  - Ao término de cada semana de 7 dias, o jogador recebe dividendos líquidos calculados por:  
    \text{Provento} = \text{Cotação Atual} \times \text{Dividend Yield} \times \text{Quantidade de Cotas}
- **RN021 - Apuração de Rentabilidade Real da Carteira**:
  - O lucro contábil auferido em investimentos corresponde exclusivamente à soma do valor de mercado da carteira atual mais os dividendos históricos recebidos, subtraindo-se o total histórico aportado.
- **RN022 - Penalidade Tributária por Venda com Prejuízo**:
  - Alienar cotas de FII com valor inferior ao preço médio de aquisição acarreta retenção punitiva de 10% sobre o prejuízo apurado, ensinando os riscos da venda no pânico de mercado.

---

## 5. Regras de Empreendimentos e Gestão de Negócios

- **RN023 - Hierarquia e Faixas de Capital dos Empreendimentos**:
  - Os negócios são divididos em três faixas de maturidade:
    - *Restaurante Pequeno*: Preço R$ 1.500,00 (Nível inicial);
    - *Fliperama Médio*: Preço R$ 12.000,00 (Nível intermediário);
    - *Centro Comercial Grande*: Preço R$ 85.000,00 (Nível avançado).
- **RN024 - Aprimoramento e Trava de Nível**:
  - Um empreendimento só pode adquirir equipamentos avançados se o nível de modernização do estabelecimento for igual ou superior ao level_required do equipamento. O nível do negócio é expandido mediante pagamento fixo de reforma.
- **RN025 - Custo Fixo de Folha de Pagamento**:
  - Funcionários contratados não cobram taxa de admissão imediata; o salário acordado é lançado cumulativamente como conta semanal fixa de folha salarial (payroll_<semana>) na virada de semana.
- **RN026 - Teto de Receita por Capacidade Operacional**:
  - O faturamento diário máximo de um negócio é rigorosamente delimitado pela capacidade física:  
    \text{Teto de Receita} = \text{Capacidade Total} \times \text{Receita por Capacidade}  
    Ganhos potenciais que ultrapassem a capacidade física instalada são perdidos por gargalo de atendimento.
- **RN027 - Dependência Operacional de Estoque**:
  - A cada dia de operação, o negócio consome unidades de estoque. Caso o estoque esteja zerado, o negócio opera com faturamento severamente deprimido (queda para 35% do faturamento potencial).
- **RN028 - Penalidade Severa por Inadimplência Operacional**:
  - Se qualquer conta semanal do empreendimento (água, luz ou folha de pagamento) ultrapassar o prazo de vencimento (due_week), o negócio entra em estado de inadimplência, sofrendo retenção punitiva de **25% de desconto em toda a receita diária** até que todas as contas vencidas sejam quitadas.

---

## 6. Regras de Progressão Educacional e Minigames

- **RN029 - Progressão Salarial por Grau de Instrução (Escola)**:
  - O nível de escolaridade (school_level) varia de 1 a 5, elevando de forma definitiva o salário semanal do jogador recebido na virada de semana.
- **RN030 - Regra da Primeira Corrida Escolar**:
  - Na primeiríssima corrida na escola (sessions_played == 0), não há limite de níveis: o jogador progride por quantos checkpoints conseguir até colidir. Nas tentativas subsequentes, cada corrida permite avançar no máximo 1 nível e encerra a sessão.
- **RN031 - Cooldown e Travas da Escola**:
  - Subir de nível encerra a atividade na escola até a semana seguinte. Colidir sem atingir checkpoint impõe carência punitiva de **2 dias completos de jogo** antes de nova tentativa.
- **RN032 - Critérios de Aptidão para o Parque**:
  - O minigame do parque exige que o personagem esteja saudável: todas as necessidades (fome, sede, stamina) devem estar em **pelo menos 50%**, o horário deve ser **anterior às 16h**, e há um limite de **2 sessões por dia**.
- **RN033 - Quiz e Recompensa do Parque**:
  - Durante os 120 segundos de caça-moedas no parque, a cada 5 moedas coletadas o jogo apresenta um quiz com perguntas extraídas do conteúdo pedagógico da semana em curso.
  - Acertar a resposta concede um cupom de **15% de desconto** para a próxima compra no mercado; errar a resposta não aplica penalidade, mas não gera o bônus.

---

## 7. Regras de Missões e Conclusão de Semanas

- **RN034 - Validação Determinística de Metas Sem Anistia**:
  - Para avançar da Semana W para W+1, o jogador deve satisfazer simultaneamente todas as missões estipuladas para a respectiva semana na exata hora do fechamento semanal.
- **RN035 - Reprovação Educativa sem Morte do Jogo**:
  - Se o jogador não cumprir uma ou mais missões ao final do 7º dia, a semana é reiniciada para nova oportunidade de aprendizado econômico, mantendo o patrimônio e os negócios do jogador, resetando apenas os guards de operações diárias para que os rendimentos continuem funcionando.
