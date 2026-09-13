# ARCHITECTURE — GALÁPAGOS: THE ORIGIN

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5 (approved technical architecture, once ACCEPTED)
    VERSION: 1.2
    DATE: 2026-09-12
    DERIVES FROM: 01_MASTER_CANON v1.1 (L2) · C-001 owner decisions · Final owner decisions ·
                  ADR-001 … ADR-008
    AMENDMENTS: v1.2 — `core/input/` added to §2 (C-002 owner review, decision 1)
    COMPANION DOCUMENTS: CONVENTIONS.md · STATE_OWNERSHIP.md · CANON_CONFLICT_RESOLUTION.md

> This document is **normative**. Where it says MUST or NEVER, CI enforces it wherever mechanically
> possible. Principles that cannot be verified are written as rules with an owner, not as advice.
>
> Detailed rationale lives in the ADRs. This document states **what the rules are**.

## 0. ADR index

| ADR | File | Decides |
|---|---|---|
| 001 | [`adr/ADR-001-engine-renderer-pixel-contract.md`](adr/ADR-001-engine-renderer-pixel-contract.md) | Godot version policy, Compatibility renderer, **320×180** pixel contract, size classes, battle staging gate |
| 002 | [`adr/ADR-002-repository-ci-dependencies.md`](adr/ADR-002-repository-ci-dependencies.md) | GitHub private + Actions, dependency policy, GUT, evidence harness, CI gates, dialogue runtime |
| 003 | [`adr/ADR-003-layers-events-autoloads.md`](adr/ADR-003-layers-events-autoloads.md) | Layer direction + lint, C/E/Q model, autoload budget, 15 substates, behaviour tags |
| 004 | [`adr/ADR-004-data-ids-canon-registry.md`](adr/ADR-004-data-ids-canon-registry.md) | JSON source, IDs, Canon Registry, **type matrix**, evolution graph, localization, **personality** |
| 005 | [`adr/ADR-005-persistence-save-first.md`](adr/ADR-005-persistence-save-first.md) | Save-first sequencing, runtime/DTO split, atomic write, fixtures, RNG, **reserve 240 + FINALIZAR VÍNCULO** |
| 006 | [`adr/ADR-006-battle-timeline-performance.md`](adr/ADR-006-battle-timeline-performance.md) | Battle timeline contract, RECUPERAR, Reaction windows, composable MovePerformance, **13 performance archetypes**, FULL/FAST/MINIMAL |
| 007 | [`adr/ADR-007-compass-bond-boundaries.md`](adr/ADR-007-compass-bond-boundaries.md) | Quantized Compás readings, state-only Bond, Control separation |
| 008 | [`adr/ADR-008-capabilities-world-traversal.md`](adr/ADR-008-capabilities-world-traversal.md) | Discrete regions, EnvironmentContext, capability grades, reachability validator, **Vertical Slice scope boundary** |

---

## 1. Layers and dependency direction

```
Presentation  ──▶  Systems  ──▶  Core  ──▶  Data
      ▲                                      
      └──────── events only (upward) ────────┘
```

Dependencies point **downward only**. Upward communication is exclusively by event. *(ADR-003 §1)*

| Layer | Root | May depend on | MUST NEVER |
|---|---|---|---|
| **Presentation** | `presentation/` | Systems, Core | mutate `GameState`; contain game rules; compute outcomes |
| **Systems** | `systems/` | Core, Data | reference presentation; depend on the scene tree; `await` animation |
| **Core** | `core/` | Data | know any specific game system by name |
| **Data** | `data/` | — | contain logic |
| **Autoload** | `autoload/` | Systems, Core | contain game rules |

**Headless testability of battle logic is a consequence of this rule, not a separate wish.** One
reference from `systems/battle/` into `presentation/` destroys it.

**Enforcement:** CI gate 2, layer lint. Any upward edge fails the build.

**Approved exceptions:** *(none currently. Every exception must be listed here with a written
justification. An exception not listed here is a build failure, not a judgement call.)*

---

## 2. Folder ownership

```
res://
├── addons/gut/              # vendored, pinned — the ONLY third-party dependency
├── autoload/                # ≤8 thin globals (§3)
├── core/                    # Layer: Core — infrastructure, no game rules
│   ├── contracts/           #   shared value objects + generated canon enums
│   ├── state/               #   runtime substate definitions
│   ├── save/                #   envelope, atomic IO, migrations
│   │   └── dto/             #   versioned save contract (separate from runtime state)
│   ├── input/               #   semantic actions, active-device detection, input config
│   ├── rng/ events/ loc/ log/ util/
├── data/
│   ├── source/              # JSON — AUTHORITATIVE
│   │   ├── canon/           #   canon registry + type matrix
│   │   ├── tikawi/ moves/ items/ world/ dialogue/ quests/
│   │   └── _registry/       #   ids.json (append-only), events.json, conditions.json
│   └── generated/           # rebuildable artifacts — NEVER hand-edited
├── systems/                 # Layer: Systems — one folder per system, one facade each
│   ├── battle/ tikawi/ roster/ bond/ control/ compass/ codex/ research/
│   ├── evolution/ encounter/ world/ environment/ quest/ dialogue/ map/
│   ├── inventory/ economy/ story/ statistics/ navigation/
│   └── ancestral/           #   Fenómenos Ancestrales — sanctioned unique-entity module
├── presentation/            # Layer: Presentation
│   ├── ui/ world/ battle/
│   └── performance/         #   MovePerformance assembly
├── content/                 # art, scenes, audio
│   ├── tikawi/ regions/ characters/ audio/ ui/
├── tools/                   # validators, generators, build + evidence tooling
│   ├── validators/ generators/ lint/
├── tests/
│   ├── unit/ integration/ canon/
│   └── fixtures/saves/      #   golden saves — NEVER regenerated, NEVER edited
└── docs/
    ├── adr/ archive/
```

**Rules.** One folder per system. Exactly one public facade per system. No system reaches into
another system's folder — only its facade. `content/` holds assets, never logic.

**`core/input/`** *(added v1.2 — ACCEPTED)* owns **semantic input actions**, **active-device
detection**, the **controller/keyboard abstraction** and **input configuration helpers**. Like every
Core folder it **MUST NOT contain gameplay rules**: it reports what the player pressed, never what
that means in the world. Raw key and joypad reads are forbidden outside it (CI gate 1). Rebinding
*storage* is a setting (§10), and rebinding *UI* is VS9 presentation — neither lives here.

---

## 3. Approved autoloads

**Hard cap: 8. Adding one requires an ADR.** *(ADR-003 §4)*

| Autoload | Responsibility (one line) |
|---|---|
| `EventBus` | Typed cross-module event registry and deferred dispatch |
| `GameState` | Holds substates; exposes reads; owns no rules |
| `SaveManager` | The only writer of adventure files |
| `SceneManager` | Scene and region transitions, loading presentation |
| `AudioManager` | Bus routing, music layers, audio-ID playback |
| `TimeManager` | Owns game time; publishes `EnvironmentContext` |
| `RngService` | Named deterministic RNG streams; seed state is save state |

7 of 8 used. `LocalizationManager` was **removed** (Godot's `TranslationServer` + `core/loc/`).

**Autoloads hold and expose. They do not implement.** Game rules live in systems.

> The autoload cap prevents clutter. The **layer lint** is what prevents coupling. Do not mistake a
> low autoload count for a decoupled architecture.

---

## 4. Public contract conventions

| Concept | Implementation | NOT |
|---|---|---|
| **Command** | public method on the owning system's facade | a command object or command bus |
| **Event** | `EventBus` signal, **past tense** | a command in disguise |
| **Query** | public method, no side effects | a query object or read model |

**Facade rules**

- Each system exposes exactly one facade: `systems/<name>/<name>_system.gd`, `class_name <Name>System`.
- Commands are imperative (`bond_attempt`, `advance_time`), return `void` or a typed result.
- Queries are prefixed `get_` / `is_` / `can_` / `find_` and **MUST NOT** mutate anything.
- Cross-system calls go **facade to facade**. Internals are private to the folder.
- Facades **MUST** be usable headless. No scene-tree assumptions, no `await` on presentation.
- All public methods and returns **MUST** be statically typed. *(CONVENTIONS.md)*

**Canon-protected contracts** — these return quantized or enumerated values and **MUST NEVER**
expose continuous magnitudes across the boundary: `CompassReading`, `BondEvaluation` *(ADR-007)*.

**Battle** exposes `BattleActionResult` as an immutable ordered step timeline *(ADR-006 §1)*.

---

## 5. Source and generated data rules

*(ADR-004)*

1. **`data/source/` JSON is authoritative.** Nothing else is a source of truth.
2. Generated artifacts derive from source and from nothing else; each carries an autogenerated
   header naming its source.
3. **Generated artifacts MUST NEVER be hand-edited.** CI gate 4 regenerates and diffs.
4. No system reads source JSON *and* a generated artifact for the same content.
5. **IDs are `snake_case` strings, immutable, never reused**, registered append-only in
   `_registry/ids.json`. Retired IDs move to `deprecated_ids`; they are never deleted.
6. **`codex_number` is presentation metadata and MUST NEVER be written into a save.**
7. No positional indices or ordering numbers as identity, anywhere.
8. **Closed condition/effect vocabulary**, shared by evolution, quests, dialogue, research,
   encounters and world gating. No arbitrary expressions, no embedded scripting.
9. **Canon Registry**: closed canon enumerations live in `data/source/canon/`; GDScript constants
   are **generated** from it. Canon is never transcribed by hand into code.
10. **Validation order:** schema → semantic → canon. Invalid content fails the build.
11. **Localization keys are generated from IDs**, never hand-written. Canonical proper names are
    **non-translatable** and CI fails if their value differs between locales.

**Family structure:** 49 non-Legendary families × exactly 3 Codex entries; 3 Legendarios as single
entries. A family is a **directed graph of evolution edges, not necessarily a linear chain** —
branching adaptation must remain expressible. *(ADR-004 §4)*

**Type matrix:** a **single attacker → defender matrix** of 13 × 13 = 169 cells lives in the Canon
Registry. Tier scale ×2.0 / ×1.5 / ×1.0 / ×0.67 / ×0.4, **no immunities anywhere**. Stacking is a
**net-step lookup, not a product**; a dual-type defender **sums the two steps and clamps** to the
scale. A declared strong matchup **establishes the inverse resistance** unless explicitly overridden.
The completed chart is **26 strong · 24 derived resistances · 119 neutral · 0 immunities**, and it is
**locked as the VS3 baseline** — any matchup change after this point is game-balance design requiring
owner approval, never an architecture-time adjustment. *(ADR-004 §6)*

**Personality:** every individual Tikawi carries a persistent `personality_trait` from a closed
registry. It **MUST NEVER** be an input to stat calculation, growth or level scaling — it is a
behavioural tag, not a hidden stat roll. *(ADR-004 §9, STATE_OWNERSHIP.md §4.1)*

---

## 6. Pixel and presentation contract

*(ADR-001 §3–§6)*

| Item | Value |
|---|---|
| **Virtual resolution** | **320 × 180** (16:9) |
| Stretch mode | `canvas_items` |
| Scaling | **Integer only**, viewport **centred**; non-uniform stretching of gameplay pixels **NEVER** |
| Outside the viewport | Black or an approved presentation background |
| Texture filter | **Nearest**, no mipmaps, no lossy compression |
| World tile | **16 × 16** (20 tiles wide exactly; 11.25 tall — frame in pixels, not in whole tiles) |
| Player sprite | **16 × 24** baseline, **16 × 32** tall pose |
| Tilemap node | `TileMapLayer`. Deprecated `TileMap` is **forbidden**. |
| Overworld directions | **4** (N/S/E/W), E/W mirroring permitted; 8-direction animation **not required** |

**Integer scaling is exact on every common 16:9 display:** 1280×720 ×4 · 1920×1080 ×6 · 2560×1440 ×8
· 3840×2160 ×12. 1366×768 renders at ×4, centred, with 43 px side and 24 px top/bottom bars.

**Tikawi size classes** — production canvases, not a requirement that every sprite fill its canvas.
Every Tikawi declares exactly one class from a closed canon-registry enum.

| Class | Overworld | Battle |
|---|---|---|
| S | 16 × 16 | 48 × 48 |
| M | 24 × 24 | 64 × 64 |
| L | 32 × 32 | 80 × 80 |
| XL | 48 × 48 | 96 × 96 |
| LEGENDARY | 64 × 64 + | up to 128 × 128 |

**Battle staging is verified, not assumed.** Against a 320 × 180 viewport a LEGENDARY battle sprite
occupies 40% of width and **71% of height**, and a 2v2 of four M-class occupies up to 80% of width in
a single row. **VS3 delivers, as an acceptance criterion, a staged 1v1 with a LEGENDARY and a staged
2v2 with M-class, both demonstrating that windup → travel → contact → impact → reaction remain
legible.** *(ADR-001 §5)*

A design with a deliberately asymmetric feature must either accept that the feature swaps sides under
E/W mirroring, or declare `mirror: false` in its asset manifest and ship both directions.

---

## 7. Error policy

| Context | Behaviour |
|---|---|
| **Build / CI** | Invalid data, unknown IDs, failed canon checks → **hard failure**. No warnings-as-acceptable. |
| **Editor / debug builds** | Programmer errors → `assert` + `push_error`, loud and immediate |
| **Release builds** | **Controlled degradation**: log, surface to the player where relevant, continue |
| **Save with unknown ID** | Degrade gracefully. **NEVER** overwrite a save that could not be fully interpreted. |
| **Recoverable domain failures** | Typed result/error enum, never a magic value, never a silent default |

Two rules that are easy to violate and expensive to violate:

- **NEVER** substitute a silent default for missing content. Missing content is a build failure at
  build time and a logged degradation at runtime — never an invisible guess.
- **NEVER** overwrite player progress with data derived from a partially-read save.

---

## 8. RNG policy

*(ADR-005 §6)*

| Rule | Detail |
|---|---|
| Streams | Named and independent: `battle`, `encounter`, `weather`, `loot`, `cosmetic` |
| Why independent | So consuming randomness in one system cannot shift another's outcomes |
| Persisted | Master seed + per-stream counters — **except** `cosmetic` |
| `cosmetic` | Non-deterministic, non-persisted, **MUST NEVER** influence game state |
| **Forbidden** | Global `randi()` / `randf()` in any game system. CI grep. |
| Battle | Every `BattleActionResult` records the seed consumed → any battle is replayable from its log |

---

## 9. Event policy

*(ADR-003 §6)*

| Rule | Detail |
|---|---|
| **Single registry** | Every cross-module event declared in one file with a documented payload |
| **Past tense only** | `tikawi_bonded`, `region_entered`, `move_resolved`. An imperative name means it should have been a facade call. |
| **Deferred dispatch** | Gameplay events are queued and drained at a known point — never emitted mid-mutation |
| **No ordering dependence** | No game truth may depend on listener order. Ordered work is an explicit call. |
| **Local stays local** | Within a module use local signals. `EventBus` crosses module boundaries only. |
| **CI check** | Orphan events (emitted, never consumed) and phantom listeners both fail |

---

## 10. Persistence boundary

*(ADR-005)*

| Rule | Detail |
|---|---|
| **Only `SaveManager` writes adventure files** | No exceptions |
| **Runtime state ≠ save DTO** | Mapped explicitly per substate: `to_save_dict()` / `from_save_dict(version)` |
| **Admission rule** | No field enters the DTO without a written justification that it is a *durable consequence* |
| **Never persisted** | node references · derived values · caches · presentation state · `cosmetic` RNG · anything recomputable |
| Format | JSON; envelope carries `save_version`, `game_version`, timestamps, checksum |
| Versioning | `save_version` is **independent** of `game_version` |
| Checksum | Detects **corruption**, not tampering. No anti-cheat. |
| Atomic write | Windows-correct sequence; backup never destroyed before the new file verifies |
| Migrations | Sequential `N → N+1`. No skipping. |
| **Golden fixtures** | Frozen on every version bump. **NEVER regenerated, NEVER edited.** |
| **Schema-hash guard** | Persisted schema changed without a version bump + registered migration → build fails |
| Position | `region_id` + `entry_point_id` authoritative; `local_offset` degrades to the entry point |

**Per-milestone obligation.** Every milestone introducing durable state delivers: persistence
mapping · schema impact · migration when needed · fixture coverage.
**No milestone closes with durable state that is unpersisted and unmigrated.**

**Roster limits.** Active team maximum **6** (canon). **Maximum reserve capacity 240**, held in
**config, not code**, so an approved expansion is migration-free. The reserve is **paged *and*
filterable from the start**: `RosterSystem` exposes a filtered, sorted, paged query, so the UI never
loads all 240 instances in order to search them. Filter criteria are derived at query time from
persisted instance fields, so adding a filter is never a schema change. A full-capacity performance
test is required from VS9. *(ADR-005 §8.1)*

**Ending a bond.** `FINALIZAR VÍNCULO` is a `RosterSystem` command, permitted only in an approved
safe physical context. It never sells, never grants money, never treats a Tikawi as inventory, and
may be forbidden per individual via the `no_bond_exit` behaviour tag. **Codex and research history
survive** — roster operations cannot write `CodexState` under §10 ownership rules, so understanding
is never lost by losing possession. *(ADR-005 §8.2, STATE_OWNERSHIP.md §5.2)*

---

## 11. Battle presentation contract

*(ADR-006 §5, §7)*

**The Tikawi supplies the body; the move supplies the effect.** A `MovePerformance` is assembled from
components — body animation (from the species' size class and morphology), travel/action (from the
move), type VFX (from the move's element), impact (from the move), target reaction (from the target's
size class), audio IDs, and camera metadata. A new move is a new combination of existing parts; a new
species inherits the whole effect library.

**Approved initial archetype library — 13 entries, `PascalCase`, closed registry, not a closed
forever-list:**

| Role | Archetypes |
|---|---|
| Approach / locomotion | `Dash` · `Leap` · `Dive` · `Charge` |
| Body action | `Spin` · `Wing` · `Tail` · `Bite` |
| Ranged delivery | `Projectile` · `Beam` · `Arc` |
| Area | `GroundBurst` · `AreaPulse` |

Custom performances are permitted for **signature starter moves, Specials and Legendarios** only.

**Presentation modes — accessibility:**

| Mode | Behaviour |
|---|---|
| **FULL** | Complete performance. The authored default. |
| **FAST** | Compressed durations; every beat still plays. |
| **MINIMAL** | Shortest legible form. |

> **All three modes MUST render action → impact → reaction. There is no mode in which a move resolves
> as a number.** CI asserts this on the MINIMAL path for every move.

**Screen shake and flash intensity are independently reducible in every mode, including FULL** — they
are separate settings, not tiers of the same one. Per-beat minimum duration floors apply in FAST and
MINIMAL so compression cannot reduce a beat to zero frames.

**Reaction windows** are a closed enum: `BEFORE_IMPACT` · `AFTER_IMPACT` · `ON_STATUS`. Chain depth is
bounded at **1**. Contextual 2v2 windows are future work and require no resolver change.
*(ADR-006 §4)*

---

## 12. Testing and CI gates

*(ADR-002 §6)*

| # | Gate | From |
|---|---|---|
| 1 | Convention lint — static typing, naming, file size, forbidden patterns | VS0 |
| 2 | **Layer dependency lint** | VS0 |
| 3 | Data validation — schema → semantic → canon | VS0 |
| 4 | Generated-artifact freshness — regenerate and diff | VS0 |
| 5 | Unit tests (GUT, headless) | VS0 |
| 6 | Windows export | VS0 |
| 7 | Scene-load smoke test | VS0/VS1 |
| 8 | Save — golden fixtures migrate + schema-hash guard | VS0 |
| 9 | Localization — missing/orphan keys, proper-noun invariance | VS2 |
| 10 | Canon boundaries — Compás, Bond, `species_id` grep | VS4 |
| 11 | Reachability / anti-soft-lock | VS7 |

**Rules.** `main` stays buildable. A red gate blocks merge. A failing test is **never** weakened to
pass — if implementation violates spec, fix the implementation; if the spec changed, update the
authority first. Agents **never** self-certify a PASS; evidence is an artifact *(ADR-002 §5)*.

**Permanent canon tests** (they never expire and never get "cleaned up"):

- No continuous numeric field crosses the Compás or Bond boundary
- At least one legal battle action exists in any reachable state
- `codex_number` never appears in a save
- No system branches on `species_id`
- Exactly 13 types · exactly 150 Codex entries · pillar ranges intact
- Every move has a complete performance recipe with all mandatory beats
- Every move rendered in **MINIMAL** still emits action, impact and target reaction
- Every performance recipe references an archetype in the closed registry
- Same seed + same inputs → identical battle step sequence

---

## 13. Species-specific behaviour

*(ADR-003 §7)*

Systems branch on **capabilities**, never on identity.

- Species may declare `behavior_tags` / `behavior_components` from a **closed validated registry**.
- **No system may branch on `species_id`.** CI grep, with a short justified allowlist.
- **Sanctioned exception:** Legendarios and Fenómenos Ancestrales may have dedicated implementation
  **inside `systems/ancestral/`**. Unique entities with code in their own module is correct. Unique
  entities with `if` branches spread across battle, world and bond is the failure this prevents.

---

## 14. Reference module pattern

Every system follows this shape. *(Documentation template, not shipped code.)*

```
systems/codex/
├── codex_system.gd          # class_name CodexSystem — THE public facade
├── codex_rules.gd           # pure functions, headless, no state
├── internal/                # private; nothing outside this folder may import it
│   └── codex_entry_writer.gd
└── README.md                # owns: CodexState | emits: codex_entry_updated | 3 lines
```

```gdscript
class_name CodexSystem
extends RefCounted
## Owns CodexState. Stores knowledge. Does not decide what is discovered
## (that is ResearchSystem) and does not present anything.

# ---- Commands: request change, return typed results ----
func record_sighting(species_id: StringName) -> CodexWriteResult:
    ...                                  # mutate only CodexState
    EventBus.emit_deferred(&"codex_entry_updated", species_id)   # past tense, deferred
    return CodexWriteResult.ok()

# ---- Queries: ask without changing anything ----
func get_entry_state(species_id: StringName) -> CodexEntryState: ...
func is_discovered(species_id: StringName) -> bool: ...

# ---- Persistence: explicit mapping, never automatic serialization ----
func to_save_dict() -> Dictionary: ...
func from_save_dict(data: Dictionary, version: int) -> void: ...
```

**Checklist for every new system:** one facade · typed public API · owns exactly the substates
listed in `STATE_OWNERSHIP.md` · emits only registered past-tense events · headless-constructible ·
explicit save mapping or an explicit "persists nothing" declaration · no `species_id` branching ·
no presentation references.

---

## 15. Scope boundaries

### 15.1 Excluded from Volume I entirely (owner decision 10)

**Volume I contains none of the following, and no preparatory infrastructure for them:**
mandatory network · telemetry · analytics backend · official modding · audio middleware · anti-cheat.

Adding any of these requires an ADR and an owner decision — never an accumulated side effect.

### 15.2 Vertical Slice boundary (Final §16)

> **VS0–VS12 is the Vertical Slice roadmap. It is NOT full Volume I production.**

| Out of Vertical Slice scope | Status |
|---|---|
| Full **maritime** traversal and the depth axis | Abstraction reserved (ADR-008 §8); **no content** |
| Full **Fenómenos Ancestrales** system | Module boundary exists (§13); **no content** |
| Full **Masters and Sellos** progression | Not implemented |

Confirmed inside the Vertical Slice: an **Evolution proof** at VS2 · **options, accessibility and
control rebinding** at VS9 · **audio delivered incrementally with a VS11 gate**.

**After VS12, a separate `VOLUME I PRODUCTION ROADMAP` is authored.** Volume I content expansion
happens there, not by widening a VS milestone.

> This section exists specifically to prevent Vertical Slice scope creep. A task that proposes
> building deferred content before VS12 is out of scope by this document, however naturally it
> follows from an abstraction that was reserved for it. Reserving an abstraction is not a licence to
> fill it.

---

## 16. Document authority

Every document in this repository carries `STATUS` and `AUTHORITY LEVEL` in its first lines.
**A document without that header is not authority.**

Authority order: Luisma's current decision → Master Canon → approved Game Design → accepted ADRs →
approved Technical Architecture (this document) → Claude spec → Codex implementation → code →
archived documents.

> **Conversation memory is not the source of truth. Versioned repository documentation is.**
