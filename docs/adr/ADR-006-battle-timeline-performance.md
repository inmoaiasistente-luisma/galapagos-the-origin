# ADR-006 — Battle Result Timeline and Composable Move Performance

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    OWNER DECISIONS APPLIED: 12 (RECUPERAR), 13 (Reaction), 16 (Combat presentation — APPROVED),
                             14 + Review §2 (type matrix restored),
                             Final 13 (Reaction windows), Final 14 (Performance archetypes),
                             Final 15 (Accessibility FULL/FAST/MINIMAL), Final 2-5 (type matrix completed)

## Context

The canon makes visible performance a protected rule: *"combat moves are performances, not
numerical notifications"*, with explicit beats — windup, body action, travel/contact, impact, target
reaction, sound, recovery. `03_CODEX_MASTER_IMPLEMENTATION.md` separately forbids putting damage
truth inside animation callbacks.

Together these are **incompatible with a flat result struct**. Given only `{damage: 12}`,
presentation cannot know when impact occurs, how many hits there were, or when a status landed —
leaving two options, both canon violations: invent timing in the animation layer and fire damage
from a callback, or reduce the performance to a flash and a number.

The protected rule was undefendable by architecture. This ADR makes it structural.

## Decision

### 1. `BattleActionResult` is an ordered timeline, not a result

```
BattleActionResult {
    action_id
    actor_slot
    target_slots   : Array
    rng_seed_used
    steps          : Array[BattleStep]   # ordered, immutable, deterministic, replayable
}

BattleStep { kind, subject_slot, payload, presentation_hint }
```

**Step kinds:** `windup` · `travel` · `contact` · `damage_applied` · `status_applied` ·
`energy_spent` · `energy_restored` · `stat_changed` · `reaction` · `terrain_changed` · `faint` ·
`recovery` · `message`

**Logic decides what happens and in what order. Presentation decides how long it takes and how it
looks.** Neither crosses into the other.

What this buys: the animation rule becomes **verifiable** (a move whose steps lack a required beat
fails CI) · headless tests assert **step sequences** rather than isolated numbers · with
`rng_seed_used`, any battle is reproducible from its log · multi-hit, multi-target, reactions and
terrain changes fit without contract changes · battle speed becomes a presentation parameter with
the beats still occurring (§7).

### 2. Slots from the start (2v2 readiness)

Positions are **slots** from VS3, with `target_slots` as an array, though VS3 implements 1v1 only.
Moves declare a targeting pattern in data (single, all-enemies, ally, self, field). Isla Lobos
introduces 2v2 by canon; retrofitting singular actor/target signatures later would change every
contract and every test.

### 3. RECUPERAR (owner decision 12)

| Property | Value |
|---|---|
| Location | **Outside** the six active moves |
| Cost | Consumes the Tikawi's action for the turn |
| Effect | Restores Energy per balance data |
| Presentation | **Visibly animates** — the canon rule applies to it too |
| Availability | Always |
| Values | **Balance data, not locked** |

**Invariant test, permanent:** *in any reachable battle state, the player has at least one legal
action.* This is the anti-soft-lock guarantee the canon's stop conditions require, expressed as a
test rather than a hope.

RECUPERAR is also cheap to animate — a Tikawi catching its breath — and reusable across every
species via the body-animation component (§5).

### 4. Reaction category (owner decision 13)

A **conditional action armed during the turn and triggered by declared reaction windows**.

**Reaction windows — the approved initial set (Final §13):**

| Window | Fires |
|---|---|
| `BEFORE_IMPACT` | after the incoming action's `contact` step is determined, before `damage_applied` |
| `AFTER_IMPACT` | immediately after `damage_applied` resolves |
| `ON_STATUS` | when a status is applied to the reacting Tikawi |

**Contextual windows for 2v2 (ally-targeted, ally-fainted, intercept) are recognised as future
work.** The slot model in §2 already carries the information they need, so adding one later is a new
window constant plus content — not a resolver rewrite.

> `ON_FAINT` was a *candidate* in this ADR's first draft, proposed by me. It is **not** in the
> approved initial set. Recorded explicitly so nobody reintroduces it later believing it was
> approved.

| Rule | Detail |
|---|---|
| Windows | **Closed enum**, exactly the three above. Adding one is a reviewed change, not a data edit. |
| Arming | A reaction is armed as the Tikawi's action; it resolves later, in a window |
| Chain depth | **Maximum 1** |
| Recursion | A reaction may not recursively trigger another; bounded by construction and asserted by test |
| Representation | A `reaction` step **inserted into the triggering action's timeline** |
| Content/balance | Future design |
| **VS0 impact** | **None.** Confirmed by Final §13 — this does not block VS0. |

The resolver is built with these interruption points from VS3 even though VS3 ships no reaction
content. Leaving the hooks is nearly free; retrofitting them means rewriting the resolver, the turn
order, the result model and every battle test.

### 5. Composable `MovePerformance` (owner decision 16)

| Component | Supplied by | Reuse |
|---|---|---|
| Body animation | **the species** (by size class / morphology) | across all its moves |
| Travel / action | the move | across all species |
| Type VFX | the move's element | across all moves of that type |
| Impact | the move | shared library |
| Reaction | the **target's** size class | across all incoming hits |
| Audio | audio IDs | shared |
| Camera / presentation metadata | the move | shared |

**The Tikawi supplies the body; the move supplies the effect.** A new move is a new combination of
existing parts; a new species inherits the whole effect library.

**5.1 The approved archetype library (Final §14)**

Thirteen archetypes are approved as the **initial** set. They are *not a closed forever-list*: adding
one is a normal content decision, and no architectural change is required to do so.

| Component role (§5 table) | Archetypes |
|---|---|
| **Approach / locomotion** — how the actor closes distance | `Dash` · `Leap` · `Dive` · `Charge` |
| **Body action** — what the body does at the point of action | `Spin` · `Wing` · `Tail` · `Bite` |
| **Ranged delivery** — travel of a projected effect | `Projectile` · `Beam` · `Arc` |
| **Area** — effect with no single travel path | `GroundBurst` · `AreaPulse` |

Mapping onto the component model: *approach* and *ranged delivery* archetypes populate the
**travel / action** component; *body action* archetypes populate the **body animation** component the
species supplies; *area* archetypes replace travel entirely and drive the **impact** component
directly. Every archetype still produces the mandatory beats — the archetype decides the shape of
`windup → travel → contact`, never whether those steps exist.

> **`Charge` is CONFIRMED as approach / travel / physical closing movement.** It is locomotion: the
> actor physically closes distance and the timeline carries a `travel` step.
>
> **A move that stays in place while gathering power is NOT a `Charge`.** It uses an **extended or
> parameterized `windup`** on whatever body-action archetype it already has. No archetype is added
> for it, and none is needed — "gathering power" is a duration and intensity parameter on an
> existing beat, not a new kind of movement.
>
> The validator follows from this: a recipe using `Charge` **must** produce a `travel` step. A
> stationary power-up that emits `travel` is a data error.

Archetype IDs are `PascalCase` and validated against a closed registry (`CONVENTIONS.md`).

**5.2 Library sizing**

Initial library: the 13 archetypes above, one impact family per each of the 13 types, and a few
reaction animations per size class — already covering hundreds of distinguishable moves.

**Custom performances are permitted** for signature starter moves, Specials and Legendarios, per
owner decision 16. The exception is affordable precisely because the general case is not.

**The arithmetic:** ~150 entries with a shared move library implies roughly 200–300 distinct moves,
each requiring seven beats, across wildly different morphologies. Authoring that by hand is not
expensive — it is infeasible, and the failure would surface at VS10 when the only cheap remedy would
be weakening a protected canon rule. **This system exists to make the canon affordable, not to
reinterpret it. The visible-animation requirement is unchanged.**

### 6. Supporting contracts

| Item | Decision |
|---|---|
| **Terrain** | Initial battle terrain is **derived** from `EnvironmentContext` + region + depth by a pure, testable function. Battle owns it thereafter; changes appear as `terrain_changed` steps. Volcápago's terrain-control identity requires in-battle mutation. |
| **Status effects** | Declarative data: duration, stacking, mutual exclusion, resolution timing, and **whether it persists outside battle**. Only persisting statuses enter the save (ADR-005). |
| **Turn order** | Velocidad, ties resolved via the seeded `battle` RNG stream. Never arbitrary. |
| **Energy** | Mechanism is canon; **values are unlocked balance data** |
| **Type matrix** | **Complete** (ADR-004 §6): 26 strong cells, 24 derived resistances, 119 neutral, **0 immunities**; tiered net-step stacking, dual-type sum-and-clamp. Ancestral now has a weakness (`Lucha > Ancestral`, Final §4) and resistances are derived by rule rather than assigned by hand. **No matchup item remains open**; the VS3 baseline is locked per Final §5. |
| **Personality** | May inform presentation and flavour. **Must never enter damage or stat calculation** (ADR-004 §9). |

### 7. Speed and accessibility

Because beats are data and duration is presentation, the accessibility policy is expressed as
**three named presentation modes (Final §15)** rather than as a speed slider:

| Mode | Behaviour |
|---|---|
| **FULL** | Complete performance. The authored default. |
| **FAST** | Compressed durations; every beat still plays. |
| **MINIMAL** | Shortest legible form — but **still renders action → impact → reaction**. |

> **All three modes retain action → impact → reaction. There is no mode in which a move resolves as
> a number.**

**Screen shake and flash intensity are independently reducible** in every mode, including FULL. They
are separate settings, not tiers of the same one — a player who wants the full performance without
camera shake must not have to give up the performance to get it.

**Validator (CI, §8):** for every move, the **MINIMAL** rendering path must still emit the mandatory
beats. A move whose MINIMAL path drops action, impact or the target reaction fails the build. This is
what stops MINIMAL from decaying into the "disable animations" toggle canon forbids — the prohibition
is checked, not remembered.

Per-beat **minimum duration floors** apply in FAST and MINIMAL so compression cannot reduce a beat to
zero frames.

### 8. Validation

| Gate | Check |
|---|---|
| Performance completeness | No move may exist in data without a complete recipe; missing mandatory beats fail the build |
| Determinism | Same seed + same inputs → identical step sequence |
| Anti-soft-lock | At least one legal action in any reachable state |
| Truth location | No damage, status or state mutation originates in `presentation/` (layer lint, ADR-003) |
| Reaction bound | Chain depth never exceeds 1 |
| Personality boundary | Damage and stat calculation do not depend on personality |
| **MINIMAL completeness** | Every move rendered in MINIMAL still emits action, impact and target reaction (§7) |
| **Archetype registry** | Every move's performance recipe references an archetype in the closed registry (§5.1) |
| **Charge semantics** | A recipe using `Charge` emits a `travel` step; a stationary power-up uses an extended `windup` instead (§5.1) |

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **Flat `BattleActionResult` struct** (damage, crit, effectiveness) | The default, and the reason this ADR exists. Presentation cannot stage a performance from it, forcing one of two explicit canon violations. |
| **Presentation drives, logic responds** (damage applied from animation callbacks) | Common in small projects and explicitly forbidden by `03`. Makes battle logic untestable headless and puts game truth in the render layer. |
| **Streaming/event-callback battle loop** instead of a materialized timeline | Allows presentation to react live; loses replayability, makes assertions order-dependent and reintroduces reentrancy. A materialized immutable list is simpler and stronger. |
| **Bespoke animation per move** | Maximum visual specificity. Infeasible at 200–300 moves, and the failure lands at VS10 where the only cheap fix weakens canon. |
| **One generic hit animation reused everywhere** | Trivially cheap; is precisely the "sprite-only nudge" canon rejects. |
| **Singular actor/target now, generalize at Isla Lobos** | Slightly simpler VS3; changes every battle contract and test later. |
| **Reactions deferred entirely, no hooks** | Smallest VS3. Retrofitting out-of-turn resolution means rewriting the resolver. |
| **Unbounded reaction chains** | More expressive; introduces recursion and non-terminating turns. Depth 1 is bounded by construction. |
| **A "disable animations" accessibility toggle** | What players will ask for; directly violates a protected canon rule. MINIMAL mode delivers the same relief while keeping action → impact → reaction. |
| **A continuous speed slider instead of three named modes** | Finer control; makes "what does the fastest acceptable setting look like" untestable, because there is no discrete worst case to assert against. Three named modes give CI a MINIMAL case. |
| **Coupling shake/flash reduction to MINIMAL mode** | Fewer settings. Rejected per Final §15: photosensitivity and motion sensitivity are not the same need as wanting shorter battles. |
| **An open-ended archetype vocabulary with no registry** | Maximum authoring freedom; the performance-completeness gate cannot validate against a vocabulary that has no definition. |

## Consequences

- The battle timeline becomes the contract everything else in combat depends on.
- Battle logs are replayable, making combat bugs reproducible instead of anecdotal.
- The performance component library becomes a real art deliverable, sized before VS3 rather than
  discovered at VS10.
- Battle is implementable before content balance is finished; the **type matrix itself is now
  complete and locked** (ADR-004 §6), so VS3 tunes values, not matchups.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| The step-kind list proves incomplete mid-VS3 | Medium | Kinds are data-driven and additive; adding one does not change the contract shape |
| Timelines become verbose and slow to assert in tests | Low | Tests assert subsequences and invariants, not whole logs |
| Composable performances all look alike | **High** | The library must be sized deliberately (open item 2); this is the quality risk, not a technical one |
| Custom performances proliferate until the general system is bypassed | Medium | Restricted by canon to signature/Special/Legendary moves; reviewed per addition |
| Presentation begins inferring outcomes from `presentation_hint` | Medium | Hints are advisory only; layer lint plus the truth-location gate |
| Reaction windows interact badly with multi-hit timelines | Medium | Depth bound 1 plus explicit window declaration; exercised by test before content exists |
| Speed scaling at maximum makes performances unreadable | Low | Minimum per-beat duration floor set during VS11 polish |

## Migration / compatibility impact

**Save compatibility:** battle timelines are **transient and never persisted**. A battle in progress
is not saved (saving occurs in safe physical contexts, per canon), so the step-kind list, the
reaction model and the performance library can all evolve with **zero save impact**.

Two exceptions to watch:
- **Persisting statuses** (§6) do enter the save. Adding, removing or changing the persistence flag
  of a status is a schema change requiring a migration under ADR-005 §5.
- **Energy** is part of a Tikawi's durable condition if it persists outside battle — a design point
  to settle in VS3. Whichever way it goes, it is a DTO admission decision, not an afterthought.

`MovePerformance` recipes and the archetype registry are generated content data, **not persisted**;
the library can be extended or rebuilt freely, which is what makes "not a closed forever-list"
(Final §14) safe. Adding a fourteenth archetype is a registry entry plus art, with no save impact.

Type matrix values are likewise data-only and unpersisted.

**Presentation mode (FULL / FAST / MINIMAL) is a setting, not save data** (ADR-005 §2), so changing
or extending the mode list never touches a player's progress.

Reaction windows are a **closed enum in code**, not data, and armed reactions are transient — battles
are not saved, so a 2v2 contextual window added later requires no migration.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-012** — result contract could not sustain the animation rule | §1 |
| **AUD-013** — "Reacción" implied out-of-turn resolution with no model | §4 |
| **AUD-014** — Energy had no floor rule; soft-lock risk | §3 |
| **AUD-015** — no composable performance system; the rule did not scale | §5 |
| **AUD-041** — terrain had no world→battle contract | §6 |
| **AUD-042** — status effect model absent | §6 |
| **AUD-043** — 1v1 contract could not support 2v2 | §2 |
| **AUD-050** — animation vs accessibility tension | §7 |

## Open items

**None.** Closed by the Final decisions and owner confirmations: the reaction window list (§4,
Final §13), the performance archetype library (§5.1, Final §14), the accessibility policy (§7,
Final §15) and the `Charge` classification (§5.1, owner confirmation).

**Not an open item, but the standing quality risk:** §5's composed performances must be sized so they
read as varied rather than repetitive. That is art-budget work reviewed at VS3, not an architectural
decision.
