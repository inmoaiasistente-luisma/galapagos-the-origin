    STATUS: ACCEPTED — LOCKED FOR IMPLEMENTATION BASELINE
    AUTHORITY LEVEL: 2 (Master Canon — highest authority below Luisma's current decision)
    CANON BASELINE: v1.1 (consolidated)
    ARCHITECTURE BASELINE: v1.1
    UPDATED: 2026-09-12 (C-001 Final Owner Decisions + owner confirmations)
    NOTE: This document is CONSOLIDATED. Every accepted v1.1 decision is merged
          into its correct section below. There is no addendum to reconcile.
          What changed is recorded in git history, in the ADRs, and in the
          compact change history at the end of this document — which is
          HISTORY, not a second source of truth.

---

# GALÁPAGOS: THE ORIGIN — MASTER CANON
**Architecture Baseline:** v1.1  
**Canon Baseline:** v1.1 (consolidated)  
**Status:** LOCKED FOR IMPLEMENTATION BASELINE  
**Primary Authority:** Luisma / Creative Owner

## Purpose
This document is the authoritative creative and game-design canon for **GALÁPAGOS: THE ORIGIN**. If code, old drafts, archived documents, agent memory, or prior conversations conflict with this document, this document wins unless Luisma explicitly approves a change.

## Project identity
- Title: **GALÁPAGOS: THE ORIGIN**
- First installment: **Volume I — San Cristóbal**
- Era: **1835**
- Protagonist: fictionalized young **Charles Darwin**, canonically **20 years old**
- Genre: open-world 2D pixel-art RPG focused on exploration, discovery, research, bonding, training, turn-based battle, adaptation/evolution, conservation and maritime exploration
- Franchise theme: **“There is always more to discover.”**

## Core design pillars
1. Exploration
2. Discovery
3. Bonding / companionship
4. Training / battles
5. Adaptation / evolution
6. Conservation vs exploitation

Canonical principle:
> **“The world does not exist to serve Blackwood; Blackwood exists inside the world.”**

## Art direction
- 2D pixel art
- top-down overworld
- GBC/GBA-era structural inspiration with original assets and identity
- richer early-GBA-like palette/detail, but not HD-2D
- pixel-perfect scaling
- playable locations presented as pixel-art maps
- maps are handcrafted, not procedurally generated

Canonical rule:
> **“Maps are authored, not procedurally generated. Systems vary what happens inside them.”**

## Mandatory animation rule
> **Combat moves are performances, not numerical notifications. Every move must communicate its action visually.**

A completed offensive move should visibly show, when appropriate:
- windup
- body action
- travel/projectile/contact
- impact
- target reaction
- sound
- recovery

A sprite-only nudge, flash, or damage number is **not** a completed attack animation.

Field abilities follow the same rule:
> **A field interaction is complete only when the Tikawi visibly performs the action in the world.**

### Animation accessibility
The mandatory visible-animation rule is unchanged. Its **presentation** may be adapted:

| Mode | Behaviour |
|---|---|
| **FULL** | Complete performance |
| **FAST** | Accelerated performance |
| **MINIMAL** | Reduced performance |

**All three modes retain recognizable action → impact → reaction communication.** Core move
readability may never be removed. There is no mode in which a move resolves as a number.

Screen shake and intense flash/effect intensity must be **independently** reducible and disableable
in every mode, including FULL.

## Tikawi
Official creature name: **Tikawi**
- singular: un Tikawi
- plural: los Tikawi

Do not use Galamon.  
Evori/Evoris remains reserved/unassigned.  
Do not claim a literal Kichwa meaning.

Tikawi are fictionalized Galápagos organisms whose extraordinary abilities exaggerate real adaptations, ecological pressures and isolation.

Codex origin tags:
- NATIVO
- ENDÉMICO
- INTRODUCIDO
- ORIGEN DESCONOCIDO

Plants, fungi and insects are separate roster pillars.

### Individual personality
Every individual Tikawi carries a **persistent personality trait/profile**. It is part of individual
identity and survives save/load.

**It may influence:** overworld behaviour · social reactions · Bond contributing factors ·
contextual tendencies.

**It must NOT influence:** base stat calculation · stat growth · hidden IV-like rolls ·
EV/training-point accumulation.

Personality is a behavioural identity, not a hidden statistic.

## Official types
Exactly 13:
1. Agua
2. Fuego
3. Planta
4. Tierra
5. Aire
6. Eléctrico
7. Frío
8. Veneno
9. Insecto
10. Sombra
11. Psíquico
12. Ancestral
13. Lucha

Do not introduce Normal, Hada, Dragón, Fantasma, Luz, Roca or Viento as official types.

### Type effectiveness — declared relationships

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
| Ancestral | Sombra | Lucha |
| Lucha | Ancestral | Psíquico |

### Canonical type cycle

> **Lucha > Ancestral > Sombra > Psíquico > Lucha**

A closed four-type cycle. Ancestral is powerful but **not generically overpowered**: it holds one
strength and one weakness, exactly like Lucha.

### Type effectiveness — rules

1. **One matrix, attacker → defender.** *"X is weak vs Y"* and *"Y is strong vs X"* are the same
   relationship, expressed from two sides.
2. **No genre immunities.** No matchup resolves to ×0.
3. **A declared strength establishes the inverse resistance ONLY when the inverse direction is not
   itself explicitly declared strong.** An explicit strong declaration overrides a derived
   resistance. *Agua → Fuego is +1, and Fuego → Agua is not declared strong, therefore
   Fuego → Agua is −1.*
4. **Step lookup, never multiplication:**

   | Steps | Multiplier |
   |---|---|
   | +2 | ×2.00 |
   | +1 | ×1.50 |
   | 0 | ×1.00 |
   | −1 | ×0.67 |
   | −2 | ×0.40 |

5. **Dual typing:** sum the steps against both defender types, clamp to [−2, +2], then look up.
6. **Mutual strength is permitted, and occurs exactly once.**
   **Veneno → Psíquico = ×1.50** and **Psíquico → Veneno = ×1.50.** Both declarations stand and
   neither derives a resistance from the other. This is **intentionally the only mutually
   super-effective pair in the baseline**; a second one is a data error until Luisma decides
   otherwise.

Resulting baseline: **26 strong cells · 24 derived resistances · 119 neutral · 0 immunities.**

### Planta — baseline locked for evaluation

Planta receives strong incoming attacks from **Fuego, Insecto, Aire, Frío and Veneno**, and its own
attacks are resisted by those same five types. It resists Agua and Tierra.

This is the **VS3 baseline and is not to be rebalanced during architecture work.** It is evaluated
through simulation and playtesting. **Any matchup change after this point is game-balance design and
requires owner approval.**

## Level and evolution
Max level: **60**

Bands:
- 1–10 Cría / principiante
- 11–20 Desarrollo
- 21–30 Intermedio
- 31–40 Avanzado
- 41–50 Élite
- 51–59 Maestro
- 60 Máximo

Evolution may depend on:
- level
- rare object
- habitat/location
- time
- bond
- challenge
- research

Evolution should meaningfully alter at least 3 of:
- silhouette
- anatomy
- behavior
- ability
- habitat
- ecological function

“Same animal, only bigger” fails review.

## Rarity
- ○ Común
- ● Poco común
- ◆ Rara
- ◆◆ Muy rara
- ✦ Exótica
- ✦✦ Mítica
- 👑 Legendaria

Rare does not automatically mean stronger.

## Starters — LOCKED
### Agua
**Mariguín → Mariguán → Mariguard**

### Fuego
**Lavalín → Lavarok → Lavadrake**

### Planta
**Scalito → Scalebark → Scaleking**

Important:
- Lavalín is a volcanic **bird**, not a reptile
- Scalito = tortoise + Scalesia inspiration
- Scalito is not a humanoid plant
- Scalysia is not Scalito’s evolution

Field roles:
- Mariguín line: Nado → Inmersión
- Lavalín line: Planeo
- Scalito line: Fuerza / Despeje

No starter may soft-lock the player.

## Volume I Codex — exactly 150
- 001–009 Starters = 9
- 010–039 Aves = 30
- 040–063 Reptiles = 24
- 064–087 Mamíferos = 24
- 088–117 Marinos/Invertebrados = 30
- 118–135 Plantas/Hongos/Insectos = 18
- 136–147 Especiales = 12
- 148–150 Legendarios = 3

### Active bird families
- Piquete → Piquelón → Piquealto
- Aluzín → Plumasol → Nubelia
- Garzél → Garzalín → Garzénix
- Cantina → Cantorín → Melodaria
- Fragatín → Fragatax → Magnifrax
- Patazul → Azurido → Azurión
- Gavilava → Aerorok → Ignialto
- Peliki → Pelicánt → Bolsamar
- Charrín → Charránia → Alamaris
- Atardal → Ocasol → Solárdex

Cormorr is reserved for later Isabela/Fernandina content and is not Volume I canon.

### Active reptile families
- Serpentia → Víborax → Ofidra
- Volcánica → Maghín → Maghator
- Geckor → Sombrageck → Escalinix
- Camuflín → Mimetik → Criptogón
- Tortugón → Tortarca → Terracasco
- Caparazul → Marearca → Oceánide
- Umbrag → Sombralag → Noctigón
- Anolisia → Ramilag → Dosselia

Terriguana is reserve, not active Volume I roster.

### Active mammal families
- Lobín → Lobario → Leonmar
- Peluri → Arctomar → Nivalmar
- Cachor → Canigal → Explorcan
- Gatín → Felinia → Sombralinx
- Ternerín → Taurgal → Cuernisla
- Riverín → Amphibov → Manglobov
- Conil → Conilag → Terracone
- Erizín → Erizoro → Espinoro

Amphibov/Manglobov is deliberately fictional and remains capybara-like.

### Active marine / invertebrate families
- Mantaris → Mantaluz → Marealido
- Tiburango → Filocéano → Abismandib
- Cabruplupo → Cefazul → Krakelis
- Cangrécido → Lavapinza → Rocamar
- Erizmar → Roquerizo → Baluérizo
- Medusal → Aurelén → Thalassia
- Hippocális → Hippoceano → Dracomar
- Langostral → Pinzático → Titancrusta
- Calamérix → Tintágor → Abisminte
- Nautilis → Spiralum → Archelonte

Dracomar does not imply a Dragon type.

### Plants / fungi / insects
- Cactilia → Espinela → Cardonis
- Mangleo → Raizmar → Arbolama
- Brotís → Germinal → Lavarbo
- Esporén → Micelium → Fungial
- Polinex → Nectivol → Apiclaro
- Termita → Arquitera → Citaduna

### Specials
136 Aurorín  
137 Auroris  
138 Solarius  
139 Umbrain  
140 Sombrélix  
141 Nocthera  
142 Cristalín  
143 Cristalith  
144 Prismatheon  
145 Lunén  
146 Miraluna  
147 Astralis

Specials rely on conditions/mysteries, not merely tiny random spawn rates.

## Legendarios — LOCKED
### #148 Volcápago
- Tierra/Fuego
- force of earth/fire/island formation
- phrase: **“El origen de las islas.”**
- battle identity: Tank / terrain control

### #149 Martilord
- Agua/Psíquico
- ocean force / guardian
- hammerhead inspiration / electroreception
- battle identity: Hunter / perception

### #150 Albatempest
- Aire/Ancestral
- wind/sky force / messenger
- great ocean bird / albatross-inspired
- can traverse the archipelago
- do not claim normal San Cristóbal albatross population
- battle identity: Speed / climate

Abyssiguana and Scalysia are not Volume I Legendarios.

Legendarios:
- do not evolve
- do not use normal team/reserve
- do not use normal random encounter tables
- do not use normal Bond flow
- may use states Calmado / Alterado / Fuera de control / Restaurado

## Main characters
- Charles Darwin — 20, young naturalist, beardless
- Isabela — ~19, island-born, practical, confident, agile, humorous
- Tomás — ~21, Ecuadorian sailor/colonist, rival/friend, athletic, impulsive, funny
- Blackwood — 45–50, elegant, dark geometric silhouette, coat/gloves/cane
- Eleanor Vale — 30–35 scientist/naturalist, morally ambiguous
- Silas Hawkins — 40–45 former whaler/mariner
- Mama Yara — 70+, elder storyteller
- Capitán Humberto — experienced local sailor tied to On The Hook

## On The Hook
A small 1835 wooden expedition sailboat/cutter with:
- cream sails
- wooden hull
- “ON THE HOOK” on hull

No motors, GPS, antennas or fiberglass.

It supports:
- wildlife observation
- coastal exploration
- fishing
- expedition travel
- León Dormido
- Isla Lobos
- Isla Perdida
- Punta Pitt
- mobile base functions

The ocean is traversed, not merely selected from a menu.

## San Cristóbal regions
1. Bahía del Desembarco
2. Tierras Secas
3. Costa de las Iguanas
4. Tierras Altas
5. El Junco
6. Cavernas de Lava
7. Tijeretas
8. Zona Volcánica
9. Punta Pitt
10. Blackwood Camp

Sea expedition locations:
- León Dormido
- Isla Lobos
- Isla Perdida (fictional)

Punta Pitt is northeast San Cristóbal, not an offshore island.

## Masters
Five Masters:
1. Costa
2. Alturas
3. Volcánico
4. Viento
5. San Cristóbal

Each grants a Sello.  
Then: **Prueba de San Cristóbal**.

Do not call this a Liga.

## Combat
- turn-based
- max team = 6
- defeated = Agotada/Agotado
- six active moves
- learned repertoire retained
- Energy system prevents spam

Stats:
- Vitalidad / PS
- Ataque
- Defensa
- Potencia
- Resistencia
- Velocidad
- Precisión
- Energía

Move categories:
- Físico
- Especial
- Soporte
- Control
- Reacción

Terrain states:
- Seco
- Húmedo
- Volcánico
- Vegetal
- Rocoso
- Acuático
- Profundo
- Ventoso

Isla Lobos introduces 2v2.

### RECUPERAR — universal battle action
A universal action guaranteeing the player always has a legal move.

- Exists **outside** the six active moves.
- Consumes the Tikawi's action for the turn.
- Restores Energy according to balance data.
- **Visibly animates** — the mandatory animation rule applies to it.
- Always available.
- Exact Energy values are balance data and are **not locked**.

### Reacción — category semantics
Reacción is a conditional action armed during the turn and triggered by declared reaction windows:
**BEFORE_IMPACT · AFTER_IMPACT · ON_STATUS**, plus future 2v2 contextual windows.

Maximum reaction chain depth: **1**. No recursive or unbounded reaction chains.

Content semantics are finalized in VS3.

### Team and reserve capacity
- Active team maximum remains **6**.
- **Volume I reserve capacity: 240 Tikawi.**
- Capacity is config/data-driven.
- The reserve interface must support appropriate **paging and filtering**.

## Compás
The Compás:
- is a brass 1835-style pocket compass with Galápagos engravings and an Ancestral component
- detects resonance
- may indicate approximate tendency/intensity
- records meaningful anomalies

It is **not**:
- GPS
- a capture device
- a storage device
- a precise distance meter
- a quest tracker

Never expose exact target distance.

## Bond / Vínculo
Canonical principle:
> **“Un Tikawi no pertenece a Darwin. Decide caminar con él.”**

Bond states:
- VÍNCULO IMPOSIBLE
- INESTABLE
- RESONANCIA
- POSIBLE
- ESTABLECIDO

Bond is contextual trust, not capture probability.

Tikawi may refuse.

Blackwood forced control is mechanically and narratively separate from Bond.

### FINALIZAR VÍNCULO
A player may voluntarily end a normal Bond, only from an approved safe physical context such as
Casa del Naturalista.

- **No sale. No money reward. Never treated as inventory disposal.**
- The individual leaves the active roster and reserve.
- **Codex and Research knowledge remain.**
- Narrative, special and ancestral individuals may prohibit the action.
- The exact ecological-return presentation is designed later.

This preserves the canonical principle: *un Tikawi no pertenece a Darwin, decide caminar con él* —
and a decision that can be made can also be unmade, by either side.

## Codex & Research
Canonical principles:
> **“El Codex no premia capturar más. Premia comprender más.”**

> **“Capturar una especie demuestra que la encontraste. Comprenderla demuestra que la conoces.”**

> **“No existe una última página del Codex.”**

Research stages:
1. Avistamiento
2. Observación
3. Interacción
4. Investigación
5. Vínculo

No photography in 1835.

Research Complete may later receive **NEW ADAPTATION DISCOVERED**.

## Field abilities
Approved:
- Fuerza
- Despeje / Corte
- Luz
- Escalada
- Planeo
- Nado
- Inmersión
- Inmersión Profunda
- Rastreo

Canonical principle:
> **“Los Tikawi no son llaves. Son compañeros que cambian la manera en que exploras.”**

Capabilities, not species IDs, should solve normal obstacles.

Field abilities are separate from the six combat moves.

## Object triad
- Compás = Vínculo
- Codex = Conocimiento
- Mapa = Descubrimiento

Support:
- Mochila = Preparación
- Farol = Profundidad
- Cuerda = Acceso
- Equipo = Progresión
- On The Hook = Expedición

## UI / UX locks
Main menu:
- Tikawi
- Codex
- Compás
- Mapa
- Mochila
- Cuaderno
- Darwin
- Guardar
- Opciones

No permanent minimap.

Legendarios use separate **Fenómenos Ancestrales** architecture.

Reserve changes only in safe physical contexts.

Fast travel only between discovered safe points.

## Opening flow
Title  
→ HMS Beagle  
→ first unknown marine sighting / Codex  
→ Bahía landing  
→ Isabela  
→ Compás  
→ first wild observation  
→ Tomás  
→ starter selection through bond  
→ friendly battle  
→ Codex update  
→ Casa del Naturalista  
→ early route choice  
→ open world

Tutorial principle:
> **“Primero deja que el jugador haga algo. Después explícale por qué funcionó.”**

## Economy & QoL
Currency: **Pesos**

Never sell Tikawi.

Core Casa del Naturalista services are free.

Localization architecture supports at least ES/EN from day one.

No hidden adaptive difficulty.

## Maritime canon
> **“The ocean is traversed, not selected from a menu.”**

> **“Fishing attracts and reveals marine life; it does not turn large Tikawi into inventory items.”**

> **“Diving extends exploration instead of launching a separate minigame.”**

Depth:
- SHALLOW
- MID
- DEEP
- ABYSSAL

No full survival loop for hull durability/hunger/fuel in Volume I initial scope.

## Galápagos Hook Adventure integration
The game may naturally promote Galápagos Hook Adventure through:
- On The Hook
- expedition culture
- fishing
- wildlife observation
- local maritime knowledge
- subtle hook symbolism

No modern ad inside 1835 fiction.

## Technical baseline
- Engine: Godot
- Language: GDScript
- Initial platform: Windows PC
- Offline-first
- Data-driven
- Modular
- Versioned saves
- Immutable IDs
- Few autoloads
- Region-based loading
- Hand-authored world
- Headless-testable battle logic

Principles:
> **“Content is data. Systems interpret data. Scenes present systems.”**

> **“Modules own behavior. Data owns content. UI owns presentation. Core owns infrastructure.”**

> **“Game logic must never depend on display names. It depends on immutable IDs.”**

> **“Invalid content must fail before the game runs.”**

### Pixel contract — visual canon

| Item | Value |
|---|---|
| Virtual resolution | **320 × 180** |
| Scaling | **Integer only**, viewport centred |
| Outside the viewport | Black or approved presentation background |
| Non-uniform stretching of gameplay pixels | **Never** |
| Filtering | Nearest |
| World tile | **16 × 16** |
| Overworld directions | 4 baseline; E/W mirroring permitted where visually appropriate |

Integer scaling behaviour: 1280×720 = ×4 · 1920×1080 = ×6 · 2560×1440 = ×8 · 3840×2160 = ×12.
At 1366×768, use the largest integer scale that fits — 1280×720 centred, with letterbox/pillarbox.

**Size classes** — production **maxima**, not a requirement that every sprite fill its canvas:

| Class | Overworld | Battle |
|---|---|---|
| S | 16 × 16 | 48 × 48 |
| M | 24 × 24 | 64 × 64 |
| L | 32 × 32 | 80 × 80 |
| XL | 48 × 48 | 96 × 96 |
| LEGENDARY | 64 × 64 + | up to 128 × 128 |

**These values are not to be changed speculatively.** VS3 proves them with a staged LEGENDARY 1v1
case and a staged M-class 2v2 case, with all mandatory action / impact / reaction beats readable.
Any future adjustment must be based on **playable visual evidence**.

## Vertical Slice
Main terrestrial Vertical Slice:
- Bahía del Desembarco
- part of Tierras Secas / Sendero del Cactus
- small rocky coast
- three starters
- representative wild Tikawi
- 1v1 combat
- real attack animations
- Energy
- Compás
- Bond
- companion
- at least one field ability
- Codex/Research
- one rumor
- one favor
- small economy
- time/weather/tide basics
- save/load
- ES/EN
- keyboard/controller

Full On The Hook navigation belongs to a later Marine Technical Slice.

Milestones:
- VS0 Foundation
- VS1 Movement & World
- VS2 Tikawi Runtime
- VS3 Battle
- VS4 Compass & Bond
- VS5 Codex & Research
- VS6 Quest & Dialogue
- VS7 Field & Environmental Systems
- VS8 Base & Economy
- VS9 Save & QoL
- VS10 Content Assembly
- VS11 Polish
- VS12 Architecture Review

### Vertical Slice scope boundary

**VS0–VS12 is the roadmap for the VERTICAL SLICE, not for full Volume I production.**

Within the Vertical Slice: Evolution appears in **VS2** as technical system proof · Options,
accessibility and rebinding in **VS9** · Audio integrates incrementally per milestone with a major
polish and quality gate in **VS11**.

**Do NOT add to VS0–VS12** merely because they are Volume I canon: full Masters, full Sellos and
Prueba de San Cristóbal progression, full Ancestral Phenomena, or full maritime navigation.

After VS12 and the scalability review, a separate **VOLUME I PRODUCTION ROADMAP** is created,
covering the Marine Technical Slice, Masters / Sellos / Prueba, Ancestral Phenomena, regional
expansion, content scale-out and full Volume I progression.

This boundary exists specifically to prevent Vertical Slice scope creep.

## Authority
Luisma is the final creative/product authority.

Claude = architecture/specification/review.  
Codex = implementation/testing/build.

Neither owns canon.

### Superseded pre-production document
`GALAPAGOS_THE_ORIGIN_GDD_v1.0.md` is archived as `docs/archive/GDD_v1.0_SUPERSEDED.md` —
**NOT IMPLEMENTATION AUTHORITY**. Master Canon wins completely. Design promoted from it into canon,
and design explicitly not promoted, are recorded in `docs/CANON_CONFLICT_RESOLUTION.md`.

## DO NOT CHANGE WITHOUT LUISMA APPROVAL
Protected:
- title
- Volume I location
- era
- Darwin age 20
- Tikawi terminology
- exactly 13 official types
- starter names/direction
- exactly 150 Volume I Codex structure
- #148 Volcápago
- #149 Martilord
- #150 Albatempest
- Compás non-GPS/non-capture/non-storage
- Legendarios separate from normal team/reserve
- team max 6
- visible combat animation requirement
- visible field-action requirement
- Codex rewards understanding
- Bond is voluntary/contextual
- field abilities separate from combat moves
- hand-authored world
- Godot/GDScript/Windows initial baseline
- Claude/Codex role separation

Final rule:
> **Architecture must adapt to the approved game. The approved game must not be simplified merely because implementation would be easier.**

---

## Canon change history — HISTORY, NOT AUTHORITY

This section records what changed between canon baselines. **It is not a second source of truth.**
The sections above are the current canon in full; nothing here needs to be reconciled against them.
Detailed rationale lives in the ADRs and in git history.

### v1.0 → v1.1 (2026-09-12, C-001)

| # | Change | Type | Merged into |
|---|---|---|---|
| 1 | Type effectiveness matrix | **RESTORED** (omitted from compact v1.0) | Official types |
| 2 | Lucha strong vs Ancestral / Ancestral weak vs Lucha | **ADDED** — completes the four-type cycle | Official types |
| 3 | Inverse-resistance rule, step lookup, dual-type clamp, no immunities | **ADDED** | Official types |
| 4 | Veneno ↔ Psíquico mutually super-effective, the only such pair | **CONFIRMED** | Official types |
| 5 | Planta baseline locked for VS3 evaluation | **CLARIFIED** | Official types |
| 6 | Individual personality trait/profile | **RESTORED** (omitted from compact v1.0) | Tikawi |
| 7 | RECUPERAR universal action | **ADDED** | Combat |
| 8 | Reacción windows and chain depth 1 | **CLARIFIED** | Combat |
| 9 | Reserve capacity 240, config-driven, paged and filterable | **ADDED** | Combat |
| 10 | FINALIZAR VÍNCULO | **ADDED** | Bond / Vínculo |
| 11 | Pixel contract: 320×180, tiles, size classes as production maxima | **ADDED** | Technical baseline |
| 12 | Animation accessibility FULL / FAST / MINIMAL | **ADDED** | Mandatory animation rule |
| 13 | Vertical Slice scope boundary | **CLARIFIED** | Vertical Slice |
| 14 | GDD v1.0 archived as superseded | **RESOLVED** | Authority |

**Unchanged from v1.0:** every item in *DO NOT CHANGE WITHOUT LUISMA APPROVAL* — title, Volume I
location, era, Darwin age 20, Tikawi terminology, exactly 13 types, starter names and direction, the
exactly-150 Codex structure, #148 Volcápago, #149 Martilord, #150 Albatempest, Compás
non-GPS/non-capture/non-storage, Legendarios separate from normal team and reserve, team max 6, the
visible combat-animation requirement, the visible field-action requirement, Codex rewards
understanding, Bond is voluntary and contextual, field abilities separate from combat moves,
hand-authored world, Godot/GDScript/Windows baseline, and Claude/Codex role separation.

> **Nothing in v1.1 simplifies the approved game. Every entry either restores something the compact
> v1.0 dropped, or records a decision the owner made during C-001.**
