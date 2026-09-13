# CLAUDE + CODEX WORKFLOW MASTER
**Project:** GALÁPAGOS: THE ORIGIN  
**Workflow Baseline:** v1.0  
**Human Owner:** Luisma  
**Architecture Agent:** Claude  
**Implementation Agent:** Codex

## Purpose
This document defines how Claude and Codex work together.

It prevents:
- duplicated authority
- silent redesign
- contradictory assumptions
- unnecessary rework
- large agent-driven refactors
- canon drift

## Organization
```text
                 LUISMA
     Creative Owner / Product Authority
                    │
                    ▼
                  CLAUDE
          Lead Architecture Agent
                    │
       Specs / ADR / Task Packets
                    │
                    ▼
                  CODEX
          Lead Implementation Agent
                    │
          Code / Tests / Build
                    │
                    ▼
              Validation / CI
                    │
                    ▼
                  CLAUDE
           Architecture Review
                    │
        PASS / CHANGES REQUIRED
                    │
                    ▼
                 LUISMA
          Playable / Visual Review
                    │
                    ▼
             MILESTONE LOCK
```

## Responsibility matrix

| Area | Luisma | Claude | Codex |
|---|---|---|---|
| Canon | **Decides** | Protects | Respects |
| Game Design | **Decides** | Formalizes | Implements |
| Architecture | Approves major changes | **Designs** | Follows |
| ADR | Approves/rejects | **Creates** | Requests |
| Specs | Reviews scope | **Creates** | Executes |
| Task decomposition | — | **Creates** | Consumes |
| Production code | Reviews outcome | Reviews | **Owns** |
| Tests | Defines critical intent | Specifies/reviews | **Implements/runs** |
| CI/CD | Approves direction | Designs | **Implements** |
| Debugging | Tests result | Handles architecture issues | **Primary** |
| Save migrations | Approves major behavior | Specifies | **Implements/tests** |
| Visual canon | **Approves** | Defines requirements | Integrates |
| Game feel | **Approves** | Advises | Adjusts |
| Build | Tests | Reviews | **Generates** |
| Commercial release | **Authorizes** | Reviews | Never publishes alone |

## Authority hierarchy
1. Luisma current decision
2. Master Canon
3. approved Game Design
4. accepted ADR
5. approved Technical Architecture
6. Claude spec
7. Codex implementation
8. current code
9. archived/old docs

Lower layers must yield to higher layers.

## Shared source-of-truth rule
> **Conversation memory is not the source of truth. Versioned repository documentation is.**

## Claude → Codex handoff
Task packet must include:
- TASK ID
- STATUS: READY
- OBJECTIVE
- WHY
- REQUIRED READING
- DEPENDENCIES
- ALLOWED PATHS
- FORBIDDEN PATHS
- PUBLIC CONTRACTS
- STATE OWNERSHIP
- DATA REQUIREMENTS
- PERSISTENCE IMPACT
- IMPLEMENTATION REQUIREMENTS
- TEST REQUIREMENTS
- ACCEPTANCE CRITERIA
- OUT OF SCOPE
- STOP CONDITIONS
- PARALLELIZATION
- DEPENDS_ON

Codex does not start DRAFT tasks.

## Task states
- DRAFT
- READY
- IN_PROGRESS
- BLOCKED
- REVIEW
- COMPLETE

Claude:
- DRAFT → READY

Codex:
- READY → IN_PROGRESS
- IN_PROGRESS → BLOCKED
- IN_PROGRESS → REVIEW

Final COMPLETE requires required reviews.

## Codex → Claude handoff
Codex returns:
- Task
- Branch
- Commit(s)
- Summary
- Files created/modified
- Tests added/executed
- Validator results
- Build result
- Runtime verification
- Canon impact
- Architecture impact
- Save impact
- Screenshots/evidence
- Known limitations
- Technical debt
- Architecture deviations

## Claude review
Claude returns:
- PASS
or
- CHANGES REQUIRED

Review:
- canon
- architecture
- spec
- persistence
- coupling
- scalability
- testing
- technical debt

## Human creative gate
Technical PASS is not creative PASS.

Luisma reviews:
- movement feel
- battle feel
- attack animation quality
- Compás feel
- Bond clarity
- UI
- pacing
- visual identity

## Change levels
### Level 0
Private implementation. Codex.

### Level 1
Module-local internal design. Codex + report.

### Level 2
Public contract / persistence / cross-module. Claude review.

### Level 3
Canon / game design. Luisma.

## Blocker routing
- IMPLEMENTATION BUG → Codex
- DATA BUG → Codex if mechanically unambiguous
- CONTENT BUG → escalate if meaning/canon changes
- ARCHITECTURE ISSUE → Claude / ADR
- CANON CONFLICT → Luisma
- ASSET MISSING → placeholder only if allowed
- DEPENDENCY REQUEST → Claude evaluates
- SAVE MIGRATION REQUIRED → Claude specifies, Codex implements

## ADR workflow
```text
Problem
↓
Claude analysis
↓
ADR proposal
↓
Luisma approves/rejects
↓
If accepted:
architecture updated
↓
Codex implements
```

## No silent redesign
Neither agent may silently:
- change canon
- alter architecture contracts
- simplify core mechanics
- remove valid tests
- introduce substitute systems

Implementation difficulty is not permission to change the game.

## No drive-by refactoring
A focused task stays focused.

Record unrelated debt separately.

## Shared architecture principles
> Content is data. Systems interpret data. Scenes present systems.

> Modules own behavior. Data owns content. UI owns presentation. Core owns infrastructure.

> Commands request change. Events report change. Queries ask without changing anything.

> State machines own transitions; UI only presents them.

> Systems communicate through contracts, not scene-tree shortcuts.

> Invalid content should fail before the game runs.

> Static generated definitions are immutable at runtime.

> Persist consequences, not irrelevant simulation.

> Use the simplest implementation that preserves boundaries.

> Implement only what the current approved milestone needs.

## Shared canon protections
Always protect:
- GALÁPAGOS: THE ORIGIN
- Volume I — San Cristóbal
- 1835
- Darwin age 20
- Tikawi terminology
- exactly 13 official types
- exact starter chains
- 150-entry Volume I structure
- #148 Volcápago
- #149 Martilord
- #150 Albatempest
- Compás non-GPS/non-capture/non-storage
- Bond voluntary/contextual
- max team 6
- field abilities separate from combat moves
- Legendarios separate from normal reserve/team
- visible battle animation requirement
- visible field-action requirement
- hand-authored world
- offline-first
- Godot/GDScript/Windows initial baseline
- Claude/Codex role separation

## Vertical Slice workflow
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

Per milestone:
```text
Luisma-approved direction
↓
Claude spec
↓
Claude task packets
↓
Codex implementation
↓
CI/tests/build
↓
Claude review
↓
Codex fixes if needed
↓
Luisma playable review
↓
Milestone lock
```

## Parallel agent rule
Multiple Codex agents may run in parallel only when Claude marks tasks PARALLEL_SAFE.

Use separate branch/worktree.

Avoid overlapping files and unfinished shared contracts.

## Testing rule
> **Never weaken a valid test merely to make a change pass.**

If implementation violates spec, fix implementation.

If spec changed, update authority first.

## Main branch rule
`main` should remain buildable.

## Save rule
Player progress has high priority.

No persisted field/ID change without migration analysis.

## Asset rule
Claude defines requirements.  
Codex integrates.  
Luisma approves visual canon.

No silent replacement of missing canonical art.

## Documentation rule
Prompts start work. Documentation governs work.

Archived documents are never current implementation authority.

## First project sequence
1. Load the four master documents
2. Claude executes C-001 Architecture Audit
3. Resolve Blocker/High findings
4. Claude creates C-002 VS0 Foundation Spec
5. Claude decomposes VS0
6. Codex starts X-001 Repository Bootstrap
7. Codex tests/builds/reports
8. Claude reviews
9. Luisma reviews
10. Move to VS1

## Do not do first
Do not begin by:
- generating all 150 production Tikawi
- implementing full San Cristóbal
- building full maritime navigation
- implementing Steam
- creating every quest
- creating every schema
- making every dev tool
- writing every move
- designing Volume II

Prove the foundation and Vertical Slice first.

## Completion standard
A task is not complete merely because code exists.

Completion requires:
- scope satisfied
- tests
- validation
- build/runtime verification where relevant
- no hidden blockers
- implementation report
- architecture review where required
- human creative review where relevant

Final workflow principle:
> **Claude defines the safe path. Codex builds the path. Luisma decides where the path goes.**
