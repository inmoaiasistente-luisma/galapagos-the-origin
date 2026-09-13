# CANON CONFLICT RESOLUTION

    STATUS: ACCEPTED
    AUTHORITY LEVEL: 2 (canon clarification, owner-decided)
    DECIDED BY: Luisma / Creative Owner
    DATE: 2026-09-12
    ORIGIN: C-001 Architecture Audit, finding AUD-004 + Annex I
    REVISION: v1.1 — R-1 completed per Final owner decisions 2–5; aligned to Master Canon v1.1
    SCOPE: Resolution of GALAPAGOS_THE_ORIGIN_GDD_v1.0.md

---

## 1. Resolution

**The Master Canon wins completely.** No canon was changed. No conflicting statement from the
old GDD survives as authority.

**Action taken (executed 2026-09-12):**

| Before | After |
|---|---|
| `GALAPAGOS_THE_ORIGIN_GDD_v1.0.md` (project root, unmarked) | `docs/archive/GDD_v1.0_SUPERSEDED.md` |
| Self-described as *"Biblia canónica de preproducción"* | Prefixed with `STATUS: SUPERSEDED — NOT IMPLEMENTATION AUTHORITY` |

## 2. General rule adopted

> **No document without a `STATUS` and `AUTHORITY LEVEL` header in its first lines is authority.**

Every document in this repository carries that header. Agents and contributors must read it
before treating any document as input. A document whose header says `SUPERSEDED` is historical
reference only.

## 3. Conflicts resolved (all in favour of Master Canon)

| # | Point | Old GDD | Master Canon — **binding** | Protected |
|---|---|---|---|---|
| 1 | Darwin's age | ~26 | **20** | Yes |
| 2 | Legendary count | 5 "Guardianes" | **3** (#148/#149/#150) | Yes |
| 3 | Legendary identity | incl. Abyssiguana, Scalysia | **Neither is a Volume I Legendario** | Yes |
| 4 | Creature terminology | "criaturas / compañeros" | **Tikawi** (*un Tikawi* / *los Tikawi*) | Yes |
| 5 | Plant-creature rule | "Scalito es una criatura vegetal bípeda antropomórfica" | **Scalito is not a humanoid plant**; tortoise + Scalesia | Yes |
| 6 | Compás | specialised variants sold in shops | **Single object**; not capture, not storage, not precise range | Yes |
| 7 | Codex structure | 30×3 + 20×2 + 15×1 + 5 leg. | **49 families × 3 + 3 Legendarios = 150** | Yes |
| 8 | Engine / platform / save | listed as "pending" | **Godot / GDScript / Windows / versioned saves** | Yes |
| 9 | Bond | "probabilidades de vínculo" | **Contextual trust, never capture probability** | Yes |
| 10 | Final trial | "SAN CRISTÓBAL TRIAL" | **Prueba de San Cristóbal**; *not a Liga* | Partial |
| 11 | Master name | "Maestro de las Tierras Altas" | **Maestro de Alturas** | Partial |
| 12 | Region name | "Campamento Blackwood" | **Blackwood Camp** | Partial |

## 4. Design promoted from the old GDD into canon

The following were **not** in the Master Canon and are hereby preserved as canonical design
direction. They are binding for architecture and must have a home in the system design.

| Promoted | Architectural consequence |
|---|---|
| **NPC routines by time/context** | Consumers of `EnvironmentContext`; NPC scheduling is data, not scripts. See `ADR-008`. |
| **Rumors may be true, incomplete, exaggerated or false** | Rumor data carries `claim` separate from `truth`. The runtime must never conflate them. See `ADR-002` §Dialogue. |
| **Emergent world events** | Event-driven, condition-gated, non-quest content. Shares the closed condition vocabulary. |
| **Map progressively completed through exploration** | `MapState` is durable, incremental, and owned by `MapSystem`. See `STATE_OWNERSHIP.md`. |
| **Three-volume saga: San Cristóbal → Santa Cruz → Isabela** | ID space, save schema and Codex must tolerate future volumes without migration. Codex entries beyond 150 must load, not crash. |
| **Post-campaign / revisitable world** | No terminal game state. `StoryState` must model "campaign resolved" without locking the world. |
| **Natural gating: the player may see a place before knowing how to reach it** | Obstacles are visible and legible; gating is by capability grade, never by invisible walls. See `ADR-008`. |

## 5. Design explicitly NOT promoted

The following remain **unlocked**. They may be adopted later by owner decision, but no
architecture may assume them, and no implementation may introduce them.

| Not promoted | Architectural consequence |
|---|---|
| Tomás automatically choosing the type-advantage starter | Rival team composition is content, not a locked rule. |
| Fixed starter evolution levels (18/36, 16/34, 17/35) | Evolution conditions are data; no level thresholds are canon. |
| Mandatory move-evolution chains | Move progression is optional content, not a required system. **No move-upgrade system is in the Volume I baseline.** |
| Fully divergent same-species builds implying IV/EV architecture | **No per-individual stat variance and no training-point accumulation in the Volume I baseline.** `TikawiInstance` stores level, learned moves, active set, bond, held item and durable status — not hidden stat rolls. Build divergence comes from move selection, held items and level. Adding IV/EV later would be a normal versioned save migration. |

## 6. Items raised by this resolution

**6.1 — Type strength/weakness baseline — RESOLVED (Review §2).**
The C-001 audit reported that the compact Master Canon contained no matchup data, and that the only
matchup statement anywhere was the starter triangle in the now-archived GDD. No chart was invented.

The owner has confirmed this was an **accidental omission** in the compact Master Canon, and has
**restored the previously approved baseline**. It is recorded in full in `ADR-004` §6 and belongs in
the Canon Registry at `data/source/canon/type_matrix.json`.

Summary of the completed baseline: **all 13 types** carry declared strengths and weaknesses,
including Lucha (`Lucha > Ancestral`, Final §4). Multiplier scale: double strong ×2.0 · strong ×1.5 ·
normal ×1.0 · resistance ×0.67 · double resistance ×0.4. **No immunities.** Stacking is a net-step
lookup, and a dual-type defender sums the two steps and clamps.

**This is no longer an open canon issue, and it is no longer an open balance issue either.** The
derivation questions are answered by Final §2–§3, Ancestral's weakness by Final §4, and the chart is
locked as the VS3 baseline by Final §5. See §7 R-1 below for the completed result and the one cell
pair flagged for confirmation.

**6.2 — Punta Pitt modelling confirmed, recorded here for the world data schema.**
Per owner decision 21: Punta Pitt is a **terrestrial region** of San Cristóbal with a
**maritime landing point**, and is **not** an offshore island. The world schema therefore
separates two concepts — `region` and `landing_point` — and Punta Pitt is a region that owns a
landing point. León Dormido and Isla Lobos are maritime destinations. See `ADR-008` §3.

---

## 7. Canon restorations — omissions in the compact Master Canon

Separate from the GDD conflict, the C-001 review identified **two previously approved design
elements that the compact Master Canon omitted**. Both are restored by owner decision. They are
recorded here because they are canon restorations, not architectural choices.

| # | Restored element | Authority | Where it now lives |
|---|---|---|---|
| **R-1** | **Type strength/weakness baseline** — full matchup data for all 13 types, plus the ×2.0 / ×1.5 / ×1.0 / ×0.67 / ×0.4 scale, no immunities. **Completed** by Final §2–§5. | Review §2 · Final §2–§5 | `ADR-004` §6 → Canon Registry; Master Canon **v1.1 — Official types** |
| **R-2** | **Individual Tikawi personality** — persistent `personality_trait` / `personality_profile` on every individual | Review §3 | `ADR-004` §9 → Canon Registry; `STATE_OWNERSHIP.md` §4 |

**R-1 is now complete, not merely restored.** The restored baseline was matchup *lists*; three owner
decisions turned them into a resolved 13 × 13 chart:

| Final decision | Effect on canon |
|---|---|
| **§2** — one attacker → defender matrix, step lookup, dual-type sum-and-clamp, no genre immunities | Fixes how the lists are read and combined |
| **§3** — a declared strong matchup **establishes the inverse resistance** unless explicitly overridden | Generates 24 resistances that the lists never stated |
| **§4** — **Lucha strong vs Ancestral / Ancestral weak vs Lucha** | Closes the cycle `Lucha > Ancestral > Sombra > Psíquico > Lucha` and removes Ancestral's weakness-free profile |

Computed result: **26 strong · 24 derived resistances · 119 neutral · 0 immunities.** One cell pair
resists the rule — **Veneno → Psíquico and Psíquico → Veneno are both explicitly declared strong**, so
rule §3 cannot derive a resistance in either direction without contradicting the other's explicit
declaration. Resolved under that rule's own "unless explicitly overridden" clause: **both declarations
stand and the pair is mutually super-effective.** This is the single point in the chart where the
derivation rule and the declared data meet head-on, and it is flagged for owner confirmation in
`ADR-004` §6.4.

Per Final §5, **Planta's pressured profile (2 offensive · 5 weaknesses · 2 resistances · resisted by
5) is locked, not fixed.** It is the VS3 baseline. Any matchup change after this point is game-balance
design requiring owner approval — never a silent architecture-time adjustment, and never a rebalance
justified by Scalito being a starter.

**On R-2, the boundary matters as much as the restoration.** Personality is part of individual
identity and **must survive save/load**. It may affect overworld behaviour, social reactions, Bond
interactions, contextual tendencies and future small approved variation.

> It does **not** authorize IV/EV architecture, hidden stat rolls, or genetic stat variance.
> **Personality must never be an input to stat calculation, growth or level scaling.**

That boundary is enforced by a permanent CI test (`ADR-004` §9), because "personality as a small
stat modifier" is the natural implementation and is precisely the drift this restoration excludes.
Personality reaches the player through Bond reasoning instead — it appears in
`BondEvaluation.contributing_factors` (`ADR-007` §2), which already carries qualitative factors and
needs no new mechanism.

**Process note.** Both omissions were found by comparing the compact Master Canon against approved
design, not by an agent noticing something missing. The rule in §2 — every document declares its
`STATUS` and `AUTHORITY LEVEL` — protects against *stale* documents being treated as authority. It
does not protect against an authoritative document being **incomplete**. That is why the Canon
Registry (`ADR-004` §3) matters: once canon is data with validators, an omission of this kind
becomes a failing build rather than a silent gap discovered milestones later.

Both restorations now live in **Master Canon v1.1**, merged into their own sections — R-1 under
*Official types*, R-2 under *Tikawi* — so the
authoritative document is no longer the incomplete one.

---

## 8. Status of the archived document

`docs/archive/GDD_v1.0_SUPERSEDED.md` is retained permanently for historical reference.
It must never be cited as authority, quoted as design input, or used to resolve ambiguity.
Where it contains design that matters, that design has been promoted in §4 above and now lives
in canon — not in the archive.
