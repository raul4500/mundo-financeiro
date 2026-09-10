# Plano de Implementação — Comandos de Teste e Apresentação de TCC (Debug Cheats)

## 1. Objetivo e Contexto

Durante a banca de TCC (tempo limite de **30 minutos**), é inviável demonstrar todas as semanas, locais, minigames, investimentos em FIIs e gestão de empresas jogando o loop normal do jogo.

Este plano define a criação de um **sistema temporário de atalhos numéricos (teclas 0 a 9)** para permitir que o apresentador demonstre qualquer mecânica do jogo sob demanda, em segundos.

### Diretriz Crítica: Remoção Limpa Pós-TCC
O sistema será implementado de forma **100% isolada e modular** (Autoload único `singletons/DebugCommands.gd` + Overlay visual opcional).
- Nenhuma lógica de trapaça será misturada ou espalhada dentro dos scripts principais (`TimeManager.gd`, `Global.gd`, `MissionManager.gd`, etc.).
- Quando o TCC for finalizado, a desativação ou remoção completa exigirá apenas:
  1. Desmarcar ou excluir o autoload no `project.godot`.
  2. Deletar o arquivo `singletons/DebugCommands.gd` (e seu `.tscn` correspondente se houver).

---

## 2. Mapeamento das Teclas Numéricas (Limite de 10 Comandos)

As teclas numéricas (`KEY_0` a `KEY_9` no teclado alfanumérico e teclado numérico) foram selecionadas cobrindo todos os pilares do jogo:

| Tecla | Nome do Comando | O que faz no jogo | Utilidade na Apresentação da Banca |
|---|---|---|---|
| **`[1]`** | **Velocidade do Tempo** | Alterna velocidade (`time_scale`): Normal (7x) &rarr; Rápido (35x) &rarr; Ultra (140x) &rarr; Pausado (0x). | Mostrar o relógio correndo e a passagem dos minutos/horas sem espera. |
| **`[2]`** | **Avançar Dia (+1 Dia)** | Executa o fechamento contábil e inicia as 08h do dia seguinte imediatamente. | Mostrar a transição de dias e a rotina sem ter que andar até a casa e dormir. |
| **`[3]`** | **Avançar Semana (+1 Semana)** | Processa a virada semanal: paga salário, dividendos, gera contas e avança para a semana N+1. | Ir direto para as Semanas 2, 3, 4 e 5 para exibir o destravamento gradual de mecânicas. |
| **`[4]`** | **Injetar Dinheiro (+R$ 5.000)** | Adiciona R$ 5.000,00 instantaneamente a `Global.player["money"]`. | Ter liquidez para comprar itens caros no mercado, cotas de FIIs e empresas no ato. |
| **`[5]`** | **Auto-Completar Missões** | Preenche todas as condições exigidas pelas missões da semana atual. | Garantir aprovação imediata no `MissionManager.verify_missions()` sem falhar ou repetir semana. |
| **`[6]`** | **God Mode (Max Necessidades)** | Restaura Fome (100%), Sede (100%) e Stamina (100%) e limpa alertas de cansaço. | Impedir Game Over indesejado ou travamentos de exaustão durante a explicação oral. |
| **`[7]`** | **Pular Tutorial & Destravar Portas** | Executa `skip_tutorial()`, destrava todos os prédios (`UNLOCK_ALL`) e libera o jogador. | Entrar em qualquer edifício imediatamente sem depender da ordem do onboarding. |
| **`[8]`** | **Subir Nível Escolar (+1 Nível)** | Aumenta `school_level` (+1 até máx 5), sobe o salário e zera o cooldown do minigame. | Demonstrar o impacto da educação no salário e testar o minigame sem esperar 2 dias. |
| **`[9]`** | **Gerar Evento Inesperado** | Força a criação imediata de uma pendência de imprevisto ou bônus no banco. | Mostrar à banca a tela do banco resolvendo uma conta de imprevisto (ex: mecânico). |
| **`[0]`** | **Setup Rápido de Empresa** | Compra o *Restaurante*, adiciona lote de insumos e contrata 1 funcionário no ato. | Demonstrar a tela completa de administração de empresas (`enterprise-view.tscn`) com números reais. |

> **Bônus de Usabilidade:** Tecla **`[F1]`** ou **`[H]`**: Mostra/oculta um painel discreto e semi-transparente no canto superior direito com o resumo dessas teclas, para evitar esquecimento durante o nervosismo da apresentação.

---

## 3. Especificação Técnica dos Comandos

### `[1]` Aceleração de Tempo
- **Ação:** Alterna `TimeManager.time_scale` entre `[7.0, 35.0, 140.0]`.
- **Feedback:** Notificação breve ("Velocidade do tempo: 5x", "20x", "Normal").

### `[2]` Avançar Dia
- **Ação:** 
  1. Chama `TimeManager._close_day(100.0)` para efetivar as operações contábeis do dia.
  2. Chama `TimeManager._advance_to_next_day()`.
- **Resultado:** O relógio reseta para 08:00, o dia incrementa e o jogador é posicionado no mapa sem passar pela penalidade da meia-noite.

### `[3]` Avançar Semana
- **Ação:**
  1. Garante que as missões da semana passem chamando a rotina do comando `[5]`.
  2. Força `TimeManager.current_day = 7`.
  3. Chama `TimeManager._process_week_rollover()`.
- **Resultado:** Avança a semana, emite o sinal `week_changed`, gera contas de água/luz, paga dividendos de fundos e atualiza o conteúdo do escritório e tutorial semanal.

### `[4]` Injetar Dinheiro (+ R$ 5.000,00)
- **Ação:** `Global.player["money"] = float(Global.player.get("money", 0.0)) + 5000.0`.
- **Resultado:** O HUD reflete o novo saldo no frame seguinte automaticamente (via `hud_control.gd`).

### `[5]` Concluir Missões da Semana Atual
- **Ação:** Injeta os dados necessários em `Global.player` para que `MissionManager._check_mission()` valide com `true` para todas as missões da semana atual:
  - `Global.player["money"] = max(Global.player.get("money", 0.0), 1000.0)`
  - `Global.player["had_no_spend_day"] = true`
  - `Global.player["no_spend_days_count"] = 7`
  - `Global.player["positive_days_count"] = 7`
  - Se histórico de despesas vazio, adiciona 1 registro de teste
  - Se houver eventos pendentes da semana, marca como `paid`
  - Se semana 3/4, garante cotas em FIIs através de `FIIManager.buy_fund("FII_SHOPPING", 1)`
  - Se semana 5, garante compra do restaurante e abastecimento de estoque.

### `[6]` Restaurar Necessidades (Max Status)
- **Ação:**
  - `Global.player["hunger"] = 100.0`
  - `Global.player["thirst"] = 100.0`
  - `Global.player["stamina"] = 100.0`
  - `TimeManager._exhaustion_alert_shown = false`
  - `TimeManager._no_stamina_alert_shown = false`
  - `Global._game_over = false`
- **Resultado:** Barras do HUD cheias, cansaço eliminado e risco de morte removido.

### `[7]` Destravar Tudo e Pular Tutorial
- **Ação:**
  - `TutorialManager.skip_tutorial()`
  - `Global.set_unlock_stage(Global.UNLOCK_ALL)`
  - `Global.force_release_all_gameplay_locks()`
- **Resultado:** Mensagens de tutorial canceladas, movimento liberado e portas de Banco, Mercado, Escritório, Escola e Empresas abertas para entrada imediata.

### `[8]` Subir Nível Escolar (+1 School Level)
- **Ação:**
  - `var lvl = int(Global.player.get("school_level", 1))`
  - Se `lvl < 5`: `Global.player["school_level"] = lvl + 1`
  - Recalcula salário: `Global.player["salary"] = Global.player["school_level"] * 300.0`
  - Zera travas da escola: `Global.player["minigame_progress"] = {"unlock_week": 1, "unlock_day": 0, "sessions_played": 1}`
- **Resultado:** Jogador ganha aumento de salário, o escritório reconhece o novo nível e a porta da escola permite jogar imediatamente.

### `[9]` Gerar Evento Inesperado
- **Ação:**
  - Força a chamada de sorteio de `EventsManager.sortear_evento()` e insere em `Global.player["pending_events"]`.
  - Dispara notificação visual na tela indicando que um evento chegou ao Banco.

### `[10]` Setup Rápido de Empreendimento (Restaurante)
- **Ação:**
  - Se `restaurant_small` não comprado: chama `EnterpriseManager.buy_enterprise("restaurant_small")`.
  - Injeta estoque inicial com `EnterpriseManager.buy_stock("restaurant_small", "ingredients")`.
  - Contrata funcionário com `EnterpriseManager.hire_employee("restaurant_small")`.
- **Resultado:** Ao entrar na porta do restaurante, a tela de gestão já abre com dados populados (gráficos de receita, custo de funcionários e estoque disponível).

---

## 4. Arquitetura de Implementação

### 4.1 Estrutura de Arquivos
```
singletons/
└── DebugCommands.gd      # Autoload único contendo toda a lógica e captura de teclas
```

### 4.2 Padrão de Captura de Teclas
O script utilizará `_unhandled_input(event: InputEvent)`:
- Garante que só reage quando a tecla for recém-pressionada (`event.is_pressed() and not event.is_echo()`), evitando que segurar a tecla execute o comando centenas de vezes.
- Suporta tanto as teclas numéricas superiores (`KEY_1` .. `KEY_0`) quanto as do teclado numérico (`KEY_KP_1` .. `KEY_KP_0`).
- Flag mestre `const CHEATS_ENABLED := true`: alterar para `false` desliga todo o processamento instantaneamente.

### 4.3 Feedback Visual (Toast Notification)
Para que o apresentador não fique em dúvida durante a banca se a tecla surtiu efeito, cada comando exibirá um aviso rápido no topo da tela (ex.: `[DEBUG] +R$ 5.000 adicionados`), desaparecendo após 2 segundos via Tween.

---

## 5. Roteiro Sugerido de Apresentação de TCC (Exemplo em 10 Minutos)

1. **Início (0-2 min):** Criar novo jogo, mostrar o mapa principal.
   - Pressionar **`[7]`** para liberar todas as portas e pular o tutorial inicial.
2. **Sistema de Sobrevivência & Mercado (2-4 min):**
   - Entrar no Mercado, explicar o custo-benefício de alimentos x bebidas.
   - Pressionar **`[4]`** para adicionar saldo e comprar a cesta.
   - Ir para a Casa, mostrar consumo de alimentos e recuperação das necessidades.
3. **Escolaridade & Minigame (4-6 min):**
   - Entrar na Escola e mostrar o minigame.
   - Pressionar **`[8]`** para demonstrar o impacto do aumento da escolaridade no salário.
4. **Banco, FIIs e Imprevistos (6-8 min):**
   - Entrar no Banco.
   - Pressionar **`[9]`** para gerar um evento inesperado e demonstrar o pagamento de imprevistos e a importância da reserva de emergência.
   - Comprar cotas de FIIs na aba de investimentos.
5. **Virada de Semana e Empreendimentos (8-10 min):**
   - Pressionar **`[5]`** para completar missões e **`[3]`** para avançar para a Semana 5.
   - Pressionar **`[0]`** para configurar o Restaurante.
   - Entrar no Restaurante e apresentar a tela de gestão empresarial: capacidade, folha de pagamento, estoque e contas semanais.

---

## 6. Procedimento de Remoção Pós-TCC

Quando a apresentação do TCC for concluída e o jogo for para a versão final:
1. Abrir `project.godot`.
2. Remover a linha do autoload `DebugCommands="*res://singletons/DebugCommands.gd"`.
3. Excluir o arquivo `singletons/DebugCommands.gd`.
4. Excluir este arquivo `DEBUG_COMMANDS_PLAN.md`.
Pronto! Nenhuma modificação residual restará no código-fonte do jogo.
