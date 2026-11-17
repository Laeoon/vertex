# VERTEX (Godot 4.x / GDScript) Code Review Rules for GGA

1. **Strict Static Typing**: Enforce strict static typing in GDScript 4.x. Never assign `Object` or `Resource` instances (such as `NetworkNodeResource`) directly to untyped `Dictionary` keys or variables without safely casting or accessing `.metadata`.
2. **Zero-Hang Headless Testing**: All tests must run cleanly in headless mode. Use `call_deferred("_run_tests")`, bounded timeouts, and avoid blocking waits or waiting for physical input devices.
3. **Custom Rendering & UI Safety**: In custom `_draw()` renderers (`game_renderer.gd`, `level_select_screen.gd`, `profile_renderer.gd`, `database_renderer.gd`), draw full-screen backgrounds before applying camera transforms `draw_set_transform(pan, 0.0, Vector2(zoom, zoom))` and prevent HUD text/chip overlaps.
4. **Architecture & Localization**: Maintain clean architecture and formal neutral Spanish for canonical narrative strings alongside `es`/`en`/`pt` localization keys.
