# Documento Mestre de Auditoria e Rastreabilidade de Software
**Projeto:** Mundo Financeiro: Um Jogo Digital Educativo Sobre Educação Financeira  
**Instituição:** Instituto Federal de Educação, Ciência e Tecnologia de São Paulo (IFSP) – Campus São Paulo  
**Curso:** Ensino Médio Técnico Integrado · Disciplina: Laboratório de Programação 3  
**Documento de Referência Didática:** IntelliC v20 R10 — Revisada 5 (Documento Mestre de Rastreabilidade de Regras)  
**Data da Auditoria:** 11/11/2026  
**Autores do Projeto Original (TCC):** Enzo Faria de Melo, Matheus Araujo Gregório, Melissa Kimberly da Costa Oliveira, Phillip da Silva Marcelino Bonfim, Raul Ferreira Borges  

---

## 1. Identificação do Sistema e da Versão Analisada

* **Nome do Sistema:** Mundo Financeiro (RPG de Simulação Educativa 2D)
* **Repositório:** `github.com/raul4500/mundo-financeiro`
* **Versão de Referência Auditada:** Revisão pós-apresentação consolidada
* **Hash Exato do Commit:** `c29419693769c944e312685a8a67ddbc8407c48d` (Branch: `main`)
* **Data do Commit Base:** 19/10/2026 – 17:00:09 -0300
* **Ambiente de Desenvolvimento & Execução:**
  * Engine: Godot Engine v4.3+ / v4.7.2-stable (Win64)
  * Linguagem: GDScript 2.0 (orientado a nós e sinais reativos)
  * Persistência: Serialização JSON em UTF-8 (`user://savegame.json`)
  * Sistema Operacional Alvo: Windows 10/11 (arquitetura preparada para Linux/macOS)
* **Declaração do Caminho de Investigação Utilizado:**  
  * **Roteiro B — Investigação assistida por Inteligência Artificial (Google Antigravity / Gemini)**.
  * **Declaração de Integridade e Verificação Humana:** Todas as afirmações, linhas de código, nomes de classes/funções e resultados de teste foram inspecionados estaticamente e verificados em execução real no terminal da engine Godot. Nenhum dado sensível, token pessoal ou credencial foi compartilhado. Todos os testes apontados como "Testada" foram executados em modo *headless* no repositório local.

---

## 2. Breve Arquitetura do Software

O *Mundo Financeiro* é estruturado sob o padrão arquitetural **Hierárquico Baseado em Cenas e Nós (Scene-Tree)** com **Singletons Centrais (Autoloads)**, desacoplando a interface visual das regras matemáticas de economia e sobrevivência:

1. **Camada de Apresentação e Interação (UI / Cenas):** Construída com nós de interface (`Control`, `PanelContainer`, `GridContainer`) e nós de mundo 2D (`Node2D`, `TileMap`, `CharacterBody2D`). As telas de estabelecimentos (`banco.gd`, `market.gd`, `home.gd`, `office.gd` e `minigame.gd`) não processam a economia de forma isolada; elas disparam comandos e escutam sinais de resposta.
2. **Camada de Lógica de Negócio e Domínio (Autoloads Globais):** Singletons declarados em `project.godot` com ciclo de vida permanente durante toda a execução da aplicação:
   * `Global.gd`: Centraliza o estado do jogador (`player`), controle de fundos unificados, necessidades biológicas (fome, sede, stamina) e travas de gameplay.
   * `TimeManager.gd`: Máquina de estados temporal (relógio diário de 08h às 24h, virada de dia e processamento da virada semanal).
   * `FIIManager.gd`: Motor de renda variável (precificação de cotas, dividendos, volatilidade e cálculo de preço médio).
   * `EnterpriseManager.gd`: Gestão de microempresas (receita diária, capacidade, estoque, custos operacionais e folha).
   * `HouseBillsManager.gd` & `EventsManager.gd`: Geradores de compromissos financeiros e eventos estocásticos.
   * `DebtRules.gd`: Classe utilitária pura (`RefCounted`) que encapsula as fórmulas financeiras de amortização, juros de mora e teto punitivo.
   * `MissionManager.gd`: Motor de avaliação contínua das metas pedagógicas da semana.
3. **Camada de Persistência e Sistema de Arquivos:** `SaveManager.gd` manipula o arquivo `user://savegame.json`. A integridade dos dados na desserialização é assegurada pelo método de saneamento e migração de esquemas `Global.ensure_player_state()`.
4. **Camada de Testes Automatizados Headless:** Suíte de 20 arquivos de teste unitário e de integração (`tests/test_*.gd`), executados via linha de comando (`--headless`) com assertivas estritas e encerramento limpo via código de saída do sistema (`get_tree().quit(0)` ou `exit(1)`).

---

## 3. Critérios de Classificação de Status (Legenda IntelliC)

Para assegurar rigor técnico de auditoria, os estados atribuídos na Matriz seguem exatamente as definições do documento mestre de referência:
* **Implementada:** O trecho de código ou estrutura de dados existe e foi localizado exatamente no repositório, mas sua verificação depende de validação formal em execução.
* **Teste localizado:** Existe script ou rotina automatizada escrita no repositório cobrindo a regra, porém sem registro de execução nesta rodada.
* **Testada:** A regra foi executada no ambiente de auditoria, com entradas, saídas esperadas e saídas observadas devidamente confirmadas via console/log.
* **Homologada:** Comportamento validado formalmente pela equipe de aceitação e consolidado na entrega final.
* **Pendente:** Regra ausente, parcialmente implementada ou teste falho/não executado.

---

## 4. Matriz de Rastreabilidade de Regras do Sistema

A matriz a seguir reúne **5 Regras Funcionais (REG)** e **4 Regras de Segurança e Integridade (SEG)**, superando a meta mínima de 8 regras exigida na atividade prática.

| ID | Regra / Comportamento Esperado | Rastreabilidade Técnica (Código Real) | Situação | Teste / Evidência Verificável |
| :--- | :--- | :--- | :---: | :--- |
| **SEG-001** | **Integridade de Saldo e Prevenção de Débito Negativo:** Nenhuma operação de compra, taxa ou penalidade pode reduzir os fundos totais do jogador abaixo de R$ 0,00. Caso os fundos combinados (`money` + `saldo` + `poupanca`) sejam insuficientes, a transação deve ser abortada atomicamente sem debitar centavos parciais. | `singletons/Global.gd`<br>Função `charge_funds(amount: float) -> bool`<br>(linhas 424–447) | **Testada** | `tests/test_poupanca.gd` (Cenário 3: cobrança de R$ 60 em saldo de R$ 50 retorna `false` e mantém saldo inalterado em R$ 50). Verificado com exit code 0. |
| **SEG-002** | **Integridade de Persistência e Tratamento de Save Corrompido:** A leitura do arquivo de progresso (`user://savegame.json`) deve validar o formato JSON; dados nulos, corrompidos ou não-dicionários não podem causar crash do motor nem corromper a memória volátil, acionando fallback para novo estado padrão (`ensure_player_state`). | `singletons/SaveManager.gd`<br>`load_game()` (linhas 43–61);<br>`singletons/Global.gd`<br>`ensure_player_state()` (linhas 210–272) | **Testada** | `tests/test_debts_and_week_restore.gd` (linhas 130–134: save sem snapshot restaurado com integridade) e `tests/test_fii_shop.gd` (linhas 46–54). |
| **SEG-003** | **Anti-Exploit de Morte e Exclusão Irreversível de Save no Game Over:** Ao ocorrer a morte definitiva do personagem por necessidades críticas esgotadas, o arquivo de save local deve ser imediatamente destruído do disco e novas tentativas de autosave bloqueadas, impedindo trapaça de reload. | `singletons/Global.gd`<br>`trigger_game_over()` (linhas 780–798);<br>`singletons/SaveManager.gd`<br>`save_game()` (linhas 30–31) | **Testada** | `tests/test_game_over_save_deletion.gd` (Cenários 1 a 5: confirma `SaveManager.has_save() == false` e desativação do botão "Continuar" no Menu). |
| **SEG-004** | **Controle Lógico de Permissão de Acesso aos Estabelecimentos (Tutorial Lock):** Durante o onboarding inicial, o acesso físico às portas dos prédios (Escritório, Banco, Mercado, Empreendimentos) é barrado na camada lógica do sistema (`is_place_unlocked`), impedindo entrada indevida mesmo se a interface ou colisão for contornada. | `singletons/Global.gd`<br>`is_place_unlocked(place_id: String) -> bool`<br>(linhas 189–201);<br>`PLACE_UNLOCK_STAGE` (linhas 34–37) | **Testada** | `tests/test_tutorial_time_pause.gd` e `tests/test_mechanics.gd` (linhas 282–286: validação de bloqueio progressivo das fases e avisos). |
| **REG-001** | **Progressão Salarial Baseada na Teoria do Capital Humano:** Cada nível de escolaridade concluído na Escola (1 a 5) recalcula o salário semanal de forma permanente e cumulativa através da fórmula: `salario = 200.0 * (1.0 + (school_level - 1) * 0.5)`. | `singletons/Global.gd`<br>`update_salary()` (linhas 389–391);<br>`scripts/minigame/minigame.gd` (linhas 205–218) | **Testada** | `tests/test_school_minigame_spawn.gd` (Cenário 5: aprovação do nível 4 eleva salário de R$ 200 para exatamente R$ 500,00). |
| **REG-002** | **Rendimento de Renda Fixa e Capitalização de Juros Compostos Diários:** O saldo alocado na Poupança bancária rende juros diários à taxa de 0,5% (`DAILY_POUPANCA_RATE := 0.005`) a cada noite dormida (`_close_day`), aplicando o regime de juros compostos sobre o montante acumulado com liquidez imediata (D+0). | `singletons/TimeManager.gd`<br>`_close_day()` (linhas 255–262);<br>`singletons/Global.gd`<br>`apply_poupanca()` e `withdraw_poupanca()` | **Testada** | `tests/test_poupanca.gd` (Cenário 4: saldo de R$ 200 rende R$ 1,00 no dia 1 e juros compostos rendem R$ 1,01 no dia 2, totalizando R$ 202,01). |
| **REG-003** | **Mitigação de Softlock em Dívidas Atrasadas (Teto Limitador de Juros):** Contas domésticas e imprevistos não quitados até a data de vencimento sofrem acréscimo diário de 10% de juros compostos, porém limitados por um teto absoluto de 1,75x (175%) do valor original (`MAX_INTEREST_MULTIPLIER := 1.75`). | `scripts/economy/debt_rules.gd`<br>`amount_with_interest()` (linhas 27–29);<br>`singletons/HouseBillsManager.gd`<br>`current_amount()` | **Testada** | `tests/test_debts_and_week_restore.gd` (Cenário 1: validação de juros compostos dia a dia e aplicação estrita do teto multiplicador de 1,75x). |
| **REG-004** | **Auditoria de Fechamento Semanal com Snapshot Anti-Exploração:** A virada de semana exige a aprovação de todas as missões semanais e liquidez para dívidas com data limite. Em caso de reprovação, a semana é reiniciada restaurando o dinheiro e estoque ao snapshot inicial (`restore_week_start`), concedendo o salário pelos 5 dias trabalhados. | `singletons/TimeManager.gd`<br>`_process_week_rollover()` (linhas 291–322);<br>`singletons/Global.gd`<br>`snapshot_week_start()` e `restore_week_start()` | **Testada** | `tests/test_debts_and_week_restore.gd` (Cenário 7: contas pagas e saldo revertidos à foto inicial da semana; salário adicionado ao caixa do trabalhador). |
| **REG-005** | **Educação Contra o Efeito Manada e Tributação de Venda com Prejuízo:** Vender cotas de FII com valor de mercado abaixo do preço médio de aquisição acarreta a retenção obrigatória de 10% de imposto sobre o prejuízo apurado, registrando a despesa educativa no histórico financeiro. | `singletons/FIIManager.gd`<br>`sell_fund()` (linhas 159–192);<br>`const LOSS_TAX_RATE := 0.10` (linha 100) | **Testada** | `tests/test_mechanics.gd` (Cenário de FII: venda de 20 cotas com custo médio 75 por 50 acarreta R$ 500 de prejuízo e R$ 50 de imposto retido). |

---

## 5. Fichas Detalhadas de Teste de Software

Seguindo o padrão formal da Seção 11.1 da apostila didática, apresentamos duas fichas completas executadas no ambiente do projeto.

### Ficha de Teste 01 (FT-01) — Regra de Segurança
* **ID do Teste e Regra Vinculada:** `FT-01` $\rightarrow$ Vinculado a **`SEG-001`** (Prevenção de Saldo Negativo e Débito em Cascata).
* **Ambiente / Versão:** Godot Engine v4.7.2-stable (Win64) em modo headless (`--headless`), Commit `c29419693769c944e312685a8a67ddbc8407c48d`.
* **Pré-condição:** Jogador inicializado em memória com carteira de R$ 50,00, saldo bancário em conta corrente de R$ 100,00 e poupança de R$ 100,00 (Fundos Totais = R$ 250,00).
* **Passos e Entrada:**
  1. Instanciar o estado fresco do jogador através de `Global._new_player_data()`.
  2. Executar `Global.charge_funds(200.0)`.
  3. Verificar saldos parciais em `player["money"]`, `player["saldo"]` e `player["poupanca"]`.
  4. Executar tentativa abusiva de débito excedente: `Global.charge_funds(60.0)` (quando restam apenas R$ 50,00 na poupança).
* **Resultado Esperado:**
  * O primeiro débito de R$ 200,00 deve ser aceito: carteira zera (R$ 0,00), conta corrente zera (R$ 0,00) e poupança absorve os R$ 50,00 restantes (saldo final da poupança = R$ 50,00).
  * A segunda chamada (`charge_funds(60.0)`) deve retornar `false` e não alterar nenhum centavo do jogador.
* **Resultado Observado:** A função debitou ordenadamente a carteira, depois o banco e a poupança. A tentativa de sobrecarga de R$ 60,00 retornou estritamente `false` e manteve a poupança em exatamente R$ 50,00.
* **Evidência Registrada:** Script `tests/test_poupanca.gd` (linhas 57–73). Execução do comando:
  `Godot_v4.7.2-stable_win64_console.exe --headless --path . "res://tests/test_poupanca.tscn"` $\rightarrow$ Saída: `ok charge_funds() consome carteira -> saldo -> poupança sem falhar`. Código de saída: `0`.
* **Conclusão:** **Aprovado (Testada com Sucesso)**.

---

### Ficha de Teste 02 (FT-02) — Regra Funcional / Negócio
* **ID do Teste e Regra Vinculada:** `FT-02` $\rightarrow$ Vinculado a **`REG-002`** (Cálculo de Juros Compostos Diários na Poupança).
* **Ambiente / Versão:** Godot Engine v4.7.2-stable (Win64) em modo headless (`--headless`), Commit `c29419693769c944e312685a8a67ddbc8407c48d`.
* **Pré-condição:** Jogador na Semana 3 com escolaridade nível 2, saldo em conta corrente de R$ 200,00 e poupança zerada.
* **Passos e Entrada:**
  1. Transferir R$ 200,00 da conta corrente para a poupança via `Global.apply_poupanca(200.0)`.
  2. Simular encerramento do primeiro dia chamando `TimeManager._close_day(100.0)`.
  3. Checar saldo da poupança e indicador de rendimento acumulado.
  4. Simular encerramento do segundo dia chamando `TimeManager._close_day(100.0)`.
  5. Checar se o segundo rendimento calculou sobre R$ 201,00 e não sobre R$ 200,00.
* **Resultado Esperado:**
  * No dia 1: Rendimento de $200 \times 0{,}005 = \text{R\$\ } 1{,}00$. Saldo passa para R$ 201,00.
  * No dia 2: Rendimento de $201 \times 0{,}005 = 1{,}005 \approx \text{R\$\ } 1{,}01$. Saldo passa para R$ 202,01.
  * Rendimento acumulado total registrado deve ser exatamente R$ 2,01.
* **Resultado Observado:** Saldo da poupança e rendimento total atingiram com exatidão R$ 201,00 no dia 1 e R$ 202,01 no dia 2, comprovando o cálculo de juros sobre juros diários sem truncamento prematuro.
* **Evidência Registrada:** Script `tests/test_poupanca.gd` (linhas 75–90). Execução do comando via CLI Godot $\rightarrow$ Saída: `ok Rendimento diário com juros compostos funciona conforme previsto`. Código de saída: `0`.
* **Conclusão:** **Aprovado (Testada com Sucesso)**.

---

## 6. Matriz de Análise de Impacto de Mudanças Hipotéticas

A tabela abaixo analisa duas alterações conceituais solicitadas para uma versão futura do jogo, mapeando regras impactadas, arquivos que precisariam ser modificados e testes de regressão indispensáveis.

| Mudança Proposta | Regras Possivelmente Afetadas | Arquivos / Componentes Afetados | Testes de Regressão a Repetir / Criar |
| :--- | :--- | :--- | :--- |
| **Mudança 1: Introdução de Cartão de Crédito com Fatura Rotativa e Limite Bancário Pré-Aprovado**<br>*(Permitir que compras no mercado e pagamentos usem limite de crédito quando a carteira e o banco estiverem zerados, gerando fatura com juros rotativos no fim do mês).* | • **SEG-001** (integridade de fundos e bloqueio de saldo negativo)<br>• **REG-003** (cálculo de juros e prazo limite)<br>• **REG-004** (avaliação de liquidez mínima na virada semanal)<br>• **RF012 / RF034** (fluxo de quitação bancária) | • `singletons/Global.gd` (novos campos `credit_limit`, `credit_used` no `data_model` e refatoração de `charge_funds`)<br>• `singletons/TimeManager.gd` (`_process_week_rollover` para cobrar a fatura)<br>• `scripts/economy/debt_rules.gd` (fórmula de juros rotativos)<br>• `scenes/world/places/bank.tscn` e `banco.gd` (nova aba "Cartão de Crédito") | 1. `tests/test_poupanca.gd` (garantir que `charge_funds` não quebre a cascata existente).<br>2. `tests/test_debts_and_week_restore.gd` (verificar se a fatura não perdoa saldo na repetição de semana).<br>3. **Criar** `tests/test_credit_card.gd` (testar limite excedido, fatura rotativa e bloqueio por inadimplência). |
| **Mudança 2: Migração do Armazenamento de Save Local (JSON) para Backend Remoto em Nuvem com Autenticação de Alunos**<br>*(Substituir o arquivo local `user://savegame.json` por requisições autenticadas REST/HTTPS para salvar o progresso dos alunos no laboratório escolar).* | • **SEG-002** (validação e resiliência de save)<br>• **SEG-003** (exclusão no Game Over)<br>• **RNF002 / RNF003** (isolamento entre alunos e tolerância a falhas de rede)<br>• **RF023 / RF074** (salvamento de partidas) | • `singletons/SaveManager.gd` (substituição de `FileAccess` local por chamadas assíncronas `HTTPRequest`)<br>• `scenes/menus/main_menu.tscn` e `main_menu.gd` (campos de login, token JWT e seleção de perfil remoto)<br>• Criação de novo singleton `NetworkClient.gd`<br>• `singletons/Global.gd` (tratamento de desconexão durante o jogo) | 1. `tests/test_game_over_save_deletion.gd` (garantir que requisição de exclusão de save na morte seja síncrona/confiável).<br>2. **Criar** `tests/test_network_resilience.gd` (simular queda de Wi-Fi no meio da partida com cache local seguro).<br>3. Teste de injeção de tokens inválidos e expiração de sessão. |

---

## 7. Análise de Riscos Reais e Recomendações Técnicas

Com base na inspeção aprofundada do código-fonte, identificamos dois riscos concretos para o ciclo de vida do software:

### Risco 1: Manipulação Trivial de Estado Client-Side (Arquivo de Save sem Criptografia ou Assinatura HMAC)
* **Contexto Técnico:** O arquivo de salvamento do jogo é gravado em texto puro em `user://savegame.json` através de `FileAccess.open()` e `JSON.stringify()` (`SaveManager.gd`, linhas 35–40).
* **Vulnerabilidade:** Qualquer estudante com noções básicas de informática pode abrir a pasta `%APPDATA%\Godot\app_userdata\mundo-financeiro` no Windows, abrir o `savegame.json` no Bloco de Notas e alterar `"money": 999999.0` ou `"school_level": 5`. Isso destrói o valor pedagógico do jogo e invalida coletas empíricas de pesquisa educacional.
* **Recomendação Prática:** Substituir `FileAccess.open()` por `FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, KEY_SECRETA)` nativo da Godot Engine, ou gerar uma chave hash SHA-256 de integridade com salt armazenada junto ao arquivo para rejeitar saves alterados manualmente.

### Risco 2: Acoplamento Frágil por Dicionário Mutável sem Tipagem Estrita (`Global.player: Dictionary`)
* **Contexto Técnico:** Todo o modelo de dados do personagem é mantido em um único dicionário dinâmico (`Global.player: Dictionary`). Funções em mais de 12 arquivos diferentes acessam chaves diretamente por string (`Global.player["saldo"]`, `Global.player["money"]`, `Global.player["hunger"]`).
* **Vulnerabilidade:** Se um novo desenvolvedor introduzir uma alteração ou digitar uma chave com erro tipográfico (por exemplo, `Global.player["mony"] = 100` ou atribuir uma string a um campo float), o GDScript não emitirá erro de compilação em tempo de design. O erro ocorrerá silenciosamente em tempo de execução durante uma virada de dia ou fechamento bancário, provocando comportamento imprevisível ou softlocks difíceis de rastrear.
* **Recomendação Prática:** Refatorar o estado global de um `Dictionary` genérico para uma classe fortemente tipada (`PlayerState extends Resource` ou `RefCounted`), com propriedades exportadas tipadas (`var money: float`, `var saldo: float`), métodos `set/get` encapsulados e sinais de mutação (`signal balance_changed(new_balance)`).

---

## 8. Conclusão sobre Manutenibilidade por Outra Equipe

Caso uma nova equipe técnica de desenvolvedores assuma o repositório do *Mundo Financeiro* hoje, a situação de manutenção é caracterizada por:

### O que a nova equipe conseguirá manter com total segurança:
1. **Regras Econômicas e de Simulação Financeira:** O cálculo de juros (`DebtRules.gd`), a gestão de fundos da poupança e FIIs (`FIIManager.gd`), as regras de vencimento de contas (`HouseBillsManager.gd`) e a cascata atômica de cobrança (`Global.charge_funds`) estão isoladas em scripts dedicados com testes unitários automatizados. Qualquer alteração nessas regras que quebre a matemática original é imediatamente detectada pela suíte de 20 testes no terminal.
2. **Ciclo de Sobrevivência e Necessidades:** A curva de decaimento de fome, sede e stamina em função dos minutos do jogo em `TimeManager.gd` possui testes determinísticos de caixa-preta (`test_mechanics.gd`), impedindo que balanceamentos futuros causem morte súbita involuntária do jogador.
3. **Persistência de Dados Básica:** O mecanismo de saneamento `Global.ensure_player_state()` garante que novos campos adicionados ao modelo padrão sejam automaticamente injetados em saves legados sem corromper o progresso anterior.

### O que exigirá cautela e revisão crítica:
1. **A Ordem das Operações na Virada de Semana (`TimeManager._process_week_rollover`):** A sequência em que os dividendos são creditados, as missões avaliadas, as contas vencidas cobradas e o snapshot restaurado possui acoplamento temporal sutil. Alterar a ordem dessas chamadas sem reexecutar `test_debts_and_week_restore.tscn` pode reintroduzir softlocks de pobreza onde o jogador não consegue progredir.
2. **Gerenciamento de Bloqueios de Interface (`gameplay_locked` e `play_time`):** O controle de pausa do relógio e trava de movimentação do jogador envolve múltiplos atores (`AlertManager`, diálogos de tutorial, cutscenes de câmera e minigames). A nova equipe deve sempre utilizar os métodos pareados `Global.lock_gameplay()` e `Global.unlock_gameplay()`, evitando atribuir variáveis booleanas de forma direta.

---

## 9. Registro de Verificação do Checklist de Entrega

* [x] **Regras formuladas de modo específico e testável:** Todas as regras possuem condições de entrada, cálculo explícito e comportamento esperado observável.
* [x] **IDs únicos com 5 funcionais e 3 de segurança:** O documento contém 5 regras funcionais (`REG-001` a `REG-005`) e 4 de segurança (`SEG-001` a `SEG-004`), totalizando 9 regras com IDs padronizados.
* [x] **Identificação da versão exata do TCC:** Registrado o hash completo do commit (`c2941969...`), branch (`main`) e data da análise.
* [x] **Localização técnica existente no código:** Arquivos, linhas e identificadores de função conferidos diretamente nos scripts do projeto.
* [x] **Status atribuído com rigor:** Distinção estrita entre *Implementada* e *Testada* com base em execuções reais no Godot.
* [x] **Evidências reproduzíveis:** Todas as evidências referenciam scripts de teste reais na pasta `tests/` com códigos de saída `0`.
* [x] **Duas fichas de teste e duas análises de mudança:** Fichas `FT-01` e `FT-02` completas na seção 5; Matriz de Impacto detalhada na seção 6.
* [x] **Riscos reais e recomendações aplicáveis:** Identificados os riscos do save JSON aberto e da tipagem dinâmica do dicionário `player`.
* [x] **Uso consciente de IA declarado:** Declarado o uso do Roteiro B com verificação humana de 100% dos trechos citados e preservação de dados sensíveis.
