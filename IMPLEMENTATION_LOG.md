# Implementation Log — Fase 6-10 Changes
**Started:** 2026-09-08  
**Status:** In Progress (Fase 6 COMPLETE, Fase 7-10 Pending)

**Progress:** 30% Complete (3/10 phases done, all 3 sub-items of Fase 6 finished)

---

## SUMMARY OF COMPLETED WORK

### ✅ Fase 6 — COMPLETE (All 3 items done)

**6.1 - Stamina Rename (COMPLETE)**
- Renamed all `player["happiness"]` → `player["stamina"]` throughout codebase
- Updated files: Global.gd, hud_control.gd, home.gd, player.tscn, home.tscn
- UI labels changed from "FELICIDADE" to "STAMINA"
- All data_model references updated

**6.2 - Stamina Decay Mechanics (COMPLETE)**
- Implemented continuous stamina decay: 100 stamina depleted in 960 minutes (16 hours)
- Base decay rate: 0.104 per minute
- After 18h: decay doubles, increases 10% per additional hour
- Added _decay_stamina() function called every minute in TimeManager
- Added _handle_midnight() for auto-teleport at 00h if awake: -R$30, stamina→50%
- Hunger now has separate game-over logic: "Você morreu de fome!"

**6.3 - Market Items with Hunger Restoration (COMPLETE)**
- Added "hunger_restore" field to all 20 market items
- Prices proportional to hunger: R$ ≈ 2.0-2.2 × hunger%
- Items display: "Bread – R$20 – 10% fome"
- Updated add_home_inventory_item() to accept hunger_restore parameter
- Converted hunger_restore % → energy value when items stored

---

## NEXT PHASES TO IMPLEMENT

### Fase 7 — Progressão de Dia e Mecanica de Repouso  
**Priority: HIGH** (Fundamental gameplay changes)

**7.1 - Manual Day End (NOT STARTED)**
- Current: Day auto-ends at 18h with immediate return home
- Needed: Alert at 18h, player must walk home, click "Dormir" to advance day
- Files to modify: TimeManager.gd (_finish_day), home.gd (add sleep option)

**7.2 - Stamina Decay After 18h + Midnight Penalty (IN PROGRESS)**
- Already added decay acceleration after 18h in TimeManager._decay_stamina()
- Already added midnight teleport/penalty in TimeManager._handle_midnight()
- Needs testing: verify rates and penalty trigger correctly

**7.3 - Game-Over Differentiation (PARTIALLY DONE)**
- Hunger=0 → Game-over (already implemented: decay_need_state() + _game_over() callback)
- Stamina=0 (before 18h) → Alert only (already in _decay_stamina())
- Stamina=0 (after 18h) → Continued decay (already implemented)

### Fase 8 — Correção de Bugs Críticos
**Priority: HIGH** (Blocking features)

**8.1 - Game-over Button Fix (NOT STARTED)**
- Problem: OK button doesn't return to menu after "Você morreu de fome"
- Solution: Already partially done via _game_over() callback, needs testing

**8.2 - Minigame Week 2 Crash (NOT STARTED)**
- Problem: Week 2 minigame fails to initialize
- Investigation needed: MinigameManager state, week transitions

### Fase 9 — Pausa e Gestão de Tempo
**Priority: MEDIUM**

**9.1 - Time Pauses in Menu (NOT STARTED)**
- Problem: TimeManager continues running when in menu
- Solution: Check current_scene in _process(), pause if not main_game.tscn

### Fase 10 — Penalidades de Investimento Ruim
**Priority: LOW** (Educational enhancement)

**10.1 - FII Loss Penalty (NOT STARTED)**
- Implement: 10% tax on selling at a loss
- Alternative: Penalize non-diversified portfolios

---

## KEY CODE CHANGES FOR REFERENCE

### Stamina Decay Rate Formula (TimeManager)
```gdscript
var decay_rate = 0.104  # Base: depletes 100 in 960 minutes
if hour >= 18:
    decay_rate = 0.208  # Double
    var hours_after_18 = hour - 18
    if hours_after_18 > 0:
        decay_rate *= (1.0 + (hours_after_18 * 0.1))  # +10% per hour
```

### Hunger Restore Ratio (Market)
- Formula: price ≈ 2.0 × hunger_restore% + adjustments
- Examples:
  - Water: R$5 (3% hunger)
  - Bread: R$20 (10% hunger)  
  - Meat: R$150 (100% hunger)

### Item Energy Calculation (Global)
```gdscript
if hunger_restore > 0:
    item["energy"] = float(hunger_restore)
    item["happiness"] = float(hunger_restore) * 0.1
```

---

## KNOWN ISSUES / NOTES FOR CONTINUATION

1. **Day Timeline Extended:** Day now goes 00h-24h instead of 00h-18h
   - All time-dependent features (missions, events, dividends) need verification
   - Mission checks still work at week boundary

2. **Hunger vs Stamina Split:**
   - Hunger: depletes slowly (-6 at day end), causes game-over when 0
   - Stamina: depletes continuously, forces rest but doesn't kill player

3. **Tutorial Integration Needed:**
   - Explain stamina mechanic and 16-hour limit
   - Explain market item hunger restoration percentages
   - Explain midnight penalty mechanic

4. **Testing Priority:**
   - Verify stamina reaches 0 at exactly 16 hours
   - Test midnight teleport and R$30 penalty trigger
   - Test hunger game-over flow
   - Verify market items restore correct hunger amounts

---

## Files Modified This Session

1. ✅ `singletons/Global.gd` - stamina rename + decay changes + hunger game-over
2. ✅ `scripts/hud/hud_control.gd` - stamina bar variable
3. ✅ `scripts/world/home/home.gd` - stamina bar variable
4. ✅ `scenes/players/player.tscn` - node rename + UI text
5. ✅ `scenes/world/places/home.tscn` - node rename + UI text
6. ✅ `singletons/TimeManager.gd` - continuous decay + midnight logic
7. ✅ `scripts/world/market/market.gd` - hunger_restore system
8. ✅ `IMPLEMENTATION_LOG.md` - this file

---

## Next Steps for User

If credits run out:
1. Continue with Fase 7.1 - modify _finish_day() to NOT auto-end day
2. Add "Dormir" button in home.gd to trigger day advance
3. Test stamina decay and midnight mechanics
4. Move to Fase 8 bug fixes
5. Implement Fase 9 time pause logic
6. Add Fase 10 FII loss penalties

All infrastructure for Fase 6 is in place. Game should now:
- Show STAMINA instead of FELICIDADE
- Deplete stamina continuously, reaching 0 at 16 hours
- Auto-teleport at midnight with penalty if awake
- Show hunger/stamina in market items
- Implement proper game-over for hunger

### 6.1 — Renomear "Felicidade" para "Stamina"

#### Files to Update (tracking scope):
- [x] `Global.gd` — campo `"happiness"` → `"stamina"` in data_model, ensure_player_state(), new_game()
- [x] `scripts/hud/hud_control.gd` — rótulo "FELICIDADE" → "STAMINA"; variable names
- [x] `scripts/world/home.gd` — recovery logic that resets happiness → stamina
- [x] `singletons/TimeManager.gd` — decay_need_state() logic; all happiness references
- [x] All scripts that read/write happiness — use grep to find them all
- [x] `scenes/ui/hud.tscn` — UI label text change
- [x] `scenes/players/player.tscn` — node renamed Happiness→Stamina, text "Felicidade"→"STAMINA"
- [x] `scenes/world/places/home.tscn` — node renamed Happiness-container→Stamina-container, text updated

---

### 6.2 — Stamina dura apenas 2/3 do dia (16 horas de jogo)

#### Target File:
- [x] `singletons/TimeManager.gd` — decay_need_state() function

#### Changes Required:
- Stamina decays to 0 in 16 hours (960 game-minutes)
- Rate: 100 / 960 = ~0.104 per minute
- Alert player at 18h (but no auto-game-over yet)

#### Changes Made:
- [x] **TimeManager.gd**: Added _decay_stamina() function called every minute
  - Base decay rate: 0.104 per minute (depletes stamina in 16 hours)
  - After 18h: decay rate doubles (0.208)
  - Each hour after 18h: rate increases by additional 10%
- [x] **TimeManager.gd**: Added _handle_midnight() function
  - At midnight (00h), if player still awake: auto-teleport to home, charge R$30, set stamina to 50%
  - Show alert: "Você passou a noite acordado e teve que comprar muito café para aguentar o dia! - R$ 30"
- [x] **TimeManager.gd**: Modified _add_minute() to call _decay_stamina() and handle hour transitions properly
- [x] **Global.gd**: Updated decay_need_state() to only handle hunger (stamina now handled by TimeManager)
- [x] **Global.gd**: Added _game_over() callback for hunger game-over alert to return to menu

---

### 6.3 — Itens do mercado vinculados ao restauro de Fome

#### Target File:
- [x] `scripts/world/market.gd` — item definitions and purchase logic

#### Changes Required:
- Link item price to hunger restoration %
- Example: pão (R$20 - 10%), arroz (R$90 - 70%), frango (R$150 - 100%)
- Ratio: price / hunger% should be ~0.3

#### Changes Made:
- [x] **market.gd**: Updated items dictionary with "hunger_restore" field for all items
  - Prices scaled proportionally: R$ ≈ 2.0-2.2 × hunger_restore%
  - Items range from water (R$5 - 3%) to meat (R$150 - 100%)
- [x] **market.gd**: Updated display to show hunger restoration % (e.g., "Bread – R$20 – 10% fome")
- [x] **market.gd**: Updated _on_buy_item() to store hunger_restore in cart entries
- [x] **market.gd**: Updated _on_finish_pressed() to pass hunger_restore to add_home_inventory_item()
- [x] **Global.gd**: Added optional hunger_restore parameter to add_home_inventory_item()
  - Converts hunger_restore % directly to energy value
  - Calculates mood bonus as hunger_restore × 0.1

---

### 6.3 — Itens do mercado vinculados ao restauro de Fome

#### Target File:
- [ ] `scripts/world/market.gd` — item definitions and purchase logic

#### Changes Required:
- Link item price to hunger restoration %
- Example: pão (R$20 - 10%), arroz (R$90 - 70%), frango (R$150 - 100%)
- Ratio: price / hunger% should be ~0.3

#### Changes Made:
**[TODO]**

---

## Fase 7 — Progressão de Dia e Mecanica de Repouso

### 7.1 — Fim de dia não é automático; alerta + mecanismo manual de descanso

#### Target Files:
- [ ] `singletons/TimeManager.gd` — modify day progression logic
- [ ] `scripts/world/home.gd` — add sleep/rest mechanic
- [ ] `scripts/hud/event_ui.gd` — show alert without auto-advance

#### Changes Required:
- 18h: Show alert "Você está exausto! Volte para casa para descansar."
- Player must walk home physically
- Add "Dormir" option in home
- Sleeping: stamina→100%, hunger→reset, day advances

#### Changes Made:
**[TODO]**

---

### 7.2 — Stamina decai mais rápido após as 18h; penalidade meia-noite

#### Target File:
- [ ] `singletons/TimeManager.gd` — decay_need_state() modifications

#### Changes Required:
- 18h-23h: decay rate doubles, then increases 10% per hour
- 00h (midnight): auto-teleport home if awake, charge R$30, stamina→50%

#### Changes Made:
**[TODO]**

---

### 7.3 — Game-over por Fome vs Game-over por Stamina

#### Target File:
- [ ] `singletons/TimeManager.gd` — update need decay logic

#### Changes Required:
- Hunger = 0 → Game-over: "Você morreu de fome!"
- Stamina = 0 (before 18h) → Alert: "Você está muito cansado!" (no game-over)
- Stamina = 0 (after 18h) → Accelerated decay

#### Changes Made:
**[TODO]**

---

## Fase 8 — Correção de Bugs Críticos

### 8.1 — Game-over por Fome: botão OK não funciona

#### Target File:
- [ ] `scripts/hud/event_ui.gd` — game-over button handler

#### Changes Required:
- Ensure OK button returns to main_menu scene
- Fix any transition issues

#### Changes Made:
**[TODO]**

---

### 8.2 — Minigame da semana 2 falha ao iniciar

#### Target Files:
- [ ] `scripts/minigame/minigame.gd`
- [ ] `singletons/MinigameManager.gd`

#### Changes Required:
- Investigate state management between weeks
- Ensure proper reset on week 2 entry
- Test minigame initialization

#### Changes Made:
**[TODO]**

---

## Fase 9 — Pausa e Gestão de Tempo

### 9.1 — Tempo continua rodando quando volta ao menu principal

#### Target File:
- [ ] `singletons/TimeManager.gd` — _process() method

#### Changes Required:
- Check current scene is main_game.tscn before running time logic
- Pause/resume via signals or scene state

#### Changes Made:
**[TODO]**

---

## Fase 10 — Penalidades de Investimento Ruim

### 10.1 — Penalizar inversões ruins em FII

#### Target File:
- [ ] `singletons/FIIManager.gd` — buy/sell logic

#### Changes Required:
- Option A: Penalize selling with loss (10% tax on loss)
- Option B: Penalize lack of diversification (>70% in one fund)
- Start with Option A

#### Changes Made:
**[TODO]**

---

## Tutorial Integration Notes

When implementing new mechanics:
- **Fase 7.1 (Sleep mechanic):** Add tutorial step explaining "Dormir" (rest) action
- **Fase 6.2 (Stamina decay):** Explain stamina bar and 2/3 day limit
- **Fase 10.1 (FII penalties):** Add tip about diversification

Insert messages in `TutorialManager.gd` and `queue_messages()` calls in appropriate scenes.

---

## Notes for Continuation

- Grep search pattern for "happiness": `happiness|felicidade` (case-insensitive)
- Timeline constraint: day now goes 00h-24h instead of 00h-18h
- All time-dependent features (missions, events, dividends) need verification
- Test saves should be cleared after stamina rename (field migration)
