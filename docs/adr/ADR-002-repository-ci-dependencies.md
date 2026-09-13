# ADR-002 — Repository, CI, Dependencies and Test Framework

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    OWNER DECISIONS APPLIED: 1 (Repository/CI), 6 (Testing), 10 (Scope), 19 (Dialogue)
    REVISION: v2 (2026-09-13) — repository visibility PUBLIC; solo-owner review model.
              Supersedes the original private-repository requirement. See §1.1.
    REVISION: v3 (2026-09-13) — Phase-1 PR-only enforcement moved from classic branch
              protection to a GitHub repository RULESET, after live verification proved
              classic protection did not enforce it. See §1.3. ENFORCEMENT INCIDENT.
    REVISION: v4 (2026-09-13) — PR-enforcement semantics corrected. The ruleset mechanism
              stands; the guarantee it provides is ASSOCIATION with a pull request, not
              rejection of every direct push. See §1.4. Restrict updates NOT authorized.

## Context

The entire agent-control model — isolated branches, reviewed merges, allowed paths, CI gates,
reproducible evidence — presupposes a repository that did not exist. VS0 also requires a test
framework and a validator framework, while Codex is forbidden from choosing dependencies.

## Decision

### 1. Repository

| Item | Decision |
|---|---|
| Host | **GitHub, PUBLIC repository** — `inmoaiasistente-luisma/galapagos-the-origin` (owner decision, 2026-09-13; see §1.1) |
| CI | **GitHub Actions**, `windows-latest` runner |
| `main` | **Protected by a repository ruleset** (§1.3). No direct pushes, by anyone, including the owner and admins. |
| Merge | **Pull request only, enforced by the ruleset in §1.3.** Review is **operationally mandatory** (§1.2); GitHub's approving-review count is **0** during the solo-owner phase. |
| Branches | `feature/<task-id>-<slug>`, `fix/<task-id>-<slug>` |
| Parallel agents | **Git worktrees**, one per writing agent |
| Large binaries | **Git LFS APPROVED** (Final §7) for `*.png`, `*.ogg`, `*.wav`, `*.aseprite`. Other binary patterns only when justified. |
| Ignored | `.godot/`, `export/`, `*.tmp`, local editor state |
| Committed | **`*.import` files** — omitting them breaks reproducible imports |

### 1.1 Repository visibility — PUBLIC (owner decision, 2026-09-13)

> **Superseded history:** this ADR originally required a **private** repository. That requirement no
> longer applies anywhere in active authority.

**Reason for the change:** the current GitHub plan does not provide the required branch-protection
features on private repositories, while a public repository supports the accepted protection model
in full. Protection was judged more valuable than concealment, and the decision was made
deliberately rather than discovered.

**Consequences accepted with the decision:**

- The repository's contents — including the accepted canon under `docs/canon/` — are world-readable
  from now on. Treat every commit as published.
- **Never commit a secret, credential or token.** On a public repository a leaked secret is
  compromised the moment it is pushed, and deleting it later does not un-publish it.
- GitHub Actions minutes are not billed on public repositories. **Git LFS quota is billed per
  account regardless of visibility**, so visibility saves nothing there.
- Reverting to private later is an owner decision requiring an ADR revision, and would not retract
  anything already published.

### 1.2 Review model during the solo-owner phase

The repository currently has **one eligible GitHub account**, and GitHub does not permit a pull
request's author to satisfy their own approval requirement. A non-zero required-approval count
therefore makes **every** pull request permanently unmergeable.

| | Value |
|---|---|
| `required_approving_review_count` | **0** |
| Pull request required for any change to `main` | **Yes** |
| Direct pushes to `main` | **Blocked** |
| `enforce_admins` | **true** |
| Force-push to `main` | **Blocked** |
| Deletion of `main` | **Blocked** |
| Required status checks | Deferred to T14 (Amendment A-01) |

**Review has not been removed; only GitHub's mechanical approval count has.** The review sequence is
unchanged and remains mandatory:

> **Codex implements → Claude reviews → owner authorises merge.**

Merging a pull request that Claude has not reviewed is a process violation, not a shortcut. When a
second eligible account exists, raising the approval count back to 1 is a settings change plus an
ADR revision.

### 1.3 Phase-1 enforcement mechanism — repository ruleset (owner decision, 2026-09-13)

> **This section exists because the previous mechanism was tested and failed.** It is recorded as an
> **enforcement incident**, not as a preference change.

#### What happened

With `required_approving_review_count` set to `0` under **classic branch protection** — the
configuration A-02 approved — a direct push to the protected branch was **accepted**:

```
git push origin HEAD:main        →  ACCEPTED
main advanced to                     46f76ffbe2518884c2c5783415bdf446664b637f
```

At the moment of that push the protection API reported, and still reports:

```
required_pull_request_reviews.required_approving_review_count : 0
enforce_admins                                                : true
allow_force_pushes                                            : false
allow_deletions                                               : false
required_status_checks                                        : null
```

**Every setting read back exactly as specified, and the branch was not protected from a direct
push.** Codex detected this and stopped without reverting, force-pushing or reconfiguring anything.

#### The falsified assumption

ADR-002 §1.2 and VS0 spec §16.2 asserted, in A-02:

> *"Setting it to 0 removes GitHub's mechanical approval requirement and **nothing else** — PR-only
> merge, blocked direct pushes, `enforce_admins`, force-push and deletion protection all remain."*

**That sentence is false and is withdrawn.** Under classic branch protection the pull-request
requirement is not an independent setting: it is expressed *inside* the
`required_pull_request_reviews` object. With the approval count at `0` and every other sub-condition
off (`require_code_owner_reviews`, `require_last_push_approval`, `dismiss_stale_reviews` all
`false`), and with no required status checks, no required signatures and no linear-history rule,
**no condition remained for a direct push to violate.** A-02 did not weaken one setting beside the
others — it emptied the object that carried the PR requirement.

`enforce_admins: true` did not save it. That flag governs whether admins may *bypass* the configured
rules; it cannot enforce a rule that evaluates to nothing.

#### The corrected mechanism

**A GitHub repository ruleset is now the authoritative Phase-1 PR-only enforcement mechanism.** In
rulesets, `pull_request` is a **rule in its own right**, evaluated independently of how many
approvals it requires — which is precisely the structural property classic protection lacks.

| Requirement | Rule |
|---|---|
| Require a pull request before merging | `pull_request` rule present |
| Required approvals | `required_approving_review_count: 0` |
| No owner/admin bypass | **`bypass_actors: []` — empty, and it stays empty** |
| Force pushes blocked | `non_fast_forward` rule |
| Deletion blocked | `deletion` rule |
| Required status checks | **None — still deferred to T14** (Amendment A-01) |

Authoritative configuration:

```json
{
  "name": "main-phase1",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    { "type": "non_fast_forward" },
    { "type": "deletion" }
  ]
}
```

**`bypass_actors` must remain empty.** No bypass actor is authorized for direct pushes to `main` —
not the owner, not an admin, not an integration, not a deploy key. Adding one re-creates the hole
this section exists to close, and requires a revision of this ADR.

*(Rulesets are available on GitHub Free for **public** repositories. The visibility decision in §1.1
is therefore what makes this mechanism available on the current plan — the two decisions are
connected, and reverting §1.1 would also remove §1.3.)*

#### Classic branch protection — retained, subordinate

Classic protection on `main` **may remain** while it does not conflict with the ruleset. GitHub
evaluates both and applies the most restrictive outcome, so leaving it in place is harmless
defence-in-depth. It is **no longer authoritative for PR-only enforcement** and must never again be
cited as evidence that direct pushes are blocked. If the two ever disagree, the ruleset is the
decision and classic protection is corrected to match.

#### The rule this incident establishes

> **Configuration evidence is not enforcement evidence.** A settings screenshot or an API dump proves
> what was *requested*, not what the platform *does*. An enforcement property may only be recorded as
> satisfied when a **live negative test** has been observed to fail — a push that was actually
> rejected.

This principle was already in force for code (*"every control ships with a committed negative test
proving it fires; a gate that has never failed is a gate nobody has tested"* — VS0 spec §20).
**It was not applied to repository configuration, and that omission is what A-02 got wrong.** It now
applies to both, and T14's Phase-2 proof cases are the same rule applied to required status checks.

**A-04 adds the other half of the rule.** A negative test is only evidence when it is **specified
against the property the control actually promises**. A-03's E1 tested a property the `pull_request`
rule never claimed, so its outcome was uninterpretable either way — a test that cannot fail for the
stated reason is no better than the settings dump it replaced. **Write the test against the
documented guarantee, not against the guarantee you assumed.** (§1.4.)

### 1.4 What the `pull_request` rule actually guarantees (owner decision, 2026-09-13)

> **The A-03 mechanism stands. The A-03 acceptance test did not.** §1.3 chose the right control and
> specified the wrong proof.

#### The corrected semantics

GitHub's *"Require a pull request before merging"* rule requires that changes introduced into the
protected branch be **associated with an open pull request** targeting that branch. It does **not**
guarantee rejection of every direct `git push`. **A commit that is already the head of an open pull
request targeting `main` may be pushed directly and accepted** — GitHub considers the change
associated with a pull request, so the rule is satisfied.

This is documented platform behaviour, **not a bypass and not a defect in the ruleset.**

#### The withdrawn test

A-03 required, as acceptance test E1:

> *"`git push origin HEAD:main` from the verification branch is refused by the ruleset."*

**That test is invalid and is withdrawn.** The commit it pushes is by construction the head of the
open verification PR, so the rule treats it as associated and accepts it. The test could not fail for
the reason A-03 believed, and passing or failing it proved nothing about enforcement.

It is replaced by **E1A** (a genuinely unassociated commit, which must be rejected) and **E1B** (the
associated-commit behaviour, recorded rather than tested). Full definitions: VS0 spec §32.7.

#### The guarantee, stated precisely

This is what the repository does and does not promise. Nothing here may be paraphrased upward into a
stronger claim.

| | |
|---|---|
| Every change reaching `main` is **associated with a pull request** | **Guaranteed** — `pull_request` rule |
| Force pushes to `main` | **Blocked** — `non_fast_forward` |
| Deletion of `main` | **Blocked** — `deletion` |
| Approving GitHub reviews required | **0**, during solo-owner mode |
| A commit with **no** open PR can reach `main` | **No** — rejected (E1A proves it) |
| A commit that **is** an open PR's head can be pushed directly | **Yes, GitHub accepts it** — and **project process forbids it** |

> **"All direct pushes to `main` are technically impossible" is not achievable** on the current
> solo-owner / GitHub Free configuration without the **Restrict updates** rule.

#### Restrict updates — NOT authorized

**Do not add the `update` ("Restrict updates") rule to this ruleset.** It would block legitimate
pull-request merges, re-creating the deadlock that A-02 and A-03 already cost this project twice. The
residual gap — a PR-head commit pushed manually — is closed by **process, not by configuration**:

> **Never push to `main`. Not even a commit that GitHub would accept because it heads an open PR.**
> "The platform allowed it" has never been authorization on this project.

The gap is narrow by construction: the commit must already be reviewable in an open PR, so the
content has been through the same path a merge would use. What is lost is the merge record, not the
review.

#### Live configuration, read back 2026-09-13

Ruleset `main-phase1`, id `23190427` — `enforcement: "active"`, `bypass_actors: []`, target
`refs/heads/main`, rules `pull_request` / `non_fast_forward` / `deletion`. **Matches §1.3.**

GitHub populated two `pull_request` parameters that §1.3 did not specify:

| Parameter | Value | Disposition |
|---|---|---|
| `allowed_merge_methods` | `["merge", "squash", "rebase"]` | **Accepted.** No merge method is restricted in VS0. |
| `require_extra_approval_for_unattributed_changes` | `true` | **Accepted, and watched.** A commit whose author is not attributable to a GitHub account can demand an approval that a solo owner cannot give. If E2 is ever blocked by an unattributed-changes approval, **that is a stop, and this parameter is the first suspect.** |

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

- A GitHub account and a **public** repository become project infrastructure; everything committed is published (§1.1).
- **A repository ruleset becomes project infrastructure** (§1.3), and its configuration is normative: `enforcement: active`, `bypass_actors: []`. It is verified by live negative test, not by reading it back.
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
| A secret or credential is committed to a **public** repository | **High** | Nothing in Volume I requires a secret (no network, no telemetry, no analytics). `.gitignore` excludes `.env*`. A leak is unrecoverable by deletion, so the control is never creating one. |
| Canon is world-readable before release | Accepted | Deliberate owner decision (§1.1). The trade was protection over concealment. |
| Review is skipped because GitHub no longer enforces an approval | **Medium** | §1.2 makes Claude's review mandatory as process; the sequence is recorded in the ADR rather than in anyone's memory |
| A protection setting reads back correctly but does not enforce | **Realised — see §1.3** | Enforcement is proven by live negative test, never by reading configuration back. VS0-T01R proves rejection; T14 proves it again for required checks |
| A bypass actor is added to the ruleset "just to unblock something" | **High** | `bypass_actors: []` is a normative value in §1.3, not a default. Changing it requires an ADR revision |
| The ruleset is deleted or set to `evaluate`/`disabled` | **High** | `enforcement: "active"` is normative. VS0-T01R's evidence records the ruleset id and state; T14 re-verifies it |
| A PR-head commit is pushed manually to `main` because GitHub accepts it | **Medium** | Closed by process, not configuration (§1.4). Recorded as an invalid project path even though it is not a GitHub bypass. **Restrict updates is not the answer** — it would block legitimate merges |
| **Restrict updates** is added to "close the last gap" | **High** | Explicitly forbidden in §1.4. It blocks legitimate PR merges and re-creates the deadlock that already cost this project twice |
| `require_extra_approval_for_unattributed_changes` demands an approval a solo owner cannot give | **Medium** | Recorded in §1.4 as the first suspect if a PR merge is ever blocked by an approval requirement. A blocked legitimate merge is a stop, not a workaround |

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
