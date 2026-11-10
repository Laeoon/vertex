# VERTEX Design System Tokens

Extracted from `juego/ui/brand.gd` (canonical visual identity tokens for VERTEX).

## Colors

| Token | Value | Usage | Source |
| --- | --- | --- | --- |
| `BG` | `#0d0e16` | Deep blue-violet base background | `juego/ui/brand.gd` |
| `PANEL` | `rgba(22, 24, 38, 0.88)` (`#161826`) | Semi-transparent tactical HUD panel | `juego/ui/brand.gd` |
| `PANEL_SOLID` | `rgba(16, 18, 31, 0.95)` (`#10121f`) | Solid dark surface for primary bars and cards | `juego/ui/brand.gd` |
| `PANEL_BORDER` | `#2a2e4a` | Structural hairline border | `juego/ui/brand.gd` |
| `ACCENT` | `#00e5ff` | Electric cyan — player, route, primary selection | `juego/ui/brand.gd` |
| `ENEMY` | `#ff2e88` | Hostile magenta — adversary/pursuer | `juego/ui/brand.gd` |
| `SUCCESS` | `#39ff88` | Terminal green — victory, safe state, Hacker mode | `juego/ui/brand.gd` |
| `WARNING` | `#ffc857` | Tactical amber — quarantine, alert, warning | `juego/ui/brand.gd` |
| `DANGER` | `#ff4757` | Crimson red — target core, breach danger | `juego/ui/brand.gd` |
| `TEXT` | `#eaecf5` | Primary crisp off-white text | `juego/ui/brand.gd` |
| `TEXT_DIM` | `#8a90b8` | Secondary muted metadata/label text | `juego/ui/brand.gd` |
| `WORLD_HEIST` | `#bf5af2` | Synthwave purple — Heist mode accent (VEX) | `juego/ui/brand.gd` |
| `WORLD_HACKER` | `#39ff88` | Terminal green — Hacker mode accent (N0X) | `juego/ui/brand.gd` |
| `WORLD_CYBER` | `#00d2ff` | Cyber cyan — Cybersecurity mode accent (AEGIS) | `juego/ui/brand.gd` |
| `WORLD_SECRET` | `#ff2a6d` | Glitch crimson — Sector 0 accent (ARCHITECT-0) | `juego/ui/brand.gd` |
| `BG_HEIST` | `#120918` | Deep synthwave purple-black canvas | `juego/ui/brand.gd` |
| `BG_HACKER` | `#09120e` | Deep terminal green-black canvas | `juego/ui/brand.gd` |
| `BG_CYBER` | `#081018` | Deep SOC night-blue canvas | `juego/ui/brand.gd` |
| `BG_SECRET` | `#14080e` | Deep kernel void crimson-black canvas | `juego/ui/brand.gd` |

## Typography

| Token | Value | Usage | Source |
| --- | --- | --- | --- |
| `FONT_MONO` | `'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace` | All HUD readouts, node labels, telemetry, and tactical buttons | `juego/ui/brand.gd` |
| `FONT_SIZE_SM` | `12px` | Keycaps, secondary telemetry, edge protocol tags | `juego/ui/brand.gd` |
| `FONT_SIZE_BASE` | `14px` | Primary HUD labels, node titles, dock actions | `juego/ui/brand.gd` |
| `FONT_SIZE_LG` | `18px` | Mode headers, primary counters | `juego/ui/brand.gd` |

## Spacing & Touch Targets

| Token | Value | Usage | Source |
| --- | --- | --- | --- |
| `TOP_BAR_H` | `48px` | Single unified top telemetry bar (no overlapping rows) | `juego/ataque/game_renderer.gd` |
| `BOTTOM_DOCK_H` | `56px` | Single unified bottom tactical dock (zero duplicate panels) | `juego/ataque/game_renderer.gd` |
| `TOUCH_TARGET_MIN` | `42px` | Minimum interactive button height for touch/mouse comfort | `juego/ataque/input_handler.gd` |
| `PILL_GAP` | `10px` | Minimum horizontal separation between interactive pills (prevents overlap) | `juego/ataque/game_renderer.gd` |

## Component Rules (HUD Anti-Overlap & Anti-Duplication Contract)

1. **Zero Duplication Rule**:
   - Every tool, exploit, or status message appears in **exactly ONE place** on screen.
   - In **Hacker Mode**, the old right-side text list (`HACKER / RUIDO / [1] Bypass...`) is **eliminated**; the Noise (`RUIDO`) meter integrates cleanly into the Top Telemetry Bar or Dock header, and the `[X] SCAN` + `[1..4]` exploits live exclusively in the Bottom Tactical Dock.
   - In **Defender (Blue Team) Mode**, the `[1] SEGMENTAR`, `[2] FIREWALL`, `[3] CUARENTENA`, `[4] RADAR` tools live in **one single dock** (never repeated as both top pills and bottom text hints).
   - The mission objective (`META: Lobby`) appears **once** in the Top Bar — never duplicated in a second `Ve hacia Lobby` box next to the camera controls.
2. **Zero Overlap Rule**:
   - All HUD bars use dynamic flex/flow spacing (`gap >= 10px`) measured from actual text width (`font.get_string_size(...) + padding`), never fixed colliding X offsets like `155 + i * 130` that cause `[1] SEGMENTAR ARISTA` to collide with `[2] FIREWALL`.
   - In-canvas node hover badges (`Δ COSTE: 1.0`) anchor with collision-avoidance offset so they never cover adjacent node titles (`Lobby`).
