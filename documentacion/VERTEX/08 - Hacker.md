---
title: "Mundo Hacker"
created: "2026-06-26"
tags:
  - hacker
  - mechanics
  - noise
  - exploits
---

# Mundo Hacker — Movimiento Lateral

## Concepto

El jugador se infiltra en una red corporativa usando herramientas abstractas de hacking. Cada acción genera ruido. Si el ruido es demasiado alto, aparecen perseguidores.

## Mecánica central

- **Ruido** como recurso limitado (+5/movimiento, -3/turno)
- **Exploits** como herramientas especiales (bypass, escalate, persist)
- **Scans** para revelar información de nodos
- **Waypoints forzados** (Core solo accesible desde AdminPanel)

## Sistema de ruido

| Nivel | Ruido | Efecto |
|-------|-------|--------|
| Seguro | 0-30 | Sin consecuencias |
| Baja | 30-60 | IA +20% agresiva |
| Alta | 60-85 | Posibilidad de perseguidor |
| Crítica | 85+ | Perseguidor garantizado, IA ×2 |

## Exploits

| Tipo | Costo ruido | Efecto | Icono |
|------|-------------|--------|-------|
| Bypass | +15 | Salta protección de nodo | ⚡ |
| Escalar | +25 | Accede a áreas restringidas | 🔓 |
| Persistir | +10 | Mantiene acceso 3 turnos | ♻ |

## Scans

- Costo: 0 ruido
- Revela: tipo de nodo (vulnerable/protegido/normal), hint de exploit, nivel de riesgo
- Nodos escaneados se marcan con ✓ en el grafo

## Nivel actual

| Nivel | Nodos | Turnos | Exploits iniciales |
|-------|-------|--------|-------------------|
| N1 — Lateral Movement | 11 | 18 | 2 bypass, 1 escalate, 1 persist |

## Grafo

```
DMZ → WebServer(1) → AppServer(2) → DBServer(3) → AdminPanel(3) → Core(2)
DMZ → MailServer(2) → FileServer(3) ↗                    ↗
                   → Printer(1) → HRPC(2) → VPNGateway(2) ↗
```

**Core solo accesible desde AdminPanel** (waypoints forzados)

## Tutoriales asociados

- [[04 - Mecánicas#Tutorial 4]]: Hacker (ruido, scans, exploits)

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `juego/hacker/hacker_n1.tres` | Grafo N1 |
| `juego/hacker/hacker_n1.json` | Config N1 |
| `juego/system/hacker_mechanics.gd` | Sistema de mecánicas |

## Enlaces

- [[04 - Mecánicas#Sistema de ruido]]
- [[06 - Level Design#Grafo Hacker N1]]
- [[05 - UI HUD#Hacker HUD]]
