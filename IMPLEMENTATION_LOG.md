# Implementation Log — Fases 6-11

**Início:** 2026-09-08
**Última atualização:** 2026-09-09
**Status:** Fases 6 a 10 implementadas, mais a fase 11 (tutorial e liberação
sequencial dos lugares). Falta validação manual em jogo.

Verificação automática: `tests/test_mechanics.gd` — 72 asserts, todos passando.

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/test_mechanics.tscn
```

---

## Auditoria da sessão anterior

A sessão de 08/09 registrou as fases 7.2 e 7.3 como "IN PROGRESS / PARTIALLY
DONE — already implemented". O código existia, mas era **inalcançável**:

- `_add_minute()` chamava `_finish_day()` assim que a hora chegava a 18 e ligava
  `day_end_pending`, que fazia `_add_minute()` retornar no topo para sempre.
- Logo `current_hour` nunca passava de 18. O ramo de aceleração pós-18h nunca
  executava e `_handle_midnight()` era código morto.
- Pelo mesmo motivo a fase 6.2 não podia funcionar: um orçamento de stamina de
  16 horas não cabe num dia de 10 horas (08h → 18h). O dia terminava com ~37 de
  stamina sobrando, sempre.

Outros pontos corrigidos nesta sessão:

| Problema | Onde estava |
|---|---|
| `Global._process()` abria o alerta "Você morreu de fome" **a cada quadro** | causa real do bug 8.1 — cada chamada empilhava um `lock_gameplay()` e o OK nunca vencia a contagem |
| `_decay_stamina()` chamava `AlertManager.alert()` **e** `Global.lock_gameplay()` | `alert()` já tranca; o segundo lock nunca era devolvido e travava o jogo de vez |
| Dois caminhos concorrentes de game-over | `Global._process()` e `decay_need_state()` |
| 6.1 marcada como 100% concluída | `home.gd:217` ainda exibia "Felicidade"; `Global.gd:112` ainda gravava a chave `happiness` em `last_week_status` |
| Seção 6.3 duplicada no log, uma feita e outra `[TODO]` | erro de cópia |
| `scenes/ui/hud.tscn` listado como arquivo modificado | esse arquivo não existe; o HUD vive em `scenes/players/player.tscn` |

---

## Fase 6 — Stamina

### 6.1 — "Felicidade" → "Stamina" ✅

Concluído na sessão anterior, mais os resíduos encontrados agora:

- `Global.gd` — `last_week_status` gravava `happiness`; agora grava `stamina`.
- `Global.gd` — `apply_home_action(..., happiness_delta, ...)` renomeado para
  `stamina_delta`.
- `home.gd` — o inventário exibia "Energia X / Felicidade Y". Como `energy`
  agora guarda o **% de fome** do item (ver 6.3), o rótulo virou "Fome +X%".

O campo `happiness` **continua existindo** dentro de cada item do
`home_inventory`. Renomear exigiria migrar saves para nada: nada mais o lê.

### 6.2 — Stamina dura 16 horas de jogo ✅

`TimeManager.STAMINA_DECAY_PER_MINUTE = 100.0 / 960.0`.

O número só fecha porque o dia foi estendido em 7.1/7.2: 08h → 24h são
exatamente 16 horas. Num dia de 08h → 18h a mecânica era impossível.

| Hora | Multiplicador | Stamina restante |
|---|---|---|
| 08h | 1.0x | 100.0 |
| 18h | 1.0x | 37.5 — dispara o aviso de cansaço |
| 19h | 2.0x | 31.25 |
| 20h | 2.2x | 18.75 |
| 21h | 2.4x | 5.0 |
| ~21h20 | 2.4x | 0 |

Fórmula a partir das 19h: `base * 2.0 * (1 + (hora - 19) * 0.1)`. Segue a tabela
do plano (18h = 1x, 19h = 2x, 20h = 2.2x), **não** o código anterior, que já
aplicava 2x às 18h.

### 6.3 — Itens do mercado vinculados à fome ✅

Concluído na sessão anterior. Um ajuste feito agora: `consume_food()` convertia
stamina a partir de `happiness * 0.35`, e como 6.3 passou a definir
`happiness = hunger_restore * 0.1`, a carne (100% de fome) devolvia 3.5 de
stamina. Agora o ganho é `energy * STAMINA_PER_FOOD_ENERGY` (0.25), direto do %
de fome do item.

---

## Fase 7 — Progressão de dia e repouso ✅

### 7.1 — Fim de dia manual

- `_finish_day()` **removido**. O dia não termina mais sozinho.
- Às 18h, `_warn_exhaustion()` mostra "Você está exausto! Volte para casa para
  descansar." uma vez por dia (`_exhaustion_alert_shown`).
- Botão **DORMIR** adicionado em `home.gd`, chamando `TimeManager.sleep()`.
- Dormir: stamina → 100, fechamento contábil do dia, dia avança para as 08h.

**Trava anti-exploit:** dormir só é aceito a partir das 18h, ou com stamina
zerada. Sem isso o jogador dormiria às 08h01 sete vezes seguidas e viraria a
semana — com salário e dividendos — pagando só a fome de sete dias.

**Divergência assumida.** O plano diz "ao dormir: stamina volta a 100%, fome
reseta". Fome resetando para 100 tornaria o game-over por fome (7.3) e o bug
8.1 impossíveis de acontecer. Implementado como o decaimento normal de fim de
dia (-6 de fome); repor fome é papel da comida comprada no mercado.

### 7.2 — Aceleração pós-18h e penalidade da meia-noite

Agora alcançáveis, porque o dia corre até as 24h. À meia-noite sem ter dormido:
-R$ 30, stamina em 50%, volta para a porta de casa via
`return_home_next_day`, mesmo fechamento contábil do sono.

**Divergência assumida.** O plano condiciona a penalidade a "stamina > 0". Com a
aceleração da 7.2 a stamina chega a zero por volta das 21h20, então essa
condição nunca seria satisfeita e a penalidade nunca dispararia. A penalidade
agora vale para qualquer jogador que chegue à meia-noite sem dormir.

**Mecânicas dependentes de tempo, verificadas.** Missões, contas da casa,
eventos, dividendos e a operação diária dos empreendimentos são todos indexados
por dia ou semana, nunca por hora — a extensão do dia não os afeta. As únicas
leituras de hora no projeto são os rótulos de relógio: `clock.gd`,
`time_display.gd` e `home.gd`.

### 7.3 — Game-over de fome vs. stamina

- Fome = 0 no fechamento do dia → game-over, volta ao menu, save apagado.
- Stamina = 0 → alerta uma vez, sem game-over e sem travar o jogador. O custo de
  ficar sem stamina é não conseguir encerrar o dia sem a penalidade da 00h.

---

## Fase 8 — Bugs críticos ✅

### 8.1 — Botão OK do game-over

Causa real: `Global._process()` chamava `AlertManager.alert("Você morreu de
fome")` a cada quadro. Cada chamada incrementava o contador de
`lock_gameplay()`; fechar o alerta devolvia um lock só, e no quadro seguinte a
caixa reabria. O plano apontava `event_ui.gd`, que não tem relação com
game-over.

Correção: `Global._process()` removido; `Global.trigger_game_over()` virou o
ponto único, com trava `_game_over` que impede reabrir a caixa. O callback
`_return_to_main_menu()` apaga o save e volta ao menu.

### 8.2 — Minigame trava na semana 2

Causa real: a "entrada correndo" em `minigame.gd._on_start_pressed()`. Ao
apertar Começar, o jogador era teletransportado **300px para trás** do marcador
do seu nível e corria em auto-run até ele — com `begin_session()` já ativo.

Os marcadores ficam logo depois do checkpoint anterior:

| Nível | Marcador | 300px atrás | O que havia lá |
|---|---|---|---|
| 2 | x=465 | x=165 | livre |
| 3 | x=1926 | x=1626 | obstacle8 (x=1779) e o checkpoint Level2 (x=1899) |
| 4 | x=3250 | x=2950 | checkpoint Level3 (x=3227) |
| 5 | x=4554 | x=4254 | checkpoint Level4 (x=4533) |

Do nível 3 em diante o jogador batia num obstáculo ou reatravessava um
checkpoint já conquistado antes de ganhar controle — o "game-over imediato". Não
havia nada errado com o `MinigameManager`, que era onde o plano mandava
procurar.

Correção: o jogador começa parado no marcador do seu nível. O run-in foi
removido — o mapa é denso demais para 300px seguros em qualquer direção. Junto
saíram `start_auto_run()` / `stop_auto_run()` de `player.gd` (chamados via
`call_deferred` num nó que nem tinha esses métodos) e `_begin_game()`, morto.

---

## Fase 9 — Pausa de tempo ✅

`main_menu.gd._ready()` desliga `Global.play_time`. Toda cena de gameplay liga
essa flag no seu `_ready()` e nenhuma a desligava ao sair, então o relógio
seguia correndo no menu.

Não foi usada a abordagem sugerida no plano (checar `current_scene.name ==
main_game.tscn` dentro de `_process`): casa, mercado, banco, escritório e
minigame são cenas de gameplay legítimas com nomes diferentes, e a lista
quebraria a cada cena nova.

---

## Fase 10 — Penalidade de investimento ✅

Opção **A** do plano: 10% de imposto sobre o prejuízo ao vender abaixo do preço
médio pago.

O `FIIManager` não tinha base de custo — `portfolio` era só `{fund_id: qtd}` e
`total_invested` um número global. Foi acrescentado `avg_price`, um dicionário
paralelo com o preço médio ponderado por fundo. `portfolio` manteve o formato,
para não quebrar `portfolio.gd` nem `fii_shop.gd`.

- Compra: recalcula o preço médio ponderado.
- Venda abaixo do preço médio: cobra 10% do prejuízo, registra em
  `expense_history` e explica ao jogador no alerta.
- Venda no lucro: nada é cobrado.
- Save antigo sem `avg_price`: adota o preço atual como base, para uma carteira
  herdada não ser taxada por um prejuízo que nunca existiu.

A opção B (concentração acima de 70%) não foi implementada — o plano a coloca
como segunda etapa, e a dica de diversificação já entrou no tutorial da semana
4.

---

## Fase 11 — Tutorial e liberação sequencial dos lugares ✅

### 11.1 — O tutorial voltava depois de ser pulado

O relato era "pulei o tutorial e ele volta depois do minigame". O bug era maior:
`FINAL_STEP` valia 8 e o tutorial **terminava** deixando `tutorial_step = 8`,
mas `main_game._ready()` fazia `resume_tutorial()` para qualquer passo de 2 a 8.
Ou seja, o tour do mundo era refeito **toda vez** que o jogador entrava na cena
do mundo — voltando do mercado, do banco, da casa, de qualquer lugar. Pular o
tutorial só tornava isso visível mais cedo, porque `skip_tutorial()` também
gravava 8.

Correção: "concluído" virou um estado próprio, `TUTORIAL_DONE = 11`, acima de
`FINAL_STEP`. `_finish_tutorial()` é o ponto único que marca isso, usado tanto
pela conclusão normal quanto pelo `skip_tutorial()`. E `main_game._ready()`
passou a testar faixa em vez de listar passos:

```gdscript
if tutorial_step == 1:
    TutorialManager.start_tutorial()
elif tutorial_step <= TutorialManager.FINAL_STEP:
    TutorialManager.resume_tutorial(tutorial_step)
```

Os avisos semanais já eram cobertos por `tutorial_weeks_shown`, que
`skip_tutorial()` preenche com todas as semanas.

### 11.2 — Cidade trancada, liberada em três etapas

Novo campo `Global.player["unlock_stage"]`:

| Estágio | O que abre | Quando |
|---|---|---|
| 0 `UNLOCK_SCHOOL_ONLY` | só a escola | novo jogo |
| 1 `UNLOCK_OFFICE` | escola + escritório | fim do minigame (passo 8) |
| 2 `UNLOCK_ALL` | tudo | fim do tour (passo 10) ou tutorial pulado |

`Global.PLACE_UNLOCK_STAGE` mapeia só `school` e `office`. Todo o resto — banco,
mercado, casa e os três empreendimentos — cai no padrão `UNLOCK_ALL`, então um
lugar novo já nasce trancado até o fim do tutorial sem precisar ser cadastrado.

`set_unlock_stage()` só avança, nunca retrocede: um evento fora de ordem não
pode retrancar o que já abriu.

### 11.3 — Nova ordem do tutorial

O roteiro passou de 8 para 10 passos:

| Passo | O que acontece |
|---|---|
| 1-4 | boas-vindas |
| 5 | espera o jogador entrar na escola |
| 6 | explicação dentro do minigame |
| 7 | espera o minigame terminar |
| **8** | **câmera vai ao escritório, apresenta, e o libera** |
| **9** | **câmera volta ao jogador e espera a visita ao escritório** |
| **10** | **apresenta o resto da cidade e libera tudo** |

O passo 10 **não** passa por `_next_step()`. O tour usa foco de câmera, que só
existe em `main_game`, e quando o escritório é destravado o jogador está na cena
do escritório. Então `office.gd._on_exit_pressed()` chama
`on_player_left_office()`, que apenas avança o contador; ao carregar o mundo,
`main_game._ready()` chama `resume_tutorial(10)` e o tour roda lá.

Mensagens: `messages[9]` (parabéns) e `messages[13]` (o que é o escritório,
com foco de câmera via `message_focus_map`) saíram do tour e foram para o passo
8, junto com a nova `messages[21]`, que avisa que o escritório é o único lugar
aberto.

### 11.4 — Portas

Casa, mercado, banco e escritório eram quatro scripts idênticos, mudando só a
cena de destino e o nome da variável de "está dentro". Em vez de repetir a trava
de progressão nos quatro, viraram subclasses de três linhas de
`scripts/world/doors/place_door.gd`, que concentra a trava, o alerta de porta
trancada e o texto do painel.

`enterprise_door.gd` recebeu a mesma trava (regra de entrada própria, por causa
do diálogo de compra). `minigame_door.gd` ficou intocado: a escola é estágio 0,
sempre aberta, e já tem a trava própria do `MinigameManager`.

O painel de cada porta diz por que ela não abre, em vez de deixar o jogador
apertando ENTER sem retorno.

### Saves anteriores

Um save sem `unlock_stage` é anterior a esta mudança. `ensure_player_state()`
entra com `UNLOCK_ALL` e, se `tutorial_step >= 8` (o "concluído" do formato
antigo), converte para `TUTORIAL_DONE`. Sem isso, quem já estava jogando teria a
cidade trancada e o tutorial repetido.

### Efeito colateral conhecido

Com a casa trancada no estágio 0, um jogador que demorar a fazer o minigame não
consegue dormir e leva a penalidade da meia-noite todo dia. É recuperável — a
escola é o único lugar aberto e o tutorial aponta para lá — mas vale saber que
existe.

---

## Tutorial

- `messages[16..18]`: barra de stamina, o dia que só acaba dormindo em casa, e
  a penalidade da meia-noite.
- `messages[19..20]`: o % de fome de cada item do mercado, e fome zerada = game
  over.
- Entram no fechamento do onboarding (passo 8), nos dois caminhos:
  `_next_step()` e `resume_tutorial()`.
- `weekly_messages[4]`: dica sobre o imposto de 10% e diversificação, junto do
  conteúdo de mercado financeiro do escritório.

Os índices novos foram **acrescentados ao fim** do array `messages` de
propósito: os índices 0-15 são referenciados um a um em `_next_step()`.

---

## Arquivos modificados nesta sessão

| Arquivo | O quê |
|---|---|
| `singletons/TimeManager.gd` | ciclo do dia reescrito: sem fim automático, `sleep()`, meia-noite, curva de stamina |
| `singletons/Global.gd` | game-over único e travado, `decay_need_state()` devolve bool, resíduos de `happiness`, stamina da comida |
| `singletons/FIIManager.gd` | `avg_price` e imposto sobre prejuízo |
| `singletons/TutorialManager.gd` | mensagens das mecânicas novas |
| `scripts/world/home/home.gd` | botão DORMIR, rótulo do inventário |
| `scripts/menus/main_menu.gd` | pausa o relógio |
| `scripts/minigame/minigame.gd` | run-in removido |
| `scripts/player/player.gd` | auto-run morto removido |
| `tests/test_mechanics.gd` + `.tscn` | auto-teste novo |
| `scripts/world/doors/place_door.gd` | **novo** — base das portas simples, com a trava de progressão |
| `scripts/world/doors/{bank,home,market,office}_door.gd` | viraram subclasses de três linhas |
| `scripts/world/doors/enterprise_door.gd` | mesma trava de progressão |
| `scripts/world/main_game.gd` | não repete mais o tutorial concluído |
| `scripts/world/office/office.gd` | avisa o tutorial ao sair |

---

## O que falta — teste manual em jogo

O auto-teste cobre só cálculo puro. Precisa de partida real:

- [ ] Andar até a casa depois das 18h, clicar DORMIR, confirmar que o dia avança
      e o jogador nasce na porta de casa.
- [ ] Tentar DORMIR antes das 18h e ver a recusa.
- [ ] Ficar acordado até as 00h e conferir os R$ 30, a stamina em 50% e o
      retorno para casa.
- [ ] Deixar a fome zerar, clicar OK e confirmar a volta ao menu principal.
- [ ] Chegar à semana 2 com nível 3+ e jogar o minigame do início ao fim.
- [ ] Sair para o menu, esperar, voltar e conferir que o relógio não andou.
- [ ] Vender um FII no prejuízo e conferir o alerta e o desconto.
- [ ] Fazer o tutorial inteiro e ver as mensagens novas na ordem certa.
- [ ] Novo jogo: confirmar que só a escola abre e as outras portas explicam o porquê.
- [ ] Pular o tutorial e confirmar que a cidade abre inteira e nada mais aparece.
- [ ] Depois do minigame: câmera vai ao escritório, volta ao jogador, e só o
      escritório abre.
- [ ] Entrar e sair do escritório: o tour do resto da cidade roda e tudo abre.
- [ ] Voltar ao mundo várias vezes depois do tutorial e confirmar que ele não
      se repete.
