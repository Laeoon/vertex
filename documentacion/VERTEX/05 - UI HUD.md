---
title: "UI y HUD"
created: "2026-06-26"
tags:
  - ui
  - hud
  - design
---

# UI y HUD

## Estructura del HUD (3 zonas)

### ZONA 1 — Barra superior (y=0..52)
- Título del nivel (izquierda)
- Turno, Puntos de movimiento, Meta (centro)
- Indicador de amenaza / perseguidores (derecha)

### ZONA 1b — Análisis de corte mínimo (y=56..78)
- Solo en modo defensor
- Muestra aristas sugeridas por StrategicAnalyzer
- Color dorado

### ZONA 1c — Bloqueos activos (y=80..98)
- Solo en modo defensor
- Lista de bloqueos con duración restante
- Color: verde (≥4), amarillo (2-3), rojo (≤1)

### ZONA 2 — Tablero del grafo
- Nodos con colores por estado
- Aristas con labels de protocolo
- Hints opcionales con P

### ZONA 3 — Barra inferior (y=688..720)
- Keybinds (izquierda)
- Estado del juego (derecha)

## Paleta de colores

| Elemento | Color | Uso |
|----------|-------|-----|
| Jugador | Cyan `Color(0.0, 0.7, 1.0)` | Nodo activo |
| Target | Rojo `Color(1.0, 0.15, 0.15)` | Objetivo |
| Vecino | Verde `Color(0.1, 0.85, 0.2)` | Accesible |
| Selección | Magenta `Color(1.0, 0.4, 0.8)` | Pulsante |
| Ruta enemigo | Naranja pulsante | Modo defensor |
| Corte mínimo | Dorado | StrategicAnalyzer |
| Bloqueado | Rojo `Color(1.0, 0.15, 0.15)` | Arista bloqueada |

## Panel de info del nodo

- Posición: derecha (x = vp_size.x - 212)
- Muestra: nombre, costo, detección, firewall, spawn
- Solo aparece cuando se selecciona un nodo

## Hacker HUD

- Panel derecho (160px ancho, y=188)
- Barra de ruido con color dinámico
- Inventario de exploits con iconos
- Hint de scan

Ver: [[04 - Mecánicas]]

## Enlaces

- [[03 - Arquitectura]]
- [[07 - Heist]]
- [[08 - Hacker]]
- [[09 - Defensa]]
