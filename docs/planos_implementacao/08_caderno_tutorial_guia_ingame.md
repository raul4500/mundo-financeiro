# Plano de Implementação 08: Caderno de Tutorial e Guia Permanente In-Game

## 1. Identificação e Contexto
- **Objetivo**: Criar uma interface permanente de consulta in-game ("Caderno de Dicas" / "Guia da Cidade") que armazena todas as instruções do tutorial, regras de sobrevivência, guias de locais e mecânicas financeiras, permitindo que o jogador consulte qualquer informação a qualquer momento, mesmo que tenha pulado os diálogos iniciais.
- **Arquivos Afetados**:
  - `scenes/ui/tutorial_notebook.tscn` (nova cena de UI)
  - `scripts/ui/tutorial_notebook.gd` (novo script controlador)
  - `scenes/players/player.tscn` (adição do botão no HUD e atalho de teclado)
  - `scripts/hud/missions_ui.gd` (coordenação visual na barra superior)
  - `scripts/menus/pause_menu.gd` (opção de acesso via menu de pausa)
  - `singletons/Global.gd` (registro de tópicos desbloqueados)
  - `tests/test_tutorial_notebook.gd` (novo teste)

## 2. Diagnóstico da Necessidade
- **O Problema do Jogador Moderno**:
  - Grande parte dos jogadores pula textos tutoriais ou os lê superficialmente na pressa de jogar.
  - Mais adiante, surgem dúvidas críticas: *"Por que não consigo dormir antes das 18h?"*, *"Por que meu salário não subiu?"*, *"Onde foi parar a comida que comprei no mercado?"*, *"Como funciona a taxa de 10% do FII?"*, *"Quando a escola reabre?"*.
  - Atualmente, uma vez que o alerta do tutorial é fechado, **não existe nenhuma forma** no jogo de rever o que foi dito. A informação é perdida para sempre naquela partida.
- **A Solução**: Um "Caderno / Diário de Bordo" acessível a qualquer momento com um clique no HUD ou pela tecla de atalho (`J` / `G` ou via Menu de Pause).

## 3. Arquitetura da Interface do Caderno

### 3.1. Layout da Tela (`tutorial_notebook.tscn`)
- Uma janela modal em `CanvasLayer` (layer 85, abaixo do AlertManager e acima do HUD comum):
  - Fundo translúcido com bloqueio de clique no cenário (`ColorRect`).
  - Caixa central estilizada com `themes/font_theme.tres`.
  - Cabeçalho: Título *"Caderno de Anotações & Guia da Cidade"* e botão "X / Fechar".
  - Divisão em duas colunas:
    - **Coluna Esquerda (Abas e Tópicos)**: Lista de categorias e botões de tópicos navegáveis.
    - **Coluna Direita (Conteúdo Detalhado)**: `ScrollContainer` com `RichTextLabel` exibindo o texto formatado, ícones e destaques.

### 3.2. Categorias e Tópicos Estruturados

1. **🎮 Controles e Comandos**:
   - Movimentação do personagem (WASD / Setas).
   - Interação em portas e balcões (tecla ENTER).
   - Confirmação de alertas e pulos (teclas ESPAÇO ou ENTER).
   - Atalhos de interface: `M` para Missões, `ESC` para Pausar e Salvar, `J` para este Caderno.
2. **⏰ Rotina, Tempo e Sobrevivência**:
   - **O Relógio da Cidade**: Dias úteis das 08h às 18h; a noite começa às 18h e encerra à meia-noite.
   - **Stamina e Sono**: A stamina se esgota durante o dia. Dormir na Casa recupera 100%. Virar a noite cobra R$ 30 e devolve só metade da stamina.
   - **Fome e Sede**: Decaem todos os dias. Fome ou sede em zero causam colapso (game over).
   - **Estoque da Casa**: Tudo o que você compra no mercado vai para a geladeira de casa. Use os botões COMER e BEBER dentro de casa.
3. **🎓 Escola e Carreira**:
   - **Formação Inicial**: A primeira corrida permite subir quantos níveis aguentar.
   - **Aulas Semanais**: Cada semana permite subir 1 nível. Bater antes do checkpoint exige 2 dias de cooldown.
   - **Níveis e Salário**: Fundamental, Médio, Técnico, Graduação e Pós-graduação. Cada nível aumenta o salário base.
4. **🏙️ Locais Importantes**:
   - **Mercado**: Alimentos e bebidas essenciais. Avalie o custo por ponto de saciedade.
   - **Banco**: Saldo em conta, Poupança com rendimento semanal, aba de Contas Fixas e Eventos Pendentes.
   - **Consultoria Financeira**: Lições semanais sobre orçamento, reserva, investimentos e negócios.
   - **Parque da Cidade**: Minigame de coletar moedas e quiz de conhecimentos com cupom de 15% de desconto no mercado.
   - **Empreendimentos**: Restaurante, Fliperama e Centro Comercial (conteúdo avançado da semana 5).
5. **💰 Finanças e Investimentos**:
   - **Reserva de Emergência**: A importância de manter dinheiro líquido para imprevistos.
   - **Poupança**: Rende juros toda virada de semana sobre o saldo aplicado.
   - **Fundos Imobiliários (FIIs)**: Rendem dividendos semanais, mas cotas oscilam de valor. Vender no prejuízo paga 10% de imposto.

## 4. Regras de Negócio e Comportamento
1. **Pausa e Bloqueio de Gameplay**:
   - Ao abrir o caderno, o tempo do jogo para (`Global.play_time = false`) e o gameplay é travado (`Global.lock_gameplay()`), permitindo que o jogador leia com tranquilidade.
   - Ao fechar, o tempo e os controles retornam ao estado anterior.
2. **Atalhos de Abertura**:
   - Botão **[GUIA]** posicionado no HUD superior (ao lado do botão MISSÕES).
   - Tecla de atalho dedicada: Tecla `J` (Journal) ou `G` (Guia).
   - Botão "Guia do Jogo" adicionado ao Menu de Pause (`pause_menu.tscn`).
3. **Notificação de Novo Conteúdo**:
   - Quando uma nova mecânica for ensinada (ex.: na virada de semana ou ao desbloquear o escritório), o botão do Guia pode exibir um pequeno ponto indicador (badge) de novo conteúdo disponível.

## 5. Passo a Passo da Implementação
1. **Criação da Cena `scenes/ui/tutorial_notebook.tscn`**:
   - Montar a árvore de nós: `Control`, `PanelContainer`, `HSplitContainer`, lista de botões de tópicos e `RichTextLabel`.
2. **Criação do Script `scripts/ui/tutorial_notebook.gd`**:
   - Dicionário com os textos completos formatados em BBCode.
   - Lógica de seleção de tópicos e rolagem para o topo ao trocar de aba.
   - Métodos `open()` e `close()` controlando `Global.lock_gameplay()`.
3. **Integração no HUD (`scenes/players/player.tscn`)**:
   - Adicionar o botão `OpenGuide` na barra superior.
   - Conectar o sinal `pressed` ao script de abertura.
   - Capturar o atalho de teclado `_unhandled_input` (tecla `J`).
4. **Integração no Menu de Pause (`scenes/menus/pause_menu.tscn`)**:
   - Adicionar botão "Guia / Instruções" entre "Continuar" e "Sair".

## 6. Resultados Esperados
- O jogador nunca mais fica desamparado caso pule ou esqueça uma instrução do tutorial.
- Consulta instantânea e intuitiva a qualquer momento da partida.
- Interface bonita, legível e integrada à paleta visual do jogo.
- Excelente material de apoio para avaliação de banca de TCC.

## 7. Plano de Testes
### Testes Automatizados (`tests/test_tutorial_notebook.gd`)
- Instanciar a cena do caderno.
- Testar abertura: verificar que `visible == true`, `Global.gameplay_locked == true` e `Global.play_time == false`.
- Percorrer cada tópico e verificar que o texto carregado não está vazio.
- Testar fechamento: verificar retorno ao estado normal de gameplay.

### Teste Manual
1. Entrar no jogo e clicar no botão [GUIA] no topo da tela.
2. Navegar pelas categorias (Controles, Rotina, Escola, Locais, Finanças).
3. Testar fechar com ESC e com o botão de fechar.
4. Pausar o jogo com ESC e acessar o Guia através do botão no Menu de Pause.
