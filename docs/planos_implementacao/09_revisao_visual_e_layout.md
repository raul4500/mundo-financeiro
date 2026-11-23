# Plano de Implementação 09: Revisão visual e de layout dos planos 01 a 08

## 1. Contexto
Os planos 01 a 08 foram implementados com foco no comportamento, sem conferir o resultado na tela. Esta revisão percorre cada plano, ajusta o visual dos componentes novos para seguir o tema do projeto (`themes/font_theme.tres`, `themes/label.tres`) e corrige as inconsistências de lógica encontradas pelo caminho.

Nada foi executado no Godot (não há o editor disponível neste ambiente): as alterações foram conferidas por leitura do código e das cenas. Rodar `tests/test_mechanics.tscn` e olhar as telas abaixo é o passo seguinte.

## 2. O que foi encontrado e alterado, plano a plano

| Plano | Problema | Ajuste |
|---|---|---|
| 01 Enter nos alertas | Nenhum problema visual. A constante da película escura estava solta em `AlertManager`. | `AlertManager.DIM_COLOR`, usada também pelo Guia do Jogo. |
| 02 Continuar jogo | Lógica correta. O botão "Pular tutorial" ficava por cima de MISSÕES e GUIA. | Botão movido para o canto inferior direito. |
| 03 Minigame da escola | A tela de início não mostrava a meta (o plano pedia). | Linha "Meta: nível seguinte e salário" (ou o texto da formação inicial). Fórmula do salário em `Global.salary_for_level()`, um só lugar. |
| 04 Missões no tutorial | O painel abria por trás do alerta e era coberto por ele. O destaque do botão usava `modulate` com cor fora do tema. | O alerta lista as missões da semana; o botão MISSÕES pulsa (escala, sem cor) até o jogador abrir o painel. |
| 05 Consultoria | Botão "Concluir Aula" criado em código com números soltos (50 px de altura contra 52 do Sair). Texto de ajuda em `RichTextLabel` sem cor, quase invisível. Botão aparecia em saves sem trava. Erro de digitação no nível 5 ("Empreendorismo"). | Botão herda a geometria do Sair. Cor do texto vem do tema. Botão só existe com a cidade fechada. Capitalização unificada ("Concluir aula"). Botão de tópico com tamanho fixo (altura do Sair, texto cortado com reticências, sem foco): o clique que colocava o "✓" no texto fazia a altura do botão diminuir. |
| 06 Tracejados | Sobraram separadores " - " em textos de mercado, histórico do banco, histórico da casa e mensagens de desmaio. Relógio com formatos diferentes ("•" e "|"). | Todos trocados pelo padrão do plano (":" ou "•"). |
| 07 Textos do onboarding | Texto da mensagem de missões dizia "painel aberto na tela", o que deixou de valer. | Texto novo, com a lista de missões dinâmica. |
| 08 Guia do Jogo | Botão GUIA com 120x52 ao lado de MISSÕES 140x52, posição absoluta. Botão do menu de pausa mais estreito que os outros. Tópico escolhido pintado com `modulate`. Título diferente do nome do botão. Texto com "nível 5" (o máximo é 6), duração do parque desatualizada, lista sem recuo. | Ver seção 3. |

Também foi corrigido o check das missões cumpridas (`DONE_COLOR`, uma cor solta que ficava escura sobre a pílula marrom): agora é a variação de tema `LabelDone`.

## 3. Detalhes do Guia do Jogo
- Botão GUIA movido para `player.tscn`, ao lado de MISSÕES, com o mesmo tamanho e âncora no canto superior direito. `MissionsUi` liga o clique ao Guia.
- Janela: `PanelContainer` do tema, título com `label.tres`, botão FECHAR com a altura do tema, tópicos como botões `toggle_mode` em `ButtonGroup`, texto em `RichTextLabel` com lista `[ul]`.
- Textos com números de regras usam marcadores `{...}` resolvidos a partir das constantes dos singletons.
- Nome único para a funcionalidade: "Guia do Jogo" (botão, menu de pausa, título da janela, mensagens do tutorial).
- ESC com o Guia aberto fecha só o Guia.

## 4. Itens fora do escopo, deixados como estavam
- O `Overlay` do painel de missões continua sendo um `Panel` em tela cheia sem tema próprio (fundo cinza padrão do Godot).
- ESC com o painel de missões aberto abre o menu de pausa em vez de fechar o painel: `pause_menu._input` consome o ESC antes de `MissionsUi._unhandled_input`.
- As barras de rolagem usam o visual padrão do Godot (o tema não define `VScrollBar`).

## 5. Conferência manual sugerida
1. Novo jogo: o alerta de missões lista as 3 metas e o botão MISSÕES pulsa até ser aberto.
2. Topo da tela: GUIA e MISSÕES com o mesmo tamanho e lado a lado, sem o botão "Pular tutorial" por cima.
3. Guia do Jogo (botão, J e menu de pausa): tópico escolhido destacado, listas com recuo, ESC fecha só o guia.
4. Consultoria na semana 1: "Concluir aula" do mesmo tamanho do Sair, texto de ajuda legível. Depois do tutorial, o botão não aparece.
5. Painel de missões: missão cumprida com pílula verde.
6. Pausa: Continuar, Guia do Jogo e Sair com a mesma largura.
