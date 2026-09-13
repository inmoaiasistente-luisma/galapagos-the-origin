# ADR-004 — Content Data Pipeline, IDs, Canon Registry and Localization

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5
    DATE: 2026-09-12
    OWNER DECISIONS APPLIED: 7 (Data), 8 (Language), 14 + Review §2 (Type matchup baseline — RESTORED),
                             18 (Evolution structure), 20 (Localization), Review §3 (Personality — RESTORED)

## Context

The authoritative flow `source → schema → semantic → canon → generated resources` was defined
conceptually with no formats, no ID rules and no generation policy. Meanwhile the Master Canon is
an unusually well-formed set of **closed enumerations**, which makes it machine-verifiable if we
choose to treat it that way.

## Decision

### 1. Source format

| Item | Decision |
|---|---|
| Authoritative source | **JSON**, committed, diffable |
| Location | `data/source/` |
| Spreadsheets | Permitted as an **authoring tool** only; export to JSON, which is authoritative |
| Hand-editing generated artifacts | **Forbidden**, enforced by generated header + CI |

### 2. Identity

| Rule | Detail |
|---|---|
| Format | **`snake_case` string**, stable forever |
| Example | `species_id: "mariguin"`, `region_id: "tierras_altas"` |
| Registry | Append-only `data/source/_registry/ids.json` |
| Reuse | **Never**, for any reason |
| Rename | Requires migration analysis — a rename is a schema change |
| Retirement | Moved to `deprecated_ids` with a reason; never deleted |
| `codex_number` | **Presentation metadata. Never identity. Never written into a save.** |

Codex ordering within a pillar is an editorial decision the owner must remain free to change. If
the number were identity, reordering two birds would be a save migration.

Same rule for regions, moves, items, quests, entry points, world changes and **individual Tikawi**
(`instance_id`): string IDs, never positional indices.

### 3. Canon Registry — canon as verifiable data

`data/source/canon/` holds the Master Canon's closed enumerations as data. GDScript constants and
enums are **generated** from it, so canon is never hand-transcribed into code.

Contents: 13 types · **type matrix (§6)** · 7 rarities · 4 origin tags · 7 level bands ·
5 Bond states · 5 research stages · 5 move categories · 8 terrain states · 4 depth levels ·
9 field capabilities · 4 Legendario states · 10 regions · 5 Masters · 5 size classes ·
**personality registry (§9)** · the 150-entry manifest.

**Canon validators (CI gate 3):**

| Check | Rule |
|---|---|
| Type count | exactly 13 |
| Forbidden types | Normal, Hada, Dragón, Fantasma, Luz, Roca, Viento must not exist |
| Codex total | exactly 150 |
| Pillar ranges | 9 / 30 / 24 / 24 / 30 / 18 / 12 / 3 |
| Family names | match the Master Canon **literally** |
| Reserved names | Cormorr, Terriguana, Abyssiguana, Scalysia absent from the Volume I roster |
| Legendarios | exactly 3; no evolution; excluded from normal encounter tables and normal team/reserve |
| Size class | every Tikawi declares exactly one |
| Type matrix | structure valid per §6 |

### 4. Family and evolution structure (owner decision 18)

| Rule | Detail |
|---|---|
| Non-Legendary families | **49 families, exactly 3 Codex entries each** |
| Legendarios | 3, single entries, no transitions |
| Topology | **A directed graph, not necessarily a linear chain** |
| Branching | A three-entry family **may** represent branching adaptation, subject to owner approval |

The data model stores evolution as **edges** (`{from_species, to_species, conditions[]}`), never as
an ordered list of stages. `A→B→C` and `A→B, A→C` are both valid three-entry families. Modelling it
as a chain would silently forbid branching adaptation, which the owner has explicitly kept open.

**Validators:** exactly 3 entries per non-Legendary family · every entry reachable from the family
base · no cycles · no cross-family edges · Legendarios have zero edges · every condition references
existing IDs · every transition achievable with Volume I content.

Conditions use the shared closed vocabulary (§5), covering the seven canonical triggers: level,
rare object, habitat/location, time, bond, challenge, research.

No evolution **level thresholds** are canon, and no move-upgrade chain system exists in the
Volume I baseline (`CANON_CONFLICT_RESOLUTION.md` §5).

### 5. One condition vocabulary for the whole game

A **single closed, validated registry** of conditions and effects, shared by evolution, quests,
dialogue, research stages, encounters and world gating.

Closed set; adding a condition type is a reviewed code + registry change. No arbitrary expressions,
no embedded scripting, no string-evaluated logic. Unknown condition type, unknown referenced ID or
malformed parameters fail the build.

This is what keeps quest data from becoming a programming language, and one grammar across six
systems is far cheaper to validate and author than three.

### 6. Type matrix — RESTORED AND COMPLETE (Review §2, Final §2–§5)

Canon: **Master Canon v1.1 — Official types / Type effectiveness.** Registry: `data/source/canon/type_matrix.json`.

**6.1 Declared baseline**

| Type | Strong vs | Weak vs |
|---|---|---|
| Agua | Fuego, Tierra | Planta, Eléctrico |
| Fuego | Planta, Insecto | Agua, Tierra |
| Planta | Agua, Tierra | Fuego, Insecto |
| Tierra | Eléctrico, Fuego | Agua, Planta |
| Aire | Insecto, Planta | Eléctrico, Tierra |
| Eléctrico | Agua, Aire | Tierra |
| Frío | Aire, Planta | Fuego |
| Veneno | Planta, Psíquico | Tierra |
| Insecto | Planta, Psíquico | Fuego, Aire |
| Sombra | Psíquico | Ancestral |
| Psíquico | Veneno, Lucha | Sombra, Insecto |
| **Ancestral** | Sombra | **Lucha** |
| **Lucha** | **Ancestral** | Psíquico |

**Canonical cycle: Lucha > Ancestral > Sombra > Psíquico > Lucha** — closed, verified.

**6.2 Resolution rules (Final §2, §3)**

1. **One matrix, attacker → defender.** *"X weak vs Y"* and *"Y strong vs X"* are the same cell.
   The matrix is the union of every `strong vs` entry and the inverse of every `weak vs` entry.
   This is intentional and includes **Tierra → Aire**, **Fuego → Frío** and **Tierra → Veneno**.
2. **No genre immunities.** No cell resolves to ×0.
3. **A declared strength establishes the inverse resistance ONLY when the inverse direction is not
   itself explicitly declared strong.** `Agua → Fuego = +1`, and `Fuego → Agua` is not declared
   strong, therefore `Fuego → Agua = −1`. **An explicit strong declaration always overrides a
   derived resistance.** *(Owner confirmation, refined wording.)*
4. **Step lookup, never multiplication:** `+2 → ×2.00 · +1 → ×1.50 · 0 → ×1.00 · −1 → ×0.67 ·
   −2 → ×0.40`.
5. **Dual typing:** sum the steps against both defender types, **clamp to [−2, +2]**, then look up.
6. **Mutual strength is permitted.** Where both directions are explicitly declared strong, both
   stand and no inverse resistance is derived in either direction (§6.4). This follows directly from
   rule 3 as refined and is stated separately only because it is the case implementers will hit.

**6.3 Resulting matrix — computed and verified**

**26 strong (+1) · 24 derived resistances (−1) · 119 neutral · 0 immunities.**

| Attacker | +1 (×1.50) against | −1 (×0.67) against |
|---|---|---|
| Agua | Fuego, Tierra | Planta, Eléctrico |
| Fuego | Planta, Insecto, **Frío** | Agua, Tierra |
| Planta | Agua, Tierra | Fuego, Aire, Frío, Veneno, Insecto |
| Tierra | Eléctrico, Fuego, **Aire**, **Veneno** | Agua, Planta |
| Aire | Insecto, Planta | Tierra, Eléctrico, Frío |
| Eléctrico | Agua, Aire | Tierra |
| Frío | Aire, Planta | Fuego |
| Veneno | Planta, **Psíquico** | Tierra |
| Insecto | Planta, Psíquico | Fuego, Aire |
| Sombra | Psíquico | Ancestral |
| Psíquico | **Veneno**, Lucha | Sombra, Insecto |
| Ancestral | Sombra | Lucha |
| Lucha | Ancestral | Psíquico |

**6.4 Veneno ↔ Psíquico — CONFIRMED BY OWNER**

> **Veneno → Psíquico = ×1.50** and **Psíquico → Veneno = ×1.50.**
> Mutually super-effective. **Confirmed.**

Both directions are explicitly declared strong. Under rule 3 as refined, neither derives an inverse
resistance from the other, because a declared strength only establishes the inverse resistance when
the inverse direction is *not* itself declared strong.

**This is the only mutually super-effective pair in the baseline, and it is intentional.** The
validator in §6.6 therefore asserts the count of mutual-strength pairs is exactly **1** — a second
one appearing is a data error until an owner decision says otherwise, not a silent new mechanic.

**6.5 Verified type profiles**

| Type | Attacks ×1.5 | Weak to | Resists | Is resisted by |
|---|---|---|---|---|
| Agua | 2 | 2 | 2 | 2 |
| Fuego | 3 | 2 | 2 | 3 |
| **Planta** | 2 | **5** | 2 | **5** |
| Tierra | **4** | 2 | 2 | 4 |
| Aire | 2 | 3 | 3 | 2 |
| Eléctrico | 2 | 1 | 1 | 2 |
| Frío | 2 | 1 | 1 | 2 |
| Veneno | 2 | 2 | 1 | 1 |
| Insecto | 2 | 2 | 2 | 2 |
| Sombra | 1 | 1 | 1 | 1 |
| Psíquico | 2 | 3 | 2 | 1 |
| **Ancestral** | **1** | **1** | 1 | 1 |
| **Lucha** | **1** | **1** | 1 | 1 |

**Ancestral is resolved.** With `Lucha > Ancestral` it holds 1 strength and 1 weakness — identical
to Lucha, and the narrowest profile in the chart alongside it. The "generically overpowered"
condition flagged in C-001 no longer exists.

**Planta is the outlier and is locked, not fixed (Final §5).** It is struck by five types and
resisted by those same five, holding two strengths and two resistances. **This is the VS3 baseline
and must not be rebalanced during architecture work.** It is evaluated through simulation and
playtesting. **Any matchup change after this point is game-balance design requiring owner
approval.** Note that Scalito is a starter, so this is the VS3 balance priority.

**Tierra has the broadest offensive coverage** (four types) and is the second item to watch.

**6.6 Validators (structure, not balance)**

13 × 13 · no missing or unknown type · every multiplier from the §6.2 tier set · net-step stacking
clamped to [−2, +2] · **no immunities present** · **every type has at least one weakness** (all 13
now pass) · the starter triangle (Agua > Fuego > Planta > Agua) holds · the canonical cycle
(Lucha > Ancestral > Sombra > Psíquico > Lucha) is closed · the derived-resistance rule holds for
every strong cell except the declared mutual pair.

**VS3 balance gate (not a validator):** a simulation report of matchup win-rates, with Planta and
Tierra flagged for owner review.

### 7. Generated runtime artifacts (Final §8 — RESOLVED)

Authoritative source remains **JSON under `data/source/`**. Generated runtime/editor resources
**may be committed where required for a reliable Godot authoring workflow**, but they are
**NEVER authority**.

1. Generated artifacts derive from `data/source/` and nothing else.
2. Every generated file carries an autogenerated header naming its source.
3. **CI gate 4, required behaviour:** `source → regenerate → compare generated artifacts → fail on
   drift`. Divergence is unmergeable, by construction.
4. **No manual edits to generated resources**, ever.
5. No system reads source JSON *and* a generated artifact for the same content.

Because generation is permitted **where required** rather than mandated everywhere, C-002 selects
per content type: generate `.tres` where the Godot editor genuinely needs inspector-referenceable
resources; load validated JSON directly where it does not. Both satisfy the rules above. The
previously open question of whether to generate at all is therefore closed — it is a per-case
workflow choice, not an architectural fork.

### 8. Localization (owner decisions 8, 20)

| Item | Decision |
|---|---|
| Narrative authoring language | **Spanish** (initial canonical) |
| Required localization | **English**, mandatory |
| Code identifiers, comments, technical docs | English |
| Canonical proper names | **Never translated** |

Keys are **generated from immutable IDs**, never hand-written:
`tikawi.<species_id>.name` · `tikawi.<species_id>.codex_desc` · `research.<species_id>.stage_<n>` ·
`move.<move_id>.name` · `region.<region_id>.name` · `personality.<trait_id>.name`

**Proper-noun invariance gate.** Tikawi names, canonical toponyms and character names are listed in
a non-translatable registry; **CI fails if their value differs between locales.** Without this,
"Mariguín", "Volcápago" and "Tierras Altas" will eventually be "translated" by a well-meaning
contributor or agent.

**CI gate 9:** missing keys in any locale · orphan keys · literal strings in UI scenes and scripts ·
proper-noun divergence. Estimated volume before dialogue: ~3,000–5,000 keys × 2 locales.

### 9. Personality registry — RESTORED (Review §3)

Individual Tikawi carry a **persistent personality**, part of individual identity.

| Item | Decision |
|---|---|
| Registry | `data/source/canon/personality.json` — a **closed, validated** set of traits/profiles |
| Field | `personality_trait` (or `personality_profile`) on `TikawiInstance` |
| Assignment | At instance creation, from the seeded RNG and/or context; **persisted** |
| Persistence | **Survives save/load** — see `STATE_OWNERSHIP.md` §4 |
| May affect | overworld behaviour · social reactions · Bond interactions · contextual tendencies · future small approved variation |
| Localization | `personality.<trait_id>.*` keys, like all content |

**Hard boundary, and the reason this needs stating explicitly:**

> **Personality MUST NEVER be an input to stat calculation, growth, or level scaling.**

Personality is a **behavioural tag**, not a hidden stat roll. The stat calculator must not even
receive it. This is what keeps personality from becoming IV/EV architecture by the back door,
which owner decision 3 of the review explicitly excludes. CI test: the stat calculator does not
depend on personality.

Natural integration point: personality appears in `BondEvaluation.contributing_factors`
(ADR-007 §2) — a qualitative reason, exactly the shape that contract already requires.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **YAML or TOML source** | More pleasant to hand-edit; adds a parser dependency and weaker native Godot support. JSON is natively supported and diffs predictably. |
| **Hand-authored `.tres` as source** | Removes the pipeline, but makes content editor-only, merge-hostile, and unvalidatable outside Godot. |
| **Spreadsheet as authoritative source** | Best bulk-authoring ergonomics; binary, unmergeable, undiffable. Kept as a tool feeding JSON. |
| **Integer IDs** | Smaller saves, faster comparison; unreadable in diffs and a renumbering hazard. Save size is a non-issue at this scale. |
| **`codex_number` as identity** | The tempting default. Makes every editorial reordering a save migration. |
| **Evolution as an ordered stage list** | Simpler; silently forbids branching families, which the owner explicitly kept open. |
| **Separate condition vocabularies per system** | Locally convenient; three grammars to validate, three to author, three to drift. |
| **Multiplicative type stacking** (×1.5² = ×2.25) | Conventional, but contradicts the stated ×2.0 / ×0.4 values. The tiered reading matches the owner's numbers exactly. |
| **Type immunities (×0)** | Genre-standard; explicitly excluded until approved. Immunities also create unwinnable matchups that interact badly with the anti-soft-lock guarantee. |
| **Personality as a stat modifier** | The obvious implementation, and precisely the IV/EV drift the review forbids. Rejected by boundary, not by preference. |

## Consequences

- Canon drift between document and code becomes a build failure rather than a review finding.
- Editorial reordering of the Codex costs nothing.
- The evolution graph model supports branching without a future migration.
- The battle system is implementable against a partially populated matrix; balance arrives later
  without touching code.
- Personality adds individual identity with no stat-system complexity.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| ~~The Veneno ↔ Psíquico mutual strength is not what the owner intended~~ | **Closed** | Confirmed by owner. Validator asserts exactly one mutual-strength pair, so an unintended second one fails the build |
| ~~Ancestral stays weakness-free and dominates late play~~ | **Closed** | Final §4 gives Ancestral a weakness (`Lucha > Ancestral`); its profile is now 1 strength / 1 weakness / 1 resist / 1 resisted |
| Planta's five-attacker exposure makes Scalito the weak starter | Medium | Surfaced and **deliberately locked** (Final §5). Resolvable during VS3 through movepool, stats or encounter design — **not** by silently rebalancing the chart |
| Tiered stacking misreads the owner's intent | **Closed** | Confirmed by Final §2: step lookup, dual-type sum-and-clamp |
| An ID is renamed casually and saves break | High | Append-only registry, `deprecated_ids`, and the ADR-005 schema-hash guard |
| Personality drifts into stat effects during implementation | Medium | Explicit boundary + CI test that the stat calculator does not depend on it |
| Generated artifacts drift from source | Medium | CI gate 4 regenerate-and-diff makes divergence unmergeable |
| Localization key volume becomes unmanageable | Medium | Keys generated from IDs, never written by hand |

## Migration / compatibility impact

**Persisted by this ADR:** `species_id`, `instance_id`, `personality_trait`, and every other
content ID referenced from a save.

- **IDs are the save's vocabulary.** Any rename, reuse or deletion is a save migration. This is why
  reuse is banned outright rather than discouraged.
- **`codex_number` is never persisted**, so Codex renumbering is always migration-free.
- **Personality is persisted from VS2 onward.** Introducing it now costs nothing; introducing it
  after instances existed would be a `save_version` bump plus a backfill migration assigning traits
  to already-bonded Tikawi. Restoring it at this point avoids that entirely.
- **Type matrix, canon registry and generated artifacts are not persisted.** Rebalancing the matrix
  at VS3, adding resistances, or giving Ancestral a weakness are **data changes with zero save
  impact** — the reason the battle system can be built before balance is finished.
- **Evolution edges are not persisted**; only the resulting `species_id` of an instance is. A
  family's topology can therefore be revised without touching saves, provided no species ID changes.
- Adding a personality trait to the closed registry later is additive and migration-free; removing
  one requires a migration for instances already carrying it.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-008** — source format, ID scheme, generated policy undefined | §1, §2, §7 |
| **AUD-029** — canon enums lived only in prose | §3 |
| **AUD-030** — `codex_number` as identity would make renumbering a migration | §2 |
| **AUD-028** — no localization key convention, gate or proper-noun policy | §8 |
| **AUD-047** — type matrix missing | §6 — **now resolved by the restored baseline**, with open balance items |

## Open items

**None.** Every item is closed: derivation readings confirmed (Final §2), the three derived cells
confirmed intentional (Final §2), Ancestral given a weakness (Final §4), the generated-data workflow
resolved (Final §8), and the Veneno ↔ Psíquico pair confirmed with the refined inverse-resistance
rule (owner confirmation, §6.2 rule 3 and §6.4).

The type matrix is **locked as the VS3 baseline**. Any matchup change after this point is
game-balance design requiring owner approval.
