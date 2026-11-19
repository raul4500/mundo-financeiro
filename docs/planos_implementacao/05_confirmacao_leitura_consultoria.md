# Plano de Implementação 05: Confirmação de Leitura na Consultoria Financeira

## 1. Identificação e Contexto
- **Objetivo**: Implementar um sistema de validação e confirmação de leitura dos conteúdos educativos na Consultoria (Escritório), impedindo que o jogador saia da sala sem interagir com as lições e assegurando que o Banco, Mercado e outros locais só sejam liberados após a conclusão comprovada do estudo.
- **Arquivos Afetados**:
  - `scripts/world/office/office.gd`
  - `scenes/world/places/office.tscn`
  - `singletons/TutorialManager.gd`
  - `singletons/Global.gd`
  - `scripts/world/doors/bank_door.gd`, `market_door.gd`, `office_door.gd`
  - `tests/test_office_study_confirmation.gd` (novo teste)

## 2. Diagnóstico do Estado Atual
- No fluxo atual do tutorial (Passos 8 a 10):
  1. O jogador conclui o minigame da Escola.
  2. O Escritório é desbloqueado (`Global.UNLOCK_OFFICE`).
  3. O jogador entra no Escritório (`office.tscn`).
  4. Na cena do escritório, existe uma lista de tópicos e um botão fixo "Sair" (`exit_button`).
  5. Ao clicar em "Sair", a função `_on_exit_pressed()` chama imediatamente:
     ```gdscript
     TutorialManager.on_player_left_office()
     TransitionManager.change_scene("res://scenes/world/main_game.tscn")
     ```
  6. Ao carregar o mapa, `main_game.gd` executa `_queue_world_tour()` e define `Global.set_unlock_stage(Global.UNLOCK_ALL)`, abrindo toda a cidade.
- **Falha Pedagógica e de Game Design**: O jogador pode entrar no escritório e clicar em "Sair" no mesmo segundo, sem clicar em nenhum tópico nem ler uma única linha sobre finanças, anulando o objetivo didático do jogo.

## 3. Regras de Negócio e Comportamento Esperado
1. **Rastreamento de Tópicos Lidos**:
   - Cada tópico do nível da semana atual (na Semana 1: "Necessidade x Desejo", "Planejamento de gastos", "Orçamento semanal", "Importância de economizar") deve ter seu estado de visualização registrado quando o jogador clica nele.
   - Um indicador visual (ex.: ícone de check `✓` ou mudança de cor) deve sinalizar os tópicos já lidos na lista lateral.
2. **Botão de Conclusão / Confirmação de Leitura**:
   - Um novo botão **"Concluir Aula"** / **"Confirmar Leitura"** deve ser exibido na interface do Escritório.
   - O botão só fica habilitado/ativo após o jogador ter visualizado todos os tópicos obrigatórios do nível da semana.
   - Ao clicar no botão, o jogo exibe uma confirmação de sucesso:
     > *"Parabéns! Você concluiu a formação de Controle de Gastos da Semana 1. Agora você compreende a diferença entre necessidade e desejo e a importância do orçamento. A cidade está liberada!"*
   - O estado de conclusão é registrado no save: `Global.player["office_study_completed_week_1"] = true`.
3. **Bloqueio de Saída Prematura**:
   - Se o jogador tentar clicar em "Sair" antes de ler todos os tópicos e confirmar a conclusão:
     - O jogo exibe um alerta modal via `AlertManager.alert()`:
       > *"Você ainda não concluiu a leitura de todos os tópicos desta aula. Para liberar o Banco, o Mercado e o restante da cidade, leia os conteúdos e clique em 'Concluir Aula'."*
     - A cidade **permanece bloqueada** caso o jogador saia sem confirmar. As portas continuam exibindo o motivo de bloqueio: *"Ainda não. Conclua os estudos na consultoria financeira primeiro."*
4. **Desbloqueio Condicionado**:
   - Apenas após a confirmação de estudo pelo jogador, `TutorialManager.on_player_left_office()` avança para `FINAL_STEP` e destrava o Banco, Mercado e Parque.

## 4. Passo a Passo da Implementação
1. **Estrutura de Dados e Persistência em `singletons/Global.gd`**:
   - Adicionar ao `data_model`:
     `"office_studies_completed": [] # Lista de semanas concluídas`
   - Adicionar helper:
     ```gdscript
     func is_office_study_completed(week: int) -> bool:
         var list: Array = player.get("office_studies_completed", [])
         return list.has(week)
     ```
2. **Atualização da Cena e Script `scripts/world/office/office.gd`**:
   - Criar array local `var viewed_topics: Array = []`.
   - No método `_on_topic_pressed(topic)`:
     - Adicionar o ID ou nome do tópico ao `viewed_topics` caso não conste.
     - Atualizar o texto do botão do tópico para incluir o prefixo `✓ `.
     - Chamar `_check_study_completion()`.
   - Implementar `_check_study_completion()`:
     - Se `viewed_topics.size() == topics.size()`, habilitar o botão `btn_concluir_leitura`.
   - Adicionar o botão `btn_concluir_leitura`:
     - Ao ser pressionado: registra a conclusão no `Global`, emite alerta de celebração de aprendizado e habilita a liberação do tutorial.
   - Modificar `_on_exit_pressed()`:
     - Se o estudo da semana não foi concluído e o tutorial está ativo:
       - Alertar o jogador e não chamar `TutorialManager.on_player_left_office()`.
3. **Integração com `singletons/TutorialManager.gd`**:
   - Garantir que a chamada para avançar o tutorial do escritório dependa estritamente da flag de confirmação de leitura.

## 5. Resultados Esperados
- O jogador é orientado a navegar pelos tópicos da aula.
- Visualmente fica evidente quais conteúdos já foram abertos (checks verdes nos botões).
- O Banco e os demais estabelecimentos permanecem bloqueados até que o jogador confirme formalmente o término do módulo da consultoria.
- Reforço do pilar pedagógico do TCC de Educação Financeira.

## 6. Plano de Testes
### Testes Automatizados (`tests/test_office_study_confirmation.gd`)
- Instanciar a cena `office.tscn`.
- Tentar sair sem abrir tópicos: verificar que `Global.is_place_unlocked("bank")` continua `false`.
- Simular clique em 2 de 4 tópicos: verificar que o botão de confirmação permanece desabilitado.
- Simular clique em todos os 4 tópicos: verificar que o botão de confirmação torna-se habilitado.
- Acionar o botão de confirmação: verificar que a semana é registrada em `Global.player["office_studies_completed"]`.
- Sair da cena: verificar que o mapa destrava o Banco e demais lugares.

### Teste Manual
1. Iniciar jogo, concluir minigame da escola e entrar no Escritório.
2. Tentar clicar direto em "Sair": receber o aviso de estudo pendente.
3. Clicar em cada um dos tópicos à esquerda e ler os detalhes.
4. Clicar em "Concluir Aula".
5. Sair para o mapa e constatar que o Banco e o Mercado agora estão com as portas destravadas.
