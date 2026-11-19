# Plano de Implementação 06: Remoção e Substituição de Tracejados nos Textos do Jogo

## 1. Identificação e Contexto
- **Objetivo**: Localizar e substituir todos os tracejados (`---`, `—`, `--` e hifens soltos como separadores) presentes nos textos da interface, diálogos do tutorial, conteúdos da consultoria, avisos do HUD e notificações, substituindo-os por pontuação gramaticalmente adequada (dois-pontos, vírgulas, parênteses ou marcadores `•`).
- **Arquivos Afetados**:
  - `singletons/TutorialManager.gd`
  - `scripts/world/office/office.gd`
  - `scripts/hud/missions_ui.gd`
  - `singletons/MissionManager.gd`
  - `scripts/hud/clock.gd`
  - `singletons/EventsManager.gd`
  - `singletons/FIIManager.gd`
  - `scripts/enterprise/enterprise_management.gd`
  - `tests/test_mechanics.gd` (compatibilidade com asserções de texto)

## 2. Diagnóstico do Estado Atual
1. **Problema de Renderização Visual na Tipografia**:
   - O projeto utiliza fontes personalizadas (`themes/font_theme.tres` e `themes/label.tres`).
   - Caracteres como travessão unicode (`—`, em-dash) ou sequências de hifens (`--` / `---`) sofrem problemas de renderização e quebra de glifo, aparecendo com espaçamentos desiguais ou parecendo artefatos de "texto rasurado" ou tracejado solto no meio da frase.
2. **Uso Vicioso de Hifens como Separadores Sintáticos**:
   - Em dezenas de mensagens do tutorial e aulas da consultoria, o travessão foi utilizado repetidamente no lugar de vírgulas, parênteses ou dois-pontos.
   - Exemplos no código atual:
     - `TutorialManager.gd`: *"sem limite — a corrida só termina quando você bater em um obstáculo."*
     - `TutorialManager.gd`: *"o que o dia gasta — comer, beber e descansar acontecem lá dentro — e o único lugar..."*
     - `office.gd`: *"pensar depois — e isso quase sempre leva a problemas."*
     - `office.gd`: *"Restaurante Sabor da Praça - R$ 1.000"*
     - `clock.gd`: `"Dia %d  -  %02dh"`
     - `missions_ui.gd`: `("- " + entry["description"])`
     - `MissionManager.gd`: `" - %s\n"`
     - `EventsManager.gd`: `"%s - %s"`

## 3. Regras de Substituição Padronizada
Para manter a elegância textual e a máxima clareza na tipografia do jogo, adotar a seguinte tabela de conversão:

| Padrão Original | Contexto de Uso | Substituição Recomendada | Exemplo Prático |
|---|---|---|---|
| `Texto A — Texto B` | Explicação complementar | `Texto A, Texto B` ou `Texto A (Texto B)` | *"o dia gasta (comer, beber e descansar)..."* |
| `Texto — conclusão` | Pausa conclusiva | `Texto; conclusão` ou `Texto: conclusão` | *"sem limite: a corrida só termina quando bater"* |
| `Item - R$ Valor` | Preço ou definição | `Item: R$ Valor` ou `Item | R$ Valor` | *"Restaurante Sabor da Praça: R$ 1.000"* |
| `- Missão não feita` | Marcador de lista não ordenada | `• Missão não feita` (bullet point) | `• Comprar comida no mercado` |
| `"Dia %d  -  %02dh"` | Relógio do HUD | `"Dia %d • %02dh"` ou `"Dia %d | %02dh"` | `"Dia 1 • 08h"` |
| `Título - Subtítulo` | Notificações de eventos/banco | `Título: Subtítulo` | `"Conta da Casa: Água e Luz"` |

## 4. Passo a Passo da Implementação
1. **Varredura e Limpeza em `singletons/TutorialManager.gd`**:
   - Substituir todas as ocorrências de `—` e ` - ` nas strings do array `messages` e `weekly_messages` pelas pontuações da tabela de regras.
2. **Varredura e Limpeza em `scripts/world/office/office.gd`**:
   - Ajustar as descrições em `levels_data` nos 5 níveis de ensino, substituindo travessões parentéticos por vírgulas ou parênteses.
   - Ajustar listas de preços de negócios para usar dois-pontos (`Restaurante: R$ 1.000`).
3. **Ajuste no HUD de Missões (`scripts/hud/missions_ui.gd`) e `MissionManager.gd`**:
   - Trocar o prefixo de itens não concluídos de `"- "` para `"• "`:
     ```gdscript
     label.text = ("✓ " if done else "• ") + entry["description"]
     ```
   - Em `MissionManager.gd:check_missions()`, trocar `text += " - %s\n"` por `text += " • %s\n"`.
4. **Ajuste no Relógio (`scripts/hud/clock.gd`)**:
   - Atualizar a formatação para:
     ```gdscript
     clock_label.text = "Dia %d • %02dh" % [TimeManager.current_day, h]
     ```
5. **Ajuste em Eventos e FIIs (`EventsManager.gd` e `FIIManager.gd`)**:
   - Trocar separadores de títulos e recibos para dois-pontos.

## 5. Resultados Esperados
- Eliminação total de caracteres tracejados (`---`, `—`) em todos os textos visíveis ao jogador.
- Melhora substancial da legibilidade em resoluções baixas e com fontes rasterizadas/pixeladas.
- Padrão gramatical culto e coeso em toda a interface do jogo.

## 6. Plano de Testes
### Testes Automatizados
- Executar script de validação de strings que percorre todas as mensagens públicas e labels assegurando que nenhuma string contenha `---` ou `—`.
- Executar suíte de testes de mecânica (`tests/test_mechanics.tscn`) e ajustar asserções legadas caso necessário.

### Teste Manual
1. Abrir o jogo e conferir o HUD superior (Relógio e Missões).
2. Abrir um diálogo do tutorial e confirmar ausência de travessões.
3. Entrar na Consultoria e conferir o texto dos 5 níveis de conteúdo.
4. Entrar no Banco e verificar títulos de contas e eventos pendentes.
