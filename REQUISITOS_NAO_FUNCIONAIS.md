# Especificação de Requisitos Não Funcionais (RNF) — Mundo Financeiro

Este documento define os Requisitos Não Funcionais do projeto **Mundo Financeiro** (desenvolvido em **Godot 4**), abrangendo restrições de arquitetura, desempenho, usabilidade, confiabilidade, compatibilidade e manutenção.

---

## 1. Arquitetura e Engenharia de Software

- **RNF001 - Padrão de Estado Centralizado (Single Source of Truth)**:
  - Todo o estado persistente do jogador deve residir exclusivamente no singleton Global.player.
  - Scripts de cena não devem manter cópias locais desacopladas de variáveis financeiras ou vitais.
- **RNF002 - Ordem e Dependência de Autoloads**:
  - A ordem de registro de singletons no project.godot deve ser estritamente preservada para evitar referências nulas no _ready().
  - Logger deve ser o primeiro singleton a inicializar; Global e SaveManager devem anteceder singletons dependentes de jogador como EnterpriseManager, FIIManager, EventsManager e MissionManager.
- **RNF003 - Separação de Layout e Conteúdo (Layout-Driven Scenes)**:
  - As cenas .tscn devem ser a única fonte de verdade para hierarquia de nós visuais, containers e posicionamento.
  - Scripts devem limitar-se a capturar nós fixos via @onready (ou _find()) e manipular instâncias dinâmicas filhas (itens de listas, linhas de tabela), sendo vedada a recriação da carcaça da interface via código.
- **RNF004 - Gestão Concorrente de Travas de Gameplay**:
  - O bloqueio de interação do jogador (gameplay_locked) deve operar por meio de contador acumulativo de bloqueios (lock_gameplay() / unlock_gameplay()), impedindo que a liberação de um sistema (ex.: fim de cutscene) destrave prematuramente outro processo ativo simultâneo (ex.: alerta modal).
- **RNF005 - Ponto Único de Troca de Cenas**:
  - Toda navegação entre cenas deve ser intermediada por TransitionManager.change_scene(path). É proibida a chamada direta a get_tree().change_scene_to_file() em nós normais de cena para prevenir vazamento de corrotinas e orfandade de nós liberados.
- **RNF006 - Resolução Defensiva de Nós de UI**:
  - Telas complexas e reutilizáveis (como a interface de empreendimentos) devem implementar busca resiliente (ind_child) com logging de advertência caso o caminho estático de nós sofra refatoração no editor, evitando quebras de execução (
ull pointer assignment).

---

## 2. Desempenho e Eficiência

- **RNF007 - Taxa de Quadros Alvo**:
  - O jogo deve manter taxa estável de 60 quadros por segundo (FPS) em computadores com configurações padrão de hardware sem placa gráfica dedicada.
- **RNF008 - Alocação e Descarte Seguro de Nós de Interface**:
  - Rotinas de atualização de listas visuais (_clear_list()) devem invocar emove_child() imediatamente antes de queue_free(), evitando acúmulo de nós pendentes de liberação no mesmo frame gráfico.
- **RNF009 - Amostragem de Spawn por Rejeição Eficiente**:
  - O algoritmo de sorteio de coordenadas dentro de polígonos irregulares de mundo (ex.: minigame do parque) deve limitar a busca a um número máximo pré-definido de iterações (máx. 30 tentativas) com fallback determinístico (centroide), impedindo travamento de thread principal.
- **RNF010 - Otimização de Varredura de Metas (Mission Polling)**:
  - O polling de verificação contínua do cumprimento de missões deve ser executado com intervalo moderado (mínimo de 0,5 segundos), evitando iterações custosas a cada quadro (_process).

---

## 3. Persistência, Integridade e Confiabilidade

- **RNF011 - Formato Aberto e Interoperável de Salvamento**:
  - Os dados de save devem ser serializados no formato padrão JSON codificado em UTF-8 no diretório seguro do usuário (user://saves/save_<id>.json).
- **RNF012 - Limite e Controle de Crescimento de Históricos**:
  - Estruturas de log e históricos armazenados no save do jogador devem possuir limites máximos de retenção (ex.: histórico de operações empresariais limitado a 50 entradas; histórico de eventos resolvidos limitado a 30 entradas), prevenindo crescimento descontrolado do arquivo de salvamento.
- **RNF013 - Isolamento de Dados Entre Sessões**:
  - Ao alternar entre partidas ou criar novo jogo, a memória de singletons globais (carteira de ações/FIIs, cooldowns de escola e parque) deve ser integralmente purgada para evitar vazamento cruzado de informações.
- **RNF014 - Tolerância a Falhas e Recuperação de Save**:
  - Erros de parsing ou corrupção de arquivos de salvamento não devem impedir a execução do jogo; o sistema deve marcar o slot como corrompido e conceder a opção de exclusão controlada.
- **RNF015 - Sistema de Logs de Execução (Runtime Logger)**:
  - Erros críticos, advertências de gameplay e checkpoints de carregamento devem ser gravados em arquivo físico de log (logs/game_runtime.log), garantindo rastreabilidade de falhas sem depender de depurador acoplado.

---

## 4. Usabilidade, Acessibilidade e Interface

- **RNF016 - Resolução Base e Responsividade**:
  - O jogo deve operar com resolução base de **1152 × 648 pixels**, projetado para manter legibilidade integral tanto em modo janela quanto em tela cheia via proporção escalada (stretch mode canvas_items ou iewport).
- **RNF017 - Prevenção de Transbordamento de Textos (Autowrap Obrigatório)**:
  - Todo componente Label destinado a exibir textos de comprimento variável ou dinâmico deve configurar obrigatoriamente utowrap_mode = TextServer.AUTOWRAP_WORD, impedindo que textos longos forcem expansão anormal de containers e empurrem elementos para fora do viewport.
- **RNF018 - Rolagem Vertical com Trava Horizontal**:
  - Áreas de rolagem de listas (ScrollContainer) devem operar com horizontal_scroll_mode = 0 (desabilitado), garantindo que listas de textos e tabelas quebrem verticalmente sem produzir barras de rolagem horizontais espúrias.
- **RNF019 - Nitidez Visual de UI no Espaço de Mundo (Subpixel Scaling)**:
  - Elementos de interface renderizados no mundo sob o zoom da câmera do jogador (como painéis informativos de portas) devem aplicar fator de escala inverso exato ao zoom da câmera (scale = 1.0 / zoom), assegurando fontes renderizadas em escala 1:1 livres de distorções e borrões de interpolação.
- **RNF020 - Consistência Temática e Tipografia**:
  - A identidade visual deve ser rigorosamente padronizada:
    - Painéis, containers estruturais e botões devem adotar 	hemes/font_theme.tres;
    - Labels de conteúdo e mensagens devem aplicar 	hemes/label.tres (ou variações corporativas de tamanho 15/16) sem herdar estilos com bordas pesadas por propagação;
    - Caracteres especiais e ícones (como o símbolo de checagem ✓) devem pertencer estritamente ao mapa de caracteres da fonte nativa (ex.: PixeloidSansBold).
- **RNF021 - Hierarquia de Camadas Visuais (CanvasLayer Layers)**:
  - A ordem de sobreposição na tela deve obedecer às camadas de renderização pré-definidas:
    - Displays secundários e tempo: layer = 5 a 10;
    - HUD principal do jogador: padrão de cena;
    - Tela de início de minigame: layer = 50;
    - Toasts de notificação (NotificationManager): layer = 90;
    - Alerta modal prioritário (AlertManager): layer = 100;
    - Cortina de transição entre telas (TransitionManager): layer = 200.
- **RNF022 - Controles Sem Conflito e Sem Foco Acidental**:
  - Botões de alerta modal não devem reter foco por teclado (ocus_mode = FOCUS_NONE), reservando a tecla Enter exclusivamente para confirmações explícitas do jogo e evitando que a barra de espaço ou Enter disparem ações indesejadas em cascata.

---

## 5. Portabilidade e Compatibilidade

- **RNF023 - Compatibilidade de Plataforma**:
  - O código-fonte GDScript e as cenas devem ser compatíveis com os ambientes Windows, Linux e macOS sob o runtime oficial do Godot 4.3+.
- **RNF024 - Independência de Ambientes Gráficos em Testes**:
  - As lógicas de negócio e regras matemáticas dos singletons devem ser passíveis de validação por meio de rotinas de teste unitário/integração (	ests/), sem dependência estrita de interação humana contínua.
