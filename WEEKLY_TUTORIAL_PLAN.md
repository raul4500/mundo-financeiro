# Plano: Tutorial dividido por semana

## Objetivo

Hoje o passo 8 de `TutorialManager._next_step()` despeja 13 mensagens seguidas (`messages[7]` a `messages[19]`) de uma vez só, logo após o minigame — incluindo o bloco inteiro de empreendimentos, que só faz sentido bem mais tarde. Trocar isso por conteúdo que aparece **no início de cada semana**, ensinando só a mecânica que acabou de destravar naquela semana.

Critério geral: cada semana mostra 1–3 mensagens curtas, nunca um dump de parágrafos.

## Estado atual (para referência ao implementar)

- `TutorialManager.messages` tem 20 entradas (índices 0–19). `_next_step()` é uma máquina de 8 passos que roda uma vez, do início do jogo até o fim do passo 8.
- Semana e progresso de conteúdo já são semanais em outros sistemas: `MissionManager.missions_data` tem entradas 1–5, `office.gd.levels_data` tem 5 níveis destravados por `player_level = Global.player["week"]`, e `EventsManager.FIRST_EVENT_WEEK = 2`.
- `TimeManager` emite `week_changed(week)` quando `MissionManager.verify_missions()` aprova o avanço — ver `singletons/TimeManager.gd:69`.
- `Global.player["tutorial_step"]` existe mas é usado só pela máquina de 8 passos. Não há campo que registre "quais semanas já mostraram o tutorial semanal".
- `AlertManager.can_skip()` hoje só libera o botão "Pular tutorial" quando `step == 1` (a primeiríssima mensagem do jogo). Isso não deve mudar — pular é para o onboarding inicial, não para os avisos semanais, que já são curtos.

## Desenho da divisão por semana

Mapeamento mecânica → semana em que already destrava, usado para decidir o que cada aviso semanal ensina:

| Semana | O que destrava | Conteúdo do aviso |
|---|---|---|
| 1 | Escola/minigame, primeiro salário, mercado, banco, escritório (onboarding atual) | Mantém os passos 1–7 e o fechamento com mensagens 7–11 como estão hoje. Sem mudança de comportamento aqui. |
| 2 | `EventsManager` começa a sortear eventos inesperados; escritório nível 2 (reserva de emergência) | Nova mensagem curta: eventos inesperados vão aparecer, viram pendência no banco (painel "Contas e bônus pendentes"), e o escritório nível 2 explica reserva de emergência — ligar os dois. |
| 3 | Escritório nível 3 (investimentos básicos: poupança, renda fixa) | Nova mensagem curta: já dá para começar a investir no banco; sugerir ler o nível 3 do escritório antes. |
| 4 | Escritório nível 4 (mercado financeiro) | Nova mensagem curta: aprofundar em mercado financeiro no escritório. |
| 5 | Escritório nível 5 (empreendedorismo); estatisticamente é quando o jogador já tem dinheiro para cogitar um empreendimento | As mensagens 12–17 (bloco de empreendimentos) saem do passo 8 e passam a disparar aqui. Conteúdo já escrito, só muda o gatilho. |

Mensagem 18 ("gastar com consciência...") e 19 ("agora é com você...") viram o fechamento do onboarding da semana 1, não mais o fim de uma cauda de 13 mensagens.

## Tarefas

### 1. Modelo de dados (`singletons/Global.gd`)

- Adicionar `"tutorial_weeks_shown": []` ao `data_model`, a `ensure_player_state()` (preenchendo `[]` se ausente) e a `new_game()`.
- Guarda os números de semana cujo aviso semanal já foi mostrado, para um reload não repetir o aviso.

### 2. Conteúdo (`singletons/TutorialManager.gd`)

- Criar um dicionário `weekly_messages: Dictionary` mapeando `int` (semana) → `Array[String]`, com o conteúdo da tabela acima.
- Mover as mensagens de empreendimentos (atuais índices 12–17) do array `messages` para dentro de `weekly_messages[5]`, mantendo o texto.
- Escrever o conteúdo novo das semanas 2, 3 e 4 (curto, 1–2 mensagens cada), no mesmo tom do resto do tutorial.
- Simplificar o passo 8 de `_next_step()` para enfileirar só o fechamento da semana 1 (mensagens 7–11, 18, 19 renumeradas), sem os blocos que foram remanejados.

### 3. Gatilho semanal

- Nova função pública, ex. `on_week_changed(week: int) -> void`:
  - Se `week` não está em `weekly_messages`, não faz nada.
  - Se `week` já está em `Global.player["tutorial_weeks_shown"]`, não faz nada (evita repetição).
  - Senão, adiciona `week` à lista, persiste (`Global.player["tutorial_weeks_shown"].append(week)`) e chama `queue_messages(weekly_messages[week])`.
- Conectar `TimeManager.week_changed` a essa função — em `TutorialManager._ready()` (o autoload já existe e nunca sai da árvore, então não há problema de ordem) ou em `main_game.gd`, seguindo o padrão já usado para `TutorialManager.focus`.
- Repetir a mesma checagem de sessão contra `pending_messages`: se o jogador está no meio de outra fila (pouco provável, mas o `TutorialManager` já tem esse padrão em `queue_messages`/`_show_next_queued_message`), não sobrepor.

### 4. Persistência

- Confirmar que `SaveManager.save_game()` grava `tutorial_weeks_shown` de graça (ele serializa `Global.player` inteiro — não deveria precisar de mudança).
- Testar manualmente: avançar para a semana 2, ver o aviso, salvar, recarregar, e confirmar que o aviso **não** aparece de novo.

### 5. `skip_tutorial()` e `can_skip()`

- Não alterar o comportamento do botão de pular: ele continua exclusivo do onboarding inicial (`step == 1`).
- Adicionar um comentário em `can_skip()` explicando por que os avisos semanais não têm botão de pular (são curtos por design; pular tornaria o botão permanentemente visível, o que teria efeito colateral em outros alertas do jogo que passam pelo mesmo `AlertManager`).

### 6. Testes manuais

- Novo jogo: só a sequência da semana 1 aparece; nada de empreendimentos.
- Avançar para semana 2: aviso curto de eventos/reserva de emergência aparece uma vez.
- Avançar para semana 3 e 4: avisos correspondentes aparecem uma vez cada.
- Avançar para semana 5: aviso de empreendimentos aparece (conteúdo igual ao atual, só que no momento certo).
- Recarregar o save no meio do jogo (ex. na semana 3) e confirmar que os avisos de semanas já vividas não repetem.
- Confirmar que `skip_tutorial()` na semana 1 ainda pula corretamente e não deixa `tutorial_weeks_shown` num estado inconsistente (semana 1 pulada não deve bloquear os avisos de semanas seguintes).

### 7. Documentação

- Atualizar `PROJECT_KNOWLEDGE.md`, seção 3.3 (Alertas e tutorial): descrever o novo mecanismo de dois estágios — onboarding linear (passos 1–7) + avisos semanais orientados por `week_changed` — e o campo `tutorial_weeks_shown`.

## Fora do escopo (decisão a confirmar antes de implementar, não implementar sem avisar)

- Não adicionar botão de pular aos avisos semanais.
- Não mudar o conteúdo do onboarding da semana 1 além de remover o bloco de empreendimentos que se move para a semana 5.
- Não criar aviso para semanas além da 5 (não há mais níveis de escritório destravando depois disso); se o jogo ganhar semana 6+ no futuro, revisitar.
