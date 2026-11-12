# Roteiro Completo de Apresentação de Slides – TCC
**Projeto:** Mundo Financeiro: Um Jogo Digital Educativo Sobre Educação Financeira  
**Instituição:** Instituto Federal de Educação, Ciência e Tecnologia de São Paulo (IFSP) – Campus São Paulo  
**Autores:** Enzo Faria de Melo, Matheus Araujo Gregório, Melissa Kimberly da Costa Oliveira, Phillip da Silva Marcelino Bonfim, Raul Ferreira Borges  
**Tempo total estimado:** 15 a 20 minutos (~1 minuto por slide)

---

## Sumário da Divisão de Slides

| Bloco | Slides | Temas Principais | Tempo Sugerido |
| :--- | :---: | :--- | :---: |
| **1. Introdução & Contextualização** | 1 a 4 | Capa, Contextualização, Justificativa com Dados e Objetivos | 4 min |
| **2. Fundamentação Teórica** | 5 e 6 | Educação Financeira, Gamificação, Juros e Capital Humano | 2.5 min |
| **3. Metodologia & O Jogo** | 7 a 11 | Ferramentas, Casos de Uso (UML), Mapa, Mecânicas e as 5 Semanas | 6 min |
| **4. Testes & Resultados** | 12 a 15 | Casos de Teste (CT-01 a 07), Avaliação com 16 Alunos e Gráficos | 4.5 min |
| **5. Conclusão & Encerramento** | 16 e 17 | Considerações Finais, Trabalhos Futuros e Agradecimentos | 2 min |

---

## Sugestão de Divisão de Falas (5 Integrantes)

* **Apresentador 1 (Slides 1 a 4):** Abertura, Contexto socioeconômico dos jovens, Problematização com dados estatísticos e Objetivos do projeto.
* **Apresentador 2 (Slides 5 a 6):** Fundamentação teórica, conceitos de matemática financeira, gamificação e teoria do capital humano.
* **Apresentador 3 (Slides 7 a 9):** Tecnologias utilizadas (Godot, GitHub, Pixilart, etc.), modelagem UML (Casos de Uso) e evolução visual do mapa (baixa vs. alta fidelidade).
* **Apresentador 4 (Slides 10 a 11):** Mecânicas centrais da simulação (necessidades, carteira x banco, contas) e a progressão pedagógica das 5 semanas.
* **Apresentador 5 (Slides 12 a 17):** Metodologia de testes de software, testes com os alunos do IFSP, análise dos gráficos, conclusões e agradecimentos.

---

# Estrutura Detalhada dos Slides

---

### Slide 1: Capa do Projeto
* **Título do Slide:** Mundo Financeiro: Um Jogo Digital Educativo Sobre Educação Financeira
* **Conteúdo no Slide (em tópicos):**
  * Trabalho de Conclusão de Curso (TCC)
  * Instituto Federal de São Paulo (IFSP) – Campus São Paulo
  * **Integrantes:**
    * Enzo Faria de Melo
    * Matheus Araujo Gregório
    * Melissa Kimberly da Costa Oliveira
    * Phillip da Silva Marcelino Bonfim
    * Raul Ferreira Borges
  * **Orientação:** [Nome do Orientador(a) / Coorientador(a)]
* **Elemento Visual Sugerido:** Logotipo oficial do IFSP e a arte em pixel art dos cinco personagens principais do jogo (conforme Apêndice E).
* **Roteiro de Fala (O que falar):**
  > *"Bom dia/boa tarde a todos os membros da banca examinadora, professores, colegas e presentes. Somos alunos do Instituto Federal de São Paulo e hoje apresentamos o nosso Trabalho de Conclusão de Curso intitulado: 'Mundo Financeiro: Um Jogo Digital Educativo Sobre Educação Financeira'."*

---

### Slide 2: Introdução e Contextualização
* **Título do Slide:** Contextualização: O Jovem e o Dinheiro
* **Conteúdo no Slide (em tópicos):**
  * **Fase de transição:** Primeiros contatos com mesadas, estágios e salários formais.
  * **Ambiente moderno de consumo:** Facilidade de acesso a crédito digital e apelo constante ao consumo imediato.
  * **Lacuna formativa:** Jovens ingressam no mercado econômico sem preparação prática prévia.
  * **O papel da escola:** Ambiente natural e necessário para desenvolver autonomia e cidadania financeira.
* **Elemento Visual Sugerido:** Ilustração ou ícone representando o jovem diante de escolhas financeiras e do mercado de consumo.
* **Roteiro de Fala (O que falar):**
  > *"A transição entre a adolescência e a vida adulta é marcada pelo primeiro contato direto com a renda própria. No entanto, o cenário atual oferece facilidade imediata de crédito aliada a estímulos constantes de consumo. Sem uma base sólida de educação financeira no ambiente escolar, esses jovens tomam decisões sem compreender o impacto de médio e longo prazo em suas vidas."*

---

### Slide 3: Problematização e Justificativa
* **Título do Slide:** O Cenário Real do Endividamento Juvenil
* **Conteúdo no Slide (em tópicos):**
  * **50,2%** dos jovens brasileiros de 18 a 24 anos já possuíam restrições no nome/SPC (Sobianek et al., 2021).
  * **Apenas 9,25%** dos estudantes do ensino médio afirmam guardar e investir parte da renda.
  * **27,6%** só guardam dinheiro quando sobra alguma quantia.
  * **Problema:** O ensino tradicional limita-se a fórmulas abstratas e cálculos matemáticos descolados da prática.
  * **Proposta:** Vivenciar a tomada de decisão em um ambiente de simulação sem risco financeiro real.
* **Elemento Visual Sugerido:** Destaque gráfico/infográfico em tamanho grande para os números **50,2%** e **9,25%**, contrastando com a necessidade de poupança.
* **Roteiro de Fala (O que falar):**
  > *"Pesquisas acadêmicas mostram que mais da metade dos jovens já entra na maioridade com restrições de crédito no nome. Além disso, menos de 10% dos estudantes do ensino médio cultivam o hábito de poupar e investir. Isso evidencia que apenas ter acesso ao dinheiro não significa saber administrá-lo. As aulas teóricas de sala de aula raramente ensinam a priorizar contas ou resistir a impulsos; era necessário criar uma ferramenta interativa e segura para essa vivência."*

---

### Slide 4: Objetivos do Trabalho
* **Título do Slide:** Objetivos do Projeto
* **Conteúdo no Slide (em tópicos):**
  * **Objetivo Geral:**
    * Desenvolver um jogo digital educativo em estilo RPG de simulação voltado para jovens de 15 a 18 anos, aproximando conceitos de gestão do dinheiro de situações práticas do cotidiano.
  * **Objetivos Específicos:**
    * Simular decisões financeiras reais: orçamento, pagamento de contas fixas, poupança, investimentos e empreendedorismo.
    * Conectar de forma interativa o nível de escolaridade com a remuneração salarial.
    * Avaliar a jogabilidade, clareza e impacto da experiência por meio de testes com estudantes do Ensino Médio Técnico.
* **Elemento Visual Sugerido:** Três caixas de destaque interligadas (Objetivo Geral no topo; Objetivos Específicos em tópicos com ícones de jogo, educação e pesquisa).
* **Roteiro de Fala (O que falar):**
  > *"Para enfrentar esse problema, o objetivo geral do nosso projeto foi construir o 'Mundo Financeiro', um RPG de simulação para a faixa etária de 15 a 18 anos. Especificamente, buscamos colocar o jogador para gerenciar despesas cotidianas, investir, entender a valorização do estudo sobre o salário e testar o jogo na prática com estudantes do próprio IFSP."*

---

### Slide 5: Fundamentação Teórica – Educação e Matemática Financeira
* **Título do Slide:** Fundamentação Teórica: Finanças e Cidadania
* **Conteúdo no Slide (em tópicos):**
  * **Educação Financeira Integral:** Construção de hábitos conscientes, controle orçamentário e autonomia ao longo da vida (Azevedo et al., 2025; Pontes, 2023).
  * **Conceitos Essenciais de Matemática Financeira:**
    * **Capital, Prazo e Taxa:** Elementos constitutivos da circulação do dinheiro.
    * **Juros Simples vs. Juros Compostos:** O efeito multiplicador do juro sobre juro no tempo (Barbosa, 2025).
    * **Inflação e Ganho Real:** Compreensão de que dinheiro parado perde poder de compra.
* **Elemento Visual Sugerido:** Gráfico comparativo simples demonstrando a curva exponencial dos juros compostos versus juros simples ao longo do tempo.
* **Roteiro de Fala (O que falar):**
  > *"Nossa fundamentação teórica divide-se em pilares fundamentais. A literatura mostra que educação financeira não é apenas fazer contas, mas desenvolver postura cidadã. Na matemática financeira, destacamos o conceito de juros compostos: se o jovem contrai dívidas em atraso, os juros crescem como bola de neve contra ele; mas se investe com disciplina, os mesmos juros trabalham a seu favor."*

---

### Slide 6: Fundamentação Teórica – Gamificação e Capital Humano
* **Título do Slide:** Gamificação Educativa e Teoria do Capital Humano
* **Conteúdo no Slide (em tópicos):**
  * **Jogos Digitais e Gamificação:**
    * Metodologias ativas: aprender fazendo (*learning by doing*) e resolução de problemas (Cosin, 2026; Alves & Branco, 2024).
    * Ambiente de experimentação segura: errar, falir e aprender sem consequências financeiras reais.
  * **Escolaridade e Salário (Capital Humano):**
    * A qualificação educacional como investimento direto no retorno salarial do trabalhador (Neves & Lima, 2019; Ribeiro et al., 2025).
    * Motivação para a continuidade dos estudos.
* **Elemento Visual Sugerido:** Diagrama conectando: *Estudo / Formação $\rightarrow$ Aumento Salarial Permanente $\rightarrow$ Capacidade de Poupança e Investimento*.
* **Roteiro de Fala (O que falar):**
  > *"Os jogos digitais atuam como laboratórios seguros onde o jovem experimenta as consequências de suas escolhas. Se ele gastar tudo em itens supérfluos, o jogo impõe a consequência imediata. Além disso, incorporamos a Teoria do Capital Humano: quanto maior a escolaridade do personagem no minigame escolar, maior se torna o seu salário base no mundo virtual, demonstrando que estudar é o primeiro grande investimento financeiro da vida."*

---

### Slide 7: Materiais e Tecnologias
* **Título do Slide:** Materiais e Ferramentas de Desenvolvimento
* **Conteúdo no Slide (em tópicos):**
  * **Godot Engine 4:** Engine principal (código em GDScript, lógica de nós, interfaces e física 2D).
  * **Pixilart:** Criação de toda a identidade visual, tilesets e animações em pixel art.
  * **Visual Paradigm:** Modelagem técnica do sistema e Diagrama de Casos de Uso (UML).
  * **GitHub:** Controle de versão distribuído, documentação e trabalho em equipe.
  * **Google Forms:** Instrumento de pesquisa de campo e validação empírica com os estudantes.
* **Elemento Visual Sugerido:** Tabela visual com os ícones das 5 ferramentas e seus papéis no projeto (espelhando o Quadro 1 do artigo).
* **Roteiro de Fala (O que falar):**
  > *"Para tornar o jogo realidade, utilizamos ferramentas modernas e acessíveis. A engine escolhida foi a Godot Engine 4, por ser open source, leve e capaz de rodar com excelente desempenho em computadores escolares sem placa de vídeo dedicada. A arte foi desenvolvida em pixel art no Pixilart, a modelagem foi feita no Visual Paradigm e todo o versionamento foi mantido via Git/GitHub."*

---

### Slide 8: Modelagem e Arquitetura do Sistema
* **Título do Slide:** Requisitos e Modelagem de Casos de Uso
* **Conteúdo no Slide (em tópicos):**
  * **Engenharia de Requisitos:**
    * 86 Requisitos Funcionais (RFs) mapeados (rotina, finanças, banco, empreendimentos).
    * 24 Requisitos Não Funcionais (RNFs) (desempenho a 60 FPS, salvamento JSON resiliente, modularidade).
  * **Casos de Uso Principais (UML):**
    * Interação com o personagem e gestão de tempo diário.
    * Participação no minigame escolar de formação.
    * Tomada de decisões financeiras (compras, pagamentos, poupança, fundos e negócios).
* **Elemento Visual Sugerido:** O **Diagrama de Casos de Uso da Figura 1** presente no artigo do TCC.
* **Roteiro de Fala (O que falar):**
  > *"O desenvolvimento seguiu padrões de engenharia de software. Mapeamos requisitos funcionais rigorosos, como o controle de caixa, cobrança de contas com vencimento e o cálculo de juros. Na tela, vemos o Diagrama de Casos de Uso que sintetiza as interações do jogador: desde o controle básico e rotina até o sistema avançado de decisões financeiras e persistência de dados."*

---

### Slide 9: O Jogo "Mundo Financeiro" – Visão Geral e Mapa
* **Título do Slide:** Design do Mundo e Ambientação
* **Conteúdo no Slide (em tópicos):**
  * Perspectiva top-down 2D em pixel art detalhado.
  * **Ciclo Temporal Realista:** Minutos, horas (08h às 24h), dias (1 a 5) e semanas.
  * **Locais Estratégicos da Cidade:**
    * **Residência:** Gestão de fome, sede, descanso e estoque da despensa.
    * **Escola:** Formação continuada e progressão salarial.
    * **Mercado Central:** Compra de suprimentos essenciais e uso de cupons.
    * **Agência Bancária:** Gestão de contas, reserva de emergência, poupança e FIIs.
    * **Parque Municipal:** Minigame de reflexos e quizzes educativos semanais.
    * **Empreendimentos:** Prédios comerciais para aquisição no estágio avançado.
* **Elemento Visual Sugerido:** Comparação lado a lado entre o **Apêndice A (esboço do mapa no papel/baixa fidelidade)** e o **Apêndice B (mapa final em pixel art de alta fidelidade)**.
* **Roteiro de Fala (O que falar):**
  > *"Aqui vemos a evolução do design do jogo. Partimos de um protótipo em papel até o mapa final de alta fidelidade em pixel art. A cidade foi planejada para simular uma rotina urbana completa: o jogador acorda em sua casa, monitora suas necessidades, vai à escola, realiza compras no mercado, gerencia seu banco e tem acesso ao parque e aos prédios comerciais."*

---

### Slide 10: Mecânicas de Sobrevivência e Finanças
* **Título do Slide:** Mecânicas Centrais: Sobrevivência e Gestão de Caixa
* **Conteúdo no Slide (em tópicos):**
  * **Necessidades Biológicas:** Fome, sede e stamina decaem com o tempo; descanso adequado é obrigatório para não sofrer penalidades médicas por exaustão.
  * **Dinheiro Físico vs. Saldo Bancário:**
    * Dinheiro na mão: vulnerabilidade e risco de gastos impulsivos.
    * Saldo no banco: segurança e organização para quitação de compromissos.
  * **Contas Fixas e Imprevistos (Eventos):**
    * Água, luz e aluguel geradas semanalmente.
    * Imprevistos (conserto mecânico, consulta médica ou bônus extras de freelance).
    * Juros punitivos em caso de inadimplência (juros diários compostos sobre o atraso).
* **Elemento Visual Sugerido:** Capturas de tela da interface do jogo (HUD com barras de fome/sede/stamina, tela da despensa da casa e painel de contas pendentes do banco).
* **Roteiro de Fala (O que falar):**
  > *"O jogador precisa manter suas necessidades vitais equilibradas. Se não comer ou passar da meia-noite sem dormir, o personagem desmaia e paga uma conta hospitalar. No banco, mostramos a diferença entre o dinheiro vivo na mão e o saldo na conta corrente. Além disso, as contas possuem data de vencimento: atrasar gera juros diários sobre juros, reforçando na prática a importância de pagar em dia."*

---

### Slide 11: Jornada Pedagógica – A Curva das 5 Semanas
* **Título do Slide:** Progressão Pedagógica em 5 Etapas (Semanas)
* **Conteúdo no Slide (em tópicos):**
  * **Semana 1 – Orçamento e Gastos:** Diferença entre necessidades e desejos, rotina básica e impacto da escola no salário.
  * **Semana 2 – Reserva de Emergência:** Chegada das contas fixas domésticas e resolução de imprevistos financeiros no banco.
  * **Semana 3 – Renda Fixa & Poupança:** Abertura da caderneta de poupança no banco, juros compostos a favor do jogador e liquidez D+0.
  * **Semana 4 – Renda Variável (FIIs):** Desbloqueio da loja de Fundos Imobiliários, volatilidade de cotas, dividendos semanais e diversificação de risco.
  * **Semana 5 – Empreendedorismo:** Compra e operação de negócios próprios (Restaurante, Fliperama e Shopping), gestão de estoque e folha de pagamento.
* **Elemento Visual Sugerido:** Linha do tempo visual ou infográfico horizontal ilustrando a jornada da Semana 1 até a Semana 5, com ícones alusivos a cada etapa.
* **Roteiro de Fala (O que falar):**
  > *"O conteúdo pedagógico segue uma progressão gradual. Na primeira semana, o foco é o controle de gastos básicos. Na segunda, a reserva de emergência para imprevistos. Na terceira, a Renda Fixa e poupança com liquidez imediata. Na quarta, a exposição à Renda Variável com cotas de FIIs e dividendos. E na quinta semana, o jogador atinge o nível de empreendedor, gerenciando funcionários, estoque e fluxo de caixa de seu próprio negócio."*

---

### Slide 12: Metodologia de Testes e Validação
* **Título do Slide:** Metodologia de Testes e Avaliação de Campo
* **Conteúdo no Slide (em tópicos):**
  * **Testes Estruturais e Funcionais (Quadros 5 e 6):**
    * Casos de Teste CT-01 a CT-07 (movimentação, decisões financeiras, juros, bloqueio de saldo, persistência e encerramento).
  * **Validação com Usuários Reais:**
    * Participação de **16 estudantes** do 2º e 3º ano do Ensino Técnico Integrado ao Médio do IFSP.
    * Sessão prática jogando o protótipo funcional em laboratório.
    * Aplicação de questionário pós-teste (Google Forms) composto por questões de múltipla escolha e respostas dissertativas.
* **Elemento Visual Sugerido:** Imagem da tabela resumida dos Casos de Teste (CTs) ao lado de uma foto da aplicação com os estudantes ou print do formulário.
* **Roteiro de Fala (O que falar):**
  > *"Para validar a ferramenta, adotamos duas abordagens: testes de software para garantir que a lógica matemática e os requisitos estivessem perfeitos, e uma avaliação prática de campo com 16 alunos do Ensino Médio Integrado do próprio campus. Eles jogaram as mecânicas e responderam a um questionário detalhado sobre usabilidade e compreensão dos conceitos financeiros."*

---

### Slide 13: Resultados – Jogabilidade e Interface
* **Título do Slide:** Resultados: Avaliação de Usabilidade e Jogabilidade
* **Conteúdo no Slide (em tópicos):**
  * **87,5%** avaliaram os controles e a movimentação como "bons" ou "muito bons" (CT-05).
  * **87,5%** consideraram a interface clara e fácil para acompanhar as informações financeiras.
  * **76,2%** confirmaram a integridade do salvamento e carregamento de partidas (CT-04).
  * **Ponto de Ajuste Identificado:** **68,75%** apontaram que o tempo diário era rápido demais no início, o que orientou ajustes no balanceamento da velocidade do relógio.
* **Elemento Visual Sugerido:** Gráfico de pizza do **Apêndice I (Figura 8)** com os percentuais de avaliação do progresso e velocidade.
* **Roteiro de Fala (O que falar):**
  > *"Em termos de experiência de usuário, os resultados foram bastante positivos: quase 90% dos estudantes elogiaram a facilidade dos controles e a clareza da interface. Mais importante ainda: as críticas dos alunos foram fundamentais para o projeto; identificamos que o relógio corria rápido demais nas primeiras versões, o que nos permitiu balancear o tempo de jogo."*

---

### Slide 14: Resultados – Absorção dos Conceitos Financeiros
* **Título do Slide:** Resultados: Eficácia dos Conceitos Financeiros
* **Conteúdo no Slide (em tópicos):**
  * **93,75%** dos alunos afirmaram compreender com clareza a **diferença entre dinheiro em mãos e saldo bancário**.
  * **87,5%** utilizaram com sucesso os recursos e serviços da agência bancária.
  * **56,25%** conseguiram operar o sistema de investimentos (FIIs e poupança).
  * **Feedback pedagógico:** A distinção física entre carteira e banco evitou que os alunos gastassem impulsivamente nos testes, demonstrando reflexão antes do ato de compra.
* **Elemento Visual Sugerido:** Gráficos da **Figura 2** (Objetivo de Conhecimento) e **Figura 10** (Diferença entre Dinheiro e Disponibilidade Bancária).
* **Roteiro de Fala (O que falar):**
  > *"Quanto ao aprendizado, o destaque absoluto foi a distinção entre dinheiro em mãos e saldo bancário: mais de 93% dos alunos assimilaram essa separação na prática. O banco tornou-se o porto seguro dos estudantes para proteger o dinheiro. Observamos também que cerca de 56% operaram a aba de investimentos, mostrando que recursos mais complexos exigem tutoriais e sinalizações ainda mais evidentes."*

---

### Slide 15: Discussão e Feedback dos Estudantes
* **Título do Slide:** Discussão dos Resultados e Impacto Pedagógico
* **Conteúdo no Slide (em tópicos):**
  * **Engajamento Ativo:** O formato RPG gerou curiosidade e interesse superior ao de aulas teóricas expositivas.
  * **Aprender com o Erro:** A falência temporária no jogo gerou reflexão e busca imediata por estratégias de recuperação (evitando o ciclo de dívidas).
  * **Sinergia Escola-Jogo:** A integração do minigame da escola mostrou aos alunos uma relação direta entre dedicação aos estudos e retorno salarial.
  * **Maturidade Acadêmica:** O trabalho comprova a viabilidade técnica e a experiência positiva, mantendo o rigor de reconhecer que a retenção de longo prazo exige estudos longitudinais.
* **Elemento Visual Sugerido:** Quadro com citações dissertativas anônimas dos estudantes destacando o que mais gostaram no jogo.
* **Roteiro de Fala (O que falar):**
  > *"A discussão dos dados mostra que a gamificação cumpre seu papel: ela engaja e permite que o jovem erre sem destruir suas finanças pessoais reais. Ver o personagem ficar sem comida porque o dinheiro acabou ensina mais do que dezenas de exercícios repetitivos no caderno. Reconhecemos que o teste mediu a experiência imediata, servindo como uma base sólida para futuras pesquisas de longo prazo."*

---

### Slide 16: Considerações Finais e Trabalhos Futuros
* **Título do Slide:** Considerações Finais e Próximos Passos
* **Conteúdo no Slide (em tópicos):**
  * **Conclusão:** O *Mundo Financeiro* cumpriu com sucesso seu objetivo de transformar conceitos abstratos de economia em vivência prática e acessível.
  * **Contribuição:** Ferramenta gratuita, aberta e adaptada à realidade do jovem brasileiro e de escolas públicas.
  * **Trabalhos Futuros:**
    * Expansão do mapa urbano e inclusão de novas profissões.
    * Portabilidade para dispositivos móveis (Android/iOS) para facilitar o uso direto em sala de aula sem laboratório de informática.
    * Realização de testes longitudinais com avaliação antes e depois de semestres letivos.
* **Elemento Visual Sugerido:** Arte final do jogo em alta fidelidade reunindo os elementos da cidade e a mensagem de missão cumprida.
* **Roteiro de Fala (O que falar):**
  > *"Concluímos que o 'Mundo Financeiro' atingiu seu propósito: entregamos um jogo completo, tecnicamente robusto e pedagogicamente estruturado. Como trabalhos futuros, pretendemos disponibilizar uma versão mobile para facilitar a aplicação por professores em salas de aula convencionais e expandir os cenários do jogo."*

---

### Slide 17: Agradecimentos
* **Título do Slide:** Agradecimentos
* **Conteúdo no Slide (em tópicos):**
  * Aos professores e professoras do IFSP: Anderson, Bernardo, Evandro, Claudete e Daniela pelo apoio, cessão de horários de aula e incentivo.
  * Aos alunos das turmas de 2º e 3º ano do Ensino Técnico Integrado ao Médio que participaram dos testes.
  * Aos membros da banca examinadora pelas contribuições ao nosso projeto.
  * **Contatos dos Autores:**
    * `enzo.faria@ifsp.edu.br`
    * `gregorio.matheus@ifsp.edu.br`
    * `costa.melissa@ifsp.edu.br`
    * `b.phillip@ifsp.edu.br`
    * `borges.raul@ifsp.edu.br`
* **Elemento Visual Sugerido:** Logotipo do IFSP, foto da equipe (se houver) e frase em destaque: *"Muito obrigado! Estamos abertos às considerações e perguntas da banca."*
* **Roteiro de Fala (O que falar):**
  > *"Agradecemos imensamente a todos os professores que nos apoiaram, aos alunos do IFSP que participaram dos testes e aos membros da banca pelo tempo e disponibilidade. Ficamos agora à inteira disposição para as perguntas e considerações."*

---

## Dicas Cruciais para o Dia da Apresentação

1. **Equilíbrio Visual nos Slides:**
   * Mantenha fundo claro com texto escuro ou tema escuro uniforme de alto contraste.
   * Evite parágrafos longos: no slide entram apenas tópicos curtos (máximo 4 a 5 linhas por slide). Quem fala o conteúdo completo é você.
2. **Demonstração Prática (Opcional / Coringa):**
   * Deixe o jogo aberto no notebook pronto para jogar. Se a banca perguntar sobre o minigame da escola ou a compra de ações/FIIs, alternar para o jogo e mostrar em 30 segundos causa um impacto muito positivo.
3. **Ensaio de Tempo com Cronômetro:**
   * Façam pelo menos dois ensaios completos com cronômetro rodando. Ajustem a transição entre os integrantes para não perder tempo trocando microfone ou posições.
