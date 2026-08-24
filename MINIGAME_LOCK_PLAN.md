# Plano: Bloqueio/cooldown do minigame + tela de início

## Objetivo

1. Depois de qualquer sessão do minigame que termine com o jogador **subindo de nível** (checkpoint), a porta da escola fica trancada até o **início da semana seguinte**.
2. Depois de qualquer sessão que termine em **derrota** (bateu no obstáculo) sem subir de nível, a porta fica trancada por um **cooldown de 2 dias** (dias de jogo, não semanas).
3. Cada sessão só permite subir **no máximo 1 nível**: assim que o jogador atinge o próximo checkpoint, a sessão termina automaticamente (mesmo comportamento de "acabou o jogo" que já existe para a derrota).
4. A porta do minigame reflete esse estado: enquanto trancada, `Enter` não entra.
5. Ao entrar no minigame, aparece uma caixa com um botão "Começar" e uma contagem regressiva de 3 segundos — exibida **depois** de qualquer mensagem de tutorial pendente daquela visita.
6. O tutorial passa a explicar essas regras, de forma resumida, na mesma sequência que já apresenta o minigame.

## Estado atual (mapeado no código)

- `scripts/minigame/level.gd` — `Area2D` de checkpoint: ao ser tocada, só faz `Global.player["school_level"] += 1` e `Global.update_salary()`. Não termina a sessão nem impede subir vários níveis na mesma corrida.
- `scripts/minigame/obstacle.gd` — ao colidir, troca para `main_game.tscn` e chama `TutorialManager.on_minigame_finished()`. É o único ponto que hoje encerra uma sessão.
- `scripts/world/doors/minigame_door.gd` — deixa entrar sempre que `Enter` é pressionado e o jogador está dentro da área, sem nenhuma verificação de bloqueio. Tem `Info-panel` (adicionado numa tarefa anterior) mas com hint estático, ao contrário de `enterprise_door.gd`, que já tem o padrão de hint dinâmico (`_update_info_hint()`).
- `scripts/minigame/minigame.gd._ready()` posiciona o jogador conforme `Global.player["school_level"]` e já expõe `notify_tutorial_minigame_finished()`; não há nenhuma tela de início.
- `Global.player["day"]` é o dia **dentro da semana** (1–7, reseta a cada virada de semana) e `Global.player["week"]` é a semana. Não existe hoje um contador de dia absoluto — precisa ser derivado.
- `TimeManager._add_minute()` só atualiza `Global.player["day"]`/emite `day_changed` **depois** do bloco de virada de semana; se `MissionManager.verify_missions()` reprovar a semana, a função retorna antes disso e o dia fica congelado até as missões serem cumpridas (bug conhecido, já registrado nos gotchas). O cooldown de dias herda esse comportamento — é consistente com o resto do jogo, não é para corrigir aqui.
- `TutorialManager` já tem, no roteiro da semana 1, o bloco de explicação do minigame (mensagens que hoje são os índices 4–6 do array `messages`, disparadas no passo 6 antes do jogador jogar pela primeira vez).

## Interpretação assumida (confirme antes de implementar)

O pedido descreve duas regras que, olhando com cuidado, são a **mesma regra geral** aplicada duas vezes — não um caso especial para a primeira jogada:

> **Regra única:** toda vez que uma sessão do minigame termina, ela termina de um destes dois jeitos — subiu de nível (no máximo 1 por sessão) ou não subiu (derrota). No primeiro caso, a porta tranca até a próxima semana. No segundo, tranca por 2 dias.

A frase "depois que jogar pela primeira vez, só vai poder jogar de novo na segunda semana" é simplesmente o resultado esperado dessa regra geral aplicada à primeira sessão (que é guiada pelo tutorial e projetada para ser vencível, terminando em subida de nível). Não crio um caminho de código separado para "a primeira vez" — é a mesma função para toda sessão, do início ao fim do jogo. Se a intenção era ter uma regra **diferente e adicional** só para a primeira sessão, isso muda o desenho — avise antes de eu implementar.

## Modelo de dados

Novo campo em `Global.player`, seguindo o padrão de `enterprises`/`pending_events` (dicionário próprio, não soltar variáveis no nível raiz):

```gdscript
"minigame_progress": {
	"unlock_week": 1,     # semana a partir da qual pode jogar (satisfeita por padrão no início do jogo)
	"unlock_day": 0       # dia absoluto a partir do qual pode jogar (satisfeita por padrão)
}
```

Adicionar em `data_model`, `ensure_player_state()` e `new_game()` — mesmo tratamento dado a `pending_events`.

Novo helper em `Global.gd`, porque `day`/`week` já vivem lá:

```gdscript
# Dia absoluto desde o início do jogo, usado para cooldowns que não devem
# resetar sozinhos na virada de semana (ao contrário de Global.player["day"]).
func get_absolute_day() -> int:
	return (int(player.get("week", 1)) - 1) * 7 + int(player.get("day", 1))
```

## Novo singleton: `MinigameManager.gd`

Centraliza a regra, para `level.gd`, `obstacle.gd` e `minigame_door.gd` não duplicarem lógica. Registrar em `project.godot` depois de `Global` (precisa de `Global.player` e do helper acima).

API proposta:

```gdscript
extends Node

const LEVEL_LOCK_WEEKS := 1   # tranca até current_week + 1
const FAIL_COOLDOWN_DAYS := 2 # tranca até absolute_day + 2

func can_play() -> bool:
	var mp = Global.player.get("minigame_progress", {})
	var week_ok = int(Global.player.get("week", 1)) >= int(mp.get("unlock_week", 1))
	var day_ok = Global.get_absolute_day() >= int(mp.get("unlock_day", 0))
	return week_ok and day_ok

# Chamado por level.gd quando o jogador sobe de nível.
func on_session_leveled_up() -> void:
	var mp = Global.player["minigame_progress"]
	mp["unlock_week"] = int(Global.player.get("week", 1)) + LEVEL_LOCK_WEEKS
	mp["unlock_day"] = 0  # a semana já é a trava ativa; o dia não deve bloquear além disso

# Chamado por obstacle.gd quando o jogador perde sem subir de nível nesta sessão.
func on_session_failed() -> void:
	var mp = Global.player["minigame_progress"]
	mp["unlock_day"] = Global.get_absolute_day() + FAIL_COOLDOWN_DAYS
	mp["unlock_week"] = int(Global.player.get("week", 1))  # a semana atual já é suficiente

# Texto para o Info-panel da porta e para uma mensagem de bloqueio, se necessário.
func lock_reason() -> String:
	if can_play():
		return ""
	var mp = Global.player.get("minigame_progress", {})
	var week_ok = int(Global.player.get("week", 1)) >= int(mp.get("unlock_week", 1))
	if not week_ok:
		return "Disponível na semana %d" % int(mp.get("unlock_week", 1))
	var days_left = int(mp.get("unlock_day", 0)) - Global.get_absolute_day()
	return "Disponível em %d dia(s)" % max(days_left, 1)
```

Sempre zerar o outro campo ao setar um: assim `can_play()` nunca fica preso por um valor antigo da trava que não está mais em uso.

## Tarefas

### 1. `Global.gd`

- Adicionar `minigame_progress` ao `data_model`, `ensure_player_state()` (preenchendo o dicionário default se ausente) e `new_game()`.
- Adicionar `get_absolute_day()`.

### 2. Criar `singletons/MinigameManager.gd`

- Implementar a API acima.
- Registrar em `project.godot`, depois de `Global`.

### 3. `scripts/minigame/level.gd`

- Ao entrar na área do checkpoint: incrementar `school_level`, chamar `Global.update_salary()` (como já faz), depois `MinigameManager.on_session_leveled_up()`, `TutorialManager.on_minigame_finished()` (hoje só `obstacle.gd` chama isso — precisa chamar aqui também, senão o passo do tutorial que espera o fim da primeira sessão nunca avança quando ela termina em vitória) e `get_tree().change_scene_to_file("res://scenes/world/main_game.tscn")`.
- Isso já garante "no máximo 1 nível por sessão": a cena troca assim que o primeiro checkpoint da corrida é tocado.

### 4. `scripts/minigame/obstacle.gd`

- Antes de trocar de cena, chamar `MinigameManager.on_session_failed()`.
- Mantém a chamada existente a `TutorialManager.on_minigame_finished()`.

### 5. `scripts/world/doors/minigame_door.gd`

- Só trocar de cena (e só chamar `TutorialManager.on_player_entered_school()`) se `MinigameManager.can_play()` for verdadeiro.
- Seguir o padrão de `enterprise_door.gd`: dar ao `Info-panel` um hint dinâmico (`_update_info_hint()` equivalente), mostrando `MinigameManager.lock_reason()` quando trancado e "Pressione ENTER para jogar" quando liberado.
- Opcional, mas recomendado: se o jogador apertar `Enter` estando trancado, mostrar `AlertManager.alert(MinigameManager.lock_reason())` uma vez, para não ficar um "nada acontece" silencioso.

### 6. Tela de início (`scripts/minigame/minigame.gd` + `scenes/minigame/minigame.tscn`)

- Adicionar um painel (`CanvasLayer` + `Panel` com `font_theme.tres`, seguindo a convenção da seção 3.8 do `PROJECT_KNOWLEDGE.md`) com um `Label` de contagem e um `Button` "Começar".
- Em `_ready()`, chamar `Global.lock_gameplay()` (o contador já existe e coexiste com o lock do tutorial) e mostrar o painel.
- A contagem só começa a rodar quando não há tutorial pendente nesta visita: checar a cada frame (ou a cada 0.2s) `AlertManager.panel.visible == false and TutorialManager.pending_messages.is_empty()`. Enquanto isso for falso, a contagem fica pausada em "3".
- Ao chegar a 0, ou ao clicar em "Começar" a qualquer momento: esconder o painel e chamar `Global.unlock_gameplay()`. Isso libera `_process()` do próprio `minigame.gd` e `_physics_process()` de `raul_minigame.gd`, que já checam `Global.gameplay_locked`.

### 7. Conteúdo do tutorial

- Adicionar uma mensagem curta ao bloco de explicação do minigame já existente (mensagens 4–6 do array `messages`), resumindo: "você só pode subir 1 nível por tentativa; se perder antes do próximo checkpoint, espera 2 dias; se conseguir, só joga de novo na semana seguinte."
- Se o `WEEKLY_TUTORIAL_PLAN.md` for implementado antes, os índices desse array vão mudar — aplicar esta mensagem depois de resolver qual plano entra primeiro, para não referenciar um índice que já foi deslocado.

### 8. Testes manuais

- Jogo novo, primeira visita à escola: porta aberta, joga, sobe 1 nível → sessão termina sozinha, sem precisar bater em obstáculo.
- Tentar entrar na porta logo em seguida, ainda na semana 1: deve estar trancada, hint mostra a semana correta.
- Avançar para a semana 2: porta libera.
- Jogar de novo, bater no obstáculo sem chegar ao próximo checkpoint: porta tranca por 2 dias; hint mostra a contagem de dias.
- Esperar os 2 dias (avançar o relógio) e conferir que libera de novo, ainda dentro da mesma semana se aplicável.
- Repetir o cenário do pedido original: nível 3 → sobe para nível 4 → tranca até a semana seguinte.
- Entrar no minigame com mensagens de tutorial pendentes: confirmar que a contagem de 3s só começa depois da última mensagem fechada.
- Entrar no minigame sem tutorial pendente (uma visita qualquer depois da primeira): a contagem começa imediatamente.
- Salvar e recarregar com um cooldown ativo (de dia ou de semana): confirmar que `minigame_progress` persiste e a trava continua valendo.

### 9. Documentação

- Atualizar `PROJECT_KNOWLEDGE.md`: descrever `MinigameManager`, o campo `minigame_progress`, a regra unificada de bloqueio, e o novo helper `Global.get_absolute_day()`.

## Fora do escopo / riscos conhecidos

- Não mexe no bug já registrado de `TimeManager` congelar o dia quando as missões da semana não são cumpridas — o cooldown herda esse comportamento por construção (se o tempo não anda, nada deveria destravar mesmo).
- `Global.play_time` continua avançando durante a tela de início (é um booleano solto, sem contador, problema já documentado em 3.2) — não deve causar bug prático aqui, só um detalhe a saber.
- Não adiciono spawnpoints/checkpoints novos nem obstáculos — isso é trabalho futuro do próprio usuário, como já registrado no projeto.
