# Plano — mecânica de Sede + tutorial da casa

Duas frentes independentes que se cruzam num ponto (a mensagem de tutorial que
explica sede fica no bloco da casa, então B5 depende de A).

**Princípio:** sede não é um sistema novo. É `hunger` clonado, reusando o
mesmo estado, o mesmo decaimento diário, o mesmo game-over e o mesmo estoque
da casa. Nada de `NeedsManager`.

---

## Diagnóstico — por que as bebidas não servem para nada hoje

`market.gd` tem duas categorias, `"Comidas"` e `"Bebidas"`, e no checkout faz:

```gdscript
Global.add_home_inventory_item(item_name.capitalize(), 1,
    "food" if group_name in ["Comidas", "Bebidas"] else "item", hunger_restore)
```

As duas caem em `"food"`. Depois `consume_food()` filtra
`category != "food"` e escolhe o item de maior `energy`. Resultado: **bebida é
comida ruim.** Cerveja custa R$ 50 e repõe 5% de fome; ninguém vai comprar.
O que falta não é balancear preço — é a bebida ter um medidor próprio para
alimentar.

Números atuais para calibrar: `HUNGER_DECAY_PER_DAY = 6.0` (fome zera em ~17
dias), `STAMINA_DECAY_PER_MINUTE = 100/960` (stamina zera em 16 h de jogo).
A fome é pressão lenta de fundo; a sede vai ser a pressão de médio prazo.

---

## Fase A — Mecânica de sede

### A1 — Campo de estado `thirst`

- **Arquivo:** `singletons/Global.gd`
- **Onde mexer:** `data_model`, `last_week_status`, `ensure_player_state()`,
  `new_game()`, `evaluate_week_status()` — em todos os lugares onde `hunger` e
  `stamina` já aparecem juntos (linhas 58-59, 75-76, 182, 185-186, 232-233,
  240, 437-439).
- **Correção:** `"thirst": 100.0` ao lado de `"hunger"`, e o mesmo
  `clampf(..., 0.0, 100.0)` na normalização.

- **⚠️ A armadilha desta fase — `normalize_home_inventory()`:** essa função
  **reconstrói cada item do zero** a partir de uma lista fixa de chaves:

  ```gdscript
  normalized[normalized_key] = {
      "name": ..., "quantity": ..., "category": ...,
      "energy": ..., "happiness": ...
  }
  ```

  Um campo `thirst` no item é **silenciosamente apagado** a cada chamada — e
  ela é chamada em `add_home_inventory_item()`, `get_home_inventory_items()` e
  `ensure_player_state()`. Adicionar `"thirst": float(item.get("thirst", 0.0))`
  aqui é obrigatório, e é o bug mais fácil de não perceber neste plano.

- **Verificar:** comprar uma bebida, sair da casa, voltar, e confirmar que o
  item ainda mostra o valor de sede.

### A2 — Dados do mercado: `thirst_restore` e categoria própria

- **Arquivo:** `scripts/world/market/market.gd`
- **Correção:** cada item ganha `thirst_restore` ao lado do `hunger_restore`
  que já existe. Nada é removido — a calibragem de fome das bebidas
  (milkshake 40, chocolate quente 25) continua valendo, agora como bônus.

  ```
  Comidas   (thirst_restore baixo, só o que é aquoso)
    bread      R$ 20   fome 10   sede  0
    rice       R$ 90   fome 70   sede  5
    hamburger  R$ 60   fome 50   sede  0
    apple      R$ 15   fome 15   sede  8
    banana     R$ 12   fome 12   sede  3
    milk       R$ 25   fome 20   sede 15
    cheese     R$ 35   fome 25   sede  0
    meat       R$150   fome100   sede  0
    egg        R$ 18   fome 18   sede  0
    fish       R$ 80   fome 65   sede  0

  Bebidas   (R$ por % de sede -> a lição financeira está nesta coluna)
    water          R$  5   fome  3   sede 25    0.20  <- eficiente
    tea            R$ 15   fome  8   sede 30    0.50
    juice          R$ 20   fome 15   sede 35    0.57
    soda           R$ 25   fome 12   sede 20    1.25
    hot_chocolate  R$ 40   fome 25   sede 25    1.60
    milkshake      R$ 55   fome 40   sede 30    1.83
    coffee         R$ 30   fome 10   sede 15    2.00
    energy_drink   R$ 45   fome 30   sede 20    2.25
    beer           R$ 50   fome  5   sede 10    5.00  <- armadilha
    wine           R$120   fome  8   sede  8   15.00  <- armadilha
  ```

  Água é 25x mais eficiente que vinho. É esse contraste que ensina, e ele já
  cai bem no tom do jogo: o item barato e sem graça é o certo.

- **Categoria:** o checkout passa a distinguir as duas:

  ```gdscript
  var category = "food" if group_name == "Comidas" else ("drink" if group_name == "Bebidas" else "item")
  ```

- **Rótulo do produto:** `_populate_items()` (linha ~106) e o card do carrinho
  (linha ~178) mostram só `%d%% fome`. Passam a mostrar o par, omitindo o zero:
  `"R$ 20 – 10% fome"` / `"R$ 5 – 25% sede"` / `"R$ 25 – 20% fome, 15% sede"`.
- **`add_home_inventory_item()`:** ganha o parâmetro `thirst_restore` e grava
  `item["thirst"]`, espelhando o que já faz com `hunger_restore` → `energy`.
- **Verificar:** o card de cada item mostra os dois valores; comprar bebida
  grava `category = "drink"` no save.

### A3 — Consumo: generalizar `consume_food()` em vez de duplicar

- **Arquivos:** `singletons/Global.gd`, `scripts/world/home/home.gd`
- **Problema:** `consume_food()` tem ~30 linhas — escolher o melhor item,
  decrementar, apagar se zerou, aplicar ganhos, gravar log, gastar 0,5 h.
  Copiar isso para `consume_drink()` é o caminho errado.
- **Correção:** uma função parametrizada, dois chamadores finos.

  ```gdscript
  # need_key: "hunger" ou "thirst" — decide o filtro e o critério de escolha.
  # O item aplica SEMPRE os dois restauros: leite mata um pouco de sede,
  # milkshake mata um pouco de fome. Quem escolhe o item é o botão.
  func consume_item(category: String, need_key: String) -> Dictionary:
      ...
  func consume_food() -> Dictionary:  return consume_item("food", "hunger")
  func consume_drink() -> Dictionary: return consume_item("drink", "thirst")
  ```

  `consume_food()` fica como fachada porque `tests/test_mechanics.gd` e
  `home.gd` já a chamam.

- **Corrigir de passagem:** a guarda é `if player["hunger"] == 100.00` —
  igualdade de float. Depois de um restauro parcial a fome pode ficar em
  99.999997 e a mensagem "Você não está com fome" nunca aparece. Na versão
  generalizada usar `>= 100.0`.
- **Casa:** botão `BEBER` em `_build_action_buttons()` (linha ~109), entre
  `COMER` e `DESCANSAR`, ligado a `_on_drink_pressed()`. Custo de tempo menor
  que comer — 0,25 h em vez de 0,5 h.
- **Verificar:** comprar água e pão, ir à casa, BEBER consome a água (não o
  pão) e COMER consome o pão; o log da casa registra as duas ações.

### A4 — Decaimento diário e game-over

- **Arquivos:** `singletons/Global.gd`, `singletons/TimeManager.gd`
- **Correção:** `const THIRST_DECAY_PER_DAY := 14.0` — sede zera em ~7 dias
  contra ~17 da fome. Com água a R$ 5 repondo 25%, são ~R$ 20/semana, algo
  entre 4% e 10% do salário: aperta sem sufocar.
- **`decay_need_state()`** já é o ponto único do decaimento diário e já
  devolve `false` para disparar game-over. A sede entra na mesma função:

  ```gdscript
  player["thirst"] = clampf(float(player.get("thirst", 100.0)) - THIRST_DECAY_PER_DAY, 0.0, 100.0)
  if player["thirst"] <= 0.0:
      trigger_game_over("Você morreu de desidratação!")
      return false
  ```

  A ordem entre fome e sede não importa: `trigger_game_over()` tem a trava
  `_game_over`, então só o primeiro alerta abre (foi a correção do bug 8.1).
- **Verificar:** dormir 7 dias sem beber → game-over de desidratação, um
  alerta só, e o botão OK volta ao menu.

### A5 — Interface: a terceira barra

- **Arquivos:** `scenes/players/player.tscn`, `scripts/hud/hud_control.gd`,
  `scenes/world/places/home.tscn`, `scripts/world/home/home.gd`
- **Correção:** duplicar o painel de fome em cada uma das duas cenas.
  - HUD do mundo: `Hud/HudControl/Thirst/VBoxContainer/Thirst-bar`
  - Casa: `.../Status-panel/VBoxContainer/Thirst-container/ProgressBar`
- **Nota:** os nomes existentes já estão inconsistentes entre si —
  `Hunger/VBoxContainer/Hunger-bar` com rótulo `Hunger-label`, mas
  `Stamina/VBoxContainer/ProgressBar` com rótulo `Title`. Seguir o padrão de
  `Hunger` no nó novo, e não o de `Stamina`.
- **Verificar:** três barras no mundo e três na casa; beber move só a de sede
  (mais o pouco de fome do item).

### A6 — Migração de saves existentes

- **Arquivo:** `singletons/Global.gd`, dentro de `normalize_home_inventory()`
- **Problema:** todo save atual tem as bebidas gravadas com
  `category = "food"` e sem `thirst`. Sem migração, a água já comprada
  continua sendo comida ruim e o botão BEBER não acha nada.
- **Correção:** remapear por nome na normalização, com a lista de bebidas do
  mercado como fonte da verdade:

  ```gdscript
  # ponytail: remap por nome, uma vez na normalização. Se as bebidas virarem
  # dados externos, ler a lista de lá em vez de repetir os nomes aqui.
  const DRINK_NAMES := ["water", "tea", "juice", "soda", "hot_chocolate",
      "milkshake", "coffee", "energy_drink", "beer", "wine"]
  ```

  Item com nome na lista e `category == "food"` → vira `"drink"` e recebe o
  `thirst_restore` da tabela A2.
- **Verificar:** carregar o save atual (que tem estoque) e confirmar que as
  bebidas aparecem com valor de sede e são bebíveis.

### A7 — Teste

- **Arquivo:** `tests/test_mechanics.gd`
- **Correção:** um caso que falha se a lógica quebrar — beber com estoque de
  água escolhe a água, aplica `thirst_restore` e `hunger_restore`, decrementa
  a quantidade, e um segundo caso onde 7 decaimentos sem beber disparam o
  game-over. O teste de stamina existente (linha ~135) usa
  `STAMINA_PER_FOOD_ENERGY` e continua valendo.

---

## Fase B — Tutorial da casa

Hoje a casa **nunca é explicada**. Ela não aparece no tour do passo 10
(`_queue_world_tour()` cita mercado, banco e escritório), e as quatro ações —
COMER, BEBER, DESCANSAR, ASSISTIR TV, DORMIR — o jogador descobre sozinho. Pior:
`TimeManager.sleep()` é o **único** jeito de encerrar o dia, e isso nunca é
dito no lugar onde acontece.

A abordagem segue a filosofia que o tutorial já usa (dosar onde a mecânica
destrava): uma linha no tour aponta a casa, e o bloco pesado dispara na
**primeira vez que o jogador entra nela**.

### B1 — Gancho de primeira visita

- **Arquivos:** `singletons/TutorialManager.gd`, `scripts/world/home/home.gd`,
  `singletons/Global.gd`
- **Precedente a copiar:** `on_player_left_office()`, chamado por
  `office.gd:235`. Mesma forma, mesma simplicidade.
- **Correção:**
  - `Global.data_model` ganha `"tutorial_home_shown": false` (+
    `ensure_player_state()` e `new_game()`).
  - `TutorialManager.on_player_entered_home()` — sai fora se a flag já está
    marcada, se `pending_messages` não está vazia, ou se o tutorial foi
    pulado; senão marca a flag e chama `queue_messages()`.
  - `home.gd._ready()` chama esse método.
- **Por que uma flag persistida e não a variável `step`:** o bloco da casa não
  é um passo do onboarding — pode acontecer na semana 1 ou na 4, dependendo de
  quando o jogador entra. E `skipped` não é salvo, então recarregar o jogo
  faria o bloco voltar. É o mesmo raciocínio de `tutorial_weeks_shown`.
- **Verificar:** entrar na casa pela primeira vez mostra o bloco; sair e
  voltar não repete; salvar/recarregar não repete.

### B2 — As mensagens novas

- **Arquivo:** `singletons/TutorialManager.gd`, array `messages`
- **⚠️ Append-only.** O array vai de 0 a 21 e os índices são referenciados um
  a um em `_next_step()`, `_resume_step()`, `_queue_office_intro()` e
  `_queue_world_tour()`. Inserir no meio quebra tudo. O array já tem o
  comentário avisando disso — as novas entram no fim, a partir de 22.
- **Conteúdo (5 mensagens):**

  1. **O que a casa é.** O único lugar onde você recupera o que o dia gasta, e
     o único lugar onde o dia termina.
  2. **O estoque.** Comida e bebida compradas no mercado **não** são
     consumidas na hora: elas ficam no estoque da casa e você usa quando
     precisa. Mencionar que o painel de estoque mostra fome e sede de cada
     item.
  3. **COMER e BEBER.** Cada botão escolhe automaticamente o item mais
     eficiente da categoria, gasta um pouco do dia (0,5 h comer / 0,25 h
     beber) e some do estoque. Comer também repõe um quarto do valor em
     stamina (`STAMINA_PER_FOOD_ENERGY`).
  4. **DESCANSAR e ASSISTIR TV.** Devolvem stamina e custam 1 h cada, mas
     **gastam fome** (-12 e -6). Servem para esticar o dia, não para
     substituir o sono.
  5. **DORMIR.** É o que encerra o dia: stamina volta a 100 e o relógio pula
     para 08:00. Antes das 18h o botão não deixa dormir; virar a noite custa
     R$ 30 de café e metade da stamina.

- **Verificar:** as 5 aparecem na ordem, o texto cabe no `ScrollContainer` do
  `AlertManager` (`TEXT_WIDTH 700 × TEXT_VISIBLE_HEIGHT 230`).

### B3 — A casa entra no tour do mundo

- **Arquivo:** `singletons/TutorialManager.gd`, `_queue_world_tour()`
- **Correção:** inserir a mensagem 22 (o que a casa é) logo antes de
  `messages[11]` (o mercado) — a ordem lógica é "você mora aqui, e compra ali".
  Só essa; as outras quatro ficam para a visita.
- **Cuidado:** o tour já tem 10 mensagens. Uma décima primeira é aceitável,
  mais que isso vira parede de texto. Se ficar longo, o candidato a sair é
  `messages[15]` ("agora é com você"), que é fechamento e não conteúdo.

### B4 — "Pular tutorial" marca a casa como vista

- **Arquivo:** `singletons/TutorialManager.gd`, `skip_tutorial()`
- **Problema:** a função já marca todas as semanas de `weekly_messages` como
  vistas justamente para não voltarem depois. A flag da casa precisa do mesmo
  tratamento, senão quem pulou o tutorial toma o bloco na cara ao entrar em
  casa.
- **Correção:** `Global.player["tutorial_home_shown"] = true`.

### B5 — Mensagem de sede *(depende da Fase A)*

- **Arquivo:** `singletons/TutorialManager.gd`
- **Correção:** uma sexta mensagem no bloco da casa, sobre sede: cai ~14 pontos
  por dia (mais rápido que fome), zera em game-over, e a coluna que importa é
  R$ por ponto reposto — água resolve por R$ 5 e cerveja pede R$ 50 pelo mesmo
  efeito de um quarto. É o mesmo raciocínio de necessidade x desejo do nível 1
  do escritório, agora com um medidor.
- **Também:** `messages[19]` ("cada item do mercado mostra quanto de fome ele
  repõe") fica desatualizada com a A2. Reescrever para citar os dois valores.
- **Verificar:** o texto bate com os números realmente implementados em A2/A4.

---

## Ordem de execução

```
A1 (estado + normalize)      <- a armadilha do thirst apagado mora aqui
  |
A2 (dados do mercado)
  |
A3 (consumo generalizado)  ->  A5 (barras)      podem ir em paralelo
  |                            A6 (migração)
A4 (decaimento/game-over)
  |
A7 (teste)
  |
B1 (gancho) -> B2 (mensagens) -> B3 (tour) -> B4 (skip) -> B5 (sede)
```

A Fase B roda inteira sem a Fase A, menos o B5. Se quiser o tutorial da casa
antes da sede, fazer B1-B4 primeiro e deixar B5 para depois de A4 — só cuidar
para as mensagens não citarem BEBER antes de o botão existir.

## Verificação final

- [ ] Três barras no mundo e três na casa, todas mexendo
- [ ] Água é a bebida mais eficiente por real; cerveja e vinho, as piores
- [ ] BEBER escolhe bebida, COMER escolhe comida, nenhum pega o do outro
- [ ] Save antigo com estoque: bebidas migradas e bebíveis
- [ ] 7 dias sem beber → um único alerta de game-over
- [ ] Primeira entrada na casa mostra o bloco; segunda não; reload não
- [ ] "Pular tutorial" não deixa o bloco da casa pendente
- [ ] `tests/test_mechanics.gd` passa
