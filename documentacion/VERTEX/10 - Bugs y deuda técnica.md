---
title: "Bugs y Deuda Técnica"
created: "2026-06-26"
updated: "2026-07-10"
tags:
  - bugs
  - technical-debt
  - issues
---

# Bugs y Deuda Técnica

## Bugs corregidos

| # | Bug | Severidad | Archivo | Fix | Estado |
|---|-----|-----------|---------|-----|--------|
| 1 | Falsa derrota al llegar con 0 puntos | 🔴 Crítico | juego_ataque.gd | `destino` en vez de `player_pos` | ✅ |
| 2 | Bloqueos de IA no expiraban sin IA | 🔴 Crítico | juego_ataque.gd | cleanup fuera de _turno_ia() | ✅ |
| 3 | Progresión de niveles rota | 🔴 Crítico | scene_params, level_manager | `level_key` unificado | ✅ |
| 4 | ai_bloquea_al_inicio muerto | 🔴 Alta | juego_ataque.gd | Lógica en reset_state() | ✅ |
| 5 | Ruido de escaneo inconsistente | 🟡 Media | hacker_mechanics.gd | NOISE_SCAN = 2 | ✅ |
| 7 | Solapamiento paneles HUD | 🟡 Media | game_renderer.gd | y=56 y y=200 | ✅ |
| 8 | Código muerto ia_defensora.gd | 🟢 Baja | ia_defensora.gd | @deprecated | ✅ |

## Deuda técnica pendiente

| # | Problema | Severidad | Impacto | Notas |
|---|----------|-----------|---------|-------|
| D2 | export_presets.cfg desactualizado | Baja | No se puede exportar | Godot 4.7, plantillas no instaladas |
| D3 | warnings de compilación (~10) | Baja | Ruido en logs | Señales no usadas, parámetros no usados |
| D4 | draw_rect width ignorado con filled=true | Baja | Warning cosmético | Godot 4.7 API warning |

## Bugs conocidos (no críticos)

| # | Bug | Severidad | Estado |
|---|-----|-----------|--------|
| B1 | get_screenshot en Ziva falla (modelo no disponible) | Baja | Limitación externa |
| B2 | execute_script sin acceso a scene_tree | Baja | Limitación de Ziva |

## Decisiones de diseño registradas

| Decisión | Razón | Fecha |
|----------|-------|-------|
| Línea amarilla eliminada | Confundía al jugador, no mostraba ruta óptima real | 2026-06-24 |
| Hints opcionales con P | Mejor UX: el jugador decide cuándo ver ayuda | 2026-06-24 |
| Core solo accesible desde AdminPanel | Forzar waypoints obligatorios en hacker | 2026-06-24 |
| Aislamiento = Victoria | Transformar bloqueos en decisiones tácticas reales | 2026-06-26 |
| Event Bus no conecta al UI | Datos directos al renderer es más simple y eficiente. Las señales se emiten para wrappers reactivos y testing, pero el UI no las necesita. Ver [[15 - Event Bus]] | 2026-07-10 |

## Enlaces

- [[01 - Estado actual]]
- [[03 - Arquitectura]]
