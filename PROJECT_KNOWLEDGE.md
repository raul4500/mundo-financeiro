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
- `scenes/world/places/restaurant.tscn` — cena de administração do restaurante
- `scenes/world/places/arcade.tscn` — cena de administração do fliperama
- `scenes/world/places/shopping.tscn` — cena de administração do centro comercial

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
- `DoorManager`, `AlertManager`, etc. — utilitários do jogo

Esse padrão centraliza dados do jogo e evita acoplamento excessivo entre cenas.

### 3.2 Regra de ouro do estado

O estado principal do jogador fica em `Global.player`, que é um dicionário com todas as propriedades fundamentais. Qualquer lógica que dependa do jogador deve preferencialmente ler/escrever em `Global.player` em vez de variáveis locais em cena.

Isso garante:

- persistência consistente
- sincronização entre telas
- compatibilidade com save/load
- manutenção mais fácil do código

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

`scripts/world/home/home.gd` foi pensado para controlar a casa do jogador como uma UI central.

### Funções principais

- `_build_ui()` — monta interface por script
- `_update_ui()` — atualiza status da UI
- `_render_inventory()` — exibe estoque
- `_render_history()` — exibe histórico de ações
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

Ao comprar um item:

1. valida se há dinheiro suficiente
2. retira dinheiro de `Global.player["money"]`
3. registra gasto em `expense_history`
4. adiciona item ao estoque da casa via `Global.add_home_inventory_item()`
5. atualiza UI de compra

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

As cenas `restaurant.tscn`, `arcade.tscn` e `shopping.tscn` usam o mesmo script: `scripts/enterprise/enterprise_management.gd`. A diferença entre elas é apenas o valor de `enterprise_id`.

A interface gera dinamicamente:

- nome, nível e status;
- dinheiro, receita, despesas, lucro e capacidade;
- lista de estoque, preço por lote e quantidade atual;
- lista de contas pendentes;
- lista de equipamentos, preços e estado de compra;
- botões de compra, pagamento e retorno ao mapa.

### Alertas de compra

Operações recusadas atualizam o status e chamam `AlertManager.alert()`. Isso inclui dinheiro insuficiente, empreendimento não comprado, item inválido, equipamento já comprado, nível insuficiente e conta inválida.

Quando falta dinheiro, a mensagem informa o valor necessário, por exemplo: `Dinheiro insuficiente para comprar este equipamento. Você precisa de R$ 350,00.`

## 15. Principais regras de design e gameplay

### Decisões de projeto observadas

- Estado centralizado em `Global.player`
- UI dinâmica criada em script para reduzir acoplamento
- lógica de inventário e economia centralizada
- Zonas do jogo são separadas em cenas, mas o estado fica global
- o roteiro enfatiza educação financeira, planejamento e autocuidado

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
- `spend_today` é zerado a cada hora de jogo em `TimeManager._add_minute()`, não a cada dia — isso afeta as missões `no_spend_day` e `no_impulse`
- o processamento financeiro e o balanceamento dos preços ainda precisam ser validados em runtime real do Godot

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
- `singletons/Logger.gd`

Este documento deve ser usado como material de contexto para qualquer tarefa futura do projeto.
