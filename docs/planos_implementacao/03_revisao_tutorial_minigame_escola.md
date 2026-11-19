# Plano de Implementação 03: Revisão Gramatical e Alinhamento Real do Minigame da Escola

## 1. Identificação e Contexto
- **Objetivo**: Corrigir a incongruência entre o texto introdutório da Escola e a mecânica real do Minigame de Formação (que é uma corrida de obstáculos com pulo em vez de perguntas/respostas ou escolhas teóricas), aprimorar a gramática, a pontuação e enxugar as mensagens explicativas.
- **Arquivos Afetados**:
  - `singletons/TutorialManager.gd` (textos das mensagens de passos 3 a 7 e guia de apresentação)
  - `scripts/minigame/minigame.gd` (painel de introdução "Aula de hoje")
  - `singletons/MinigameManager.gd` (mensagens de porta e avisos de checkpoint)
  - `tests/test_mechanics.gd` / `tests/test_school_minigame_spawn.gd`

## 2. Diagnóstico do Estado Atual
1. **Incongruência Temática Grave**:
   - No `presentation_guide` e resquícios de textos antigos, o tutorial afirma:
     > *"Neste minigame, você precisará responder corretamente e tomar decisões relacionadas à sua formação. Foque nos conhecimentos essenciais..."*
     > *"Sempre pense em como cada decisão pode abrir ou fechar portas para suas metas financeiras."*
   - Na prática, o minigame da escola é um **jogo de plataforma/runner com física contínua**: o personagem corre automaticamente pelo corredor da escola e o jogador deve pressionar a tecla `Espaço` no tempo correto para pular sobre bancos, cones e caixas até cruzar os checkpoints de nível. Não existe quiz nem tomada de decisões conceituais nesse minigame (o quiz com perguntas fica no Parque).
2. **Prolixidade Excessiva na Entrada da Escola**:
   - Ao entrar na escola pela primeira vez, o jogador é interrompido por uma sequência de 5 caixas de alerta consecutivas (`messages[4]` a `messages[8]`), repletas de repetições e texto denso antes de poder clicar em "Começar".
3. **Problemas Gramaticais e de Estilo**:
   - Uso inconsistente de travessões (`—`) misturados com hifens simples (`-`).
   - Falta de paralelismo sintático e frases truncadas.

## 3. Regras de Negócio e Novo Conteúdo Textual
1. **Fidelidade Mecânica**:
   - O texto deve explicar explicitamente que o estudo é representado por um teste de agilidade e perseverança (superação de obstáculos).
   - O comando deve ser claro: **pressionar ESPAÇO para saltar**.
2. **Conexão Direta com a Vida Financeira**:
   - Explicar de forma sucinta que cada checkpoint cruzado representa um nível a mais de escolaridade (de 1 a 5), e cada nível aumenta permanentemente o salário recebido na virada de semana.
3. **Consolidação em Menos Mensagens (Enxugamento)**:
   - Reduzir a sequência de 5 alertas para 2 ou 3 alertas objetivos e bem formatados:
     - **Mensagem A (Mecânica e Controles)**:
       > *"Bem-vindo(a) à sua formação escolar! Aqui você supera os desafios dos estudos na prática. O seu personagem corre automaticamente: pressione ESPAÇO no momento certo para pular os obstáculos pelo caminho."*
     - **Mensagem B (Impacto Salarial e Checkpoints)**:
       > *"Cada checkpoint ultrapassado garante um nível a mais de escolaridade e aumenta o seu salário semanal. Nesta primeira corrida, vá o mais longe que conseguir antes de esbarrar em um obstáculo!"*
     - **Mensagem C (Regras Futuras e Cooldown)**:
       > *"Nas próximas semanas, cada ida à escola permitirá avançar 1 nível por vez. Se tropeçar antes da meta, será preciso esperar 2 dias de descanso para tentar de novo."*
4. **Painel "Aula de Hoje" em `minigame.gd`**:
   - Atualizar o texto do painel pré-corrida para exibir informações contextuais claras:
     - Título: *"Corrida de Formação Escolar"*
     - Subtítulo: *"Pressione ESPAÇO para pular os obstáculos até o próximo checkpoint."*
     - Indicador da meta: *"Meta atual: Nível %d (%s) - Salário: R$ %d"*

## 4. Passo a Passo da Implementação
1. **Revisão em `singletons/TutorialManager.gd`**:
   - Substituir os textos de `messages[4]`, `messages[5]`, `messages[6]`, `messages[7]` e `messages[8]`.
   - Na fila do passo 6 em `_next_step()`, enfileirar a nova lista enxugada de mensagens.
   - Atualizar as anotações do `presentation_guide` para refletir fielmente a mecânica de runner com saltos.
2. **Refinamento em `scripts/minigame/minigame.gd`**:
   - Em `_create_start_screen()`, ajustar os labels para utilizar a nova redação e tipografia limpa.
3. **Verificação de Consistência em `singletons/MinigameManager.gd`**:
   - Revisar as strings de `LEVEL_LABELS` (ex.: "Ensino Fundamental", "Ensino Médio", "Ensino Técnico", "Graduação", "Pós-graduação") e os avisos de cooldown nas portas.

## 5. Resultados Esperados
- O jogador lê uma explicação coerente com o que vê na tela (pular obstáculos com Espaço para subir de nível e salário).
- Ausência total de referências enganosas a "responder perguntas" ou "tomar decisões teóricas" na escola.
- Redução de leitura entediante antes do minigame começar, acelerando o ciclo de ação do jogador.
- Gramática, pontuação e clareza impecáveis em português.

## 6. Plano de Testes
### Testes Automatizados
- Executar `tests/test_school_minigame_spawn.tscn` para garantir que o fluxo de checkpoints e avanço de nível permaneça íntegro.
- Atualizar asserções de texto em `tests/test_mechanics.gd` que façam busca por trechos exatos das mensagens antigas.

### Teste Manual
1. Iniciar novo jogo e seguir até a Escola.
2. Ler a nova introdução antes e dentro do minigame.
3. Constatar que a mensagem orienta exatamente a pular com a tecla Espaço.
4. Concluir a corrida e constatar que o aumento salarial e o nível são informados com clareza.
