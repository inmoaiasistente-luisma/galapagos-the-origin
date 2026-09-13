# CODEX — VS0 HANDOFF

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AMENDED: A-01 (2026-09-12) — two-phase branch protection; see spec §30
    AUTHORITY LEVEL: 4 (operational handoff — subordinate to VS0_FOUNDATION_SPEC.md)
    FOR: Codex (implementation agent)
    SCOPE: VS0 only

> **This is an operational handoff, not a specification.** It tells you what to read, in what order
> to work, and when to stop. **`VS0_FOUNDATION_SPEC.md` is the specification**, and where the two
> ever differ, the spec wins and this document is wrong.

---

## 1. Read before you start

| Order | Document | Why |
|---|---|---|
| 1 | **`docs/VS0_FOUNDATION_SPEC.md`** | Your actual instructions. Read it whole once, then re-read the sections each task packet names. |
| 2 | `docs/canon/01_GALAPAGOS_THE_ORIGIN_MASTER_CANON.md` | *Technical baseline* · *Pixel contract* · *Authority*. **Canon outranks everything, including the spec.** |
| 3 | `docs/ARCHITECTURE.md` | Layers, folders, autoloads, contracts, data rules, pixel contract, persistence, CI gates |
| 4 | `docs/CONVENTIONS.md` | All of it. This is what CI gate 1 enforces on your code. |
| 5 | `docs/STATE_OWNERSHIP.md` | Who may mutate what |
| 6 | `docs/adr/ADR-001` … `ADR-005` | The decisions behind VS0 |
| 7 | `docs/adr/ADR-006` … `ADR-008` | **Context only.** Nothing in them is built in VS0. Read them so you do not foreclose them. |

Each task packet in spec §23 lists its own required reading. Re-read those sections at the start of
the task, not from memory.

---

## 2. Fixed values — never choose these

| Item | Value |
|---|---|
| Engine | **Godot 4.7.2-stable**, standard build |
| Language | **GDScript. No .NET, no C#.** |
| Export templates | **Godot 4.7.2**, matching the editor exactly |
| Pre-release builds | **Godot 4.8 dev/pre-release is NOT authorized** |
| Renderer | **Compatibility** (`gl_compatibility`) |
| Virtual resolution | **320 × 180**, integer scaling, centred, Nearest filtering |
| World tile | **16 × 16** |
| Test framework | **GUT**, vendored at `addons/gut/`, matching Godot 4.7, highest qualifying patch |
| Autoloads in VS0 | **Exactly four**, in order: `EventBus` → `GameState` → `RngService` → `SaveManager` |
| Save format | **JSON**, `save_version: 1` |
| Default locale | `es`, fallback `en` |

**Version verification is mandatory before any export:** `editor == templates == 4.7.2`. On
mismatch, **stop**. Do not export, do not substitute a nearby version.

**Toolchain vs dependencies:** CI **may** download the pinned Godot editor and templates — exact
version, explicit URL, SHA-256 verified, **never a `latest` URL**. **GUT is vendored in the
repository and is never downloaded by CI.** (ADR-002 §2.)

---

## 3. Bootstrap inputs you do not have yet

| Parameter | Status |
|---|---|
| `GITHUB_OWNER` | **Supplied by Luisma.** Not yet known. |
| `GITHUB_REPOSITORY` | **Supplied by Luisma.** Not yet known. |

Produce every part of T01 that does not need them. **Stop at the step that does.** Do not invent an
account name, an organization, or a placeholder that looks real.

---

## 4. Execution order

Ten waves. Do not start a wave until the previous one is merged green.

| Wave | Tasks | Delivers |
|---|---|---|
| **A** | T01 Repository bootstrap | Repo, **Phase-1** branch protection, LFS, ignore rules, README, PR template. **No workflow file, no required status checks — deferred to T14 by owner decision.** |
| **B** | T02 Godot baseline · T03 Folder skeleton | 4.7.2 pinned, pixel contract, folder tree |
| **C** | T04 GUT | Headless test runner, gate 5 |
| **D** | T05 Convention lint · T06 Layer lint · T07 Validator framework | Gates 1, 2, 3 (partial) |
| **E** | T08 Canon Registry + generators | Gates 3, 4 complete |
| **F** | T09 EventBus + GameState · T12 Localization | First two autoloads, ES/EN |
| **G** | T10 RngService · T13 Input | Determinism, semantic actions |
| **H** | T11 Save Core | **Gate 8** — envelope, atomic write, fixture v1, schema hash |
| **I** | T15 Boot + smoke + evidence | Gate 7, the end-to-end proof |
| **J** | T14 CI + Windows export | Gate 6, the real workflows, and **Phase-2 protection** — required checks added under their exact names and proven in four cases |

Full dependency graph: spec §24. Merge order and the gate that goes live at each merge: spec §26.

---

## 5. Parallel work

**Parallel-safe waves: B (T02 ‖ T03) · D (T05 ‖ T06 ‖ T07) · F (T09 ‖ T12) · G (T10 ‖ T13).**

Everything else runs alone. T11 Save Core runs alone deliberately — it defines the persistence
contract every later milestone depends on.

Rules, without exception:

- **One writing agent per git worktree. Always.**
- A task's `ALLOWED PATHS` is your write scope. **Verify the diff yourself before opening the PR**;
  from T14 onward CI verifies it too. Staying inside scope is your obligation either way — the check
  catches mistakes, it does not define the rule.
- Read-only research may run concurrently and report to the owning agent.
- Only the integration owner edits shared manifests or reconciles overlapping changes.
- `tools/generators/generate_all.gd` and `tools/validators/validate_all.gd` **discover** their
  members by file scan. Adding a generator or validator means **adding a file**, never editing a
  shared registration list. Do not "simplify" this into a hardcoded list — it exists to remove
  merge conflicts between the parallel waves.

---

## 6. Branch and worktree rules

| Rule | Value |
|---|---|
| Branch naming | `feature/VS0-T0n-<slug>` · `fix/VS0-T0n-<slug>` |
| `main` | **Protected from T01.** No direct pushes, no force-push, no deletion — by anyone, including you. |
| Merge | Pull request only, with review |
| Required status checks | **Phase 2, added by T14**, once the real workflows exist with stable check names |
| Worktrees | One per writing agent, always |
| Scope | PR diff must stay inside the task's `ALLOWED PATHS` |
| `.github/workflows/` | **T14 owns it exclusively.** No other task creates or edits a workflow. |
| Red gate | **Blocks merge.** Never "fixed" by weakening or skipping the test. |

**Between T01 and T14 there are no required status checks, and that is deliberate** (spec §16.2,
§30). Run your task's gates **locally**, through the same headless entry points CI will call. **Do
not create a temporary, bootstrap or placeholder check to fill the gap — none is authorized.** The
deferral is an approved hardening item: do not report it as technical debt or as an architecture
deviation.

If the implementation violates the spec, fix the implementation. If the spec changed, the authority
document is updated **first** — and that is Claude's and Luisma's job, not yours.

---

## 7. Stop conditions

**Stop, report, and do not proceed** when any of these occurs. Full list: spec §22.

1. A task needs a decision the spec does not make — a value, a name, a threshold, a format, a library.
2. The spec contradicts an ADR, `ARCHITECTURE.md`, `CONVENTIONS.md` or the Master Canon.
3. Two accepted documents contradict each other.
4. A canon rule cannot be implemented as specified.
5. The installed editor is not `4.7.2-stable`, or editor and templates differ.
6. No GUT release matches Godot 4.7 — **the engine pin wins.**
7. A required 2D feature is missing under the Compatibility renderer.
8. The task would require an upward layer dependency, or a **layer-lint exception**.
9. The task would require a **fifth autoload**.
10. The task would change the persisted schema without a `save_version` bump.
11. A test fails and the only available fix is to weaken or skip it.
12. The task cannot be completed within its `ALLOWED PATHS`.
13. The work would exceed VS0 scope (spec §2, §3).
14. `GITHUB_OWNER` / `GITHUB_REPOSITORY` are needed and unknown.

**Report format:** what you attempted · which document and section caused the stop · the two
conflicting requirements · what you would need in order to proceed.

> **Do not implement your proposed resolution.** A stop that arrives with the fix already applied is
> a violated stop. Filling a gap reasonably is exactly the failure this rule prevents: the
> reasonable fill becomes de-facto architecture, and every later correction has to fight working
> code. **Stopping is the deliverable.**

---

## 8. Required completion evidence

**You never self-certify a PASS.** A task is done when CI produced the artifact and the artifact
says so. Every PR carries, automatically:

| Artifact | From |
|---|---|
| `convention_lint.txt` | gate 1 |
| `layer_lint.txt` + `layer_graph.json` | gate 2 |
| `validation_report.json` | gate 3 |
| `generated_diff.txt` | gate 4 |
| `gut_results.xml` (JUnit) | gate 5 |
| `save_migration_report.txt` + `schema_hash.txt` | gate 8 |
| `smoke_scene_load.txt` | gate 7 |
| `export_log.txt` + exported binary | gate 6 |
| `evidence/*.png` | pixel and renderer evidence |
| `boot_report.txt` | end-to-end boot proof |

Artifacts upload **on failure as well as on success**. Full definitions: spec §19.

**Every control ships with a committed negative test proving it fires** — the layer lint on a
deliberate upward edge, the canon validator on broken matrix data, the schema-hash guard on an
unversioned change, gate 1 on global RNG use. A gate that has never failed is a gate nobody has
tested. Spec §20 items 10, 14, 18 and 21.

Anything requiring human judgement — how the pixel grid looks — is evidenced by a screenshot and
**reviewed by Luisma**, never certified by an agent.

**Before T14, gate evidence is produced locally** by the same headless commands CI will run, and
attached to the PR by hand. From T14 onward CI produces it automatically and branch protection
enforces it.

---

## 9. Out of scope — do not build

Player movement · camera · tilemaps with content · `SceneManager` · `TimeManager` · `AudioManager` ·
Tikawi runtime · battle · type effectiveness **evaluation** · Compás · Bond · Codex · research ·
quests · dialogue · field abilities · economy · inventory · save slots · options or rebinding UI ·
navigation · fishing · diving · Masters · Legendarios · any of the 150 Codex entries.

Full list with earliest milestones: spec §3. Deliberate omissions and why: spec §29.

> **VS0 exists to make VS1 safe to start. Anything that does not make VS1 safer belongs to VS1 or
> later.**

---

## 10. Definition of done

VS0 is complete when **all 28 criteria in spec §20** are true and each is demonstrated by an
artifact. That checklist is the acceptance gate. This handoff does not restate it, and passing "most
of it" is not passing it.
