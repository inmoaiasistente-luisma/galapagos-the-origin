# CONVENTIONS — GALÁPAGOS: THE ORIGIN

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    APPLIES TO: all production GDScript, data, documentation and repository workflow
    ENFORCED BY: CI gate 1 (convention lint) wherever mechanically possible

---

## 1. Language (owner decision 8)

| Context | Language |
|---|---|
| Code identifiers | **English** |
| Technical code comments | **English** |
| Technical architecture documentation | **English** |
| Narrative / content authoring | **Spanish** (initial canonical) |
| Required localization | **English** (mandatory) |
| **Canonical names** | **Exactly canonical — never translated, never anglicised** |

Canonical names are preserved verbatim as IDs and enum values:

```gdscript
species_id = &"mariguin"          # canonical name, snake_case, never "sea_iguana"
region_id  = &"tierras_altas"     # canonical toponym, never "highlands"
BondState.RESONANCIA              # canon state, never "RESONANCE"
MoveCategory.REACCION             # canon category, never "REACTION"
```

**The rule in one line:** English for everything we invented; canonical Spanish, unchanged, for
everything the canon named.

> The C-001 audit document is in Spanish because it was written for owner review before this rule
> existed. Everything from this point forward is English.

---

## 2. GDScript

### 2.1 Static typing is mandatory

Every variable, parameter and return type in production code is explicitly typed. Untyped
production GDScript fails CI gate 1.

```gdscript
# Correct
func get_entry_state(species_id: StringName) -> CodexEntryState:
    var entry: CodexEntryState = _entries.get(species_id, CodexEntryState.UNKNOWN)
    return entry

# Rejected
func get_entry_state(species_id):
    var entry = _entries.get(species_id)
    return entry
```

Typing is not style here. It is the only cheap defence in a data-driven codebase where hundreds of
IDs move through contracts as strings, and it is what makes the canon-protected contracts
(`CompassReading`, `BondEvaluation`, `BattleActionResult`) verifiable.

### 2.2 Naming

| Element | Convention | Example |
|---|---|---|
| File | `snake_case.gd` | `codex_system.gd` |
| Class | `PascalCase` | `class_name CodexSystem` |
| Function / variable | `snake_case` | `record_sighting` |
| Private member | leading `_` | `_entries` |
| Constant | `SCREAMING_SNAKE` | `MAX_TEAM_SIZE` |
| Enum type / values | `PascalCase` / `SCREAMING_SNAKE` | `BondState.ESTABLECIDO` |
| Signal | **past tense**, `snake_case` | `tikawi_bonded` |
| Command method | imperative verb | `bond_attempt` |
| Query method | `get_` / `is_` / `can_` / `find_` | `can_traverse` |
| Test file | `test_<subject>.gd` | `test_battle_timeline.gd` |
| Scene | `snake_case.tscn` | `battle_stage.tscn` |

### 2.3 `class_name`

Declare `class_name` only for types reused **outside** their own folder: facades, shared value
objects, generated canon types, save DTOs. `class_name` is a global namespace entry; internal
helpers do not get one.

### 2.4 File size

**Maximum 500 lines.** A file exceeding it is a design signal, not a formatting problem: split by
responsibility, not by line count.

### 2.5 Comments

Comment the **why**, never the **what**. `## Docstrings` on every public facade method: what it
owns, what it emits, what it does not do.

```gdscript
# Correct — records a non-obvious constraint
# Deferred: emitting inside the mutation would let ResearchSystem observe a half-written entry.

# Useless — restates the code
# Emit the signal
```

### 2.6 Forbidden patterns (CI gate 1)

| Forbidden | Instead |
|---|---|
| `randi()` / `randf()` global | `RngService` named stream *(ADR-005 §6)* |
| `if species_id == ...` in systems | capability / `behavior_tags` *(ADR-003 §7)* |
| Literal user-facing strings | localization keys *(ADR-004 §8)* |
| `get_node("../../..")` across modules | facade call or event |
| `TileMap` (deprecated) | `TileMapLayer` |
| Direct writes to `GameState.<substate>` outside its owner | the owning system's facade |
| Hand-edited files under `data/generated/` | edit the source, regenerate |
| Untyped production declarations | explicit types |

---

## 3. Data and IDs

| Rule | Detail |
|---|---|
| Format | JSON, 2-space indent, keys `snake_case`, UTF-8, LF endings |
| IDs | `snake_case` strings, immutable, **never reused**, registered append-only |
| Ordering | Files sorted deterministically so diffs stay readable |
| `codex_number` | Presentation metadata only — **never identity, never in a save** |
| Comments | JSON has none; use a `_note` field where explanation is needed |
| **Performance archetype IDs** | **`PascalCase`**, from the closed registry — `Dash`, `Leap`, `Dive`, `Charge`, `Spin`, `Wing`, `Tail`, `Bite`, `Projectile`, `Beam`, `Arc`, `GroundBurst`, `AreaPulse` |

**Why archetype IDs are the one `PascalCase` exception in data.** Every other data ID is `snake_case`
because it names an instance of content — a species, a region, a move. An archetype names a **type of
presentation component**, and it maps one-to-one onto a class in `presentation/performance/`. Keeping
the two spellings identical means the registry entry and the class implementing it cannot drift
apart, and the CI check that every recipe references a real archetype becomes a direct name lookup
rather than a transformation. Adding an archetype is a registry entry plus the matching class; the
linter rejects an archetype ID that is not `PascalCase`, and one with no implementing class.
*(ADR-006 §5.1)*

**Localization keys** are generated from IDs, never hand-written:

```
tikawi.<species_id>.name
tikawi.<species_id>.codex_desc
research.<species_id>.stage_<n>
move.<move_id>.name
region.<region_id>.name
```

Canonical proper names are listed as **non-translatable**; CI fails if their value differs between
locales.

---

## 4. Tests

| Rule | Detail |
|---|---|
| Framework | GUT, pinned and vendored *(ADR-002 §3)* |
| Location | `tests/unit/`, `tests/integration/`, `tests/canon/` |
| Naming | `test_<subject>.gd`, one behaviour per test function |
| Determinism | Any test touching randomness sets an explicit seed |
| Fixtures | `tests/fixtures/saves/` — **never regenerated, never edited** |
| **Never weaken a test to make a change pass** | If implementation violates spec, fix the implementation. If the spec changed, update the authority first. |
| Canon tests | Live in `tests/canon/` and are permanent. They are never "cleaned up". |

---

## 5. Repository workflow

| Item | Convention |
|---|---|
| Branches | `feature/<task-id>-<slug>` · `fix/<task-id>-<slug>` |
| `main` | Protected. No direct pushes by anyone, including agents. |
| Merge | Pull request with review |
| Parallel agents | One writing agent per **git worktree**; write scope = the task's `ALLOWED PATHS` |
| Commits | Imperative subject, ≤72 chars, prefixed with the task ID: `X-001: add save envelope` |
| Commit trailers | **No `Co-Authored-By` trailer** unless project settings enable attribution |
| PR description | Task ID · summary · tests run · validator result · **persistence impact** · canon impact · architecture deviations |
| Scope | **No drive-by refactors.** Unrelated debt is recorded separately, not fixed in passing. |
| LFS | `*.png`, `*.ogg`, `*.wav`, `*.aseprite` |
| Always committed | `*.import` files |
| Never committed | secrets, `.env`, `.godot/`, exports, local editor state |

---

## 6. Documentation

Every document begins with:

```
    STATUS: DRAFT | PROPOSED | ACCEPTED | SUPERSEDED
    AUTHORITY LEVEL: <1-9>
    DATE: YYYY-MM-DD
```

**A document without this header is not authority.** ADRs are `docs/adr/ADR-NNN-<slug>.md` and are
immutable once ACCEPTED — a change is a new ADR that supersedes the old one, never an edit.
