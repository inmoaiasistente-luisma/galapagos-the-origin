# ENGINE — GALÁPAGOS: THE ORIGIN

    STATUS: PROPOSED
    AUTHORITY LEVEL: 6 (Codex implementation record; subordinate to accepted authority)
    DATE: 2026-09-14

---

## VS0-T02 — Godot baseline, renderer and pixel contract

### Toolchain

| Item | Verified value |
|---|---|
| Editor | Godot `4.7.2-stable` |
| Executable `--version` output | `4.7.2.stable.official.ed1daf0bf` |
| Build | Standard GDScript build; no .NET and no C# |
| Export templates | Godot `4.7.2.stable`, matching the editor |

The template version was read from `templates/version.txt` inside the export-template archive and
from the installed template directory `4.7.2.stable`.

### Sources

- Editor archive: <https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip>
- Export-template archive: <https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz>
- Official release: <https://github.com/godotengine/godot/releases/tag/4.7.2-stable>

All URLs identify the exact pinned release. No floating or `latest` URL is used.

### Integrity

SHA-256 values computed from the artifacts actually used on the owner machine:

| Artifact | SHA-256 |
|---|---|
| `Godot_v4.7.2-stable_win64.exe.zip` | `731980F9608D61333E5BAF54A2EF17210ACC7A538446C0CB9969F002ACA1E953` |
| `Godot_v4.7.2-stable_win64.exe` | `AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424` |
| `Godot_v4.7.2-stable_win64_console.exe` | `C8F0A6BC45A19B33541501E57F6F7CD972AB18453743266339D495CBBE846643` |
| `Godot_v4.7.2-stable_export_templates.tpz` | `F298490B8D44D934BE425A5A65A51BF15F422428B229A06A6E11D9FFEA248011` |

### Renderer

- Rendering method: Compatibility (`gl_compatibility`).
- Native Godot feature tag: `"4.7"`.
- Renderer feature: `"GL Compatibility"`.
- Project metadata: `PackedStringArray("4.7", "GL Compatibility")`.

### Project contract

| Contract item | Value |
|---|---|
| Logical viewport | `320 × 180` |
| Calibration window | `1280 × 720` |
| VS0 resize policy | Fixed; `resizable = false` |
| Stretch mode | `canvas_items` |
| Effective stretch aspect | `keep` |
| Scale mode | `integer` |
| Default texture filtering | Nearest; stored enum value `0` |
| Pixel transform snapping | `true` |
| Pixel vertex snapping | `true` |
| Outside-viewport background | `Color(0, 0, 0, 1)` |
| World tile reference | `16 × 16` |
| Player baseline reference | `16 × 24` |
| Player tall-pose reference | `16 × 32` |

The calibration scene displays 20 complete tile columns and 11 complete tile rows plus a 4-pixel
partial row, visibly demonstrating the vertical extent `180 / 16 = 11.25`.

### Renderer feature matrix

All checks used Godot `4.7.2.stable.official.ed1daf0bf` with the Compatibility renderer.

| Feature | Result | Evidence | Observed result |
|---|---|---|---|
| `CanvasModulate` day/night tint | PASS | `renderer_canvas_modulate.png` | The calibration field received the intended cool global tint. |
| `Light2D` + `LightOccluder2D` shadows | PASS | `renderer_light_occluder.png` | The point light illuminated the field and the occluder produced a sharp shadow region. |
| 2D normal-map behavior | PASS | `renderer_normal_map.png` | The generated normal texture produced a directional raised-surface light response. |
| Blend/backbuffer behavior | PASS | `renderer_backbuffer_blend.png` | A screen-texture backbuffer pass and additive impact ring composed over the underlying scene. |
| Screen-space post effect | PASS | `renderer_screen_space.png` | The full-screen screen-texture pass produced visible scanlines and vignette. |

The evidence images are local review artifacts and are not committed to the repository.

During the initial automated evidence capture, the scripts saved each PNG but did not call
`get_tree().quit(0)` on success; successful runs depended on external process termination. Some
windowed processes returned Windows code `0xC0000005` after a valid screenshot had been written.
The capture lifecycle was corrected so success explicitly calls `get_tree().quit(0)`, failure keeps
`get_tree().quit(1)`, and ordinary interactive runs do not auto-exit. All seven required captures
were then repeated. Exit codes were: `boot_1280x720.png = -1073741819 (0xC0000005)`,
`boot_1366x768.png = 0`, `renderer_canvas_modulate.png = -1073741819 (0xC0000005)`,
`renderer_light_occluder.png = 0`, `renderer_normal_map.png = 0`,
`renderer_backbuffer_blend.png = -1073741819 (0xC0000005)`, and
`renderer_screen_space.png = 0`. The symptom therefore remains unresolved after the clean-exit
correction. Causal layer not determined. Every PNG was written successfully and the required
rendering result is visible in its evidence image. The pinned console executable's required
headless boot remained clean with exit code `0`; the finding does not block the locked pixel
contract.

### Windowed calibration evidence

| Window | Result | Evidence | Measurement |
|---|---|---|---|
| `1280 × 720` | PASS | `boot_1280x720.png` | `320 × 180` at exactly ×4, full window, crisp pixel grid. |
| `1366 × 768` | PASS | `boot_1366x768.png` | `1280 × 720` content at ×4, centred with 43-pixel side bars and 24-pixel top/bottom bars; all bars are black. |

### Effective-value verification

The pinned runtime queried the effective `ProjectSettings` values directly. All T02 values matched.
In particular, `display/window/stretch/aspect` returned `keep` although that default-valued setting
is intentionally absent from `project.godot`. This was implementation verification, not a GUT run.

### Headless verification

Command:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit
```

Observed result: exit code `0`; no missing resource, script error, broken main scene, missing autoload,
or unauthorized engine was reported.

The GUT project-settings test is written and committed by T02, but it is not executed here. GUT is
introduced and the test is executed by VS0-T04. No CI verification is claimed; CI begins in VS0-T14.
