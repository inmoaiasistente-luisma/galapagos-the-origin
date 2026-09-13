# ADR-001 — Engine, Renderer and Pixel Contract

    STATUS: ACCEPTED — Luisma, 2026-09-12
    AUTHORITY LEVEL: 5 (approved technical architecture, once ACCEPTED)
    DATE: 2026-09-12
    REVISION: v3 — engine version pinned to 4.7.2-stable (C-002 owner review, decision 2)
              v2 — 480×270 superseded by 320×180 (Final Owner Decision 1)
    OWNER DECISIONS APPLIED: 2 (Engine), 3 (Renderer), Final 1 (Pixel Contract)
    CANON: Master Canon v1.1 — Technical baseline / Pixel contract

## Context

Godot and GDScript are canon. Nothing beneath them was specified: version, build flavour, renderer,
base resolution, scaling mode, tile size or sprite size classes. `project.godot` cannot be written
without these, and the pixel contract determines the production cost of every sprite the project
will ever draw.

A first revision proposed 480×270. The owner replaced it with **320×180**, which is the better
choice: it divides evenly into every common 16:9 display, which 480×270 did not.

## Decision

### 1. Engine

| Item | Decision |
|---|---|
| Engine | **Godot 4.7.2-stable** — PINNED (owner decision, C-002 review) |
| Build | **Standard GDScript build. No .NET / no C#.** |
| Export templates | **Godot 4.7.2 exactly.** A mismatched template version is a hard stop, never a workaround. |
| Pre-release builds | **Godot 4.8 development and pre-release builds are NOT authorized.** |
| Upgrades | Require a new ADR. Codex may never bump the engine, not even a patch release. |

**Pinning procedure — first task of VS0:**
1. Godot **4.7.2-stable** is installed on the owner machine, with its **matching 4.7.2 export
   templates**.
2. The exact version string is recorded in `docs/ENGINE.md`, `project.godot` and the CI workflow,
   together with the download URL and a **SHA-256 checksum** for both editor and templates.
3. **Codex and CI verify editor version == template version == 4.7.2 before any export.** On
   mismatch: stop and report. Do not export, do not substitute a nearby version.
4. Verify that 4.7.2-stable boots the empty project headless on both the owner machine and the CI
   runner, and record the evidence.

The version is now asserted because the owner has fixed it. It was previously left open precisely so
that it would be recorded from a real install rather than guessed — and the GUT pin (ADR-002 §3) is
selected **against 4.7.2**, not the other way round.

### 2. Renderer

**Compatibility renderer.** Target: modest Windows hardware. Moving to Forward+ later requires
demonstrated evidence plus a new ADR.

**VS0 verification gate** — under Compatibility on the pinned version, record pass/fail for:
`CanvasModulate` day/night tinting · `Light2D` + `LightOccluder2D` shadows (Farol, Cavernas de Lava,
night) · 2D normal maps if the art direction wants them · the blend/backbuffer modes required by
impact VFX (ADR-006) · screen-space weather effects.

A missing feature is evidence, and reopens this section under a new ADR rather than being worked
around silently.

### 3. Pixel contract (Final Owner Decision 1)

| Item | Value |
|---|---|
| **Virtual resolution** | **320 × 180** (16:9) |
| Stretch mode | `canvas_items` |
| Scaling | **Integer only**, viewport **centred** |
| Outside the viewport | Black or approved presentation background |
| Non-uniform stretching of gameplay pixels | **Never** |
| Texture filter | **Nearest**, no mipmaps, no lossy compression |
| World tile | **16 × 16** |
| Player sprite | **16 × 24** baseline, **16 × 32** tall pose |
| Tilemap node | `TileMapLayer` — deprecated `TileMap` forbidden |
| Overworld directions | **4 baseline** (N/S/E/W) |
| Mirroring | East/West permitted where visually appropriate |
| 8-direction animation | **Not required** for any Tikawi |

**Integer scaling behaviour — exact fill on every common 16:9 display:**

| Display | Scale | Result |
|---|---|---|
| 1280 × 720 | **×4** | exact fill |
| 1920 × 1080 | **×6** | exact fill |
| 2560 × 1440 | **×8** | exact fill |
| 3840 × 2160 | **×12** | exact fill |
| 1366 × 768 | ×4 | 1280 × 720 centred, letterbox/pillarbox (43 px sides, 24 px top/bottom) |

**Tile arithmetic.** 320 / 16 = **20 tiles wide, exactly**. 180 / 16 = **11.25 tiles tall** — not a
whole number, so region layouts and camera framing are designed in pixels, not in whole screens of
tiles. For reference, the GBA was 15 × 10 tiles; this is a slightly wider view at the same height,
consistent with the canonical "richer early-GBA-like" target.

### 4. Tikawi size classes (Final Owner Decision 1)

**Production canvases, not a requirement that every sprite fill its canvas.**

| Class | Overworld | Battle | Typical occupants |
|---|---|---|---|
| **S** | 16 × 16 | 48 × 48 | insects, small plants, fungi, hatchlings |
| **M** | 24 × 24 | 64 × 64 | most Tikawi; comparable to the player |
| **L** | 32 × 32 | 80 × 80 | second/third-stage land and marine forms |
| **XL** | 48 × 48 | 96 × 96 | large final stages |
| **LEGENDARY** | 64 × 64 + | up to 128 × 128 | Volcápago, Martilord, Albatempest |

Every Tikawi declares exactly one class, from a closed enum in the canon registry (ADR-004).

### 5. Battle staging — VS3 verification gate

Battle canvases grew while the viewport shrank, so staging must be **verified rather than assumed**.
Against a 320 × 180 viewport:

| Case | Footprint | Share of viewport |
|---|---|---|
| M battle sprite (64 × 64) | one combatant | 20% width · 36% height |
| XL (96 × 96) | one combatant | 30% width · 53% height |
| LEGENDARY (128 × 128) | one combatant | 40% width · **71% height** |
| 2v2, four M-class | 4 × 64 px | up to 80% width if staged in one row |

**Owner confirmation: the 320 × 180 contract and the battle canvas classes above are APPROVED as
production maxima and are NOT to be changed speculatively.** They are proven, not adjusted, and any
future adjustment must be based on **playable visual evidence**, never on an estimate made before
sprites exist — including the estimates in the table above.

Neither case is a problem, but both are tight, and the canon requires travel space for
windup → travel → contact → reaction. **VS3 must prove the contract with, as acceptance criteria:**

1. a **staged LEGENDARY 1v1** case;
2. a **staged M-class 2v2** case;
3. **all mandatory action / impact / reaction beats readable** in both. Mitigations available without touching this contract: depth-staggered rows rather
than a single line, sprites occupying less than their canvas (explicitly permitted), and HUD layout
that does not compete with the staging band.

### 6. Mirroring constraint

A design with a deliberately asymmetric feature (a marking, a scar, a single claw) must either
accept that the feature swaps sides under E/W mirroring, or declare `mirror: false` in its asset
manifest and ship both directions.

## Alternatives considered

| Alternative | Why not chosen |
|---|---|
| **480 × 270** *(this ADR's v1)* | Superseded. Exact fill only at 1080p and 4K; 1366×768 and 1280×720 fell to ×2 with roughly half the screen unused. 320×180 divides evenly into all four common 16:9 resolutions. |
| **240 × 160 (true GBA)** | Maximum period fidelity; too little staging room for the seven-beat performance rule, and does not scale integer to 16:9 displays. |
| **Godot 4.x .NET / C#** | GDScript is canon. Adds a runtime, export size and CI friction for no benefit. |
| **Godot 3.x** | Effectively a different language and toolchain; no forward path. |
| **Forward+ renderer** | Better 2D light tooling; raises the GPU floor against the modest-hardware target. Deferred behind an evidence gate rather than refused. |
| **Non-integer / smooth scaling** | Fills every display, destroys pixel-perfect rendering. Contradicts canon. |
| **Expanded viewport at odd resolutions** | Avoids letterboxing; makes visible area display-dependent. Rejected: with 320×180, letterboxing is rare enough that identical framing is the better trade for handcrafted maps. |
| **8-direction overworld animation** | Roughly 2.7× the overworld frame count across ~150 Tikawi. Infeasible, and not required by canon. |
| **Per-species sprite dimensions** | Makes every Tikawi a bespoke integration case — the art-pipeline equivalent of species-specific scripts. |

## Consequences

**Integer scaling is now effectively universal.** Four of the five most common Windows resolutions
fill exactly; only 1366 × 768 letterboxes, and it does so at ×4 rather than ×2. This removes the
open question that existed under 480 × 270.

**Asset cost.** 4 directions with E/W mirroring means **3 authored directions** per overworld
animation — roughly a 60% reduction in overworld frame count versus 8-direction across ~150 Tikawi.
The single largest art-budget decision in the contract.

**Battle sprites are proportionally large.** Relative to the viewport, battle canvases are
substantially bigger than under the superseded contract. This suits detailed creature presentation
and is why §5 exists as a verification gate rather than an assumption.

**A smaller world viewport.** 20 × 11.25 tiles is an intimate, period-appropriate frame. Region
compositions and encounter staging must be authored for it from the first map.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| LEGENDARY or 2v2 staging cannot fit the seven beats legibly at 320×180 | **High** | §5 VS3 verification gate with named acceptance criteria, before content scale-out |
| A required 2D feature is unavailable under Compatibility | High | §2 VS0 verification gate, before any presentation work |
| Editor and export template versions drift | High | Both pinned and CI-verified; mismatch fails the build |
| Size-class canvases prove wrong after sprites exist | High | Locked now, before art production begins |
| The 320×180 world view feels cramped for exploration | Medium | Evaluated in VS1 with real maps; camera and region composition absorb it |
| Asymmetric Tikawi designs break under mirroring | Low | `mirror: false` escape hatch in the asset manifest |

## Migration / compatibility impact

**Save compatibility: none.** Nothing in this ADR is persisted.

- Changing **base resolution or tile size** after content exists is not a migration — it is
  re-authoring every map and sprite. This is the ADR that must be right before VS1 content begins,
  and the 480 → 320 revision was made at the only cost-free moment to make it.
- Changing the **renderer** affects shaders and visual verification, not data or saves; it requires
  re-running §2.
- An **engine upgrade** may rewrite import formats and `.import` metadata; treat every upgrade as a
  full regression pass including export.
- **Size classes** are a closed enum in the canon registry; adding a class later is a registry
  change plus asset work, not a schema break. Class assignment per species is generated data, not
  persisted.

## Findings resolved

| Finding | Resolution |
|---|---|
| **AUD-003** — engine version, renderer and export templates unpinned | §1, §2 |
| **AUD-005** — pixel contract undefined | §3, §4, §6 — **now fully closed**; the letterbox open item is resolved by 320×180 |

## Open items

**None blocking.** §5 is a VS3 acceptance criterion, not an open decision.
