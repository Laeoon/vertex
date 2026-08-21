---
title: "Level Design"
created: "2026-06-26"
tags:
  - level-design
  - graphs
---

# Level Design

## Principios de diseño

1. **Los nodos son puntos de decisión** — no decoración
2. **Las conexiones son rutas posibles** — con sentido lógico
3. **Los bloqueos deben ser justificables** — la IA reacciona
4. **Las rutas alternativas deben tener sentido** — no caminos muertos
5. **Las soluciones emerjen de la estructura** — no del caos visual

## Grafo Heist N1

**Archivo:** `juego/nivel1/nivel1_red.tres`

```
Inicio → Puerta(1) → Seguridad(2) → CPD(2) → Sala(2) → Boveda(1)
Inicio → RPA(1)    ↗              → Cajas(3) ↗
```

| Nodo | Entradas | Salidas | Waypoint |
|------|----------|---------|----------|
| Inicio | 0 | 2 | No |
| Puerta | 1 | 1 | No |
| RPA | 1 | 1 | No |
| Seguridad | 2 | 2 | Sí (WP1) |
| CPD | 1 | 1 | No |
| Cajas | 1 | 2 | Sí (WP2) |
| Sala | 2 | 1 | No |
| Boveda | 2 | 0 | Target |

**Budget:** 12 puntos | **Óptimo:** ~9 pts | **Margen:** ~33%

## Balance Heist: par y metas (slice 5)

Medido con el harness de self-play (`tests/balance/_balance_harness.tscn`,
100 corridas/política, semillas fijas). Políticas: greedy (jugador guiado),
greedy_err (un error en la primera elección real), random (perdido).
Criterio aprobado: **curva accesible** — N1 al 1er intento, N2 al 2º, N3 en 2-3.

| Nivel | par_turnos | par_coste | greedy | greedy_err | random | Estrellas (en par / con 1 error) |
|-------|-----------|-----------|--------|-----------|--------|----------------------------------|
| heist_n1 | 6 | 9.0 | 100% (5t/9c) | 100% | 50% | 3★ / 3★ |
| heist_n2 | 7 | 11.0 | 100% (6t/11c) | 100% (14c → 2★) | 8% | 3★ / 2★ |
| heist_n3 | 8 | 19.0 | 91% (9 capturas) | 0% (error = pérdida) | 1% | 3★ / — |

Reglas de par (estilo golf): en par = 3★; coste ≤1.5×par Y turnos ≤1.25×par = 2★ (el código toma mini(cost_stars, turn_stars); aclarado por auditoría 2026-08-21); más allá 1★. El presupuesto es sólo supervivencia, ya no define estrellas.

Notas de diseño N2/N3 (slice 5):
- N2 ganó aristas de retorno `Almacen→Perimetro` y `CCTV→Lobby`: los lados del grafo eran trampas unidireccionales (un error = muerte sin recuperación).
- N3: la detección (0.10-0.12 en Monitoreo/DataCenter/Servidores/CriptoVault) con perseguidores rápidos (speed 2, delay 1) aporta la varianza; sus trampas topológicas (Direccion/Cafeteria) SON la dificultad — exigen intentos limpios.
- Al evaluar grafos nuevos: cada arista agregada cambia la agresividad de la IA bloqueadora (`would_isolate` ve más rutas) — probar con el harness, no a ojo.

## Grafo Hacker N1

**Archivo:** `juego/hacker/hacker_n1.tres`

```
DMZ → WebServer(1) → AppServer(2) → DBServer(3) → AdminPanel(3) → Core(2)
DMZ → MailServer(2) → FileServer(3) ↗                    ↗
                   → Printer(1) → HRPC(2) → VPNGateway(2) ↗
```

**Core solo accesible desde AdminPanel** (waypoints forzados)

## Grafo Cyber N1

**Archivo:** `juego/cyber/cyber_n1.tres`

```
Internet → FirewallPer → DMZ → InternalFW → ServInterno → Database
Internet → Proxy → MailServer → InternalFW ↗
Internet → IDS → Monitor → Database
```

**Modo defensor:** El jugador protege Database del atacante que viene de Internet.

## Grafo Defense N1 (Defensa Perimetral)

**Archivo:** `juego/defense/defense_n1.tres`

```
(Ver defense_n1.tres para el grafo completo)
```

**Modo defensor:** El jugador protege DataCenter del atacante que viene de Internet.

## Reglas de validación

Antes de implementar un nivel, verificar:
1. Cada nodo tiene ≥1 entrada y ≥1 salida (excepto inicio/target)
2. No hay dead ends
3. El presupuesto/ruido/turnos son alcanzables
4. Los waypoints son accesibles desde la ruta óptima
5. La IA tiene al menos 2 rutas alternativas

Ver: [[04 - Mecánicas]]

## Enlaces

- [[07 - Heist]]
- [[08 - Hacker]]
- [[09 - Defensa]]
