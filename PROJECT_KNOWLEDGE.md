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
- `singletons/HouseBillsManager.gd` — geração e pagamento das contas semanais da casa
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
- `HouseBillsManager` — regras das contas recorrentes da casa
- `MinigameManager` — travas e cooldown da escola/minigame (ver seção 12.2)
- `TransitionManager` — fade entre cenas; ponto único de troca de cena (ver 3.9)
- `Logger` — grava logs de runtime em arquivo
- `EventsManager` — sorteia eventos inesperados e mantém as pendências (contas/bônus) que o jogador resolve no banco; dados vêm de `UnexpectedEvents`, que serve só como fonte de dados. Ver seção 12.1
- `TutorialManager` — onboarding da semana 1 e avisos semanais do tutorial (ver 3.3)
- `AlertManager` — `CanvasLayer` de alerta modal, compartilhado por todo o jogo
- `NotificationManager` — `CanvasLayer` de toasts no canto superior direito (ver 3.10)
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

- `blocker` — `ColorRect` em tela cheia, preto a 50%, com `MOUSE_FILTER_STOP`;
- `panel` — `Control` transparente em tela cheia (não é `Panel`: um `Panel` full-rect pintaria por cima de tudo e esconderia o overlay);
- `dialog` — **`PanelContainer`** central com `font_theme.tres` → `MarginContainer` (28) → `VBoxContainer` → `text_scroll` + botão OK;
- `text_scroll` — `ScrollContainer` de `TEXT_WIDTH × TEXT_VISIBLE_HEIGHT` (700×230) com `horizontal_scroll_mode` desabilitado, contendo o `alert_label` (`label.tres`, autowrap);
- `skip_button` — botão "Pular tutorial" ancorado no canto superior direito, visível apenas quando `TutorialManager.can_skip()` é verdadeiro.

**Por que `PanelContainer` e não `Panel`.** O `dialog` era um `Panel` com `custom_minimum_size = Vector2(560, 160)`. `Panel` não é container: ele não lê o tamanho mínimo dos filhos, então o `CenterContainer` o mantinha travado em 560×160 enquanto o texto do tutorial (até 380 caracteres, ~6 linhas no corpo 23) crescia para fora da caixa. O comentário no código dizia "a altura acompanha o tamanho do texto", o que nunca foi verdade nessa estrutura. `PanelContainer` se dimensiona pelo conteúdo.

O tamanho da caixa é **fixo** de propósito: quem define a área de texto é o `custom_minimum_size` do `text_scroll`, não a mensagem. Assim a caixa não muda de tamanho a cada alerta. Textos maiores que a área rolam — e `alert()` zera `scroll_vertical`, senão a mensagem seguinte abriria já rolada. O `alert_label` fica com `MOUSE_FILTER_IGNORE` para a roda do mouse chegar ao `ScrollContainer`.

**`alert()` enfileira, não sobrescreve.** A virada de semana dispara três alertas em sequência (`verify_missions()`, a mensagem semanal do tutorial e o evento inesperado). Sem fila, o último apagava o texto dos anteriores e — pior — o contador de `gameplay_locked` ficava preso: eram N `lock_gameplay()` (uma por chamada) para um único `unlock_gameplay()` (o clique). Agora `alert()` só empilha em `_queue`, e `_show_next()` exibe um por vez, travando **uma vez por alerta exibido**. `_close_alert()` puxa o próximo **depois** de rodar o callback, porque o callback pode enfileirar outro alerta — é assim que o tutorial encadeia as mensagens.

**`defer_alerts()` e `resume_alerts()` para minigames.** Durante minigames onde o jogador está em ação ativa (corrida de obstáculos da escola ou caça às moedas do parque), alertas externos gerados em background (como o aviso das 18h de `TimeManager` ou eventos inesperados de `EventsManager`) são retidos em `_deferred_queue` e não travam o gameplay. `alert(..., immediate=true)` ou `alert_immediate()` permite alertas intencionais do próprio minigame (como o feedback do quiz do parque). Ao final da sessão, `resume_alerts()` transfere os alertas acumulados para a fila principal, exibindo todos eles ordenadamente após o resultado da partida.

**`alert_choice(text, choices)`** é a variante com N botões, usada pelos eventos inesperados com `escolhas`. Cada escolha é `{"text": String, "callback": Callable}`. Nela o botão OK some, o "Pular tutorial" some e **a barra de espaço não fecha** — fechar pelo teclado descartaria a decisão sem criar conta nem bônus. Os botões vivem em `choice_box` e são limpos com `remove_child()` antes do `queue_free()`, pelo mesmo motivo do `_clear_list()` dos empreendimentos.

Os botões usam `focus_mode = FOCUS_NONE` de propósito. Um botão com foco é acionado pela ação `ui_accept`, que inclui **Enter** por padrão — e o atalho de confirmação do alerta deve ser somente a barra de espaço, tratada manualmente em `_input()` com `set_input_as_handled()`.

`TutorialManager.skip_tutorial()` marca `skipped`, limpa a fila de mensagens e pula `step` e `tutorial_step` para `FINAL_STEP`. O botão de pular só aparece na primeira mensagem (`can_skip()` exige `step == 1`).

**O tutorial tem dois estágios principais (onboarding e avisos semanais).**

*Estágio 1 — onboarding linear.* `messages` e a máquina de passos de `_next_step()`, que roda uma vez só, da abertura do jogo até o fim da semana 1:
1. Boas-vindas (`messages[0]`, botão de pular disponível).
2. Objetivo principal e Controles (`messages[1]`, `messages[28]` e `messages[29]`): ensina movimentação (WASD/Setas, Shift), interações (Enter, Espaço), missões (M/F ou botão na HUD) e pause (ESC) **antes** de citar ou focar a escola.
3. Primeiro passo: a escola (`messages[2]`).
4. Escolaridade e salário (`messages[3]`).
5. Foco da câmera na escola (`emit_signal("focus", "School")`) e aguarda o jogador entrar.
6. Explicação dentro do minigame de formação (`messages[4]` a `messages[8]`).
7. Espera o minigame terminar.
8. Pós-minigame: primeiro salário e apresentação/destravamento do escritório (`messages[9]`, `messages[13]`, `messages[21]`).
9. Espera o jogador entrar e sair do escritório de consultoria.
10. Tour do mundo: apresenta a casa com foco de câmera (`"Home"`, `messages[22]`) e explica todas as mecânicas domésticas (estoque, alimentação, descanso, sono, penalidade da meia-noite e sede: `messages[23-25, 16-18, 27]`), seguido do mercado com foco (`"Market"`, `messages[11, 19, 20]`), banco com foco (`"Bank"`, `messages[12]`), parque com foco (`"Park"`, `messages[30]` — caça às moedas, quiz semanal, cupom de desconto no mercado e regras de acesso) e mensagens finais (`messages[14, 15]`). Ao concluir, destrava a cidade inteira (`UNLOCK_ALL`) e marca `tutorial_home_shown = true`.
11. Tutorial concluído (`TUTORIAL_DONE = 11`).

*Estágio 2 — avisos semanais.* `weekly_messages` é um dicionário `semana → Array[String]`, disparado por `TutorialManager.on_week_changed(week)`, que o `TimeManager` chama na virada de semana logo após `week_changed`. Cada semana ensina só o que acabou de destravar:

| Semana | Conteúdo |
|---|---|
| 2 | Contas fixas da casa e eventos inesperados viram pendências no banco; ligação com o nível 2 do escritório (reserva de emergência) |
| 3 | Investimentos básicos e os FIIs no banco (nível 3 do escritório) |
| 4 | Mercado financeiro (nível 4 do escritório) |
| 5 | Bloco dos empreendimentos: 6 mensagens com preço, capacidade e contas semanais reais de cada negócio |

As semanas escolhidas acompanham o que o resto do jogo já libera: `EventsManager.FIRST_EVENT_WEEK = 2` e `office.gd` usa `player_level = Global.player["week"]`, então o nível N do escritório destrava na semana N.

`Global.player["tutorial_weeks_shown"]` guarda as semanas já mostradas, para um reload não repetir. A comparação passa por `_week_already_shown()`, que converte cada item com `int()` — depois de salvar e carregar, o JSON devolve os números como float e comparar `2` com `2.0` direto no `Array.has()` é frágil.

`skip_tutorial()` marca **todas** as semanas de `weekly_messages` como vistas e define `tutorial_home_shown = true`: o botão diz "Pular tutorial", então pula o tutorial inteiro, não só o onboarding. Isso vai para `Global.player` de propósito — a variável `skipped` não é salva, então checá-la faria os avisos semanais voltarem após um reload.

*Estágio 3 — mecânicas da casa.* A apresentação detalhada da casa agora faz parte do tour do mundo (Passo 10), ocorrendo após o minigame e a consultoria. Quando o tour roda, marca `Global.player["tutorial_home_shown"] = true`. `home.gd._ready()` mantém a chamada a `TutorialManager.on_player_entered_home()` como segurança/fallback, mas a trava impede que mensagens sejam exibidas novamente ao entrar na residência.

**Status congelados em 100% durante o tutorial inicial:** Enquanto o tutorial inicial não for concluído (`Global.is_tutorial_active()` — isto é, `tutorial_step < 11` e `unlock_stage < UNLOCK_ALL`), os status do jogador (`hunger`, `thirst`, `stamina`) não diminuem e permanecem cravados em 100.0. O aviso de cansaço das 18h e a penalidade de meia-noite não acontecem. Assim que o jogador é liberado para explorar o mundo (conclusão do tour no Passo 10) ou ao usar o botão "Pular tutorial", todos os status são confirmados em 100% e a simulação de decaimento natural começa a atuar normalmente.

**O array `messages` é append-only.** Os índices 0–21 são citados um a um em `_next_step()`, `_resume_step()`, `_queue_office_intro()` e `_queue_world_tour()`; inserir no meio renumera tudo e quebra as quatro. Conteúdo novo entra no fim — 22 (a casa, no tour com foco `"Home"`), 23–27 (estoque, comer/beber, descansar/TV, dormir, sede), 28–29 (comandos e controles básicos) e 30 (o parque, no tour com foco `"Park"`).

**Os números das mensagens dos empreendimentos são copiados dos arquivos em `scripts/enterprise/data/`** — ao mexer em `purchase_price`, `water_bill`, `electricity_bill`, `starting_capacity`, `employee_salary` ou `upgrade_costs`, atualize o texto do tutorial junto, senão ele passa a ensinar valores errados.

### 3.4 Layout na cena, conteúdo no script

Padrão adotado para as interfaces do jogo: **a cena `.tscn` é a fonte de verdade do layout; o script é a fonte de verdade do conteúdo.**

O script captura os nodos fixos com `@onready` e só cria/limpa os filhos dinâmicos dentro dos containers que já existem. Nunca recria painéis, containers de seção ou labels de cabeçalho.

Já seguem esse padrão:

- `scripts/world/home/home.gd` sobre `scenes/world/places/home.tscn`;
- `scripts/enterprise/enterprise_management.gd` sobre `scenes/world/ui/enterprise-view.tscn`.

Parcialmente: `banco.gd` — os painéis de investimentos e de contas/bônus já vêm da cena (abas do `TabContainer` `Investimentos`), mas `history_panel` ainda é montado por script.

Ainda constroem a interface inteira por script (candidatos ao mesmo tratamento): `market.gd`, `office.gd`, `AlertManager.gd`.

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

### 3.8 Convenção de temas: painel x label

Regra do projeto: **containers e painéis usam `font_theme.tres`; `Label` de conteúdo usa `label.tres`.**

O motivo é que `font_theme.tres` define `Label/styles/normal = label_round.png` e `Label/font_sizes/font_size = 24`, e **tema propaga para todos os descendentes**. Um `Label` criado em runtime dentro de um container que carrega `font_theme` nasce com fundo de caixa arredondada e corpo 24 — numa lista densa isso vira uma pilha de caixas gigantes.

Onde isso está aplicado:

- `enterprise_management.gd` → `ROW_LABEL_THEME` + `_make_row_label()` (corpo 16);
- `banco.gd` → `EVENT_LABEL_THEME` + `_make_event_label()` (corpo 15);
- `AlertManager.gd` → `alert_label` com `label.tres`, `dialog` e botões com `font_theme.tres`;
- na própria cena `enterprise-view.tscn`, os labels de cabeçalho declaram `theme = label.tres` à mão.

O `font_theme.tres` também define `PanelContainer/styles/panel` e os estilos de `TabContainer` (`panel`, `tab_selected`, `tab_unselected`, `tab_focus`), então esses dois tipos já saem com o visual pixel-art sem override nenhum.

Nota: `label.tres` **não** define `Label/fonts/font`, só cor (preto), corpo 23 e um `StyleBoxFlat` transparente. Quem usa `label.tres` renderiza com a fonte padrão do Godot, não com a pixel font.

### 3.9 Transições entre cenas

**Toda troca de cena passa por `TransitionManager.change_scene(caminho)`.** Nunca chame `get_tree().change_scene_to_file()` direto — se aparecer um, é código que escapou da conversão.

`TransitionManager` é um `CanvasLayer` autoload com um `ColorRect` preto em tela cheia. `change_scene()` faz fade-out, troca, espera um frame para a cena nova entrar na árvore, e faz fade-in. Duração e cor ficam em um lugar só (`FADE_DURATION`).

Quatro detalhes que sustentam isso:

- **quem chama não pode dar `await`.** Ao trocar de cena, o nó que chamou é liberado; se estivesse esperando a corrotina, retomaria já morto. A corrotina vive no autoload, que sobrevive à troca. Os call sites chamam e retornam;
- **`_transitioning` bloqueia chamada repetida.** As portas usam `Input.is_key_pressed()` dentro de `_process`, que é verdadeiro **todo frame** enquanto a tecla está segurada. Sem a guarda, um fade de 0.35 s viraria dezenas de chamadas seguidas. Isto já era um problema latente antes das transições — só não aparecia porque a troca era instantânea;
- **`process_mode = PROCESS_MODE_ALWAYS`.** Um `Tween` segue o `process_mode` do nó dono. Se uma transição começasse com a árvore pausada (menu de pausa), o tween congelaria, o `await` nunca voltaria e o jogo ficaria travado com `_transitioning = true` para sempre;
- **`layer = 200`**, acima do `AlertManager` (100) e do diálogo de compra das portas (90), para o fade cobrir tudo. E `unlock_gameplay()` roda mesmo quando `change_scene_to_file` retorna erro, senão o contador de `gameplay_locked` ficaria preso.

**Exceção deliberada:** `Global.new_game()` continua trocando de cena direto. É a passagem da escolha de personagem para o mundo, e `Global` é a base de que todos dependem — fazê-lo consumir um singleton de UI inverteria a direção das dependências do projeto. Para ter fade também ali, o caminho limpo é `choose_character.gd` chamar a transição e `new_game()` deixar de trocar de cena.

### 3.10 Notificações (toasts)

`NotificationManager` é o par não-modal do `AlertManager`. Uso:

```gdscript
NotificationManager.notify("Missão concluída: Economize R$100")
NotificationManager.notify("Conta paga", 5.0)   # duração opcional
```

**A regra de escolha entre os dois:** alerta trava o jogo e exige confirmação; notificação não trava nada e some sozinha em 3 s. Se a mensagem puder ser perdida sem prejuízo, é notificação.

Detalhes que sustentam isso:

- **`layer = 90`** — abaixo do `AlertManager` (100) e do `TransitionManager` (200), acima dos HUDs. Um alerta modal cobre os toasts de propósito;
- **`process_mode = PROCESS_MODE_ALWAYS`** — um `Tween` segue o `process_mode` do nó dono. Sem isso, um toast aberto quando o jogador abre o menu de pausa congelaria na tela para sempre;
- **o tween nasce no toast (`toast.create_tween()`), não no autoload.** Assim ele morre junto se o toast for removido antes da hora pelo limite de `MAX_VISIBLE` (4). Um tween criado no autoload continuaria mexendo em um nó liberado;
- **`MOUSE_FILTER_IGNORE`** no stack e no toast: é decoração, não pode roubar clique de botão nenhum embaixo;
- o `VBoxContainer` do stack precisa de **altura real** (`STACK_HEIGHT`): um `Container` distribui os filhos dentro do próprio retângulo, e com altura zero os toasts nasceriam invisíveis;
- `TOP_MARGIN = 80` começa a pilha **abaixo** do botão "MISSÕES (F)", que ocupa o topo direito até `y = 65`.

Convenção de tema seguida (ver 3.8): o `PanelContainer` do toast usa `font_theme.tres`, o `Label` usa `label.tres`.

### 3.11 Progresso de missão em tempo real

`MissionManager` reavalia as missões da semana a cada `CHECK_INTERVAL` (0,5 s) no `_process`. É polling de propósito: as missões são derivadas de **estado** (dinheiro, carteira, estoque, contas), não de eventos — instrumentar cada sistema que pode cumprir uma missão seria muito mais código e deixaria caminhos de fora.

- `is_completed(id)` alimenta o check do painel (`scripts/hud/missions_ui.gd`);
- `mission_completed(mission)` é emitido na transição, e `_announce()` dispara o toast;
- **o check espelha `_check_mission()` ao vivo, então pode sumir** (gastar o dinheiro que cumpria `money_min`). É intencional: o painel tem de contar a mesma verdade que `verify_missions()` no fim da semana, senão o jogador veria ✓ e reprovaria mesmo assim;
- **a semeadura é silenciosa.** `refresh_progress(notify)` força `notify = false` quando a semana muda (inclui a primeira varredura, com `_tracked_week = -1`), senão uma missão que já nasce cumprida — o dinheiro que sobrou da semana anterior — anunciaria uma conquista que o jogador não acabou de fazer;
- **a semeadura acontece no primeiro `_process`, não no `_ready()`.** `MissionManager` é registrado **antes** de `FIIManager` e `EnterpriseManager` em `project.godot`, e `_check_mission()` chama os dois: no `_ready()` eles ainda não existem;
- `Global.new_game()` chama `reset_progress()` junto de `FIIManager.reset()`, para a partida nova não herdar o que já foi anunciado.

O `✓` usado no painel existe na `PixeloidSansBold` (U+2713 está no cmap da fonte); `✔` (U+2714) e `☑` (U+2611) **não** existem e sairiam como caixa vazia.

Teste: `tests/test_mission_notifications.tscn`.

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
- `pending_house_bills`: contas domésticas abertas que devem ser pagas no banco
- `house_bill_history`: últimas contas domésticas quitadas
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
5. ao completar semana (5 dias):
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
- se falhar, mostra o alerta de reprovação e devolve `false` sem avançar a semana — quem chama (`TimeManager._process_week_rollover()`) repete a mesma semana. `MissionManager._game_over()` existe no arquivo mas não tem nenhum chamador; falhar uma missão nunca é game over
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

### Fundos presentes

Oito, definidos em `FIIManager._default_funds()` (fonte única; `funds` e `reset()` usam a mesma função). Risco e retorno andam juntos de propósito: maior volatilidade, maior yield semanal.

| Id | Nome exibido | Preço | Yield/semana | Volatilidade/dia |
|---|---|---:|---:|---:|
| `FII_RECEBIVEIS` | Recebíveis | R$ 100 | 1,9% | ±0,8% |
| `FII_RESIDENCIAL` | Residencial | R$ 85 | 2,1% | ±1,2% |
| `FII_LAJES` | Lajes Corporativas | R$ 120 | 2,0% | ±1,5% |
| `FII_HOSPITAIS` | Hospitais | R$ 140 | 2,3% | ±1,7% |
| `FII_SHOPPING` | Shopping | R$ 100 | 2,5% | ±2,0% |
| `FII_AGRO` | Agro | R$ 110 | 2,7% | ±2,2% |
| `FII_LOGISTICA` | Logística | R$ 90 | 3,0% | ±2,5% |
| `FII_HOTEIS` | Hotéis | R$ 75 | 3,2% | ±3,0% |

O **id** (`FII_*`) é a chave gravada no save e em `portfolio`: não renomear. O **nome exibido não leva a sigla "FII"** (estourava o label dos cards).

**Saves antigos:** o save grava o dicionário `funds` inteiro, então um save velho só conhecia os fundos da época, com nome e taxas da época. `FIIManager._merge_default_funds()` (chamada em `load_data()`) acrescenta os fundos que faltam e reaplica o que é catálogo (`name`, `dividend_yield`, `volatility`), preservando só o `price` salvo, que é estado de jogo.

**Loja** (`scripts/world/bank/fii_shop.gd`, aba `FII-shop` do banco): o grid (`Fund-grid`, `columns = 2`) é da cena; o script cria um card por fundo com nome, preço, volatilidade ("±x% ao dia"), input e Comprar/Vender. **Vender fica desativado** enquanto `FIIManager.portfolio` não tem cotas do fundo. A loja se redesenha em `funds_updated`, que `buy_fund`, `sell_fund` e `reset` emitem. Colunas: 2 e não 3 como no mercado, porque a aba tem ~640 px e dois botões + SpinBox não cabem num card de ~205 px.

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
- `HBoxContainer/Actions/VBoxContainer` — container **vazio** na cena, preenchido em runtime com os botões Descansar, Assistir TV e Dormir (Comer e Beber **não** são mais botões: ver abas abaixo);
- `.../Hunger-container/ProgressBar`, `.../Thirst-container/ProgressBar` e `.../Stamina-container/ProgressBar` — as barras usam `show_percentage`, então não existem labels separados de porcentagem;
- `.../status-message` — mensagem de retorno das ações;
- `HBoxContainer/VBoxContainer/Food-tabs` — `TabContainer` com as abas **Comidas** e **Bebidas**, cada uma com um `GridContainer` de 2 colunas (`Food-grid`, `Drink-grid`) que `_render_inventory()` enche com cards do estoque;
- `History-scroll` — recebe um `VBoxContainer` criado em runtime para as linhas;
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

Há ainda um ajuste fino por personagem, somado ao Y da posição base:

```gdscript
const CHARACTER_Y_OFFSET = {
	"Phillip": 85.0
}
```

O Phillip desce 85 px para alinhar com os outros; quem não está no dicionário usa `0.0`. É um dicionário em vez de um `if` para que um personagem novo com o mesmo problema seja uma linha, sem tocar na lógica. As chaves precisam bater exatamente com a string gravada em `Global.player["name"]` por `choose_character.gd` — a comparação é sensível a maiúsculas.

Na função, a variável local se chama `sprite_position` e não `position` de propósito: `position` sombrearia a propriedade do próprio `Control` e o Godot emitiria aviso.

> Duplicação conhecida: o mapa nome → cena (`CHARACTER_SCENES`) agora existe em três lugares — `home.gd`, `scripts/player/player.gd` e `scripts/player/raul_minigame.gd`. Um personagem novo precisa ser adicionado nos três. Candidato a virar uma constante única em `Global`.

### Funções principais

- `_build_ui()` — só cria o que é dinâmico: botões de ação e os containers de lista dentro dos scrolls
- `_update_ui()` — atualiza status da UI
- `_render_inventory()` — exibe o estoque em cards, itens `food` na aba Comidas e `drink` na aba Bebidas (card = ícone, nome, "Estoque: N", "Fome +x% / Sede +y%" e botão COMER ou BEBER; mesmo `BankCard` das abas do banco)
- `_render_history()` — exibe histórico de ações (últimas 10)
- `_on_consume_pressed(item_key)` — chama `Global.consume_specific_item()` com o item do card
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

## 10.1 Necessidades: fome, sede e stamina

Três medidores, todos em `Global.player`. **Nenhum mata**: zerar qualquer um faz o jogador desmaiar.

| Medidor | Decai | Zerar | Repõe |
|---|---|---|---|
| `hunger` | `HUNGER_DECAY_PER_MINUTE` por minuto de jogo | desmaio | comer (item do estoque) |
| `thirst` | `THIRST_DECAY_PER_MINUTE` por minuto de jogo | desmaio | beber (item do estoque) |
| `stamina` | `STAMINA_DECAY_PER_MINUTE = 100/960`, minuto a minuto | desmaio (depois de a velocidade cair a zero) | dormir |

**Desmaio** (`TimeManager._faint(cause)`, único caminho para os três): cobra `MIDNIGHT_PENALTY` (R$ 30, piso em zero), fecha o dia com `_close_day()` e, quando o jogador fecha o alerta, `_advance_to_next_day()` o leva para casa no dia seguinte. Fome e sede entram por `TimeManager.collapse_if_needs_depleted()`, chamada a cada minuto em `_add_minute()` e logo após `Global.apply_home_action()`. O texto cita a causa ("exaustão", "fome", "sede" ou "fome e sede").

**A necessidade zerada é restaurada a `MIDNIGHT_STAMINA` (50) no `_close_day()`** (`Global.restore_depleted_needs()`). Sem isso o jogador acordaria ainda em zero e desmaiaria de novo no primeiro minuto do dia seguinte, em loop. Consequência assumida: sem dinheiro nem comida, o desmaio se repete a cada ~dia pagando R$ 0 (a cobrança tem piso em zero) — não há mais derrota por fome.

`Global.trigger_game_over()` continua existindo (e a trava `_game_over`, e `SaveManager` não grava durante um game over), mas **nada o chama hoje**. `SaveManager.load_game()` também não apaga mais saves com fome/sede zeradas.

Fome e sede caem em `Global.decay_need_state()`, que só decai e devolve `false` se alguma zerou; quem desmaia o jogador é `TimeManager`.

A sede cai **mais rápido** que a fome de propósito — zera em ~7 dias contra ~17.
É o que dá utilidade às bebidas: antes delas existir a sede, `market.gd` mandava
`"Comidas"` e `"Bebidas"` para a mesma categoria `"food"`, e bebida era apenas
comida ruim (cerveja a R$ 50 repondo 5% de fome).

### Consumo: o jogador escolhe o item

A casa chama `Global.consume_specific_item(item_key)`: consome **exatamente** o item do card clicado (`item_key` = nome em minúsculas, a chave do estoque). A categoria do item decide se vale como comer ou beber (`EAT_ACTION`/`DRINK_ACTION`: textos, 0,5 h comer / 0,25 h beber, e qual necessidade já cheia bloqueia).

`Global.consume_item(category, need_key, action)` continua existindo e escolhe sozinha o "melhor" item da categoria; `consume_food()` e `consume_drink()` são fachadas dela, hoje sem chamador na UI (só testes). As duas terminam em `_consume_chosen()`, que tira 1 do estoque, aplica os ganhos e gasta o tempo.

**O item aplica sempre os dois restauros.** Leite mata um pouco de sede,
milkshake mata um pouco de fome; quem decide a categoria é o botão, não o efeito.
No item do inventário, `energy` guarda o % de fome e `thirst` o % de sede.
Comer ainda devolve `STAMINA_PER_FOOD_ENERGY` (um quarto) da fome em stamina.

### ⚠️ `normalize_home_inventory()` reconstrói cada item do zero

A função monta cada item a partir de uma **lista fixa de chaves**, e roda em
`add_home_inventory_item()`, `get_home_inventory_items()` e `ensure_player_state()`.
Qualquer campo novo do item precisa ser repetido lá dentro, senão é **apagado
silenciosamente** na próxima chamada. Foi por isso que `thirst` teve de entrar
no dicionário literal — é a armadilha mais fácil de não perceber nesta área.

O mesmo lugar faz a **migração de saves antigos**: bebida gravada como `"food"`
e sem valor de sede é remapeada por nome via `Global.DRINK_THIRST`, que espelha
os `thirst_restore` de `market.gd["Bebidas"]`. As duas tabelas são comparadas
por `tests/test_mechanics.gd`, então divergir quebra o teste. Atenção ao nome:
o item é gravado com `name.capitalize()`, que troca `_` por espaço
(`hot_chocolate` → `Hot Chocolate`), então a busca reverte o espaço para `_`.

### A lição financeira está no R$ por ponto

Cada item do mercado mostra o que repõe (`_restore_label()` omite o que é zero).
A coluna que ensina é preço dividido por ponto reposto:

- água — R$ 5 por 25% de sede = **R$ 0,20/ponto**
- cerveja — R$ 50 por 10% = **R$ 5,00/ponto** (25x mais caro)
- vinho — R$ 120 por 8% = **R$ 15,00/ponto** (75x mais caro)

O item barato e sem graça é o certo. É o "necessidade x desejo" do nível 1 do
escritório, agora com um medidor para provar.

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

## 11.1 Contas da casa

`HouseBillsManager.gd` concentra as despesas recorrentes da residência. A casa é ativa por padrão, portanto ao fim de cada semana `TimeManager` chama `HouseBillsManager.generate_weekly_bills()` antes do avanço de semana.

São geradas três contas para a semana encerrada: água (R$ 30), luz (R$ 45) e aluguel/condomínio (R$ 75). Cada uma fica em `Global.player["pending_house_bills"]`, com ID que inclui a semana, prazo `due_week = week + 1` e sem alterar o dinheiro do jogador ao nascer. O ID é conferido também no histórico, evitando duplicação caso a rotina seja chamada novamente após a conta já ter sido paga.

No banco, a aba **Contas da casa** lista somente as pendências, com valor, semana de criação, vencimento e botão **Pagar**. `HouseBillsManager.pay_bill()` valida o saldo, desconta o valor, remove a pendência, registra uma entrada de categoria `house_bill` em `expense_history` e move a conta para `house_bill_history` (limitado a 50 entradas).

As duas listas fazem parte de `Global.player`, então já são persistidas pelo `SaveManager`; `ensure_player_state()` também as cria para saves antigos. O tutorial da semana 2 apresenta as contas domésticas e os dois prazos (vencimento e data limite) — ver 12.3.

## 12. Sistema bancário

`scripts/world/bank/banco.gd` é o ambiente do banco.

Seu papel inclui:

- mostrar dinheiro do jogador
- manter painel de histórico financeiro
- exibir despesas e registros do dia
- funcionar como fonte visual do registro de gastos

Histórico de gastos é representado em `Global.player["expense_history"]`.

### Abas em cards

As cinco abas do `TabContainer` (Histórico, Eventos, Contas da casa, FII-shop, Portfolio) mostram **um card por registro**, num `GridContainer` de 2 colunas (`columns = 2` na cena; mercado usa 3, mas a aba do banco tem ~640 px). O card é montado por `scripts/world/bank/bank_card.gd` (`BankCard.new_card()`, `make_label()`, `make_button()`, `new_empty_card()`), para as cinco terem o mesmo visual e uma regra só.

- Estrutura do card: `PanelContainer > MarginContainer > VBoxContainer`. **`PanelContainer`, não `Panel`:** `Panel` não lê o tamanho mínimo dos filhos e o texto de prazo (que quebra em várias linhas) vazaria para fora do card. `custom_minimum_size` é só o piso, para cards da mesma linha não ficarem com alturas muito diferentes.
- Labels usam `label.tres` (o `Label` do `font_theme.tres` tem fundo `label_round.png` e corpo 24: caixa dentro de caixa) e **sempre com autowrap**, senão pedem a largura do texto inteiro e empurram o card para fora do grid (ver 3.5).
- Lista vazia vira **um card de aviso** (`new_empty_card()`), não um `Label` solto, que ficaria preso à primeira célula do grid.
- Conteúdo de cada card: **histórico** = item, preço, "Semana N - Dia M" (mais recente primeiro); **eventos** e **contas da casa** = título, valor (com juros se vencida), prazos e botão Pagar/Resgatar; **loja** = nome, preço, volatilidade, input, Comprar/Vender; **carteira** = nome, cotas, valor.
- Os nós de lista mantêm os nomes antigos (`History-list`, `Events-list`, `House-bills-list`), agora `GridContainer`; o da carteira virou `Holdings-grid` e o da loja `Fund-grid`. Todas as listas redesenham com `remove_child()` antes do `queue_free()`.

Além da aba **Eventos** para imprevistos e bônus, o `TabContainer` `Investimentos` tem a aba **Contas da casa**. Ela é um painel fixo na cena; `banco.gd` apenas preenche sua lista e reage ao sinal `HouseBillsManager.bills_updated`.

### Painel de contas e bônus pendentes

Fica em `bank.tscn`, em `Investimentos/Eventos/Margin/VBoxContainer/Events-scroll/Events-list`. O painel virou uma aba do `TabContainer` chamado `Investimentos`, junto com a loja de FIIs e a carteira — o que resolveu o empilhamento de painéis que existia antes. O layout é da cena; `banco.gd` só preenche a lista, escutando `EventsManager.events_updated` para se redesenhar. É aqui que os eventos inesperados são resolvidos — ver seção 12.1.

> `history_panel` ainda é criado por script em `(710, 25)` com tamanho `(390, 590)`, o que o coloca por cima da área do `TabContainer`. É o último resquício do layout antigo do banco e o candidato natural a virar mais uma aba.

## 12.1 Eventos inesperados (contas e bônus pendentes)

O sistema foi remodelado: **um evento nunca mexe direto em `Global.player["money"]`**. Ele cria uma pendência que o jogador resolve manualmente no banco.

Fluxo:

1. `EventsManager.maybe_spawn_events(week)` é o único ponto de entrada da geração. Ele barra qualquer semana abaixo de `FIRST_EVENT_WEEK = 2`.
2. Dois gatilhos chamam essa função: o timer de `SPAWN_INTERVAL = 100.0` segundos em `_process` (frequência original preservada) e o avanço de semana em `TimeManager`, logo após `week_changed`.
3. `sortear_evento()` percorre `UnexpectedEvents` e devolve o primeiro evento cuja `probabilidade` passar no `randf()`.
4. Sem `escolhas`, `create_pending_event()` grava a pendência. Com `escolhas`, nada é gravado até o jogador clicar numa opção no alerta — e então só a opção escolhida vira pendência.
5. No banco, `Pagar`/`Resgatar` chamam `pay_event()`/`collect_event()`, que devolvem `{"success": bool, "message": String}` como o `EnterpriseManager`.

Forma de uma pendência em `Global.player["pending_events"]`:

```gdscript
{
	"id": "quebra_carro_1755792000_3",  # source_id + unix time + índice
	"title": "Problema no carro",
	"description": "...",
	"week_generated": 3,
	"amount": 500.0,                    # SEMPRE positivo
	"is_bonus": false,                  # o sinal vive aqui
	"status": "pending",                # pending | paid | collected
	"location": "bank",
	"source_id": "quebra_carro"
}
```

Armadilhas que este desenho evita, e que valem lembrar:

- **`amount` é sempre positivo.** Os dados em `UnexpectedEvents` usam `"dinheiro": -500` para contas. Guardar esse valor cru fazia `pay_event()` calcular `money - (-500)` e **creditar** o jogador ao pagar uma conta. Quem lê o valor usa `abs()`, e o sinal fica só em `is_bonus`;
- **o timer respeita `Global.play_time` e `gameplay_locked`.** `EventsManager` é autoload e nunca sai da árvore, então sem essa guarda o sorteio corria no menu inicial, na escolha de personagem e por cima de alertas modais;
- **`has_pending_from_source()` impede empilhar o mesmo evento.** Com um sorteio a cada 100 s, sem isso o banco enchia de contas idênticas de "Problema no carro";
- **`Time.get_unix_time_from_system()`, não `OS.get_unix_time()`** — este último não existe no Godot 4 e derrubava a criação da pendência;
- **`MAX_RESOLVED_EVENTS = 30`** limita só as pendências já resolvidas; as abertas nunca são podadas.

Persistência sai de graça: `SaveManager.save_game()` serializa `Global.player` inteiro, então `pending_events` já é salvo. Como o JSON devolve números como float no load, quem exibe `week_generated` precisa de `int()`.

**Decisões deliberadas**, para não serem "corrigidas" por engano:

- ~~não existe expiração nem multa automática~~ — **superado** por 12.3: contas e eventos de cobrança agora vencem, rendem juros e são cobrados sozinhos na data limite;
- a UI fica só no banco, não em casa. `location` existe no modelo e `get_pending_events(location)` já filtra, então acrescentar um painel em casa é só passar `"home"`;
- **o aviso do evento é um alerta modal, não uma notificação.** `event_ui.gd` e `event_message.tscn` foram removidos: a apresentação vive em `EventsManager._show_pending_alert()` e `_show_choice_alert()`, sobre o `AlertManager`. O evento mexe no dinheiro e, no caso com `escolhas`, exige uma decisão — um aviso que some sozinho descartaria a escolha em silêncio. O painel antigo também não pausava o jogo, só aparecia;
- **o alerta só aparece se a pendência foi mesmo criada.** Antes o painel abria mesmo quando `has_pending_from_source()` descartava o sorteio, anunciando uma conta que não existia;
- o nível 2 do escritório ganhou o tópico "Eventos inesperados no jogo", que explica a mecânica e diz onde resolver. O nível 2 destrava na semana 2, a mesma em que os eventos começam.

## 12.2 Minigame: travas, cooldown e tela de início

`MinigameManager` (autoload, registrado depois de `Global`) guarda a regra. **A primeira sessão é diferente das demais** — este é o ponto que mais confunde:

- **primeira corrida** (`sessions_played == 0`): é a formação inicial, **sem limite de níveis**. O jogador atravessa quantos checkpoints conseguir e a corrida só acaba quando ele bate. Depois dela, a escola trava até a semana seguinte, tenha ele subido muito ou pouco;
- **das próximas em diante**: alcançar o checkpoint sobe 1 nível e **encerra** a corrida, travando até a semana seguinte; bater antes disso trava por 2 dias de jogo.

`on_checkpoint_reached()` devolve `true` só quando a corrida deve terminar ali — na primeira sessão devolve `false` e o jogador segue correndo. `on_obstacle_hit()` sempre encerra.

Ao gravar uma trava, a outra é zerada, senão um cooldown antigo continuaria somando por cima do novo.

Estado em `Global.player["minigame_progress"] = {"unlock_week": int, "unlock_day": int, "sessions_played": int}`. Os padrões já estão satisfeitos, então uma partida nova começa com a escola aberta. `_progress()` normaliza chaves ausentes, como `EnterpriseManager._normalize_state()`.

**`MAX_SCHOOL_LEVEL = 5`** casa com os 5 níveis do escritório e com os 4 checkpoints do mapa (`Level1`..`Level4` levam do nível 1 ao 5). No nível máximo `can_play()` devolve `false`. Sem esse teto, um jogador no topo nasceria depois do último checkpoint e correria até o fim do chão, caindo no vazio sem nada encerrar a corrida.

**`Global.get_absolute_day()`** existe por causa disso: `Global.player["day"]` vai de 1 a 5 e reseta na virada de semana, então não serve para cooldown — um cooldown de 2 dias iniciado no dia 4 precisa continuar valendo no dia 1 da semana seguinte. O helper devolve `(week - 1) * 5 + day`.

**O limite de nível é por corrida, não por área.** `MinigameManager._session_active` é ligado por `begin_session()` e o desfecho o consome. Já foi feito errado uma vez: cada `Area2D` tinha o próprio guard `finished`, o que só impedia a **mesma** área de disparar duas vezes — com vários checkpoints no mapa, o jogador subia um nível em cada um que atravessasse. Um guard por área é sempre insuficiente aqui.

A ordem de `begin_session()` também importa: ela é chamada em `_begin_game()`, quando a contagem termina, e **não** em `_ready()`. Nos níveis 2+ o jogador nasce logo depois do checkpoint anterior; se a sessão já estivesse ativa, uma área poderia disparar antes de ele poder jogar. `_exit_tree()` chama `end_session()` para nenhuma sessão aberta sobrar para a próxima entrada.

### Fim de corrida: alerta de resultado

Os dois desfechos (`level.gd`, checkpoint que encerra a corrida, e `obstacle.gd`, batida) chamam `MinigameManager.show_result_and_return(headline)`. Ele abre um alerta com a escolaridade e o salário **atuais** (`result_text()`; na primeira corrida já com todos os níveis que o jogador subiu) e só quando o jogador confirma `_return_to_world()` roda a mesma sequência de antes: `TutorialManager.on_minigame_finished()` e `TransitionManager.change_scene(WORLD_SCENE)`. O tutorial só avança depois do OK.

- **`AlertManager.alert_immediate()`**, não `alert()`: durante a corrida os alertas externos estão adiados (`defer_alerts()` em `minigame.gd`), e este precisa abrir na hora. O alerta trava o gameplay, então o jogador para onde estava enquanto lê.
- **Graça no espaço:** espaço é o pulo e é também o atalho de confirmar do alerta. O jogador está martelando a tecla quando bate, e um aperto desses fecharia o alerta sem dar para ler. `alert()`/`alert_immediate()` aceitam `space_grace_msec` (aqui `AlertManager.SPACE_GRACE_MSEC` = 500 ms), tempo em que o atalho é ignorado; o clique no botão continua valendo. É **opt-in por alerta**: aplicar a todos quebraria o fluxo do tutorial, que fecha alertas no mesmo instante em que abrem.

### HUD do minigame (nível e salário)

Os labels `Level` e `Salary` ficam em `Hud` (`CanvasLayer`, `layer = 10`) > `Margin` > `Box`, no canto superior direito. **Não podem ser filhos da `Camera2D`**: filho de câmera é desenhado no mundo e herda o `zoom = 4`, então um texto de 8 px saía pequeno e esticado 4x, embaçado. No `CanvasLayer` o texto é rasterizado no tamanho final da tela, sem mexer no zoom nem nas escalas do personagem (e o `Game_Over`, que continua filho da câmera por causa do caminho fixo em `obstacle.gd`, ainda tem o mesmo defeito).

`minigame.gd._refresh_hud()` lê `school_level` e `salary` de `Global.player` e só reescreve o texto quando o valor muda. Roda em `_ready()` e no início de `_process()`, **antes** dos early-returns: o checkpoint trava o gameplay no mesmo quadro em que o nível sobe (e `MinigameManager` chama `Global.update_salary()`), e o HUD ainda precisa mostrar os valores novos.

### Mapa do minigame

Layout em `scenes/minigame/minigame.tscn`, com 4 obstáculos por checkpoint:

| x | nó | papel |
|---|---|---|
| 170 | `Marker_1` | spawn do nível 1 |
| 449 | `Level1` | checkpoint → nível 2 |
| 465 | `Level1/Marker_2` | spawn do nível 2 |
| 564, 720, 876, 1032 | `obstacle2`..`obstacle5` | |
| 1188 | `Level2` | checkpoint → nível 3 |
| 1204 | `Marker_3` | spawn do nível 3 |
| 1344, 1500, 1656, 1812 | `obstacle6`..`obstacle9` | |
| 1968 | `Level3` | checkpoint → nível 4 |
| 1984 | `Marker_4` | spawn do nível 4 |
| 2124, 2280, 2436, 2592 | `obstacle10`..`obstacle13` | |
| 2748 | `Level4` | checkpoint → nível 5 (máximo) |

Obstáculos em `y = -43`, checkpoints em `y = -115`, espaçamento de 156 px entre obstáculos — o mesmo dos dois originais. O trecho inicial (`Marker_1` → `Level1`) não tem obstáculos: são só 279 px, curtos demais para quatro, e os nós existentes não foram movidos.

`minigame.gd` escolhe o spawn por `SPAWN_MARKERS[school_level - 1]` e posiciona a câmera em `marker + CAMERA_OFFSET`, em vez dos antigos `cam_marker`/`cam_marker2` (que continuam na cena, sem uso).

**O chão é um `TileMapLayer` e precisou ser estendido junto.** Ele é gravado como `tile_map_data = PackedByteArray(...)`: 2 bytes de cabeçalho e 12 bytes por célula (6 × int16 LE: `x`, `y`, `source_id`, `atlas_x`, `atlas_y`, `alternative`). A linha do chão fica em `y = -2`, `source_id = 4`, e `atlas_x` segue o ciclo `4,5,6` a partir de `x = 31`. Ia de `x = 6` a `69` (mundo 96–1120) e agora vai até `x = 190` (mundo 96–3056). Ao mexer nisso de novo, **valide gerando as células já existentes e comparando byte a byte com o arquivo antes de escrever** — um erro aqui apaga o chão inteiro.

`minigame_door.gd` checa `can_play()` antes de entrar, mostra `lock_reason()` no `Hint` do painel da porta e dispara um alerta se o jogador insistir no ENTER (uma vez só por aproximação — `is_key_pressed` é verdadeiro todo frame).

**Tela de início.** `minigame.gd` monta um `CanvasLayer` em `layer = 50` (acima do display de tempo em 5, abaixo do `AlertManager` em 100, para as mensagens de tutorial ficarem por cima). O fluxo é: `_ready()` trava com `Global.lock_gameplay()` → o botão "Começar" só aparece quando `AlertManager.panel.visible` é falso e `TutorialManager.pending_messages` está vazio → clicar inicia a contagem de 3 s → `_begin_game()` destrava.

O `_exit_tree()` devolve o lock se a cena for abandonada antes de começar. Isso não é teórico: o minigame tem um menu de pausa que leva ao menu principal, e sem essa devolução o contador de `gameplay_locked` ficaria preso e travaria o jogo inteiro.

**Tempo congelado durante o minigame da escola:** Ao entrar na escola, `MinigameManager.is_in_minigame = true` (que sincroniza `Global.in_school_minigame = true`) e `Global.play_time = false`. O `TimeManager._process()` e `EventsManager._process()` são suspensos enquanto o jogador estiver na cena da escola. Isso impede que a simulação do mundo principal interfira no minigame: a stamina não decai, o aviso das 18h e a penalidade/teletransporte da meia-noite não acontecem, e eventos inesperados não são sorteados durante a corrida. Além disso, `AlertManager._close_alert()` e `pause_menu.toggle_pause()` não religam `play_time` enquanto `Global.in_school_minigame` for verdadeiro. Ao sair da cena (checkpoint, colisão ou menu), `is_in_minigame` volta a `false` no `_exit_tree()`, e o mundo principal (`main_game.gd`) retoma o relógio com `Global.play_time = true`.

## 12.3 Prazos, juros, cobrança automática e semana repetida

**Linha do tempo de uma conta** (contas da casa e eventos que cobram; **bônus ficam de fora**; contas de empreendimento têm regra própria, a de -25% de receita, e não entram aqui):

| Campo | Conta da casa | Evento |
|---|---|---|
| `due_week` — vence no **fim** (último dia) dessa semana | geração + 1 | semana em que nasceu |
| `limit_week` — cobrada sozinha no fim dessa semana | geração + 2 | semana de origem + 1 |

Pagar até o fim da semana do vencimento custa o valor original. Depois, o valor cresce **10% ao dia, composto** (`DebtRules.INTEREST_PER_DAY`), a partir do dia seguinte ao vencimento. Cinco dias de atraso = 1,1⁵ ≈ 1,61x.

**O valor com juros é sempre derivado do dia atual** (`current_amount()` em `HouseBillsManager`/`EventsManager`, que usam `scripts/economy/debt_rules.gd`); o `amount` gravado nunca muda. É o que faz uma semana repetida devolver os mesmos valores em vez de aplicar juros sobre juros já cobrados.

**Cobrança automática** em `TimeManager._process_week_rollover()`, depois que as missões passam e **antes** de liberar a semana seguinte: soma tudo com `limit_week <= semana que acaba` (com juros até o último dia dela), recebe o salário, e cobra tirando primeiro da carteira e depois do banco (`Global.charge_funds()`). Se carteira + banco + salário não cobrem, a semana se repete. Essa checagem vem **antes** de `verify_missions()` para o alerta "Parabéns, vai para a próxima semana" não aparecer logo antes de "você perdeu a semana" (`MissionManager.all_passed()` responde sem alertar). A cobrança usa `register_expense(..., count_as_daily_spend = false)`: acontece já no dia 1 da semana nova e não pode estragar o "dia sem gastar" de um dia ainda não jogado.

**Pagamento manual** (banco) também usa carteira + banco e o valor de hoje com juros.

**Semana repetida** (`TimeManager._repeat_week()`, tanto por missão falhada quanto por dívida): `Global.restore_week_start()` devolve **dinheiro, banco e o estado das contas** à foto tirada no início da semana (`Global.snapshot_week_start()`, chamada em `new_game()`, no fim de cada virada de semana bem-sucedida e em `ensure_player_state()` para saves antigos). As contas entram na foto de propósito: sem elas, pagar uma conta numa tentativa fracassada devolveria o dinheiro **e** deixaria a conta paga — dívida perdoada de graça.

**Limite conhecido:** compras (estoque da casa, FIIs, empreendimentos, upgrades) **não** voltam na foto. Dá para gastar, falhar a semana de propósito e ficar com o que comprou e o dinheiro de volta. Fechar isso exige restaurar mais estado (inventário, `FIIManager`, `enterprises`).

**Escritório com relógio parado.** `Global.in_office` é ligado por `office.gd._ready()` e solto em `_exit_tree()`. `Global.time_frozen_by_scene()` (minigame da escola **ou** escritório) é o ponto único que `AlertManager._close_alert()`, `TutorialManager`, `pause_menu`, `EventsManager` e `TimeManager._process()` consultam antes de religar/avançar `play_time`; sem isso, fechar um alerta dentro do escritório religava o relógio.

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


## 15. Missões — conexão com Escritório e Tutorial

As missões semanais foram projetadas para reforçar, na prática, os tópicos apresentados no Escritório e as mensagens do tutorial. Abaixo está o mapeamento por semana que serve como referência para designers e para agentes (Claude) que vão editar ou criar missões.

- Semana 1
  - Missões: economizar_100, sem_gastar, registrar_gastos
  - Escritório (Nível 1): Controle de gastos — Necessidade x Desejo, Planejamento de gastos, Orçamento semanal
  - Tutorial: mensagens iniciais sobre começar a controlar gastos e onde ver o histórico (Banco/Casa).
  - Justificativa: exercícios de economia básica e registro de despesas para ensinar o hábito de acompanhar gastos.

- Semana 2
  - Missões: construir_reserva (guardar R$120 no banco), economizar_300, resolver_evento
  - Escritório (Nível 2): Reserva de emergência, Imprevistos financeiros, Eventos inesperados no jogo
  - Tutorial: instrução para checar o painel "Contas / Bônus pendentes" no Banco e como pagar/resgatar
  - Justificativa: força a prática de guardar reserva no banco (saldo bancário) e a interação com o sistema de eventos (resolver pendências geradas nesta semana).

- Semana 3
  - Missões: aplicar_poupanca (guardar ao menos R$ 50 na poupança), analise_gastos, economizar_300_s3
  - Escritório (Nível 3): Investimentos básicos — Poupança, Renda fixa e títulos públicos, Juros compostos (o motor da riqueza), Inflação (ladrão invisível e ganho real), Liquidez (reserva vs longo prazo)
  - Banco: Desbloqueio da aba Poupança (Renda Fixa com liquidez D+0 e rendimento diário de 0,5% com juros compostos)
  - Tutorial: guia sobre poupança, renda fixa e juros compostos
  - Justificativa: consolidar o hábito de poupar e iniciar investimentos em Renda Fixa antes de se expor à Renda Variável.

- Semana 4
  - Missões: investir_fii (comprar cotas de FII), diversificar (mais de 1 fundo), lucro_fii (ganhar R$ 5 com investimentos)
  - Escritório (Nível 4): Mercado financeiro — Ações e Fundos Imobiliários (FIIs), Risco e Retorno (balança dos mercados), Diversificação (Markowitz e ovos na cesta), Proventos e Dividendos (renda passiva e reinvestimento), Volatilidade e Efeito Manada
  - Banco: Desbloqueio das abas FII-shop e Portfolio
  - Tutorial: recomendações para diversificação de fundos, proventos semanais e perigo de vender na baixa
  - Justificativa: introduzir risco/retorno, diversificação real, proventos de FIIs e controle emocional contra o efeito manada.

- Semana 5
  - Missões: comprar_empreeendimento (compre ao menos 1 empreendimento), pagar_contas_emp (pague contas pendentes do empreendimento), repor_estoque
  - Escritório (Nível 5): Empreendedorismo — estoque, contas semanais, folha, capacidade, equipamentos
  - Tutorial: passo a passo para comprar um empreendimento, gerenciar estoque e pagar contas no banco
  - Justificativa: forçar o jogador a praticar gestão de um negócio, incluindo pagamento de contas e reposição de estoque.

Notas de implementação e manutenção

- Quando criar novas missões, sempre indique a `week` alvo e associe `type` que pode ser verificado por `MissionManager._check_mission()`.
- Missões que envolvem ações em UI (por exemplo, pagar no banco) devem ter checadores que validem o estado persistente (por exemplo, `pending_events` com `status != "pending"` ou `EnterpriseManager.get_pending_bills()` igual a 0).
- A missão `pending_event_resolve` foi implementada para contar apenas eventos gerados na semana corrente (campo `week_generated` nos eventos). Isso evita que eventos antigos falsamente satisfaçam a missão da semana.
- Evite chamar _game_over() diretamente ao falhar missões sem revisar a pedagogia — hoje a falha exibe alerta e obriga a repetir a semana, o que é menos punitivo e mais formativo.

Referências:
- Missions: `singletons/MissionManager.gd`
- Escritório (conteúdo): `scripts/world/office/office.gd`
- Eventos inesperados: `singletons/EventsManager.gd`, `singletons/UnexpectedEvents.gd`
- Painel de contas e banco: `scripts/world/bank/banco.gd`


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
- ~~`spend_today` é zerado a cada hora~~ — desatualizado: hoje `spend_today` só zera uma vez por dia, em `_advance_to_next_day()` (`TimeManager.gd`). Não afeta mais `no_spend_day`/`no_impulse`
- o processamento financeiro e o balanceamento dos preços ainda precisam ser validados em runtime real do Godot
- `EnterpriseManager.process_all_daily_operations()` é chamado **antes** de `Global.player["day"]` ser atualizado no `TimeManager`, então o dia gravado no histórico e nas despesas fica defasado em 1. A operação não duplica (o guard `last_operation_day` funciona), mas as datas registradas estão erradas
- `restaurant.tscn`, `arcade.tscn` e `shopping.tscn` foram escritas à mão como cenas herdadas (`[node name="X" instance=ExtResource(...)]` na raiz). **Validado em runtime**: carregam e renderizam corretamente. O mesmo padrão pode ser reusado para outras telas
- o ambiente do agente **não tem o Godot disponível por CLI**. Nenhuma alteração de cena ou script pode ser validada automaticamente — tudo precisa ser testado no editor. Priorize layout por container (que é autocorretivo) em vez de offsets em pixel
- o `history` de cada empreendimento é limitado a 50 entradas e as pendências resolvidas de `pending_events` a 30, mas `Global.player["expense_history"]` e `home_actions_log` continuam crescendo sem limite no save
- **a tela do banco ainda tem o `history_panel` criado por script** em `(710,25)`-`(1100,615)`, sobreposto à área do `TabContainer` `Investimentos`. Os demais painéis (FIIs, carteira, eventos) já viraram abas e não se empilham mais
- `scripts/world/main_game.gd` tem três teclas de debug no `_process`: **Page Down** entra no restaurante, **Page Up** entra no mercado e **End** dá R$ 10.000 ao jogador. Precisam sair antes de qualquer build de entrega
- `AlertManager._close_alert()` sempre devolve `Global.play_time = true` quando destrava. Como as cenas de interior (banco, casa, empreendimentos, mercado) rodam com `play_time = false`, qualquer alerta aberto lá dentro faz o tempo voltar a correr ao fechar. Afeta `enterprise_management.gd` e agora também `banco.gd`. É a mesma pendência do `play_time` sem contador, citada em 3.2

### 16.1 Bugs críticos corrigidos numa auditoria (trace estático, sem Godot disponível)

Achados por simulação manual de ponta a ponta do jogo. Documentados aqui para ninguém reintroduzir a mesma classe de erro:

- **Morrer de fome/sede travava o relógio de qualquer partida nova, para sempre.** `TimeManager.day_end_pending` só era zerado em `_advance_to_next_day()`, que nunca roda no caminho de morte (`_close_day()` retorna cedo). Como `TimeManager` é autoload e sobrevive ao game over, a flag ficava presa em `true` e `sleep()`/`_add_minute()` paravam de funcionar até reiniciar o app. Corrigido com `TimeManager.reset()`, chamado por `Global.new_game()`.
- **Sair do minigame do parque pelo menu de pausa podia travar o jogo inteiro.** `park_minigame_session.gd` não tinha `_exit_tree()`; `pause_menu.gd`'s "Sair" troca de cena direto, sem rodar `ParkMinigameManager.end_session()` nem devolver o lock de um quiz aberto. Corrigido com um `_exit_tree()` espelhando o padrão já usado em `scripts/minigame/minigame.gd`.
- **Repetir uma semana por missão falhada zerava a receita/despesa dos empreendimentos a semana inteira, em silêncio.** O guard de `process_daily_operation()` (`EnterpriseManager.gd`) compara dia+semana; como a semana não muda numa repetição, os dias 1-7 da tentativa nova colidem com os carimbos da tentativa fracassada. Corrigido com `EnterpriseManager.reset_operation_guards()`, chamado no ramo de falha de `TimeManager._process_week_rollover()`.
- **`FIIManager.update_prices()` nunca tinha um chamador.** Os preços dos FIIs nunca se moviam — a "volatilidade" documentada não existia em runtime. Agora é chamado uma vez por dia, em `TimeManager._close_day()`, junto de `EnterpriseManager.process_all_daily_operations()`.
- **`Global.DRINK_THIRST` (migração de saves antigos) estava fora de sincronia com `market.gd["Bebidas"]`**: faltava `milk` e sobravam `hot_chocolate`/`milkshake`/`beer`/`wine`, que não existem mais no mercado. Corrigido para espelhar exatamente as 7 bebidas atuais — `tests/test_mechanics.gd` cobre isso.
- **Evento com escolha sorteado de novo enquanto uma pendência anterior do mesmo tipo ainda está aberta**: o jogador clicava numa opção e `create_pending_event()` descartava a pendência em silêncio (`has_pending_from_source()`), sem feedback nenhum. Agora `EventsManager.trigger_evento()` checa o mesmo guard **antes** de mostrar o diálogo de escolha, igual ao caminho sem escolha já fazia.
- **`ensure_player_state()` nunca recuperava a chave `"name"`.** Um save sem ela fazia `main_menu.gd` (único lugar com acesso direto por colchete, `!= ""` contra `null`) tratar um save inválido como válido. `"name"` entrou na lista de chaves normalizadas.
- **`apply_home_action()` (Descansar/Assistir TV) podia zerar a fome sem checar na hora.** Corrigido, e depois superado: fome/sede zerada não é mais game over, vira desmaio (ver 10.1) — `apply_home_action()` chama `TimeManager.collapse_if_needs_depleted()` ao fim.
- **Dinheiro não tinha piso.** As penalidades da meia-noite (-R$30) e de semana ruim (-R$25) podiam empurrar o saldo indefinidamente negativo, sem consequência nem recuperação. Ambas agora usam `max(0.0, ...)`.
- Baixa severidade, também corrigidos: o check do painel de missões só reavaliava no instante em que F era pressionado, não enquanto ficava segurado; `had_no_spend_day`/`no_spend_days_count` não resetavam numa semana repetida.

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
- **toda troca de cena passa por `TransitionManager.change_scene()`**, nunca por `get_tree().change_scene_to_file()` direto, e **sem `await`** no call site (ver 3.9)
- ao mudar balanceamento de empreendimentos, revise os números citados no nível 5 do escritório
- ao adicionar conteúdo de tutorial, decida a qual semana ele pertence e use `weekly_messages` (ver 3.3); o onboarding linear é só a semana 1

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
- `singletons/HouseBillsManager.gd`
- `scripts/enterprise/enterprise_management.gd`
- `scripts/enterprise/data/restaurant_info.gd`
- `scripts/enterprise/data/arcade_info.gd`
- `scripts/enterprise/data/shopping_info.gd`
- `scenes/world/ui/enterprise-view.tscn`
- `scenes/world/places/home.tscn`
- `singletons/AlertManager.gd`
- `singletons/TutorialManager.gd`
- `singletons/EventsManager.gd`
- `singletons/UnexpectedEvents.gd`
- `scenes/world/places/bank.tscn`
- `scenes/world/main_game.tscn`
- `scripts/world/doors/enterprise_door.gd`
- `scripts/world/office/office.gd`
- `themes/font_theme.tres` e `themes/label.tres`
- `singletons/Logger.gd`

Este documento deve ser usado como material de contexto para qualquer tarefa futura do projeto.

## 21. Estado dos planos na raiz do projeto

| Arquivo | Status |
|---|---|
| `FIX_PLAN.md` | **concluído** — as 13 etapas de correção foram aplicadas |
| `ENTERPRISE_PLAN.md` | **concluído** na primeira versão, mais as mecânicas de nível, funcionários, capacidade e inadimplência |
| `CLAUDE_HOME_REFACTOR_PROMPT.md` | **concluído** — `home.gd` ancorado em `home.tscn` |
| `CLAUDE_ENTERPRISE_VIEW_REFACTOR_PLAN.md` | **concluído** — as 8 tarefas; o layout evoluiu depois para grid 2×2 e por fim para `TabContainer` |
| `CLAUDE_EVENTS_REWORK_PLAN.md` | **concluído** — ver seção 12.1. Fora do escopo por decisão registrada: expiração/multa automática e painel de eventos em casa |
| `MINIGAME_LOCK_PLAN.md` | **concluído** — ver seção 12.2 |
| `WEEKLY_TUTORIAL_PLAN.md` | **concluído** — ver seção 3.3 |
| `SCENE_TRANSITIONS_PLAN.md` | **concluído** — ver seção 3.9. Exceção deliberada: `Global.new_game()` continua trocando de cena direto |
| `SAVE_SLOTS_PLAN.md` | **não implementado** — plano aprovado, nenhuma etapa executada. O save continua único em `user://savegame.json` |

Ao retomar o `SAVE_SLOTS_PLAN.md`, ajustes que o plano ainda não reflete: `Global.player` ganhou as chaves `enterprises`, `pending_events`, `minigame_progress` e `tutorial_weeks_shown`; o `EnterpriseManager` **não** precisa de um `reset()` como o `FIIManager`, porque não guarda estado próprio no autoload. Inclua no checklist "empreendimentos, contas pendentes, trava do minigame e progresso do tutorial não vazam entre slots".
