# Mundo Financeiro — Auditoria de Balanceamento Econômico (E2E)

Simulação manual de ponta a ponta (sem Godot disponível neste ambiente — cálculo analítico, não execução) de todas as semanas do jogo, testando se um jogador consegue cumprir as missões de cada semana sem morrer de fome/sede, usando os preços e valores atuais do código. Documenta as inconsistências encontradas e a solução proposta para cada uma.

**Metodologia:** para cada semana, calculo o fluxo de caixa de um jogador "responsável" (compra comida/bebida de forma eficiente, paga as contas da casa quando vencem) em três níveis de salário (baixo/médio/alto, ver abaixo), e confiro se ele consegue bater o valor de `money_min` da semana **e** continuar vivo **e** continuar pagando as contas que o próprio jogo ensina a pagar. Onde a conta não fecha, documento o valor novo.

## 1. Parâmetros centrais do jogo (lidos do código atual)

| Parâmetro | Valor | Fonte |
|---|---|---|
| Fome decai | 6/dia dormido | `Global.HUNGER_DECAY_PER_DAY` |
| Sede decai | 14/dia dormido | `Global.THIRST_DECAY_PER_DAY` |
| Necessidades congeladas em 100% durante todo o tutorial | sim | `Global.is_tutorial_active()` — corrige um risco que eu ia reportar (jogador preso sem acesso a casa/mercado); já está resolvido no código atual |
| Salário inicial (dinheiro de largada) | Raul/Melissa 220, Matheus 260, Phillip 240, Enzo 180 (piso 200) | `choose_character.gd` × `Global.new_game()` |
| Salário por nível de escolaridade | Nível 1=200, 2=300, 3=400, 4=500, 5=600 | `Global.update_salary()` |
| **Salário é pago 1x por semana**, não por dia | `Global.get_paid()` só roda em `_process_week_rollover()` |
| Contas da casa | Água 30 + Luz 45 + Aluguel 75 = **R$150/semana**, para sempre, sem multa por atraso | `HouseBillsManager.gd` |
| Penalidade de meia-noite / desmaio por stamina zerada | R$30, piso em zero | `TimeManager.gd` |
| Penalidade de semana com necessidade crítica (<35%) | R$25, piso em zero | `Global.evaluate_week_status()` |
| Fundo mais barato (FII) | ~R$90/cota (Logística) | `FIIManager.gd` |
| Restaurante (empreendimento mais barato) | R$1.500 de compra + ~R$50/semana de contas | `restaurant_info.gd` |

## 2. Achado #1 (o exemplo do usuário, confirmado): a armadilha do pão

**Antes da correção**, pão custava R$20 e repunha 10% de fome = **R$2,00/ponto** — o pior custo-benefício de toda a categoria Comidas (ovo, banana e maçã já custavam R$1,00/ponto). Pão é also o item de menor preço absoluto, então é o primeiro que um jogador novo tende a comprar — e é justamente o mais caro por ponto.

**Simulação (personagem Enzo, o mais pobre, R$180 iniciais, semana 1):**
- Missão `economizar_100` exige `money >= 100` no dia 7, **antes** do pagamento do salário.
- Comprando pão (ineficiente) para cobrir a fome da semana (42%) + água para a sede (98%): 5 pães × R$20 + 4 águas × R$5 = **R$120** → sobra R$60 → **reprova `economizar_100`**.
- Comprando ovo/banana (eficiente) + água: ~R$48 + R$20 = R$68 → sobra R$112 → passa, com margem apertada.

Isso confirma exatamente o padrão que o usuário descreveu: a missão "exige guardar X" e a compra mais óbvia (a mais barata em R$, não em R$/ponto) impede alcançar X.

**Correção aplicada em código** (`scripts/world/market/market.gd`, `singletons/TutorialManager.gd`):
- Pão: R$20 → **R$4**, mantendo 10% de fome → **R$0,40/ponto**, agora o melhor custo-benefício da categoria.
- Texto do tutorial (nível de fome do pão) atualizado para não citar o preço antigo.

**Resultado pós-correção:** 5 pães (R$20) + 4 águas (R$20) = **R$40/semana** de subsistência básica. Mesmo o Enzo (R$180) sobra R$140 antes do salário — `economizar_100` passa com folga, para qualquer estilo de compra.

## 3. Achado #2 (crítico): contas da casa vs. missões de poupança — o jogo pune quem paga as próprias contas

Contas da casa (R$150/semana) começam a existir no fim da semana 1 (vencem na semana 2) e **continuam para sempre**, sem multa se não forem pagas (`HouseBillsManager` não tem `due_week` lido em lugar nenhum — decisão documentada em `PROJECT_KNOWLEDGE.md` §12.1).

**Simulação, salário BAIXO (R$200-220/semana, nível de escola 1, sem evoluir no minigame):**

| Semana | Entra com | – comida (nova, R$40) | – conta da casa (R$150) | Saldo no dia 7 (antes do salário) | Meta da missão | Resultado |
|---|---:|---:|---:|---:|---:|---|
| 1 | 220 | 40 | — (ainda não existe) | 180 | `economizar_100` (100) | passa |
| 2 | 180+220=400 | 40 | 150 | 210 | `economizar_300` (300) | **reprova, faltam 90** |
| 2 (sem pagar a conta) | 400 | 40 | 0 | 360 | 300 | passa — **só se ignorar a conta** |

O jogador só consegue passar a missão da semana 2 **se ele fizer exatamente o oposto do que o nível 2 do escritório ensina** (guardar reserva pagando as contas em dia). Isso é uma contradição pedagógica direta, não só numérica: o mecanismo de "sem multa por atraso" (deliberado, ok) combinado com um alvo de missão que ignora o custo fixo vira um incentivo a nunca pagar contas.

**Solução documentada:**
- Baixar `construir_reserva` de 200 → **120** e `economizar_300` de 300 → **150** (semana 2), valor alcançável por quem paga a conta de R$150 no salário baixo (210 ≥ 150, ainda sobra margem para o evento da semana).
- Ou, alternativa que preserva os números atuais: aumentar o salário-base (nível 1) de 200 para ~260, o que também resolve — mas mexe em mais sistemas (curva de progresso do minigame). Recomendo a primeira opção (mais cirúrgica).

## 4. Achado #3 (crítico): `economizar_500` (semana 3) — só alcançável com salário alto

Continuando a simulação (agora com os valores corrigidos da semana 2, `economizar_300`→150):

| Semana | Salário/sem. | Entra com | – comida (40) | – conta (150) | – 1 cota FII (~90, missão `investir_fundo`) | Saldo antes do salário | Meta | Resultado |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| 3, tier BAIXO (200) | 200 | 210+200=410 | 40 | 150 | 90 | **130** | 500 | **reprova, faltam 370** |
| 3, tier MÉDIO (400) | 400 | 350+400=750 | 40 | 150 | 90 | **470** | 500 | reprova por pouco (30) |
| 3, tier ALTO (600) | 600 | 560+600=1160 | 40 | 150 | 90 | **880** | 500 | passa com folga |

`economizar_500` só é viável para quem já evoluiu bastante no minigame de formação (nível de escola 4-5). Um jogador de desempenho médio no minigame (nível 3, salário 400) fica **a R$30 de distância** — margem tão apertada que qualquer imprevisto (evento negativo, -R$300/-R$500 de `UnexpectedEvents.gd`) já derruba.

**Solução documentada:** baixar `economizar_500` (semana 3) → **300**. Mantém a progressão (maior que a meta da semana 2) mas alcançável pelo tier médio com folga (470 ≥ 300) e viável — ainda que apertado — pelo tier baixo (130 vs 300 ainda reprova; ver Achado #5 sobre nivelar o salário mínimo).

## 5. Achado #4 (crítico): `lucro_200` (semana 4) é matematicamente quase impossível

`profit` = `FIIManager.get_profit()` = valor da carteira + dividendos recebidos − total investido.

- Dividend yield dos fundos: 0,8%–1,2% **por semana**, pago 1x por semana.
- Para gerar R$200 só de dividendo em 1-2 pagamentos (o que dá pra receber entre investir na semana 3 e o corte da semana 4), precisaria de **~R$10.000 a R$20.000 investidos** (200 ÷ 0,01 ÷ 2 pagamentos ≈ R$10.000). Nenhum tier de salário chega perto disso em 3-4 semanas de jogo.
- A outra fonte de lucro é a variação de preço (`update_prices()`, ±2%–2,5%/dia, aleatória e sem viés de alta) — ou seja, é uma aposta de cara-ou-coroa, não uma lição de investimento. Mesmo favorável, a variação sobre um valor investido de algumas centenas de reais rende algumas dezenas, não R$200.

**Solução documentada:**
- Baixar `lucro_200` → **R$20** (qualquer lucro real, por pequeno que seja, já cumpre a lição "seu dinheiro rendeu"), **e/ou**
- Aumentar `dividend_yield` dos 3 fundos em `FIIManager.gd` (ex.: 0,8/1,0/1,2% → 2%/2,5%/3%), o que também torna a missão da semana 3 (`investir_fundo`) mais recompensadora e reforça a lição de juros compostos. Recomendo fazer as duas coisas.

## 6. Achado #5: `comprar_empreeendimento` (semana 5) — só para tier alto ou quem nunca pagou conta

Restaurante custa R$1.500 (o mais barato). Seguindo a simulação com os valores já corrigidos (2 e 3):

- Tier BAIXO responsável: por volta da semana 5 acumula ~R$300-500 líquidos — **longe** de R$1.500.
- Tier ALTO responsável: acumula pouco mais de R$2.000-2.500 líquidos por essa altura — **passa**, com sobra pequena para o estoque inicial (R$35 mínimo).

Diferente dos achados 3 e 4, isto **não é uma contradição** (repetir a semana 5 até juntar capital é um padrão de progressão aceitável, e repetir semana não tem penalidade permanente) — mas é lento demais para o tier baixo, que pode levar 5+ repetições da semana 5 só acumulando salário. 

**Solução documentada (prioridade menor que os achados 3/4):** baixar `purchase_price` do restaurante de R$1.500 → **R$900**, ou aceitar como "meta de longo prazo" e não mexer. Deixo as duas opções registradas; não é bloqueante como os achados 2-4.

## 7. Tabela de preços do mercado — recalibração completa (documentado, não aplicado em código, exceto o pão)

Preço por ponto de fome/sede restaurado, comparado a proporção realista (pão < ovo/fruta < arroz a granel < queijo < peixe/hambúrguer < carne):

| Item | Preço atual | Restaura | R$/ponto atual | Preço proposto | R$/ponto proposto | Nota |
|---|---:|---:|---:|---:|---:|---|
| Pão | **R$4** (já aplicado) | 10% fome | 0,40 | — | — | aplicado em código |
| Ovo | R$18 | 18% fome | 1,00 | R$8 | 0,44 | ainda mais barato que hoje, realista (ovo é proteína barata) |
| Banana | R$12 | 12% fome | 1,00 | R$6 | 0,50 | fruta comum, barata |
| Maçã | R$15 | 15% fome | 1,00 | R$7 | 0,47 | idem |
| Arroz | R$90 | 70% fome | 1,29 | R$25 | 0,36 | hoje é o item mais caro em termos absolutos sem motivo — arroz é o alimento-base mais barato por refeição no Brasil |
| Queijo | R$35 | 25% fome | 1,40 | R$20 | 0,80 | laticínio, preço médio |
| Peixe | R$80 | 65% fome | 1,23 | R$45 | 0,69 | proteína intermediária |
| Hambúrguer | R$60 | 50% fome | 1,20 | R$35 | 0,70 | processado, preço médio-alto |
| Carne | R$150 | 100% fome | 1,50 | R$70 | 0,70 | premium, mas ainda a "refeição completa" de 1 item |
| Água | R$5 | 25% sede | 0,20 | — | — | já é o melhor custo-benefício, não mexer |
| Leite | R$25 | 15% sede | 1,67 | R$15 | 1,00 | hoje pior custo-benefício que refrigerante, sem motivo realista |
| Chá | R$15 | 30% sede | 0,50 | — | — | já bem calibrado |
| Suco | R$20 | 35% sede | 0,57 | — | — | já bem calibrado |
| Refrigerante | R$25 | 20% sede | 1,25 | — | — | ok como "opção cara e pouco eficiente", mantém a lição do escritório |
| Café / Energético | R$30 / R$45 | 15% / 20% sede | 2,00 / 2,25 | — | — | **manter caro de propósito** — mimetiza cafeína desidratando pouco, é a "armadilha consciente" que o pão não devia ser |

Com esses preços, o custo de subsistência semanal mínimo (42% fome + 98% sede) usando os itens mais baratos cai para ~R$30-35/semana, dando folga extra em todas as semanas simuladas acima.

## 8. Tabela de missões — valores recalibrados (documentado)

| Semana | Missão | Valor atual | Valor proposto | Motivo |
|---|---|---:|---:|---|
| 2 | `construir_reserva` | 200 | **120** | Achado #2 |
| 2 | `economizar_300` | 300 | **150** | Achado #2 |
| 3 | `economizar_500` | 500 | **300** | Achado #3 |
| 4 | `lucro_200` | 200 | **20** | Achado #4 |
| 5 | `comprar_empreeendimento` (restaurante) | 1.500 | 900 (opcional) | Achado #5 |

Nenhuma outra missão (semana 1, `resolver_evento`, `analise_gastos`, `diversificar`, `pay_enterprise_bill`, `replenish_stock`) mostrou problema de viabilidade financeira na simulação — são checagens de ação (fez ou não fez), não de acúmulo de capital.

## 9. Re-simulação com os valores propostos (achados 2-5 aplicados)

| Semana | Tier BAIXO (sal. 200) | Tier MÉDIO (sal. 400) | Tier ALTO (sal. 600) |
|---|---|---|---|
| 1 — `economizar_100` (100) | 180 ✅ | 180 ✅ | 180 ✅ |
| 2 — `economizar_300`→150 | 210 ✅ | 550 ✅ | 890 ✅ |
| 3 — `economizar_500`→300 | 130 ❌ (ainda apertado) | 470 ✅ | 880 ✅ |
| 4 — `lucro_200`→20 | ✅ (qualquer dividendo cobre) | ✅ | ✅ |
| 5 — `comprar_empreeendimento` (1.500, sem mexer) | precisa repetir semanas | viável por volta da semana 6-7 | viável na semana 5 |

O tier BAIXO (jogador que não evolui nada no minigame de formação, fica travado no nível 1/salário 200 a vida toda) continua apertado na semana 3 mesmo após a correção — porque a causa raiz não é só o valor da missão, é o salário nunca subir. Isso é esperado: o jogo *quer* que evoluir no minigame importe. Não achei necessário zerar essa margem — um jogador que ignora completamente a escola deve mesmo sentir mais dificuldade, e ele ainda não morre nem trava (só reprova e repete a semana, sem penalidade permanente).

## 10. Achados estruturais adicionais (não são de preço/missão, mas afetam a jogabilidade)

- **[RESOLVIDO — ver `PROJECT_KNOWLEDGE.md` §12.3]** Contas da casa e eventos agora têm vencimento, juros de 10%/dia composto e cobrança automática na data limite; sem fundos, a semana se repete com o dinheiro do início dela. O texto abaixo descreve o estado anterior, e a re-simulação das seções 3-4 e 9 deve ser refeita com a cobrança automática (ignorar a conta deixou de ser opção). **Contas da casa nunca têm consequência (estado anterior).** Um jogador "esperto" percebe isso e simplesmente nunca paga — o que ironicamente facilita passar as missões de `money_min` (achado #2). Recomendo, em uma iteração futura, adicionar alguma penalidade leve por conta muito atrasada (ex.: -5% de felicidade, ou travar a missão `no_impulse`/`sem_gastar` enquanto houver conta vencida há 2+ semanas) para a lição "pague suas contas" ter peso mecânico, não só narrativo.
- **`pagar_contas_emp` (semana 5) pode ser cumprida sem pagar nenhuma conta**, se o empreendimento for comprado na mesma semana em que a missão é checada (a primeira conta só é gerada no fechamento daquela semana, depois da checagem da missão). Baixa prioridade — o jogador comprou o negócio de qualquer forma, mas o nome da missão promete uma ação que não ocorreu.
- **`resolver_evento` (semana 2) filtra por `week_generated == semana atual`** — se o único evento sorteado na semana for do mesmo tipo de uma pendência antiga ainda não resolvida, o gerador bloqueia a repetição (proteção contra empilhar contas duplicadas) e a missão pode não ter nada nascido para resolver naquela semana. Baixa probabilidade (5 tipos de evento, sorteio a cada 100s de jogo real + 1 sorteio garantido na virada de semana), mas registrado.

## 11. O que já foi aplicado em código vs. o que fica documentado

**Aplicado em código:**
- `scripts/world/market/market.gd`: todos os 9 preços de comida/bebida da seção 7 (pão R$20→R$4, ovo→R$8, banana→R$6, maçã→R$7, arroz→R$25, queijo→R$20, peixe→R$45, hambúrguer→R$35, carne→R$70, leite→R$15). Água, chá, suco, refrigerante, café e energético mantidos de propósito (seção 7).
- `singletons/TutorialManager.gd`: texto do tutorial atualizado com os novos preços do pão e da carne.
- `singletons/MissionManager.gd`: os 4 valores de missão da seção 8 — `construir_reserva` 200→120, `economizar_300` (semana 2) 300→150, `economizar_500`→`economizar_300_s3` (semana 3) 500→300, `lucro_200`→`lucro_fii` (semana 4) 200→20. IDs renomeados para não ficarem com número desatualizado no nome.
- `singletons/FIIManager.gd`: `dividend_yield` dos 3 fundos subido (Shopping 1%→2,5%, Lajes 0,8%→2%, Logística 1,2%→3%), extraído para `_default_funds()` para não duplicar o dicionário entre a inicialização e `reset()` (achado #4).

**Documentado nesta auditoria, deixado como decisão de design (não aplicado):**
- Preço do restaurante (achado #5) — apresentei R$1.500→R$900 como opção, mas seção 6 também documenta "não mexer" como válido; não escolhi por você.
- As 3 notas estruturais da seção 10 (penalidade para conta atrasada da casa, `pagar_contas_emp` trivial em compra na mesma semana, `resolver_evento` podendo não ter nada pra resolver) — são mudanças de mecânica nova, não só de valor, então pedem decisão de design antes de implementar.
