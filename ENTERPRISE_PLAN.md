# Plano de desenvolvimento — Sistema de empreendimentos

Implementar as etapas em ordem. Cada etapa deve ser testada no Godot antes de iniciar a próxima. A mecânica deve funcionar para três negócios diferentes usando uma única lógica de administração e uma interface gerada por script.

## 1. Objetivo da mecânica

Adicionar ao mapa principal prédios que podem ser comprados e transformados em negócios administráveis pelo jogador.

O jogador deverá conseguir:

- encontrar um prédio disponível no mapa;
- ver informações básicas do empreendimento;
- comprar o prédio, se tiver dinheiro suficiente;
- abrir a interface de administração do negócio;
- comprar estoque;
- pagar contas de água e luz;
- comprar móveis e equipamentos;
- acompanhar receitas, despesas e lucro;
- melhorar o nível de aprimoramento do estabelecimento;
- receber lucro conforme a eficiência e o nível do negócio;
- administrar mais de um empreendimento ao longo do jogo, se tiver dinheiro para isso.

A mesma mecânica deve ser utilizada para todos os negócios. O que muda entre eles são os dados: nome, preço, estoque, equipamentos, custos, capacidade, receita e identidade visual.

## 2. Negócios disponíveis

Usar inicialmente estes três negócios:

### 2.1 Pequeno — Restaurante Sabor da Praça

Perfil: negócio de entrada, com menor custo e operação simples.

Dados iniciais sugeridos:

- `id`: `restaurant_small`
- `name`: `Restaurante Sabor da Praça`
- `size`: `small`
- `purchase_price`: `1500.0`
- `base_daily_revenue`: `70.0`
- `base_daily_expenses`: `25.0`
- `water_bill`: `20.0`
- `electricity_bill`: `30.0`
- `starting_capacity`: `10`
- `max_level`: `5`
- categoria principal: alimentação

Estoques possíveis:

- ingredientes básicos;
- bebidas;
- embalagens;
- itens de limpeza.

Equipamentos possíveis:

- fogão simples;
- geladeira pequena;
- mesas básicas;
- placa de divulgação.

### 2.2 Médio — Fliperama Neon

Perfil: negócio intermediário, com investimento maior e maior potencial de receita.

Dados iniciais sugeridos:

- `id`: `arcade_medium`
- `name`: `Fliperama Neon`
- `size`: `medium`
- `purchase_price`: `12000.0`
- `base_daily_revenue`: `420.0`
- `base_daily_expenses`: `150.0`
- `water_bill`: `80.0`
- `electricity_bill`: `220.0`
- `starting_capacity`: `25`
- `max_level`: `5`
- categoria principal: lazer

Estoques possíveis:

- fichas ou créditos;
- bebidas;
- lanches;
- produtos de limpeza.

Equipamentos possíveis:

- máquina de arcade;
- máquina de dança;
- sistema de som;
- iluminação neon;
- balcão de atendimento.

### 2.3 Grande — Centro Comercial Mundo Mix

Perfil: empreendimento avançado, caro de comprar e manter, com maior capacidade de gerar lucro.

Dados iniciais sugeridos:

- `id`: `shopping_large`
- `name`: `Centro Comercial Mundo Mix`
- `size`: `large`
- `purchase_price`: `85000.0`
- `base_daily_revenue`: `2600.0`
- `base_daily_expenses`: `950.0`
- `water_bill`: `450.0`
- `electricity_bill`: `1100.0`
- `starting_capacity`: `100`
- `max_level`: `5`
- categoria principal: comércio

Estoques possíveis:

- produtos para lojas;
- materiais de manutenção;
- itens de limpeza;
- suprimentos de segurança;
- publicidade.

Equipamentos possíveis:

- sistema de segurança;
- escadas rolantes ou decoração;
- gerador de energia;
- praça de alimentação;
- painel de publicidade;
- sistema de climatização.

### 2.4 Justificativa dos preços

Os preços devem criar três momentos financeiros diferentes:

- Restaurante: objetivo alcançável depois das primeiras semanas;
- Fliperama: investimento de médio prazo, exigindo economia e planejamento;
- Centro Comercial: meta de longo prazo, exigindo salário, investimentos e lucro acumulado.

Não aproximar os preços dos três negócios. A diferença deve ser perceptível para que o jogador entenda progressão, risco operacional e planejamento de capital.

Os valores acima são valores iniciais de balanceamento, não devem ser tratados como definitivos antes do teste de economia com o salário, gastos e FIIs atuais.

## 3. Arquitetura geral

A arquitetura deve separar dados, estado, regras e interface.

### 3.1 Dados estáticos dos negócios

Criar uma estrutura de dados por negócio, preferencialmente com `Resource` customizado:

- `scripts/enterprise/enterprise_info.gd`
- `scripts/enterprise/data/restaurant_info.gd`
- `scripts/enterprise/data/arcade_info.gd`
- `scripts/enterprise/data/shopping_info.gd`

Alternativa compatível com a arquitetura atual: usar Dictionaries em arquivos separados. A preferência é `Resource`, porque permite editar os dados pelo Inspector e evita espalhar valores hardcoded na interface.

Cada `EnterpriseInfo` deve conter:

- `enterprise_id`;
- `display_name`;
- `description`;
- `size`;
- `category`;
- `purchase_price`;
- `base_daily_revenue`;
- `base_daily_expenses`;
- `water_bill`;
- `electricity_bill`;
- `starting_capacity`;
- `max_level`;
- `stock_items`;
- `equipment_items`;
- `upgrade_items`;
- `visual_scene` ou referência visual do prédio;
- multiplicador de risco;
- multiplicador de operação;
- texto de compra e de administração.

Cada item de estoque, conta ou equipamento deve seguir uma estrutura comum:

```gdscript
{
    "id": "basic_ingredients",
    "name": "Ingredientes básicos",
    "category": "stock",
    "price": 80.0,
    "quantity": 1,
    "revenue_bonus": 12.0,
    "capacity_bonus": 0,
    "description": "Mantém o negócio funcionando por um período."
}
```

### 3.2 Estado persistente do jogador

Adicionar o estado dos empreendimentos em `Global.data_model` e garantir a normalização em `ensure_player_state()`.

Estrutura sugerida:

```gdscript
player["enterprises"] = {
    "restaurant_small": {
        "owned": false,
        "level": 0,
        "cash_balance": 0.0,
        "stock": {},
        "equipment": {},
        "pending_bills": {},
        "daily_revenue": 0.0,
        "daily_expenses": 0.0,
        "total_revenue": 0.0,
        "total_expenses": 0.0,
        "total_profit": 0.0,
        "last_operation_day": 0,
        "last_operation_week": 0,
        "history": []
    }
}
```

Regras:

- o jogador não pode perder dados de um negócio já comprado;
- novos campos devem receber valores padrão quando um save antigo for carregado;
- o estado deve ficar em `Global.player`, nunca apenas em uma cena;
- o dinheiro utilizado na compra, nas contas e nos equipamentos deve sair de `Global.player["money"]`;
- o saldo do empreendimento deve ser separado do dinheiro pessoal apenas se essa distinção for implementada de forma consistente.

Recomendação inicial: usar `Global.player["money"]` para compras e despesas, e registrar a contabilidade do negócio nos campos `total_revenue`, `total_expenses` e `total_profit`. Não criar uma segunda carteira até a primeira versão estar estável.

## 4. EnterpriseManager

Criar `singletons/EnterpriseManager.gd` como autoload responsável pelas regras comuns dos três negócios.

O manager não deve saber detalhes exclusivos de restaurante, fliperama ou shopping. Ele deve receber um `enterprise_id`, buscar o `EnterpriseInfo` correspondente e operar sobre os dados.

### 4.1 Responsabilidades

- registrar os dados disponíveis dos três negócios;
- retornar informações por `enterprise_id`;
- verificar se o jogador pode comprar um prédio;
- comprar um empreendimento;
- verificar propriedade;
- comprar estoque;
- pagar contas;
- comprar equipamentos e móveis;
- calcular receita diária;
- calcular despesas diárias;
- calcular lucro;
- aplicar avanço de nível;
- gerar histórico de operações;
- processar a operação diária;
- emitir signals para atualizar a UI;
- fornecer dados prontos para a interface.

### 4.2 Signals sugeridos

```gdscript
signal enterprise_purchased(enterprise_id)
signal enterprise_updated(enterprise_id)
signal enterprise_operation_finished(enterprise_id, result)
signal enterprise_error(message)
signal enterprise_balance_changed(enterprise_id)
```

### 4.3 Funções sugeridas

```gdscript
func get_enterprise_info(enterprise_id: String) -> Dictionary
func get_player_enterprise(enterprise_id: String) -> Dictionary
func is_owned(enterprise_id: String) -> bool
func can_buy(enterprise_id: String) -> Dictionary
func buy_enterprise(enterprise_id: String) -> Dictionary
func get_available_stock(enterprise_id: String) -> Array
func buy_stock(enterprise_id: String, item_id: String, quantity: int) -> Dictionary
func get_pending_bills(enterprise_id: String) -> Dictionary
func pay_bill(enterprise_id: String, bill_id: String) -> Dictionary
func buy_equipment(enterprise_id: String, equipment_id: String) -> Dictionary
func calculate_daily_revenue(enterprise_id: String) -> float
func calculate_daily_expenses(enterprise_id: String) -> float
func calculate_daily_profit(enterprise_id: String) -> float
func process_daily_operation(enterprise_id: String) -> Dictionary
func get_dashboard_data(enterprise_id: String) -> Dictionary
```

Toda função que altera estado deve retornar um Dictionary com resultado explícito:

```gdscript
{
    "success": true,
    "message": "Estoque comprado.",
    "money_spent": 80.0,
    "profit_change": 0.0
}
```

Em caso de falha:

```gdscript
{
    "success": false,
    "message": "Dinheiro insuficiente.",
    "reason": "insufficient_money"
}
```

## 5. Modelo de operação e lucro

O lucro precisa ser compreensível para o jogador e previsível o suficiente para permitir planejamento.

### 5.1 Receita diária

Usar uma fórmula comum:

```text
receita_base = info.base_daily_revenue
bonus_nivel = 1.0 + ((nivel - 1) * 0.20)
bonus_equipamentos = soma dos bonuses dos equipamentos
bonus_estoque = fator de estoque disponível
receita_diaria = receita_base * bonus_nivel + bonus_equipamentos + bonus_estoque
```

Uma alternativa mais fácil de balancear:

```text
receita_diaria = receita_base * multiplicador_do_nivel * multiplicador_da_operacao
```

Sugestão de multiplicador de nível:

- nível 1: `1.00`
- nível 2: `1.20`
- nível 3: `1.45`
- nível 4: `1.75`
- nível 5: `2.15`

### 5.2 Despesas

As despesas devem incluir:

- conta de água;
- conta de luz;
- custo de estoque consumido;
- manutenção dos equipamentos;
- custo operacional diário;
- eventuais taxas ou impostos futuros.

As contas podem vencer diariamente ou semanalmente. Recomendação: gerar água e luz semanalmente, com aviso antes do vencimento, para não transformar o jogo em uma sequência de microcobranças.

### 5.3 Estoque

O estoque deve ter quantidade e consumo.

Fluxo sugerido:

1. o jogador compra estoque;
2. o empreendimento opera;
3. parte do estoque é consumida;
4. se o estoque estiver baixo, a receita cai;
5. se estiver zerado, o negócio pode operar com receita mínima ou ficar temporariamente parado;
6. a UI mostra quantidade atual, consumo estimado e dias restantes.

O estoque não deve ser apenas cosmético. Ele precisa criar uma decisão entre:

- comprar muito e imobilizar dinheiro;
- comprar pouco e correr risco de perder receita;
- manter reserva de caixa para contas e emergências.

### 5.4 Aprimoramentos

Equipamentos e móveis devem melhorar um ou mais indicadores:

- receita;
- capacidade de atendimento;
- consumo de estoque;
- custo de manutenção;
- risco de operação;
- felicidade ou reputação futura.

Cada item deve ter:

```gdscript
{
    "id": "new_equipment",
    "name": "Equipamento aprimorado",
    "price": 500.0,
    "level_required": 1,
    "revenue_bonus": 40.0,
    "capacity_bonus": 5,
    "maintenance_cost": 12.0,
    "description": "Aumenta a capacidade e a receita diária."
}
```

O nível do empreendimento deve subir por investimento, não apenas por tempo. Exemplo:

- nível 1: prédio comprado;
- nível 2: primeiro conjunto de móveis/equipamentos;
- nível 3: estoque e equipamentos intermediários;
- nível 4: melhorias avançadas;
- nível 5: estabelecimento totalmente aprimorado.

## 6. Interface única gerada pelo EnterpriseManager

Criar uma cena reutilizável, por exemplo:

- `scenes/ui/enterprise_management.tscn`
- `scripts/enterprise/enterprise_ui.gd`

O `EnterpriseManager` calcula os dados e a UI renderiza. A UI não deve duplicar regras financeiras.

### 6.1 Abertura da interface

A interface deve ser aberta a partir do prédio ou de uma cena de administração:

```gdscript
EnterpriseUI.open_for("restaurant_small")
```

A UI então chama:

```gdscript
EnterpriseManager.get_dashboard_data("restaurant_small")
```

Ao abrir outro negócio, a mesma cena é reutilizada com outro ID:

```gdscript
EnterpriseUI.open_for("shopping_large")
```

### 6.2 Painéis da interface

A interface deve ter pelo menos:

#### Cabeçalho

- nome do empreendimento;
- tamanho e categoria;
- nível atual;
- status: funcionando, sem estoque, contas vencidas ou falido;
- botão para sair.

#### Dashboard

- dinheiro pessoal atual;
- receita do dia;
- despesas do dia;
- lucro estimado;
- lucro acumulado;
- contas pendentes;
- nível de estoque;
- capacidade atual;
- próxima operação ou fechamento.

#### Estoque

- lista de itens disponíveis para compra;
- preço unitário;
- quantidade atual;
- consumo estimado;
- dias de estoque restantes;
- botões de comprar quantidade;
- alerta de estoque baixo.

#### Contas

- água;
- luz;
- manutenção;
- valor;
- vencimento;
- status pago/pendente;
- botão de pagamento;
- aviso quando o pagamento reduzir o dinheiro pessoal.

#### Móveis e equipamentos

- itens já comprados;
- itens bloqueados por nível;
- preço;
- bônus de receita/capacidade;
- custo de manutenção;
- botão de compra;
- descrição do impacto.

#### Relatório financeiro

- receita por dia e semana;
- despesas por categoria;
- lucro líquido;
- total investido no negócio;
- retorno acumulado;
- histórico das últimas operações.

### 6.3 Renderização orientada a dados

A UI deve usar funções genéricas:

```gdscript
func render_dashboard(data: Dictionary) -> void
func render_stock(items: Array, state: Dictionary) -> void
func render_bills(bills: Array) -> void
func render_equipment(items: Array, state: Dictionary) -> void
func render_history(history: Array) -> void
```

Não criar `restaurant_ui.gd`, `arcade_ui.gd` e `shopping_ui.gd`. A diferença deve vir dos arrays recebidos pelo `EnterpriseManager`.

### 6.4 Atualização da interface

Conectar a UI aos signals do manager:

- depois de comprar estoque, atualizar estoque e dinheiro;
- depois de pagar uma conta, atualizar contas e saldo;
- depois de comprar equipamento, atualizar nível, receita e lista de equipamentos;
- depois do fechamento diário, atualizar dashboard e histórico;
- em caso de erro, mostrar mensagem de alerta sem fechar a interface.

## 7. Prédios e cenas do mapa principal

Identificar os prédios atualmente sem função e escolher três para os empreendimentos.

Criar um script comum para a interação do prédio:

- `scripts/world/enterprise/enterprise_building.gd`

O prédio deve ter um `enterprise_id` exportado:

```gdscript
@export var enterprise_id: String = "restaurant_small"
```

O mesmo script será usado nos três prédios.

### 7.1 Estados visuais do prédio

O prédio deve mostrar estado visual diferente para:

- disponível para compra;
- comprado, mas ainda não administrado;
- funcionando;
- contas atrasadas;
- sem estoque;
- totalmente aprimorado.

### 7.2 Interação

Ao entrar na área do prédio:

- mostrar nome e preço se ainda não for comprado;
- mostrar "Administrar" se já for do jogador;
- bloquear interação quando `Global.gameplay_locked` estiver ativo;
- abrir alerta de confirmação antes da compra;
- chamar `EnterpriseManager.buy_enterprise(enterprise_id)`;
- abrir a interface após compra bem-sucedida.

Não colocar lógica de dinheiro diretamente no script da porta/prédio. O prédio apenas detecta interação e chama o manager.

### 7.3 Estrutura de cena sugerida

Para cada prédio:

```text
EnterpriseBuilding (Area2D ou Node2D)
├── Sprite2D
├── CollisionShape2D
├── InteractionLabel
├── CameraFocusPoint (opcional)
└── EnterpriseBuilding.gd
```

Usar uma cena base reutilizável se os prédios tiverem o mesmo comportamento de interação.

## 8. Integração com o tempo

Adicionar o processamento de empreendimentos ao `TimeManager`.

Ao avançar um dia:

1. processar cada empreendimento que o jogador possui;
2. consumir estoque;
3. calcular receita;
4. registrar despesas;
5. adicionar receita ao dinheiro do jogador ou ao caixa do empreendimento;
6. atualizar lucro acumulado;
7. gerar contas quando chegar o período definido;
8. emitir `enterprise_updated`;
9. salvar automaticamente em momento apropriado.

Recomendação: o processamento financeiro deve acontecer uma única vez por dia, usando `last_operation_day` e `last_operation_week` para evitar duplicidade ao trocar de cena ou recarregar o mapa.

O tempo gasto em ações de administração deve ser definido explicitamente. Exemplos:

- comprar estoque: 1 hora;
- pagar contas: 0,5 hora;
- comprar equipamento: 2 horas;
- revisar relatório: 1 hora;
- operação diária: automática, sem clique repetido.

Se o projeto ainda não possui uma função genérica para gastar horas, criar no `TimeManager` ou em `Global` uma função validada, por exemplo:

```gdscript
func try_spend_time(hours: float) -> Dictionary
```

Ela deve verificar o horário, atualizar hora/dia e retornar sucesso ou erro.

## 9. Integração com dinheiro, gastos e missões

Todas as despesas empresariais devem aparecer no histórico financeiro com categoria própria:

- `enterprise_purchase`;
- `enterprise_stock`;
- `enterprise_bill`;
- `enterprise_equipment`;
- `enterprise_maintenance`.

Usar `Global.register_expense()` quando a função representar uma saída real de dinheiro do jogador.

Adicionar, futuramente, missões específicas:

- comprar o primeiro empreendimento;
- obter lucro em uma semana;
- manter estoque por determinado número de dias;
- pagar todas as contas no prazo;
- alcançar determinado nível de aprimoramento;
- administrar dois negócios;
- recuperar o investimento inicial.

Não implementar essas missões antes de o fluxo básico de lucro e despesas estar validado.

## 10. Save/load

Atualizar `SaveManager` para garantir que `Global.player["enterprises"]` seja salvo e carregado.

Ao carregar um save antigo:

- criar a chave `enterprises` se não existir;
- criar os três registros padrão com `owned = false`;
- preservar apenas dados válidos;
- corrigir tipos numéricos e Dictionaries ausentes;
- não apagar negócios já comprados.

Testes obrigatórios:

- comprar restaurante, salvar, fechar e carregar;
- confirmar que propriedade, nível, estoque, equipamentos, contas e lucro foram preservados;
- carregar save anterior à mecânica sem crash;
- confirmar que dados inválidos não quebram a interface.

## 11. Alertas e feedback

Usar `AlertManager` para mensagens importantes:

- compra confirmada;
- dinheiro insuficiente;
- conta paga;
- estoque comprado;
- estoque baixo;
- equipamento comprado;
- empreendimento sem caixa;
- negócio operando com receita reduzida;
- negócio sem estoque;
- tentativa de comprar prédio já comprado.

Alertas de confirmação de compra devem informar:

- nome do negócio;
- preço;
- dinheiro restante;
- consequência da compra;
- opção de cancelar.

Manter a regra atual do projeto para confirmação de alertas: botão e tecla Espaço, sem usar Enter caso essa regra continue vigente.

## 12. Balanceamento inicial

Antes de considerar a mecânica pronta, montar uma tabela de teste:

| Negócio | Compra | Receita diária base | Despesa diária base | Lucro estimado inicial | Tempo para recuperar compra |
|---|---:|---:|---:|---:|---:|
| Restaurante | R$ 1.500 | R$ 70 | R$ 25 | R$ 45 | aproximadamente 34 dias |
| Fliperama | R$ 12.000 | R$ 420 | R$ 150 | R$ 270 | aproximadamente 45 dias |
| Centro Comercial | R$ 85.000 | R$ 2.600 | R$ 950 | R$ 1.650 | aproximadamente 52 dias |

Essas estimativas não incluem contas separadas, estoque, equipamentos, eventos e upgrades. Usar a tabela como ponto de partida e recalcular após integrar a economia real.

Evitar que:

- o negócio pequeno seja sempre a melhor escolha;
- o negócio grande seja impossível de alcançar;
- upgrades recuperem o investimento rápido demais;
- contas deixem o jogador sem dinheiro sem aviso;
- o jogador lucre sem manter estoque ou pagar despesas.

Adicionar uma prévia na UI:

- "retorno estimado";
- "lucro médio diário";
- "dias para recuperar investimento";
- aviso de risco e despesas.

## 13. Ordem prática de implementação

### Etapa 1 — Definir contratos

- criar o modelo de `EnterpriseInfo`;
- definir o Dictionary de estado persistente;
- definir IDs e nomes dos três negócios;
- registrar sinais e retornos padronizados;
- documentar o formato dos itens.

### Etapa 2 — Preparar o estado global

- adicionar `enterprises` ao `data_model`;
- implementar normalização em `ensure_player_state()`;
- garantir compatibilidade com saves antigos;
- adicionar funções auxiliares para criar estado padrão.

### Etapa 3 — Criar os dados dos negócios

- criar `RestaurantInfo`;
- criar `ArcadeInfo`;
- criar `ShoppingInfo`;
- preencher estoques, contas e equipamentos;
- validar que os IDs são únicos;
- revisar preços e bônus.

### Etapa 4 — Implementar o EnterpriseManager

- carregar os três dados;
- implementar compra;
- implementar propriedade;
- implementar estoque;
- implementar contas;
- implementar equipamentos;
- implementar cálculo de receita, despesa e lucro;
- implementar histórico;
- adicionar logs relevantes usando `Logger`.

### Etapa 5 — Processar o ciclo diário

- integrar com `TimeManager`;
- garantir processamento único por dia;
- testar receita sem estoque;
- testar contas vencidas;
- testar lucro e prejuízo;
- testar troca de cena sem duplicar operação.

### Etapa 6 — Criar a interface única

- criar a cena de administração;
- criar dashboard;
- criar abas ou painéis de estoque, contas, melhorias e relatório;
- conectar botões aos métodos do manager;
- conectar signals de atualização;
- exibir erros e sucessos.

### Etapa 7 — Integrar os prédios do mapa

- adicionar script comum;
- configurar `enterprise_id` em cada cena;
- mostrar estado visual;
- abrir compra ou administração;
- bloquear durante alertas e pausas.

* não é necessáro se preocupar com quais serão os prédio o mapa, só crie a cena de cada um que depois o Dev criará as portas no mundo principal que redirecionarão para essas cenas

### Etapa 8 — Integrar save/load

- salvar estado completo;
- carregar dados antigos;
- testar corrupção ou campos ausentes;
- confirmar persistência de todas as operações.

### Etapa 9 — Balancear e polir

- testar com diferentes salários;
- testar compra em semanas iniciais e avançadas;
- revisar custos de contas e estoque;
- ajustar retorno dos upgrades;
- adicionar feedback visual e histórico;
- confirmar que administrar o negócio exige escolhas reais.

## 14. Testes de aceitação

### Compra

- jogador sem dinheiro não consegue comprar;
- jogador com dinheiro compra o prédio uma única vez;
- valor sai de `Global.player["money"]`;
- prédio muda para o estado comprado;
- interface de administração abre corretamente.

### Estoque

- compra reduz dinheiro;
- estoque aumenta na quantidade correta;
- estoque é consumido durante a operação;
- estoque baixo altera a receita;
- estoque zerado produz aviso e comportamento definido.

### Contas

- contas são geradas no ciclo correto;
- contas aparecem na interface;
- pagamento reduz dinheiro;
- conta paga não pode ser paga novamente;
- conta vencida altera o status do negócio conforme a regra definida.

### Equipamentos

- equipamento tem pré-requisito e preço;
- dinheiro insuficiente impede a compra;
- bônus aparece no dashboard;
- equipamento comprado não pode ser comprado novamente se for único;
- nível do empreendimento atualiza corretamente.

### Lucro

- receita, despesas e lucro são exibidos separadamente;
- prejuízo não é apresentado como lucro;
- relatório mantém histórico;
- upgrades aumentam o lucro de forma mensurável;
- negócios diferentes usam a mesma lógica e produzem resultados conforme seus dados.

### Interface única

- abrir o restaurante carrega dados do restaurante;
- abrir o fliperama carrega dados do fliperama;
- abrir o centro comercial carrega dados do centro comercial;
- nenhuma informação do negócio anterior permanece na interface;
- botões e listas são reutilizados sem duplicação de script.

### Tempo e save

- operações com custo de tempo atualizam o relógio;
- trocar de cena não duplica receita;
- salvar e carregar preserva o estado;
- iniciar um save antigo cria os dados padrão dos negócios;
- alertas bloqueiam o gameplay durante confirmação.

## 15. Riscos e decisões pendentes

### Caixa pessoal ou caixa empresarial

Decisão recomendada para a primeira versão: despesas saem do dinheiro pessoal e receitas entram no dinheiro pessoal, enquanto o manager mantém apenas os registros contábeis. Separar caixas pode ser uma evolução posterior.

### Frequência das contas

Decisão recomendada: contas de água e luz semanais, com despesas operacionais diárias. Isso oferece planejamento sem excesso de cliques.

### Operação automática ou manual

Decisão recomendada: operação automática ao passar o dia. A administração manual fica para estoque, contas, equipamentos e decisões estratégicas.

### Falência

Não implementar falência definitiva na primeira versão. Usar status temporário, como `warning` ou `closed`, quando faltar dinheiro, estoque ou contas pagas. A falência pode ser adicionada depois com confirmação clara.

### Quantidade de negócios

Permitir comprar os três negócios, mas manter o custo total alto o suficiente para exigir progressão. A interface pode ter uma tela de lista de empreendimentos no futuro, mas a primeira versão pode abrir cada negócio diretamente no prédio.

## 16. Resultado esperado

Ao final da implementação, o jogador deverá conseguir:

1. encontrar três prédios disponíveis no mapa;
2. comprar um negócio adequado ao seu momento financeiro;
3. administrar estoque, contas e equipamentos;
4. observar como melhorias aumentam receita e lucro;
5. gastar dinheiro e tempo em decisões de empreendedorismo;
6. acompanhar o resultado financeiro em uma interface clara;
7. salvar e continuar a administração depois de fechar o jogo;
8. usar a mesma interface e o mesmo código para negócios com identidades e preços diferentes.

A regra central da implementação é:

> Dados específicos ficam nos arquivos de informação de cada negócio. Regras, estado, operações e interface são compartilhados pelo `EnterpriseManager` e pela cena de administração reutilizável.
