# ADR-002 — Repository, CI, Dependencies and Test Framework

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    OWNER DECISIONS APPLIED: 1 (Repository/CI), 6 (Testing), 10 (Scope), 19 (Dialogue)

## Context

The entire agent-control model — isolated branches, reviewed merges, allowed paths, CI gates,
reproducible evidence — presupposes a repository that did not exist. VS0 also requires a test
framework and a validator framework, while Codex is forbidden from choosing dependencies.

## Decision

### 1. Repository

| Item | Decision |
|---|---|
| Host | **GitHub, private repository** |
| CI | **GitHub Actions**, `windows-latest` runner |
| `main` | **Protected.** No direct pushes, by anyone, including agents. |
| Merge | **Pull request only**, with review |
| Branches | `feature/<task-id>-<slug>`, `fix/<task-id>-<slug>` |
| Parallel agents | **Git worktrees**, one per writing agent |
| Large binaries | **Git LFS APPROVED** (Final §7) for `*.png`, `*.ogg`, `*.wav`, `*.aseprite`. Other binary patterns only when justified. |
| Ignored | `.godot/`, `export/`, `*.tmp`, local editor state |
| Committed | **`*.import` files** — omitting them breaks reproducible imports |

**Worktree protocol.** One writing agent per worktree, always. A task packet's `ALLOWED PATHS` is
the write scope; CI verifies the PR diff touches nothing outside it. Read-only research agents may
run concurrently and report to the owning agent. Only the integration owner edits shared manifests,
the ID registry, or reconciles overlapping changes.

### 2. Dependency policy

> **Every third-party dependency is pinned to an exact version, vendored into the repository, and
> requires an ADR. No dependency may be fetched at build time or at run time.**

This is what makes offline-first true in practice, and what keeps a build from a five-year-old
commit reproducible.

**Scope clarification (C-002 owner review, decision 3).** The rule above governs **project
libraries, plugins and runtime dependencies** — anything the game links against, loads, or ships.
It does **not** govern the **external toolchain**, which is the engine editor and its export
templates.

| | Rule |
|---|---|
| **Project dependencies** (GUT, and any future addon) | **Vendored in the repository.** CI must **never** download them. GUT in particular is committed at `addons/gut/` and is never fetched dynamically. |
| **External toolchain** (Godot editor, export templates) | CI **may download** it, and only under all four conditions: **exact version** · **explicit URL/source** · **SHA-256 verified** · **no `latest` URL and no floating version**. |

A download that satisfies those four conditions is reproducible and auditable, which is the property
the original rule exists to protect. A `latest` URL satisfies none of them and is forbidden.

**Approved allowlist: exactly one entry (§3).** Out of scope per owner decision 10, and therefore
requiring no dependency at all: network, telemetry, analytics, modding, audio middleware.

### 3. Test framework — GUT (APPROVED, Final §6)

**GUT (Godot Unit Test), vendored at `addons/gut/`, pinned to the exact release verified against
the engine version pinned in ADR-001 §1.**

| Criterion | GUT | gdUnit4 |
|---|---|---|
| Pinnable exact version | Yes | Yes |
| Vendorable, no network | Yes, plain addon folder | Yes, larger addon |
| GDScript-only (matches "no .NET") | **Yes** | Carries unused C# support |
| Headless CLI + CI reporting | Yes, incl. JUnit XML | Yes, richer |
| Surface exposed to engine upgrades | **Smaller** | Larger |
| Scene runner / input simulation | No | **Yes** |

The decisive factor is what this project actually tests. The heavy work — battle timeline
assertions, data and canon validators, save migrations against golden fixtures, reachability
analysis, RNG determinism — is **pure GDScript with no scene involved**. GUT covers all of it.
gdUnit4's real advantage is its scene runner, and a project-owned verification harness is required
regardless (§5), serving that purpose without enlarging the dependency.

**Re-evaluation trigger:** if frame-stepping or input simulation becomes necessary for
controller-focus or battle-presentation testing and the project harness cannot provide it
economically, reopen this section.

**VS0 gate:** the pinned GUT release must run headless against the pinned Godot version before
either pin is final. On incompatibility, the engine pin wins and the framework is re-examined.

### 4. Validators are project-owned

Schema, semantic and canon validators are written by us, with no dependency. They encode domain
rules no third party can supply, and they are how canon becomes verifiable (ADR-004). They run in
the editor and as headless scripts.

### 5. Evidence and verification harness

A no-fabricated-PASS rule without a mechanism becomes prose. VS0 delivers the mechanism:

- **Scene load smoke test** — load every scene headless, fail on any script error.
- **Verification scenes** — scripted deterministic sequences, runnable headless, writing
  screenshots to fixed paths, attached to the PR as artifacts.
- **Required evidence by task type** declared in the task packet, not improvised afterwards.

Anything requiring human judgement — movement feel, performance quality — is evidenced by a short
recording and reviewed by **Luisma**, never certified by an agent.

### 6. CI gate order

Cheapest-first. VS0 delivers gates 1–6.

| # | Gate | From |
|---|---|---|
| 1 | Convention lint: static typing, naming, file size, forbidden patterns | VS0 |
| 2 | Layer dependency lint (ADR-003) | VS0 |
| 3 | Data validation: schema → semantic → canon (ADR-004) | VS0 |
| 4 | Generated-artifact freshness: regenerate and diff | VS0 |
| 5 | Unit tests (GUT, headless) | VS0 |
| 6 | Windows export | VS0 |
| 7 | Scene load smoke test | VS0/VS1 |
| 8 | Save: golden fixtures migrate + schema-hash guard (ADR-005) | VS0 |
| 9 | Localization: missing/orphan keys, proper-noun invariance (ADR-004) | VS2 |
| 10 | Canon boundaries: Compás, Bond, `species_id` grep (ADR-007) | VS4 |
| 11 | Reachability / anti-soft-lock (ADR-008) | VS7 |

`main` stays buildable. A red gate blocks merge; it is never "fixed" by weakening the test.

### 7. Dialogue and quest runtime

Per owner decision 19: **custom, minimal, data-driven runtime. No dialogue plugin.**

- Dialogue and quest data are JSON, validated at build time.
- Conditions and effects come from a **single closed vocabulary**, shared with evolution and
  research (ADR-004 §5). One grammar for the whole game, not three.
- All dialogue text is localization keys. No literal strings in scenes or scripts.
- Rumors model `claim` and `truth` as separate fields (promoted canon).
- Adopting any dialogue dependency later requires a new ADR.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **Local-only repository, no remote CI** | Preserves zero external services, but Codex would self-certify every PASS — removing the main control against optimistic reporting. |
| **gdUnit4** | Richer, incl. scene runner. Rejected on surface area: larger dependency, unused C# support, higher cost at every ADR-gated engine upgrade. Recorded with a re-evaluation trigger. |
| **Custom test runner, zero dependencies** | Avoids the dependency entirely, but we would maintain assertions, discovery, headless running and CI reporting ourselves. Effort belongs in canon tests, not in a runner. |
| **Dialogue addon (e.g. a graph-based plugin)** | Saves weeks in VS6. Rejected because general-purpose plugins encourage arbitrary expressions, drifting straight into the "quest data must not become a programming language" failure canon forbids. |
| **Fetching dependencies at build time** | Simpler CI, breaks offline-first and reproducibility of old commits. |
| **Trunk-based development without PRs** | Faster for a solo developer, removes the review gate that exists specifically because agents write the code. |

## Consequences

- A GitHub account and private repository become project infrastructure.
- Codex gains an objective gate it cannot self-certify — the point of the arrangement.
- Vendoring makes dependency updates deliberate, reviewed events.
- The custom dialogue runtime is a real cost carried in VS6, accepted for canon safety.
- Git LFS affects clone size and GitHub storage quota.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Pinned GUT incompatible with pinned Godot | High | §3 VS0 gate resolves before either pin is final; engine pin wins |
| CI gates grow slow enough that they get bypassed | Medium | Cheapest-first ordering; gates added incrementally, never all at once |
| Custom dialogue runtime under-delivers and VS6 slips | Medium | Closed vocabulary keeps scope bounded; re-evaluation via ADR if it proves insufficient |
| Worktree discipline breaks and two agents write the same file | High | One writer per worktree; `ALLOWED PATHS` diff check in CI |
| LFS quota or clone size becomes painful as art lands | Low | Reviewed at VS10; asset budget tracked via the completeness report |
| GitHub outage blocks work | Low | Offline-first: local clone is fully buildable and testable without the network |

## Migration / compatibility impact

**Save compatibility: none.** This ADR touches no persisted data.

- Changing CI host later is a workflow rewrite, not a code change; the gates are scripts and remain
  portable by design.
- Replacing the test framework later means rewriting test harness calls across the suite — the
  reason it is pinned deliberately rather than drifted into.
- Adopting a dialogue dependency later would require migrating dialogue/quest JSON into that
  plugin's format, a content migration. Recorded here as the reversal cost.
- `*.import` files committed from VS0 keep imports reproducible across an engine upgrade; an
  upgrade may rewrite them en masse, which is an expected, reviewable diff.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-001** — no repository, branch policy or CI host | §1 |
| **AUD-007** — VS0 requires a test framework Codex may not choose | §3, §4 |
| **AUD-027** — dialogue runtime dependency unevaluated | §7 |
| **AUD-051** — required evidence had no mechanism | §5 |

## Open items

**None.** Final §6 approves GUT; Final §7 approves Git LFS for the listed binary classes. The only
remaining action is mechanical: pin the exact GUT release verified against the pinned Godot version
during VS0 (§3).
