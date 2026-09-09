# Plano de correções e melhorias — varredura de 08/09/2026

Após resolução das 10 correções críticas (fases 0-3 anteriores), este documento
descreve as próximas melhorias e fixes em desenvolvimento, ordenadas por
prioridade e dependência.

---

## Fase 6 — Mecânica de Stamina e Descanso

Redesenho do sistema de "Felicidade" e seu impacto no gameplay.

### 6.1 — Renomear "Felicidade" para "Stamina"

- **Arquivos afetados:** 
  - `Global.gd` — campo `"happiness"` → `"stamina"`
  - `scripts/hud/hud_control.gd` — rótulo e barra de progresso
  - `scripts/world/home.gd` — lógica de repouso
  - `singletons/TimeManager.gd` — decay e reset diário
  - Todos os scripts que leem/escrevem `happiness` → `stamina`
  - `scenes/ui/hud.tscn` — rótulo "FELICIDADE" → "STAMINA"

- **Problema:** O termo "Felicidade" é semanticamente enganoso para uma mecânica
  que força repouso obrigatório. "Stamina" (energia/resistência) deixa claro que
  é um recurso de sobrevivência.

- **Verificar:** todas as telas mostram "STAMINA" em vez de "FELICIDADE"; reload
  e new game não quebram; valores persistem no save.

### 6.2 — Stamina dura apenas 2/3 do dia (16 horas de jogo)

- **Arquivo:** `singletons/TimeManager.gd`, função `decay_need_state()`
- **Problema:** Hoje stamina decai uniformemente durante todo o dia (24 horas de
  jogo). Precisa ser mais agressivo e forçar o jogador a voltar para casa antes
  do fim do dia.

- **Correção:**
  - Stamina começa em 100 no início do dia
  - Decai linearmente até estar zerada às 16 horas de jogo (64 minutos de jogo)
  - Taxa de decay = 100 / 960 minutos = ~0.104 por minuto
  - Quando stamina chegar a 0 **antes** das 18h, o jogo **não** faz game-over
    imediatamente; apenas avisa o jogador que precisa descansar
  - Comportamento exato: ver item 7

- **Verificar:** jogar normalmente sem voltar para casa, confirmar que stamina
  zera aos 16 minutos de game-time, independente de fome.

### 6.3 — Itens do mercado vinculados ao restauro de Fome

- **Arquivo:** `scripts/world/market.gd` (ou dados de itens equivalentes)
- **Problema:** Hoje todos os itens provavelmente restauram a mesma quantidade
  de fome. Precise vincular preço e potência para ensinar trade-off econômico.

- **Estrutura de exemplo:**
  ```
  pão        - R$ 20   - restaura 10% de fome
  arroz      - R$ 90   - restaura 70% de fome
  frango     - R$ 150  - restaura 100% de fome
  agua       - R$ 5    - restaura 5% de fome
  sanduiche  - R$ 50   - restaura 40% de fome
  ```

- **Lógica:** item.preco deve ser proporcional a (item.restaura_fome / 100)
  mais um multiplicador base. Ex: R$ / (% restaurado) deve ser ~0.3 em média.

- **Verificar:** comprar um item barato restaura menos fome; comida cara dura
  mais tempo; economia forçada na semana 1 impõe aperto real.

---

## Fase 7 — Progressão de Dia e Mecanica de Repouso

Obrigatoriedade de voltar para casa e dormir para passar o dia; penalidades
por ficar acordado até meia-noite.

### 7.1 — Fim de dia não é automático; alerta + mecanismo manual de descanso

- **Arquivos:** `singletons/TimeManager.gd`, `scripts/world/home.gd`,
  `scripts/hud/event_ui.gd`

- **Problema atual:** Quando "fim do dia" é atingido, o dia avança
  automaticamente e o jogador volta para casa.

- **Novo comportamento:**
  1. Quando fome OU stamina chegam a zero, ou em horário fixo (18h de jogo):
     - Mostrar alerta: "Você está exausto! Volte para casa para descansar."
     - **Não avançar o dia automaticamente**
  2. Jogador deve ir até a casa **fisicamente** (andar pelo mundo)
  3. Dentro da casa, há uma cama/opção "Dormir"
  4. Ao dormir: stamina volta a 100%, fome reseta, dia avança normalmente
  5. Se não dormir e ficar jogando além de certos horários → ver 7.2

- **Verificar:** ficar até às 18h, receber alerta, voltar para casa
  fisicamente, dormir, e confirmar que o dia avança.

### 7.2 — Stamina decai mais rápido após as 18h; penalidade por ficar acordado

- **Arquivo:** `singletons/TimeManager.gd`, função `decay_need_state()`

- **Observação:** agora o dia pode ir até meia noite (24h) e não somente até 18h, e por isso todas as mecânicas que dependem do tempo, como missões, fundo imobiliários devem ser verificadas para garantir que essa mudança não quebre essas mecânicas que já estão funcionado

- **Mecanismo:**
  - 18h: stamina continua decaindo normalmente (0.104/min)
  - 19h-23h: taxa de decay **dobra** (0.208/min)
  - A cada hora após as 18h, a taxa aumenta 10% adicional
    - 18h → base (1x)
    - 19h → 2x
    - 20h → 2.2x
    - 21h → 2.4x
    - etc.

- **Meia-noite (00h):**
  - Se jogador ainda estiver acordado (stamina > 0 mas não dormiu):
    - Teletransportar automaticamente para casa
    - Mostrar alerta: "Você passou a noite acordado e teve que comprar muito
      café para aguentar o dia! - R$ 30"
    - Cobrar R$ 30 (ou valor configurável)
    - Stamina fica em 50% (não totalmente recuperado)
    - Forçar novo dia sem ter dormido "direito"

- **Verificar:** ficar acordado após as 18h, sentir stamina cair mais rápido,
  chegar às 00h e receber penalidade.

### 7.3 — Game-over por Fome vs Game-over por Stamina

- **Arquivo:** `singletons/TimeManager.gd`

- **Problema:** Hoje há um único game-over quando fome chega a 0. Precisa
  diferenciar.

- **Novo comportamento:**
  - **Fome = 0:** Alerta: "Você morreu de fome!" → Tela de Game-Over
  - **Stamina = 0 (durante o dia, antes das 18h):** Alerta: "Você está muito
    cansado! Volte para casa para descansar." → Não é game-over, apenas força
    o retorno
  - **Stamina = 0 (após 18h):** Taxa de decay acelerada (ver 7.2), preparando
    para meia-noite

- **Verificar:** morrer de fome leva ao game-over; apenas ficar sem stamina
  durante o dia não mata.

---

## Fase 8 — Correção de Bugs Críticos

Problemas que quebraram a jogabilidade em testes recentes.

### 8.1 — Game-over por Fome: botão OK não funciona

- **Arquivo:** `scripts/hud/event_ui.gd` (ou onde quer que seja o handler de
  game-over)

- **Problema:** Quando fome chega a 0, aparece alerta "Você morreu de fome".
  Clicar em "OK" não retorna à tela inicial; jogo fica congelado ou trata-se de
  um bug de transição.

- **Correção:**
  - Verificar se `AlertManager.alert()` está sendo chamado corretamente
  - Garantir que ao fechar o alerta, uma flag trigera `TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")`
  - Testar manualmente: deixar fome ir a 0, clicar OK, voltar ao menu

- **Verificar:** morrer de fome, clicar OK, estar de volta no menu principal.

### 8.2 — Minigame da semana 2 falha ao iniciar

- **Arquivo:** `scripts/minigame/minigame.gd` (ou `scenes/minigame/minigame.tscn`)

- **Problema:** Ao chegar na semana 2, iniciar o minigame teletransporta ou
  trava, causando game-over imediato.

- **Investigação necessária:**
  - Verificar se há gerenciamento de estado que mudou entre semana 1 e 2
  - Conferir se `MinigameManager` está resetando corretamente
  - Procurar por chamadas a `reset()` que possam estar faltando
  - Testar em headless ou com debug mode ativado

- **Verificar:** chegar na semana 2, abrir minigame, jogar normalmente sem
  falhas imediatas.

---

## Fase 9 — Pausa e Gestão de Tempo

Sistema de pausa que persiste através de transições de cena.

### 9.1 — Tempo continua rodando quando volta ao menu principal

- **Arquivo:** `singletons/TimeManager.gd`

- **Problema:** Ao sair do jogo para o menu principal via `TransitionManager`,
  `TimeManager._process()` continua sendo acionado e o tempo avança mesmo sem
  o jogador estar no mundo.

- **Correção:**
  - Rastrear qual cena está ativa (usar `get_tree().current_scene.name` ou
    similar)
  - `TimeManager._process()` deve fazer `return` se não estiver em
    `main_game.tscn`
  - Alternativa: usar sinal `tree_exited` do main_game para avisar TimeManager
    de pausar, e sinais de `tree_entered` para resumir

- **Verificar:** entrar no jogo, sair para o menu, voltar alguns segundos depois
  — confirmar que o tempo não pulou.

---

## Fase 10 — Penalidades de Investimento Ruim

Sistema de risco e recompensa para FII.

### 10.1 — Penalizar inversões ruins em FII

- **Arquivo:** `singletons/FIIManager.gd`

- **Contexto:** "Más escolhas" em FII podem significar:
  - Vender com perda (preço caiu)
  - Todos os fundos caem juntos (volatilidade do mercado)
  - Investir tudo em um único fundo (falta de diversificação)

- **Opções de penalidade:**
  
  **A) Penalidade ao vender com perda:**
  ```
  lucro_sobre_venda = preco_venda - preco_compra_medio
  if lucro_sobre_venda < 0:
      penalidade = abs(lucro_sobre_venda) * 0.1  # 10% de imposto
      Global.player["money"] -= penalidade
  ```

  **B) Penalidade por falta de diversificação:**
  - Se > 70% da carteira está em um único fundo:
    - Reduzir dividendos em 20%
    - Ou cobrar taxa administrativa

  **C) Penalidade aleatória de "volatilidade":**
  - A cada semana, se há grande oscilação de preço:
    - Cobrar R$ 50-100 de "taxa de consultoria" ou "corretagem"

- **Recomendação:** Implementar **A** primeiro (mais claro), depois **B** para
  ensinar diversificação.

- **Verificar:** vender um fundo com perda, confirmar que há custo adicional;
  carteira diversificada não sofre penalidade.

---

## Resumo de Ordem Sugerida

```
Fase 6  (6.1, 6.2, 6.3)     -> Renomear e redesenhar stamina
   |
Fase 7  (7.1, 7.2, 7.3)     -> Mecanismo de descanso obrigatório
   |
Fase 8  (8.1, 8.2)          -> Bugs críticos (game-over, minigame)
   |
Fase 9  (9.1)               -> Gestão de pausa temporal
   |
Fase 10 (10.1)              -> Penalidades de investimento
```

Fases 6-7 são o redesenho principal do jogo. Fases 8-9 são bloqueadores.
Fase 10 é enriquecimento educacional.

---

## Checklist de Verificação Final

- [ ] "Felicidade" renomeada para "Stamina" em 100% das UIs
- [ ] Stamina zera em 2/3 do dia (16 horas de game-time)
- [ ] Itens do mercado têm fome restaurada vinculada ao preço
- [ ] Fim de dia força retorno físico à casa + dormir
- [ ] Stamina decai mais rápido após 18h
- [ ] Meia-noite: teletransporte + penalidade R$ 30
- [ ] Fome = 0 → Game-over com OK funcional
- [ ] Minigame semana 2 inicia sem falhas
- [ ] Sair para menu principal pausa o tempo
- [ ] Vendas com perda cobram penalidade em FII
