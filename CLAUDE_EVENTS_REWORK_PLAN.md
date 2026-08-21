# Plano de Tarefas: Reestruturação dos "Eventos Inesperados"

Objetivo

- Remodelar o sistema de "eventos inesperados" para que:
  1. Comece a aparecer somente a partir do início da semana 2 do jogo (ou seja, quando a semana atual for >= 2).
  2. Não altere automaticamente o dinheiro do jogador ao ser gerado. Em vez disso, cada evento deve criar uma "conta" (debito) ou um "bônus" (crédito) pendente que o jogador poderá pagar/resgatar manualmente via interface (preferencialmente no Banco; alternativa possível: Painel "Casa/Inbox").
  3. Garantir que o conceito e conteúdo de eventos inesperados exista e seja integrado ao nível 2 do escritório (office level 2). Se não existir, adicioná-lo, com documentação explicando o que são os eventos e como lidar com eles.

Contexto / Restrições

- Não alterar a jogabilidade existente além do comportamento dos eventos.
- Não cobrar/creditar o jogador automaticamente ao gerar o evento; apenas quando o jogador usar a ação de "Pagar" / "Resgatar".
- Manter persistência via SaveManager; eventos pendentes devem sobreviver a reloads/saves.
- Usar as singletons centrais (Global, TimeManager, EventManager / nome similar) quando possível. Se o projeto não possuir um EventManager, criar um arquivo singleton `EventManager.gd` e registrá-lo em project.godot autoload.

Recomendações de localização de UI

- Padrão (recomendado): Banco — adicionar um painel fixo (UnexpectedEventsPanel ou PendingEventsPanel) dentro da cena do banco (ex.: scenes/world/ui/bank.tscn ou scripts/world/bank/banco.gd). O painel deve conter:
  - ScrollContainer + VBoxContainer para listar eventos pendentes
  - Para cada item: título, descrição curta, valor, tipo (conta / bônus), semana gerada, botão `Pagar` ou `Resgatar`, botão `Detalhes` (opcional)
- Alternativa: Casa — painel "Inbox" em home para mostrar eventos pendentes (útil quando o jogador está em casa e quer cuidar de contas)
- O claude pode escolher um dos dois, mas documentar a decisão. Preferir Banco por coerência com fluxo financeiro.

Modelo de Dados (sugestão)

- Estrutura de evento pendente (Dictionary / Resource):
  {
    "id": String unique,
    "title": String,
    "description": String,
    "week_generated": int,
    "amount": float,
    "is_bonus": bool,         # true = crédito (bônus/recebível), false = débito (conta a pagar)
    "status": "pending" | "paid" | "collected" | "expired",
    "location": "bank" | "home",
    "due_week": int?,        # opcional: semana para expirar ou data limite
    "created_by": String?,   # opcional: id do evento
  }

- Armazenamento: adicionar em `Global.player.pending_events` (array de dictionaries) ou criar `Global.pending_events` dependendo da arquitetura atual. Garantir que SaveManager persista.

API / Funções a adicionar/alterar (sugestões)

1. EventManager.gd (singleton)
   - maybe_spawn_events(current_week): Verificar se deve criar eventos nesta semana (usar RNG, probabilidades e regras de balanceamento). Somente executar quando current_week >= 2.
   - create_pending_event(event_data): Normaliza e insere em Global.player.pending_events e chama SaveManager.save_player() ou similar.
   - pay_event(event_id): Localiza o evento; se is_bonus == false e jogador tiver dinheiro suficiente, subtrai o montante (via Global: Global.player.money -= amount), atualiza status para "paid" e persiste.
   - collect_event(event_id): Se is_bonus == true, adiciona o monto ao dinheiro do jogador e marca como "collected".
   - expire_events(current_week): Marcar/tratar eventos vencidos (status = "expired"); lógica de penalidade opcional (documentar antes de aplicar).

2. TimeManager.gd
   - Ao avançar de semana (trigger de fim de semana), chamar EventManager.maybe_spawn_events(new_week) — mas somente se new_week >= 2.

3. Global.gd
   - Garantir campo `player.pending_events` inicializado (array vazio) e serializável.

4. Bank UI (scripts/world/bank/banco.gd)
   - Adicionar/atalhar métodos para renderizar `Global.player.pending_events` filtrando por location == "bank" e criando linhas com botões Pagar/Resgatar.
   - Os botões devem chamar EventManager.pay_event / collect_event.

5. Home UI (scripts/world/home/home.gd)
   - (Opcional) Adicionar painel de eventos em casa (filtrar location == "home").

6. Market / Outros geradores de evento
   - Remover qualquer lógica que ao gerar evento imediatamente altere `player.money`.

Tarefas Priorizadas e Passo-a-passo para o Claude

1) Análise e descoberta (env. 30-60 min)
   - Procurar por scripts responsáveis por eventos inesperados (nomes prováveis: event*, unexpected*, random_event*, world_events.gd)
   - Procurar pontos onde esses scripts chamam Global.player.money +=/-= e registrar todas as ocorrências.
   - Listar cenas relacionadas: bank, home, office/level2, market.
   - Entregar um breve relatório (1-2 parágrafos) sobre onde eventos são gerados hoje e onde já mexem no dinheiro.

2) Implementar EventManager (se não existir) ou refatorar existente (1-3 horas)
   - Criar/ajustar singleton EventManager.gd com a API indicada (maybe_spawn_events, create_pending_event, pay_event, collect_event, expire_events).
   - Garantir que a geração de eventos só ocorra quando week >= 2 (baseado na resposta: iniciar no começo da semana 2).
   - Modificar todos os pontos que hoje adicionam/subtraem `player.money` ao gerar evento, para que chamem `create_pending_event` em vez de mexer no dinheiro.

3) Persistência (30-60 min)
   - Adaptar SaveManager para salvar `player.pending_events` (se a serialização atual do player já incluir arrays/dictionaries, apenas garantir que o campo exista e é persistido).
   - Testar salvar/carregar manualmente (simulação): criar eventos, salvar, fechar e recarregar jogo (ou emular carga) e checar se `pending_events` persiste.

4) UI do Banco (1-3 horas)
   - Adicionar um painel fixo em banco.tscn ou estender a renderização existente:
     - ScrollContainer > VBoxContainer para linhas de evento
     - Cada linha: HBoxContainer com Labels (title, amount, week) e botões (Pagar / Resgatar / Detalhes)
   - Conectar botões para chamar EventManager.pay_event / collect_event.
   - Aplicar o tema `font_thems.tres` consistentemente nos novos nodes.
   - Garantir que ao pagar/resgatar a UI atualize e SaveManager salve o novo estado.

5) UI da Casa (opcional/alternativa) (30-90 min)
   - Se o claude optar por também mostrar em Casa: adicionar painel `HomeEventsPanel` com mesma estrutura, mas filtrando location == "home".

6) Integração com Level 2 do Escritório (office level 2) (30-120 min)
   - Procurar cena do escritório nível 2 (ex.: scenes/world/office/level2.tscn ou scripts correlatos).
   - Verificar se existe conteúdo referente a eventos inesperados. Se NÃO existir, adicionar:
     - Documentação em comentários (ou em um arquivo README curto) explicando o que são eventos inesperados: "ocorrências financeir(o)as que podem gerar contas a pagar ou bônus a receber; apresentados ao jogador como itens pendentes que exigem ação manual no banco/na casa."
     - No nível 2 do escritório, incluir uma seção informativa (Label/Panel) que explica os eventos e um atalho para abrir o Banco (ou o Painel de Eventos) para o jogador: por exemplo, um botão "Ver Contas/Bônus" que leva ao banco/abre overlay.
   - Se já existir, confirmar que o texto/explicação está coerente e ajustar linguagem/links.

7) Testes e validação (30-90 min)
   - Teste manual 1: Iniciar nova run, verificar que nenhum evento aparece no menu inicial ou antes da semana 2.
   - Teste manual 2: Avançar para semana 2 (ou simular) e validar que eventos gerados são listados em `pending_events` e aparecem no Banco.
   - Teste manual 3: Pagar uma conta -> confirmar débito em `Global.player.money` e estado `paid`, salvar/carregar e confirmar persistência.
   - Teste manual 4: Coletar bônus -> confirmar acréscimo em `Global.player.money` e estado `collected`.
   - Teste manual 5: Verificar logs (Logger.gd) para entradas pertinentes sobre criação/pagamento/coleta de eventos.

8) Documentação e comentários (15-30 min)
   - Adicionar comentários nos arquivos alterados explicando o fluxo e motivos da mudança.
   - Atualizar PROJECT_KNOWLEDGE.md com o novo fluxo de eventos (breve parágrafo e links para EventManager e banco UI).

Critérios de Aceitação

- Antes da semana 2: nenhum evento inesperado deve ser gerado (nem mostrado no menu inicial ou em qualquer painel).
- A geração de eventos passa a criar apenas itens pendentes (contas/bonuses) armazenados em `player.pending_events`.
- Nenhuma alteração automática no `player.money` ao criar o evento.
- O Banco (ou Home, se escolhido) exibe corretamente os eventos pendentes com opção de Pagar/Resgatar e atualiza o saldo apenas quando ação explícita é tomada.
- Os eventos pendentes persistem entre saves/loads.
- O nível 2 do escritório contém referência/explicação dos eventos inesperados e um atalho/indicação de onde pagar/resgatar.

Notas para o Claude (instruções específicas)

- Ao refatorar, procurar por quaisquer scripts que atualmente façam `Global.player.money +=` ou `-= ` quando um evento aparece. Substituir por criação de `pending_event` e comentar a alteração (ex.: "Refatorado: não aplicar alteração monetária automática; criada pending_event").
- Se houver regras de expiração/penalidade automática, documentar e propor comportamento (ex.: event.expire_week -> penalidade) antes de aplicar. Evitar penalidades automáticas sem confirmação do usuário.
- Trabalhar preferencialmente com recursos (Resource) ou dictionaries serializáveis para os eventos; garantir compatibilidade com SaveManager.
- Manter o tema `font_thems.tres` em todos os nodes novos.

Checklist final para entrega (o que o claude deve enviar ao terminar)

- [ ] PR/branch com mudanças (lista de arquivos alterados)
- [ ] Relatório curto declarando onde eventos eram gerados originalmente e o que foi mudado
- [ ] Implementação do EventManager (ou refatoração) com testes manuais descritos
- [ ] UI do Banco (e opcionalmente Home) que mostra e permite pagar/coletar eventos
- [ ] Atualização do SaveManager para persistir pending_events
- [ ] Atualização / adição de conteúdo no nível 2 do escritório explicando eventos
- [ ] Atualização do PROJECT_KNOWLEDGE.md descrevendo o novo fluxo

Tempo estimado total: 3–8 horas (depende do estado atual dos scripts e da necessidade de criar um EventManager do zero).

---

Se quiser, ao terminar eu posso revisar o diff (lista de arquivos e mudanças) e rodar uma checagem rápida nos scripts mais prováveis (procurando por ocorrências de alterações diretas de `player.money`) antes de abrir o PR. Quer que eu já verifique os arquivos atualmente no repositório e faça uma proposta de locais exatos a alterar (lista de hits)?