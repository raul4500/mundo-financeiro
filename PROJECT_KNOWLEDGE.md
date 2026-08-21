# Mundo Financeiro – conhecimento do projeto

Este documento consolida o que foi aprendido sobre o projeto e serve como base de contexto para qualquer agente (Claude, Copilot, outros) continuar o desenvolvimento sem perder a arquitetura e a lógica do jogo.

## 1. Visão geral do projeto

O jogo é um simulador/educação financeira em Godot 4 com loop principal baseado em:

- movimentação no mapa
- interação com ambientes: casa, banco, mercado, escritório
- gerenciamento de dinheiro e gastos
- progresso por semanas
- objetivos/missões semanais
- investimentos em FIIs
- compra e administração de empreendimentos
- manutenção de fome e felicidade em casa
- persistência de save

O projeto usa autoloads (singletons) para manter estado global e lógica centralizada.

## 2. Estrutura principal do projeto

Arquivos centrais:

- `project.godot` — configuração principal e autoloads
- `singletons/Global.gd` — estado global do jogador
- `singletons/SaveManager.gd` — salvamento e carregamento
- `singletons/TimeManager.gd` — tempo do jogo
- `singletons/MissionManager.gd` — missões semanais
- `singletons/FIIManager.gd` — gestão de FIIs
- `singletons/EnterpriseManager.gd` — compra, estoque, equipamentos, contas e operação dos empreendimentos
- `singletons/Logger.gd` — log de runtime
- `scripts/world/home/home.gd` — cena da casa do jogador
- `scripts/world/market/market.gd` — mercado e compras
- `scripts/world/bank/banco.gd` — banco e histórico de despesas
- `scripts/world/office/office.gd` — navegador de conteúdo educacional (níveis/tópicos); a progressão de `school_level`/salário vem do minigame (`scripts/minigame/level.gd`), não do escritório
- `scripts/world/main_game.gd` — fluxo principal do mapa
- `scripts/enterprise/enterprise_management.gd` — interface única de administração dos empreendimentos
- `scripts/enterprise/data/restaurant_info.gd` — dados do restaurante pequeno
- `scripts/enterprise/data/arcade_info.gd` — dados do fliperama médio
- `scripts/enterprise/data/shopping_info.gd` — dados do centro comercial grande
- `scenes/world/ui/enterprise-view.tscn` — cena base com o layout fixo da administração de empreendimentos
- `scenes/world/places/restaurant.tscn` — cena de administração do restaurante (herda de `enterprise-view.tscn`)
- `scenes/world/places/arcade.tscn` — cena de administração do fliperama (herda de `enterprise-view.tscn`)
- `scenes/world/places/shopping.tscn` — cena de administração do centro comercial (herda de `enterprise-view.tscn`)
- `scenes/world/places/home.tscn` — layout fixo da casa, usado como âncora por `home.gd`

## 3. Arquitetura e padrão do projeto

### 3.1 Autoloads

Em `project.godot`, vários nodes ficam automaticamente disponíveis globalmente. Os principais são:

- `Global` — estado do jogador e sistema de economia/necessidades
- `SaveManager` — serialização da save
- `TimeManager` — avanço de tempo/dia/semana
- `MissionManager` — validação de missões
- `FIIManager` — compra/venda de FIIs
- `EnterpriseManager` — regras compartilhadas dos três empreendimentos
- `Logger` — grava logs de runtime em arquivo
- `EventsManager` — sorteia e dispara eventos inesperados (dados vêm de `UnexpectedEvents`, que serve só como fonte de dados, não como sistema ativo)
- `TutorialManager` — roteiro do onboarding (mensagens, passos, pular tutorial)
- `AlertManager` — `CanvasLayer` de alerta modal, compartilhado por todo o jogo
- `CameraManager` — cutscenes de câmera
- `DoorManager` — utilitário de portas

Esse padrão centraliza dados do jogo e evita acoplamento excessivo entre cenas.

**Ordem importa.** `Logger` é o primeiro autoload da lista em `project.godot`, porque vários singletons registram log no próprio `_ready()`. `UnexpectedEvents` vem antes de `EventsManager`, que lê os dados dele na inicialização. `Global` vem antes de `EnterpriseManager` e `FIIManager`, que dependem de `Global.player`.

### 3.2 Trava de gameplay (`gameplay_locked`)

`Global.gameplay_locked` é derivado de um **contador** (`_gameplay_lock_count`), não de um booleano solto. Quem precisa travar o jogador chama `Global.lock_gameplay()` e, ao terminar, `Global.unlock_gameplay()`.

Isso existe porque `AlertManager` e `CameraManager` podem travar o gameplay ao mesmo tempo (um alerta de tutorial durante uma cutscene). Com booleano simples, o primeiro a terminar destravava o jogador no meio da ação do outro.

Nunca atribua `Global.gameplay_locked = true/false` diretamente — use as duas funções, sempre em par.

> Pendência conhecida: `Global.play_time` ainda é um booleano sem contador e é escrito direto por `AlertManager` e por `enterprise_door.gd`. Sofre do mesmo problema que `gameplay_locked` já resolveu.

### 3.3 Alertas e tutorial

`AlertManager` é um `CanvasLayer` autoload com `layer = 100`. A layer alta é obrigatória: autoloads entram na árvore **antes** da cena atual, então qualquer `CanvasLayer` da cena (HUD, missões, pause) ficaria por cima do alerta e roubaria os cliques.

Estrutura do alerta, montada em `_create_alert_ui()`:

- `blocker` — `ColorRect` em tela cheia, preto a 10%, com `MOUSE_FILTER_STOP`;
- `panel` — `Control` transparente em tela cheia (não é `Panel`: um `Panel` full-rect pintaria por cima de tudo e esconderia o overlay);
- `dialog` — `Panel` central com `font_theme.tres`, contendo o texto (`label.tres`) e o botão OK;
- `skip_button` — botão "Pular tutorial" ancorado no canto superior direito, visível apenas quando `TutorialManager.can_skip()` é verdadeiro.

Os botões usam `focus_mode = FOCUS_NONE` de propósito. Um botão com foco é acionado pela ação `ui_accept`, que inclui **Enter** por padrão — e o atalho de confirmação do alerta deve ser somente a barra de espaço, tratada manualmente em `_input()` com `set_input_as_handled()`.

`TutorialManager.skip_tutorial()` marca `skipped`, limpa a fila de mensagens e pula `step` e `tutorial_step` para `FINAL_STEP`. O botão de pular só aparece na primeira mensagem (`can_skip()` exige `step == 1`).

O roteiro tem 20 mensagens em `messages` e 8 passos em `_next_step()`. O passo 8 enfileira a cauda inteira (`messages[7]` a `messages[19]`), que inclui o bloco dos empreendimentos (`messages[12]` a `messages[17]`): aviso de conteúdo avançado, mecânica comum a todo negócio, um resumo de cada um dos três empreendimentos com preço e contas semanais reais, e o aviso de que o nível 5 do escritório é pré-requisito prático. **Os números dessas mensagens são copiados dos arquivos em `scripts/enterprise/data/`** — ao mexer em `purchase_price`, `water_bill`, `electricity_bill`, `starting_capacity`, `employee_salary` ou `upgrade_costs`, atualize o texto do tutorial junto, senão ele passa a ensinar valores errados.

### 3.4 Layout na cena, conteúdo no script

Padrão adotado para as interfaces do jogo: **a cena `.tscn` é a fonte de verdade do layout; o script é a fonte de verdade do conteúdo.**

O script captura os nodos fixos com `@onready` e só cria/limpa os filhos dinâmicos dentro dos containers que já existem. Nunca recria painéis, containers de seção ou labels de cabeçalho.

Já seguem esse padrão:

- `scripts/world/home/home.gd` sobre `scenes/world/places/home.tscn`;
- `scripts/enterprise/enterprise_management.gd` sobre `scenes/world/ui/enterprise-view.tscn`.

Ainda constroem a interface inteira por script (candidatos ao mesmo tratamento): `banco.gd`, `market.gd`, `office.gd`, `AlertManager.gd`.

### 3.5 Armadilha de largura: `Label` sem autowrap

Esta causou um bug real na tela dos empreendimentos e provavelmente afeta as telas que ainda montam UI por script.

Um `Label` **sem** `autowrap_mode` reporta como largura mínima a largura do **texto inteiro em uma linha**. Ele se recusa a encolher. E quando os filhos de um `Container` do Godot somam mais que o espaço disponível, o container **não comprime ninguém — ele transborda**, empurrando os últimos filhos para fora da tela.

Foi o que aconteceu: quatro painéis em um `HBoxContainer` de 1034 px exigiam ~1844 px de mínimo, porque as linhas de estoque/contas/equipamentos tinham labels sem autowrap. Contas e Equipamentos ficaram inteiramente fora da tela, o que parecia "zoom da câmera".

Regras que saíram disso:

- todo `Label` de conteúdo variável recebe `autowrap_mode = TextServer.AUTOWRAP_WORD` (com autowrap, a largura mínima cai para a da palavra mais longa). Em `enterprise_management.gd` isso está centralizado em `_make_row_label()`;
- ao colocar conteúdo dentro de um `ScrollContainer`, defina `horizontal_scroll_mode = 0`. Com o scroll horizontal habilitado, o Godot dá ao filho a largura mínima que ele pedir e mostra uma barra lateral, em vez de deixar o texto quebrar;
- o viewport base é **1152×648** (`[display]` do `project.godot` não define `viewport_width`, então vale o padrão). Faça a conta de largura disponível antes de dividir a tela em colunas.

### 3.6 Regra de ouro do estado

O estado principal do jogador fica em `Global.player`, que é um dicionário com todas as propriedades fundamentais. Qualquer lógica que dependa do jogador deve preferencialmente ler/escrever em `Global.player` em vez de variáveis locais em cena.

Isso garante:

- persistência consistente
- sincronização entre telas
- compatibilidade com save/load
- manutenção mais fácil do código

### 3.7 Painéis das portas (UI em espaço de mundo)

Cada uma das 8 portas de `scenes/world/main_game.tscn` tem um filho `Info-panel` com o nome do lugar, uma descrição curta e a dica "Pressione ENTER para entrar". O painel nasce com `visible = false` na cena e o script da porta o mostra em `_on_body_shape_entered` e o esconde em `_on_body_shape_exited`.

Estrutura, igual nas 8 portas:

```
<Nome>_door (Area2D)
├── CollisionShape2D
└── Info-panel (Panel, visible = false, z_index = 100, scale = 0.333333)
    └── Margin (MarginContainer 22/16/22/16, full rect)
        └── VBoxContainer (separation 6)
            ├── Title       (font_size 20)
            ├── Description (font_size 14, expand vertical)
            └── Hint        (font_size 13, cor azulada)
```

O painel é centralizado na `CollisionShape2D` da porta: `offset_left = shape.position.x - 70` e `offset_top = shape.position.y - 22`, com tamanho local 420×132.

**Por que `scale = 0.333333`.** A câmera do jogador tem `zoom = Vector2(3, 3)`, então a área visível do mundo é de apenas 384×216 unidades. Um painel de 420 unidades de largura ocuparia mais de uma tela inteira. Como `1/3 × 3 = 1`, a escala de 1/3 faz o painel ocupar 140×44 unidades de mundo e ainda assim renderizar exatamente 420×132 pixels no viewport — ou seja, as fontes são desenhadas em escala 1:1 e ficam nítidas, sem o borrão de texto pequeno esticado pelo zoom.

Consequências práticas:

- os `font_size` do painel são valores normais de UI (20/14/13), não unidades de mundo. Não os reduza "para caber": quem controla o tamanho na tela é a escala;
- se mudar o `zoom` da câmera em `scenes/players/player.tscn`, a escala dos 8 painéis precisa virar `1/zoom` para o texto continuar nítido;
- `pivot_offset` fica em (0,0), então a escala é aplicada a partir do canto superior esquerdo. É isso que faz a conta de centralização (`- 70`, `- 22`) funcionar;
- `z_index = 100` é obrigatório: o nó `Doors` vem antes de `Light-poles` na cena, então sem isso os postes de luz desenhariam por cima do painel.

`enterprise_door.gd` resolve os nós com `get_node_or_null()` dentro de `_ready()`, e **não** com `@onready`, porque é a classe base de `restaurant_door.gd`, `arcade_door.gd` e `shopping_door.gd`, que sobrescrevem `_ready()`. Ele também troca o texto do `Hint` conforme a posse: "Pressione ENTER para entrar" para quem já é dono, "Pressione ENTER para ver a proposta" para quem ainda não comprou. O painel é escondido enquanto o diálogo de compra está aberto e volta se o jogador ainda estiver na porta.

Os `Label` antigos dessas portas (`Minigame`, `Market`, `Bank`) foram removidos da cena, porque o painel já mostra o nome do lugar. As referências `$Minigame` / `$Market` / `$Bank` saíram dos scripts junto — se voltarem a aparecer, é sinal de que alguém restaurou uma versão antiga.

## 4. Modelo do jogador (Global.player)

O `Global.gd` define um `data_model` com os campos principais:

- `name`: nome do jogador
- `money`: dinheiro disponível
- `saldo`: saldo líquido/financeiro cumulativo
- `week`: semana atual
- `salary`: salário
- `school_level`: evolução educacional / nível
- `position`: posição do personagem no mundo
- `day`: dia atual
- `hour`: hora atual
- `tutorial_step`: etapa do tutorial
- `investments`: estado de investimentos
- `enterprises`: estado persistente dos empreendimentos comprados
- `expense_history`: histórico de gastos
- `spend_today`: gasto do dia
- `positive_days_count`: quantidade de dias positivos
- `hunger`: fome, de 0 a 100
- `happiness`: felicidade, de 0 a 100
- `home_inventory`: estoque da casa
- `home_actions_log`: registro de ações da casa
- `last_week_status`: status final da semana

### Estado dos empreendimentos

`Global.player["enterprises"]` contém um registro para cada negócio disponível:

- `restaurant_small`
- `arcade_medium`
- `shopping_large`

Cada registro mantém:

- `owned`: se o jogador comprou o negócio;
- `level`: nível de aprimoramento (1 a `max_level`, sobe via `upgrade_level()`);
- `employees`: número de funcionários contratados;
- `cash_balance`: lucro acumulado do caixa empresarial;
- `stock`: quantidade de cada item de estoque;
- `equipment`: equipamentos comprados;
- `pending_bills`: contas de água e luz pendentes;
- `daily_revenue` e `daily_expenses`: valores da última operação;
- `total_revenue`, `total_expenses` e `total_profit`: contabilidade acumulada;
- `last_operation_day` e `last_operation_week`: proteção contra processamento duplicado;
- `history`: histórico de compras, contas e operações, limitado às últimas `EnterpriseManager.MAX_HISTORY_ENTRIES` (50) entradas para o save não crescer sem limite. Toda escrita passa por `_append_history()`, que é o único ponto que mexe nessa lista.

### Funções importantes de Global

- `ensure_player_state()`
  - garante que o dicionário do jogador exista e tenha chaves mínimas
  - normaliza tipos e valores
  - ajusta `hunger` e `happiness` para limites válidos

- `new_game(name, money)`
  - reinicializa o save
  - cria o estado inicial do jogador
  - envia para o mapa principal

- `load_data()`
  - carrega save do arquivo de savegame
  - valida o dicionário antes de usar

- `register_expense(item_name, category, price, day, week)`
  - grava gastos no histórico
  - soma no gasto diário

- `add_home_inventory_item(item_name, quantity, category)`
  - adiciona item ao estoque da casa
  - calcula energia e felicidade do item de acordo com o tipo e preço

- `get_home_inventory_items()`
  - retorna lista de itens do estoque com quantidade > 0

- `consume_food()`
  - escolhe a melhor comida disponível no estoque
  - remove 1 unidade
  - aumenta fome e felicidade do jogador
  - registra no log da casa

- `apply_home_action(action_name, hunger_delta, happiness_delta, time_cost)`
  - aplica ação em casa como descansar e assistir TV
  - muda `hunger` e `happiness`
  - grava no histórico de ações

- `decay_need_state()`
  - descarrega fome e felicidade ao longo do tempo
  - se fome/felicidade estiverem baixos, efeitos colaterais ocorrem

- `evaluate_week_status()`
  - avalia o bem-estar da semana
  - aplica penalidade financeira em semanas muito ruins
  - salva `last_week_status`

### Sistema de estoque da casa

A lógica de casa usa um inventário em dicionário:

```gdscript
player["home_inventory"] = {
  "hamburger": {
    "name": "hamburger",
    "quantity": 2,
    "category": "food",
    "energy": 26.0,
    "happiness": 12.0
  }
}
```

Regra importante:

- o item comprado no mercado entra no estoque da casa
- a comida só pode ser consumida se houver quantidade > 0
- a energia depende do nome do item e do preço
- a felicidade também varia de acordo com a qualidade e tipo do alimento

## 5. Sistema de tempo e ciclo de jogo

`TimeManager.gd` controla a passagem do tempo.

### Estrutura

- `current_day`, `current_hour`, `current_minute`
- `time_scale` controla velocidade do tempo do jogo
- `_process(delta)` avança o relógio quando `Global.play_time` é verdadeiro

### Fluxo de avanço

Quando o tempo passa:

1. aumenta minuto
2. se passar de 60 minutos, avança uma hora
3. se passar de 24 horas, avança um dia
4. ao completar um dia:
   - `Global.decay_need_state()` é chamado
   - `positive_days_count` cresce
5. ao completar semana (7 dias):
   - `Global.evaluate_week_status()` é chamado
   - as missões da semana são avaliadas
   - se aprovadas, o jogador recebe pagamento da semana e avança a semana

### Observação importante

No projeto atual, o tempo e a progressão estão semiconscientes e dependem do `play_time`, que precisa estar ativo no contexto correto do jogo para que o ciclo passe a se mover.

## 6. Sistema de missões semestrais / semanais

`MissionManager.gd` define missões por semana usando `missions_data`.

### Exemplo de missões

- `economizar_100`, `economizar_300`, `economizar_500`
- `sem_gastar`
- `registrar_gastos`
- `no_impulse`
- `invest`
- `analyze`
- `diversify`
- `profit`
- `portfolio`
- `positive_days`

### Lógica da validação

`verify_missions(week)`:

- pega a lista de missões da semana
- verifica cada uma com `_check_mission`
- se falhar, chama `_game_over()`
- se todas forem concluídas, avança semana

### Regras reais implementadas

Exemplos:

- `money_min`: jogador precisa ter dinheiro mínimo
- `no_spend_day`: não pode haver gasto no dia
- `log_expense`: precisa registrar pelos menos um gasto
- `invest`: carteira de FIIs precisa ter valor > 0
- `positive_days`: precisar ter pelo menos N dias positivos
- `profit`: usa `FIIManager.get_profit()` (valor da carteira + dividendos recebidos − total aportado). Antes olhava `player["saldo"]`, que só muda por depósito/saque no banco — dava para cumprir a missão "Ganhe R$200 com investimentos" sem nunca comprar um FII
- `diversify`: precisa ter mais de um fundo na carteira

## 7. Sistema de FIIs

`FIIManager.gd` original foi pensado para controlar:

- lista de fundos disponíveis
- preço de cada fundo
- volatilidade
- carteira do jogador
- compra e venda de cotas
- dividendos

### Fundos base presentes

- `FII_SHOPPING`
- `FII_LAJES`
- `FII_LOGISTICA`

### Dados do fundo

Cada fundo tem:

- `name`
- `price`
- `dividend_yield`
- `volatility`

### Lógica principal

- `update_prices()` altera preços com variação aleatória
- `buy_fund(fund_id, amount)` compra cotas
- `sell_fund(fund_id, amount)` vende cotas
- `pay_dividends()` soma `preço * dividend_yield * quantidade` de cada fundo ao dinheiro do jogador (não dobra nada); é chamado automaticamente pelo `TimeManager` ao fechar cada semana
- `get_portfolio_value()` retorna valor total da carteira
- `save_data()` salva carteira + fundos em `Global.player["investments"]`
- `load_data()` recarrega os dados do save

### Importante

A lógica de FIIs deve sempre usar `Global.player["money"]` como fonte da economia real do jogador.

## 8. Sistema de save/load

`SaveManager.gd` é o responsável por salvar o jogo em `user://savegame.json`.

### Funcionalidades

- `save_game()`
  - duplica o estado do jogador
  - converte para JSON
  - salva em arquivo

- `load_game()`
  - lê o arquivo de save
  - faz `JSON.parse_string`
  - retorna dicionário se válido

- `delete_save(caminho)`
  - remove o save

- `save_timer` e `save_interval`
  - salvamento periódico automático

### Observações

- `SaveManager` também salva dados de FIIs usando `FIIManager.save_data()`
- o save deve sempre respeitar o formato do `Global.player`
- a rotina de load deve sempre chamar `ensure_player_state()` depois de ler o save

## 9. Sistema de logger

`Logger.gd` foi implementado para registrar runtime e facilitar debugging:

- `log_info()`
- `log_warning()`
- `log_error()`

Ele escreve em arquivo em `logs/game_runtime.log`, criando pastas quando necessário. Pode servir como diagnóstico visual depois de rodar o jogo em ambiente real.

## 10. Sistema de casa do jogador

`scripts/world/home/home.gd` controla a casa do jogador, ancorado no layout fixo de `scenes/world/places/home.tscn` (ver seção 3.4).

### Nodos fixos usados pelo script

Capturados com `@onready`, todos definidos no editor:

- `Money-label` e `Time-label` — dinheiro e dia/semana no topo;
- `HBoxContainer/Actions/VBoxContainer` — container **vazio** na cena, preenchido em runtime com os botões Comer, Descansar e Assistir TV;
- `.../Hunger-container/ProgressBar` e `.../Happiness-container/ProgressBar` — as barras usam `show_percentage`, então não existem labels separados de porcentagem;
- `.../status-message` — mensagem de retorno das ações;
- `Inventory-scroll` e `History-scroll` — recebem um `VBoxContainer` criado em runtime para as linhas;
- `Exit` — botão fixo da cena, conectado por código (a cena não tem seção `[connection]`);
- `Node2D` — âncora **vazia** onde `_build_character()` instancia o sprite do personagem em runtime.

### Sprite do personagem na casa

A cena tinha um `raul.tscn` fixo dentro do `Node2D`, o que mostrava o Raul mesmo para quem escolheu outro personagem. Agora `_build_character()` lê `Global.player["name"]`, carrega a cena correspondente e a instancia no `Node2D`, reproduzindo exatamente a transformação do sprite de exemplo que foi removido:

```gdscript
const CHARACTER_POSITION = Vector2(458, 405)
const CHARACTER_SCALE = Vector2(17, 17.911)
const CHARACTER_ANIMATION = "default"
```

Esses três valores **são o contrato visual**: se o sprite sair de lugar na casa, é aqui que se ajusta, não na cena. Os cinco personagens (`raul`, `matheus`, `phillip`, `melissa`, `enzo`) têm raiz `AnimatedSprite2D` e as animações `default`, `down`, `up` e `walk`, com `autoplay = "default"` — mas o script chama `play("default")` explicitamente para não depender disso.

> Duplicação conhecida: o mapa nome → cena (`CHARACTER_SCENES`) agora existe em três lugares — `home.gd`, `scripts/player/player.gd` e `scripts/player/raul_minigame.gd`. Um personagem novo precisa ser adicionado nos três. Candidato a virar uma constante única em `Global`.

### Funções principais

- `_build_ui()` — só cria o que é dinâmico: botões de ação e os containers de lista dentro dos scrolls
- `_update_ui()` — atualiza status da UI
- `_render_inventory()` — exibe estoque
- `_render_history()` — exibe histórico de ações (últimas 10)
- `_on_eat_pressed()` — chama `Global.consume_food()`
- `_on_rest_pressed()` — chama `Global.apply_home_action("rest", -12.0, 18.0, 1.0)`
- `_on_tv_pressed()` — chama `Global.apply_home_action("watch_tv", -6.0, 14.0, 1.0)`
- `_on_exit_pressed()` — volta para o mapa principal

### Papel da casa no gameplay

A casa funciona como loop de manutenção da vida do personagem:

- comer reduz fome
- descansar aumenta felicidade e reduz fome
- assistir TV aumenta felicidade, mas também reduz fome
- o jogador precisa gerenciar estoque para sobreviver
- ações são registradas no log da casa

### Sistema de necessidade

O jogador começa com:

- fome: 100
- felicidade: 100

Durante o tempo, ambos descem. Se o jogador não comer ou não investir em descanso/atividades, sua saúde e humor caem, influenciando a semana.

## 11. Sistema de mercado

`scripts/world/market/market.gd` representa o mercado.

### Regra de compra

O mercado tem um **carrinho real**. Nada é debitado ao adicionar um item — só ao finalizar.

1. `_on_buy_item()` apenas acrescenta o item ao array `cart` e desenha a linha no carrinho, com um botão "X" conectado a `_on_remove_from_cart()`
2. `_on_remove_from_cart()` remove o item do array, subtrai do total e apaga a linha
3. `_on_clean_kart_pressed()` esvazia o carrinho inteiro
4. `_on_finish_pressed()` valida o dinheiro contra o **total** e só então, para cada item: debita `Global.player["money"]`, registra em `expense_history` e chama `Global.add_home_inventory_item()`

Antes o débito acontecia no "Adicionar" e o botão "X" não estava conectado a nada — o carrinho era decorativo e não havia como cancelar uma compra.

### Itens do mercado

O mercado usa uma estrutura de categorias:

- `foods`
- `drinks`
- `home`
- `tools`
- `electronics`

Cada item tem um preço e pode ser adicionado ao inventário doméstico.

## 12. Sistema bancário

`scripts/world/bank/banco.gd` é o ambiente do banco.

Seu papel inclui:

- mostrar dinheiro do jogador
- manter painel de histórico financeiro
- exibir despesas e registros do dia
- funcionar como fonte visual do registro de gastos

Histórico de gastos é representado em `Global.player["expense_history"]` e pode ser renderizado com `VBoxContainer`/`ScrollContainer`.

## 13. Fluxo do jogo em alto nível

Ciclo típico:

1. inicia o jogo / cria novo save
2. carrega dados gerais do jogador
3. o mapa principal é aberto
4. o jogador se move entre locais
5. compra itens no mercado ou interage com banco/empresa
6. retorna para casa quando necessário
7. come, descansa, assiste TV
8. o tempo passa e fome/felicidade decaem
9. o jogador precisa manter o estado vivo e controlar gastos
10. a semana termina e missões são avaliadas
11. progresso financeiro e da jornada continua

## 14. Sistema de empreendimentos

O jogo possui três empreendimentos com faixas de investimento distintas:

| ID | Negócio | Tamanho | Preço de compra |
|---|---|---|---:|
| `restaurant_small` | Restaurante Sabor da Praça | pequeno | R$ 1.500,00 |
| `arcade_medium` | Fliperama Neon | médio | R$ 12.000,00 |
| `shopping_large` | Centro Comercial Mundo Mix | grande | R$ 85.000,00 |

As cenas dos empreendimentos e as portas que as conectam ao mapa principal já existem. `scripts/world/doors/enterprise_door.gd` é a porta base: se o negócio já foi comprado ela troca de cena, senão abre um diálogo de compra. As três portas concretas (`restaurant_door.gd`, `arcade_door.gd`, `shopping_door.gd`) herdam dela e só definem `enterprise_id` e `destination_scene`.

### Dados separados por negócio

Os arquivos de dados retornam Dictionaries com preço de compra, receita, despesas, contas, capacidade, estoque e equipamentos específicos:

- `scripts/enterprise/data/restaurant_info.gd`;
- `scripts/enterprise/data/arcade_info.gd`;
- `scripts/enterprise/data/shopping_info.gd`.

A interface e as regras não devem ser duplicadas para cada negócio. Novos empreendimentos devem fornecer apenas um novo catálogo de dados e uma cena configurada com outro ID.

### EnterpriseManager

`singletons/EnterpriseManager.gd` é um autoload que concentra as regras comuns dos três empreendimentos. A interface chama o manager usando o `enterprise_id`.

Funções principais:

- `can_buy()` e `buy_enterprise()`;
- `get_upgrade_cost()` e `upgrade_level()`;
- `hire_employee()`, `fire_employee()` e `get_weekly_payroll()`;
- `buy_stock()`;
- `buy_equipment()`;
- `generate_weekly_bills()`;
- `get_pending_bills()`, `get_overdue_bills()`, `has_overdue_bills()` e `pay_bill()`;
- `get_status()` — `ok`, `warning`, `closed` ou `not_owned`;
- `calculate_daily_revenue()` e `get_revenue_ceiling()`;
- `calculate_daily_expenses()`;
- `calculate_daily_profit()`;
- `process_daily_operation()`;
- `get_dashboard_data()`.

As operações retornam Dictionaries com `success`, `message`, `reason` e valores financeiros relevantes. Falhas emitem o signal `enterprise_error`.

### Nível e aprimoramento

O nível começa em 1 na compra e sobe apenas por investimento, via `upgrade_level()`. Os custos ficam em `upgrade_costs` (um valor por nível a partir do 2) em cada arquivo de dados.

O nível tem dois efeitos: multiplica a receita base (`1.0`, `1.2`, `1.45`, `1.75`, `2.15`) e libera equipamentos com `level_required` maior. Sem aprimoramento, os equipamentos de nível 2 e 3 são inalcançáveis.

### Funcionários

Cada negócio define `employee_salary` (semanal), `employee_revenue_bonus` (diário), `employee_capacity_bonus` e `max_employees`.

Contratar não cobra nada na hora: o salário entra como a conta `payroll_<semana>` no fechamento da semana, junto de água e luz. É a mecânica que ensina custo fixo.

### Capacidade e teto de receita

`get_revenue_ceiling()` = capacidade × `revenue_per_capacity`. A receita diária é limitada por esse teto **antes** da penalidade de inadimplência.

A capacidade vem de `starting_capacity` + bônus de equipamentos + funcionários. Isso faz bônus de receita sem estrutura serem desperdiçados — o gargalo é intencional e didático.

### Inadimplência

Toda conta nasce com `due_week = week + 1`, dando ao jogador a semana seguinte inteira para pagar. Passado o prazo, ela conta como atraso e a receita diária do negócio cai 25% enquanto existir qualquer conta vencida. A conta não desaparece: continua pendente e acumula com as das semanas seguintes.

### Compra de estoque

O estoque é comprado por lote. Cada item informa preço, unidades recebidas, consumo e bônus de receita.

No restaurante:

- ingredientes básicos: R$ 80,00 por lote;
- bebidas: R$ 45,00 por lote;
- itens de limpeza: R$ 35,00 por lote.

Os preços aparecem na lista e também nos botões de compra. O estoque é consumido durante a operação diária. Sem estoque, o negócio continua com receita reduzida.

### Equipamentos

Equipamentos aumentam receita e capacidade, mas podem gerar manutenção. No restaurante:

- fogão industrial: R$ 350,00;
- geladeira maior: R$ 600,00;
- mesas confortáveis: R$ 900,00.

Cada equipamento pode exigir nível mínimo e não pode ser comprado duas vezes.

### Operação financeira

Ao passar um dia, `TimeManager` chama `EnterpriseManager.process_all_daily_operations()`.

Para cada empreendimento comprado, o manager calcula receita, calcula despesas, consome estoque, registra os totais, atualiza o caixa, adiciona o lucro ao dinheiro do jogador e grava a operação no histórico.

`last_operation_day` e `last_operation_week` impedem que a mesma operação seja processada duas vezes no mesmo dia.

### Contas semanais

No fechamento da semana, o manager gera contas de água e luz para cada empreendimento comprado. As contas ficam em `pending_bills` até serem pagas.

A chave da conta inclui o número da semana (`water_3`, `electricity_3`), então **contas não pagas de semanas anteriores continuam pendentes e acumulam** em vez de serem sobrescritas pelas da semana seguinte.

O pagamento reduz `Global.player["money"]`, **remove a conta de `pending_bills`**, atualiza despesas e lucro, registra a saída em `expense_history` com categoria `enterprise_bill` e atualiza a interface. `get_pending_bills()` retorna apenas contas em aberto.

### Interface compartilhada

O layout fica em `scenes/world/ui/enterprise-view.tscn`. As cenas `restaurant.tscn`, `arcade.tscn` e `shopping.tscn` **herdam** dessa cena base — cada uma tem 7 linhas: herda o layout, anexa `enterprise_management.gd` e define o `enterprise_id`. Editar a cena base propaga para os três negócios.

Árvore da cena base:

```text
EnterpriseView (Control)
└── Margin (MarginContainer 32/24/32/24)
    └── VBoxContainer (separation 12)
        ├── Business-panel (PanelContainer, font_theme, expand vertical, stretch_ratio 0.6)
        │   └── VBoxContainer (separation 8)
        │       ├── Title-label   (font_size 28)
        │       ├── Status-label  (font_size 18, cor por situação)
        │       ├── Stats-grid (GridContainer, columns = 3, h_sep 24, v_sep 6)
        │       │   ├── Money-label     ├── Revenue-label  ├── Expenses-label
        │       │   ├── Profit-label    ├── Capacity-label ├── Ceiling-label
        │       │   └── Bills-label     └── Payroll-label  └── Total-profit-label
        │       └── Message-label (resultado da última operação)
        ├── Sections (TabContainer, font_theme, expand vertical)
        │   ├── Negócio      (ScrollContainer) → Business-list
        │   ├── Estoque      (ScrollContainer) → Stock-list
        │   ├── Contas       (ScrollContainer) → Bills-list
        │   └── Equipamentos (ScrollContainer) → Equipment-list
        └── Exit-button (font_theme)
```

**As seções são abas, não cards.** Antes eram quatro `PanelContainer` em um grid 2×2, todos visíveis. Agora é um `TabContainer` e só uma seção aparece por vez. Três consequências:

- **o nome do nó da aba é o título que o jogador lê** — é assim que o `TabContainer` funciona. Por isso as abas se chamam `Negócio`, `Estoque`, `Contas` e `Equipamentos`, com acento. Renomear uma aba muda o texto na tela **e** o caminho no script;
- o `Label` de título dentro de cada seção foi removido: a barra de abas já cumpre esse papel. O `PanelContainer` de cada seção também saiu, porque o `TabContainer` desenha o próprio fundo. Cada aba é diretamente um `ScrollContainer` (com `horizontal_scroll_mode = 0`) contendo o `*-list`;
- `_refresh_ui()` só mexe no conteúdo dos `*-list`, nunca no `TabContainer`. Isso é intencional: a aba seguidamente selecionada continua selecionada depois de comprar estoque ou pagar conta.

O `font_theme.tres` já traz os estilos de `TabContainer` (`panel`, `tab_selected`, `tab_unselected`, `tab_focus` e as cores de fonte selecionada/não selecionada), então a barra de abas segue o visual pixel-art do resto da tela.

Os quatro `ScrollContainer` (com `horizontal_scroll_mode = 0`) garantem que nem a largura nem a altura possam transbordar — o texto quebra e a aba rola.

**Os nomes dos nós são o contrato com o script, e esse contrato já quebrou três vezes** — sempre com o mesmo sintoma: `Node not found` no `@implicit_ready()` e, em seguida, `Invalid assignment of property 'text' ... on a base object of type 'null instance'` em `_refresh_ui()`. As quebras foram: os labels de cabeçalho ganharem um pai (`Margin/VBoxContainer/` → `.../Panel/`), esse pai ser renomeado para `Business-panel`, e as seções virarem abas.

Por isso o script não usa mais `$"caminho"` direto. Todos os nós passam por `_find(path)`, que tenta o caminho esperado e, se falhar, procura o nó **pelo nome na árvore inteira** (`find_child(nome, true, false)`), avisando no console qual caminho atualizar. Reorganizar o layout agora degrada para um aviso em vez de derrubar a tela — desde que os nomes de folha (`Money-label`, `Business-list`, …) continuem únicos.

Convenção de tema da tela: **painéis usam `font_theme.tres`, labels usam `label.tres`**. Isso importa porque `Sections` carrega `font_theme.tres`, cujo `Label/styles/normal` é `label_round.png` e cujo corpo é 24 — e o tema propaga para os descendentes. Sem isso, cada linha criada em runtime viria com fundo de caixa arredondada e fonte gigante. Por isso `_make_row_label()` aplica `label.tres` e reduz o corpo para 16.

**Um label por indicador.** O cabeçalho já teve um `Summary-label` e um `Status-label` com todos os números concatenados por `|`. Foram quebrados em nove labels dentro de `Stats-grid` (3 colunas × 3 linhas): dinheiro, receita diária, despesas diárias, lucro estimado, capacidade, teto de receita, contas pendentes, folha semanal e lucro acumulado. `Status-label` ficou só com a frase da situação, e `Message-label` recebe o resultado da última operação.

`Message-label` existe porque `_show_result()` escrevia a mensagem no `status_label` **antes** de chamar `_refresh_ui()`, que a sobrescrevia no mesmo frame — a mensagem nunca aparecia. Agora a ordem é invertida e o destino é outro label.

**Lembrete de `PanelContainer`:** ele chama `fit_child_in_rect()` com o **mesmo retângulo para todos os filhos**, porque foi feito para receber um único filho. Os três labels já ficaram empilhados um sobre o outro por estarem direto sob o `Business-panel`. Por isso existe o `VBoxContainer` no meio — não o remova.

**Fixo na cena:** painéis, labels de cabeçalho, títulos de seção e o botão Voltar.

**Dinâmico no script**, sempre dentro dos quatro `*-list`:

- `_render_business()` — linha de aprimoramento de nível e linha de funcionários (contratar/demitir);
- `_render_stock()` — nome, preço por lote, quantidade atual e botão de compra;
- `_render_bills()` — contas pendentes e botão de pagamento;
- `_render_equipment()` — equipamentos, preço e estado de compra.

`_clear_list()` faz `remove_child()` antes do `queue_free()`. Sem isso, dois `_refresh_ui()` no mesmo frame duplicariam as linhas, porque `queue_free()` só libera no fim do frame.

### Conteúdo educativo correspondente no escritório

O nível 5 do escritório (`scripts/world/office/office.gd`) ensina **exatamente** as mecânicas acima, com os números reais dos arquivos de dados. São 11 tópicos: escolher e comprar o negócio, cálculo do lucro diário, estoque como capital de giro, custos fixos x variáveis, inadimplência, payback de equipamentos, gargalo de capacidade, folha de pagamento, aprimoramento de nível, ponto de equilíbrio e quando escalar.

Esse acoplamento é intencional e precisa ser mantido: **ao mudar um valor de balanceamento em `*_info.gd` ou uma regra no `EnterpriseManager`, confira se algum tópico do nível 5 cita aquele número.** Conteúdo educativo com número errado é pior que conteúdo ausente.

Exemplos de números hoje citados no escritório: preço dos três negócios, queda a 35% sem estoque, penalidade de 25% por inadimplência, payback do fogão (R$ 350 ÷ (R$ 18 − R$ 8) = 35 dias), teto de receita do restaurante (capacidade 10 × `revenue_per_capacity` 10 = R$ 100/dia), salário e bônus de funcionário, multiplicadores de nível e as contas semanais do shopping (R$ 1.550).

O escritório libera um nível por semana (`player_level = Global.player["week"]`), então o nível 5 só fica acessível na semana 5.

### Alertas de compra

Operações recusadas atualizam o status e chamam `AlertManager.alert()`. Isso inclui dinheiro insuficiente, empreendimento não comprado, item inválido, equipamento já comprado, nível insuficiente e conta inválida.

Quando falta dinheiro, a mensagem informa o valor necessário, por exemplo: `Dinheiro insuficiente para comprar este equipamento. Você precisa de R$ 350,00.`

## 15. Principais regras de design e gameplay

### Decisões de projeto observadas

- Estado centralizado em `Global.player`
- Layout na cena, conteúdo no script (ver 3.4) — substitui a abordagem antiga de montar a UI inteira em código, que gerava interfaces duplicadas sobrepostas
- lógica de inventário e economia centralizada
- Zonas do jogo são separadas em cenas, mas o estado fica global
- o roteiro enfatiza educação financeira, planejamento e autocuidado
- as mecânicas de empreendedorismo têm conteúdo educativo espelhado no escritório, com os mesmos números

### Motivação para gastar dinheiro e tempo

A lógica atual faz o jogador sentir custo real de improviso e de ausência de autocuidado:

- gastar dinheiro reduz o saldo
- comer/resource management melhora estado do personagem
- ficar sem comida e sem descanso piora `hunger` e `happiness`
- semanas ruins geram penalidades de dinheiro

Isso adiciona motivação para:

- planejar compras
- evitar gastos impulsivos
- comer em casa
- equilibrar vida pessoal e dinheiro

## 16. Gotchas / problemas conhecidos

Algumas áreas exigem atenção:

- o projeto teve problemas de autoload/parse e logger antes do ajuste final
- há necessidade de garantir que os autoloads estejam carregados corretamente em `project.godot`
- a lógica de tempo e missões precisa ser validada em runtime real do Godot
- muitas cenas podem ter dependências semânticas em nomes de nó específicos
- em alguns pontos a arquitetura ainda mistura cena e lógica global
- `spend_today` é zerado a cada hora de jogo em `TimeManager._add_minute()`, não a cada dia — isso afeta as missões `no_spend_day` e `no_impulse`. O `emit_signal("day_changed")` está no mesmo bloco horário, com o mesmo problema
- o processamento financeiro e o balanceamento dos preços ainda precisam ser validados em runtime real do Godot
- `EnterpriseManager.process_all_daily_operations()` é chamado **antes** de `Global.player["day"]` ser atualizado no `TimeManager`, então o dia gravado no histórico e nas despesas fica defasado em 1. A operação não duplica (o guard `last_operation_day` funciona), mas as datas registradas estão erradas
- `restaurant.tscn`, `arcade.tscn` e `shopping.tscn` foram escritas à mão como cenas herdadas (`[node name="X" instance=ExtResource(...)]` na raiz). **Validado em runtime**: carregam e renderizam corretamente. O mesmo padrão pode ser reusado para outras telas
- o ambiente do agente **não tem o Godot disponível por CLI**. Nenhuma alteração de cena ou script pode ser validada automaticamente — tudo precisa ser testado no editor. Priorize layout por container (que é autocorretivo) em vez de offsets em pixel
- `scenes/world/ui/enterprise-view.tscn` não tem `uid://` nem campos `unique_id` — o Godot atribui na primeira vez que abrir e salvar
- o `history` de cada empreendimento é limitado a 50 entradas, mas `Global.player["expense_history"]` e `home_actions_log` continuam crescendo sem limite no save

## 17. Como continuar sem quebrar a base

Ao trabalhar no projeto:

- sempre use `Global.player` como fonte do estado do jogador
- quando criar novos dados de jogador, adicione à `data_model`
- atualize `ensure_player_state()` quando necessário
- favoreça alterações em singletons em vez de espalhar lógica de estado em cenas
- serialize tudo que deve persistir em `SaveManager`
- sempre que criar um novo comportamento relevante para a semana, atualize `MissionManager`
- ao alterar empreendimentos, mantenha os dados específicos nos arquivos `*_info.gd`
- use `EnterpriseManager` para qualquer compra, conta, estoque, equipamento ou cálculo de lucro
- preserve `enterprise_id` e o formato de `Global.player["enterprises"]` para não quebrar saves
- ao adicionar chaves novas ao estado de um empreendimento, inclua em `_default_state()` — `_normalize_state()` preenche automaticamente os saves antigos
- escreva no histórico de empreendimento só via `_append_history()`, nunca com `state["history"].append()` direto, ou o limite de 50 entradas é furado
- não crie estrutura de UI em script se a cena já tem o nodo (ver 3.4); se faltar um nodo fixo, avise antes de improvisar
- não atribua `Global.gameplay_locked` direto — use `lock_gameplay()` / `unlock_gameplay()` em par
- ao mudar balanceamento de empreendimentos, revise os números citados no nível 5 do escritório

## 18. Checklist de desenvolvimento ideal

Antes de alterar qualquer gameplay, verificar:

- [ ] Estado do jogador está em `Global.player`
- [ ] Save ainda funciona
- [ ] Tempo continua coerente
- [ ] Economia não foi quebrada
- [ ] UI da casa continua renderizando corretamente
- [ ] Inventário da casa continua consistente
- [ ] Missões continuam válidas
- [ ] Empreendimentos continuam usando `Global.player["enterprises"]`
- [ ] Compras empresariais aparecem no histórico de despesas
- [ ] Operações diárias não são duplicadas
- [ ] Contas semanais aparecem e podem ser pagas
- [ ] Interface continua reutilizável nos três IDs
- [ ] Nenhuma interface aparece duplicada (script não recriou a árvore da cena)
- [ ] Os caminhos `@onready` batem com os nomes reais dos nodos na cena
- [ ] Números citados no escritório continuam iguais aos dos `*_info.gd`
- [ ] Alerta continua clicável e só a barra de espaço confirma

## 19. Conclusão

O projeto já está estruturado em torno de uma arquitetura interessante para um jogo de educação financeira: estado global, gestão por singletons, tempo, missões, inventário e economia. A parte principal do ciclo funcional e educativo está consolidada em:

- `Global`
- `TimeManager`
- `MissionManager`
- `FIIManager`
- `SaveManager`
- `home.gd`
- `market.gd`
- `banco.gd`

Esse conjunto permite que um novo agente entenda o comportamento do projeto e continue implementando sem perder a lógica base já construída.

## 20. Arquivos-chave para consulta rápida

- `project.godot`
- `singletons/Global.gd`
- `singletons/TimeManager.gd`
- `singletons/SaveManager.gd`
- `singletons/MissionManager.gd`
- `singletons/FIIManager.gd`
- `scripts/world/home/home.gd`
- `scripts/world/market/market.gd`
- `scripts/world/bank/banco.gd`
- `singletons/EnterpriseManager.gd`
- `scripts/enterprise/enterprise_management.gd`
- `scripts/enterprise/data/restaurant_info.gd`
- `scripts/enterprise/data/arcade_info.gd`
- `scripts/enterprise/data/shopping_info.gd`
- `scenes/world/ui/enterprise-view.tscn`
- `scenes/world/places/home.tscn`
- `singletons/AlertManager.gd`
- `singletons/TutorialManager.gd`
- `scripts/world/office/office.gd`
- `singletons/Logger.gd`

Este documento deve ser usado como material de contexto para qualquer tarefa futura do projeto.

## 21. Estado dos planos na raiz do projeto

| Arquivo | Status |
|---|---|
| `FIX_PLAN.md` | **concluído** — as 13 etapas de correção foram aplicadas |
| `ENTERPRISE_PLAN.md` | **concluído** na primeira versão, mais as mecânicas de nível, funcionários, capacidade e inadimplência |
| `CLAUDE_HOME_REFACTOR_PROMPT.md` | **concluído** — `home.gd` ancorado em `home.tscn` |
| `CLAUDE_ENTERPRISE_VIEW_REFACTOR_PLAN.md` | **concluído e validado em runtime** — as 8 tarefas, mais o ajuste de layout 2×2 |
| `SAVE_SLOTS_PLAN.md` | **não implementado** — plano aprovado, nenhuma etapa executada. O save continua único em `user://savegame.json` |

Ao retomar o `SAVE_SLOTS_PLAN.md`, dois ajustes que o plano ainda não reflete: `Global.player` ganhou a chave `enterprises`, e o `EnterpriseManager` **não** precisa de um `reset()` como o `FIIManager`, porque não guarda estado próprio no autoload. Inclua no checklist "empreendimentos comprados não vazam entre slots".
