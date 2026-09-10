# Minigame do Parque — Caça-Moedas

## 1. Objetivo

Dar ao jogador algo ativo para fazer durante o dia (feedback de playtest: "não tem nada pra fazer, só esperar o dia passar"). É uma corrida casual, opcional, dentro do próprio mundo aberto — sem trocar de cena — que também reforça o conteúdo financeiro da semana atual via um quiz.

## 2. Como o jogador acessa

- Existe uma área (`Doors/Park_trigger`, um `Area2D`) posicionada dentro do parque em `scenes/world/main_game.tscn`.
- Ao entrar nela, aparece um painel de info (mesmo padrão visual das portas de loja/casa/banco).
- Apertando **ENTER** dentro da área, se liberado (ver §6), a sessão começa.
- Script: [scripts/park/park_minigame_trigger.gd](scripts/park/park_minigame_trigger.gd).

> **Localização do parque:** demarcada no editor — `Node2D "Park"` contendo `Area2D "Park-zone"` com um `CollisionPolygon2D` desenhado à mão em `main_game.tscn`. O trigger lê esse polígono em runtime (`ParkMinigameTrigger.PARK_ZONE_PATH = "Park/Park-zone/CollisionPolygon2D"`) e converte os pontos locais do polígono para coordenadas de mundo com `to_global()`. Se o node não for encontrado (ex.: cena ainda não salva no editor), o minigame recusa iniciar com um alerta em vez de spawnar moeda em lugar errado.

## 3. Fluxo de uma sessão

1. Jogador aperta ENTER no `Park_trigger` → `ParkMinigameTrigger._start_minigame()`.
2. Cria e adiciona um `ParkMinigameSession` (CanvasLayer) à cena atual, chama `.start(world, spawn_polygon)`.
3. `ParkMinigameManager.begin_session()` é chamado: marca sessão ativa e consome 1 das 2 tentativas do dia.
4. `Global.player_hud_hidden = true` — o HUD do personagem some, sobra só a UI do minigame.
5. A sessão constrói sua própria UI em código (timer + placar no topo da tela) e spawna a primeira moeda.
6. Jogador anda pelo mapa (movimento normal, sem trocar de cena) coletando moedas antes de cada uma expirar.
7. A cada 5 moedas coletadas (até 2 vezes por sessão), o jogo pausa para um quiz.
8. Quando o tempo geral (120s) acaba, a sessão encerra: mostra quantas moedas foram coletadas, restaura o HUD (`player_hud_hidden = false`) e libera a trava de sessão ativa.

## 4. Moedas

- Script: [scripts/park/park_coin.gd](scripts/park/park_coin.gd) — um `Area2D` construído inteiramente em código (sem asset novo: o círculo é desenhado via `_draw()`), com um `Label` de contagem regressiva acima dela.
- Só existe **uma moeda por vez** em tela.
- Vida útil: **10 segundos** (`ParkMinigameManager.COIN_LIFETIME`). Se o tempo acabar, ela some e a próxima nasce imediatamente.
- Coleta: automática ao encostar (`Area2D.body_shape_entered`, igual ao padrão usado nos obstáculos do minigame da escola) — não precisa apertar nada.
- Posição de spawn: sorteada dentro do polígono real do parque (§2), por amostragem por rejeição — sorteia um ponto dentro do retângulo que envolve o polígono e descarta o que cair fora dele (`Geometry2D.is_point_in_polygon`), até 30 tentativas; se falhar (polígono muito fino/côncavo), cai no centroide como último recurso. Implementado em `ParkMinigameSession._random_point_in_spawn_polygon()`.

## 5. Timer geral e placar

- Duração da sessão: **120 segundos** (`ParkMinigameManager.SESSION_SECONDS`).
  - Motivo de ser 120s e não 60s: com moeda de 10s, 60s dificilmente permite juntar as 10 moedas necessárias para dois quizzes; 120s deixa isso alcançável.
- UI construída em código dentro de [scripts/park/park_minigame_session.gd](scripts/park/park_minigame_session.gd) (mesmo espírito do `AlertManager`), mostrando "⏱ Xs" e "Moedas: N" no topo da tela.
- O timer **pausa** automaticamente durante o quiz (`Global.gameplay_locked` true) e retoma ao fechar o quiz/feedback.

## 6. HUD durante o minigame

- Flag central: `Global.player_hud_hidden` (bool, estado de execução — não é salvo, igual `Global.gameplay_locked`).
- Ligada em `ParkMinigameSession.start()`, desligada em `_end_session()`.
- Cada HUD do personagem checa esse flag e se esconde sozinho:
  - [scripts/hud/hud_control.gd](scripts/hud/hud_control.gd) — dinheiro + barras de fome/sede/stamina.
  - [scripts/hud/clock.gd](scripts/hud/clock.gd) — relógio (dia/hora) e label de semana.
  - [scripts/hud/missions_ui.gd](scripts/hud/missions_ui.gd) — botão e painel de missões.
- Resultado: durante a sessão só fica visível a UI própria do minigame (timer + placar + quiz), construída por cima em uma `CanvasLayer` separada.

## 7. Trava de acesso

Todas as condições abaixo passam por `ParkMinigameManager.can_play()`, checadas em ordem (a primeira que falhar decide a mensagem de `lock_reason()`):

1. **Sessão já ativa** — não dá pra começar uma segunda sessão simultânea (`is_session_active()`).
2. **Status em dia** — fome, sede **e** stamina precisam estar todas **≥ 50%** (`ParkMinigameManager.MIN_STATUS_PERCENT`). Checado em `_status_ok()`.
3. **Horário** — só libera **antes das 16h** (`ParkMinigameManager.LATEST_START_HOUR`), comparando com `TimeManager.current_hour`. Passado isso, "já é tarde demais pra brincar".
4. **Cooldown diário** — limite de **2 sessões por dia** (`MAX_PLAYS_PER_DAY`). Contagem usa `Global.get_absolute_day()` e reseta sozinha ao virar o dia; estado persistido em `Global.player["park_minigame"] = {"day": ..., "plays_used": ...}`.

A checagem de horário só vale para **iniciar** — uma sessão já em andamento não é interrompida se o relógio passar das 16h no meio da corrida (o relógio do jogo fica pausado durante o quiz de qualquer forma, e o timer da sessão é de segundos reais, não de horas de jogo).

## 8. Quiz

- A cada **5 moedas coletadas**, até **2 vezes por sessão**, o jogo pausa (`Global.lock_gameplay()` + `Global.play_time = false`) e mostra uma pergunta de múltipla escolha (4 alternativas) em cima da tela.
- Banco de perguntas: [scripts/park/park_quiz_data.gd](scripts/park/park_quiz_data.gd) — **8 perguntas por semana, semanas 1 a 5** (40 no total), escritas em cima do conteúdo de `scripts/world/office/office.gd` (o que o jogador está estudando naquela semana). Semanas além da 5 reaproveitam o banco da semana 5.
- Seleção: aleatória, sem repetir a mesma pergunta dentro da mesma sessão (reembaralha se esgotar o pool disponível).
- **Não há penalidade por errar** — só não ganha a recompensa. Isso foi decisão de design explícita (não desincentivar tentar).
- Acertar: `ParkMinigameManager.grant_quiz_reward()` concede um cupom de **15% de desconto** (`QUIZ_REWARD_DISCOUNT`), guardado em `Global.player["market_discount"]`.

## 9. Cupom de desconto no mercado

- Campo: `Global.player["market_discount"]` (float, 0.0 a 1.0).
- Consumido de uma vez só na próxima finalização de compra em [scripts/world/market/market.gd](scripts/world/market/market.gd) (`_on_finish_pressed()`), aplicado sobre todos os itens do carrinho.
- O total exibido no carrinho já mostra o valor com desconto quando há cupom ativo (`update_labels()`).

## 10. Arquivos envolvidos

| Arquivo | Papel |
|---|---|
| `singletons/ParkMinigameManager.gd` (autoload) | Cooldown diário, trava de sessão simultânea, trava de status/horário, acesso ao banco de perguntas da semana, concessão do cupom. |
| `scripts/park/park_quiz_data.gd` | Dados estáticos: 40 perguntas (8 × 5 semanas). |
| `scripts/park/park_coin.gd` | A moeda individual (visual + timer de 10s + coleta). |
| `scripts/park/park_minigame_session.gd` | Orquestra a sessão inteira: spawn de moedas dentro do polígono do parque, timer geral, placar, quiz, HUD escondido. |
| `scripts/park/park_minigame_trigger.gd` | Área no mundo que inicia a sessão (ENTER) e resolve o polígono do parque. |
| `scenes/world/main_game.tscn` | Contém `Doors/Park_trigger` (área + painel de info) e `Park/Park-zone/CollisionPolygon2D` (área real do parque). |
| `scripts/world/market/market.gd` | Consome o cupom de desconto no checkout. |
| `scripts/hud/hud_control.gd`, `scripts/hud/clock.gd`, `scripts/hud/missions_ui.gd` | Escondem-se sozinhos quando `Global.player_hud_hidden` é true. |
| `singletons/Global.gd` | Guarda `park_minigame` (cooldown, salvo) e `market_discount` (cupom, salvo); `player_hud_hidden` é estado de execução, não salvo. |
| `tests/test_park_minigame.gd` (+ `.tscn`) | Checagem manual: banco de perguntas, cooldown, sessão simultânea, recompensa, trava de status, trava de horário. |

## 11. Constantes de configuração

Todas em `ParkMinigameManager.gd`, fáceis de ajustar:

| Constante | Valor atual | Efeito |
|---|---|---|
| `MAX_PLAYS_PER_DAY` | 2 | Sessões permitidas por dia |
| `SESSION_SECONDS` | 120.0 | Duração do timer geral |
| `COIN_LIFETIME` | 10.0 | Segundos até cada moeda sumir |
| `COINS_PER_QUIZ` | 5 | Moedas coletadas entre um quiz e outro |
| `MAX_QUIZZES_PER_SESSION` | 2 | Limite de quizzes por sessão |
| `QUIZ_REWARD_DISCOUNT` | 0.15 (15%) | Desconto do cupom no mercado |
| `MIN_STATUS_PERCENT` | 50.0 | Fome/sede/stamina mínimas para entrar |
| `LATEST_START_HOUR` | 16 | Hora limite para iniciar uma sessão |

## 12. Limitações conhecidas

- Não foi testado dentro do editor Godot (implementado sem acesso a uma sessão gráfica); vale revisar visualmente antes de considerar pronto — em especial a amostragem de moedas dentro do polígono e a sensação de jogo (timers, quiz, HUD sumindo).

> **Verificado:** `Park/Park-zone/CollisionPolygon2D` está salvo em `main_game.tscn` com exatamente o caminho que `ParkMinigameTrigger.PARK_ZONE_PATH` espera. `Park` e `Park-zone` estão sem transform próprio (posição padrão), então os pontos do polígono já são coordenadas de mundo diretas. O `Doors/Park_trigger` (posição `Vector2(950, 300)`, raio 22) cai inteiramente dentro do polígono real — não precisou ser movido.
