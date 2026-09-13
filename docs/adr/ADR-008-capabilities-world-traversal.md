# ADR-008 — Capability-Grade Traversal, World Regions and Environment

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    OWNER DECISIONS APPLIED: 11 (World loading), 15 (Time), 17 (Capabilities), 21 (Punta Pitt),
                             Final 16 (Vertical Slice scope boundary)

## Context

Three interlocking questions were open: how the world loads, how environment reaches its many
consumers, and how traversal is gated. They are decided together because they share one data model —
the world graph.

## Decision

### 1. Region loading (owner decision 11)

**Discrete handcrafted region scenes, connected by short, visually coherent transitions.** The
player perceives a connected island; the engine loads modular regions.

| Rule | Detail |
|---|---|
| Authoring | Hand-authored. **No procedural terrain.** Systems vary what happens inside authored maps. |
| Streaming | **No AAA streaming** |
| Transitions | Short, with visual and musical continuity across the seam |
| Entry points | Stable `entry_point_id`, paired across region boundaries |
| Tilemap | `TileMapLayer` (ADR-001) |
| Coordinates | Local per region; global absolute coordinates are never the sole recovery source |

Position persistence: `region_id` + `entry_point_id` authoritative, `local_offset` a refinement that
falls back to the entry point when a region is re-authored (ADR-005 §7).

### 2. World graph and persistent world changes

The world is **data before it is scenes**: nodes are regions and entry points; edges are transitions
carrying requirements (capability + grade, item, tide, time, story progress).

One model serves region loading, fast travel, maritime landing points and — critically — the
reachability validator (§7). Without it, anti-soft-lock analysis is not possible.

**World changes** are namespaced typed records (`region_id` + `change_id` + type), never loose
booleans. The catalogue is declared in data and validated: no unknown IDs, no duplicates.
**Rule:** persist only what alters what the player can see or do again; anything re-derivable from
rules is recomputed, not stored.

### 3. Punta Pitt and maritime landing points (owner decision 21)

| Concept | Meaning |
|---|---|
| `region` | A terrestrial area of San Cristóbal |
| `landing_point` | A maritime arrival point, owned by a region |

**Punta Pitt is a terrestrial region of San Cristóbal that owns a landing point. It is not an
offshore island.** León Dormido and Isla Lobos are maritime destinations; Isla Perdida is a
fictional maritime destination.

### 4. Environment: one context, many consumers (owner decision 15)

`TimeManager` owns game time and publishes an **immutable `EnvironmentContext` snapshot**:

```
EnvironmentContext { time_of_day, minute_of_day, weather, tide, region_modifiers }
```

| Rule | Detail |
|---|---|
| **Single source** | Nobody recomputes environment conditions. No `if hour >= 18` scattered across systems. |
| Storage | Deterministic game-time representation: an **integer minute counter**, persisted |
| **Advances** | Overworld exploration and navigation |
| **Pauses** | Battle · dialogue · normal menus |
| Deliberate advance | Rest advances time intentionally |
| Real-world day length | **Not locked**; tuned through playtesting |
| Tide | **Derived** from time by a pure, testable function — never independent state. Also makes tide predictable for the player, which exploration design needs. |
| Weather | Transitions from the seeded `weather` stream with per-region bias, so it is reproducible in tests |

**Consumers:** encounters (§6), evolution, field access, battle terrain (ADR-006 §6), NPC routines,
lighting, audio, maritime navigation. The highest-fan-out system in the game; one contract is what
keeps them coherent.

**NPC routines** (promoted canon) consume `EnvironmentContext` and are expressed as data schedules,
never per-NPC scripts.

### 5. Capability-grade traversal (owner decision 17)

**A unified capability model. Tools and Tikawi both provide capabilities, at different grades and
contexts.**

```
Obstacle requires: capability + minimum grade (+ optional context)
Provider:          a held tool, OR a Tikawi in the team
```

| Capability | Basic grade (tool) | Advanced grade (Tikawi) |
|---|---|---|
| `light` | Farol — basic light | Mobile / environmental light interaction |
| `climb` | Cuerda — basic access | Stronger / contextual traversal |
| `strength`, `clear_cut`, `glide`, `swim`, `dive`, `deep_dive`, `tracking` | per content | per content |

**Rules:**

- Obstacles ask for **capability and grade**, never species identity. Enforced by the `species_id`
  grep (ADR-003 §7).
- One query point resolves all providers, so every gate in the game is auditable together.
- Field abilities remain **separate from the six combat moves** (canon).
- A field action is complete only when the Tikawi **visibly performs it** — reusing the
  `MovePerformance` component system (ADR-006 §5).
- Natural gating philosophy (promoted canon): obstacles are **visible and legible**; the player may
  see a place before knowing how to reach it. No invisible walls.

This preserves both halves of the canon: Farol and Cuerda keep real roles, and *"Los Tikawi no son
llaves"* holds — the Tikawi is not the only way through, it is the better way.

### 6. Encounters

A single `EncounterService` receives `(region, EnvironmentContext, depth, player_context)` and
resolves a candidate using the seeded `encounter` stream.

**Two distinct mechanisms:**

| Mechanism | For |
|---|---|
| Weighted table | Common fauna |
| **Condition-gated appearance** | Specials, Legendarios, rare events |

The second is a canon requirement, not a convenience: *Specials rely on conditions and mysteries,
not merely tiny random spawn rates.* A weight-only system **cannot express that** and would have to
be rebuilt.

**Coverage validator:** every Volume I species with a declared encounter must be reachable under
some condition combination the game can actually produce. Catches orphaned content long before VS10.
A distribution report per region and condition supports owner balancing.

### 7. Reachability / anti-soft-lock validator (CI gate 11)

Canon: *no starter may soft-lock the player.* The three starters grant **disjoint** capabilities —
Mariguín: swim → dive · Lavalín: glide · Scalito: strength / clear_cut. None grants light, climb,
tracking or deep_dive.

This is a **global** property of the world. Nobody can verify it by reading a map; it emerges from
obstacles × capabilities × Tikawi availability × time × tide × items. And it fails in the worst
possible way: for one starter choice only, in a mid-game region, discovered by a player.

**The validator** walks the world graph (§2) breadth-first from the start, once **per starter**,
accumulating capabilities obtainable along the way, and fails the build if any mandatory main-path
region is unreachable. Degenerate cases included: single-Tikawi team, all Agotados, adverse tide,
night.

The same pass checks reserve access only in safe physical contexts, fast travel only between
discovered safe points, and the availability of an approved safe context for FINALIZAR VÍNCULO
(ADR-005 §8.2).

### 8. Locomotion abstraction (maritime deferral)

VS1 defines `LocomotionMode` and `TraversalContext` and implements **`walk` only**.

The maritime slice is correctly deferred — but canon is explicit that *the ocean is traversed, not
selected from a menu* and *diving extends exploration rather than launching a separate minigame*.
That is the **same** exploration space with different locomotion, plus a depth axis
(SHALLOW / MID / DEEP / ABYSSAL) in a top-down 2D game.

From VS1: reserve a **layer/depth field** on player position (only value: `surface`), and express
obstacles by required capability rather than "land or water". Cost now: near zero. Cost of
retrofitting a depth axis onto a walk-only body later: the movement system and everything depending
on it.

**Nothing maritime is implemented in VS1. The door is simply not closed.**

### 9. Vertical Slice scope boundary (Final §16)

**VS0–VS12 is the Vertical Slice roadmap, not full Volume I production.** Three areas this ADR
touches are explicitly **out of Vertical Slice scope** and move to the **VOLUME I PRODUCTION
ROADMAP**, authored separately after VS12:

| Deferred to post-VS12 | Status in the Vertical Slice |
|---|---|
| **Maritime navigation and the full depth axis** | Not implemented. Only the §8 abstraction is reserved. |
| **Fenómenos Ancestrales** (full system) | Module boundary exists (ADR-003 §7); no content. |
| **Masters and Sellos** (full progression) | Not implemented. |

The distinction that matters here: **§8 stays, the maritime slice does not.** The locomotion and
depth abstraction is cheap insurance that costs one reserved field and one enum today and prevents a
movement-system rewrite later. Deferring the *content* while keeping the *abstraction* is the whole
point — it is not scope creep, it is the opposite: it is what allows the maritime work to be
deferred safely.

Everything else in this ADR — the world graph, capability grades, environment context, encounters and
the reachability validator — **is** Vertical Slice work, because the Vertical Slice contains regions,
gates, time and encounters from VS1 onward.

> This section exists specifically to prevent Vertical Slice scope creep. If a task proposes building
> maritime traversal, Ancestral content or Masters/Sellos progression before VS12, it is out of scope
> by this ADR, regardless of how naturally it follows from the abstraction in §8.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **Seamless contiguous world with sector streaming** | Strongest "real island" feel; a fundamentally different and far more expensive architecture, explicitly excluded ("no AAA streaming") and unnecessary given the GBA structural reference. |
| **Menu-based region selection** | Cheapest; contradicts open-world canon and the natural-gating philosophy. |
| **Global absolute coordinates as the saved position** | Simplest; every map re-authoring becomes a save hazard, and re-authoring will happen constantly. |
| **Each system computing time-of-day from a shared clock** | No contract to maintain; produces the exact incoherence this prevents — spawns believing it is night while lighting believes it is dusk. |
| **Tide as independent state** | More authoring control; desynchronizes from time and becomes unpredictable for the player, which harms exploration design. |
| **Real-time clock tied to wall time** | Atmospheric; unplayable for condition-gated content and untestable. |
| **Separate tool-gating and Tikawi-gating systems** | Matches how canon introduces them; produces two incompatible gate models, and makes global reachability analysis impossible. |
| **Species-keyed obstacles** (`if species == scalito`) | Trivial to write; explicitly forbidden by canon and unmaintainable at 150 species. |
| **Manual play-testing for soft-lock coverage** | Standard practice; cannot cover three starters × conditions × degenerate states, and fails late and silently. |
| **Weight-only encounter tables** | Simpler; cannot express Specials' condition-based appearance, so it would need rebuilding. |
| **Defer locomotion abstraction entirely to the marine slice** | Less VS1 work; forces a movement-system rewrite when depth arrives. |
| **Build maritime traversal inside the Vertical Slice, since §8 makes it cheap** | The abstraction is cheap; the *content* — water regions, depth layers, marine encounters, navigation — is not. Out of scope per Final §16 and moved to the Volume I Production Roadmap. |

## Consequences

- The world graph becomes a first-class authored artifact, not a by-product of scene layout.
- Region transitions are a presentation problem, which is where the perceived continuity is won.
- Environment coherence is guaranteed by construction rather than by discipline.
- Every gate in the game is auditable in one pass, which is what makes the canon anti-soft-lock
  guarantee real.
- Capability grades let tools and companions coexist without either becoming redundant.
- Maritime, Ancestral and Masters/Sellos content is bounded out of the Vertical Slice by §9, while the
  architecture that would make them expensive to add later is kept.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| World graph drifts out of sync with the actual scenes | **High** | Validator cross-checks graph entry points against scene entry nodes; mismatch fails the build |
| Transitions feel choppy and break the "connected island" illusion | Medium | Presentation-side continuity (visual + musical) budgeted in VS1, reviewed by the owner, not assumed |
| Reachability validator becomes slow or produces false failures | Medium | Graph is small (tens of nodes); failures print the blocking edge and the starter path |
| Two grades prove insufficient and grades proliferate | Medium | Grade set is a closed enum; expanding it is a reviewed registry change (open item 2) |
| Tide derivation makes some content unreachable at certain times | Medium | Covered by the §7 degenerate-case sweep, including adverse tide |
| Reserved depth field never gets used and adds dead weight | Low | One field; the asymmetry of costs strongly favours reserving it |
| Encounter conditions become so specific that content is effectively unreachable | Medium | §6 coverage validator plus the distribution report |
| The §8 abstraction is read as permission to start the maritime slice | Medium | §9 states the boundary explicitly; the abstraction is reserved, the content is post-VS12 |
| The §6 coverage validator fails during the Vertical Slice because post-VS12 species have no reachable encounter | Medium | The validator's scope is the **declared content of the current milestone**, not all 150 entries; species outside Vertical Slice scope are excluded by declaration, not by exception |

## Migration / compatibility impact

**Persisted by this ADR:** player position (`region_id`, `entry_point_id`, `local_offset`, depth
layer), world change records, `EnvironmentState` (minute counter, weather, tide), and discovered map
points.

- **Region and entry-point IDs are save vocabulary.** Re-authoring a map is migration-free; renaming
  a region or entry point is a migration (ADR-004 §2). This is precisely why position is stored by
  ID rather than by coordinates.
- **The depth layer field is introduced at VS1** with a single value. Adding the remaining depth
  values later is a value change, not a schema change — the reason for reserving it now. Introducing
  the field after saves existed would have been a `save_version` bump.
- **World change records are persisted by ID.** Adding a change type is additive; removing one
  requires a migration for saves that recorded it. Hence the validated catalogue.
- **`EnvironmentState` enters the schema at VS0** (ADR-003 §5). Changing the real-world duration of
  a game day is a **config change with no save impact**, because time is stored as an absolute
  minute counter, not as a fraction of a day. This is why the duration can stay unlocked and be
  tuned through playtesting.
- **Capability and grade definitions are generated data, not persisted.** Rebalancing which tool
  provides which grade has zero save impact.
- **The world graph itself is not persisted**, so its topology can be revised freely; only the IDs
  it contains are load-bearing.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-022** — capability and tool gating overlapped with no model | §5 |
| **AUD-023** — no reachability validator despite anti-soft-lock canon | §7 |
| **AUD-024** — world loading model undecided | §1 |
| **AUD-025** — Time/Weather/Tide had no contract | §4 |
| **AUD-026** — encounter selection had no service or determinism | §6 |
| **AUD-032** — no locomotion abstraction; marine deferral risked a rewrite | §8 |
| **AUD-046** — world change persistence model undefined | §2 |
| **AUD-055** — Punta Pitt listed as both region and maritime destination | §3 |

## Open items — owner decision required

None blocking VS0. Three design questions are needed before the milestones that consume them:

1. **Transition presentation style** — cut, short fade, or a seam effect. Determines perceived
   continuity, which is the whole point of the discrete-regions decision. *Needed by VS1.*
2. **Capability grade count** — are two grades (basic tool / advanced Tikawi) sufficient, or three?
   *Needed by VS7.*
3. **Reserve access rules and fast-travel point definition**, needed before the §7 validator is
   complete. *Needed by VS7.*
