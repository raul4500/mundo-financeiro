# Plano de Implementação 02: Bug de Movimento ao "Continuar Jogo"

## 1. Identificação e Contexto
- **Objetivo**: Corrigir o defeito onde o personagem fica completamente imóvel (não responde aos comandos WASD ou setas) após o jogador clicar no botão "Continuar" no Menu Principal.
- **Arquivos Afetados**:
  - `scripts/menus/main_menu.gd`
  - `scripts/menus/pause_menu.gd`
  - `singletons/Global.gd`
  - `scripts/player/player.gd`
  - `scripts/world/main_game.gd`
  - `tests/test_continue_game_movement.gd` (novo teste automatizado)

## 2. Diagnóstico da Causa Raiz
Foram identificadas 4 falhas simultâneas que causam ou contribuem para o travamento de movimentação ao continuar um jogo salvo:

1. **Vazamento de Trava no Menu de Pause (`pause_menu.gd`)**:
   - Ao abrir o menu de pause com ESC, executa-se `Global.lock_gameplay()` (`_gameplay_lock_count` incrementa em +1).
   - Ao clicar no botão "Sair" (`_on_sair_pressed`), o script salva o jogo e chama `TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")` **sem** chamar `toggle_pause()` ou `Global.unlock_gameplay()`.
   - O contador de bloqueio de gameplay vai para o menu principal com valor `> 0`.
2. **Falta de Reset Robusto de Travas no Início do Jogo Carregado (`main_menu.gd`)**:
   - Em `main_menu.gd`, a função `start()` apenas executa:
     ```gdscript
     Global.unlock_gameplay()
     TransitionManager.change_scene("res://scenes/world/main_game.tscn")
     ```
   - Chamar `unlock_gameplay()` uma única vez apenas subtrai 1 de `_gameplay_lock_count`. Se o contador estivesse em 2 ou mais (devido a pause menu + transição anterior), `Global.gameplay_locked` permanece `true` ao chegar no mapa principal.
   - Em `player.gd`, a linha 33 impede qualquer movimento se `Global.gameplay_locked == true`.
3. **Ausência de Chamada Explícita a `Global.load_data()` no Botão Continuar**:
   - O menu principal parte do princípio de que `Global.player` já contém os dados carregados na inicialização do jogo (`Global._ready()`). Porém, se o jogador jogou uma partida, sofreu alterações de estado, voltou ao menu e clicou em "Continuar", o save do disco não é recarregado de forma limpa.
4. **Vulnerabilidade de Velocidade Zerada (`player["speed"]`)**:
   - No `Global.gd`, quando a stamina zera, `lose_speed()` reduz `player["speed"]` progressivamente até 0.0.
   - Se o jogo for salvo nessa condição, `Global.ensure_player_state()` não possui validação de piso para `"speed"`, fazendo com que `velocity = direction * speed` resulte em vetor nulo `(0, 0)`, mesmo com `gameplay_locked = false`.

## 3. Regras de Negócio e Solução Técnica
1. **Garantia de Liberação de Travas no Carregamento**:
   - Ao clicar em "Continuar", todas as travas residuais de gameplay devem ser forçadas a zero através de `Global.force_release_all_gameplay_locks()`.
   - Em `main_game.gd._ready()`, se o tutorial já estiver concluído (`tutorial_step > TutorialManager.FINAL_STEP`), deve ser garantido que `Global.force_release_all_gameplay_locks()` seja executado após a montagem do personagem.
2. **Correção do Fluxo de Saída no Menu de Pause**:
   - Em `pause_menu.gd`, a função `_on_sair_pressed()` deve desligar `paused = false` e liberar o lock do pause antes de salvar e trocar de cena, ou invocar a limpeza global de transição para o menu.
3. **Recarga Fidedigna dos Dados Salvos**:
   - Em `main_menu.gd:start()`, invocar explicitamente `Global.load_data()` antes de trocar de cena, assegurando que o estado em memória corresponda com exatidão ao arquivo em disco.
4. **Sanitização de Velocidade do Jogador**:
   - Em `Global.ensure_player_state()`, incluir `"speed"` na lista de atributos verificados e garantir que `player["speed"]` tenha como piso o valor padrão de 70.0 (ou restauração de velocidade caso não esteja no estado de colapso).

## 4. Passo a Passo da Implementação
1. **Ajuste em `scripts/menus/pause_menu.gd`**:
   - No método `_on_sair_pressed()`:
     ```gdscript
     func _on_sair_pressed() -> void:
         visible = false
         if paused:
             Global.unlock_gameplay()
             paused = false
         Global.play_time = false
         SaveManager.save_game()
         TransitionManager.change_scene("res://scenes/menus/main_menu.tscn")
     ```
2. **Ajuste em `scripts/menus/main_menu.gd`**:
   - No método `start()`:
     ```gdscript
     func start() -> void:
         if not SaveManager.has_save() or Global.player.get("name", "") == "":
             return
         Global.load_data()
         Global.force_release_all_gameplay_locks()
         Global.reestore_speed() # Restaura velocidade base de 70.0 caso estivesse zerada
         TransitionManager.change_scene("res://scenes/world/main_game.tscn")
     ```
3. **Ajuste em `singletons/Global.gd`**:
   - Em `ensure_player_state()`:
     - Adicionar `"speed"` com valor padrão de `70.0`.
     - Garantir que se `float(player.get("speed", 0.0)) <= 0.0`, o valor seja restaurado para `70.0` se não estiver em game over.
4. **Ajuste defensivo em `scripts/world/main_game.gd`**:
   - No final de `_ready()`, caso o tutorial esteja concluído ou o passo atual não demande cutscene ativa de câmera, chamar `Global.force_release_all_gameplay_locks()`.

## 5. Resultados Esperados
- O jogador consegue andar normalmente com WASD / Setas imediatamente após clicar em "Continuar".
- Salvar o jogo dentro de qualquer prédio, pelo menu de pause ou no mapa aberto restaura o personagem responsivo.
- O contador `Global._gameplay_lock_count` é rigorosamente `0` e `Global.gameplay_locked` é `false` ao entrar no mundo.

## 6. Plano de Testes
### Testes Automatizados (`tests/test_continue_game_movement.gd`)
- Criar um save artificial com:
  - Tutorial concluído (`tutorial_step = 11`, `unlock_stage = 2`).
  - Simular saída com pause ativo (`_gameplay_lock_count = 2`).
  - Executar a rotina de carregamento do `main_menu.start()`.
  - Instanciar `main_game.tscn`.
  - Simular entrada de movimento (`Input.action_press("move_right")`).
  - Validar que `Global.gameplay_locked == false`, `_gameplay_lock_count == 0` e `player.velocity.x > 0`.

### Teste Manual
1. Iniciar jogo, andar pelo mapa.
2. Abrir Menu de Pause com ESC e clicar em "Sair".
3. No Menu Principal, clicar no botão "Continuar".
4. Pressionar W, A, S, D: constatar movimentação imediata e fluida do personagem.
