# VS0 — FOUNDATION SPECIFICATION

    STATUS: ACCEPTED — Luisma, 2026-09-12 (C-002 owner review)
    AUTHORITY LEVEL: 4 (Claude implementation specification — binding on Codex once ACCEPTED)
    TASK: C-002
    DATE: 2026-09-12
    ENGINE PIN: Godot 4.7.2-stable · standard GDScript build · Compatibility renderer
    AMENDMENTS: A-01 (2026-09-12) — required CI status checks moved from T01 to T14;
                T14 ← T15 dependency reviewed and confirmed intentional. See §30.
                A-02 (2026-09-13) — repository visibility PUBLIC; solo-owner review model
                (0 approving GitHub reviews). See §31.
                A-03 (2026-09-13) — ENFORCEMENT INCIDENT. Phase-1 PR-only enforcement moved
                from classic branch protection to a repository RULESET after a direct push
                to `main` was accepted. T01 not accepted; VS0-T01R added. See §32.
                A-04 (2026-09-13) — PR-enforcement semantics corrected. Ruleset stands;
                A-03's test E1 withdrawn as invalid and replaced by E1A/E1B. The guarantee
                is ASSOCIATION with a PR, not rejection of every push. See §33.
                A-05 (2026-09-13) — MICRO. T01R test E2 evidence hardened: the merge PATH
                must be proven by `headRefOid != mergeCommit`. See §34.
                A-06 (2026-09-13) — MICRO. T01R test E4 split into E4A (API proof of the
                deletion rule) and E4B (behavioural rejection). The default-branch
                safeguard makes the ruleset's deletion behaviour unisolatable. See §35.
    DERIVES FROM: Master Canon v1.1 (ACCEPTED) · ADR-001 … ADR-008 (ACCEPTED) ·
                  ARCHITECTURE.md · CONVENTIONS.md · STATE_OWNERSHIP.md ·
                  CANON_CONFLICT_RESOLUTION.md (all ACCEPTED)
    AUDIENCE: Codex (implementation), Luisma (approval)

> This document tells Codex **exactly what to build in VS0 and exactly what not to build.**
> It contains no production code. Where a value cannot be asserted without verifying it against a
> real install (engine version, GUT release, checksums), this document states the **rule that
> determines it**, so the choice is mechanical rather than a decision.
>
> **If any task in this document still requires Codex to invent architecture, this document is
> defective.** §27 is the audit that checks that claim.

---

## 1. VS0 Objective

**Build the minimum reliable engineering foundation required before gameplay implementation
begins — and prove it runs, in CI, on Windows.**

VS0 produces no gameplay. Its output is a repository in which:

- the engine, renderer and pixel contract are **pinned and verified**, not assumed;
- the layer architecture is **enforced by a lint**, not by memory;
- data is **validated before the game runs**, not discovered broken at runtime;
- canon is **generated into code**, not transcribed by hand;
- durable state is **persisted and migratable from the first milestone**, not retrofitted at VS9;
- randomness is **deterministic and reproducible**, not ambient;
- every claim of PASS is an **artifact in CI**, not an assertion by an agent.

The single sentence that governs every scope question in VS0:

> **VS0 exists to make VS1 safe to start. Anything that does not make VS1 safer belongs to VS1 or
> later.**

---

## 2. Scope

VS0 delivers exactly the following, and nothing else.

| # | Deliverable | Why it must exist before VS1 |
|---|---|---|
| 1 | GitHub **public** repository, protected `main`, PR-only merge, worktree protocol | VS1 is the first milestone where an agent writes code that can be wrong. The review gate must exist before the code does. |
| 2 | Godot project that boots, exact engine version pinned, export templates matched | Every later task presumes a known engine. An unpinned engine makes every bug irreproducible. |
| 3 | Compatibility renderer configured and feature-verified | VS1 authors lighting and world presentation. Discovering a missing 2D feature after maps exist is expensive. |
| 4 | 320 × 180 pixel contract configured | VS1 authors the first tiles and sprites. Changing base resolution after art exists is re-authoring, not a setting. |
| 5 | Folder skeleton matching `ARCHITECTURE.md` §2 | The layer lint has nothing to check without it, and the first file placed wrongly sets a precedent. |
| 6 | Convention lint (CI gate 1) | Typing, naming and file-size drift is cheap to prevent and expensive to reverse. |
| 7 | Layer dependency lint (CI gate 2) | **The load-bearing control of the architecture.** GDScript has no modules; unverified layering erodes within weeks. |
| 8 | Source → generated data pipeline + validation (CI gates 3, 4) | VS1 authors the first region data. Data that can be invalid at runtime violates canon ("invalid content must fail before the game runs"). |
| 9 | Canon Registry foundation with generated GDScript constants | Canon transcribed by hand drifts silently. This converts an omission into a failing build — the exact failure class C-001 hit twice. |
| 10 | Save Core: envelope, atomic write, migration harness, golden fixture v1, schema-hash guard (CI gate 8) | Per ADR-005, save-first exists so that VS1…VS8 never define durable state without a persistence contract. |
| 11 | `RngService` with named streams, seeds persisted | RNG seeds are save state. Adding the service after saves exist is a `save_version` bump. It is also what makes tests deterministic. |
| 12 | `EventBus` + `GameState` shell with **one** substate (`RngState`) | Save Core needs something real to persist. One substate proves the whole chain end-to-end without inventing gameplay state. |
| 13 | Localization foundation (ES/EN, `core/loc/`, key parity check) | Canon requires ES/EN from day one. Retrofitting `tr()` across authored content is a rewrite; starting with it costs nothing. |
| 14 | Input foundation: action map, device-kind detection | VS1's first deliverable is movement. Movement bound to raw keys instead of actions makes VS9 rebinding a rewrite. |
| 15 | GUT vendored, pinned, running headless (CI gate 5) | Every subsequent gate is expressed as a test. |
| 16 | GitHub Actions workflow running gates 1–6 and 8 | Codex must not be able to self-certify a PASS. |
| 17 | Windows export succeeding headless (CI gate 6) | The target platform must be provably buildable from day one, not at VS11. |
| 18 | Scene-load smoke test + evidence harness (CI gate 7) | The mechanism behind the no-fabricated-PASS rule. |

**Autoloads introduced in VS0: exactly four** — `EventBus`, `GameState`, `SaveManager`,
`RngService`. See §7 for why the other three wait.

---

## 3. Explicit Out of Scope

**VS0 MUST NOT implement any of the following.** A pull request that touches them is rejected on
scope regardless of code quality.

| Not in VS0 | Earliest milestone |
|---|---|
| Player movement, camera, collision, tilemaps with real content | VS1 |
| `SceneManager`, region transitions, region loading | VS1 |
| `TimeManager`, `EnvironmentContext`, weather, tide | VS1 / VS7 |
| `AudioManager`, any audio playback | VS1 (incremental per Master Canon) |
| Tikawi runtime, stats, levels, evolution | VS2 |
| Battle, `BattleActionResult`, moves, type-matrix **evaluation code** | VS3 |
| Compás, Bond, Blackwood Control | VS4 |
| Codex, Research | VS5 |
| Quests, dialogue, rumors | VS6 |
| Field abilities, capabilities, traversal, reachability validator | VS7 |
| Economy, Casa del Naturalista, inventory | VS8 |
| Save slots, autosave policy, save UI, options UI, **control rebinding UI** | VS9 |
| Bulk species/move/region content, any of the 150 Codex entries as real data | VS10 |
| Navigation, fishing, diving, maritime anything | Post-VS12 production roadmap |
| Masters, Sellos, Prueba, Legendarios, Fenómenos Ancestrales | Post-VS12 production roadmap |

**Three clarifications that will otherwise be argued about:**

1. **The type matrix is authored as data in VS0; it is not evaluated in VS0.** VS0 ships
   `data/source/canon/type_matrix.json`, its schema, its validator and the generated `TikawiType`
   enum — because the Canon Registry is the deliverable being proven. It ships **no damage
   calculation**. That is VS3.
2. **`GameState` gets one substate, not fifteen.** The other fourteen arrive with the systems that
   own them. Declaring empty substates now would freeze a schema nobody has used.
3. **Localization gets keys, not content.** A handful of system strings prove the pipeline. Content
   strings arrive with content.

---

## 4. Required Reading

Codex reads these before the first VS0 task, and re-reads the cited sections named in each task
packet. **All are ACCEPTED authority.**

| Document | Read for |
|---|---|
| `docs/canon/01_GALAPAGOS_THE_ORIGIN_MASTER_CANON.md` | Technical baseline · Pixel contract · Authority. Canon wins over this spec if they ever disagree — report the conflict, do not resolve it. |
| `docs/ARCHITECTURE.md` | §1 layers · §2 folder ownership · §3 autoloads · §4 contracts · §5 data rules · §6 pixel contract · §7 errors · §8 RNG · §9 events · §10 persistence · §12 CI gates |
| `docs/CONVENTIONS.md` | All of it. This is what CI gate 1 enforces. |
| `docs/STATE_OWNERSHIP.md` | §1 ownership table · §4 `TikawiInstance` (read-only context; not implemented in VS0) |
| `docs/adr/ADR-001` | Engine pinning procedure · renderer verification gate · pixel contract |
| `docs/adr/ADR-002` | Repository, dependency policy, GUT, evidence harness, CI gate order |
| `docs/adr/ADR-003` | Layer direction, lint, autoload budget, event policy |
| `docs/adr/ADR-004` | IDs, Canon Registry, generated artifacts, validation order, localization keys |
| `docs/adr/ADR-005` | Save Core, DTO split, atomic write, fixtures, schema hash, RNG streams |
| `docs/adr/ADR-006`, `ADR-007`, `ADR-008` | **Context only.** Nothing in them is implemented in VS0. Read them so VS0 does not foreclose them. |

**Bootstrap inputs** (values, not decisions — Codex never invents them):

| Input | Value | Status |
|---|---|---|
| Engine | **Godot 4.7.2-stable**, standard GDScript build, no .NET | **FIXED** (owner decision) |
| Export templates | **Godot 4.7.2**, matching exactly | **FIXED** (owner decision) |
| Renderer | **Compatibility** | **FIXED** (ADR-001 §2) |
| `GITHUB_OWNER` | `inmoaiasistente-luisma` | **SUPPLIED** (owner, 2026-09-13) |
| `GITHUB_REPOSITORY` | `galapagos-the-origin` | **SUPPLIED** (owner, 2026-09-13) |
| Repository visibility | **PUBLIC** | **FIXED** (owner decision, 2026-09-13 — ADR-002 §1.1, §31.1) |

`GITHUB_OWNER` and `GITHUB_REPOSITORY` are **named bootstrap parameters**, referenced by those names
everywhere in this specification and in the workflow. Both values are now supplied; **Codex still
invents neither**, and uses these exact values rather than inferring a destination.

**The repository is public by deliberate owner decision** (§31.1): the current GitHub plan does not
provide the required branch protection on private repositories, and protection was chosen over
concealment. Everything committed is published — **never commit a secret, credential or token.**

---

## 5. Repository tree after VS0

Folders marked `(empty)` exist with a `.gitkeep` and a one-line `README.md` naming their owner and
layer. They are created now because the layer lint and the folder-ownership rule need the shape to
exist before the first file lands in the wrong place.

```
res://
├── .github/workflows/ci.yml
├── .gitattributes                    # Git LFS patterns
├── .gitignore
├── project.godot                     # pinned version, renderer, pixel contract, input map, autoloads
├── export_presets.cfg                # Windows Desktop preset
├── addons/gut/                       # vendored, pinned — the ONLY third-party dependency
├── autoload/
│   ├── event_bus.gd
│   ├── game_state.gd
│   ├── save_manager.gd
│   └── rng_service.gd
├── core/
│   ├── contracts/
│   │   ├── result.gd                 # typed result/error value object
│   │   └── generated/                # canon enums — GENERATED, never hand-edited
│   ├── state/
│   │   └── rng_state.gd              # the ONE substate implemented in VS0
│   ├── save/
│   │   ├── save_envelope.gd
│   │   ├── save_io.gd                # Windows-correct atomic write
│   │   ├── save_migrator.gd          # functioning but empty migration chain
│   │   ├── save_schema.gd            # schema hash computation
│   │   └── dto/
│   │       └── rng_state_dto.gd
│   ├── rng/
│   │   └── rng_stream.gd
│   ├── events/
│   │   └── event_registry.gd         # GENERATED from data/source/_registry/events.json
│   ├── loc/
│   │   └── loc.gd                    # locale selection + key helpers
│   ├── input/                        # NEW FOLDER — see §13 and §28 item 1
│   │   ├── input_actions.gd          # GENERATED action-name constants
│   │   └── input_device.gd           # last-used device kind
│   ├── log/
│   └── util/
├── data/
│   ├── source/
│   │   ├── canon/
│   │   │   ├── types.json            # the 13 official types
│   │   │   ├── type_matrix.json      # declared relationships + rules metadata
│   │   │   ├── size_classes.json
│   │   │   ├── bond_states.json
│   │   │   ├── move_categories.json
│   │   │   ├── research_stages.json
│   │   │   ├── origin_tags.json
│   │   │   └── rarity_tiers.json
│   │   ├── loc/
│   │   │   └── system.csv            # ES/EN system strings only
│   │   ├── _registry/
│   │   │   ├── ids.json              # append-only; empty arrays in VS0
│   │   │   ├── events.json
│   │   │   ├── input_actions.json
│   │   │   └── rng_streams.json
│   │   └── _schema/                  # JSON Schema for every source file above
│   │       └── *.schema.json
│   └── generated/
│       └── .gitkeep                  # generated GDScript lands in core/contracts/generated/
├── systems/                          # (empty) — no system exists in VS0
├── presentation/
│   └── boot/
│       └── boot.tscn                 # the one scene VS0 ships
├── content/                          # (empty)
├── tools/
│   ├── validators/
│   │   ├── validate_all.gd           # schema → semantic → canon, headless entry point
│   │   ├── schema_validator.gd
│   │   ├── canon_validator.gd
│   │   └── loc_validator.gd
│   ├── generators/
│   │   ├── generate_all.gd           # headless entry point
│   │   ├── canon_enum_generator.gd
│   │   ├── event_registry_generator.gd
│   │   └── input_actions_generator.gd
│   ├── lint/
│   │   ├── convention_lint.gd
│   │   └── layer_lint.gd
│   └── evidence/
│       ├── smoke_scene_load.gd
│       └── capture_boot_evidence.gd
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── canon/
│   └── fixtures/saves/
│       └── save_v1.json              # golden fixture v1 — FROZEN FOREVER
└── docs/
    ├── ENGINE.md                     # NEW — pinned versions, checksums, verification evidence
    ├── adr/ archive/ canon/
    └── (existing accepted documents)
```

**Two folders that do not exist yet and must not be created in VS0:** `systems/<anything>/` beyond
the empty root, and `content/<anything>/` beyond the empty root. The first system folder is created
by the first system, in VS1.

---

## 6. Exact Godot and project settings required

Every setting below is **mandatory and verified by test or by CI**, not left to whoever opens the
editor first.

### 6.1 Engine pinning (ADR-001 §1)

| Item | Rule |
|---|---|
| Engine | **Godot 4.7.2-stable**, standard build. **No .NET / no C#.** |
| Pre-release | **Godot 4.8 development and pre-release builds are NOT authorized.** |
| Exact version | `4.7.2-stable`, recorded verbatim in `docs/ENGINE.md`, `project.godot` (`config/features`) and `.github/workflows/ci.yml`. Codex never chooses it and never rounds it. |
| Export templates | **Godot 4.7.2, exactly equal to the editor version.** |
| **Version verification** | Codex **and** CI verify `editor version == template version == 4.7.2` **before any export**. On mismatch: **stop and report.** Do not export, do not substitute. |
| CI acquisition | CI downloads the pinned editor and templates from an **explicit official release URL**, verifies **SHA-256** against `docs/ENGINE.md`, and caches by version. **No `latest` URL. No floating version.** |
| Upgrades | Require a new ADR. Codex may never bump the engine, not even a patch release. |

> **On the "no dependency fetched at build time" rule** (clarified by owner decision, ADR-002 §2).
> That rule governs **project libraries, plugins and runtime dependencies** — everything the game
> links against or ships. There is exactly one, GUT, and it is **vendored and never downloaded by
> CI**. The **external toolchain** — editor and export templates — is a different category: CI may
> acquire it, and only under all four conditions above. Pinned, checksummed toolchain acquisition is
> reproducible; a `latest` URL is not, and is forbidden.

### 6.2 Renderer (ADR-001 §2)

| Setting | Value |
|---|---|
| `rendering/renderer/rendering_method` | `gl_compatibility` |
| `rendering/renderer/rendering_method.mobile` | `gl_compatibility` |

**VS0 renderer verification gate.** Under the pinned version and Compatibility, record PASS/FAIL for
each, with a screenshot artifact: `CanvasModulate` tinting · `Light2D` + `LightOccluder2D` shadows ·
2D normal maps · the blend/backbuffer modes needed by impact VFX · a screen-space post effect.

A FAIL is **evidence, not a blocker**: it is recorded in `docs/ENGINE.md` and reopens ADR-001 §2. It
is never worked around silently.

### 6.3 Pixel contract (Master Canon — Technical baseline; ADR-001 §3)

| Setting | Value |
|---|---|
| `display/window/size/viewport_width` | `320` |
| `display/window/size/viewport_height` | `180` |
| `display/window/size/window_width_override` | `1280` |
| `display/window/size/window_height_override` | `720` |
| `display/window/stretch/mode` | `canvas_items` |
| `display/window/stretch/aspect` | `keep` |
| `display/window/stretch/scale_mode` | `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | `Nearest` |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` |
| `rendering/2d/snap/snap_2d_vertices_to_pixel` | `true` |
| `application/config/name` | `Galapagos The Origin` |
| `application/run/main_scene` | `res://presentation/boot/boot.tscn` |

**Verified by test, not by inspection.** A canon test asserts each of these values by reading
`ProjectSettings`. A test — not a checklist item someone ticks.

**Also asserted by the same test:** the window is not resizable below one integer scale, and the
letterbox/pillarbox background is the approved black.

### 6.4 Settings that are deliberately NOT configured in VS0

Physics tick rate, audio bus layout, and rendering quality options are left at engine defaults. They
are tuned when there is something to tune them against. Setting them now would be a guess recorded
as a decision.

---

## 7. Autoloads introduced in VS0, and why

**Four of the approved eight.** Registration order matters and is fixed.

| Order | Autoload | Introduced in VS0 because | Would break if deferred |
|---|---|---|---|
| 1 | `EventBus` | `SaveManager` must announce completion without anything depending on it; the event registry and the orphan/phantom CI check are foundation | Every later system would wire direct references first and be refactored later |
| 2 | `GameState` | Save Core needs a real substate to persist; `GameState` is where substates live | Save Core would serialize something invented, then be rewritten at VS1 |
| 3 | `RngService` | Its seed state **is** save state (ADR-005 §6); tests need determinism from the first test | Adding it after saves exist is a `save_version` bump and a migration |
| 4 | `SaveManager` | ADR-005 §1 moves Save Core to VS0/VS1 precisely so no milestone defines durable state without persistence | This is the finding (AUD-006) that made save-first a decision |

**Deliberately NOT introduced in VS0:**

| Autoload | Waits for | Why waiting is correct |
|---|---|---|
| `SceneManager` | VS1 | VS0 ships one scene. A transition manager with nothing to transition between would be designed against zero requirements. |
| `TimeManager` | VS1 | Game time is meaningless before an overworld exists to advance it. `EnvironmentState` enters the save schema when `TimeManager` arrives — an ordinary `N → N+1` migration, which is exactly what the harness is for. |
| `AudioManager` | VS1 | Canon integrates audio incrementally. VS0 has nothing to play. |

**Autoload rules restated because they are violated by default:** autoloads **hold and expose**;
they do not implement game rules. `GameState` owns no rules. `SaveManager` is the **only** writer of
adventure files. `EventBus` carries past-tense events with **deferred** dispatch.

---

## 8. Data source / generated pipeline foundation

### 8.1 The pipeline

```
data/source/**.json          (AUTHORITATIVE, hand-authored, reviewed)
        │
        ├── schema validation        → tools/validators/schema_validator.gd
        ├── semantic validation      → referential integrity, ID rules
        ├── canon validation         → tools/validators/canon_validator.gd
        │
        └── generation               → tools/generators/generate_all.gd
                 │
                 └── core/contracts/generated/*.gd     (GENERATED, committed, never hand-edited)
```

### 8.2 Rules (ADR-004 §5, §7 — all already decided)

1. `data/source/` JSON is the **only** source of truth.
2. Generated artifacts derive from source and nothing else, and carry a header naming their source
   and the generator that produced them.
3. **Generated artifacts are committed** — so the editor and a fresh clone work without a build
   step — **and are never authority and never hand-edited.**
4. **CI gate 4:** `regenerate → compare → fail on drift`. Divergence is unmergeable by construction.
5. **Validation order is fixed: schema → semantic → canon.** A later stage never runs on data that
   failed an earlier one, so error messages stay meaningful.
6. Invalid data is a **build failure**, never a warning, never a runtime default.

### 8.3 What VS0 generates

| Generated file | From | Contains |
|---|---|---|
| `core/contracts/generated/canon_enums.gd` | `data/source/canon/*.json` | `TikawiType`, `SizeClass`, `BondState`, `MoveCategory`, `ResearchStage`, `OriginTag`, `RarityTier` |
| `core/contracts/generated/type_matrix_data.gd` | `canon/type_matrix.json` | the declared relationships as data **only** — no evaluation function |
| `core/events/event_registry.gd` | `_registry/events.json` | event name constants + payload documentation |
| `core/input/input_actions.gd` | `_registry/input_actions.json` | action name constants |

### 8.4 ID rules enforced from VS0 (ADR-004 §2)

`snake_case` strings · immutable · **never reused** · registered append-only in
`data/source/_registry/ids.json` · retired IDs move to `deprecated_ids` and are never deleted · no
positional index is ever identity · `codex_number` is presentation metadata and **must never** be
written into a save.

In VS0 `ids.json` is structurally complete and contains **no content IDs**. The registry exists
before the first ID, because the rule "never reused" is unenforceable if the registry starts late.

---

## 9. Canon Registry foundation

**This is the component that converts a canon omission from a silent gap into a failing build.** It
exists in VS0 because C-001 found that failure class twice — the type matrix and individual
personality were both missing from the compact canon and were caught by a human reading, not by a
machine.

### 9.1 What VS0 authors

| File | Content | Closed? |
|---|---|---|
| `types.json` | Exactly the 13 official types, canonical Spanish IDs | **Yes — exactly 13** |
| `type_matrix.json` | The declared `strong vs` / `weak vs` table, the step scale, and the rule metadata | **Yes** |
| `size_classes.json` | S, M, L, XL, LEGENDARY with overworld and battle canvases | **Yes** |
| `bond_states.json` | The five canonical Bond states | **Yes — exactly 5** |
| `move_categories.json` | Físico, Especial, Soporte, Control, Reacción | **Yes — exactly 5** |
| `research_stages.json` | The five research stages, ordered | **Yes — exactly 5** |
| `origin_tags.json` | NATIVO, ENDÉMICO, INTRODUCIDO, ORIGEN DESCONOCIDO | **Yes — exactly 4** |
| `rarity_tiers.json` | Canon rarity tiers | **Yes** |

Spanish canonical names are preserved **verbatim** as IDs (`CONVENTIONS.md` §1):
`&"psiquico"`, `&"reaccion"`, `BondState.RESONANCIA`. English is used only for things we invented.

### 9.2 Canon validators that ship in VS0

These are **permanent canon tests**. They never expire and are never "cleaned up".

| Check | Fails the build when |
|---|---|
| Type count | `types.json` does not contain exactly 13 entries |
| Forbidden types | Normal, Hada, Dragón, Fantasma, Luz, Roca or Viento appears |
| Matrix completeness | The matrix does not resolve to a full 13 × 13 = 169 cells |
| Multiplier set | Any cell resolves outside `{×2.00, ×1.50, ×1.00, ×0.67, ×0.40}` |
| **No immunities** | Any cell resolves to ×0 |
| Inverse-resistance rule | A derived resistance exists where the inverse direction is explicitly declared strong |
| **Mutual-strength count** | The number of mutually super-effective pairs is **not exactly 1** (Veneno ↔ Psíquico) |
| Computed totals | The resolved matrix is not **26 strong · 24 resistances · 119 neutral · 0 immunities** |
| Cycle integrity | `Lucha > Ancestral > Sombra > Psíquico > Lucha` is not closed |
| Bond states | The five canonical states are not exactly present |
| Size classes | A class is missing, or a canvas differs from the canon table |
| ID hygiene | Any ID is not `snake_case`, or is duplicated, or is absent from `ids.json` |

> The **mutual-strength count** and the **computed totals** checks are the ones worth understanding.
> They do not merely validate the data — they pin the *consequences* of the data. If someone later
> adds a strong relationship, the totals move and the build fails, forcing the change to be a
> deliberate owner decision rather than a quiet edit. That is Final §5 ("any matchup change after
> this point is game-balance design requiring owner approval") expressed as a test instead of a
> sentence.

### 9.3 What VS0 does NOT build

No damage formula. No effectiveness lookup function used by gameplay. No move data. No species data.
The registry is **data plus validators plus generated enums**. Evaluation is VS3.

---

## 10. Save Core foundation

Per ADR-005, Save Core lands now so that no later milestone closes with durable state that is
unpersisted and unmigrated.

### 10.1 Envelope

```
{
  "save_version":  1,
  "game_version":  "<from project.godot>",
  "created_at":    "<ISO-8601 UTC>",
  "updated_at":    "<ISO-8601 UTC>",
  "schema_hash":   "<sha256 of the persisted schema shape>",
  "checksum":      "<sha256 of the payload>",
  "payload":       { "rng": { ... } }
}
```

- Format: **JSON**. Not `.tres` (resource loading resolves script paths — an unnecessary hazard for
  a file the player can edit), not opaque binary (undiagnosable in the field).
- `save_version` is **independent** of `game_version`.
- The checksum detects **corruption, not tampering**. There is no anti-cheat. A hand-edited save
  that validates structurally loads normally.

### 10.2 Windows-correct atomic write (ADR-005 §4)

The POSIX `write-temp → rename-over` idiom is **not** safely portable to Windows. The required
sequence:

```
write temp → flush + close → re-read and verify checksum
→ rotate current to backup → move temp into place → verify → clean up
```

- The backup is **never** destroyed before the new file verifies.
- Rename failure (AV scanner, file lock) is an **expected case with bounded retry**, not an
  exception that escapes.
- **Mandatory VS0 test:** simulate interruption at **every** step of that sequence and assert that a
  loadable save always remains. This is the test that protects a player's progress, and it is
  written before there is any progress to protect.

### 10.3 Runtime state ≠ save DTO (ADR-005 §2)

| | Runtime state | Save DTO |
|---|---|---|
| Lives in | `core/state/` | `core/save/dto/` |
| Freedom | refactor freely | changes only with a version bump + migration |
| Mapping | explicit `to_save_dict()` / `from_save_dict(data, version)` — never automatic serialization |

**Admission rule:** no field enters the DTO without a written justification that it is a *durable
consequence*. In VS0 exactly one substate is persisted: `RngState`.

**Never persisted:** node references · derived values · caches · presentation state · the `cosmetic`
RNG stream · settings and key rebindings (separate config file, so changing options never touches a
save).

### 10.4 Migrations, fixtures and the schema-hash guard

| Item | Rule |
|---|---|
| Chain | Sequential `N → N+1`. No version-skipping migrations. |
| Harness | **Functioning but empty** in VS0 — registered, tested with a synthetic `v0 → v1` case, and proven to run. |
| **Golden fixture v1** | A real `save_version: 1` file frozen at `tests/fixtures/saves/save_v1.json`. **Never regenerated. Never edited.** |
| CI gate 8a | Load every historical fixture, migrate to current, assert **semantic** invariants. "It didn't crash" is not a pass. |
| CI gate 8b | **Schema-hash guard.** If the persisted schema changes without a `save_version` bump and a registered migration, the build fails. |
| Forward saves | A future-version save is **rejected cleanly** — never partially read, never overwritten. |

> Gate 8b is what makes "no persisted change without a migration" impossible to forget, **including
> by an agent.** It is mechanical, not discretionary, and it is the single highest-value test in
> VS0.

### 10.5 Settings file — separate, deliberately

Settings, locale choice, accessibility options and (from VS9) key rebindings live in
`user://settings.cfg`, **outside the save**. Changing an option must never risk player progress. VS0
creates the file and writes exactly two keys: locale and presentation mode default.

---

## 11. RNG foundation

### 11.1 Streams (ADR-005 §6)

Named, independent streams declared in `data/source/_registry/rng_streams.json`:

| Stream | Persisted | Notes |
|---|---|---|
| `battle` | Yes | |
| `encounter` | Yes | |
| `weather` | Yes | |
| `loot` | Yes | |
| `cosmetic` | **No** | Non-deterministic, and **must never** influence game state |

Streams are independent so that consuming randomness in one system cannot shift another's outcomes —
the classic cause of tests that "break by themselves".

### 11.2 Rules

- Master seed and per-stream counters are **persisted** (except `cosmetic`) — this is `RngState`,
  the one substate VS0 implements.
- **Forbidden:** global `randi()`, `randf()`, `randomize()` or `RandomNumberGenerator` instantiation
  anywhere outside `core/rng/`. **CI grep, gate 1.**
- Reproducibility test: same master seed + same call sequence → identical outputs, **and identical
  outputs after a save/load round trip**. That second half is the one that catches the real bug.

---

## 12. Localization foundation

Canon requires ES/EN from day one. Retrofitting `tr()` across authored content is a rewrite;
starting with it costs nothing.

| Item | Decision |
|---|---|
| Mechanism | Godot's built-in `TranslationServer` + `tr()`. **No `LocalizationManager` autoload** (ADR-003 §4). |
| Source | `data/source/loc/system.csv`, columns `key,es,en` |
| Import | Godot's CSV translation importer. The produced `.translation` resources are engine import artifacts under `.godot/` and are **not** committed; the `.import` files **are** committed (ADR-002 §1). |
| Helper | `core/loc/loc.gd` — locale selection, fallback to `en`, key existence query. A Core helper, not a global. |
| Default locale | `es`, with `en` fallback |
| Keys | **Generated from IDs**, never hand-written (ADR-004 §5 rule 11). VS0 authors only `ui.*` and `system.*` system keys. |
| Proper nouns | Canonical proper names are listed **non-translatable**; CI fails if their value differs between locales. The list exists in VS0 and is populated as content arrives. |

**VS0 validator (`loc_validator.gd`), runs in gate 3:** every key present in every locale · no orphan
keys · no empty values · no proper noun differing between locales · no literal user-facing string in
any `.gd` or `.tscn` outside `tools/` and `tests/`.

That last check is the one that keeps localization honest, and it is far cheaper to satisfy from an
empty repository than from a populated one.
---

## 13. Input / controller foundation

VS1's first deliverable is movement. Movement bound to raw keys instead of named actions makes VS9
rebinding a rewrite of every input site, and makes controller support an afterthought.

### 13.1 What VS0 delivers

| Item | Decision |
|---|---|
| Action vocabulary | A **closed list**, declared in `data/source/_registry/input_actions.json`, generated into `core/input/input_actions.gd` as constants, and written into `project.godot`'s InputMap |
| Bindings | Keyboard **and** gamepad bound for every action, in VS0 |
| Device kind | `core/input/input_device.gd` tracks the **last-used device kind** (`KEYBOARD` / `GAMEPAD`) and emits `input_device_changed` |
| Rebinding | **Not in VS0.** VS9. The action indirection is what makes VS9 cheap. |
| Raw key reads | **Forbidden** outside `core/input/`. CI grep for `Input.is_key_pressed`, `InputEventKey` and raw joypad reads — gate 1. |

### 13.2 The VS0 action list

Closed for VS0. Adding an action is a registry entry plus a binding, reviewed like any data change.

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_up` / `move_down` / `move_left` / `move_right` | W/A/S/D **and** arrows | left stick + D-pad |
| `confirm` | Enter, Space | A / cross |
| `cancel` | Esc, Backspace | B / circle |
| `menu` | Tab | Start |
| `interact` | E | X / square |
| `page_left` / `page_right` | Q / E… | L1 / R1 |
| `debug_toggle` | F1 | — |

> `page_left` / `page_right` exist in VS0 for one reason: the reserve is **paged and filterable**
> (Master Canon — Team and reserve capacity). Declaring the actions now costs two lines and prevents
> the VS8/VS9 reflex of binding paging to whatever key is free.

### 13.3 Why device-kind detection is VS0 and not VS9

Prompt glyphs ("press A" vs "press Enter") are a presentation concern, but *which device is active*
is a piece of infrastructure every UI screen from VS1 onward will ask for. Adding the query later
means auditing every prompt. It is twenty lines now.

---

## 14. Test framework setup

| Item | Decision |
|---|---|
| Framework | **GUT**, approved (Final §6). No alternative is evaluated. |
| Location | `addons/gut/`, **vendored**, committed |
| Version | The GUT release whose declared compatibility matches **Godot 4.7**. If several qualify, take the **highest patch**. Vendored, never downloaded by CI. Recorded in `docs/ENGINE.md`. **This is a rule, not a choice.** |
| Network | **None** at build or run time |
| Execution | Headless CLI, JUnit XML output attached as a CI artifact |
| Directories | `tests/unit/`, `tests/integration/`, `tests/canon/` |

**VS0 pin gate (ADR-002 §3):** the pinned GUT release must run headless against **Godot 4.7.2-stable**
before the GUT pin is final. On incompatibility, **the engine pin wins** — 4.7.2 does not move — and
the GUT version is re-examined under the same rule.

**Test naming and structure** follow `CONVENTIONS.md` §4. Tests in `tests/canon/` are **permanent** —
they are never deleted, never skipped, and never weakened to make a build pass.

---

## 15. Validator framework

Validators are **project-owned, with no dependency** (ADR-002 §4). They encode domain rules no third
party can supply, and they are how canon becomes verifiable.

### 15.1 Structure

```
tools/validators/validate_all.gd     # headless entry point; runs the three stages in order
├── schema_validator.gd              # stage 1: JSON Schema conformance
├── semantic_validator.gd            # stage 2: referential integrity, ID rules, uniqueness
├── canon_validator.gd               # stage 3: the canon invariants in §9.2
└── loc_validator.gd                 # stage 3: localization invariants in §12
```

### 15.2 Rules

1. **Order is fixed and short-circuiting:** schema → semantic → canon. A later stage never runs on
   data that failed an earlier one, so the first error message is the true one.
2. **Output is a machine-readable report** (`validation_report.json`) plus human-readable stdout.
   Both are CI artifacts.
3. **Every failure names the file, the JSON pointer, the rule that failed and the authority that
   requires it** (e.g. `canon/type_matrix.json #/psiquico/strong_vs — mutual-strength count is 2,
   expected exactly 1 — Master Canon, Type effectiveness rule 6`). A validator that says "invalid
   data" is a defective validator.
4. Validators run **headless** and in the **editor**. Same code, both entry points.
5. **Exit code is the contract:** `0` = pass, non-zero = fail. CI needs nothing else.

### 15.3 The two lints

| Lint | Gate | Checks |
|---|---|---|
| `convention_lint.gd` | 1 | static typing on every declaration and return · naming per `CONVENTIONS.md` §2.2 · file ≤ 500 lines · forbidden patterns: global RNG, raw key reads, `species_id ==` branching, literal user-facing strings, `print(` outside `tools/`, deprecated `TileMap` |
| `layer_lint.gd` | 2 | builds the dependency graph from `preload`, `load`, `class_name` references and type annotations, grouped by root folder, and **fails on any upward edge** |

**Layer lint specifics, so it is not re-invented:**

- Allowed edges: `presentation → systems`, `presentation → core`, `systems → core`,
  `systems → data`, `core → data`, `autoload → systems`, `autoload → core`.
- **Everything else is a failure.** Especially `systems → presentation`, which is the one that
  destroys headless-testable battle logic.
- `tools/` and `tests/` are outside the layer graph and may reference anything.
- **Approved exceptions live in one list in `ARCHITECTURE.md` §1 and nowhere else.** An exception
  not on that list is a build failure, **not a judgement call**, and Codex may not add one.
- The lint reports the **file, line and the offending edge**. A lint that cannot be acted on gets
  disabled, and a disabled layer lint is an architecture with no layers.

---

## 16. CI workflow

`.github/workflows/ci.yml`, GitHub Actions, `windows-latest`, triggered on pull request and on push
to `main`.

### 16.1 Job order — cheapest first (ADR-002 §6)

| Step | Gate | Fails the build when |
|---|---|---|
| 0 | — | Checkout with `lfs: true`; restore from cache or download **Godot 4.7.2-stable** editor + **4.7.2** templates from an explicit pinned URL; **verify SHA-256**; assert `editor == templates == 4.7.2`. **GUT is never downloaded — it is vendored.** |
| 1 | **Gate 1** | Convention lint reports any violation |
| 2 | **Gate 2** | Layer dependency lint reports any upward edge |
| 3 | **Gate 3** | Data validation fails at any stage (schema → semantic → canon → localization) |
| 4 | **Gate 4** | Regenerating from source produces a diff against committed generated artifacts |
| 5 | **Gate 5** | GUT headless reports any failing or errored test |
| 6 | **Gate 8** | Golden-fixture migration or the schema-hash guard fails |
| 7 | **Gate 7** | Scene-load smoke test reports any script error |
| 8 | **Gate 6** | Windows export fails, or the exported binary does not launch headless |
| 9 | — | Upload artifacts (§19) |

> Gates 8 and 7 run **before** the export step even though their canonical numbers are higher,
> because a failing save migration should not wait behind a five-minute export. Gate *numbers* are
> identity (they are referenced across every ADR); gate *order* is a performance decision. Both are
> stated here so the difference is deliberate rather than confusing.

Gates **9, 10 and 11** (localization content, canon boundaries, reachability) do not run in VS0
because the systems they check do not exist. Their workflow steps are **not** stubbed — an
always-green gate is worse than an absent one.

### 16.2 Branch protection (ADR-002 §1)

Branch protection is applied in **two phases**, because required status checks cannot reference
workflows that do not yet exist.

**Phase 1 — enforced by a repository RULESET (ADR-002 §1.3), proven by VS0-T01R:**

| Rule | Value |
|---|---|
| Visibility | **PUBLIC** (ADR-002 §1.1). Everything committed is published. |
| **Enforcement mechanism** | **GitHub repository ruleset**, `enforcement: "active"`, targeting `refs/heads/main`. **Classic branch protection is not authoritative** — see the incident note below. |
| `main` | **Protected.** No direct pushes, by anyone — owner, admin or agent. |
| Merge | Pull request only — `pull_request` rule present |
| `required_approving_review_count` | **0** — see the solo-owner note below |
| **`bypass_actors`** | **`[]` — empty, and it stays empty.** No bypass actor is authorized for direct pushes to `main`. |
| Force-push to `main` | **Blocked** — `non_fast_forward` rule |
| Deletion of `main` | **Blocked** — `deletion` rule |
| Branches | `feature/<task-id>-<slug>`, `fix/<task-id>-<slug>`, `docs/<amendment-id>-<slug>` |
| Parallel agents | **One writing agent per git worktree, always** |
| Required status checks | **Deliberately not configured.** No VS0 workflow exists yet, so there is no stable check name to require. |

> **Enforcement incident — read this before configuring anything (§32, ADR-002 §1.3).** Phase 1 was
> originally enforced by **classic branch protection**. With `required_approving_review_count` at
> `0`, a direct push to `main` was **accepted** while every setting still read back as specified.
> Under classic protection the pull-request requirement lives *inside* the review object; emptying
> that object left no condition for a push to violate, and `enforce_admins` cannot enforce a rule
> that evaluates to nothing.
>
> A-02's claim that setting the count to 0 removes the approval requirement *"and nothing else"* is
> **withdrawn as false.** In a ruleset, `pull_request` is an independent rule, which is why the
> mechanism changed.
>
> **Configuration evidence is not enforcement evidence.** Phase 1 is satisfied only when a live
> **unassociated** push has been **observed to be rejected** — never by reading the settings back.

> **What Phase 1 guarantees, precisely (A-04, ADR-002 §1.4).** The `pull_request` rule requires that
> changes reaching `main` be **associated with an open pull request**. It does **not** reject every
> direct `git push`: **a commit that is already the head of an open PR targeting `main` may be pushed
> directly and accepted**, because GitHub considers it associated. That is documented behaviour, not
> a bypass.
>
> | | |
> |---|---|
> | A commit with **no** open PR reaches `main` | **Rejected** (proven by E1A) |
> | A commit that **is** an open PR's head, pushed manually | **GitHub accepts it — project process forbids it** |
> | Force push · deletion | **Rejected** |
>
> **"All direct pushes are technically impossible" is not achievable** on this solo-owner / GitHub
> Free configuration without the **Restrict updates** rule, and **Restrict updates is not
> authorized** — it would block legitimate PR merges. The residual gap is closed by process:
> **never push to `main`, even when GitHub would accept it.**

> **Why zero approvals, and what it does not mean (ADR-002 §1.2).** The repository has one eligible
> GitHub account, and GitHub does not let a pull request's author approve their own PR. A non-zero
> count makes **every** PR permanently unmergeable. Setting it to 0 removes GitHub's mechanical
> approval count **and nothing about who may push** — under the ruleset, the `pull_request` rule
> blocks direct pushes independently of the approval count.
>
> **Review remains mandatory as process:** *Codex implements → Claude reviews → owner authorises
> merge.* Merging without Claude's review is a process violation. When a second eligible account
> exists, restoring the count to 1 is a settings change plus an ADR revision.

**Phase 2 — T14, once the real workflows exist:**

| Rule | Value |
|---|---|
| Required status checks | **Every VS0 gate, by its exact stable check name**, as produced by the workflow T14 committed |
| Path scope | CI verifies the PR diff touches nothing outside the task packet's `ALLOWED PATHS` |

> **No temporary, bootstrap or placeholder check is authorized at any point.** A stand-in check would
> mean either inventing a CI architecture before the gates exist, or requiring a check whose name
> changes when the real workflow lands — and a required check whose name moves silently stops being
> required. The gap between T01 and T14 is closed by running the gates **locally** through the same
> headless entry points CI will call, and by T14's deliberate-failure branches, which prove
> retroactively that every gate fires.

`main` stays buildable throughout. **A red gate blocks merge and is never "fixed" by weakening the
test.** If the implementation violates the spec, fix the implementation; if the spec changed, update
the authority document first.

---

## 17. Windows export configuration

| Item | Decision |
|---|---|
| Preset | `Windows Desktop`, named `windows-vs0`, committed in `export_presets.cfg` |
| Architecture | `x86_64` |
| Mode | Debug export in CI (release signing and packaging are VS11) |
| Embed PCK | No — separate `.pck`, which makes the export diffable and the failure legible |
| Templates | **Godot 4.7.2 templates**, installed to the path CI expects. **Version equality is verified before export; a mismatch stops the task.** |
| Output | `export/windows/galapagos.exe` (+ `.pck`), **gitignored**, uploaded as an artifact |
| Verification | The exported binary is launched headless with `--quit-after` and must exit `0` |

**Why the export runs in VS0 rather than VS11:** an export that has never been run is an export that
does not work. Export failures are usually configuration (templates, paths, import artifacts), and
they are trivial to fix in an empty project and miserable to fix in a full one.

---

## 18. Smoke verification strategy

Three layers, cheapest first. All run headless. None requires a human.

### 18.1 Boot verification

`presentation/boot/boot.tscn` is the project's main scene and the only scene VS0 ships. Headless, it:

1. boots with all four autoloads registered, in order;
2. loads generated canon enums and asserts the type count is 13;
3. initializes `RngService` from a fixed master seed;
4. writes a save, reads it back, and asserts semantic equality;
5. prints a structured `BOOT OK` report with the engine version, `save_version` and `schema_hash`;
6. exits `0`.

Any failure exits non-zero with the failing step named. **This single scene is the end-to-end proof
that VS0's parts are connected**, not merely present.

### 18.2 Scene-load smoke test (gate 7)

`tools/evidence/smoke_scene_load.gd` loads **every** `.tscn` in the repository headless and fails on
any script error, missing dependency or broken resource path. In VS0 that is one scene. It is worth
writing now because it costs nothing now and catches the class of failure that otherwise appears
when there are eighty scenes and nobody knows which one broke.

### 18.3 Visual evidence

`tools/evidence/capture_boot_evidence.gd` runs the boot scene windowed at exactly `1280 × 720`
(×4 integer scale) and writes:

- `evidence/boot_1280x720.png` — proves integer scaling and Nearest filtering visually;
- `evidence/renderer_features.png` — the §6.2 renderer feature checks, rendered in one frame;
- `evidence/pixel_grid_1366x768.png` — proves centred letterboxing at the awkward resolution.

Uploaded as CI artifacts. **Reviewed by Luisma. Never certified by an agent.**

---

## 19. Evidence / artifacts required

Every VS0 pull request attaches, automatically, from CI:

| Artifact | Produced by | Proves |
|---|---|---|
| `convention_lint.txt` | gate 1 | Conventions hold |
| `layer_lint.txt` + `layer_graph.json` | gate 2 | No upward dependency edge exists |
| `validation_report.json` | gate 3 | Source data is schema-, semantically- and canon-valid |
| `generated_diff.txt` | gate 4 | Committed generated artifacts match a fresh regeneration |
| `gut_results.xml` (JUnit) | gate 5 | Every test, with names, ran and passed |
| `save_migration_report.txt` | gate 8 | Every golden fixture migrates to current with invariants intact |
| `schema_hash.txt` | gate 8b | The persisted schema hash, and whether it changed |
| `smoke_scene_load.txt` | gate 7 | Every scene loads without error |
| `export_log.txt` + exported binary | gate 6 | Windows export succeeds and the binary launches |
| `evidence/*.png` | §18.3 | The pixel contract and renderer features, visually |
| `boot_report.txt` | §18.1 | The foundation is connected end to end |

**The rule these artifacts exist to enforce (ADR-002 §5):**

> **Agents never self-certify a PASS. Evidence is an artifact.** A task is not done because Codex
> says it is done. It is done because CI produced the artifact and the artifact says so.

Anything requiring human judgement — how the pixel grid *looks* — is evidenced by a screenshot and
reviewed by **Luisma**.

---

## 20. Definition of Done

VS0 is complete when **every** line below is true and demonstrated by an artifact. This is a
checklist for acceptance, not a summary.

**Repository**
1. **Public** GitHub repository exists at `GITHUB_OWNER/GITHUB_REPOSITORY`; `main` is protected by
   an **active repository ruleset** with `bypass_actors: []`; every change reaching `main` is
   **associated with a pull request**; `required_approving_review_count` is **0**; force-push and
   deletion of `main` blocked; **Restrict updates is absent**.
   **Each is demonstrated by a live negative test, not by a settings dump** — a rejected
   **unassociated** push (E1A), a rejected force-push (E3), a rejected deletion (E4), and one PR
   merged with zero approvals (E2), plus the ruleset readback (E5) — VS0-T01R, §23 and §32.7.
   *(Required status checks are Phase 2 — criterion 24.)*
2. `.gitattributes` declares Git LFS for `*.png`, `*.ogg`, `*.wav`, `*.aseprite`.
3. `.gitignore` excludes `.godot/`, `export/`, `evidence/`, `*.tmp`; `*.import` files **are**
   committed.

**Engine and project**
4. `docs/ENGINE.md` records the exact Godot version, the export-template version, the GUT version,
   and SHA-256 checksums for each.
5. The project boots headless on the owner machine **and** on the CI runner.
6. A canon test asserts every `project.godot` value in §6.2 and §6.3 — renderer, viewport, stretch,
   scale mode, filter, snapping, main scene.
7. The renderer feature verification (§6.2) is recorded in `docs/ENGINE.md` with screenshots.

**Architecture**
8. The folder tree in §5 exists, each folder carrying a one-line `README.md` naming owner and layer.
9. Exactly **four** autoloads are registered, in the order in §7.
10. The layer lint runs, reports a clean graph, and **has been proven to fail** on a deliberately
    introduced upward edge (the negative test is committed as a test, not performed by hand).

**Data and canon**
11. Every file in §9.1 exists, is schema-valid, and passes every canon check in §9.2.
12. `ids.json` exists, is append-only, and is structurally complete with no content IDs.
13. Generated artifacts exist, carry their autogenerated header, and match a fresh regeneration.
14. The canon validator **has been proven to fail** on a deliberately broken copy of
    `type_matrix.json` (committed as a test).

**Persistence**
15. A save can be written, read back and semantically compared.
16. The interruption test (§10.2) covers **every** step of the atomic-write sequence.
17. Golden fixture v1 is frozen in `tests/fixtures/saves/` and migrates to current.
18. The schema-hash guard **has been proven to fail** on an unversioned schema change (committed as
    a test).
19. A forward-version save is rejected cleanly and the existing file is untouched.

**RNG**
20. Same seed + same call sequence → identical output, **including across a save/load round trip**.
21. Global RNG use is rejected by gate 1 (proven by a negative test).

**Localization and input**
22. `system.csv` has full ES/EN parity; the loc validator passes; no literal user-facing string
    exists outside `tools/` and `tests/`.
23. Every action in §13.2 is bound for keyboard **and** gamepad; device-kind detection reports
    correctly; raw key reads are rejected by gate 1.

**CI and export**
24. The workflow runs gates 1–8 (excluding 9–11) and is green on `main`, **and** branch protection
    now requires every gate by its exact check name, proven by all four cases: a PR with every
    required check green **can** merge · a PR with a required check failing **cannot** · a PR with a
    required check missing or pending **cannot** · a direct push to `main` remains blocked.
25. Windows export succeeds and the exported binary exits `0`.
26. Every artifact in §19 is attached to the PR.

**Evidence**
27. Boot report shows `BOOT OK` with engine version, `save_version` and `schema_hash`.
28. Pixel evidence screenshots at `1280×720` and `1366×768` are attached and **approved by Luisma**.

> Items 10, 14, 18 and 21 are the ones worth insisting on. A gate that has never failed is a gate
> nobody has tested. **Every control in VS0 ships with a committed negative test proving it fires.**

---

## 21. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| 1 | Pinned GUT release is incompatible with the pinned Godot version | **High** | §14 pin gate resolves it before either pin is final; **the engine pin wins** |
| 2 | Export templates drift from the editor version | **High** | Both pinned with checksums in `docs/ENGINE.md`; CI verifies before exporting |
| 3 | A required 2D feature is unavailable under Compatibility | **High** | §6.2 verification gate runs in VS0, before any presentation work; a FAIL reopens ADR-001 §2 rather than being worked around |
| 4 | The layer lint produces false positives and someone disables it | **High** | Approved-exception list reviewed, never suppressed; failures name file, line and edge; **Codex may not add an exception** |
| 5 | VS0 grows into VS1 — "we need a player to test movement input" | **High** | §3 is explicit; §23 task packets carry `FORBIDDEN PATHS`; CI checks the diff scope |
| 6 | Save Core is built against an invented substate and rewritten at VS1 | Medium | Exactly one substate, `RngState`, which is genuinely durable and genuinely VS0's own |
| 7 | The canon registry ossifies before content exists | Medium | Only **closed canon enumerations** are registered — the sets canon already declares as exhaustive. Nothing open-ended is registered in VS0. |
| 8 | Generated artifacts are hand-edited "just this once" | Medium | Gate 4 regenerate-and-diff makes it unmergeable; autogenerated headers make it visible |
| 9 | CI becomes slow enough that gates get bypassed | Medium | Cheapest-first ordering; engine binary cached by version; VS0 runs 8 gates, not 11 |
| 10 | The Windows atomic write fails intermittently under antivirus | Medium | §10.2 explicit sequence with bounded retry; backup preserved; interruption test at every step |
| 11 | Codex hits an unstated decision and fills the gap reasonably | **High** | §27 decision-free audit; every task carries `STOP CONDITIONS`; **filling a gap is itself a stop condition** |
| 12 | The pinned engine version turns out to have a blocking bug | Low–Medium | Version change requires an ADR; the pin is recorded with evidence, so the decision is auditable rather than silent |
| 13 | Git LFS quota or clone size becomes painful | Low | No binary assets exist in VS0; reviewed at VS10 |

---

## 22. Stop Conditions

**Codex stops immediately, reports, and does not proceed, when any of these occurs.** These are not
escalation suggestions. They are halts.

| # | Stop condition |
|---|---|
| 1 | A task requires a decision this document does not make — including a value, a name, a threshold, a file format or a library |
| 2 | This specification contradicts an ADR, `ARCHITECTURE.md`, `CONVENTIONS.md` or the Master Canon |
| 3 | Two accepted documents contradict each other |
| 4 | A canon rule cannot be implemented as specified |
| 5 | The pinned Godot version and the pinned GUT version are incompatible |
| 6 | A required 2D feature is missing under the Compatibility renderer |
| 7 | Implementing a task as written would require an upward layer dependency |
| 8 | A task would require a fifth autoload |
| 9 | A task would require changing the persisted schema without a `save_version` bump |
| 10 | A test fails and the only available fix is to weaken or skip the test |
| 11 | A task cannot be completed within its `ALLOWED PATHS` |
| 12 | The work would exceed VS0 scope as defined in §2 and §3 |
| 13 | **The implementation would differ from currently accepted authority — even when the owner has stated the new intent conversationally** (see the rule below) |

> **Stop condition 13 — a conversational decision is not an amendment.** If Luisma says something in
> conversation that differs from an accepted document — a different repository visibility, a
> different value, a different rule — that is an instruction to **amend the document**, not
> permission to implement the difference. Report the divergence and stop until the authority document
> has been updated. The order is always **decide → amend the authority → implement**, and it does not
> change because the owner is the source of the change.
>
> Reporting *"architecture deviations: none"* while the implementation differs from accepted
> authority is a reporting defect in its own right, independent of whether the difference is later
> approved. Recorded from VS0-T01 (§31.3).

| # | Stop condition |
|---|---|
| 14 | **A control, gate or protection cannot be shown to fire.** Reading the configuration back is not proof. If the negative test does not fail as expected — the push is accepted, the lint passes broken input, the guard does not trip — **stop and report.** Do not proceed on the assumption that it works. |

> **Stop condition 14 — configuration evidence is not enforcement evidence.** A settings dump proves
> what was requested, not what the platform does. This is the rule VS0 already applied to code
> (*"a gate that has never failed is a gate nobody has tested"*, §20) and failed to apply to
> repository configuration, at the cost of an accepted direct push to `main` (§32). It now applies to
> both. **Never record a protection as satisfied because it was configured.**

**The reporting format on a stop:** what was attempted · which document and section caused the stop ·
what the two conflicting requirements are · what Codex would need in order to proceed. **No proposed
resolution is implemented.** A stop that arrives with the fix already applied is a violated stop.

> This is the control that matters most in VS0. A competent agent does not halt at a gap — it fills
> it reasonably, and the reasonable fill becomes de-facto architecture that every later correction
> has to fight. **Stopping is the deliverable.**
---

## 23. Codex task decomposition

**Fifteen packets.** Packet weight is chosen by risk, not by size:

| Weight | Used for | Fields |
|---|---|---|
| **Lightweight** | Mechanical work with no architectural or persistence surface | ID · Objective · Reading · Dependencies · Paths · Requirements · Tests · Acceptance · Parallel |
| **Full** | Architecture, persistence, or a cross-module boundary | all of the above plus Persistence Impact and task-specific Stop Conditions |

The global stop conditions in §22 apply to **every** task, lightweight or full. Task-level stop
conditions are additions, never replacements.

**Two framework rules that exist to remove merge conflicts between parallel tasks:**

1. `tools/generators/generate_all.gd` **discovers** generators by scanning
   `tools/generators/*_generator.gd` for a common entry point. Adding a generator is adding a file.
   **No task edits another task's registration.**
2. `tools/validators/validate_all.gd` discovers validators the same way, ordered by a declared stage
   constant (`SCHEMA`, `SEMANTIC`, `CANON`) rather than by call order in a shared file.

---

### VS0-T01 — Repository bootstrap · *Lightweight · Level 0*

> **STATUS: NOT ACCEPTED (A-03).** The four repository files are correct and are **on `main`**, but
> they arrived by a **direct push that branch protection should have rejected** (§32). The content is
> authorised; the path was not. Three of the acceptance criteria below — direct push rejected,
> force-push blocked, deletion blocked — were **reported as satisfied on the strength of a settings
> dump and are now known to be false**. They are re-proven by **VS0-T01R**, and T01 is accepted only
> when T01R passes. **T01 is not re-implemented and its history is not rewritten.**

| Field | Content |
|---|---|
| **Objective** | Create the **public** repository, Phase-1 branch protection, ignore/attribute files, README and PR template. **No Godot content. No CI workflow. No required status checks.** |
| **Required reading** | ADR-002 §1, §2 |
| **Dependencies** | None. **Bootstrap inputs (§4, both SUPPLIED):** `GITHUB_OWNER` = `inmoaiasistente-luisma`, `GITHUB_REPOSITORY` = `galapagos-the-origin`. Use these exact values; invent nothing. |
| **Allowed paths** | `/.gitignore` `/.gitattributes` `/README.md` `/.github/PULL_REQUEST_TEMPLATE.md` |
| **Forbidden paths** | `/.github/workflows/**` *(owned by T14)* · everything else |
| **Implementation requirements** | **Public** repo at `GITHUB_OWNER/GITHUB_REPOSITORY` (ADR-002 §1.1) — **use the supplied values exactly (§4); invent no account, organization or placeholder name** · default branch `main` · `main` protected, no direct pushes by anyone · PR-only merge · **`required_approving_review_count` = 0** · **`enforce_admins` = true** · **force-push to `main` blocked** · **deletion of `main` blocked** · branch naming `feature/<task-id>-<slug>`, `fix/<task-id>-<slug>` · `.gitattributes` declares LFS for `*.png`, `*.ogg`, `*.wav`, `*.aseprite` · `.gitignore` excludes `.godot/`, `export/`, `evidence/`, `*.tmp` and **does not** exclude `*.import` · `README.md` · PR template carrying the task packet's Acceptance Criteria and required evidence · repository visibility and settings evidence captured. **Configure NO required status checks, and create NO workflow file — `/.github/workflows/**` belongs to T14.** |
| **Tests** | None (no code). **File contents** verified by inspection. **Enforcement** is not verified here — see VS0-T01R. A settings dump is not a test. |
| **Acceptance criteria** | **Satisfied by T01:** repository is **public** · default branch is `main` · `git check-attr` confirms the LFS patterns · `.gitignore` excludes `.godot/`, `export/`, `evidence/`, `*.tmp` and **does not** exclude `*.import` · README present and pointing at `ARCHITECTURE.md` §16 · PR template present with Task / Worktree / Commit(s) / Files created / Files modified / Summary / Acceptance / Verification / Evidence / Impact declarations.<br><br>**Moved to VS0-T01R by A-03** — these are enforcement properties and **a settings dump does not prove them**: a direct push to `main` is rejected · `main` cannot be force-pushed · `main` cannot be deleted · a change to `main` is possible only through a pull request · a PR merges with **0** approving reviews.<br><br>**Required CI status checks are intentionally deferred until T14, when the real VS0 workflows and their stable check names exist.** Their absence at T01 is an approved deferral, **not** a failed acceptance criterion. |
| **Persistence impact** | None |
| **Approved deferred hardening** | **Required status checks → T14.** Recorded here as an owner-approved deferral. It is **not technical debt**, it is **not an architecture deviation**, and it must not be reported as either. The hardening is complete when criterion 24 of §20 passes. |
| **Parallelization** | Blocks everything. Nothing runs beside it. |
| **Stop condition** | The repository's actual state differs from this packet in any way this packet does not authorize — **report the divergence and stop before changing it**, even if Luisma has described the difference conversationally (§22 condition 13). Both bootstrap inputs are supplied (§4); invent neither. |

---

### VS0-T01R — Repository enforcement remediation · *Full · Level 1*

> **This is not a re-implementation of T01.** The four repository files are already on `main` and are
> correct. T01R exists **only** to install the corrected enforcement mechanism and to **prove by live
> negative test** that it works. It creates no gameplay, no engine, no workflow and no architecture.

| Field | Content |
|---|---|
| **Objective** | Install the Phase-1 **repository ruleset** (ADR-002 §1.3) and **prove** — by observed rejection, not by configuration — that direct push, force-push and deletion of `main` are refused, and that a PR merges with **0** approving reviews. |
| **Required reading** | **ADR-002 §1.3** (the incident and the exact ruleset) · §16.2 of this document · **§32** · `CONVENTIONS.md` §5 |
| **Dependencies** | VS0-T01 content is on `main` (it already is). **Blocks every other VS0 task**: nothing else merges until enforcement is proven. |
| **Allowed paths** | `/README.md` — **one line only**, recording the enforcement mechanism. Nothing else. |
| **Forbidden paths** | `/.github/workflows/**` *(T14)* · `/docs/**` *(Claude and Luisma only)* · every other path |
| **Branch** | `feature/VS0-T01R-enforcement-verification` |
| **Implementation requirements** | **(a)** A repository ruleset exists exactly as specified in ADR-002 §1.3 — `enforcement: "active"`, target `refs/heads/main`, rules `pull_request` (`required_approving_review_count: 0`), `non_fast_forward`, `deletion`, and **`bypass_actors: []`**. **(b)** A single harmless, authorised line is added to `README.md` recording that `main` is enforced by a repository ruleset and pointing at ADR-002 §1.3 — this is the change that travels through the proof, and it is real content rather than a throwaway. **(c)** The five acceptance tests below are executed **from the owner/admin account**, because that is the account whose push was wrongly accepted. **(d)** Verbatim command output is captured for each. |
| **Tests** | The acceptance tests are the deliverable. There is no code to unit-test. |
| **Results already accepted (A-06, 2026-09-13)** | **E1A = PASS · E2 = PASS · E3 = PASS.** These are **accepted and must not be rerun.** Outstanding: **E4A** (API proof) · **E4B** (retain the rejection output already captured) · **E5** final readback. Then complete T01R reporting. `main` must still exist at `679fabfd3a9a9b0ceea544eed6db070eea5d7d9e`. |
| **Acceptance criteria** | **A-03's E1 is WITHDRAWN as invalid** (A-04, §33): the commit it pushed was by construction the head of an open PR, so the rule treats it as associated and accepts it. It is replaced by E1A and E1B.<br><br>**E1A — unassociated direct push rejected.** Create a fresh disposable commit on a branch with **no open PR targeting `main`**, containing only an explicitly authorized harmless verification change. `git push origin <unassociated-commit>:main` must be **REJECTED — not associated with a pull request**; verbatim stderr captured. **If it is accepted, STOP: the `pull_request` rule is not enforcing its documented property.**<br>**E1B — associated-commit semantics, recorded not tested.** Document that a commit already the head of an open PR **may be accepted** when pushed directly under the `pull_request` rule. This is **not** a bypass failure — GitHub considers the change associated. **Project process still forbids it, and Codex must never use that path intentionally.**<br>**E2 — normal PR path.** A fresh authorized verification commit on a feature branch, opened as a PR and merged through GitHub's **normal merge operation** with `required approvals = 0`. **ACCEPTED. No `--admin`. No bypass.**<br>**E2 evidence must record `PR number` · `headRefOid` · `mergeCommit` · `reviewDecision` · the merge method/operation used, and acceptance requires `headRefOid != mergeCommit`** (A-05, §34). A PR reporting `MERGED` is **not** sufficient: PR #1 and PR #3 both report `MERGED` and neither was merged.<br>**E3 — force push rejected.** A non-fast-forward update to `main` is **REJECTED by `non_fast_forward`**; stderr captured.<br>**E4A — deletion rule proven by API.** The active `main-phase1` ruleset, read from the GitHub API, **targets `refs/heads/main`** · **contains a `deletion` rule** · **`enforcement: "active"`** · **`bypass_actors: []`**; raw JSON captured.<br>**E4B — deletion behaviourally rejected.** `git push origin --delete main` is **rejected**; verbatim stderr captured. **`main` is the default branch, so GitHub's default-branch safeguard may reject the deletion before the ruleset produces a distinguishable error. The absence of a ruleset-specific `GH013` message MUST NOT fail T01R** (A-06, §35).<br>**Deletion protection is accepted on the conjunction of all four:** (1) an active `deletion` rule proven by API readback · (2) deletion of `main` behaviourally rejected · (3) `main` still exists at the expected SHA · (4) no bypass actor exists. **Do not claim the behavioural rejection proves which layer fired.**<br>**E5 — ruleset readback.** `enforcement = active` · `bypass_actors = []` · target `refs/heads/main` · `pull_request` present · `non_fast_forward` present · `deletion` present; raw JSON captured with the ruleset id.<br><br>**E1A, E2, E3, E4 and E5 must all pass. E1A failing to fail is a hard stop.** |
| **Persistence impact** | None |
| **Canon impact** | None |
| **Evidence** | Attached to the PR by hand (CI does not exist until T14): `t01r_e1a_unassociated_push_rejected.txt` · `t01r_e2_pr_merge.txt` · `t01r_e3_force_push_rejected.txt` · `t01r_e4a_deletion_rule.json` · `t01r_e4b_delete_rejected.txt` · `t01r_e5_ruleset.json`. **Verbatim output. Not a summary, not a screenshot of a settings page.** E1B produces no evidence file — it is a recorded semantic, not a test.<br><br>**`t01r_e2_pr_merge.txt` must contain all five fields** — `PR number`, `headRefOid`, `mergeCommit`, `reviewDecision`, merge method/operation — **and show `headRefOid != mergeCommit`** (§34). |
| **Parallelization** | **Blocks everything.** Nothing runs beside it, and nothing merges until it passes. |
| **Stop conditions** | Any test that does not produce the expected outcome — especially **E1A failing to be rejected**, or **E2 failing to merge**. · The ruleset cannot be created with an empty `bypass_actors` on the current plan. · A legitimate PR merge is blocked by an approval requirement — suspect `require_extra_approval_for_unattributed_changes` (ADR-002 §1.4) and **report; do not work around it**. · Remediation would require reverting `46f76ff` or `0ca3206`, rewriting history, force-pushing, or deleting a branch — **none is authorized (§32, §33).** · The fix would require adding a bypass actor, or the **Restrict updates** rule — **neither is authorized; report instead.** |
| **Explicitly forbidden** | Reverting `46f76ffbe2518884c2c5783415bdf446664b637f` or `0ca3206e77e59e421705f9e55ed9dbbeab87959f` · rewriting history · force-pushing anything · re-opening or re-creating PR #1 or PR #3 · re-implementing the four T01 files · adding a bypass actor · **adding the `update` (Restrict updates) rule** · pushing a PR-head commit directly to `main` even though GitHub would accept it · configuring required status checks (T14) |

---

### VS0-T02 — Godot baseline, renderer and pixel contract · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Pin the engine, configure the renderer and the 320 × 180 pixel contract, and prove both by test and by screenshot. |
| **Required reading** | ADR-001 (all) · Master Canon — *Technical baseline / Pixel contract* · `ARCHITECTURE.md` §6 · §6 of this document |
| **Dependencies** | VS0-T01. **Fixed inputs:** Godot **4.7.2-stable** + matching **4.7.2** export templates, installed on the owner machine. |
| **Allowed paths** | `/project.godot` `/docs/ENGINE.md` `/icon.svg` `/presentation/boot/**` |
| **Forbidden paths** | `core/**` `systems/**` `data/**` `tools/**` `addons/**` |
| **Implementation requirements** | Every setting in §6.2 and §6.3, verbatim · `docs/ENGINE.md` recording **`4.7.2-stable`** for editor and templates, SHA-256 checksums and the explicit download URL (no `latest`) · the renderer feature matrix (§6.2) executed and recorded with PASS/FAIL and screenshots · a placeholder `boot.tscn` that renders a 320 × 180 test pattern (pixel grid, 16 × 16 tile guides, a 16 × 24 player-size reference) · **no autoloads registered yet** |
| **Tests** | `tests/canon/test_project_settings.gd` asserting **every** value in §6.2 and §6.3 by reading `ProjectSettings`. *(Written here; executed once GUT lands in T04. The test file is committed by this task.)* |
| **Acceptance criteria** | Project boots headless on the owner machine and exits `0` · `docs/ENGINE.md` complete with checksums · evidence screenshots at `1280×720` (exact fill) and `1366×768` (centred with letterbox) attached · every renderer feature recorded PASS or FAIL with evidence |
| **Persistence impact** | **None.** Nothing in this task is persisted. `game_version` is read from `application/config/version` at save time (T11) — this task sets that value. |
| **Stop conditions** | The installed editor is not `4.7.2-stable` · editor and template versions differ · a 4.8 pre-release build is present and would be used · a §6.3 setting cannot be expressed in `project.godot` · a renderer feature fails **and** the failure blocks the pixel contract (a non-blocking FAIL is recorded, not a stop) |
| **Parallelization** | Parallel-safe with VS0-T03 |

---

### VS0-T03 — Folder skeleton and layer scaffolding · *Lightweight · Level 0*

| Field | Content |
|---|---|
| **Objective** | Create the exact folder tree in §5 with ownership READMEs, so the first file cannot land in the wrong layer. |
| **Required reading** | `ARCHITECTURE.md` §1, §2 · §5 of this document |
| **Dependencies** | VS0-T01 |
| **Allowed paths** | Every folder in §5, **`.gitkeep` and `README.md` only** |
| **Forbidden paths** | Any `.gd`, `.tscn`, `.json` or `.cfg` file |
| **Implementation requirements** | Tree exactly as §5 · each folder carries a `README.md` of at most three lines naming its **layer**, its **owner** and what it must never contain · no folder is created that §5 does not list · no empty system folders under `systems/` |
| **Tests** | `tests/unit/test_folder_contract.gd` — every folder in §5 exists and carries a README; **no folder outside §5 exists** at repository root level |
| **Acceptance criteria** | Tree matches §5 exactly, verified by the test · no source file was added |
| **Persistence impact** | None |
| **Parallelization** | Parallel-safe with VS0-T02 |

---

### VS0-T04 — GUT vendoring and headless test runner · *Lightweight · Level 1*

| Field | Content |
|---|---|
| **Objective** | Vendor the pinned GUT release and make `run tests headless → JUnit XML → exit code` work. |
| **Required reading** | ADR-002 §2, §3 · §14 of this document |
| **Dependencies** | VS0-T02, VS0-T03 |
| **Allowed paths** | `/addons/gut/**` `/tests/**` `/tools/test/**` `/docs/ENGINE.md` |
| **Forbidden paths** | `core/**` `systems/**` `presentation/**` `data/**` |
| **Implementation requirements** | Select the GUT release **by the rule in §14** — matching Godot **4.7**, highest qualifying patch — and record it in `docs/ENGINE.md` with a checksum · vendor it committed, with **no network access at build or run time** · a headless runner script producing JUnit XML · the test directories from §14 · run the tests committed by T02 and T03 |
| **Tests** | A self-test asserting the runner reports a **deliberately failing** test as a failure and returns non-zero. A runner that can only report success is not a runner. |
| **Acceptance criteria** | Headless run produces JUnit XML and a correct exit code · T02 and T03 tests pass · the deliberate-failure self-test proves failures are detected · GUT version and checksum recorded |
| **Persistence impact** | None |
| **Parallelization** | Blocks the T05/T06/T07 wave |
| **Stop condition** | No GUT release satisfies the §14 rule against Godot 4.7.2 — **the engine pin wins; stop and report.** Do not substitute another framework, and do not download GUT in CI as a workaround. |

---

### VS0-T05 — Convention lint (CI gate 1) · *Standard · Level 1*

| Field | Content |
|---|---|
| **Objective** | Implement the convention lint that gate 1 runs. |
| **Required reading** | `CONVENTIONS.md` (all) · §15.3 of this document |
| **Dependencies** | VS0-T04 |
| **Allowed paths** | `/tools/lint/convention_lint.gd` `/tests/unit/test_convention_lint.gd` `/tests/fixtures/lint/**` |
| **Forbidden paths** | `/tools/lint/layer_lint.gd` and everything outside the allowed list |
| **Implementation requirements** | Static typing on every declaration, parameter and return · naming per `CONVENTIONS.md` §2.2 · file ≤ 500 lines · forbidden patterns: global `randi`/`randf`/`randomize`/`RandomNumberGenerator` outside `core/rng/`, raw key reads outside `core/input/`, `species_id ==` branching, literal user-facing strings outside `tools/` and `tests/`, `print(` outside `tools/`, deprecated `TileMap` · output names **file, line, rule** · exit code `0` / non-zero · `tools/` and `tests/` exempt where §15.3 says so |
| **Tests** | Fixture files in `tests/fixtures/lint/` that **must fail**, one per rule, plus a clean fixture that must pass. Every rule ships with a negative test. |
| **Acceptance criteria** | Every rule fires on its negative fixture · the clean fixture passes · the real repository passes · report is actionable |
| **Persistence impact** | None |
| **Parallelization** | Parallel-safe with VS0-T06 and VS0-T07 (disjoint files) |

---

### VS0-T06 — Layer dependency lint (CI gate 2) · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Implement the lint that makes the layer architecture real. **This is the load-bearing control of the whole architecture.** |
| **Required reading** | ADR-003 §1, §2 · `ARCHITECTURE.md` §1, §2 · §15.3 of this document |
| **Dependencies** | VS0-T04 |
| **Allowed paths** | `/tools/lint/layer_lint.gd` `/tests/unit/test_layer_lint.gd` `/tests/fixtures/layers/**` |
| **Forbidden paths** | `/tools/lint/convention_lint.gd` and everything outside the allowed list |
| **Implementation requirements** | Build the dependency graph from `preload`, `load`, `class_name` references and type annotations, grouped by root folder · allow **only** the edges listed in §15.3 · fail on any other edge, naming file, line and edge · emit `layer_graph.json` · read approved exceptions **only** from the list in `ARCHITECTURE.md` §1 — **Codex may not add an exception** · `tools/` and `tests/` sit outside the graph |
| **Tests** | Fixtures containing a deliberate `systems → presentation` edge, a deliberate `core → systems` edge, and a clean tree. The first two **must** fail the lint. |
| **Acceptance criteria** | Both upward-edge fixtures fail · the clean fixture passes · the real repository passes · `layer_graph.json` is produced · the report names file, line and edge |
| **Persistence impact** | None |
| **Stop conditions** | A legitimate VS0 file cannot satisfy the rules without an exception — **stop; do not add the exception.** An exception is an `ARCHITECTURE.md` amendment, and that is Claude's and Luisma's decision. |
| **Parallelization** | Parallel-safe with VS0-T05 and VS0-T07 |

---

### VS0-T07 — Validator framework, schemas and registries · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Build the schema and semantic validation stages, the JSON Schemas, and the append-only registries. |
| **Required reading** | ADR-004 §1, §2, §5 · `ARCHITECTURE.md` §5 · §8, §15 of this document |
| **Dependencies** | VS0-T04 |
| **Allowed paths** | `/tools/validators/validate_all.gd` `/tools/validators/schema_validator.gd` `/tools/validators/semantic_validator.gd` `/data/source/_schema/**` `/data/source/_registry/**` `/tests/unit/test_validators.gd` `/tests/fixtures/data/**` |
| **Forbidden paths** | `/tools/validators/canon_validator.gd` `/tools/validators/loc_validator.gd` `/data/source/canon/**` `/tools/generators/**` |
| **Implementation requirements** | `validate_all.gd` **discovers** validators by scanning `tools/validators/*_validator.gd` and orders them by a declared stage constant — it contains no hardcoded validator list · stages short-circuit: schema → semantic → canon · JSON Schema for every source file listed in §5 · `ids.json`, `events.json`, `input_actions.json`, `rng_streams.json` created structurally complete and **empty of content IDs** · semantic stage enforces: `snake_case`, uniqueness, no reuse of a `deprecated_ids` entry, referential integrity, no positional index as identity · every failure reports **file · JSON pointer · rule · authority** (§15.2 rule 3) · emits `validation_report.json` |
| **Tests** | Malformed fixtures per rule, each of which must fail with the correct pointer; a clean fixture that passes; a test proving the semantic stage does **not** run when the schema stage fails |
| **Acceptance criteria** | Discovery mechanism works with a validator added purely as a new file · every negative fixture fails with an actionable message · `validation_report.json` is produced · exit code contract holds |
| **Persistence impact** | **None directly** — but this task defines the ID rules that **all** persisted references depend on. An ID mistake here becomes a save-migration problem later, which is why the "never reused" rule is enforced from the empty registry. |
| **Stop conditions** | A canon enumeration cannot be expressed in JSON Schema without an arbitrary interpretation · the ID rules in ADR-004 §2 conflict with a canon name |
| **Parallelization** | Parallel-safe with VS0-T05 and VS0-T06 |

---

### VS0-T08 — Canon Registry, generator framework and gate 4 · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Author the closed canon enumerations as data, generate GDScript constants from them, and make hand-editing generated files unmergeable. |
| **Required reading** | ADR-004 §3, §6, §7 · Master Canon — *Official types*, *Combat*, *Technical baseline* · §9 of this document |
| **Dependencies** | VS0-T07 |
| **Allowed paths** | `/data/source/canon/**` `/data/source/_schema/canon/**` `/tools/generators/**` `/tools/validators/canon_validator.gd` `/core/contracts/generated/**` `/tests/canon/**` |
| **Forbidden paths** | `/systems/**` `/presentation/**` `/core/save/**` `/core/rng/**` |
| **Implementation requirements** | Author every file in §9.1 with canonical **Spanish IDs verbatim** · `generate_all.gd` **discovers** generators by scanning `tools/generators/*_generator.gd`, with no hardcoded list · `canon_enum_generator.gd` emits `core/contracts/generated/canon_enums.gd` and `type_matrix_data.gd`, each carrying an autogenerated header naming source and generator · **data only — no effectiveness function, no damage formula** · `canon_validator.gd` implements **every** check in §9.2 · gate 4 regenerate-and-diff tooling |
| **Tests** | `tests/canon/` — the full §9.2 check set as permanent tests · a **deliberately broken** copy of `type_matrix.json` that must fail the mutual-strength and totals checks · a test proving a hand-edited generated file is detected by regenerate-and-diff |
| **Acceptance criteria** | Exactly 13 types · matrix resolves to **26 strong · 24 resistances · 119 neutral · 0 immunities** · exactly **one** mutual-strength pair (Veneno ↔ Psíquico) · the `Lucha > Ancestral > Sombra > Psíquico > Lucha` cycle is closed · every generated file matches a fresh regeneration · the broken-data fixture fails as expected |
| **Persistence impact** | **Indirect and important.** Canon IDs become save vocabulary the moment anything references them. They are `snake_case`, immutable and never reused from this task onward. `codex_number` is **never** written into a save. |
| **Stop conditions** | A canon enumeration in the accepted documents is ambiguous or incomplete · the computed matrix totals do **not** match §9.2 — **stop and report; do not adjust the data to make the test pass.** The totals are the canon, and a mismatch means either the data or this specification is wrong, which is Luisma's call, not Codex's. |
| **Parallelization** | Blocks the T09/T12 wave. Runs alone. |

---

### VS0-T09 — EventBus and GameState shell · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Register the first two autoloads, with a generated event registry and deferred dispatch. |
| **Required reading** | ADR-003 §3, §4, §5, §6 · `ARCHITECTURE.md` §3, §9 · `STATE_OWNERSHIP.md` §1 |
| **Dependencies** | VS0-T08 |
| **Allowed paths** | `/autoload/event_bus.gd` `/autoload/game_state.gd` `/core/events/**` `/tools/generators/event_registry_generator.gd` `/data/source/_registry/events.json` `/project.godot` *(autoload entries only)* `/tests/unit/test_event_bus.gd` `/tests/unit/test_game_state.gd` |
| **Forbidden paths** | `/core/save/**` `/core/rng/**` `/systems/**` `/presentation/**` |
| **Implementation requirements** | Every cross-module event declared in `events.json` with a documented payload; `core/events/event_registry.gd` is **generated** from it · **past tense only** · **deferred dispatch** — queued and drained at a known point, never emitted mid-mutation · no game truth may depend on listener order · CI check for orphan events (declared, no listener) and phantom listeners (listening to an undeclared event) · `GameState` **holds substates and exposes reads, and owns no rules**; in VS0 it holds **exactly one slot**, for `RngState`, which T10 fills · autoload registration order per §7 |
| **Tests** | Deferred dispatch is observably deferred · listeners see settled state · an undeclared event cannot be emitted · orphan and phantom detection both fire on fixtures · `GameState` exposes no mutator for a substate it does not own |
| **Acceptance criteria** | Both autoloads registered in order · event registry generated and matching `events.json` · all tests pass · layer lint clean |
| **Persistence impact** | `GameState` is the **container** for persisted substates but persists nothing itself. The container/DTO split (§10.3) is established here and must not be short-circuited later by serializing `GameState` directly. |
| **Stop conditions** | An event cannot be expressed in past tense without becoming a command · deferred dispatch cannot satisfy a VS0 requirement · a fifth autoload appears necessary |
| **Parallelization** | Parallel-safe with VS0-T12 |

---

### VS0-T10 — RngService and RngState · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Deterministic named RNG streams whose seed state is real, persisted state. |
| **Required reading** | ADR-005 §6 · `ARCHITECTURE.md` §8 · `STATE_OWNERSHIP.md` §1 · §11 of this document |
| **Dependencies** | VS0-T09 |
| **Allowed paths** | `/autoload/rng_service.gd` `/core/rng/**` `/core/state/rng_state.gd` `/data/source/_registry/rng_streams.json` `/project.godot` *(autoload entry only)* `/tests/unit/test_rng.gd` |
| **Forbidden paths** | `/core/save/**` `/autoload/save_manager.gd` `/systems/**` `/presentation/**` |
| **Implementation requirements** | The five streams in §11.1 · independent, so consuming randomness in one cannot shift another · master seed + per-stream counters in `RngState`, **owned by `RngService`**, registered in `GameState` · `cosmetic` is non-deterministic, non-persisted, and **must never influence game state** · global RNG use forbidden outside `core/rng/` (gate 1 enforces; this task must not be the exception) · `to_save_dict()` / `from_save_dict(data, version)` on `RngState` — **T11 consumes these; this task defines them** |
| **Tests** | Same seed + same call sequence → identical outputs · streams are provably independent (consuming from `battle` does not shift `encounter`) · `cosmetic` is absent from `to_save_dict()` · state round-trips through `to_save_dict()` / `from_save_dict()` with identical subsequent outputs |
| **Acceptance criteria** | All the above pass · `RngState` is registered in `GameState` · global RNG grep is clean |
| **Persistence impact** | **`RngState` is the one substate persisted in VS0 and enters `save_version: 1`.** Its DTO shape is frozen by golden fixture v1 in T11. Changing it after T11 requires a `save_version` bump and a migration. |
| **Stop conditions** | Determinism cannot be guaranteed across a save/load boundary with the chosen generator · a stream is needed that is not in §11.1 |
| **Parallelization** | Parallel-safe with VS0-T13 |

---

### VS0-T11 — Save Core · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Envelope, Windows-correct atomic write, migration harness, golden fixture v1 and the schema-hash guard. **The highest-risk task in VS0.** |
| **Required reading** | ADR-005 (all) · `ARCHITECTURE.md` §10 · `STATE_OWNERSHIP.md` §1 · §10 of this document |
| **Dependencies** | VS0-T09, VS0-T10 |
| **Allowed paths** | `/autoload/save_manager.gd` `/core/save/**` `/tests/unit/test_save_*.gd` `/tests/integration/test_save_roundtrip.gd` `/tests/fixtures/saves/**` `/project.godot` *(autoload entry only)* |
| **Forbidden paths** | `/core/rng/**` `/core/state/**` `/systems/**` `/presentation/**` `/data/source/**` |
| **Implementation requirements** | Envelope exactly as §10.1 · **JSON**, never `.tres`, never opaque binary · `save_version` independent of `game_version` · the Windows-correct sequence in §10.2 with bounded retry and the backup never destroyed before the new file verifies · runtime state ≠ DTO, with explicit mapping and **no automatic serialization** · sequential `N → N+1` migration chain, functioning and registered, exercised by a synthetic `v0 → v1` case · **golden fixture v1 frozen** in `tests/fixtures/saves/save_v1.json` · schema-hash computation and the gate-8b guard · forward-version saves rejected cleanly, existing file untouched · `SaveManager` is the **only** writer of adventure files · settings file (§10.5) created separately, outside the save |
| **Tests** | Interruption simulated at **every** step of §10.2, asserting a loadable save always remains · golden fixture v1 migrates to current with **semantic** invariants asserted, not "it didn't crash" · schema-hash guard fires on an unversioned schema change · forward-version save rejected and the file on disk unchanged · corrupted checksum detected · round trip: write → read → `RngService` produces identical subsequent outputs |
| **Acceptance criteria** | Every test above passes · fixture v1 committed and **marked never-regenerate in a README beside it** · `save_migration_report.txt` and `schema_hash.txt` produced as artifacts |
| **Persistence impact** | **This task defines the persistence contract for the entire project.** `save_version: 1` is frozen here. Every later durable field is an `N → N+1` migration against fixture v1. |
| **Stop conditions** | The atomic sequence cannot be made reliable on Windows as specified · a field would enter the DTO without a written durable-consequence justification · the schema hash cannot be computed stably across runs · the migration harness would need to skip versions |
| **Parallelization** | **None. Runs alone.** It touches the contract every later milestone depends on. |

---

### VS0-T12 — Localization foundation · *Standard · Level 1*

| Field | Content |
|---|---|
| **Objective** | ES/EN from day one, with a validator that keeps it honest. |
| **Required reading** | ADR-004 §5 rule 11 · ADR-003 §4 *(why there is no `LocalizationManager`)* · §12 of this document |
| **Dependencies** | VS0-T08 |
| **Allowed paths** | `/core/loc/**` `/data/source/loc/**` `/tools/validators/loc_validator.gd` `/project.godot` *(locale settings only)* `/tests/unit/test_loc.gd` |
| **Forbidden paths** | `/autoload/**` `/core/save/**` `/systems/**` `/data/source/canon/**` |
| **Implementation requirements** | `TranslationServer` + `tr()`; **no autoload** · `system.csv` with `key,es,en`, **system strings only** · Godot CSV import; `.translation` artifacts are **not** committed, `.import` files **are** · `core/loc/loc.gd` for locale selection, `en` fallback and key-existence queries · default locale `es` · the non-translatable proper-noun list exists, populated as content arrives · `loc_validator.gd` registers itself as a `CANON`-stage validator by file discovery (no edit to `validate_all.gd`) |
| **Tests** | Key parity across locales · no orphan keys · no empty values · a proper noun differing between locales fails · a literal user-facing string in a fixture `.gd` fails · fallback to `en` works for a missing `es` key |
| **Acceptance criteria** | Validator passes on the real repository and fails on every negative fixture · locale switching works at runtime · no literal user-facing string exists outside `tools/` and `tests/` |
| **Persistence impact** | **None in the save.** Locale is a **setting** (§10.5), deliberately outside the save so changing language never risks progress. |
| **Parallelization** | Parallel-safe with VS0-T09 |

---

### VS0-T13 — Input foundation · *Standard · Level 1*

| Field | Content |
|---|---|
| **Objective** | Named actions, keyboard and gamepad bindings, and device-kind detection. No rebinding UI. |
| **Required reading** | §13 of this document · `ARCHITECTURE.md` §1 *(Core layer rules)* · ADR-005 §2 *(settings live outside the save)* |
| **Dependencies** | VS0-T08 |
| **Allowed paths** | `/core/input/**` `/data/source/_registry/input_actions.json` `/tools/generators/input_actions_generator.gd` `/project.godot` *(InputMap only)* `/tests/unit/test_input.gd` |
| **Forbidden paths** | `/presentation/**` `/systems/**` `/autoload/**` `/core/save/**` |
| **Implementation requirements** | Exactly the actions in §13.2, declared in `input_actions.json`, **generated** into `core/input/input_actions.gd`, and written into the InputMap · **keyboard and gamepad bound for every action** · `input_device.gd` tracks the last-used device kind and emits `input_device_changed` · **no rebinding UI, no options screen** — that is VS9 · raw key reads forbidden outside `core/input/` |
| **Tests** | Every declared action exists in the InputMap with **both** a keyboard and a gamepad binding · generated constants match the registry · device-kind switches on a simulated gamepad event · a fixture using `Input.is_key_pressed` outside `core/input/` fails gate 1 |
| **Acceptance criteria** | All the above pass · regenerating `input_actions.gd` produces no diff |
| **Persistence impact** | **None in the save.** Rebindings are a **setting** (ADR-005 §2), which is exactly why VS9's rebinding work will require no migration. |
| **Parallelization** | Parallel-safe with VS0-T10 |

---

### VS0-T14 — CI workflow and Windows export · *Full · Level 2*

| Field | Content |
|---|---|
| **Objective** | Wire every VS0 gate into GitHub Actions, export for Windows, publish the evidence, and **complete Phase-2 branch protection** by requiring every gate under its stable check name. |
| **Required reading** | ADR-002 §1, §5, §6 · §16, §17, §19 of this document |
| **Dependencies** | VS0-T15 (and therefore, transitively, everything else). **Confirmed intentional — see §30.2.** |
| **Allowed paths** | `/.github/workflows/**` *(sole owner)* `/export_presets.cfg` `/tools/ci/**` `/docs/ENGINE.md` |
| **Forbidden paths** | `core/**` `systems/**` `presentation/**` `data/source/**` `addons/**` |
| **Implementation requirements** | Step order per §16.1 · checkout with `lfs: true` · pinned editor and templates downloaded, **SHA-256 verified**, cached by version · gates 1–8 as separate, individually legible steps · **gates 9–11 are not stubbed** · Windows export per §17 with the exported binary launched headless and required to exit `0` · every artifact in §19 uploaded, **including on failure**.<br><br>**Phase-2 branch protection, in this exact order** — the sequence matters because a workflow cannot be a required check before it exists on `main`: (1) open a PR adding the workflow and merge it under Phase-1 rules; (2) read the **exact check names** the workflow now reports; (3) add those names to `main`'s required status checks; (4) prove all four cases below. **No temporary or placeholder check is authorized at any step.**<br><br>Consequence to state rather than hide: **T14's own workflow PR merges without required checks enforced on it**, because it is the PR that creates them. That is unavoidable and is why step 4 exists. |
| **Tests** | **(a) Gate proofs:** a deliberately failing branch per gate — one commit that breaks the convention lint, one that adds an upward layer edge, one that breaks canon data, one that hand-edits a generated file, one that changes the persisted schema without a version bump. **Each must turn CI red on the correct step and no other.**<br>**(b) Protection proofs:** dedicated **throwaway** PRs — `test/ci-green`, `test/ci-red`, `test/ci-pending` — opened solely to exercise branch protection and closed without merging (except the green one, which proves merge is possible). Never use a real task PR for this. |
| **Acceptance criteria** | CI green on `main` · each deliberate-failure branch fails on the expected step and no other · artifacts present on both success and failure.<br><br>**Phase-2 protection proven, all four cases with evidence:**<br>1. a PR with **all required checks green can merge**;<br>2. a PR with a **required check failing cannot merge**;<br>3. a PR with a **required check missing or pending cannot merge**;<br>4. a **direct push to `main` remains blocked**. |
| **Persistence impact** | None |
| **Stop conditions** | The pinned engine cannot be acquired reproducibly with a verifiable checksum · export templates cannot be installed on the runner · a gate cannot run headless on `windows-latest` |
| **Parallelization** | **None. Final task.** |

---

### VS0-T15 — Boot scene, smoke test and evidence harness · *Standard · Level 2*

| Field | Content |
|---|---|
| **Objective** | Prove the foundation is **connected**, not merely present, and produce the evidence a human reviews. |
| **Required reading** | ADR-002 §5 · §18, §19 of this document |
| **Dependencies** | VS0-T11, VS0-T12, VS0-T13 |
| **Allowed paths** | `/presentation/boot/**` `/tools/evidence/**` `/tests/integration/test_boot.gd` |
| **Forbidden paths** | `core/**` `autoload/**` `systems/**` `data/source/**` |
| **Implementation requirements** | The boot sequence in §18.1, exactly, in order, exiting non-zero with the failing step named · `smoke_scene_load.gd` loading **every** `.tscn` headless and failing on any script error · `capture_boot_evidence.gd` producing the three screenshots in §18.3 · `boot_report.txt` recording engine version, `save_version` and `schema_hash` · **the boot scene may not mutate `GameState` directly** — it calls facades and autoloads only |
| **Tests** | Boot integration test asserting all six steps, in order · smoke loader proves it detects a deliberately broken scene fixture · evidence capture produces files of the expected dimensions |
| **Acceptance criteria** | `BOOT OK` headless with a correct report · smoke test passes and its negative fixture fails · three screenshots produced at correct resolutions · layer lint clean |
| **Persistence impact** | The boot scene **writes and reads a real save**, so it is an end-to-end exercise of T11's contract. It must use `SaveManager` and never touch save files directly. |
| **Stop conditions** | The boot sequence cannot complete without a fifth autoload or a system that VS0 forbids · headless screenshot capture is unavailable under the Compatibility renderer |
| **Parallelization** | Runs alone, immediately before VS0-T14 |

---

## 24. Task dependencies

```
T01 Repository ──► T01R Enforcement remediation   ◄── nothing merges until this passes
 ├─► T02 Godot baseline ──┐
 └─► T03 Folder skeleton ─┴─► T04 GUT
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
        T05 Convention    T06 Layer lint    T07 Validator
            lint                              framework
                                                  │
                                                  ▼
                                          T08 Canon Registry
                                            + generators
                                                  │
                              ┌───────────────────┼───────────────────┐
                              ▼                   ▼                   ▼
                        T09 EventBus +      T12 Localization    T13 Input
                           GameState              │              (needs T08)
                              │                   │                   │
                              ▼                   │                   │
                        T10 RngService            │                   │
                              │                   │                   │
                              ▼                   │                   │
                        T11 Save Core             │                   │
                              └───────────────────┴───────────────────┘
                                                  │
                                                  ▼
                                    T15 Boot + smoke + evidence
                                                  │
                                                  ▼
                                          T14 CI + Windows export
```

**Direct dependencies, stated flatly:**

| Task | Depends on | Because |
|---|---|---|
| T01 | — | Nothing can be reviewed before the repository exists |
| **T01R** | **T01** | **Enforcement must be proven before anything else merges. T01's protection was configured but never tested, and the untested path was used (§32).** |
| T02 | T01, **T01R** | |
| T03 | T01, **T01R** | |
| T04 | T02, T03 | The GUT pin is verified against the pinned engine, and tests need their folders |
| T05 | T04 | The lint ships with tests |
| T06 | T04 | The lint ships with tests |
| T07 | T04 | The validators ship with tests |
| T08 | T07 | Canon data must be schema- and semantically valid before canon rules are meaningful |
| T09 | T08 | The event registry is a generated artifact and needs the generator framework |
| T10 | T09 | `RngState` lives in `GameState` |
| T11 | T09, T10 | Save Core needs a real substate to persist |
| T12 | T08 | The loc validator plugs into the discovery framework |
| T13 | T08 | Action constants are a generated artifact |
| T15 | T11, T12, T13 | Boot exercises save, locale and input together |
| T14 | T15 | The workflow runs the smoke and evidence steps T15 creates, and Phase-2 required checks need the **final** check names. **Intentional — §30.2.** |

**Why T14 is last, and why that is not an inversion.** See §30.2. In short: `.github/workflows/`
has exactly one owner, and that owner writes the workflow **once**, against a complete gate set, so
the check names it publishes are the ones branch protection requires forever after.

---

## 25. Parallel-safe tasks

Each wave is safe to run concurrently, **one writing agent per git worktree**, with non-overlapping
`ALLOWED PATHS`.

| Wave | Tasks | Path overlap | Notes |
|---|---|---|---|
| A | **T01** | — | Alone |
| **A′** | **T01R** | `README.md`, one line | **Alone. Blocks every later wave** — no task merges until PR-only enforcement is proven by live rejection |
| B | **T02**, **T03** | None — T02 owns `project.godot` and `docs/ENGINE.md`; T03 owns folder markers only | Safe |
| C | **T04** | — | Alone; establishes the test runner |
| D | **T05**, **T06**, **T07** | None — three disjoint file sets under `tools/` | **The widest parallel wave in VS0** |
| E | **T08** | — | Alone; every downstream generated artifact depends on the framework it creates |
| F | **T09**, **T12** | None — `autoload/` + `core/events/` versus `core/loc/` + `data/source/loc/` | Safe |
| G | **T10**, **T13** | None — `core/rng/` + `core/state/` versus `core/input/` | Safe |
| H | **T11** | — | **Alone, deliberately.** It defines the persistence contract. |
| I | **T15** | — | Alone |
| J | **T14** | — | Alone |

**Shared-file hazards, and how they are removed rather than managed:**

| Shared file | Touched by | Resolution |
|---|---|---|
| `project.godot` | T02, T09, T10, T11, T12, T13 | Each task edits a **disjoint section** (settings / autoloads / locale / InputMap) and the waves are sequenced so no two concurrent tasks touch it. T02's wave is the only one where it is rewritten wholesale. |
| `tools/generators/generate_all.gd` | T08, T09, T13 | **Discovery by file scan** (§23). T09 and T13 add a generator file and register nothing. |
| `tools/validators/validate_all.gd` | T07, T08, T12 | Same discovery mechanism, ordered by stage constant. |
| `docs/ENGINE.md` | T02, T04, T14 | Sequenced across three waves; each appends its own section. |

> The point of the two discovery mechanisms is small and worth stating plainly: **a registration list
> in a shared file is a merge conflict generator and a coordination tax on every future task.** File
> discovery removes both, permanently, for the cost of one scan at build time.

---

## 26. Recommended merge order

Merge order equals wave order. Each PR merges to `main` green, and `main` stays buildable
throughout — the property that makes every later bisect meaningful.

| # | PR | Gate green at merge |
|---|---|---|
| 1 | T01 Repository bootstrap | — (files only. **Enforcement unproven — see row 1R**) |
| **1R** | **T01R Enforcement remediation** | **Phase-1 enforcement proven live: E1 direct push rejected · E2 PR merged with 0 approvals · E3 force-push rejected · E4 deletion rejected · E5 `bypass_actors: []`** |
| 2 | T02 Godot baseline | Project boots headless |
| 3 | T03 Folder skeleton | Folder contract test |
| 4 | T04 GUT | Gate 5 live |
| 5 | T05 Convention lint | **Gate 1 live** |
| 6 | T06 Layer lint | **Gate 2 live** |
| 7 | T07 Validator framework | Gate 3 partial (schema + semantic) |
| 8 | T08 Canon Registry | **Gates 3 and 4 live** |
| 9 | T09 EventBus + GameState | Gates 1–5 |
| 10 | T12 Localization | Gate 3 extended |
| 11 | T10 RngService | Gates 1–5 |
| 12 | T13 Input | Gates 1–5 |
| 13 | T11 Save Core | **Gate 8 live** |
| 14 | T15 Boot + evidence | **Gate 7 live** |
| 15 | T14 CI + export | **Gate 6 live; Phase-2 protection applied — all VS0 gates required for merge** |

**Reading the "gate green at merge" column correctly.** Until T14 merges, a gate being "live" means
**the gate exists and is run locally through the same headless entry point CI will call** — not that
GitHub is enforcing it. Enforcement begins at step 15. This is a consequence of the two-phase
protection decision (§16.2) and is stated here so the column is not misread as a claim about CI.

**A deliberate ordering choice worth naming:** T05 and T06 merge **before** any `core/` code exists.
The lints therefore govern every line of production code from the first one, rather than being
applied retroactively to code that already passes review. Retrofitting a lint is how lint exceptions
get born.

---

## 27. Decision-free audit

The instruction was: *verify that Codex can execute every task without making an architectural or
product decision.* This section is that verification. Each row is a place where an implementer would
otherwise have to choose.

| # | Decision Codex would otherwise make | Where it is already made |
|---|---|---|
| 1 | Exact Godot version | **Owner input** (§4), recorded by Codex. Never chosen. |
| 2 | Which GUT release | **Rule**, not choice: matching pinned minor version, highest qualifying patch (§14) |
| 3 | Renderer | ADR-001 §2 — Compatibility |
| 4 | Base resolution, tile size, scaling | Master Canon — Pixel contract; ADR-001 §3; §6.3 lists every setting verbatim |
| 5 | Folder layout | `ARCHITECTURE.md` §2, reproduced exactly in §5 |
| 6 | Which autoloads, and their order | §7 — four, ordered, with the other three explicitly deferred |
| 7 | Save format | ADR-005 §3 — JSON, with `.tres` and binary explicitly rejected |
| 8 | Atomic-write sequence | §10.2 — the exact sequence, not "write atomically" |
| 9 | Envelope fields | §10.1 — the literal object |
| 10 | What is persisted in VS0 | §10.3 — exactly one substate, `RngState` |
| 11 | Migration strategy | ADR-005 §5 — sequential `N → N+1`, no skipping |
| 12 | RNG stream names | §11.1 — the five, with `cosmetic` non-persisted |
| 13 | Validation order | §15.2 — schema → semantic → canon, short-circuiting |
| 14 | Which canon enumerations to register | §9.1 — the eight files, all closed sets |
| 15 | Matrix derivation rules | Master Canon — *Type effectiveness rules*; ADR-004 §6.2, including the refined rule 3 |
| 16 | The Veneno ↔ Psíquico case | Owner-confirmed: both ×1.50, the only mutual pair; asserted by a validator (§9.2) |
| 17 | Input action names and bindings | §13.2 — the closed list, both device families |
| 18 | Localization mechanism | §12 — `TranslationServer`, no autoload, CSV source |
| 19 | Default locale | §12 — `es`, fallback `en` |
| 20 | CI host, runner, gate order | ADR-002 §1, §6; §16.1 |
| 21 | Export configuration | §17 — preset, architecture, PCK policy, output path |
| 22 | Whether generated artifacts are committed | ADR-004 §7 / §8.2 — committed, never authority, never hand-edited |
| 23 | Where the engine binary comes from in CI | §6.1 — official release, pinned version **and** checksum, with the rationale stated so it is not "fixed" later |
| 24 | How generators and validators register | §23 — file discovery, specified precisely to remove a shared-file decision |
| 25 | What counts as evidence | §19 — the artifact list |
| 26 | What "done" means | §20 — 28 enumerated criteria |

**Three places where Codex must stop rather than decide** — these are gaps by design, because the
answer is Luisma's or Claude's:

| Gap | Who decides |
|---|---|
| A layer-lint **exception** | Claude proposes, Luisma approves, `ARCHITECTURE.md` records. **Never Codex.** |
| A **fifth autoload** | ADR required |
| A **canon ambiguity** found while authoring the registry | Luisma. Codex stops and reports (§22 item 4). |

**Conclusion:** no VS0 task requires Codex to invent architecture. Every remaining unknown is either
an owner input listed in §4, or a stop condition in §22.

---

## 28. Owner decisions — all resolved

All three items raised at C-002 review are decided. Nothing in this specification is open.

| # | Item | Decision |
|---|---|---|
| 1 | **`core/input/`** as a Core folder | **APPROVED.** Added to `ARCHITECTURE.md` §2 (v1.2). Owns semantic actions, active-device detection, the controller/keyboard abstraction and input configuration helpers. **No gameplay rules.** |
| 2 | **Engine version** | **Godot 4.7.2-stable**, standard GDScript build, no .NET. Templates 4.7.2 exactly. **4.8 pre-release builds are not authorized.** Upgrades require an ADR. |
| 3 | **CI toolchain acquisition** | **APPROVED** under four conditions — exact version, explicit URL, SHA-256 verified, no `latest`. The "no build-time dependency fetching" rule is clarified in ADR-002 §2 as governing **project libraries**, not the external toolchain. **GUT stays vendored and is never downloaded by CI.** |

**No value remains outstanding.** `GITHUB_OWNER` and `GITHUB_REPOSITORY` — the last two, and inputs
rather than decisions — were supplied by the owner on 2026-09-13 and are recorded in §4, together
with the repository's **public** visibility (§31.1). Codex still invents neither; it uses the
recorded values.

---

## 29. What VS0 deliberately leaves undone

Recorded so that its absence reads as a decision rather than an oversight.

| Not done | Why, and when |
|---|---|
| Release export, signing, packaging, installer | Nothing to ship. **VS11.** |
| Audio bus layout | Nothing to play. **VS1 onward, incrementally; VS11 gate.** |
| Physics tick and quality tuning | Nothing to tune against. **VS1.** |
| Options / accessibility / rebinding UI | **VS9** per Master Canon. The action indirection (§13) is what keeps it cheap. |
| CI gates 9, 10, 11 | The systems they check do not exist. **VS2, VS4, VS7.** An always-green gate is worse than an absent one. |
| The other fourteen `GameState` substates | They arrive with the systems that own them, each as an ordinary `N → N+1` migration — which is the entire reason Save Core lands first. |
| Type effectiveness **evaluation** | VS0 ships the data and its validators. The formula is **VS3**. |
| Any of the 150 Codex entries | **VS10.** VS0 registers closed canon enumerations only. |

> Every line in this table is a place where building it now would feel productive and would cost
> more than it saves. **VS0 exists to make VS1 safe to start — nothing more.**

---

## 30. Amendment A-01 — CI status checks and the T14 ← T15 dependency

    DATE: 2026-09-12
    ORIGIN: C-002 owner review, following Codex's correct stop before VS0-T01
    TYPE: Implementation-specification correction. Not an architectural decision. No ADR required.

### 30.1 The contradiction, and how it is resolved

**Contradiction.** T01's acceptance criteria required proving that *"a PR without green checks cannot
merge"* — but T01 creates only the repository, and the workflows that produce those checks are
created by T14. Enforcing required status checks at T01 therefore had exactly two outcomes, both
unacceptable:

| Outcome | Why it fails |
|---|---|
| Codex invents a bootstrap CI check | An architectural decision made by the implementer — the precise failure this specification exists to prevent |
| Required checks are set with no workflow to satisfy them | Every PR between T01 and T14 becomes unmergeable, blocking the whole milestone |

**Resolution (owner decision).** Branch protection is applied in **two phases** (§16.2).

| | Old requirement | New requirement |
|---|---|---|
| **T01** | *"a PR without green checks cannot merge"* | Phase-1 protection only: repository *(private at the time of A-01; **PUBLIC** from A-02, §31)* · default branch `main` · direct pushes blocked · PR-only merge *("with review" at the time of A-01; **0 approving GitHub reviews** from A-02, §31.2)* · force-push and deletion of `main` blocked · LFS, ignore, README, PR template, settings evidence. **No required status checks. No workflow file.** |
| **T14** | *"branch protection requiring all checks"* (unspecified mechanism) | Owns `.github/workflows/` outright. After the workflows exist on `main` with stable check names, adds those exact names as required, and proves four cases: green merges · failing cannot · missing/pending cannot · direct push still blocked. |

**No temporary, bootstrap or placeholder check is authorized.** The T01 → T14 gap is an **approved
deferred hardening item** — explicitly *not* technical debt, *not* an architecture deviation, and
*not* a failed acceptance criterion. Codex must not report it as any of those.

### 30.2 T14 ← T15 — reviewed and **confirmed intentional**

The dependency is correct and is retained. The reasoning, recorded so it is not re-litigated:

1. **`.github/workflows/` has exactly one owner.** T14 is that owner. If T14 ran before T15, either
   T15 would have to edit T14's workflow to add the smoke and evidence steps — breaking the
   one-owner rule and the `ALLOWED PATHS` discipline — or T14 would ship a workflow referencing
   `tools/evidence/` files that do not yet exist, which fails on its first run.
2. **Phase-2 protection requires final check names.** A required check whose name later changes
   silently stops being required. Writing the workflow once, against the complete gate set, is what
   makes the names stable — which is exactly what the owner decision demands.
3. **The real workflow cannot be meaningfully earlier anyway.** Gates 1–8 are created by T05–T11. A
   workflow authored before them would run almost nothing, and would be rewritten when they landed.

**The honest cost, stated rather than hidden:** VS0 itself is developed without GitHub enforcing its
gates. Three things bound that cost, and they were already in the specification:

- every gate is runnable **locally through the same headless entry point CI calls**, so "green
  locally" and "green in CI" are the same command;
- every control ships with a **committed negative test** proving it fires (§20 items 10, 14, 18, 21);
- T14's **deliberate-failure branches** prove retroactively that each gate turns CI red on the
  correct step.

From VS1 onward this cost does not exist: CI and Phase-2 protection are already in place.

### 30.3 Documents and sections changed

| Document | Sections |
|---|---|
| `VS0_FOUNDATION_SPEC.md` | Header (amendment record) · §16.2 (two-phase protection) · §20 criteria 1 and 24 · §23 packet **T01** · §23 packet **T14** · §24 dependency table + note · §26 merge order rows 1 and 15 + column note · **§30** (this section) |
| `CODEX_VS0_HANDOFF.md` | §4 wave table · §6 branch rules · §8 evidence note |
| Packet **T15** | **Unchanged.** Its dependencies (T11, T12, T13) and responsibilities are correct as written. |

### 30.4 Final execution order — unchanged

```
… → T11 Save Core → T15 Boot + smoke + evidence → T14 CI + export + Phase-2 protection
```

### 30.5 Decision-free confirmation

With this amendment, no task requires Codex to invent architecture:

| Previously open | Now |
|---|---|
| How T01 satisfies a required-checks criterion with no CI | **Removed.** T01 does not configure required checks, and the deferral is stated in its acceptance criteria. |
| What a bootstrap check would look like | **Not applicable.** No bootstrap check is authorized. |
| When and how required checks are enabled | **Specified**: T14, in four ordered steps, using the workflow's own reported check names. |
| How to prove protection works | **Specified**: four named cases, on throwaway PRs, never on real task PRs. |
| Whether T14 ← T15 is an error | **Confirmed intentional**, with the reasoning and the trade-off recorded in §30.2. |

**C-002 remains ACCEPTED. T01 is READY. T14 is READY with corrected scope. T15 is unchanged and
READY. No other task is affected.**

---

## 31. Amendment A-02 — repository visibility and the solo-owner review model

    DATE: 2026-09-13
    ORIGIN: Owner decision following Claude's architecture review of PR #1 (VS0-T01)
    TYPE: Implementation-specification correction + ADR-002 revision. No new architectural decision.

### 31.1 Repository visibility — PRIVATE → **PUBLIC**

| | Old | New |
|---|---|---|
| Visibility | **Private** GitHub repository | **PUBLIC** — `inmoaiasistente-luisma/galapagos-the-origin` |

**Reason (owner):** the current GitHub plan does not provide the required branch-protection features
on private repositories, while a public repository supports the accepted protection model in full.
**Protection was chosen over concealment, deliberately.**

**No active authority requires a private repository any more.** The previous requirement survives
only as superseded history in ADR-002 §1.1 and in this section.

**Standing consequence, recorded because it is permanent:** everything committed is published, canon
included. **Never commit a secret, credential or token** — on a public repository a leak is
compromised on push and deletion does not un-publish it. Nothing in Volume I requires one (no
network, no telemetry, no analytics), and `.gitignore` excludes `.env*`.

### 31.2 Solo-owner review model — approving reviews **0**

| | Old | New |
|---|---|---|
| Merge rule | "Pull request only, **with review**" — read by GitHub as `required_approving_review_count: 1` | Pull request only, **`required_approving_review_count: 0`** |

**Reason:** the repository has one eligible GitHub account, and GitHub does not permit a PR's author
to satisfy their own approval requirement. A non-zero count makes every PR permanently unmergeable —
which is exactly what PR #1 demonstrated.

**Unchanged and still mandatory, mechanically:** PR-only merge · direct pushes to `main` blocked ·
`enforce_admins: true` · force-push blocked · deletion of `main` blocked · required CI checks
deferred to T14 under A-01.

> **⚠ PARTIALLY SUPERSEDED BY A-03 (§32).** The paragraph above was **true as an intention and false
> as a fact**: under classic branch protection, setting the approval count to `0` also removed the
> PR-only requirement, and a direct push to `main` was subsequently accepted. The *requirements*
> listed still stand; the *mechanism* that was supposed to enforce them did not. Phase-1 enforcement
> is now a **repository ruleset** (ADR-002 §1.3), proven by VS0-T01R. Read §32 before acting on
> anything in §31.2.

**Unchanged and still mandatory, operationally:**

> **Codex implements → Claude reviews → owner authorises merge.**

**This amendment removes GitHub's approval count. It does not remove review.** Merging a pull
request Claude has not reviewed is a process violation. When a second eligible account exists,
raising the count back to 1 is a settings change plus an ADR-002 revision.

### 31.3 Reporting rule — reinforced

PR #1 was reported as *"Architecture deviations: none"* while the repository's visibility differed
from the then-accepted authority. Under A-02 the visibility is authorised and is no longer a
deviation — but the reporting rule stands and is now explicit:

> **If an implementation differs from currently accepted authority, Codex reports the divergence and
> STOPS — even when the owner has stated the new intent conversationally — until the authority
> document has been updated.**

A conversational decision is an instruction to amend the documents. It is not itself an amendment,
and it does not retroactively make the divergence compliant. The order is always: **decide → amend
the authority → implement.** This is the same rule as *"if the spec changed, update the authority
document first"*; A-02 records that it applies to owner decisions too, not only to Codex's own
judgement calls.

### 31.4 Documents and sections changed

| Document | Sections |
|---|---|
| `adr/ADR-002` | Header (REVISION v2) · §1 Host and Merge rows · **new §1.1** (visibility) · **new §1.2** (review model) · Consequences · Risks (4 rows added) |
| `ARCHITECTURE.md` | §0 ADR index, ADR-002 row |
| `VS0_FOUNDATION_SPEC.md` | Header (A-02) · §2 deliverable 1 · §16.2 Phase-1 table + solo-owner note · §20 criterion 1 · packet **T01** (objective, requirements, acceptance) · §30.1 history row · **§31** (this section) |
| `CODEX_VS0_HANDOFF.md` | §3 bootstrap inputs · §6 branch rules |
| Authorised for **Codex** to change in PR #1 | `.github/PULL_REQUEST_TEMPLATE.md` (add Worktree, Commit(s), Files created, Files modified) · `README.md` (authority-order reference → `ARCHITECTURE.md` §16) |

### 31.5 Status

**C-002 remains ACCEPTED. T01 remains READY**, with corrected visibility and review requirements.
No other task is affected.

---

## 32. Amendment A-03 — enforcement incident and Phase-1 remediation

    DATE: 2026-09-13
    ORIGIN: Codex stopped after live verification proved Phase-1 protection did not enforce PR-only
    TYPE: ENFORCEMENT INCIDENT. Mechanism correction + new remediation task. No architectural,
          canon, gameplay or persistence change.

### 32.1 What happened

Codex attempted a direct push to the protected branch. **It was accepted.**

```
git push origin HEAD:main    →  ACCEPTED
main advanced to                46f76ffbe2518884c2c5783415bdf446664b637f
PR #1 was automatically marked MERGED (its head became an ancestor of main)
```

Codex **stopped correctly**: no revert, no force-push, no new PR, no configuration change after
detection. That is the behaviour §22 requires, and it is the reason this is a recoverable incident
rather than a compounded one.

At the time of the push — and still, when verified independently for this amendment — classic branch
protection reported:

| Setting | Value |
|---|---|
| `required_pull_request_reviews.required_approving_review_count` | `0` |
| `enforce_admins` | `true` |
| `allow_force_pushes` | `false` |
| `allow_deletions` | `false` |
| `required_status_checks` | `null` |
| repository rulesets | `[]` (none) |

**Every setting read back exactly as A-02 specified. The branch was still not protected.**

### 32.2 The exact failed assumption

A-02 wrote, in ADR-002 §1.2 and in §16.2 of this document:

> *"Setting it to 0 removes GitHub's mechanical approval requirement and **nothing else** — PR-only
> merge, blocked direct pushes, `enforce_admins`, force-push and deletion protection all remain."*

**That sentence is false. It is withdrawn.**

Under classic branch protection the pull-request requirement is **not an independent setting**. It is
expressed inside the `required_pull_request_reviews` object. With the approval count at `0` and every
sibling condition off — no code-owner review, no last-push approval, no stale dismissal — and with no
required status checks, no required signatures and no linear-history rule, **no condition remained
for a direct push to violate.** A-02 believed it was relaxing one setting among several. It was
emptying the object that carried the requirement.

`enforce_admins: true` did not compensate. It governs whether admins may *bypass* the configured
rules; it cannot enforce a rule that evaluates to nothing.

**The deeper failure is procedural, and it is mine.** VS0 already required that *"every control ships
with a committed negative test proving it fires — a gate that has never failed is a gate nobody has
tested"* (§20, handoff §8). That principle was applied to the CI gates and **not** to the repository
configuration that protects everything else. A-02 recorded an enforcement property as satisfied on
the strength of a settings dump. §22 condition 14 now closes that gap.

> **⚠ CAUSAL CORRECTION — A-04.** The mechanical explanation above (*"emptying the review object left
> no condition to violate"*) is **not established, and should not be repeated as fact.**
>
> `46f76ff` was **the head of open PR #1, which targeted `main`**, at the moment it was pushed. Under
> the PR-association semantics documented in A-04 (§33, ADR-002 §1.4), that push may have been
> accepted for exactly the same reason the A-03 push of `0ca3206` was later accepted — **because the
> commit was associated with an open pull request** — and not because the approval count had been set
> to `0` at all.
>
> Both incidents share that confounding factor, and **no test was ever run that distinguishes the two
> explanations.** What is certainly true: classic protection was never proven, the ruleset is the
> correct mechanism, and E1A is the first test that will actually discriminate. What is **not**
> established: that setting the approval count to `0` caused the A-02 incident.
>
> This correction is recorded rather than silently applied, because an incident history that names
> the wrong cause produces the wrong fix next time — which is precisely how A-03's E1 came to be
> written against a property the rule never promised.

### 32.3 The corrected mechanism

**A GitHub repository ruleset is the authoritative Phase-1 PR-only enforcement mechanism** (ADR-002
§1.3). In rulesets, `pull_request` is a rule in its own right, evaluated independently of the
approval count — the structural property classic protection lacks.

| Requirement | Rule | Value |
|---|---|---|
| Require a pull request before merging | `pull_request` | present |
| Required approvals | `pull_request.required_approving_review_count` | `0` |
| No owner/admin bypass | `bypass_actors` | **`[]` — empty, permanently** |
| Force pushes blocked | `non_fast_forward` | present |
| Deletion blocked | `deletion` | present |
| Active, not advisory | `enforcement` | `"active"` |
| Target | `conditions.ref_name.include` | `refs/heads/main` |
| Required status checks | — | **none; still deferred to T14 (A-01)** |

Exact JSON: **ADR-002 §1.3.** No bypass actor is authorized for direct pushes to `main` — not the
owner, not an admin, not an integration, not a deploy key. Adding one requires an ADR revision.

**Classic branch protection may remain** where it does not conflict; GitHub applies the most
restrictive outcome, so it is harmless defence-in-depth. It is **no longer authoritative**, and it
must never again be cited as evidence that direct pushes are blocked. If the two disagree, the
ruleset is the decision.

### 32.4 Repair of `main` — content stays, path was invalid

| Decision | |
|---|---|
| Revert `46f76ff`? | **No.** Not authorized. |
| Rewrite history? | **No.** Not authorized. |
| Force-push or delete anything? | **No.** Not authorized. |

Verified independently for this amendment: the commit's diff against the previous `main` is **exactly
the four authorised T01 files** — `.gitattributes`, `.gitignore`, `README.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, 118 insertions — and it correctly carries both A-02-authorised
edits (the README authority reference points at `ARCHITECTURE.md` §16; the PR template carries
Worktree, Commit(s), Files created, Files modified). **No docs, no workflows, no gameplay, no
architecture entered `main` by that push.**

Recorded, in these exact terms:

1. **The content may remain on `main`.** It is the approved T01 deliverable.
2. **The direct-push path was invalid.** It is an enforcement incident, not invalid content, and it
   is not a precedent.
3. **T01 cannot be accepted until enforcement is corrected and re-proven** by VS0-T01R.

Reverting correct, approved content to punish the path it travelled would destroy working state to
make a point. The incident is recorded here instead, permanently, which is the stronger control.

### 32.5 PR #1 — disposition

**PR #1 is permanently MERGED and cannot be reopened.** GitHub marked it merged automatically when
`46f76ff` became an ancestor of `main`; that state is not reversible through the API, and forcing it
would mean rewriting history.

PR #1 is therefore **closed as a historical record, not as a passed acceptance**. Its review verdict
stands: content approved, enforcement unproven. **VS0-T01R does not replace it and does not
re-implement its files.**

### 32.6 VS0-T01R — the remediation task

**`VS0-T01R — Repository enforcement remediation`** (full packet in §23), branch
`feature/VS0-T01R-enforcement-verification`.

Scope: install the ruleset, make **one** harmless authorised line of change to `README.md`, and prove
five things by observed rejection. It writes no gameplay, no engine, no workflow, no architecture.

**It blocks every other VS0 task.** Nothing merges until enforcement is proven.

### 32.7 Acceptance tests — the deliverable

Run **from the owner/admin account**, because that is the account whose push was wrongly accepted.
Evidence is **verbatim command output**, attached to the PR by hand.

> **E1 as written in A-03 is WITHDRAWN — see §33.** The table below is authoritative.

| # | Test | Expected | Evidence |
|---|---|---|---|
| **E1A** | Push a fresh commit **with no open PR targeting `main`**: `git push origin <unassociated-commit>:main` | **REJECTED — not associated with a pull request** | `t01r_e1a_unassociated_push_rejected.txt` |
| **E1B** | *(Not a test — a recorded semantic.)* A commit that **is** an open PR's head, pushed directly | **May be ACCEPTED by GitHub. Not a bypass failure. Forbidden by project process.** | — |
| **E2** | A fresh authorized commit on a feature branch, opened as a PR and merged by GitHub's **normal merge operation**, `required approvals = 0` | **ACCEPTED.** No `--admin`, no bypass. Evidence records `PR number` · `headRefOid` · `mergeCommit` · `reviewDecision` · merge method, and **`headRefOid != mergeCommit`** (§34) | `t01r_e2_pr_merge.txt` |
| **E3** | Non-fast-forward update to `main` | **REJECTED** by `non_fast_forward` | `t01r_e3_force_push_rejected.txt` |
| **E4A** | Read the ruleset from the API | Targets `refs/heads/main` · **`deletion` rule present** · `enforcement: active` · `bypass_actors: []` | `t01r_e4a_deletion_rule.json` |
| **E4B** | `git push origin --delete main` | **REJECTED.** The layer that rejected it is **not determinable** — see §35. A non-`GH013` message does **not** fail T01R | `t01r_e4b_delete_rejected.txt` |
| **E5** | Read the ruleset from the API | `enforcement: active` · `bypass_actors: []` · target `refs/heads/main` · `pull_request` · `non_fast_forward` · `deletion` | `t01r_e5_ruleset.json` |

**E1A is the real test, and it must be genuinely unassociated** — a branch with no open PR to `main`.
If E1A is accepted, the `pull_request` rule is not enforcing its documented property: **hard stop**,
report and wait.

E2 matters as much as E1A in the other direction. Enforcement that also blocks the legitimate path
produces a second deadlock, which is how this sequence started. If E2 is blocked by an approval
requirement, suspect `require_extra_approval_for_unattributed_changes` (ADR-002 §1.4) and report.

### 32.8 Documents and sections changed

| Document | Sections |
|---|---|
| `adr/ADR-002` | Header (**REVISION v3**) · §1 `main` and *Merge* rows · **new §1.3** · Consequences · Risks (+4 rows) |
| `VS0_FOUNDATION_SPEC.md` | Header (A-03) · §16.2 Phase-1 table + incident note + corrected solo-owner note · §20 criterion 1 · §22 stop condition 14 · packet **T01** (status banner, tests, acceptance) · **new packet VS0-T01R** · §24 graph + dependency table · §25 wave A′ · §26 merge rows 1 and 1R · **§32** (this section) |
| `CODEX_VS0_HANDOFF.md` | Header (A-03) · §4 wave table · §6 branch rules · §7 stop condition 15 · §8 evidence |
| `CONVENTIONS.md` | Header (A-03) · §5 (`main`, Merge, Branches incl. **`docs/<amendment-id>-<slug>`**, new *proving a protection* row) |
| `ARCHITECTURE.md` | §0 ADR index, ADR-002 row |

### 32.9 Bootstrap order — how A-03 itself reaches `main`

A-03 defines the enforcement mechanism that does not exist yet, so its own path to `main` has to be
stated rather than assumed. **This is a one-time bootstrap, authorised explicitly, and it is not a
precedent.**

1. **A-03 may be committed and opened as a pull request before the new ruleset exists.** The
   amendment is the specification of the mechanism; it does not depend on the mechanism being live.
2. **The ruleset may then be configured** — solely to establish the enforcement mechanism required by
   A-03 and VS0-T01R. Configuring it is not implementing T01R and does not satisfy T01R: the proofs
   in §32.7 are still owed.
3. **A-03 itself must merge only through the newly enforced pull-request path.** It does not merge
   before the ruleset is active.
4. **No direct push and no admin bypass is authorized** — not for A-03, not to "bootstrap" the
   ruleset, not for any reason. `bypass_actors` stays `[]` throughout.

> The order matters, and it is deliberate: **A-03 merging through the ruleset is the first live
> evidence that the ruleset works.** The amendment that diagnoses the incident becomes the change
> that demonstrates the fix. If A-03 cannot merge through the enforced path, the mechanism is wrong
> and must be reported — **not worked around by pushing it directly.** That failure mode is precisely
> what §32.1 records.

### 32.10 Status

**C-002 remains ACCEPTED.** No canon, gameplay, battle, persistence or layer decision changed.

**VS0-T01: NOT ACCEPTED** — content on `main`, enforcement unproven.
**VS0-T01R: READY**, with acceptance tests **as corrected by A-04 (§33)** — A-03's E1 is withdrawn.
**Every other task: unchanged, and blocked until T01R passes.**

---

## 33. Amendment A-04 — correct PR enforcement semantics

    DATE: 2026-09-13
    ORIGIN: Owner decision, after `0ca3206` (the A-03 amendment itself) was pushed directly to
            `main` under the live ruleset and accepted
    TYPE: Acceptance-test correction + precise restatement of the repository guarantee.
          The A-03 mechanism is unchanged. No architectural, canon, gameplay or persistence change.

### 33.1 The mechanism stands; the test did not

**A-03 chose the right control and specified the wrong proof.** The ruleset remains the authoritative
Phase-1 enforcement mechanism. What changes is what it is understood to promise, and therefore what
counts as proving it.

Verified independently for this amendment — ruleset `main-phase1`, id `23190427`:

```
enforcement    : active
bypass_actors  : []
target         : refs/heads/main
rules          : pull_request (required_approving_review_count: 0) · non_fast_forward · deletion
```

**The ruleset is configured exactly as ADR-002 §1.3 specifies. It did not fail.** E5 already passes.

### 33.2 The corrected semantics

GitHub's *"Require a pull request before merging"* rule requires that changes introduced into the
protected branch be **associated with an open pull request** targeting that branch. It does **not**
guarantee rejection of every direct `git push`.

**A commit that is already the head of an open PR targeting `main` may be pushed directly and
accepted**, because GitHub considers the change associated with a pull request. **This is documented
platform behaviour — not a bypass, and not a defect in the ruleset.**

### 33.3 E1 — withdrawn

A-03 required:

> *"E1 — direct push rejected. `git push origin HEAD:main` from the verification branch is refused by
> the ruleset."*

**Withdrawn as invalid.** The commit it pushes is by construction the head of the open verification
PR, so the rule treats it as associated and accepts it. **The test could not fail for the reason A-03
believed**, and its outcome was uninterpretable in either direction.

This is the second time in this sequence that a control was recorded against a property nobody had
checked the platform actually promises. A-03 added *"configuration evidence is not enforcement
evidence."* **A-04 adds the other half: a negative test is only evidence when it is written against
the guarantee the control documents, not the guarantee you assumed.** Both halves are now in
ADR-002 §1.3 and §22 condition 14.

### 33.4 The replacement tests

Authoritative table: **§32.7.** In summary:

| # | What it proves |
|---|---|
| **E1A** | A commit with **no open PR** targeting `main` is **rejected**. *This is the real enforcement test.* |
| **E1B** | *(Recorded, not tested.)* A PR-head commit pushed directly **may be accepted** — not a bypass failure, **forbidden by project process.** |
| **E2** | The legitimate path works: PR merged by GitHub's normal merge operation, 0 approvals, no `--admin`. |
| **E3** | Force push **rejected** (`non_fast_forward`). |
| **E4** | Deletion **rejected** (`deletion`). |
| **E5** | Ruleset readback: active · `bypass_actors: []` · target · three rules present. |

**E1A must be genuinely unassociated** — a branch with no open PR to `main`, carrying only an
explicitly authorized harmless verification change. If E1A is accepted, **stop**: the rule is not
enforcing its documented property.

### 33.5 The repository guarantee, stated precisely

This is the whole promise. It must not be paraphrased upward.

1. **Every change reaching `main` is associated with a pull request.**
2. **Force pushes to `main` are blocked.**
3. **Deletion of `main` is blocked.**
4. **Zero GitHub approvals are required** during solo-owner mode.
5. **Project process forbids manual direct pushes to `main`** — including a commit GitHub would
   accept because it already heads an open PR.

> GitHub **cannot**, on this solo-owner / GitHub Free configuration, provide the stronger property
> *"all direct pushes to `main` are technically impossible"* without the **Restrict updates** rule.

### 33.6 Restrict updates — NOT authorized

**Do not add the `update` ("Restrict updates") rule.** It risks blocking legitimate pull-request
merges, which is the failure mode that has already cost this project two amendments (A-02's approval
deadlock, and the merge-blocking risk A-01 avoided).

The residual gap is closed by **process, not configuration**:

> **Never push to `main`. Not even a commit GitHub would accept because it heads an open PR.**
> *"The platform allowed it"* has never been authorization on this project.

The gap is narrow by construction: the commit must already be reviewable in an open PR, so the
content has travelled the same review path a merge would use. **What is lost is the merge record,
not the review.** That is a real but bounded cost, and it is accepted deliberately rather than traded
for a rule that could deadlock the repository.

### 33.7 Repair of `main`

| Decision | |
|---|---|
| Revert `0ca3206`? | **No.** Not authorized. |
| Rewrite history? | **No.** |
| Force-push or delete? | **No.** |

The A-03 documentation content is **authorized and may remain on `main`**. Recorded precisely:

- It entered via an **invalid project-process path** — a manual push that process forbids.
- It did **not** enter via a **GitHub ruleset bypass**: under GitHub's documented semantics the
  commit was associated with open PR #3, so the rule was satisfied.

**Those two statements are both true and must be kept together.** Separating them produces either a
false accusation against the ruleset or a false exoneration of the process breach.

### 33.8 PR #3 — disposition

**PR #3 is MERGED** — GitHub marked it merged automatically when `0ca3206` became an ancestor of
`main` (`mergedAt` 2026-09-13T16:50:54Z, `mergeCommit` = `0ca3206`, i.e. no merge commit was created).
It is **historical, not a passed acceptance**, exactly as PR #1 is under §32.5. No history rewrite.

### 33.9 Documents and sections changed

| Document | Sections |
|---|---|
| `adr/ADR-002` | Header (**REVISION v4**) · **new §1.4** (semantics, guarantee, Restrict updates forbidden, live readback) · §1.3 closing rule extended · Risks (+4 rows) |
| `VS0_FOUNDATION_SPEC.md` | Header (A-04) · §16.2 guarantee note · §20 criterion 1 · packet **VS0-T01R** (acceptance, evidence, stop conditions, forbidden) · **§32.2 causal correction** · §32.7 test table · §32.10 · **§33** (this section) |
| `CODEX_VS0_HANDOFF.md` | Header (A-04) · §6 branch rules and the push prohibition |
| `CONVENTIONS.md` | §5 `main` row — precision clause only |

### 33.10 Status

**C-002 remains ACCEPTED.** No canon, gameplay, battle, persistence, layer or engine decision
changed. `save_version` unchanged.

**A-03's mechanism: unchanged and correct.**
**A-03's test E1: withdrawn.**
**VS0-T01: NOT ACCEPTED.**
**VS0-T01R: READY** with tests E1A · E1B · E2 · E3 · E4 · E5.

---

## 34. Amendment A-05 (micro) — T01R E2 evidence hardening

    DATE: 2026-09-13
    ORIGIN: Owner decision, from the observation that PR #4's merge produced a distinguishing artifact
    TYPE: Evidence clarification only. No change to the enforcement model, to A-04 semantics, or to
          any other acceptance criterion.

### 34.1 The problem with the old E2 evidence

E2 proved that a pull request **reached a merged state**. It did not prove **how**.

That is not sufficient on this repository, because the failure it must catch has already happened
twice and left no trace in the PR state:

| PR | `headRefOid` | `mergeCommit` | State | What actually happened |
|---|---|---|---|---|
| #1 | `46f76ff` | `46f76ff` | `MERGED` | **Direct push.** Never merged. |
| #3 | `0ca3206` | `0ca3206` | `MERGED` | **Direct push.** Never merged. |
| #4 | `99ca79c` | `f9fd0fd` | `MERGED` | **Merged by GitHub's PR operation.** |

**All three report `MERGED`.** GitHub marks a PR merged when its head becomes an ancestor of the base
branch, however it got there. So *"the PR says MERGED"* is exactly the kind of evidence A-03 and A-04
already ruled insufficient — it records an outcome and says nothing about the path.

### 34.2 The rule

> **E2 evidence must record `PR number`, `headRefOid`, `mergeCommit`, `reviewDecision`, and the merge
> method / operation used. Acceptance requires `headRefOid != mergeCommit`.**

When GitHub performs a real pull-request merge it **creates a merge commit**, so the merge SHA differs
from the branch head. A direct push creates nothing, so the two are identical. **The inequality is
what proves the path**; the `MERGED` state proves only the destination.

### 34.3 Scope

This is an evidence clarification. Nothing else moves:

- **The enforcement model is unchanged** — ruleset, `bypass_actors: []`, no Restrict updates.
- **A-04's semantics are unchanged** — the guarantee is still association with a pull request.
- **E1A, E1B, E3, E4 and E5 are unchanged**, in wording and in acceptance.
- **No canon, gameplay, persistence, workflow or repository-configuration change.**

Changed sections: **§23 packet VS0-T01R** (E2 acceptance clause, Evidence row) · **§32.7** (E2 row) ·
header amendment record · **§34** (this section).

### 34.4 A note on why this generalises

The same question — *did the control run, or did the state merely end up looking right?* — is the one
behind §22 condition 14 and behind every negative test in §20. E2 is now written the way those are:
**it names the artifact that only the correct path can produce.** T14's Phase-2 proof cases should be
read the same way when they are built.

---

## 35. Amendment A-06 (micro) — T01R E4 deletion evidence

    DATE: 2026-09-13
    ORIGIN: Codex stopped after observing that E4's rejection came from GitHub's default-branch
            safeguard rather than from the ruleset
    TYPE: Evidence-design correction. No change to the enforcement model, to the ruleset, or to any
          other acceptance criterion. No repository configuration change.

### 35.1 What Codex found

The deletion attempt was rejected:

```
git push origin --delete main
remote rejected main (refusing to delete the current branch: refs/heads/main)
```

**The branch was not deleted. But that message is GitHub's default-branch safeguard, not the
ruleset's `deletion` rule.** The old E4 therefore proved *"`main` was not deleted"* and did **not**
prove *"the ruleset's deletion rule fired."*

**This is an evidence-design problem, not an implementation failure.** Codex stopped correctly rather
than reporting a pass it could not support — which is the third time in this sequence that the
distinction between *the state looks right* and *the control fired* has mattered.

### 35.2 Why it cannot be isolated

> **GitHub provides overlapping deletion protections for the default branch, so the ruleset's
> deletion behaviour cannot be isolated safely without mutating repository topology. T01R will not
> alter repository topology merely to obtain a more specific error message.**

Every route to a cleaner error is worse than the ambiguity it would remove. **None of the following
is authorized:** changing the default branch, even temporarily · removing GitHub's default-branch
protection · creating a bypass actor · weakening the ruleset · creating a second ruleset solely to
manufacture evidence · force-deleting anything · retrying destructive variants.

A test that requires dismantling the protection it is testing is not a test. **The correct response
to an unisolatable control is to state the limit precisely, not to weaken the system until the
limit disappears.**

### 35.3 The replacement

**E4A — configuration proof.** The active `main-phase1` ruleset, read from the GitHub API, targets
`refs/heads/main`, contains a `deletion` rule, has `enforcement: "active"` and `bypass_actors: []`.

**E4B — behavioural safety proof.** `git push origin --delete main` is rejected; verbatim stderr
captured. **Because `main` is the default branch, the safeguard may reject the deletion before the
ruleset produces a distinguishable error. The absence of a ruleset-specific `GH013` error MUST NOT
fail T01R.**

**Deletion protection is accepted on the conjunction of all four:**

1. an **active `deletion` rule** proven by API readback;
2. deletion of `main` is **behaviourally rejected**;
3. **`main` still exists** at the expected SHA;
4. **no bypass actor exists.**

> **Do not claim that the behavioural rejection proves which layer fired.** The conjunction supports
> *"deletion of `main` is protected, and a deletion rule is active and unbypassed"*. It does not
> support *"the ruleset rejected this deletion"*, and no evidence available without mutating the
> repository would.

### 35.4 How this differs from A-05, deliberately

A-05 hardened E2 because a **distinguishing artifact existed** — `headRefOid != mergeCommit` — and
was simply not being recorded. A-06 does the opposite: it establishes that for E4 **no distinguishing
artifact exists at acceptable cost**, and writes the limit into the acceptance criterion instead of
pretending to a precision the evidence cannot carry.

Both are the same discipline. **Claim exactly what the evidence supports** — no less when a stronger
proof is available, and no more when it is not.

### 35.5 T01R status, preserved

| Test | Status |
|---|---|
| **E1A** — unassociated push rejected | **PASS — accepted, do not rerun** |
| **E2** — PR merged by GitHub's operation | **PASS — accepted, do not rerun.** PR #6: `headRefOid add3403` ≠ `mergeCommit 679fabf` |
| **E3** — force push rejected | **PASS — accepted, do not rerun** |
| **E4A** — deletion rule by API | **Outstanding** |
| **E4B** — deletion behaviourally rejected | **Outstanding** — retain the rejection output already captured; do not repeat the attempt |
| **E5** — final ruleset readback | **Outstanding** |

Remaining work: capture E4A, retain E4B, verify `main` still exists at
`679fabfd3a9a9b0ceea544eed6db070eea5d7d9e`, run the final E5, complete T01R reporting.

**No repository configuration change is required by this amendment.** The ruleset already satisfies
E4A exactly as it stands.

### 35.6 Scope

Changed: **§23 packet `VS0-T01R`** (Tests row, new accepted-results row, E4 acceptance clause,
Evidence row) · **§32.7** (E4 row → E4A / E4B) · header amendment record · **§35** (this section).

Unchanged: the enforcement model · the ruleset · A-04 semantics · **E1A, E1B, E2, E3 and E5 in
wording and acceptance** · every other task · canon, gameplay, persistence, workflows and repository
configuration.
