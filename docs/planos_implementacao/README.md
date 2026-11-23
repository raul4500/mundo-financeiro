# Planos de Implementação e Melhorias do Mundo Financeiro

Este diretório reúne o planejamento arquitetural e funcional detalhado para as melhorias, correções de bugs e refinamentos pedagógicos solicitados para o jogo **Mundo Financeiro**.

---

## 📋 Sumário dos Planos de Implementação

| # | Arquivo do Plano | Título / Melhoria | Objetivo Principal | Complexidade |
|---|---|---|---|:---:|
| **01** | [`01_confirmacao_enter_alertas.md`](./01_confirmacao_enter_alertas.md) | **Confirmação com Tecla Enter** | Fazer o botão "OK" / "Continuar" responder à tecla Enter (teclado padrão e numérico) além do Espaço. | Baixa |
| **02** | [`02_bug_movimento_continuar_jogo.md`](./02_bug_movimento_continuar_jogo.md) | **Correção: Personagem Imóvel ao Continuar** | Eliminar vazamentos de trava de gameplay no menu de pause e garantir recarga do save e restauração de velocidade. | Média |
| **03** | [`03_revisao_tutorial_minigame_escola.md`](./03_revisao_tutorial_minigame_escola.md) | **Alinhamento do Minigame da Escola** | Corrigir textos contraditórios (que falavam em responder perguntas), alinhando à corrida real de saltar obstáculos com Espaço. | Média |
| **04** | [`04_tutorial_direcionamento_missoes.md`](./04_tutorial_direcionamento_missoes.md) | **Direcionamento Prático para Missões** | Substituir o monólogo introdutório por uma apresentação guiada do painel de missões na primeira semana. | Média |
| **05** | [`05_confirmacao_leitura_consultoria.md`](./05_confirmacao_leitura_consultoria.md) | **Confirmação de Leitura na Consultoria** | Exigir visualização e confirmação de estudo dos tópicos educativos antes de destravar o Banco e o restante da cidade. | Média |
| **06** | [`06_remocao_tracejados_textos.md`](./06_remocao_tracejados_textos.md) | **Remoção de Tracejados (`---`, `—`)** | Substituir travessões e hifens em textos da interface e tutoriais por pontuação polida (dois-pontos, vírgulas, `•`). | Baixa |
| **07** | [`07_otimizacao_textos_onboarding.md`](./07_otimizacao_textos_onboarding.md) | **Enxugamento do Tutorial Geral** | Reduzir a extensão dos textos em 50-60%, tornando as mensagens ágeis, contextuais e focadas na ação imediata. | Média |
| **08** | [`08_caderno_tutorial_guia_ingame.md`](./08_caderno_tutorial_guia_ingame.md) | **Caderno de Dicas & Guia Permanente** | Adicionar um handbook in-game permanente para consulta das mecânicas a qualquer momento (tecla `J`, HUD ou Pause). | Alta |
| **09** | [`09_revisao_visual_e_layout.md`](./09_revisao_visual_e_layout.md) | **Revisão visual e de layout (01 a 08)** | Alinhar os componentes novos ao tema do projeto, padronizar botões e corrigir inconsistências de lógica. | Média |

---

## 🎯 Ordem de Execução Recomendada (Quando Autorizada)

1. **Fase 1: Correções de Usabilidade Imediata & Bugs Críticos**
   - Plano 01 (Enter nos alertas)
   - Plano 02 (Bug de movimento ao continuar)
2. **Fase 2: Polimento Textual e Gramatical**
   - Plano 06 (Remoção de tracejados em todas as strings)
   - Plano 03 (Alinhamento do minigame de obstáculos)
   - Plano 07 (Enxugamento e otimização dos textos do onboarding)
3. **Fase 3: Fluxos Educativos e Progressão Guiada**
   - Plano 04 (Tutorial guiado para a tela de missões)
   - Plano 05 (Validação e confirmação de leitura no escritório)
4. **Fase 4: Nova Feature de Consulta Permanente**
   - Plano 08 (Criação do Caderno de Tutorial / Guia in-game)

---

> **Aviso**: Conforme solicitado, **nenhum plano foi executado no código-fonte por enquanto**. Todos os passos técnicos, arquivos alvo, testes e resultados esperados estão documentados e prontos para implementação sob sua aprovação.
