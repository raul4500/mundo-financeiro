# Plano de desenvolvimento — Sistema de múltiplos saves (5 slots)

## 1. Objetivo

Substituir o save único por um sistema de **até 5 saves independentes**, com:

- criar um novo jogo **sem apagar** os saves existentes;
- tela dedicada para **escolher** qual save jogar;
- **exclusão** de saves a qualquer momento (com confirmação);
- bloqueio de criação de novo jogo quando já existirem 5 saves;
- botão `Continuar` do menu principal vira `Jogar`, levando à tela de seleção.

---

## 2. Situação atual (o que precisa mudar)

| Onde | Comportamento hoje | Problema |
|---|---|---|
| [SaveManager.gd:36](singletons/SaveManager.gd:36) | Grava sempre em `user://savegame.json` | Arquivo único, sem slots |
| [SaveManager.gd:63](singletons/SaveManager.gd:63) | `delete_save(caminho)` recebe nome de arquivo | API frágil, baseada em string solta |
| [Global.gd:97](singletons/Global.gd:97) | `new_game()` chama `SaveManager.delete_save()` | **Apaga o save anterior** — é exatamente o que queremos eliminar |
| [Global.gd:294](singletons/Global.gd:294) | `_ready()` chama `load_data()` no boot | Carrega um save automaticamente antes de qualquer escolha do jogador |
| [main_menu.gd:6](scripts/menus/main_menu.gd:6) | `Continuar` visível se `Global.player["name"] != ""` | Depende do save já carregado no boot |
| [choose_character.gd:12](scripts/menus/choose_character.gd:12) | `Global.new_game(name, k*200)` | Sem verificação de limite de slots |
| [MissionManager.gd:164](singletons/MissionManager.gd:164) | `_game_over()` chama `Global.new_game()` | Consumiria um slot novo a cada game over |
| [FIIManager.gd:46-48](singletons/FIIManager.gd:46) | `portfolio`/`total_invested` vivem no autoload | Não são resetados em `new_game()` → **carteira vaza entre partidas** |

> O último item é um bug já existente: iniciar um novo jogo na mesma sessão mantém a carteira de FIIs da partida anterior. O plano corrige isso junto.

---

## 3. Decisões de design

1. **Slots fixos de 1 a 5.** Cada slot é um arquivo próprio em `user://saves/save_<id>.json`. Slot vazio = arquivo inexistente. Ao excluir o slot 2, o próximo novo jogo reaproveita o slot 2 (menor id livre).
2. **Sem arquivo de índice.** Os metadados exibidos na lista (nome, semana, dinheiro, data) são lidos do próprio save. Um índice separado seria uma segunda fonte de verdade que pode dessincronizar.
3. **`SaveManager` é o único dono do disco.** Nenhum outro script monta caminho de arquivo. `Global` pede ao `SaveManager`; a UI pergunta ao `SaveManager`.
4. **Slot ativo explícito.** `SaveManager.current_slot: int` (0 = nenhum). Salvar sem slot ativo é no-op registrado no log, nunca um crash.
5. **Nada é carregado no boot.** `Global._ready()` apenas garante um `player` válido em memória. O save só entra quando o jogador escolhe um slot. Isso separa "estado de menu" de "estado de partida".
6. **Compatibilidade retroativa.** Um `user://savegame.json` legado é migrado automaticamente para o slot 1 na primeira execução.
7. **Falha suave.** Save corrompido não quebra a tela: o slot aparece como `Save corrompido` e só permite excluir.

---

## 4. Formato de dados

### 4.1 Estrutura em disco

```
user://
└── saves/
    ├── save_1.json
    ├── save_2.json
    └── save_5.json      # slots 3 e 4 vazios
```

### 4.2 Conteúdo do arquivo

O payload atual (`Global.player` serializado) passa a ficar dentro de `player`, com um bloco `meta` irmão. Isso permite ler os metadados da lista sem depender do formato interno do jogador.

```json
{
  "meta": {
    "slot": 1,
    "version": 1,
    "created_at": "2026-08-19T14:32:10",
    "updated_at": "2026-08-19T15:07:44"
  },
  "player": { "name": "Raul", "money": 340.0, "week": 3, "...": "..." }
}
```

- `version` permite migrações futuras sem adivinhação.
- `created_at` é definido uma vez, no novo jogo; `updated_at` é reescrito a cada save.
- Ao ler um arquivo **sem** a chave `meta` (formato antigo), tratar o JSON inteiro como `player` e sintetizar o `meta`.

### 4.3 Resumo exibido na UI (`SaveSlotInfo`)

Dicionário retornado por `SaveManager.list_slots()`, um por slot de 1 a 5:

```gdscript
{
  "slot": 1,
  "is_empty": false,
  "is_corrupted": false,
  "name": "Raul",
  "week": 3,
  "money": 340.0,
  "school_level": 2,
  "updated_at": "2026-08-19T15:07:44"
}
```

---

## 5. Etapas de implementação

As fases são sequenciais: cada uma deixa o jogo em estado executável.

### Fase 1 — `SaveManager` multi-slot

Arquivo: `singletons/SaveManager.gd`

**Constantes e estado**

```gdscript
const SAVE_DIR := "user://saves"
const SAVE_FORMAT := "user://saves/save_%d.json"
const LEGACY_SAVE_PATH := "user://savegame.json"
const MAX_SLOTS := 5
const SAVE_VERSION := 1

var current_slot: int = 0   # 0 = nenhuma partida carregada
```

**API pública** (toda validação de slot fica aqui, não nos chamadores)

```gdscript
func list_slots() -> Array               # sempre MAX_SLOTS itens, na ordem 1..5
func slot_exists(slot: int) -> bool
func has_free_slot() -> bool
func get_free_slot() -> int              # menor id livre, ou 0 se lotado
func save_to_slot(slot: int) -> bool
func load_slot(slot: int) -> Dictionary  # {} se vazio/corrompido
func delete_slot(slot: int) -> bool
func save_game() -> bool                 # wrapper: save_to_slot(current_slot)
```

**Helpers privados**

```gdscript
func _slot_path(slot: int) -> String
func _is_valid_slot(slot: int) -> bool   # 1 <= slot <= MAX_SLOTS
func _ensure_save_dir() -> void          # DirAccess.make_dir_recursive_absolute(SAVE_DIR)
func _read_slot_file(slot: int) -> Dictionary   # {} em qualquer falha
func _migrate_legacy_save() -> void
```

**Regras**

- `_ensure_save_dir()` e `_migrate_legacy_save()` rodam em `_ready()`, nessa ordem.
- `_migrate_legacy_save()`: se `LEGACY_SAVE_PATH` existe e o slot 1 está livre, move o conteúdo para o slot 1 e remove o arquivo antigo. Se o slot 1 já existir, apenas registra um aviso e não apaga nada.
- `save_to_slot()` chama `FIIManager.save_data()` antes de serializar (como hoje) e preserva o `created_at` já existente no arquivo.
- `delete_slot()` zera `current_slot` se o slot excluído for o ativo.
- `save_game()` com `current_slot == 0` retorna `false` e loga aviso — sem crash, sem gravar lixo.
- **Remover** `delete_save(caminho)`; nenhum chamador deve montar caminho de arquivo.

**Autosave** (`_process`)

```gdscript
if current_slot == 0:
    return          # em menus não existe partida para salvar
```

---

### Fase 2 — `Global` desacoplado do boot

Arquivo: `singletons/Global.gd`

**`_ready()`** — deixa de carregar save automaticamente:

```gdscript
func _ready() -> void:
    ensure_player_state()     # player válido e vazio para os menus
```

**Novo `start_new_game(name, money) -> bool`** (substitui o corpo de `new_game`):

1. `var slot = SaveManager.get_free_slot()`; se `0`, loga e retorna `false` (a UI mostra a mensagem).
2. Monta o `player` do zero (mesmo bloco de campos que existe hoje em `new_game`).
3. `FIIManager.reset()` — **corrige o vazamento de carteira entre partidas**.
4. `SaveManager.current_slot = slot` e `SaveManager.save_to_slot(slot)` (grava imediatamente, para o slot já aparecer ocupado).
5. `TimeManager.update_time()`.
6. `change_scene_to_file("res://scenes/world/main_game.tscn")`.
7. Retorna `true`.

**Novo `load_game_from_slot(slot) -> bool`**:

1. `var data = SaveManager.load_slot(slot)`; se vazio, retorna `false`.
2. `player = data`; `ensure_player_state()`.
3. `SaveManager.current_slot = slot`.
4. `FIIManager.load_data()`.
5. `TimeManager.update_time()`.
6. `change_scene_to_file("res://scenes/world/main_game.tscn")`.
7. Retorna `true`.

**Novo `reset_current_game() -> void`** (para o game over): reconstrói o `player` no **mesmo** slot, mantendo `name`, e regrava — nunca consome um slot novo.

**Remover** `load_data()` e o `new_game()` antigo, atualizando os chamadores.

---

### Fase 3 — `FIIManager.reset()`

Arquivo: `singletons/FIIManager.gd`

```gdscript
func reset() -> void:
    portfolio.clear()
    total_invested = 0.0
    total_dividends_received = 0.0
    funds = _default_funds()          # extrair o dicionário inicial para uma função
    emit_signal("portfolio_updated")
    emit_signal("funds_updated")
```

Extrair o literal de `funds` para `_default_funds()` é necessário porque `load_data()` sobrescreve `funds` com os preços salvos — sem isso, um novo jogo herdaria os preços da partida anterior.

---

### Fase 4 — Cena de seleção de save

Arquivos novos: `scenes/menus/save_select.tscn`, `scripts/menus/save_select.gd`

**Árvore de nós**

```
SaveSelect (Control, full rect)          → save_select.gd
├── TextureRect                          (mesmo fundo do menu principal)
├── Title (Label)                        "Escolha um save"
├── SlotList (VBoxContainer, centralizado)
│   └── [5 linhas construídas em runtime]
├── BackButton (Button)                  "Voltar"
└── ConfirmDialog (ConfirmationDialog)    confirmação de exclusão
```

Temas: `res://themes/font_theme.tres` nos botões, `res://themes/label.tres` nos textos — coerente com o resto do projeto.

**Linha de slot** (construída por `_build_slot_row(info)`):

| Estado | Texto | Botões |
|---|---|---|
| Ocupado | `1 — Raul · Semana 3 · R$ 340 · Nível 2` | `Jogar`, `Excluir` |
| Vazio | `2 — Vazio` | `Novo jogo` |
| Corrompido | `3 — Save corrompido` | `Excluir` |

**Fluxo do script**

```gdscript
func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    _refresh_slots()

func _refresh_slots() -> void:
    # limpa SlotList e reconstrói a partir de SaveManager.list_slots()

func _on_play_pressed(slot: int) -> void:
    if not Global.load_game_from_slot(slot):
        _show_error("Não foi possível carregar este save.")

func _on_new_game_pressed(_slot: int) -> void:
    get_tree().change_scene_to_file("res://scenes/menus/choose_character.tscn")

func _on_delete_pressed(slot: int) -> void:
    # guarda o slot pendente e abre o ConfirmDialog

func _on_delete_confirmed() -> void:
    SaveManager.delete_slot(_pending_delete_slot)
    _refresh_slots()

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
```

**Regras de UI**

- `_refresh_slots()` é a única função que desenha a lista; toda ação termina chamando ela. Sem atualização parcial de estado na tela.
- Excluir **sempre** passa pelo `ConfirmationDialog` — perda de save é irreversível.
- Botão `Novo jogo` aparece só nas linhas vazias, o que já comunica visualmente o limite de 5.

---

### Fase 5 — Menu principal

Arquivos: `scenes/menus/main_menu.tscn`, `scripts/menus/main_menu.gd`

- Renomear o botão `GridContainer/start`: texto `Continuar` → **`Jogar`**, e deixá-lo **sempre visível** (remover `visible = false` da cena).
- `_on_start_pressed()` passa a navegar para `res://scenes/menus/save_select.tscn`.
- `_ready()` deixa de depender de `Global.player["name"]`. Em vez disso:

```gdscript
func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    new_game_button.disabled = not SaveManager.has_free_slot()
```

- `_on_novo_jogo_pressed()` só navega para `choose_character` se houver slot livre; caso contrário, mostra a mensagem *"Você já tem 5 saves. Exclua um para começar um novo jogo."* (via `AlertManager.alert()`, reaproveitando o alerta que já existe).

> Manter o botão desabilitado **e** a checagem no handler: o estado visual comunica, a checagem garante.

---

### Fase 6 — Seleção de personagem e game over

`scripts/menus/choose_character.gd`

```gdscript
func select_character(name: String, k: float) -> void:
    if not Global.start_new_game(name, k * 200):
        AlertManager.alert("Você já tem 5 saves. Exclua um para começar um novo jogo.")
```

Adicionar também a checagem em `_ready()` — se o jogador chegou nessa tela sem slot livre (navegação inesperada), volta ao menu com o aviso.

`singletons/MissionManager.gd` — `_game_over()`:

```gdscript
func _game_over():
    _log_warning("Game Over acionado")
    Global.reset_current_game()
```

Assim o game over reinicia a partida **no mesmo slot**, em vez de consumir um slot novo a cada derrota.

---

## 6. Casos de borda a tratar

| Caso | Comportamento esperado |
|---|---|
| Pasta `user://saves` não existe | Criada em `SaveManager._ready()` |
| `savegame.json` legado presente | Migrado para o slot 1; slot 1 ocupado → só loga aviso, não apaga |
| JSON inválido / truncado | Slot listado como corrompido, apenas `Excluir` disponível |
| JSON válido mas não é `Dictionary` | Tratado como corrompido |
| Save sem bloco `meta` | Lido como formato antigo; `meta` sintetizado na próxima gravação |
| Excluir o slot atualmente em jogo | Permitido apenas fora da partida (a tela só é acessível pelo menu); `current_slot` volta a 0 |
| 5 slots ocupados | `Novo Jogo` desabilitado no menu e ausente na tela de seleção |
| Salvar sem slot ativo | No-op com aviso no log |
| Autosave rodando em menu | Bloqueado pelo guard `current_slot == 0` |

---

## 7. Checklist de testes manuais

- [ ] Primeiro boot sem nenhum save: `Jogar` abre a lista com 5 slots vazios.
- [ ] Boot com `savegame.json` antigo: aparece no slot 1 com os dados corretos.
- [ ] Criar jogo → volta ao menu → `Jogar` mostra o slot ocupado com nome/semana/dinheiro corretos.
- [ ] Criar 5 jogos: `Novo Jogo` fica desabilitado e a tela de seleção não oferece `Novo jogo`.
- [ ] Excluir o slot 2 e criar novo jogo: o novo ocupa o slot 2.
- [ ] Carregar o slot 3, jogar, sair pelo menu de pause, recarregar o slot 3: progresso preservado.
- [ ] Comprar FIIs no slot 1, sair, criar novo jogo: carteira zerada (regressão do vazamento).
- [ ] Corromper manualmente um `save_N.json`: slot mostrado como corrompido e excluível, sem travar a tela.
- [ ] Falhar uma missão (game over): partida reinicia no mesmo slot, contagem de saves não muda.
- [ ] Autosave de 300s não cria arquivo enquanto o jogador está nos menus.

---

## 8. Riscos e pontos de atenção

1. **`Global` deixa de carregar save no boot.** Qualquer script que hoje assuma `Global.player` já populado ao entrar numa cena precisa ser conferido. `ensure_player_state()` garante um dicionário válido, mas os valores serão os padrões até um slot ser carregado. Conferir: [hud_control.gd:12](scripts/hud/hud_control.gd:12), [missions_ui.gd](scripts/hud/missions_ui.gd), [clock.gd](scripts/hud/clock.gd).
2. **`FIIManager.funds` é sobrescrito pelo save.** Por isso `reset()` precisa restaurar `_default_funds()`, não só limpar o `portfolio`.
3. **Ordem dos autoloads.** `SaveManager` já vem antes de `Global` em [project.godot](project.godot) — manter assim, pois `Global.start_new_game()` depende do `SaveManager` pronto.
4. **Exclusão é irreversível.** Confirmação obrigatória; não implementar "lixeira" nesta entrega.
5. **Migração roda uma única vez.** Depois de mover o arquivo legado, o `savegame.json` deixa de existir — testar a migração com uma cópia de backup do arquivo real.

---

## 9. Ordem de execução sugerida

1. Fase 1 (`SaveManager`) — base de tudo, testável isoladamente via log.
2. Fase 3 (`FIIManager.reset`) — pequena e independente.
3. Fase 2 (`Global`) — depende de 1 e 3.
4. Fase 4 (cena de seleção) — depende de 1 e 2.
5. Fase 5 (menu principal) — depende de 4.
6. Fase 6 (personagem + game over) — fecha os fluxos restantes.
7. Rodar o checklist da seção 7.
8. Atualizar a seção 8 do [PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md), que ainda descreve o save único em `user://savegame.json`.
