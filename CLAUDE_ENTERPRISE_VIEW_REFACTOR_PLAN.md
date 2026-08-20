# Plano de tarefas para refatoração da interface de empreendimentos

## Objetivo

Usar a cena base `scenes/world/ui/enterprise-view.tscn` como estrutura visual fixa e deixar o script responsável apenas por preencher os containers dinâmicos conforme o empreendimento carregado.

A lógica do jogo deve continuar igual: o conteúdo muda de acordo com `enterprise_id`, mas a estrutura visual da interface continua sendo a mesma para todos os três negócios.

## Regra principal

Essa refatoração deve seguir o mesmo princípio da casa:

- fixo na cena: painel principal, labels, containers, categorias, botões de navegação
- dinâmico no script: linhas de negócio, estoque, contas, equipamentos, ações e mensagens de status

A lógica de negócio e as regras do empreendimento não devem ser alteradas. O trabalho é estrutural e visual.

## Contexto real da cena atual

A cena já foi criada em `scenes/world/ui/enterprise-view.tscn` e a estrutura atual é esta:

```text
EnterpriseView (Control)
└── Margin (MarginContainer)
    └── VBoxContainer
        ├── Title-label (Label)
        ├── Summary-label (Label)
        ├── Status-label (Label)
        ├── Sections (HBoxContainer)
        │   ├── Business-panel (PanelContainer)
        │   │   └── VBoxContainer
        │   │       ├── Title (Label)
        │   │       └── Business-list (VBoxContainer)
        │   │
        │   ├── Stock-panel (PanelContainer)
        │   │   └── VBoxContainer
        │   │       ├── Title (Label)
        │   │       └── Stock-list (VBoxContainer)
        │   │
        │   ├── Bills-panel (PanelContainer)
        │   │   └── VBoxContainer
        │   │       ├── Title (Label)
        │   │       └── Bills-list (VBoxContainer)
        │   │
        │   └── Equipment-panel (PanelContainer)
        │       └── VBoxContainer
        │           ├── Title (Label)
        │           └── Equipment-list (VBoxContainer)
        │
        └── Exit-button (Button)
```

## Nodos fixos que devem ser usados pelo script

Esses nodos já existem e devem ser reusados sem recriar a árvore visual:

- `EnterpriseView`
- `EnterpriseView/Margin`
- `EnterpriseView/Margin/VBoxContainer`
- `EnterpriseView/Margin/VBoxContainer/Title-label`
- `EnterpriseView/Margin/VBoxContainer/Summary-label`
- `EnterpriseView/Margin/VBoxContainer/Status-label`
- `EnterpriseView/Margin/VBoxContainer/Sections`
- `EnterpriseView/Margin/VBoxContainer/Sections/Business-panel`
- `EnterpriseView/Margin/VBoxContainer/Sections/Business-panel/VBoxContainer`
- `EnterpriseView/Margin/VBoxContainer/Sections/Business-panel/VBoxContainer/Business-list`
- `EnterpriseView/Margin/VBoxContainer/Sections/Stock-panel`
- `EnterpriseView/Margin/VBoxContainer/Sections/Stock-panel/VBoxContainer`
- `EnterpriseView/Margin/VBoxContainer/Sections/Stock-panel/VBoxContainer/Stock-list`
- `EnterpriseView/Margin/VBoxContainer/Sections/Bills-panel`
- `EnterpriseView/Margin/VBoxContainer/Sections/Bills-panel/VBoxContainer`
- `EnterpriseView/Margin/VBoxContainer/Sections/Bills-panel/VBoxContainer/Bills-list`
- `EnterpriseView/Margin/VBoxContainer/Sections/Equipment-panel`
- `EnterpriseView/Margin/VBoxContainer/Sections/Equipment-panel/VBoxContainer`
- `EnterpriseView/Margin/VBoxContainer/Sections/Equipment-panel/VBoxContainer/Equipment-list`
- `EnterpriseView/Margin/VBoxContainer/Exit-button`

## O que deve ser dinâmico

Esses elementos continuam sendo criados e renderizados pelo script:

- linhas de negócio dentro de `Business-list`
  - upgrade
  - contratação de funcionários
  - demissão
- linhas de estoque dentro de `Stock-list`
  - nome do item
  - preço
  - quantidade em estoque
  - botão de comprar
- linhas de contas dentro de `Bills-list`
  - nome da conta
  - valor
  - botão de pagar
- linhas de equipamentos dentro de `Equipment-list`
  - nome do equipamento
  - preço
  - botão de comprar quando não comprado
- mensagens vazias quando a lista estiver vazia

## Tarefas do Claude

### Tarefa 1 — Ler a cena real e mapear os nodos fixos

**Objetivo:** usar os nomes exatos da cena `enterprise-view.tscn`, sem inventar estruturas alternativas.

**Ações:**
- abrir a cena
- localizar os nodos listados acima
- confirmar que a árvore visual fixa está correta
- dar preferência ao uso de `@onready` ou `get_node` para conectar os nodos fixos

**Critério de sucesso:**
- o agente referencia corretamente cada nodo fixo já existente
- não recria `Margin`, `VBoxContainer`, `Sections`, `Business-panel` etc. em `_build_ui()`

### Tarefa 2 — Refatorar o script para usar a cena fixa

**Objetivo:** substituir a lógica de criação da interface em código pela lógica de preenchimento dos containers já existentes.

**Ações:**
- remover ou reduzir a criação manual do layout principal em `_build_ui()`
- manter a interface visual seguindo a cena e não reescrevendo a árvore
- adaptar as variáveis do script (`title_label`, `summary_label`, `status_label`, `stock_list`, etc.) para os nomes corretos da cena
- manter a lógica funcional que já existe

**Critério de sucesso:**
- o layout da cena continua visualmente estável
- a lógica de renderização funciona dentro dos containers fixos

### Tarefa 3 — Preservar a lógica de negócio

**Objetivo:** manter toda a lógica de dados e eventos sem alteração.

**Ações:**
- preservar os métodos e regras de atualização:
  - `_refresh_ui()`
  - `_status_text()`
  - `_render_business()`
  - `_render_stock()`
  - `_render_bills()`
  - `_render_equipment()`
  - `_clear_list()`
  - `_show_result()`
  - `_on_buy_stock()`
  - `_on_pay_bill()`
  - `_on_buy_equipment()`
  - `_on_exit_pressed()`
- manter a conexão com `EnterpriseManager`
- garantir que os botões criados em runtime continuem sendo conectados corretamente

**Critério de sucesso:**
- compra, pagamento, contratação e upgrade funcionam igual
- os dados continuam vindos do mesmo manager

### Tarefa 4 — Reaproveitar o mesmo `.tscn` para os 3 empreendimentos

**Objetivo:** a mesma cena base deve funcionar para qualquer empreendimento, sem necessidade de duplicar a estrutura.

**Ações:**
- manter `@export var enterprise_id: String = "restaurant_small"`
- garantir que o script preenche os container de acordo com o empreendimento carregado
- não criar um `.tscn` separado para cada negócio sem necessidade

**Critério de sucesso:**
- o mesmo arquivo serve para restaurante, fliperama e shopping
- o conteúdo muda conforme `enterprise_id`, não o layout

### Tarefa 5 — Validar se faltam nodos essenciais

**Objetivo:** prevenir criação de elementos redundantes ou incompletos.

**Verificação obrigatória:**
- há `Title-label`?
- há `Summary-label`?
- há `Status-label`?
- há `Sections`?
- há painel para `Negócio`?
- há painel para `Estoque`?
- há painel para `Contas`?
- há painel para `Equipamentos`?
- há `Exit-button`?

Se algum desses nodos estiver ausente, o Claude deve avisar explicitamente e pedir que o usuário crie esse nodo antes de continuar. Neste estado atual, a cena já contém todos eles, então nenhuma correção de estrutura fixa é necessária.

## Regras de implementação

- Não recriar a estrutura principal da cena em código.
- Usar os nodos já existentes como referência.
- Preencher só os containers dinâmicos.
- Não alterar a lógica do gameplay.
- Não criar uma cena separada para cada empreendimento se a mesma base serve para os três.
- Não renomear o `enterprise_id` nem a lógica do manager.

## Resultado esperado

Ao final, o agente deve entregar:

1. a interface de empreendimentos conectada à cena fixa
2. a estrutura visual reaproveitada para todos os negócios
3. o conteúdo dinâmico preenchendo corretamente os containers
4. a lógica funcional preservada intacta
5. a compatibilidade com o mesmo script atual, apenas ajustado ao layout fixo

## Observação final

A cena atual está pronta para esse padrão: um único `enterprise-view.tscn` para os três negócios. O Claude deve usar esse arquivo como a fonte de verdade do layout e o script como a fonte de verdade dos dados.

Se a cena sofrer alterações no futuro, o Claude deve reler o arquivo antes de continuar e confirmar se a estrutura fixa ainda está compatível com o script.
