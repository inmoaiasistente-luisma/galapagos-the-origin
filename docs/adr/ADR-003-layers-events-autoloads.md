# ADR-003 — Layers, Dependency Direction, Events and Autoload Budget

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    AMENDS: 02_CLAUDE_MASTER_ARCHITECT.md — autoload list, GameState substate list
    OWNER DECISIONS APPLIED: 4 (State ownership approvals — EnvironmentState, RngState APPROVED)

## Context

The architecture baseline states correct principles but never declares which layer may depend on
which. GDScript provides no module system, no visibility modifiers and no interfaces: any script
can `preload()` any path and every autoload is globally reachable. **Layering in Godot is not a
language property. It exists only if it is verified.**

## Decision

### 1. Dependency direction

```
Presentation  ──▶  Systems  ──▶  Core  ──▶  Data
      ▲                                      
      └──────── events only (upward) ────────┘
```

| Layer | Root | May depend on | MUST NEVER |
|---|---|---|---|
| **Presentation** | `presentation/` | Systems, Core | mutate `GameState`; contain game rules; compute outcomes |
| **Systems** | `systems/` | Core, Data | reference presentation; depend on the scene tree; `await` animation |
| **Core** | `core/` | Data | know any specific game system by name |
| **Data** | `data/` | — | contain logic |
| **Autoload** | `autoload/` | Systems, Core | contain game rules |

**The canon requirement that battle logic be headless-testable is a *result* of this rule.** One
reference from `systems/battle/` into `presentation/` destroys it.

### 2. Enforcement — layer lint (CI gate 2)

A script builds the dependency graph from `preload`, `load`, `class_name` and type annotations,
grouped by root folder, and **fails the build on any upward edge**. Approved exceptions live in one
short list in `ARCHITECTURE.md`, each justified in writing. An exception not on that list is a
build failure, not a judgement call.

### 3. Commands, Events and Queries — the lightweight interpretation

| Concept | Implementation | NOT |
|---|---|---|
| **Command** | public method on the owning system's facade | a command object or command bus |
| **Event** | `EventBus` signal, **past tense** | a command in disguise |
| **Query** | public method, no side effects | a query object or read model |

No CQRS infrastructure. Single-player, single-writer, no undo, no input replay, no networking —
command objects would be pure ceremony. The principle is preserved in full; the machinery is zero.

### 4. Autoloads — AMENDMENT

**Hard cap: 8. Adding one requires an ADR.**

| Autoload | Status | Responsibility (one line) |
|---|---|---|
| `EventBus` | approved | Typed cross-module event registry and deferred dispatch |
| `GameState` | approved | Holds substates; exposes reads; owns no rules |
| `SaveManager` | approved | The only writer of adventure files |
| `SceneManager` | approved | Scene and region transitions, loading presentation |
| `AudioManager` | approved | Bus routing, music layers, audio-ID playback |
| `TimeManager` | **confirmed** | Owns game time; publishes `EnvironmentContext` |
| `RngService` | **ADDED** | Named deterministic RNG streams; seed state is save state |
| `LocalizationManager` | **REMOVED** | Superseded by `TranslationServer` + `core/loc/` |

`TimeManager` was conditional ("maybe… if justified"); owner decision 15 makes game time mandatory
and precisely specified, so the condition is met. `RngService` is added because its seed state is
**persisted** (ADR-005) — without it, loading a save re-rolls an outcome the player already saw.
`LocalizationManager` is removed because Godot already provides `TranslationServer` and `tr()`; a
wrapper does not justify one of eight slots.

Net: **7 of 8 used, one in reserve.**

> With `EventBus` and `GameState` global, everything can reach everything regardless of the count.
> The autoload cap prevents clutter; the **layer lint (§2)** prevents coupling. Do not mistake a low
> autoload count for a decoupled architecture.

### 5. GameState substates — AMENDMENT, **APPROVED by owner**

The list of 13 substates is extended to **15**. Both additions are **APPROVED** (owner decision 4).

| Added | Owner | Why it cannot live elsewhere |
|---|---|---|
| `EnvironmentState` | `TimeManager` | Game time, weather and tide are durable and cross-cutting; no existing substate owns them |
| `RngState` | `RngService` | Stream seeds and counters must survive save/load or outcomes silently re-roll |

No substate is added for the Cuaderno, Compás anomalies or Bond. The journal is a **presentation
aggregation** over `QuestState`, `MapState` and `CodexState`; anomalies are durable map records;
bond and personality are per-individual and live on `TikawiInstance`. Resisting state growth is
itself a decision.

Full ownership table: `STATE_OWNERSHIP.md`.

### 6. Event policy

| Rule | Detail |
|---|---|
| **Single registry** | Every cross-module event declared in one file with a documented payload |
| **Past tense only** | `tikawi_bonded`, `region_entered`, `move_resolved`, `bond_ended` |
| **Deferred dispatch** | Queued and drained at a known point, never emitted mid-mutation |
| **No ordering dependence** | No game truth may depend on listener order |
| **Local stays local** | Within a module, local signals. `EventBus` crosses module boundaries only. |
| **CI check** | Orphan events and phantom listeners both fail |

### 7. Species-specific behaviour — sanctioned escape hatch

The rule "avoid species-specific runtime scripts" is correct but, absolute, is unimplementable: the
canon itself creates three Legendarios with unique states and battle identities, twelve Specials
with condition-gated acquisition, Blackwood Control, and individuals that may forbid
FINALIZAR VÍNCULO. A rule with no sanctioned exit gets routed around as `if species == …` scattered
through unrelated systems.

- Species and individuals may declare `behavior_tags` / `behavior_components` from a **closed,
  validated registry** (`no_evolution`, `ancestral_phenomenon`, `terrain_shaper`,
  `condition_gated_encounter`, `no_bond_exit`, …).
- **No system may branch on `species_id`.** CI greps for `species_id ==`, `species ==` and
  equivalents outside a short justified allowlist.
- **Sanctioned exception:** Legendarios and Fenómenos Ancestrales may have dedicated implementation
  **inside `systems/ancestral/`**, declared in `ARCHITECTURE.md`. Unique entities with code in
  their own module is correct. Unique entities with `if` branches spread across battle, world and
  bond is the failure this prevents.

This extends the canon's own field-ability principle — *capabilities, not species* — to the runtime.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **No declared layer direction; rely on review** | The audit's root finding. In GDScript, unverified layering erodes within weeks and takes headless testability with it. |
| **Enforce layering by convention only, no lint** | Convention is not enforcement when an agent writes most of the code. The lint is the load-bearing control. |
| **Full CQRS** (command objects, bus, handlers) | Matches the vocabulary literally, adds substantial infrastructure for zero benefit in a single-writer game. Squarely the overengineering risk the owner asked me to watch. |
| **Direct system-to-system calls, no EventBus** | Fewer moving parts, but makes Codex/Research/Quest/Statistics all hard-depend on the systems that feed them. |
| **EventBus for everything, including intra-module** | Uniform, but turns every internal signal into a global contract and makes "who listens" unanswerable. |
| **Immediate (non-deferred) event dispatch** | Simpler, reintroduces reentrancy during mid-battle mutation — the hardest class of bug to diagnose. |
| **Absolute ban on species-specific code** | Unimplementable against canon. Gets violated covertly, which is worse than a declared, contained exception. |
| **Keep `LocalizationManager`; drop `RngService`** | Inverts the value: one duplicates an engine service, the other owns persisted state. |

## Consequences

- The layer lint is the load-bearing control of this architecture. If one CI gate survives budget
  pressure, it is that one.
- Deferred dispatch means listeners observe settled state, at the cost of events not being
  instantaneous — the correct trade for a turn-based game.
- Language switching becomes a Core helper rather than a global.
- Unique-entity code is permitted but confined, so it stays auditable.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Layer lint produces false positives and gets disabled | High | Approved-exception list, reviewed rather than suppressed; lint failures are triaged, never muted |
| Deferred dispatch hides ordering bugs until late | Medium | Explicit "no ordering dependence" rule plus orphan/phantom CI checks |
| `GameState` becomes a god-object despite ownership rules | High | `STATE_OWNERSHIP.md` plus the write-outside-owner grep |
| The `systems/ancestral/` exception widens over time | Medium | Exception list is explicit and short; widening it requires a new ADR |
| The 8-autoload cap is met and a real need appears | Low | One slot held in reserve; adding requires an ADR |
| `behavior_tags` registry grows into an ad-hoc scripting layer | Medium | Closed and validated; adding a tag is a reviewed code + registry change |

## Migration / compatibility impact

**Save compatibility:** `RngState` and `EnvironmentState` are **persisted**, so both are part of
the save schema from VS0. Introducing them now costs nothing; introducing either after VS0 would
have been a `save_version` bump plus a migration. This is a direct benefit of the ADR-005
save-first sequencing.

`behavior_tags` declared on **species** are generated data, rebuildable, not persisted. Tags
declared on an **individual** (e.g. `no_bond_exit`) are persisted on `TikawiInstance` and are
therefore schema — adding one later is a normal versioned migration.

Removing `LocalizationManager` has no persisted impact; language preference lives in settings, not
in the save (ADR-005 §2).

Reversing the layer direction later is not a migration — it is an architectural rewrite. This is
the ADR to get right before VS0.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-002** — baseline was prose, not an enforceable architecture | §1, §2 + `ARCHITECTURE.md` |
| **AUD-009** — dependency direction undefined and unenforceable | §1, §2 |
| **AUD-017** — EventBus untyped, unregistered, no ordering policy | §6 |
| **AUD-021** — species-specific behaviour had no sanctioned mechanism | §7 |
| **AUD-039** — autoload set had no cap and one redundant entry | §4 |
| **AUD-040** — Commands/Events/Queries had no implementation model | §3 |

## Open items

**None blocking.** §5 is APPROVED by owner decision 4. §4 carries the same amendment reasoning and
is confirmed by implication; flag it if you want the autoload amendment recorded as a separate
approval.
