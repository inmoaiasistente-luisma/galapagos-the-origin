# GALÁPAGOS: THE ORIGIN

`GALÁPAGOS: THE ORIGIN` is being built in Godot as an offline-first, pixel-perfect adventure.
The repository is currently in **VS0**, the infrastructure-only foundation milestone; gameplay and
production content are intentionally out of scope.

## Technical baseline

- Godot `4.7.2-stable`, Standard GDScript build (no .NET)
- Compatibility renderer
- Virtual resolution: `320×180`
- World tiles: `16×16`
- Integer pixel-perfect scaling with nearest filtering
- Initial platform: Windows PC

## Authoritative project documents

The accepted canon, architecture, conventions, ownership rules, ADRs, and VS0 specification live in
[`docs/`](docs/). When sources disagree, follow the authority order recorded in
[`ARCHITECTURE.md` §16](docs/ARCHITECTURE.md#16-document-authority). Canonical content will be authored
in `data/source/*.json`; generated resources are rebuildable outputs and are never edited by hand.

## Repository workflow

- Create branches as `feature/<task-id>-<slug>` or `fix/<task-id>-<slug>`.
- Never push directly to `main`; every change reaches it through a reviewed pull request.
- Keep each task within its packet's `ALLOWED PATHS` and use one worktree per writing agent.
- Complete the pull request template with executed verification and impact declarations.

Git LFS is required. After cloning, run `git lfs install`; the repository tracks PNG, OGG, WAV, and
Aseprite assets through LFS.
