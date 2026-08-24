# Plano de Tarefas: Contas da Casa + Tutorial

Objetivo

- Implementar um sistema de contas da casa que o jogador precisa pagar no banco.
- Essas contas devem aparecer de forma recorrente, seguindo o ritmo semanal do jogo.
- A lógica deve ser consistente com o modelo já usado para contas de empreendimentos, mas separada e adaptada ao contexto da casa.
- O tutorial deve incluir essa mecânica e explicar como o jogador deve lidar com as contas da casa, que ficam pendentes até o pagamento no banco.

Contexto do projeto

- As contas dos empreendimentos já existem em `EnterpriseManager` e são geradas no fim da semana em `TimeManager`.
- A casa ainda não tem uma estrutura equivalente para despesas domésticas.
- A ideia é manter o mesmo padrão: gerar conta semanal, armazenar como pendente, exibir no banco e pagar manualmente.
- O jogador não deve perder dinheiro automaticamente por apenas gerar a conta; o impacto financeiro só acontece quando ele paga.

Arquivos prováveis a serem alterados

- `singletons/Global.gd`
- `singletons/TimeManager.gd`
- `scripts/world/bank/banco.gd`
- `singletons/TutorialManager.gd`
- `singletons/SaveManager.gd` (se necessário)
- `project.godot` (se novo singleton for necessário)
- `PROJECT_KNOWLEDGE.md` (documentação final)

Regras de negócio esperadas

1. A casa gera contas semanais.
2. As contas da casa aparecem no banco, em um painel de pendências.
3. O pagamento acontece manualmente pelo banco.
4. As contas ficam pendentes antes do pagamento; não devem reduzir o dinheiro do jogador na criação.
5. O sistema deve ser persistente entre saves.
6. O tutorial precisa explicar o que são essas contas, quando aparecem e como pagar.
7. A lógica da casa não deve quebrar a lógica já existente de empreendimentos.

Estrutura de dados sugerida

Adicionar ao `Global.player`:

- `pending_house_bills`: Array de dicionários
- `house_bill_history`: Array de dicionários (opcional, mas recomendado)

Estrutura de cada conta da casa:

```gdscript
{
  "id": "house_bill_2025_3_water",
  "title": "Conta de água",
  "description": "Despesa da casa da semana atual.",
  "amount": 120.0,
  "week": 3,
  "due_week": 4,
  "paid": false,
  "category": "house",
  "created_at_day": 1,
  "created_at_week": 3
}
```

Tipos de contas que o Claude pode considerar:

- Conta de água
- Conta de luz
- Aluguel / condomínio (se a casa for tratada como moradia)
- Internet / telefone (opcional)
- Manutenção básica (opcional, se o jogo quiser ampliar)

Recomendação prática para o Claude

- Começar com três tipos básicos: água, luz e aluguel/condomínio.
- Isso bate com o conceito da vida real e mantém a lógica simples.

Tarefas a serem executadas pelo Claude

1. Revisão da arquitetura atual
   - Abrir `Global.gd`, `TimeManager.gd`, `EnterpriseManager.gd` e `banco.gd` para comparar o padrão atual de contas.
   - Entender como as contas de empreendimento são criadas e pagas.
   - Reusar o mesmo modelo de `pending_bills` para o caso da casa, mas em um armazenamento separado para não conflitar.

2. Criar o modelo de dados da casa
   - No `Global.player`, garantir que `pending_house_bills` exista.
   - Garantir que esse campo também seja inicializado em `new_game()` e em `ensure_player_state()`.
   - Se necessário, sincronizar com `SaveManager` para persistência.

3. Gerar contas da casa no fim da semana
   - Em `TimeManager._add_minute()`, no momento em que week rollover acontece, chamar uma rotina nova de geração de contas da casa.
   - A função deve verificar se o jogador possui a casa/estado residencial ativo.
   - Gerar apenas uma vez por semana para não duplicar contas.
   - As contas devem ter `due_week = week + 1` para refletir prazo de pagamento.

4. Criar a lógica de “conta pendente”
   - A conta deve ser armazenada em `pending_house_bills` com `paid = false`.
   - O saldo do jogador não deve mudar ao gerar a conta.
   - A cobrança só acontece quando o jogador escolhe pagar no banco.

5. Adicionar o fluxo de pagamento no banco
   - No `banco.gd`, criar um painel para contas da casa.
   - Listar todos os itens de `Global.player["pending_house_bills"]` com status `paid == false`.
   - Para cada conta, mostrar:
     - nome da conta
     - valor
     - semana de criação
     - botão "Pagar"
   - Ao clicar em pagar:
     - validar se o jogador tem dinheiro suficiente
     - debitar `Global.player["money"]`
     - marcar a conta como `paid = true`
     - remover ou mover para histórico
     - salvar o progresso

6. Implementar persistência
   - Garantir que `pending_house_bills` e `house_bill_history` sejam salvos e carregados corretamente.
   - Validar o comportamento após um save e reload.
   - Confirmar que a conta não desaparece nem duplica ao carregar.

7. Integrar a lógica ao tutorial
   - Atualizar `TutorialManager.gd` para incluir uma mensagem explicando as contas da casa.
   - O tutorial deve dizer:
     - que o jogador também tem despesas de casa
     - que essas contas aparecem semanalmente
     - que elas ficam pendentes e devem ser pagas no banco
     - que o dinheiro só é debitado quando o jogador pagar
   - A mensagem pode aparecer na etapa em que o jogador já está inserido no ciclo de gestão financeira, depois do início do jogo ou após algumas semanas de gameplay.

8. Revisar a UX e textos
   - Garantir que os textos de tutorial e do banco sejam claros e bem escritos.
   - Exemplo de texto do tutorial:
     - "Além dos gastos do mercado, sua casa também gera contas fixas. Elas aparecem semanalmente e precisam ser pagas no banco para evitar prejuízos."
   - O banco deve deixar claro que esse painel é de contas da casa.

9. Validar regras críticas
   - Conta da casa não aparece antes do início do ciclo semanal correto.
   - Conta da casa não reduz o dinheiro na criação.
   - Conta só é removida após pagamento.
   - O jogador pode pagar apenas se tiver saldo suficiente.
   - Save/load preserva o estado das pendências.
   - O tutorial fala sobre a mecânica de forma clara.

Fluxo sugerido para o tutorial

Opção A: Introdução simples (recomendada)

- Mensagem 1: "Você também precisa cuidar da sua casa. Existem despesas mensais/semanais da moradia."
- Mensagem 2: "Essas contas aparecem no banco como pendências. Pagá-las é obrigatório para manter seu orçamento saudável."
- Mensagem 3: "Você não perde dinheiro ao receber a conta; a cobrança acontece quando você a paga."

Opção B: Explicação no contexto de semana/semana 2+

- Quando o sistema atingir a segunda semana, o tutorial dispara um aviso de que as despesas da casa começaram.
- O aviso leva o jogador ao banco para ver a pendência e pagar.

Recomendação: usar a Opção A como texto formal do tutorial e a Opção B como gatilho contextual no gameplay.

Critérios de aceitação

- O jogador recebe contas da casa no fim da semana.
- As contas da casa ficam em painel do banco e podem ser pagas manualmente.
- O saldo do jogador só é alterado quando o pagamento é confirmado.
- Salvar e carregar mantém o estado das pendências.
- O tutorial explica a mecânica de forma clara.
- O sistema não conflita com as contas de empreendimentos já existentes.
- A lógica é fácil de manter e expandir.

Checklist final

- [ ] `Global.player` possui `pending_house_bills`
- [ ] `TimeManager` gera contas da casa semanalmente
- [ ] `banco.gd` lista contas da casa pendentes
- [ ] Pagamento da conta reduz dinheiro e marca como paga
- [ ] Save/load mantém as pendências corretamente
- [ ] Tutorial menciona as contas da casa e explica como pagar no banco
- [ ] Documentação atualizada em `PROJECT_KNOWLEDGE.md`

Observações importantes para o Claude

- Não misturar `pending_house_bills` com `pending_bills` de empreendimento.
- Não reaproveitar nomes de variáveis sem checagem: o projeto já usa `pending_bills` em negócios.
- Manter a regra de “gerar conta = não debitar dinheiro automaticamente”.
- Priorizar consistência com as contas de empreendimentos e o padrão do jogo.
- Sempre que criar novos textos de tutorial, usar linguagem simples e acessível para o jogador.

Tempo estimado

- 2 a 5 horas, dependendo de quão bem estruturado o fluxo de contas de empreendimento já está e de quanto o Claude precisar adaptar UI e tutorial.

Conclusão

Este plano garante que o Claude implemente uma mecânica de contas da casa de forma coerente com o restante do jogo, com pagamento manual no banco, integração ao tutorial e manutenção da lógica atual de finanças do projeto.
