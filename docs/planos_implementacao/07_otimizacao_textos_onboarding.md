# Plano de Implementação 07: Otimização e Enxugamento dos Textos do Tutorial da Semana 1

## 1. Identificação e Contexto
- **Objetivo**: Reduzir a extensão dos textos do onboarding inicial (Semana 1) em aproximadamente 50% a 60%, tornando as mensagens diretas, atrativas e orientadas à ação, evitando que o jogador pule os diálogos por cansaço de leitura e perca os conceitos fundamentais de sobrevivência e progressão.
- **Arquivos Afetados**:
  - `singletons/TutorialManager.gd`
  - `singletons/AlertManager.gd`
  - `tests/test_mechanics.gd`
  - `tests/test_tutorial_time_pause.gd`

## 2. Diagnóstico do Estado Atual
- **Sobrecarga Cognitiva Inicial**:
  - Logo nos passos 1 e 2, o jogador é obrigado a passar por 4 alertas gigantescos (`messages[0]`, `messages[1]`, `messages[28]`, `messages[29]`), somando mais de 1.200 caracteres de texto estático antes mesmo de dar o primeiro passo pelo mapa.
  - No passo 6 (minigame), são mais 5 mensagens consecutivas.
  - No passo 10 (tour do mundo), são 15 mensagens em sequência rápida de câmera.
- **Comportamento do Jogador**:
  - Por causa do volume excessivo de texto, a maioria dos jogadores aperta Espaço ou Enter repetidamente para "se livrar" da caixa de diálogo.
  - Com isso, perdem regras capitais:
    - Que itens comprados no mercado vão para a despensa de casa e não são consumidos no balcão.
    - Que fome e sede zeradas causam colapso e perda de progresso.
    - Como recuperar stamina dormindo antes da meia-noite.
    - Onde e quando cumprir as missões da semana.

## 3. Diretrizes de Redação e Novo Modelo Textual
1. **Regra de Ouro: Máximo de 2 Frases por Alerta**:
   - Cada caixa de alerta deve ter no máximo 150 a 180 caracteres.
   - Frase 1: O fato direto / a mecânica.
   - Frase 2: A ação imediata esperada do jogador.
2. **Eliminação de Jargão Vazio e Sermões Abstratos**:
   - Cortar frases como: *"Neste jogo você vai aprender a cuidar do seu dinheiro, tomar decisões importantes e construir uma vida financeira saudável. Cada escolha que fizer terá consequência..."*.
   - Substituir por: *"Bem-vindo! Seu objetivo é gerenciar seu dinheiro, cumprir metas semanais e construir sua carreira na cidade."*
3. **Distribuição Contextual (Just-In-Time)**:
   - Dividir o aprendizado ao longo do ciclo natural da primeira semana:
     - **Início**: Movimentação básica (WASD), Missões e Escola.
     - **Após a Escola**: Salário recebido e visita à Consultoria.
     - **Após a Consultoria**: Como usar a Casa (dormir, estoque de comida e recuperação de energia).
     - **Às 18:00 do primeiro dia**: Dica prática e curta de recolhimento para dormir.

## 4. Tabela de Comparação: Antes vs. Depois

| Passo / Assunto | Texto Atual (Prolixo) | Novo Texto (Enxuto e Direto) |
|---|---|---|
| **Boas-vindas** | *"Bem-vindo(a) ao Mundo Financeiro! Neste jogo, você vai aprender a cuidar do seu dinheiro, tomar decisões importantes e construir uma vida financeira saudável. Cada escolha que fizer terá consequência, então pense com calma antes de agir."* (246 caracteres) | *"Bem-vindo ao Mundo Financeiro! Gerencie seu dinheiro com sabedoria, cumpra as missões da semana e construa sua independência financeira."* (135 caracteres) |
| **Controles Básicos** | *"Antes de começar a explorar a cidade, conheça os comandos básicos:\n\n• Movimentação: use as teclas W, A, S, D ou as Setas...\n• Interação: aproxime-se de portas...\n• Confirmação: use Espaço..."* (384 caracteres) | *"Controles:\n• Andar: W, A, S, D ou Setas.\n• Entrar em prédios: aproxime-se e aperte ENTER.\n• Confirmar: ESPAÇO ou ENTER."* (120 caracteres) |
| **Missões** | Bloco denso de 4 linhas misturado com relógio e salvamento. | *"Fique atento às suas MISSÕES no topo da tela (tecla M). Cumpra todas as metas até o fim da semana para ser promovido e avançar no jogo!"* (136 caracteres) |
| **Ida à Escola** | 2 alertas repetitivos sobre escolaridade e renda futura. | *"Comece pela sua qualificação. Siga até a Escola para iniciar seus estudos e garantir um salário maior!"* (107 caracteres) |
| **A Casa e Cama** | 6 mensagens longas sobre stamina, meia-noite, R$ 30 de café, decaimento... | *"Sua casa é onde você come, descansa e dorme. Volte antes da meia-noite e clique em DORMIR para recuperar 100% da sua energia para o dia seguinte."* (148 caracteres) |
| **Mercado e Fome** | 3 mensagens longas com comparações minuciosas de pão e carne. | *"Comidas e bebidas compradas no mercado vão para o estoque da sua casa. Mantenha fome e sede acima de zero para não desmaiar!"* (125 caracteres) |

## 5. Passo a Passo da Implementação
1. **Edição do Array `messages` em `singletons/TutorialManager.gd`**:
   - Reescrever as posições de mensagens mantendo a compatibilidade de índices com os pontos de foco da câmera (`message_focus_map`).
2. **Compactação das Filas de Alertas**:
   - No passo 2, unificar as explicações em apenas 2 caixas ágeis (Controles + Missões).
   - No passo 10, fundir mensagens correlacionadas de forma que o tour pela cidade seja dinâmico e não interrompa a câmera com pausas excessivas.
3. **Garantia de Registro no Caderno de Tutorial**:
   - Conectar as mensagens encurtadas ao Caderno In-Game (ver Plano 08) para que o jogador saiba que os detalhes aprofundados estão sempre acessíveis na íntegra a qualquer momento.

## 6. Resultados Esperados
- Tempo gasto na introdução antes do primeiro movimento reduzido de ~45 segundos para ~12 segundos.
- Taxa de retenção e leitura dos alertas aumentada significativamente.
- Menos frustração e jogabilidade muito mais fluida desde o primeiro minuto.

## 7. Plano de Testes
### Testes Automatizados
- Executar `tests/test_tutorial_camera_lock.tscn` e `tests/test_world_tour_camera.tscn` para validar que a nova cadência de mensagens não gera gargalos ou quebras de sinais.

### Teste Manual
1. Criar novo jogo e cronometrar a passagem pelos alertas da Semana 1.
2. Confirmar que o texto cabe confortavelmente na caixa de diálogo sem necessidade de rolagem forçada.
3. Verificar a clareza e ritmo das informações apresentadas.
