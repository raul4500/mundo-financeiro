# Plano de correção — mundo-financeiro

Executar as etapas em ordem. Cada etapa é independente e testável isoladamente.
Ao concluir cada etapa, rodar o jogo (ou abrir a cena no editor) e confirmar antes de seguir.
`doors.gd` já foi excluído — não recriar, não referenciar.

## 1. missions_ui.gd — crash após semana 5 → estado "concluído"

Arquivo: `scripts/hud/missions_ui.gd`
Problema: linha 17 faz `MissionManager.missions_data[phase]` direto; `missions_data` só tem chaves 1–5; semana 6+ retorna `null` e quebra o `for`.

Correção:
- Trocar `MissionManager.missions_data[phase]` por `MissionManager.get_missions(phase)` (helper já existe em `singletons/MissionManager.gd:116-117`, usa `.get(week, [])`).
- Em `load_missions(phase)`: se `missions` vier vazio (`[]`) E `phase > 5` (ou seja, passou da última semana com missões definidas), limpar a lista e mostrar um único `Label` com texto "Todas as missões foram concluídas!" em vez do loop normal. Se `missions` vier vazio mas `phase <= 5`, manter comportamento atual (lista vazia, sem crash — já não quebraria mais com `get_missions`).
- Confirmar que `mission_button`/`panel` continuam funcionando normalmente nesse estado (não esconder o botão, só trocar o conteúdo da lista).

## 2. player.gd / raul_minigame.gd — crash em inicializador de campo

Arquivos: `scripts/player/player.gd:13-15`, `scripts/player/raul_minigame.gd:12-14`
Problema: `load(characters[char_name]).instantiate()` roda como inicializador de campo (antes de `_ready()`); se `char_name` não existir em `characters`, quebra antes da validação em `_ready()` rodar.

Correção (aplicar nos dois arquivos, mesmo padrão):
- Mover a leitura de `char_name`, `load()` e `.instantiate()` para dentro de `_ready()`, depois da checagem `if not characters.has(char_name)`.
- Se `char_name` inválido: usar um fallback padrão (primeiro personagem de `characters`, ou uma chave `"default"` se existir) em vez de `get_tree().quit()` — só usar `quit()`/`push_error` se nem o fallback existir. (Confirmar com o usuário se preferem fallback ou apenas evitar o crash mantendo o quit — se não houver decisão, usar fallback por ser menos destrutivo para o jogador.)
- Declarar as variáveis (`scene`, `animated_player`) como `var` sem inicializador no topo, atribuir dentro de `_ready()`.

## 3. EventsManager.gd — unificar com UnexpectedEvents.gd

Arquivos: `singletons/EventsManager.gd`, `singletons/UnexpectedEvents.gd`
Problema: `EventsManager.gd:7` mantém lista hardcoded própria (linha 5 tem a versão "correta" comentada); diverge de `UnexpectedEvents.gd`, que fica morto. Evento `tentacao_compra` perde o campo `escolhas` na cópia local, então o branch de escolha (`if evento.has("escolhas"): return evento`) nunca é alcançado.

Correção:
- Comparar as duas listas de eventos campo a campo; `UnexpectedEvents.gd` é a fonte que tem `escolhas` — usar ela como base.
- Remover a lista hardcoded de `EventsManager.gd:7-...` e descomentar/usar `var eventos: Array = UnexpectedEvents.unexpected_events["eventos"]`.
- Verificar em `project.godot` que `UnexpectedEvents` carrega antes de `EventsManager` no autoload (hoje `EventsManager` é o PRIMEIRO da lista, linha 20, antes de `UnexpectedEvents`, linha 23 — precisa inverter a ordem para o autoload referenciar dados já prontos).
- Testar o evento `tentacao_compra`: precisa abrir UI de escolha (Comprar/Não comprar) e não aplicar impacto fixo automaticamente.

## 4. Eventos financeiros silenciosos fora do mapa principal

Arquivo: `scripts/player/player.gd` (instancia `event_ui.tscn`), `singletons/EventsManager.gd`
Problema: `EventsManager` roda sempre (autoload), mas `event_ui.tscn` só existe como filho do player no mapa principal — eventos alteram `Global.player["money"]` mesmo dentro de banco/mercado/escritório/minigame sem UI.

Correção (escolher uma abordagem):
- Opção A (recomendada): mover a instância de `event_ui.tscn` para um autoload próprio (ou para o `hud_control.gd`, se ele já é global/persistente) em vez de depender do player do mapa principal existir.
- Opção B: pausar o timer/gatilho de eventos do `EventsManager` quando o jogador não está no mapa principal (ex.: expor `EventsManager.set_active(bool)` e chamar nas transições de cena).
- Testar entrando no banco/mercado/escritório e confirmando que eventos ou não disparam, ou disparam com UI visível.

## 5. FIIManager.gd — pay_dividends() nunca chamado

Arquivo: `singletons/FIIManager.gd:99` (`pay_dividends()`), `singletons/TimeManager.gd` (fluxo de avanço de semana/dia)
Problema: função existe mas nenhuma chamada no projeto — dividendos nunca são pagos.

Correção:
- Decidir a cadência (semanal é a mais coerente com o resto do jogo). Chamar `FIIManager.pay_dividends()` dentro do bloco de `TimeManager` que já roda ao fechar semana (mesmo ponto onde `Global.evaluate_week_status()` é chamado, ver PROJECT_KNOWLEDGE.md seção 5).
- Confirmar que `pay_dividends()` soma corretamente em `Global.player["money"]` (checar a fórmula `price * dividend_yield * quantity`, não deve "dobrar" nada).
- Testar: comprar cota de um fundo, avançar uma semana, confirmar que o dinheiro aumenta pelo valor esperado.

## 6. Missão "profit" desconectada de FIIs

Arquivo: `singletons/MissionManager.gd:150-151`
Problema: checa `player["saldo"]` (só muda por depósito/saque manual no banco), não tem relação com lucro de investimentos — mission "Ganhe R$200 com investimentos" pode passar sem nunca comprar FII.

Correção:
- Definir uma métrica real de lucro de investimento: usar `FIIManager.get_portfolio_value()` menos o total investido (precisa rastrear total aportado, se ainda não existir um campo assim em `Global.player["investments"]` — adicionar se faltar) ou somar dividendos pagos (depende da etapa 5 já estar feita).
- Atualizar a condição da missão `"profit"` para usar essa métrica em vez de `saldo`.
- Testar: comprar FII, aguardar dividendo/valorização, confirmar que a missão só passa com ganho real de investimento.

## 7. bank_door.gd sem guarda de gameplay_locked

Arquivo: `scripts/world/doors/bank_door.gd:6-8`
Problema: única porta sem `if Global.gameplay_locked: return` no início do `_process` (comparar com `scripts/world/doors/home_door.gd:5-7`, que já tem o padrão certo).

Correção: adicionar as mesmas duas linhas no início do `_process` de `bank_door.gd`, igual ao padrão de `home_door.gd`/`office_door.gd`/`minigame_door.gd`/`shop_door.gd`.

## 8. Ordem de autoload — Logger por último

Arquivo: `project.godot:19-31`
Problema: `Logger` é o último autoload; `TimeManager._ready()` tenta logar antes de `Logger` existir na árvore, cai só no `print()`.

Correção: mover `Logger="*res://singletons/Logger.gd"` para ser o PRIMEIRO da lista de autoloads (antes de `EventsManager`), já que é uma dependência transversal usada por vários outros singletons em `_ready()`. Testar que `logs/game_runtime.log` recebe a mensagem "TimeManager inicializado" (ou equivalente) após o ajuste.

Nota: ao mexer na ordem de autoload, também aplicar a inversão da etapa 3 (`UnexpectedEvents` antes de `EventsManager`) na mesma edição do `project.godot`, para não editar o arquivo duas vezes.

## 9. gameplay_locked sem coordenação entre CameraManager e AlertManager

Arquivos: `singletons/CameraManager.gd` (`focus()` ~linha 29,48), `singletons/AlertManager.gd` (`alert()`/`_close_alert()` ~linhas 83-84,110-111)
Problema: os dois escrevem no mesmo booleano sem pilha/contador — sobreposição pode destravar cedo demais ou travar indevidamente.

Correção:
- Substituir o booleano simples por um contador (`Global.gameplay_lock_count: int`) ou expor `Global.lock_gameplay()` / `Global.unlock_gameplay()` que incrementam/decrementam esse contador; `Global.gameplay_locked` vira um getter (`gameplay_lock_count > 0`).
- Atualizar `CameraManager.focus()`/fim da cutscene e `AlertManager.alert()`/`_close_alert()` para chamar lock/unlock em vez de atribuir `true`/`false` diretamente.
- Testar cenário de sobreposição: abrir alerta durante uma cutscene de câmera e confirmar que o gameplay só destrava quando AMBOS terminarem.

## 10. market.gd — carrinho cosmético, sem cancelamento

Arquivo: `scripts/world/market/market.gd` (`_on_buy_item` ~linhas 189-217)
Problema: dinheiro debitado e item adicionado ao inventário já no clique de "Adicionar" (não no "Finalizar compra"); botão "X" (`remove_product`) é criado mas nunca conectado; `_on_clean_kart_pressed`/`_on_finish_pressed` só limpam a lista visual sem devolver dinheiro.

Correção (decisão de design — confirmar com usuário se o fluxo desejado é "compra imediata sem carrinho" ou "carrinho real"):
- Se manter fluxo atual (compra imediata ao "Adicionar"): remover o botão "X"/carrinho da UI para não sugerir uma funcionalidade que não existe, OU
- Se implementar carrinho real: mover a lógica de debitar dinheiro e adicionar ao inventário de `_on_buy_item` para `_on_finish_pressed`; conectar `remove_product.pressed` para remover o item da lista antes de finalizar.
- Este item precisa de uma decisão de produto antes de implementar — sinalizar ao usuário no início da etapa.

## 11. pause_menu.gd — mouse capturado ao despausar

Arquivo: `scripts/menus/pause_menu.gd` (`toggle_pause()` ~linhas 6-15)
Problema: define `Input.set_mouse_mode(MOUSE_MODE_CAPTURED)` ao retomar; resto do jogo usa `MOUSE_MODE_VISIBLE` (`home.gd`, `banco.gd`, `market.gd`); linha equivalente em `main_game.gd` está comentada.

Correção: trocar `MOUSE_MODE_CAPTURED` por `MOUSE_MODE_VISIBLE` em `toggle_pause()` ao despausar. Testar pausar/despausar dentro do mapa principal e confirmar que o cursor continua visível.

## 12. minigame.gd — só trata school_level 1 e 2

Arquivos: `scripts/minigame/minigame.gd:16-22`, `scripts/minigame/level.gd:4`
Problema: `level.gd` incrementa `school_level` sem limite; `minigame.gd` só tem branch para nível 1 e 2 — nível 3+ fica sem posicionamento de player/câmera.

Correção:
- Ou adicionar um `else`/branch genérico em `minigame.gd` que reutiliza os marcadores do último nível definido (2) para qualquer `curr_level >= 2`, ou
- Definir um limite máximo de `school_level` em `level.gd` (travar em 2, ou no valor mais alto que tiver conteúdo real) se não houver conteúdo pensado para níveis além do 2.
- Confirmar com o usuário qual dos dois é o comportamento pretendido antes de implementar (impacta progressão de salário via `update_salary()`).

## 13. Inconsistências de documentação (PROJECT_KNOWLEDGE.md)

Sem impacto em código — atualizar o `.md` depois que as etapas acima estiverem resolvidas:
- Seção 7: corrigir texto sobre `pay_dividends()` ("dobra no dinheiro" → descrição real da fórmula).
- Seção 2/10: `office.gd` não é "trabalho/rotina", é navegador de conteúdo educacional; progressão de `school_level`/salário vem do minigame (`level.gd`), não do escritório — ajustar texto.
- Remover menção a `UnexpectedEvents` como sistema separado se a etapa 3 unificar tudo em `EventsManager`.

---

## Itens que precisam de decisão do usuário antes de codar
- Etapa 2: fallback de personagem inválido (usar personagem padrão vs. manter quit/erro).
- Etapa 10: carrinho de compras — implementar de verdade ou remover a UI de cancelamento.
- Etapa 12: limite de `school_level` — travar em 2 ou expandir conteúdo do minigame.

Para as demais etapas (1, 3-9, 11), a correção é direta e pode ser aplicada sem perguntas adicionais.

## Decisão sobre os itens pendentes
- Etapa 2: preciso que vc reconstrua a lógica do personagem do minigame, fazendo com que o mesmo personagem selecionado no "choose_character" seja renderizado no minigame. A lógica é a mesma para o Player.gd que só muda o node de AnimatedSprite2D, mas no mingame, ele deve rodar a animação de walk 100% do tempo.
- Etapa 10: Pode implementar de verdade a opção de remover item do carrinho.
- Etapa 11: Eu vou construir o restante do minigame depois, colocando mais obstáculos e adicionando pontos de checkpoint e spawnpoint