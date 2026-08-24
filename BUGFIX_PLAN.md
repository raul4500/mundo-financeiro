# Plano de correções — varredura de 24/08/2026

Origem: varredura completa dos 49 scripts do projeto, com verificação executando
o Godot 4.7.2 em modo headless. Os itens marcados **[verificado]** foram
reproduzidos rodando o jogo, não deduzidos por leitura.

A ordem das fases é intencional: a Fase 0 existe para que as fases seguintes
possam ser diagnosticadas, e a Fase 1 depende de a Fase 0 estar pronta.

---

## Fase 0 — Recuperar a capacidade de diagnóstico

Enquanto estas duas coisas não estiverem resolvidas, qualquer investigação nas
fases seguintes é feita às cegas: o console abre com erros falsos e o arquivo de
log não guarda nada.

### 0.1 — Remover o autoload fantasma `DoorManager` [verificado]

- **Arquivo:** `project.godot` (seção `[autoload]`)
- **Problema:** `DoorManager="*uid://dcjoibsvo3jjk"` aponta para um UID que não
  existe em nenhum arquivo. O motor reclama em toda inicialização:

  ```
  ERROR: Unrecognized UID: "uid://dcjoibsvo3jjk".
  ERROR: Failed to instantiate an autoload, can't load from path: .
  ```

  Nenhum script do projeto referencia `DoorManager` (0 ocorrências).
- **Correção:** apagar a linha.
- **Verificar:** iniciar o jogo e confirmar que o console não abre mais com
  esses dois erros.

### 0.2 — Corrigir o Logger, que apaga o próprio log

- **Arquivo:** `singletons/Logger.gd`, função `_append_line()` (linha ~45)
- **Problema:** o arquivo é aberto com `FileAccess.WRITE`, que **trunca**, e só
  depois chama `seek_end()` — num arquivo já vazio. Cada chamada sobrescreve o
  log inteiro. O `logs/game_runtime.log` versionado tem exatamente 1 linha.
- **Correção:** abrir com `FileAccess.READ_WRITE` e recorrer a `WRITE` apenas
  quando o arquivo ainda não existe:

  ```gdscript
  var file = FileAccess.open(target_path, FileAccess.READ_WRITE)
  if file == null:
      file = FileAccess.open(target_path, FileAccess.WRITE)
  ```

  A mesma troca vale para o fallback de `USER_LOG_PATH` logo abaixo.
- **Atenção:** `_can_write_file()` (linha ~34) também abre com `WRITE` e trunca.
  Ali o truncamento é aceitável — é o começo de sessão —, mas confirme que ele
  roda **uma vez só**, no `_ready()`.
- **Nota de longo prazo:** `res://` é somente leitura em build exportada. O
  fallback para `user://` já existe e cobre isso; só não confie no log dentro do
  repositório depois de exportar.
- **Verificar:** rodar o jogo, executar algumas ações e conferir que
  `logs/game_runtime.log` tem várias linhas em ordem cronológica.

---

## Fase 1 — Destravar o jogo

Três problemas independentes que, juntos, tornam o jogo impossível de terminar.

### 1.1 — `spend_today` nunca é zerado: a semana 1 é invencível [verificado]

Este é o mais grave do projeto. **O save atual já está preso nele**
(`week=1.0`, `spend_today=18020.0`, `school_level=4`).

- **Arquivos:** `singletons/Global.gd`, `singletons/TimeManager.gd`,
  `singletons/MissionManager.gd`
- **Problema:** `spend_today` só é zerado em `Global.new_game()` (linha 154).
  Nunca na virada do dia. Confirmado rodando 24 h de tempo de jogo:

  ```
  antes=18020.0   depois de 24h de jogo=18020.0
  ```

  As missões da semana 1 ficam então contraditórias:

  ```
  [OK ]   Economize R$100
  [FALHA] Não gaste dinheiro por 1 dia    -> exige spend_today == 0
  [OK ]   Registre seus gastos            -> exige ter gasto alguma vez
  ```

  Para registrar um gasto é preciso gastar; ao gastar, `sem_gastar` falha para
  sempre. E `TimeManager` faz `return` quando as missões falham (linha 90), então
  a semana nunca avança.

- **Cuidado com a ordem — armadilha real:** zerar `spend_today` no início do
  bloco de virada de dia **não resolve**, piora. A verificação de missões
  acontece mais adiante *no mesmo bloco*, e passaria a ler sempre `0`, fazendo a
  missão passar de graça. É preciso separar "quanto gastei hoje" de "houve um
  dia sem gastos".

- **Correção em três partes:**

  **(a) Novo campo de estado.** Em `Global.gd`, adicionar `"had_no_spend_day": false`
  em `data_model`, em `ensure_player_state()` e em `new_game()`, junto de
  `spend_today`.

  **(b) Fechar o dia em `TimeManager._add_minute()`,** logo depois de
  `Global.player["day"] = current_day` e **antes** de `decay_need_state()`:

  ```gdscript
  # Fecha o dia que terminou antes de qualquer sistema ler o dia novo.
  # A missão "não gaste por 1 dia" olha a flag, e não spend_today: o
  # contador precisa zerar aqui, mas a conquista do dia precisa sobreviver
  # até a verificação de missões da virada de semana.
  if float(Global.player.get("spend_today", 0.0)) == 0.0:
      Global.player["had_no_spend_day"] = true
  Global.player["spend_today"] = 0.0
  ```

  **(c) Missão passa a ler a flag.** Em `MissionManager._check_mission()`:

  ```gdscript
  "no_spend_day":
      return bool(player.get("had_no_spend_day", false))
  ```

  E, ao avançar de semana com sucesso (Fase 1.3), zerar
  `Global.player["had_no_spend_day"] = false`, para cada semana precisar
  conquistá-la de novo.

- **Migração de save:** não é necessária. `spend_today` se auto-corrige na
  primeira virada de dia, e `had_no_spend_day` entra por `ensure_player_state()`.
- **Verificar:** com o save atual, passar um dia inteiro sem comprar nada e
  confirmar que a semana 1 finalmente vira. A missão `no_impulse` (hoje sem uso)
  também volta a fazer sentido com o reset diário.

### 1.2 — Vazamento de lock no AlertManager congela o jogo [verificado]

- **Arquivo:** `singletons/AlertManager.gd`
- **Problema:** `alert()` chama `Global.lock_gameplay()` (linha 163) toda vez,
  mas `_close_alert()` destrava só uma. Chamar `alert()` com um alerta **já
  aberto** vaza um lock. Reproduzido:

  ```
  lock antes: false
  depois de 2 alerts e 1 fechamento -> gameplay_locked=true  play_time=false
  ```

  Jogo congelado, sem nada na tela explicando. E não é hipotético: acontece em
  **toda virada de semana** (ver 1.3).

- **Correção (a) — obrigatória, pequena e de baixo risco:** travar apenas na
  transição escondido → visível.

  ```gdscript
  func alert(text: String, step: bool = false) -> void:
      var was_visible = panel.visible
      ...
      if not was_visible:
          Global.play_time = false
          Global.lock_gameplay()
  ```

- **Correção (b) — a correta:** dar uma fila ao AlertManager, para a segunda
  mensagem não apagar a primeira antes de ser lida.

  ```gdscript
  var _queue: Array = []   # itens: {"text": String, "step": bool}

  func alert(text: String, step: bool = false) -> void:
      _queue.append({"text": text, "step": step})
      if panel.visible:
          return                    # já há alerta na tela; este espera
      Global.play_time = false
      Global.lock_gameplay()
      _show_front()
  ```

  `_close_alert()` faz `pop_front()`; se a fila ainda tiver itens, mostra o
  próximo **sem** destravar; se esvaziou, esconde e destrava uma única vez.

- **Atenção — reentrância:** `continue_tutorial_after_alert()` pode chamar
  `alert()` de volta (via `queue_messages` → sinal `show_message`). Com a fila
  isso é seguro (vira um append), mas trate `next_step` do item que **acabou de
  fechar**, não do que entrou. Este é o ponto do plano que mais precisa de teste
  manual.
- **Verificar:** disparar dois alertas seguidos e confirmar que ambos são
  legíveis e que, ao fim, `gameplay_locked == false` e `play_time == true`.

### 1.3 — Reordenar a virada de semana

- **Arquivo:** `singletons/TimeManager.gd`, `_add_minute()`, linhas ~70-90
- **Problema duplo:**
  1. `verify_missions()` abre um alerta e, três linhas depois,
     `TutorialManager.on_week_changed()` abre outro por cima. O jogador nunca lê
     a mensagem das missões — e sai com um lock vazado (item 1.2).
  2. `generate_weekly_bills()`, `evaluate_week_status()` e `pay_dividends()`
     rodam **antes** da verificação. Preso na semana 1, o jogador não recebe
     salário, mas recebe dividendos e leva a multa de R$ 25 a cada 7 dias, para
     sempre.
- **Correção:** verificar as missões primeiro; só processar a semana se ela de
  fato terminou.

  ```gdscript
  if week_rollover:
      var week = int(Global.player.get("week", 1))
      if not MissionManager.verify_missions(week):
          # A semana repete: nada de contas, dividendos ou avaliação.
          week_blocked = true
      else:
          HouseBillsManager.generate_weekly_bills()
          EnterpriseManager.generate_all_weekly_bills()
          Global.evaluate_week_status()
          FIIManager.pay_dividends()
          Global.player["week"] = week + 1
          Global.player["had_no_spend_day"] = false
          Global.get_paid()
          emit_signal("week_changed", Global.player["week"])
          TutorialManager.on_week_changed(int(Global.player["week"]))
          EventsManager.maybe_spawn_events(int(Global.player["week"]))
  ```

  Mantenha `generate_weekly_bills()` **antes** do incremento da semana: as contas
  são geradas com `week` atual e `due_week = week + 1`, e mover isso mudaria o
  balanceamento dos prazos.

- **Bônus:** o `return` atual também engole os `emit_signal("day_changed")` e
  `("time_changed")` do fim da função — o relógio da HUD trava naquele minuto.
  Troque o `return` por uma flag (`week_blocked`) e deixe a função terminar
  normalmente.
- **Verificar:** falhar as missões de propósito e confirmar que (a) a mensagem
  de missões é legível, (b) não vêm dividendos nem multa, (c) o relógio continua
  correndo.

---

## Fase 2 — Tutorial e estado de partida

Depende da Fase 1.2: a fila do AlertManager é pré-requisito de 2.1.

### 2.1 — O alerta de missão sequestra a máquina de estados do tutorial

- **Arquivo:** `singletons/MissionManager.gd`, linhas 131 e 141
- **Problema:** `AlertManager.alert(msg, true)` — o `true` é o parâmetro `step`,
  que faz `_close_alert()` chamar `TutorialManager.continue_tutorial_after_alert()`.
  Toda virada de semana avança o passo do tutorial indevidamente.
- **Correção:** trocar por `AlertManager.alert(msg)` nas duas chamadas. O
  parâmetro `step` deve ser exclusivo do TutorialManager.
- **Verificar:** virar uma semana durante o onboarding e confirmar que
  `TutorialManager.step` não pula.

### 2.2 — O tutorial destrava o jogo com 7 mensagens ainda na fila

- **Arquivo:** `singletons/TutorialManager.gd`, passo 8 (linha ~277)
- **Problema:** `Global.force_release_all_gameplay_locks()` roda logo depois de
  `queue_messages([...])`. O jogador volta a andar e o relógio volta a correr
  enquanto ainda lê o fecho do onboarding.
- **Correção:** remover a chamada. Com a Fase 1.2 pronta, o lock passa a ser
  simétrico e não há mais o que forçar. Mesma coisa em `skip_tutorial()`
  (linha ~213) — ali a intenção é legítima, mas o correto é o AlertManager
  esvaziar a fila e destravar sozinho.
- **Meta:** ao fim desta fase, `force_release_all_gameplay_locks()` deve poder
  ser **apagada**. Ela é curativo do bug 1.2; se ainda for necessária, é sinal
  de que sobrou um par lock/unlock desbalanceado.
- **Verificar:** completar o onboarding inteiro e confirmar que o personagem só
  se move depois da última mensagem.

### 2.3 — O tutorial não retoma depois de recarregar

- **Arquivos:** `singletons/TutorialManager.gd`, `scripts/world/main_game.gd`
- **Problema:** `TutorialManager.step` é memória volátil e nunca é restaurado de
  `Global.player["tutorial_step"]`. `main_game.gd` (linha 23) só chama
  `start_tutorial()` quando o passo é 1. Quem salvar no meio do onboarding nunca
  mais vê o resto — e `on_player_entered_school()` (exige `step == 5`) nunca
  dispara.
- **Correção:** restaurar `step` do save ao iniciar a cena, e retomar do ponto
  em vez de só tratar o passo 1:

  ```gdscript
  var saved_step = int(Global.player.get("tutorial_step", 1))
  if saved_step < TutorialManager.FINAL_STEP:
      TutorialManager.resume_tutorial(saved_step)
  ```

  `resume_tutorial()` precisa reposicionar `step` e reemitir a mensagem do passo
  atual (ou pular direto para o passo 5/7 se for um dos passos de espera).
- **Atenção:** `_next_step()` faz `Global.player["tutorial_step"] += 1` em
  paralelo a `step += 1`, e os dois podem divergir hoje. Faça `tutorial_step`
  espelhar `step` (`Global.player["tutorial_step"] = step`) em vez de somar.
- **Verificar:** salvar no passo 3, sair para o menu, voltar, e confirmar que o
  tutorial continua do 3.

### 2.4 — `new_game()` não reseta o FIIManager

- **Arquivos:** `singletons/Global.gd` (`new_game`), `singletons/FIIManager.gd`
- **Problema:** `portfolio`, `total_invested` e `total_dividends_received` são
  estado em memória do autoload. `new_game()` limpa
  `player["investments"]`, mas o FIIManager continua com a carteira do jogo
  anterior até alguém chamar `load_data()`.
- **Correção:** criar `FIIManager.reset()` que zera os três campos e restaura
  `funds` para os valores padrão, e chamá-la em `Global.new_game()`.
- **Relacionado:** ver 3.4 — hoje o save guarda `funds_data`, o que também
  precisa ser resolvido para o reset ser completo.
- **Verificar:** comprar cotas, voltar ao menu, iniciar jogo novo e confirmar
  carteira zerada.

---

## Fase 3 — Bugs pontuais

Independentes entre si; podem ser feitos em qualquer ordem.

### 3.1 — Remover os cheats de debug

- **Arquivo:** `scripts/world/main_game.gd`, `_process()`, linhas 37-42
- **Problema:** `End` dá R$ 10.000; `PageUp`/`PageDown` teleportam para mercado e
  restaurante. Num jogo cujo objetivo é ensinar orçamento, um botão de dinheiro
  infinito não é detalhe.
- **Correção:** apagar. Se forem úteis no desenvolvimento, guardá-los atrás de
  `if OS.is_debug_build():` — assim somem da build exportada.

### 3.2 — `ESC` pode não pausar

- **Arquivo:** `scripts/menus/pause_menu.gd`, linha 15
- **Problema:** `Input.is_action_just_pressed()` dentro de `_input(event)`.
  `_input` roda uma vez **por evento**, e o polling continua verdadeiro o frame
  inteiro. Com o mouse em movimento, dois eventos no mesmo frame chamam
  `toggle_pause()` duas vezes e a ação se anula.
- **Correção:** `if event.is_action_pressed("ui_cancel"):`
- **Verificar:** apertar ESC mexendo o mouse ao mesmo tempo, várias vezes.

### 3.3 — Dinheiro exibido como float cru

- **Arquivos:** `scripts/world/bank/banco.gd:206`, `scripts/hud/hud_control.gd:87`
- **Problema:** `str()` / `%s` produzem `R$ 1234.5600000001`.
- **Correção:** usar `"%.2f"`, como já é feito no resto do projeto
  (`home.gd`, `enterprise_management.gd`).

### 3.4 — Sorteio de eventos enviesado

- **Arquivo:** `singletons/EventsManager.gd`, `sortear_evento()` (linha 73)
- **Problema:** percorre a lista e devolve o primeiro que passar no dado.
  `quebra_carro` é testado sempre primeiro; `tentacao_compra` — o único com
  escolha, e o mais educativo — só é alcançado quando os quatro anteriores
  falham. A chance de algum evento sair por sorteio é ~67%, mas a distribuição
  entre eles é bem desigual.
- **Correção:** sorteio ponderado sobre a soma das probabilidades:

  ```gdscript
  func sortear_evento() -> Dictionary:
      var total = 0.0
      for evento in eventos:
          total += float(evento.get("probabilidade", 0.1))
      if total <= 0.0 or randf() > total:
          return {}                       # nenhuma ocorrência desta vez
      var roll = randf() * total
      var acc = 0.0
      for evento in eventos:
          acc += float(evento.get("probabilidade", 0.1))
          if roll <= acc:
              return evento
      return {}
  ```

- **Atenção:** isto muda a frequência de eventos. Ajuste `SPAWN_INTERVAL` ou as
  probabilidades depois de sentir o novo ritmo em jogo.

---

## Fase 4 — Qualidade e consistência

Nada aqui quebra o jogo. É dívida técnica que fica mais cara com o tempo.

| # | Item | Onde | Ação |
|---|---|---|---|
| 4.1 | 23 guardas `if player == null` são código morto | todo o projeto | `var player: Dictionary` nunca é `null` — inicializa como `{}`. Trocar por `player.is_empty()` onde a intenção era "sem partida", ou remover |
| 4.2 | `cash_balance` do empreendimento é fictício | `EnterpriseManager.process_daily_operation()` | O lucro é somado **e** no dinheiro do jogador **e** no caixa do negócio. Decidir: ou o caixa é separado (e o jogador saca dele), ou o campo some da UI |
| 4.3 | O save guarda `funds_data` | `FIIManager.save_data()/load_data()` | Reescrever preço ou yield de um fundo não afeta saves antigos. Salvar só o preço corrente, não a definição inteira |
| 4.4 | `history_panel` do banco é criado por script | `banco.gd:52` | Posição fixa (710,25) sobrepondo o TabContainer `Investimentos`. Mover para `bank.tscn`, como os painéis de Eventos e Contas da casa |
| 4.5 | `_close_alert()` religa `play_time` sempre | `AlertManager.gd:199` | Dentro de cenas internas onde o tempo devia ficar parado, um alerta o reativa. Guardar o valor anterior e restaurá-lo |
| 4.6 | Portas usam `KEY_ENTER` cru | 6 scripts em `scripts/world/doors/` | Fora do input map: Enter do teclado numérico não funciona e não é remapeável. Criar uma ação `interact` |
| 4.7 | `Global._process()` vazio | `Global.gd:354` | Chamada por frame sem função. Remover |
| 4.8 | `obstacle.gd` tem `game_over` não usado | `obstacle.gd:3` | Resíduo. Remover |
| 4.9 | `timer = 0.0` descarta o resto | `TimeManager.gd:39` | `timer -= 1.0` evita deriva do relógio |
| 4.10 | Autosave roda no menu principal | `SaveManager.gd:78` | O `_process` não checa se há partida em curso |
| 4.11 | `office_door.gd` usa `dentro_banco` | `office_door.gd` | Nome copiado do banco. Cosmético |
| 4.12 | `MissionManager._game_over()` é código morto | `MissionManager.gd` | Nunca chamado, e passa `salary` no lugar de `money`. Remover ou ligar |
| 4.13 | `has_node("/root/X")` misturado com acesso direto | `MissionManager`, `TutorialManager` | Autoload sempre existe. Padronizar no acesso direto |

### 4.14 — O estrutural: disciplina do `gameplay_lock`

Depois dos bloqueadores, é o que eu atacaria primeiro. O contador em `Global` está
correto, mas hoje **sete lugares diferentes** travam e destravam por conta
própria — AlertManager, TransitionManager, CameraManager, `enterprise_door`,
`minigame.gd`, TutorialManager e o próprio `force_release_all_gameplay_locks()`.

Já existe uma função de emergência para consertar o que vaza, o que é o sintoma
clássico de um invariante sem dono. Concentrar a trava em quem abre UI modal
(AlertManager com fila, TransitionManager, diálogo de compra) e proibir os
demais de mexer no contador elimina a classe inteira de bug — incluindo o 1.2.

---

## Fase 5 — Verificação

### 5.1 — Roteiro manual mínimo

- [ ] O console abre limpo, sem erros de autoload
- [ ] `logs/game_runtime.log` acumula linhas
- [ ] Passar um dia sem comprar nada → a semana 1 vira
- [ ] Falhar as missões → mensagem legível, sem dividendos, relógio andando
- [ ] Dois alertas seguidos → ambos legíveis, jogo destravado ao fim
- [ ] Onboarding completo → personagem só se move na última mensagem
- [ ] Salvar no passo 3, recarregar → tutorial continua do 3
- [ ] Jogo novo depois de comprar cotas → carteira zerada
- [ ] ESC mexendo o mouse → pausa de forma confiável
- [ ] Valores em dinheiro com duas casas em todas as telas

### 5.2 — Harness headless (reutilizável)

O Godot está em `C:\Users\x586706\Downloads\projeto\Godot_v4.7.2-stable_win64_console.exe`.
Para checar que **todo** script e cena carregam com os autoloads ativos, criar
`_tmpcheck/check.gd` + `_tmpcheck/check.tscn` com um `Node` que percorre
`res://scripts`, `res://singletons` e `res://scenes` chamando `load()` e
imprimindo o que falhar, e rodar:

```bash
"/c/Users/x586706/Downloads/projeto/Godot_v4.7.2-stable_win64_console.exe" --headless --path . res://_tmpcheck/check.tscn
```

O mesmo harness serve para inspecionar estado real do save sem abrir o jogo —
foi assim que o item 1.1 e o 1.2 foram confirmados. Apagar `_tmpcheck/` depois.

**Não use `--check-only --script <arquivo>`:** esse modo não registra os
autoloads, então todo script que use `Global` reporta um erro falso de
`Identifier not found`.

---

## Ordem sugerida de execução

```
Fase 0  (0.1, 0.2)          -> diagnóstico confiável
   |
Fase 1  (1.1, 1.2, 1.3)     -> jogo terminável        [1.3 depende de 1.2]
   |
Fase 2  (2.1, 2.2, 2.3, 2.4) -> tutorial e estado     [2.1 e 2.2 dependem de 1.2]
   |
Fase 3  (3.1 .. 3.4)         -> independentes entre si
   |
Fase 4  (4.1 .. 4.14)        -> dívida técnica; 4.14 é o de maior retorno
   |
Fase 5                       -> verificação
```

Fases 0 a 2 são o mínimo para o jogo ser jogável do início ao fim.
