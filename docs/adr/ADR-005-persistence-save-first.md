# ADR-005 — Persistence Architecture and Save-First Sequencing

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    AMENDS: milestone roadmap — VS9 redefined
    OWNER DECISIONS APPLIED: 5 (Persistence — APPROVED), 11 (Position persistence),
                             Review §4 (Reserve capacity 240, FINALIZAR VÍNCULO),
                             Final 11 (Reserve paging + filtering), Final 12 (FINALIZAR VÍNCULO),
                             Final 16 (Vertical Slice scope boundary)

## Context

The save model's *contents* were well designed. Its *position* in the roadmap was not: seven
systems with durable state were scheduled before persistence existed. Owner decision 5 approves
moving the Save Core forward.

## Decision

### 1. Sequencing (owner decision 5 — APPROVED)

**Save Core lands in VS0/VS1:** versioned envelope, Windows-correct atomic write, backup rotation,
recovery, a **functioning but empty migration harness**, and **golden fixture v1** frozen in VS0
and checked in CI forever.

**Every milestone introducing durable state delivers, as mandatory acceptance criteria:**
persistence mapping · save schema impact · migration when needed · regression/fixture coverage.

> **No milestone closes with durable state that is unpersisted and unmigrated.**

**VS9 is redefined** as **Save UX / QoL**: slots, autosave policy, save UI, settings, player
recovery flows — no longer the first appearance of persistence. Per Final §16, VS9 also carries
**options, accessibility settings and control rebinding**, which is why §2 places settings in a
separate config file rather than in the save.

**Scope boundary (Final §16).** VS0–VS12 is the **Vertical Slice roadmap**, not full Volume I
production. This ADR's persistence framework is built to full production quality because retrofitting
it is the failure it exists to prevent — but the **content** it persists stays inside Vertical Slice
scope. Post-VS12 content expansion is a `save_version` bump plus an ordinary `N → N+1` migration,
which is exactly what §5 is for.

### 2. Runtime state is not the save payload

| | Runtime state | Save DTO |
|---|---|---|
| Lives in | `core/state/` | `core/save/dto/` |
| Purpose | what the game needs now | a versioned, stable contract |
| Freedom | refactor freely | changes only with a version bump + migration |
| Mapping | `to_save_dict()` / `from_save_dict(version)` per substate |

Without this split, every internal refactor becomes a schema change and the project accumulates
trivial migrations until nobody wants to touch state. Moving the Save Core forward **without** it
would merely freeze an accidental schema earlier.

**Admission rule.** No field enters the DTO without a written justification that it is a *durable
consequence*, reviewed at each milestone via the task template's `Persistence Impact` field.

**Never persisted:** node references · derived values · caches · presentation state · the `cosmetic`
RNG stream · settings and key rebindings (these live in a separate config file, so changing options
never touches a save) · anything recomputable from data plus persisted state.

### 3. Format and envelope

| Item | Decision |
|---|---|
| Format | **JSON** — diffable, inspectable for support, trivially migratable |
| Not used | Godot `Resource`/`.tres` saves (loading them can resolve script paths — an unnecessary hazard) and opaque binary (undiagnosable in the field) |
| Envelope | `save_version`, `game_version`, `created_at`, `updated_at`, `checksum`, `payload` |
| Versioning | **`save_version` independent of `game_version`** |
| Size | Tens to low hundreds of KB, including a full 240-slot reserve |

**Checksum detects corruption, not tampering.** Single-player, offline, no anti-cheat. A hand-edited
save that validates structurally loads normally.

### 4. Atomic write — Windows-correct

The POSIX `write-temp → rename-over` idiom is **not** safely portable to Windows: replacing an
existing file has different semantics, and file locks or antivirus handles can make a rename fail
transiently. Unspecified, this fails on the *target* platform, on the player's machine, with their
progress.

```
write temp → flush + close → re-read and verify checksum
→ rotate current to backup → move temp into place → verify → clean up
```

The backup is **never** destroyed before the new file verifies. Rename failure is an *expected* case
with bounded retry, not an impossible exception. `user://` resolves under the Windows user profile;
the real path is documented for support.

**VS0 test, mandatory:** simulate interruption at **every** step and assert a loadable save always
remains.

### 5. Migrations and golden fixtures

| Rule | Detail |
|---|---|
| Chain | Sequential `N → N+1`. No version-skipping migrations. |
| Golden fixtures | On every `save_version` bump, a real save of the **previous** version is frozen into `tests/fixtures/saves/`. **Never regenerated, never edited.** |
| CI gate 8a | Load **every** historical fixture, migrate to current, assert **semantic** invariants — team survives, reserve survives, Codex progress survives, bonded Tikawi still exist with their personality, position resolves, quests remain coherent. "It didn't crash" is not a pass. |
| CI gate 8b | **Schema hash guard.** If the persisted schema changes without a `save_version` bump and a registered migration, the build fails. |
| Forward saves | A future-version save is **rejected cleanly** — never partially read, never overwritten |

Gate 8b makes "no persisted change without a migration" impossible to forget, including by an agent.

### 6. Deterministic RNG (`RngService`)

Named independent streams: `battle`, `encounter`, `weather`, `loot`, `cosmetic`.

- Independent so consuming randomness in one system cannot shift another's outcomes — the classic
  cause of tests that "break by themselves".
- Master seed and per-stream counters are **persisted**, except `cosmetic`.
- `cosmetic` is non-deterministic, non-persisted, and **must never** influence game state.
- **Forbidden:** global `randi()` / `randf()` in any game system. CI grep.
- Every `BattleActionResult` records the seed consumed (ADR-006), making any battle reproducible.

### 7. Position persistence (owner decision 11)

```json
"position": { "region_id": "...", "entry_point_id": "...", "local_offset": [x, y] }
```

`region_id` + `entry_point_id` are **authoritative**; `local_offset` is a refinement. On load,
validate the offset against the current region; if the region was re-authored and it is no longer
valid, **fall back to the entry point**. Degrade, never fail, never spawn inside geometry. Maps will
be re-authored many times; the save must survive it.

### 8. Roster capacity and bond exit (Review §4)

**8.1 Reserve capacity**

| Item | Decision |
|---|---|
| Active team maximum | **6** (canon, unchanged) |
| **Maximum reserve capacity** | **240 Tikawi** |
| Storage | **Data/config-driven**, not a hardcoded constant |

| **Reserve UI** | **Paged and filterable from the start** (Final §11) |

The value lives in config so an owner-approved expansion later requires no architectural redesign —
only a config change plus a UI review. At 240 instances the save remains well inside the size
envelope in §3, but the **reserve UI must be paged *and* filterable from the start**, and a
large-reserve performance test is required from VS9.

**Filtering is a requirement, not a convenience.** Paging alone makes 240 individuals *navigable*;
it does not make a specific individual *findable*. Filtering and sorting — by species, type, region
of origin, evolution stage, bond state, personality — must therefore be designed into the reserve
query API from the first version, not bolted onto a paged list later. Concretely: `RosterSystem`
exposes a filtered, sorted, paged query rather than "give me everything, the UI will sort it";
otherwise the UI ends up loading all 240 instances to filter them itself, which is the performance
failure the cap was meant to bound.

**8.2 FINALIZAR VÍNCULO**

A voluntary bond may be ended by the player, as a `RosterSystem` command.

| Rule | Detail |
|---|---|
| Context | Only in an approved **safe physical context**, such as Casa del Naturalista |
| **Never** | sells the Tikawi · grants money · treats it as inventory |
| Effect | The Tikawi leaves team/reserve and **returns to the world/ecological abstraction** |
| Prohibition | Narrative, special and ancestral individuals may forbid the action, via the `no_bond_exit` behaviour tag (ADR-003 §7) — never a `species_id` check |
| **Codex/research history survives** | `CodexState` is owned by `CodexSystem` and is **not touched** by roster operations |
| Event | `bond_ended` (past tense, deferred) |
| Identity | The retired `instance_id` is **never reused** (ADR-004 §2) |

The Codex guarantee falls out of the existing ownership split rather than needing special handling:
roster operations cannot write Codex state, so knowledge cannot be lost when an individual leaves.
This is the canon principle made structural — *"Capturar una especie demuestra que la encontraste.
Comprenderla demuestra que la conoces."* Understanding does not depend on possession.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **Keep Save at VS9 as originally planned** | Seven systems would define durable state with no persistence contract, then have it retrofitted — the direct cause of the save-breaking-change risk. |
| **Serialize `GameState` directly** | The obvious shortcut. Makes every internal refactor a schema change and drags caches and node references into the save. |
| **Binary saves (`var_to_bytes`)** | Compact and fast; undiagnosable when a player reports a corrupted file, and migrations become opaque. Size is not a constraint here. |
| **Godot `Resource` / `.tres` saves** | Natively convenient; loading a resource can resolve script paths, an unnecessary hazard for a file the player can edit. |
| **Save-anywhere with full world snapshot** | Maximum convenience; enormous schema surface and far more migration burden. Consequence-based persistence is the canon direction. |
| **Skip-version migrations (`v1 → v5` directly)** | Fewer steps to write; combinatorial explosion of paths and untestable in practice. Sequential chaining is verifiable. |
| **Regenerate golden fixtures when schemas change** | Removes fixture maintenance, and removes the entire point: a regenerated fixture tests the case that cannot fail. |
| **Unlimited reserve** | No cap to design around; unbounded save growth, load time and an unnavigable UI, all discovered late on real playthroughs. |
| **Paged reserve UI without filtering** | Cheaper in VS9. Rejected per Final §11: 240 individuals across 20 pages is navigable but not searchable, and retrofitting filtering means reworking the query API after the UI depends on its shape. |
| **Persisting a denormalized index to make filtering fast** | Faster queries; adds derived data to the save, which §2 forbids. 240 in-memory instances filter fast enough without it. |
| **Bond exit as "release anywhere"** | Simpler; contradicts the canon that bonding is a considered, contextual act, and invites accidental loss of a companion. |

## Consequences

- Persistence becomes a design constraint from day one rather than archaeology in VS9.
- Fixtures accumulate permanently. Intended: they are the only evidence old saves still load.
- JSON saves are player-readable. Accepted — support value outweighs obscurity offline.
- A 240-slot reserve makes a paged **and filtered** reserve query, plus a large-reserve performance
  test, non-optional. The filtering requirement shapes the `RosterSystem` query API, not just the UI.
- Ending a bond is a deliberate, located act with no economic dimension, and costs no knowledge.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Atomic write fails intermittently on Windows under AV or file locks | High | §4 explicit sequence, bounded retry, backup preserved, interruption test at every step |
| A persisted schema change ships without a migration | High | §5 gate 8b schema-hash guard; mechanical, not discretionary |
| Fixture suite grows slow as versions accumulate | Low | Fixtures are small; the suite runs headless in seconds |
| 240-slot reserve degrades load time or UI responsiveness | Medium | Paged **and filtered** query from the start; large-reserve performance test from VS9; compact instance storage (`STATE_OWNERSHIP.md` §4) |
| Reserve filtering is deferred as "UI polish" and implemented by loading all 240 instances | Medium | Filtering belongs to the `RosterSystem` query API (§8.1), specified here rather than left to VS9 UI work |
| A player ends a bond by accident and loses a companion | Medium | Safe-context restriction plus confirmation; `no_bond_exit` for narrative individuals |
| Save DTO drifts back into mirroring runtime state under delivery pressure | Medium | Admission rule reviewed per milestone; the DTO folder is small and visible by design |
| Players edit saves and then report bugs | Low | Accepted. Checksum is corruption detection; no anti-cheat is built. |

## Migration / compatibility impact

This ADR **is** the migration framework. Its own compatibility impact:

- **Save Core arrives before any content**, so fixture v1 is nearly empty and every later schema
  addition is an ordinary `N → N+1` step rather than a first-time serialization of seven systems.
- **`EnvironmentState` and `RngState`** (ADR-003 §5) enter the schema at VS0, avoiding a later bump.
- **`personality_trait`** (ADR-004 §9) enters at VS2 with the first instances, avoiding a backfill
  migration over already-bonded Tikawi.
- **Reserve capacity is config, not schema.** Raising 240 later changes no persisted shape and needs
  no migration — only a UI and performance review. This is the specific reason for making it
  config-driven. Filter and sort criteria are likewise **derived at query time from persisted
  instance fields**, so adding a new filter is never a schema change.
- **`bond_ended`** removes an instance from the roster and touches no other substate, so it requires
  no migration; the retired `instance_id` is never reused, which keeps historical references valid.
- **Position** is stored as `region_id` + `entry_point_id`, so re-authoring maps is not a migration.
  Only renaming a region or entry point ID is — hence the ID rules in ADR-004 §2.
- **Settings and rebindings live outside the save**, so options changes never risk player progress.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-006** — Save Core scheduled at VS9 | §1 |
| **AUD-010** — GameState conflated with save payload | §2 |
| **AUD-033** — seeded RNG absent from architecture and save | §6 |
| **AUD-034** — Windows atomic-write specifics unaddressed | §4 |
| **AUD-035** — no golden fixture or migration discipline | §5 |
| **AUD-045** — reserve capacity and bond-exit semantics undefined | §8 — **now resolved** |

## Open items

**None blocking.** Owner decision 5 settles sequencing; Review §4 settles reserve capacity and bond
exit. §2–§8 are the engineering consequences.
