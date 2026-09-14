# CODEX — VS0 HANDOFF

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AMENDED: A-01 (2026-09-12) — two-phase branch protection; see spec §30
             A-02 (2026-09-13) — repository PUBLIC; 0 approving GitHub reviews; see spec §31
             A-03 (2026-09-13) — ENFORCEMENT INCIDENT: `main` is protected by a repository
             RULESET, not classic branch protection. VS0-T01R added and blocks everything.
             See spec §32 and ADR-002 §1.3.
             A-04 (2026-09-13) — PR-enforcement semantics corrected. The guarantee is
             ASSOCIATION with a PR, not rejection of every push. T01R test E1 withdrawn,
             replaced by E1A/E1B. See spec §33 and ADR-002 §1.4.
    TASK STATUS: ACCEPTED — VS0-T01, VS0-T01R, VS0-T02. Spec §39 is the acceptance ledger
                 and is authoritative on task status. T01/T01R detail §37; T02 detail §38
                 and §39.1 (owner decisions: game version `0.1.0`, window not resizable
                 in VS0).
                 NEXT: VS0-T03 — the last task blocking VS0-T04. Its packet was corrected
                 in spec §40; read the VS0-T03 DIRECTORY MANIFEST in spec §23 and build
                 from it, not from the §5 tree. §5 is the VS0 end-state SHAPE, not a T03
                 file list.
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

| Parameter | Value |
|---|---|
| `GITHUB_OWNER` | `inmoaiasistente-luisma` |
| `GITHUB_REPOSITORY` | `galapagos-the-origin` |
| Visibility | **PUBLIC** (ADR-002 §1.1) |

Both values are now supplied. The repository is **public by deliberate owner decision** — the GitHub
plan does not provide the required branch protection on private repositories. **Everything you commit
is published.** Never commit a secret, credential or token.

---

## 4. Execution order

Ten waves. Do not start a wave until the previous one is merged green.

| Wave | Tasks | Delivers |
|---|---|---|
| **A** | T01 Repository bootstrap | Repo, LFS, ignore rules, README, PR template. **No workflow file, no required status checks — deferred to T14 by owner decision.** **Files are on `main`. T01 was ACCEPTED by the owner on 2026-09-14, once T01R proved enforcement (spec §37).** |
| **A′** | **T01R Enforcement remediation** | The Phase-1 **ruleset**, and **live proof** that direct push, force-push and deletion of `main` are rejected and that a PR merges with 0 approvals. **Blocked every later wave; COMPLETE and ACCEPTED 2026-09-14 — the block is discharged (spec §37).** |
| **B** | T02 Godot baseline · T03 Folder skeleton | 4.7.2 pinned, pixel contract, folder tree. **T02 ACCEPTED 2026-09-14 (spec §39). T03 outstanding — directories and ownership markers only; see spec §23 manifest and §40.** |
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
| Branch naming | `feature/VS0-T0n-<slug>` · `fix/VS0-T0n-<slug>` · `docs/<amendment-id>-<slug>` *(documentation and ADR amendments — Claude and Luisma only)* |
| **Enforcement mechanism** | **A GitHub repository ruleset** (ADR-002 §1.3), `enforcement: "active"`, **`bypass_actors: []`**. **Classic branch protection is not authoritative and must never be cited as proof that a push is blocked.** |
| **What the rule actually guarantees** | Every change reaching `main` is **associated with an open pull request** (ADR-002 §1.4). It does **not** reject every direct push: **a commit that already heads an open PR may be pushed directly and accepted by GitHub.** That is documented behaviour, not a bypass — **and project process forbids you from ever using it.** |
| `main` | **Protected.** No direct pushes, no force-push, no deletion — by anyone, including you and including the owner. |
| Merge | Pull request only — the ruleset's `pull_request` rule |
| Approving GitHub reviews required | **0** — solo-owner phase (spec §16.2, §31.2). **This removes GitHub's approval count, not the review.** |
| Required status checks | **Phase 2, added by T14**, once the real workflows exist with stable check names |
| Worktrees | One per writing agent, always |
| Scope | PR diff must stay inside the task's `ALLOWED PATHS` |
| `.github/workflows/` | **T14 owns it exclusively.** No other task creates or edits a workflow. |
| Red gate | **Blocks merge.** Never "fixed" by weakening or skipping the test. |

> **`git push origin HEAD:main` has succeeded on this repository twice, and should never have been
> attempted either time** (spec §32, §33). On the second occasion the ruleset was live and correctly
> configured — GitHub accepted the push because the commit already headed an open PR, which the
> `pull_request` rule counts as associated. **The platform was working as documented. The process was
> not being followed.**
>
> **Never push to `main`. Not to unblock yourself, not to save a round trip, not because GitHub let
> you, and not because the commit is already in an open PR.** *"The platform allowed it"* is not
> authorization; the process is the authorization. **The only path to `main` is GitHub's own merge
> operation on a pull request.**
>
> If a push to `main` is ever accepted again, **stop and report it as an incident** — do not revert
> it, do not force-push over it, do not reconfigure anything. And **never** propose closing the gap
> with the **Restrict updates** rule: it is explicitly forbidden (ADR-002 §1.4) because it would block
> legitimate merges.

**Between T01 and T14 there are no required status checks, and that is deliberate** (spec §16.2,
§30). Run your task's gates **locally**, through the same headless entry points CI will call. **Do
not create a temporary, bootstrap or placeholder check to fill the gap — none is authorized.** The
deferral is an approved hardening item: do not report it as technical debt or as an architecture
deviation.

**Review is still mandatory, and GitHub no longer enforces it for you.** The sequence is:

> **Codex implements → Claude reviews → owner authorises merge.**

Never merge your own pull request, and never treat "GitHub allows it" as "the process permits it".

If the implementation violates the spec, fix the implementation. If the spec changed, the authority
document is updated **first** — and that is Claude's and Luisma's job, not yours.

**This applies to owner decisions too.** If Luisma tells you something in conversation that differs
from an accepted document — a different visibility, a different value, a different rule — that is an
instruction to **amend the document**, not permission to implement the difference. Report the
divergence, stop, and wait for the amended authority. **Decide → amend → implement**, in that order,
every time.

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
14. The implementation would differ from currently accepted authority — **including when Luisma
    stated the new intent conversationally.** A conversational decision is an instruction to amend
    the document, not permission to implement the difference. **Decide → amend → implement.**
15. **A control, gate or protection cannot be shown to fire.** Reading the configuration back is not
    proof. If the negative test does not fail as expected — the push is accepted, the lint passes
    broken input, the guard does not trip — **stop.** Do not proceed on the assumption that it works.
    **Configuration evidence is not enforcement evidence** (spec §22 condition 14, §32).

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

**Enforcement and protection properties are evidenced only by observed rejection.** A settings page,
an API dump or a configuration diff proves what was *requested*, never what the platform *does*. The
evidence for "direct pushes are blocked" is a push that was **refused**, captured verbatim — nothing
else counts. This is the same rule as the negative tests above, and it is in this handoff because
ignoring it for repository configuration cost VS0 an accepted direct push to `main` (spec §32).

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
