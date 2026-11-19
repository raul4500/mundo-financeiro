# Plano de Implementação 04: Tutorial com Encaminhamento Prático para Missões

## 1. Identificação e Contexto
- **Objetivo**: Substituir o texto introdutório passivo e genérico do início do jogo por um encaminhamento prático e interativo para a interface de Missões, ensinando o jogador onde ver seus objetivos da semana e por que eles são o motor de progressão do jogo.
- **Arquivos Afetados**:
  - `singletons/TutorialManager.gd`
  - `scripts/hud/missions_ui.gd`
  - `scenes/players/player.tscn` (HUD de Missões)
  - `singletons/MissionManager.gd`
  - `tests/test_mission_notifications.gd`

## 2. Diagnóstico do Estado Atual
- Atualmente, ao iniciar uma nova partida, o jogo exibe blocos estáticos de texto (`messages[0]`, `messages[1]`, `messages[28]`, `messages[29]`).
- A menção às missões fica perdida no meio de uma lista de atalhos de teclado:
  > *"• Missões: clique no botão MISSÕES no topo da tela (ou use as teclas M ou F) para ver seus objetivos da semana. Cumprir missões é essencial para evoluir."*
- **Problema**: O jogador não é incentivado a abrir o painel, não visualiza as metas da Semana 1, e como a maioria das pessoas pula o texto inicial, muitos passam a semana sem saber que precisam cumprir missões para não repetir a semana.
- Missões não são apenas uma mecânica secundária: elas são o requisito obrigatório para avançar de semana (`MissionManager.check_missions()`).

## 3. Regras de Negócio e Novo Fluxo de Onboarding
1. **Redução Drástica do Texto Inicial**:
   - Eliminar os parágrafos conceituais abstratos sobre "tomar decisões na vida real".
   - Apresentação rápida (1 mensagem direta):
     > *"Bem-vindo ao Mundo Financeiro! Para evoluir na cidade e conquistar sua independência, você precisará cumprir metas semanais."*
2. **Passo Prático de Abertura de Missões**:
   - Em vez de apenas falar sobre as missões, o tutorial deve direcionar a atenção do jogador para o botão **MISSÕES** no canto superior direito:
     - Opção A (Guiada): O tutorial abre automaticamente o painel de missões com um destaque visual e explica as metas da Semana 1.
     - Opção B (Ação Requerida): O tutorial pede para o jogador pressionar `M` ou clicar no botão `MISSÕES` para continuar.
   - Recomendação de design: Abrir o painel de missões diretamente na tela acompanhado de um diálogo explicativo leve e focado:
     > *"Estas são as suas Missões da Semana! Toda semana você receberá novos desafios para gerenciar seu dinheiro. Cumpra todas elas até o final do 5º dia para ser promovido e avançar no jogo."*
3. **Apresentação das Metas da Semana 1**:
   - Destacar os 3 objetivos iniciais do jogador:
     1. Formação escolar na Escola.
     2. Visita à Consultoria Financeira.
     3. Manter o orçamento equilibrado.
4. **Fechamento e Direcionamento para a Escola**:
   - Após fechar o painel de missões, a câmera ou o diálogo aponta o próximo passo:
     > *"Seu primeiro objetivo é qualificar-se. Siga até a Escola para começar seus estudos!"* (Em seguida, câmera foca na Escola).

## 4. Passo a Passo da Implementação
1. **Criação de Sinal e Integração em `scripts/hud/missions_ui.gd`**:
   - Adicionar método `highlight_button()` ou método público `open_for_tutorial()` que exibe o painel de forma guiada.
   - Conectar sinal de abertura/fechamento do painel ao `TutorialManager`.
2. **Reestruturação dos Passos em `singletons/TutorialManager.gd`**:
   - **Passo 1**: Boas-vindas breves (1 caixa de texto).
   - **Passo 2**: Encaminhamento para missões. Emite sinal para abrir o painel de missões com o texto explicativo sobre as metas semanais.
   - **Passo 3**: Fechamento do painel de missões e indicação da Escola como primeiro compromisso.
   - **Passo 4**: Foco de câmera na Escola e início da formação.
3. **Efeito Visual no Botão de Missões (Opcional/Recomendado)**:
   - Adicionar uma pequena pulsação ou modulação de cor no botão `MissionsUi/Open` durante o passo do tutorial para que o jogador memorize sua posição no topo direito da tela.

## 5. Resultados Esperados
- O jogador visualiza concretamente a tela de missões nos primeiros 30 segundos de gameplay.
- Compreensão imediata de que o avanço semanal depende de completar a lista de missões.
- Fim da "parede de texto" estática do início da partida.

## 6. Plano de Testes
### Testes Automatizados
- Simular o fluxo de passos 1 a 3 no `tests/test_mechanics.gd` e validar:
  - Abertura da interface de missões durante o tutorial.
  - Carregamento correto das 3 missões da fase 1.
  - Fechamento da interface e transição suave para o foco da Escola.

### Teste Manual
1. Iniciar "Novo Jogo" com qualquer personagem.
2. Confirmar a mensagem inicial e verificar a abertura guiada da janela de missões.
3. Checar a visibilidade dos objetivos da Semana 1.
4. Fechar missões e verificar o direcionamento imediato para a Escola.
