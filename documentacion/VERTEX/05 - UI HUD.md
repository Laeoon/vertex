---
title: "UI y HUD"
created: "2026-06-26"
updated: "2026-08-03"
tags:
  - ui
  - hud
  - design
---

# UI y HUD

## Estructura del HUD (3 zonas)

### ZONA 1 — Barra superior (y=0..52)
- Titulo del nivel (izquierda)
- Turno, Puntos de movimiento, Meta (centro)
- Indicador de amenaza / perseguidores (derecha)

### ZONA 1b — Analisis de corte minimo (y=56..78)
- Solo en modo defensor
- Muestra aristas sugeridas por StrategicAnalyzer
- Color dorado

### ZONA 1c — Bloqueos activos (y=80..98)
- Solo en modo defensor
- Lista de bloqueos con duracion restante
- Color: verde (mayor o igual a 4), amarillo (2-3), rojo (menor o igual a 1)

### ZONA 2 — Tablero del grafo
- Nodos con colores por estado
- Aristas con labels de protocolo
- Hints opcionales con P

### ZONA 3 — Barra inferior (y=688..720)
- Keybinds (izquierda)
- Estado del juego (derecha)

## Escalado y resolucion

El juego se disena a resolucion base 1280x720 y usa stretch mode canvas_items con aspecto expand. En monitores grandes la UI y el tablero escalan para llenar la pantalla. El juego se abre en pantalla completa exclusiva.

## Paleta de colores

| Elemento | Color | Uso |
|----------|-------|-----|
| Jugador | Cyan Color(0.0, 0.7, 1.0) | Nodo activo |
| Target | Rojo Color(1.0, 0.15, 0.15) | Objetivo |
| Vecino | Verde Color(0.1, 0.85, 0.2) | Accesible |
| Seleccion | Magenta Color(1.0, 0.4, 0.8) | Pulsante |
| Ruta enemigo | Naranja pulsante | Modo defensor |
| Corte minimo | Dorado | StrategicAnalyzer |
| Bloqueado | Rojo Color(1.0, 0.15, 0.15) | Arista bloqueada |

## Panel de info del nodo

- Posicion: derecha (x = vp_size.x - 212)
- Muestra: nombre, costo, deteccion, firewall, spawn
- Solo aparece cuando se selecciona un nodo

## Hacker HUD

- Panel derecho (160px ancho, y=188)
- Barra de ruido con color dinamico
- Inventario de exploits con iconos
- Hint de scan

## UI de Tutoriales

El sistema de tutoriales (TutorialPlayer) superpone una capa sobre el HUD con estos elementos:

- Panel central de explicacion: ventana grande para conceptos e instrucciones
- Recordatorio de accion superior: alerta compacta "ACCION: <nombre>" que pide confirmar con [Enter]
- Barra de progreso con titulo del paso y objetivo
- Navegacion: anterior, siguiente, indice, salto
- Hints contextuales: se muestran tras 10s o 3 intentos fallidos
- Glosario [G]: panel con terminos de ciberseguridad y teoria de grafos
- Tooltips sobre botones con retraso de 0.5s
- Raíles visuales que resaltan nodos y aristas relevantes del paso actual

Ver: [[16 - Tutoriales Alfa 0.1.0]]

## Enlaces

- [[03 - Arquitectura]]
- [[04 - Mecanicas]]
- [[07 - Heist]]
- [[08 - Hacker]]
- [[09 - Defensa]]
