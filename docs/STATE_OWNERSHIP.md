# STATE OWNERSHIP — GALÁPAGOS: THE ORIGIN

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    ENFORCES: "GameState exposes state; domain systems own valid mutations"
    RELATED: ARCHITECTURE.md §10 · ADR-003 §5 · ADR-004 §9 · ADR-005 §8
    OWNER DECISIONS APPLIED: Review §3 (Personality — RESTORED),
                             Review §4 (13 → 15 substates APPROVED · reserve 240 · FINALIZAR VÍNCULO),
                             Final 10 (15 substates), Final 11 (reserve paging + filtering),
                             Final 12 (FINALIZAR VÍNCULO)

---

## 1. The rule

> **Every substate has exactly one owner. Only that owner mutates it. Everyone else reads through
> a query or reacts to an event.**

`GameState` is an autoload holding substates. It **owns no rules**. UI never writes to raw state.
Without this table the rule is unauditable — nobody can answer *"who mutated `ReserveState`?"* in a
review or in CI.

**Enforcement.** Reads are public. Writes go through the owning system's facade. GDScript cannot
enforce this at language level, so CI greps for writes to `GameState.<substate>` outside the
owner's folder. Crude, effective, and it converts a principle into a gate.

---

## 2. Ownership table

| Substate | Owner (facade) | May be mutated by | Emits | Persisted |
|---|---|---|---|---|
| `MetaState` | `SaveManager` | SaveManager only | `save_completed`, `save_loaded` | ✅ |
| `PlayerState` | `PlayerSystem` | PlayerSystem | `player_moved_region` | ✅ |
| `TeamState` | `RosterSystem` | RosterSystem | `team_changed` | ✅ |
| `ReserveState` | `RosterSystem` | RosterSystem | `reserve_changed` | ✅ |
| `WorldState` | `WorldSystem` | WorldSystem | `world_change_applied` | ✅ |
| `StoryState` | `StorySystem` | StorySystem | `story_beat_reached` | ✅ |
| `QuestState` | `QuestSystem` | QuestSystem | `quest_updated`, `rumor_recorded` | ✅ |
| `CodexState` | `CodexSystem` | CodexSystem | `codex_entry_updated` | ✅ |
| `InventoryState` | `InventorySystem` | InventorySystem | `item_changed` | ✅ |
| `EconomyState` | `EconomySystem` | EconomySystem | `pesos_changed` | ✅ |
| `NavigationState` | `NavigationSystem` | NavigationSystem | `vessel_state_changed` | ✅ |
| `MapState` | `MapSystem` | MapSystem | `map_point_discovered`, `anomaly_recorded` | ✅ |
| `StatisticsState` | `StatisticsSystem` | **StatisticsSystem only, from events** | — | ✅ |
| `EnvironmentState` **(added — APPROVED)** | `TimeManager` | TimeManager | `time_advanced`, `weather_changed`, `tide_changed` | ✅ |
| `RngState` **(added — APPROVED)** | `RngService` | RngService | — | ✅ (except `cosmetic`) |

Both additions are **APPROVED** (Review §4). The list is final at **15 substates**.

---

## 3. Notes on the ambiguous cases

These are the substates that attract stray writes. Deciding them now is the point of this document.

**`TeamState` + `ReserveState` share one owner (`RosterSystem`).** They are one domain — the
roster — and moving a Tikawi between them is a single transaction. Splitting ownership would make
that transaction cross a boundary for no benefit. Reserve access is restricted to safe physical
contexts (canon) and is validated in CI gate 11.

**`CodexState` is written only by `CodexSystem`.** `ResearchSystem` decides *whether* an
observation produces a discovery; it then calls the Codex facade. Research never writes Codex state
directly. This preserves the canonical split: *Codex stores knowledge; Research decides what is
discovered.*

**`StatisticsState` is append-only and event-driven.** Every system wants to write statistics, so
none may. `StatisticsSystem` subscribes to events and writes; nobody calls it.

**`WorldState` vs `QuestState` vs `StoryState`.** Boundaries, in order of precedence:
- `WorldState` — changes to the **world itself** (obstacle cleared, camp dismantled, object taken).
- `StoryState` — main campaign progress, including *campaign resolved* without locking the world
  (post-campaign play is promoted canon).
- `QuestState` — quests, favours and **rumors**, the latter storing `claim` and `truth` separately.

A quest that changes the world calls `WorldSystem`. It does not write world data itself.

**No substate exists for the Cuaderno, the Compás or Bond.**
- The **Cuaderno** is a presentation aggregation over `QuestState`, `MapState` and `CodexState`.
- **Compás anomalies** are durable map records → `MapState` *(ADR-007 §1)*.
- **Bond values and Control** live on the `TikawiInstance` inside the roster, not in a global
  substate. Bond is per-individual, so global state would be the wrong shape.

Resisting state growth is itself a decision. Two substates were added because nothing could
legitimately own them; three candidates were rejected because something already could.

---

## 4. Tikawi instance data

A `TikawiInstance` is owned by `RosterSystem` and persisted within `TeamState` / `ReserveState`.

**Contains:** `species_id` · `instance_id` · **`personality_trait`** · level · experience ·
learned moves · the six active moves · bond value *(internal, never crosses the boundary —
ADR-007 §2)* · `ControlState` · held item · persisting statuses · individual `behavior_tags`
(e.g. `no_bond_exit`) · nickname if any · origin metadata.

### 4.1 Personality (RESTORED — Review §3)

Every individual Tikawi carries a **persistent personality**, part of its individual identity.

| Item | Rule |
|---|---|
| Field | `personality_trait` (or `personality_profile`) |
| Source | Closed, validated registry in the Canon Registry *(ADR-004 §9)* |
| Assignment | At instance creation, from the seeded RNG and/or context |
| Persistence | **Survives save/load.** Asserted by the golden-fixture invariants *(ADR-005 §5)* |
| May affect | overworld behaviour · social reactions · Bond interactions · contextual tendencies · future small approved variation |
| Bond integration | Appears in `BondEvaluation.contributing_factors` — a qualitative factor, which is exactly what that contract already carries |

> **Hard boundary: personality MUST NEVER be an input to stat calculation, growth or level scaling.**
> The stat calculator must not even receive it.

Personality is a **behavioural tag, not a hidden stat roll**. The boundary is stated explicitly and
tested permanently because "personality as a small stat modifier" is the natural implementation and
is exactly the IV/EV drift that Review §3 excludes.

### 4.2 What an instance does not contain

**No per-individual stat variance (IVs) and no accumulated training points (EVs).** Per
`CANON_CONFLICT_RESOLUTION.md` §5, no such system is in the Volume I baseline. Build divergence
comes from move selection, held items, level and — for behaviour, not statistics — personality.
Adding IV/EV later would be a normal versioned save migration.

**Nothing copied from `TikawiSpeciesData`.** Species definitions are shared, immutable and
generated; an instance references them by ID and stores only what diverges. This is what keeps the
save compact at full reserve capacity.

---

## 5. Roster capacity and bond exit (Review §4 — DECIDED)

### 5.1 Capacity

| Item | Value |
|---|---|
| Active team maximum | **6** (canon, unchanged) |
| **Maximum reserve capacity** | **240 Tikawi** |
| **Reserve access** | **Paged and filterable** from the start (Final §11) |
| Storage | **Data/config-driven**, never a hardcoded constant |

The value lives in config so an owner-approved expansion later needs no architectural redesign —
only a config change plus a UI review. Because capacity is config rather than schema,
raising it is **migration-free** *(ADR-005 §8.1)*.

Two consequences that are now requirements, not suggestions:
- The **reserve is paged *and* filterable from the start**. Paging makes 240 individuals
  *navigable*; only filtering makes a specific individual *findable*. A flat 240-entry list is
  neither.
- **Filtering belongs to the owner, not to the UI.** `RosterSystem` exposes a filtered, sorted, paged
  query — by species, type, region of origin, evolution stage, bond state and personality — so that
  presentation never loads all 240 instances in order to search them. Putting the filter in the UI
  would both violate the ownership rule in §1 and reintroduce the performance problem the cap exists
  to bound.
- Filter and sort criteria are **derived at query time from persisted instance fields** (§4), so
  adding a new filter is never a schema change.
- A **large-reserve performance test** (full 240) is required from VS9, covering save size, load
  time and UI responsiveness.

### 5.2 FINALIZAR VÍNCULO

A voluntary bond may be ended by the player. Implemented as a `RosterSystem` command.

| Rule | Detail |
|---|---|
| Context | Only in an **approved safe physical context**, such as Casa del Naturalista |
| **Never** | sells the Tikawi · grants money · treats it as inventory |
| Effect | The Tikawi leaves team/reserve and **returns to the world / ecological abstraction** |
| Prohibition | Narrative, special and ancestral individuals may forbid it, via the `no_bond_exit` behaviour tag — **never** a `species_id` check *(ADR-003 §7)* |
| **Codex / research history** | **Preserved.** `CodexState` is owned by `CodexSystem` and is not touched by roster operations. |
| Event | `bond_ended` (past tense, deferred) |
| Identity | The retired `instance_id` is **never reused** *(ADR-004 §2)* |
| Safeguard | Confirmation required; the safe-context restriction prevents accidental loss |

**The knowledge guarantee is structural, not special-cased.** Under the ownership rules in §2, a
roster operation *cannot* write Codex state — so understanding cannot be lost by losing possession.
That is the canon principle itself, made impossible to violate:
*"Capturar una especie demuestra que la encontraste. Comprenderla demuestra que la conoces."*

---

## 6. Open items

**None.** Review §4 closed the three items previously listed here: the 13 → 15 substate amendment is
APPROVED, reserve capacity is set at 240, and bond exit semantics are defined.
