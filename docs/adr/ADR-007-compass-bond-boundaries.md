# ADR-007 — Canon Boundaries for Compás, Bond and Control

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    RELATED CANON: Compás non-GPS/non-capture/non-storage · Bond voluntary and contextual ·
                   Blackwood Control separate from Bond
    OWNER DECISIONS APPLIED: Review §3 (Personality), Review §4 (FINALIZAR VÍNCULO)

## Context

The canon protects the Compás and Bond with strong prohibitions: never expose exact target distance,
never behave as GPS, never present a capture percentage, never convert Bond into capture
probability. Every prohibition is correct. **None is currently enforced by anything.**

The natural implementation of each satisfies the canon only while someone remembers to. A compass
service that queries positions and hands them to the UI is compliant until the first usability
tweak, leftover debug value, or "temporary" precision improvement. The pressure is real: Bond is the
central acquisition mechanic, and the entire genre trains players to expect a percentage.

This ADR applies one principle: **make the violation structurally impossible rather than merely
forbidden.**

## Decision

### 1. Compás — quantized readings only

The Compás service is the **only** code that sees positions. What crosses the boundary contains
**no continuous magnitudes**:

```
CompassReading {
    strength_band   : enum   # bands, never a float distance
    direction_hint  : enum   # 8 discrete sectors, or UNSTABLE
    stability       : enum
    resonance_type  : id
    anomaly         : id | null
}
```

| Rule | Detail |
|---|---|
| UI input | Presentation **never** receives positions, distances, angles or any continuous value |
| Impossibility | It cannot display what it does not have |
| Anomalies | "Meaningful anomalies" are **durable** records in `MapState` (ADR-005) |
| Not a device | No capture behaviour, no storage behaviour, no quest tracking |

**Permanent canon tests:** no float distance field in the public contract · band count small and
fixed · direction discrete · `presentation/compass/` contains no reference to world positions.

### 2. Bond — states and reasons, never a scalar

`BondEvaluation` returns the canonical state and qualitative reasons. Any internal score stays
internal and **never crosses the system boundary**.

```
BondEvaluation {
    state                : VINCULO_IMPOSIBLE | INESTABLE | RESONANCIA | POSIBLE | ESTABLECIDO
    contributing_factors : Array[id]
    refusal_reason       : id | null
}
```

| Rule | Detail |
|---|---|
| No numbers out | No continuous numeric field in the public contract. Permanent test. |
| States exhaustive | The five canon states are the complete result space |
| **Refusal is first-class** | A Tikawi **may refuse**. A distinct outcome with a communicable reason — *not* a failed roll |
| Result | A successful Bond creates **exactly one** persistent `TikawiInstance` |
| **Personality participates** | The individual's `personality_trait` (ADR-004 §9) appears in `contributing_factors` |

Removing the number is not only compliance. *"Un Tikawi no pertenece a Darwin. Decide caminar con
él."* A percentage says "try again". A reason — wrong habitat, wrong hour, the Tikawi is frightened,
this individual is wary by nature, Darwin's prior conduct — says something about the world. The
constraint forces the game to be **more** expressive, not less.

Personality slots into this contract without any new mechanism: it is already shaped as a
qualitative factor, which is exactly what `contributing_factors` carries.

### 3. Blackwood Control — explicit, separate, ordered

Control is a **distinct state**, never a Bond value.

| Rule | Detail |
|---|---|
| Representation | A `ControlState` component on the instance/actor, independent of bond |
| Ordering | A controlled Tikawi is **not eligible** for Bond evaluation until Control is removed |
| Visibility | That ineligibility is an explicit, communicated state — not a hidden branch or a silent zero |
| Removal | Its own mechanic, separate from bonding |

### 4. Ending a bond (Review §4)

FINALIZAR VÍNCULO is specified in ADR-005 §8.2 as a roster operation. Its boundary consequences here:

| Rule | Detail |
|---|---|
| Not the inverse of Bond | Bonding is an evaluation; ending is a deliberate, located act. They are separate commands. |
| Prohibition | `no_bond_exit` behaviour tag (ADR-003 §7) — never a `species_id` check |
| Knowledge survives | `CodexState` is untouched by roster operations, so Codex and research history persist after the individual leaves |
| No economics | Never sells, grants no money, never treats the Tikawi as inventory |

The knowledge guarantee is structural rather than special-cased: roster operations cannot write
Codex state under the ownership rules, so understanding cannot be lost by losing possession — which
is the canon principle itself.

### 5. Legendarios are out of this flow

Per canon, Legendarios do not use normal Bond, normal team/reserve, or normal encounter tables. They
belong to the **Fenómenos Ancestrales** architecture, with their own states (Calmado / Alterado /
Fuera de control / Restaurado) and their own module (ADR-003 §7). Nothing in §1–§4 applies to them,
and the Bond system must not be generalized to accommodate them.

### 6. Enforcement (CI gate 10)

| Check |
|---|
| No continuous numeric field in `CompassReading` or `BondEvaluation` |
| `presentation/` contains no reference to target world positions |
| The five Bond states are exhaustively handled |
| No `species_id` branching in bond, compass, control or roster code |
| Legendary IDs never appear in normal team, reserve or encounter tables |
| Personality does not reach damage or stat calculation |

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **Prose prohibition only, enforced by review** | The status quo the audit flagged. Survives exactly as long as memory does, and fails under VS11 usability pressure. |
| **Return a raw score and let UI decide what to show** | Simplest implementation; the data prohibited by canon crosses the boundary, so the violation becomes a one-line change forever after. |
| **Return a score but mark it "internal use only"** | A comment is not a boundary. Debug values leak, then become features. |
| **Compass returning a continuous angle, quantized in the UI** | Visually smoother needle; puts canon compliance in the render layer, the least reliable place for it. |
| **Bond as a visible percentage** | Genre-standard, immediately legible, and an explicit canon violation. |
| **Bond as a hidden percentage with a state shown** | Compliant on screen, but the score still crosses the boundary and reduces refusal to a failed roll rather than a reason. |
| **Control modelled as bond = 0** | Fewer concepts; conflates two mechanics canon requires to be separate, and makes the ineligibility invisible. |
| **Generalizing Bond to cover Legendarios** | Reuse; canon explicitly separates them, and generalization would drag Legendary edge cases into the common path. |
| **Personality as a numeric bond modifier** | Easy to implement; reintroduces the scalar through the back door and edges toward hidden stat rolls. |

## Consequences

- Identical implementation effort; materially lower risk of losing a protected rule.
- Bond communication must be authored as **reasons** — content work the owner must supply, which
  produces a better system than a number would.
- Tuning Compás feel means tuning band and sector counts, not exposing precision.
- Personality becomes visible to the player through bond reasoning rather than through statistics.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Players find bond opaque without a number | **Medium–High** | The factor and refusal vocabulary must be rich and legible. This is the real design risk and it is content work, not architecture. |
| Band/sector granularity feels wrong and is tuned by adding precision | Medium | Granularity is an enum size; increasing it stays discrete. The CI test blocks reintroducing continuous values. |
| Factor vocabulary grows unbounded and becomes noise | Medium | Closed, validated registry; surfaced factors capped in presentation |
| `contributing_factors` becomes a de facto score if UI counts them | Low–Medium | Presentation shows reasons, not tallies; reviewed at VS4 |
| Control and Bond interaction confuses players | Medium | Ineligibility is an explicit communicated state, never a silent failure |
| A debug build exposes the internal score and it ships | Medium | The score never leaves the system; debug tooling reads it inside the module only |

## Migration / compatibility impact

**Persisted by this area:** the individual's bond level and `ControlState` on `TikawiInstance`, and
Compás anomalies in `MapState`.

- The **internal bond score is persisted** as part of the instance, but is **not** part of any public
  contract. Its representation can change with a normal versioned migration without affecting UI.
- `CompassReading` and `BondEvaluation` are **transient** — never persisted. Band counts, sector
  counts, factor vocabulary and refusal reasons can all be revised with **zero save impact**. This
  is deliberate: the tuning surface is the one with no migration cost.
- **Anomaly records in `MapState` are persisted** and referenced by ID; anomaly IDs follow the
  ADR-004 §2 rules, so adding anomaly types is additive and removing one requires a migration.
- `no_bond_exit` as an **individual** behaviour tag is persisted (ADR-003 migration notes); as a
  **species** tag it is generated data and is not.
- Ending a bond removes an instance and touches nothing else, so it needs no migration; the retired
  `instance_id` is never reused.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-018** — Compás contract could leak exact position | §1 |
| **AUD-019** — bond scalar could cross the boundary to UI | §2 |

## Open items — owner decision required

1. The vocabulary of Bond **contributing factors** and **refusal reasons** — design content, and the
   main determinant of whether a number-free bond reads clearly.
2. The number of Compás **strength bands**, and whether direction uses 8 sectors or fewer — a feel
   decision best made with the mechanic in hand.
3. How **personality** should express itself in bond reasoning: a general tendency, or specific
   traits with specific refusals.
