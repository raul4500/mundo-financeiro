# Plano de Implementação 01: Confirmação de Alertas com Tecla Enter

## 1. Identificação e Contexto
- **Objetivo**: Permitir que o jogador confirme e feche alertas modais (botão "OK" ou "Continuar") pressionando a tecla `Enter` do teclado (tanto o Enter principal quanto o Enter do teclado numérico), mantendo a compatibilidade existente com a barra de `Espaço` e o clique do mouse.
- **Arquivos Afetados**:
  - `singletons/AlertManager.gd`
  - `tests/test_alert_queue.gd` / `tests/test_alert_queue.tscn` (ou novo teste dedicado)

## 2. Diagnóstico do Estado Atual
No arquivo `singletons/AlertManager.gd`, o método `_input(event)` filtra estritamente:
```gdscript
if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
```
- Apenas `KEY_SPACE` é aceito para avançar o diálogo.
- A tecla `Enter` (`KEY_ENTER` e `KEY_KP_ENTER`), amplamente utilizada em jogos de PC e interfaces Desktop para confirmação rápida, é sumariamente ignorada.
- Adicionalmente, quando o jogador está em frente a uma porta (que usa `KEY_ENTER` para interagir), abrir um alerta e pressionar Enter não fecha a mensagem, causando estranheza na jogabilidade.

## 3. Regras de Negócio e Comportamento Esperado
1. **Teclas de Confirmação Suportadas**: O fechamento de alertas simples (sem escolhas) deve ser acionado por:
   - Clique com botão esquerdo do mouse no botão "OK" / "Continuar".
   - Tecla `Espaço` (`KEY_SPACE`).
   - Tecla `Enter` padrão (`KEY_ENTER`).
   - Tecla `Enter` do teclado numérico (`KEY_KP_ENTER`).
   - Ação `ui_accept` caso mapeada, evitando duplicidade se for uma tecla física repetida.
2. **Consumo de Input (`set_input_as_handled`)**:
   - Sempre que o Enter ou Espaço for pressionado com o alerta visível, a entrada deve ser consumida imediatamente via `get_viewport().set_input_as_handled()`.
   - Isso impede que o Enter "vaze" para o cenário (por exemplo, ativando portas de prédios ou ações de interação sob o diálogo).
3. **Respeito aos Alertas de Escolha (`choice_box`)**:
   - Se o alerta contiver opções de múltipla escolha (`choice_box.visible == true`), nem o Espaço nem o Enter devem fechar o alerta automaticamente, obrigando o jogador a selecionar conscientemente uma opção via mouse ou navegação.
4. **Período de Graça (`_space_grace_msec`)**:
   - O tempo de carência para evitar pulos acidentais (usado ao sair de minigames ou telas movimentadas) deve se aplicar identicamente ao Enter.

## 4. Passo a Passo da Implementação
1. **Atualização em `singletons/AlertManager.gd`**:
   - Modificar a checagem no método `_input(event)`:
     ```gdscript
     var is_confirm_key := false
     if event is InputEventKey and event.pressed and not event.echo:
         if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
             is_confirm_key = true
     ```
   - Garantir o consumo do input: `get_viewport().set_input_as_handled()`.
   - Verificar se `choice_box.visible` está ativo; se sim, interromper com `return`.
   - Verificar `_space_grace_msec` (renomear internamente para `_confirm_grace_msec` mantendo compatibilidade retroativa).
   - Executar `_close_alert()`.
2. **Atualização dos Textos de Dica (Hints)**:
   - Onde o tutorial menciona comandos de confirmação (ex.: `TutorialManager.messages`), revisar para indicar "Espaço ou Enter" para avançar diálogos.

## 5. Resultados Esperados
- Pressionar Enter em qualquer alerta comum fecha a janela instantaneamente e executa seu callback ou próximo passo do tutorial.
- Pressionar Enter próximo a portas enquanto um alerta está ativo fecha apenas o alerta, sem forçar a entrada na porta no mesmo frame.
- Menus de escolha e tomada de decisão permanecem seguros contra toques acidentais de teclado.

## 6. Plano de Testes
### Testes Automatizados (`tests/test_alert_queue.gd`)
- Simular emissão de `InputEventKey` com `keycode = KEY_ENTER` e verificar se `AlertManager.panel.visible` torna-se `false`.
- Simular emissão de `InputEventKey` com `keycode = KEY_KP_ENTER` e verificar o fechamento.
- Testar alerta com `choice_box`: emitir `KEY_ENTER` e verificar que o alerta continua aberto (`assert(AlertManager.panel.visible == true)`).
- Verificar que `_close_alert()` decrementa corretamente `Global._gameplay_lock_count`.

### Teste Manual
1. Iniciar novo jogo ou carregar save.
2. Ao surgir a mensagem do tutorial ou aviso diário, pressionar `Enter` e verificar se avança.
3. Repetir utilizando o `Enter` do teclado numérico.
4. Parar em frente à porta do Mercado ou da Escola, abrir um alerta e apertar Enter: confirmar que fecha o alerta e não entra no prédio de imediato.
