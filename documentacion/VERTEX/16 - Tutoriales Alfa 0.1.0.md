---
title: "Tutoriales - Release Alfa 0.1.0"
created: "2026-08-02"
updated: "2026-08-02"
tags:
  - tutorials
  - release
  - alpha
  - docs
---

# Tutoriales - Release Alfa 0.1.0

## Resumen

Tutoriales expandidos con contexto pedagógico para universitarios con conocimientos básicos en redes. El sistema de tutoriales cubre 6 niveles progresivos desde navegación básica hasta operaciones combinadas, con mejoras de UX completas.

## Slice Día 3.7 — Correcciones y Reducción de Textos (2026-08-02)

### Bug Corregido

#### Waypoint vacío causaba derrota al ganar
- **Causa raíz:** `_ganar()` no verificaba `waypoints.size() > 0` antes de comparar índices.
- **Solución:** Tutoriales con `waypoints: []` ahora permiten ganar correctamente.

### Reducción de Textos

Los pasos de los tutoriales fueron reducidos ~50% para mejorar legibilidad:

| Tutorial | Antes (promedio) | Después (promedio) |
|----------|-----------------|-------------------|
| tut1_movimiento | ~356 chars | ~260 chars |
| tut2_perimetro | ~397 chars | ~296 chars |
| tut3_avanzado | ~435 chars | ~305 chars |
| tut4_hacker | ~1017 chars | ~456 chars |
| tut4_defensa | ~891 chars | ~478 chars |
| tut5_defense | ~1131 chars | ~559 chars |
| tut6_combined | ~841 chars | ~533 chars |

La información detallada del mundo real (herramientas, protocolos, analogías extensas) permanece disponible en el GLOSARIO [G].

### Separación de Pantallas de Victoria

- Tutoriales ahora muestran "TUTORIAL COMPLETADO" en vez de "VICTORIA".
- Modo ataque muestra "VICTORIA" con estadísticas.
- Modo defensa muestra "VICTORIA DEFENSIVA" con su propio panel.

## Slice Día 3.8 v2 — Fix Tutorial UX (2026-08-02)

### Problemas Reportados

1. `tut_desc` no se mostraba para tutoriales 4, 5, 6 en el menú de mundos.
2. La ventana del tutorial tapaba la vista del tablero durante las acciones.
3. Las acciones (ej. escanear en modo hacker) no completaban el requerimiento.
4. Tab + Enter accidental llevaba al jugador por el camino incorrecto (perdía).
5. Faltaban guías visuales ("railes") de qué acción hacer.

### Nuevo Patrón: Explicación (ventana) vs. Acción (recordatorio)

**Flujo:** explicación → [Enter] → recordatorio pequeño → acción en el juego → [Enter] → siguiente explicación...

| Tipo de paso | Elemento | Posición | Contenido |
|--------------|----------|----------|-----------|
| Informativo (sin `action_required`) | Panel grande | Centro | Título, texto completo, objetivo, botón Siguiente |
| Acción (`action_required` no vacío) | Recordatorio compacto | Arriba (top) | "⚠ ACCIÓN: <nombre>", cómo hacerla, "[Enter] cuando completes la acción" |

- El recordatorio NO tapa el área de juego (barra superior compacta).
- La ventana de explicación NO se hace más pequeña: se reserva solo para pasos informativos.
- `[Enter]` CONFIRMA: en pasos de acción solo avanza si la acción ya se cumplió;
  si no, el evento pasa al juego (para que mover o resolver del defensor funcionen).
- Borde ámbar pulsante mientras se espera la acción → borde verde al cumplirla (Rail 4).

### Cambios por Archivo

- `core/locale/{es,en,pt}.json` — Añadidas `tut4_desc`–`tut7_desc` (faltaban → el selector mostraba la clave literal).
- `escenas/main_menu/tutorials_menu.gd` — tut7 ahora usa `loc("tut7_desc")`.
- `juego/tutorials/tutorial_player.gd` —
  - `notify_action()` ya NO auto-avanza: marca la acción cumplida y espera [Enter].
  - `can_perform_action(tipo)` — bloquea acciones distintas a la requerida.
  - `_draw_action_reminder()` — recordatorio superior para pasos de acción.
  - `_input` [Enter/Espacio]: avanza si la acción se cumplió; si no, no consume el evento.
  - Auto-advance por tiempo solo en pasos informativos.
- `juego/ataque/juego_ataque.gd` — Notificaciones al tutorial: escaneo
  (`_scan_selected_node`), exploits (`_use_hacker_exploit`), bloqueo de arista y
  firewall del defensor (solo cuando la acción se aplicó de verdad).
- `juego/ataque/input_handler.gd` — Bloqueo de acciones incorrectas durante el
  tutorial con mensaje "completa la acción indicada" (mover, escanear, exploits,
  clics de defensor).
- `juego/ataque/game_renderer.gd` — Railes visuales: highlight más grande y
  brillante con anillo pulsante (Rail 1) y flecha desde el jugador al objetivo
  en pasos de acción (Rail 3).
- `juego/tutorials/data/tut6_combined.json` — `try_attack` ahora es
  `action_required: "move"` (la acción es moverse a la Oficina) + hint añadido.
- `juego/tutorials/test_tutorial_system.gd` — Tests actualizados al nuevo flujo
  (16 tests: incluye `can_perform_action`).

### Verificación del Slice

- ✅ Tutorial system test: 16/16 passed
- ✅ Main test suite (run_all.gd): 7/7 passed
- ✅ Smoke test de escena (tut1 + tut4_hacker): sin errores de runtime
- ✅ 0 errores de script (importación en editor)
- ✅ 10 JSONs válidos

## Slice Día 3.6 — Correcciones de Bugs y QoL (2026-08-02)

### Bugs Corregidos

#### Bug 1: Tutorial se cerraba abruptamente al completar
- **Causa raíz:** Al alcanzar el target en un nivel tutorial, `_ganar()` mostraba la pantalla de victoria normal sin manejar el estado del tutorial activo.
- **Solución:** Se agregó el método `complete_tutorial()` a `tutorial_player.gd` que marca el último paso como alcanzado y muestra el mensaje de tutorial completado. `juego_ataque.gd` ahora llama a este método antes de `_ganar()` en niveles con tutorial activo. El mensaje de victoria muestra "TUTORIAL COMPLETADO" con instrucciones para volver al menú [Q].

#### Bug 2: Controles poco intuitivos
- **Causa raíz:** Los atajos de teclado estaban documentados en texto pequeño semi-transparente sin fondo visible.
- **Solución:** Nueva barra de controles siempre visible con fondo oscuro semi-transparente en la parte inferior. Muestra contextualmente los atajos según el modo (esperando acción vs. navegación). Overlay de ayuda completa accesible con [H] que lista todos los controles con explicaciones.

#### Bug 3: Reinicio no mostraba el tutorial de nuevo
- **Causa raíz:** `reset_state()` no reiniciaba el `tutorial_player`, que quedaba en estado `is_active = false` después de completarse.
- **Solución:** `reset_state()` ahora recarga y reinicia el tutorial si `tutorial_path` está configurado, restaurando todos los pasos desde el principio.

### Mejoras de Contenido

#### tut4_hacker.json (7 pasos)
- Paso 3 (134→950 chars): Contexto nmap, Nikto, enum4linux; pasos prácticos detallados
- Paso 5 (187→1296 chars): Sistema de ruido con 4 niveles de alerta, costos, analogía con logs
- Paso 6 (120→899 chars): Lateral movement, analogía del edificio, plan de ruta

#### tut4_defensa.json (6 pasos)
- Paso 4 (165→1098 chars): Dijkstra explicado (historia 1956, GPS, OSPF, reacciones del atacante)
- Paso 5 (190→1091 chars): 3 estrategias defensivas reales con pros/contras cada una

#### tut5_defense.json (7 pasos)
- Todos los pasos expandidos a 870-1324 chars cada uno
- Paso 1-7: Contexto real de firewalls, min-cut, timing, SOC, herramientas profesionales (Splunk, Palo Alto, CrowdStrike, Wireshark)

### QoL Implementadas

- **Barra de progreso visual:** Barra de progreso + porcentaje numérico debajo de los indicadores de paso
- **Overlay de ayuda [H]:** Muestra todos los controles del tutorial con explicaciones detalladas
- **Tecla [H] contextual:** Pista durante acciones, ayuda de controles durante navegación
- **Tooltips mejorados:** Agregado tooltip para Glosario [G], tooltips contextuales corregidos

## Tutoriales Disponibles

### 1. Navegación y Conceptos Básicos (tut1_movimiento)
- **Duración:** ~5 minutos
- **Conceptos:** Grafos, aristas, costos, Dijkstra
- **Contexto real:** OSPF, BGP, nmap, traceroute
- **8 pasos** con analogías del mundo real
- **Tiempos auto-advance:** 8s (textos de cierre)
- **Objetivo:** Aprender navegación básica en grafos y los conceptos de redes reales.

### 2. Perímetro e IA Adaptativa (tut2_perimetro)
- **Duración:** ~6 minutos
- **Conceptos:** Firewalls, IPS, route redundancy
- **Contexto real:** Cisco ASA, Snort, Suricata, HSRP
- **7 pasos** con herramientas de seguridad
- **Objetivo:** Entender cómo la IA adaptativa bloquea rutas y cómo encontrar caminos alternativos.

### 3. Avanzado: Waypoints, Detección, Perseguidores (tut3_avanzado)
- **Duración:** ~8 minutos
- **Conceptos:** Defensa en profundidad, IDS, SIEM
- **Contexto real:** Splunk, ELK, QRadar, CSIRT
- **9 pasos** con modelo de castillo medieval
- **Tiempos auto-advance:** 12s (resumen final extenso)
- **Objetivo:** Dominar waypoints, detección probabilística y perseguidores con defensa en profundidad.

### 4. Modo Hacker (tut4_hacker)
- **Duración:** ~8 minutos
- **Conceptos:** Cyber Kill Chain, exploits, ruido
- **Contexto real:** Metasploit, privilege escalation, pentesting ético
- **7 pasos** con nota ética sobre uso legal
- **Descripciones expandidas:** Escaneo [X] ahora incluye analogía con nmap, Nessus
- **Objetivo:** Aprender las fases de la Cyber Kill Chain y usar herramientas de infiltración.

### 5. Introducción a Defensa (tut4_defensa)
- **Duración:** ~7 minutos
- **Conceptos:** Firewall, bloqueo de aristas, min-cut
- **Contexto real:** SOC, SIEM, IDS/IPS, EDR
- **6 pasos** con estrategias defensivas
- **Descripciones expandidas:** Introducción al SOC, estrategia de bloqueo ampliada
- **Tiempos auto-advance:** 8s (condiciones de victoria)
- **Objetivo:** Aprender a bloquear aristas para detener al atacante en modo defensor.

### 6. Estrategias Avanzadas de Defensa (tut5_defense)
- **Duración:** ~6 minutos
- **Conceptos:** Min-cut, firewall de nodo, timing
- **7 pasos** con estrategias de defensa
- **Tiempos auto-advance:** 10s (condiciones de victoria)
- **Objetivo:** Dominar firewall de nodo, corte mínimo, timing de bloqueos y gestión de recursos.

### 7. Nivel Experto (tut6_combined)
- **Duración:** ~7 minutos
- **Conceptos:** Operaciones combinadas, lateral movement, privilege escalation
- **Contexto real:** Pentesting profesional, OPSEC, crown jewels
- **4 pasos** con síntesis de conceptos y analogías del mundo real
- **Descripciones expandidas:** Los 4 pasos duplicaron contenido pedagógico
- **Objetivo:** Síntesis de todas las mecánicas: waypoints, IA, presupuesto y perseguidores combinados.

## Mejoras de UX (Día 3)

- **Indicador de progreso mejorado** — Muestra el título del paso actual y el objetivo general del tutorial bajo el indicador de puntos
- **Navegación mejorada** — Botón atrás (←), índice de pasos ([I]), skip ([ESC])
- **Hints contextuales** — Ayuda en pasos difíciles con auto-reveal a los 10 segundos o 3 intentos fallidos ([H] manual)
- **Localización completa** — Todos los textos de UI en 3 idiomas (es, en, pt)

## Mejoras de UX (Día 3.5 - Pulido Final)

- **Tiempos de auto-advance ajustados** — Basados en longitud del texto (6-12s según complejidad)
- **Descripciones expandidas** — tut4_defensa (SOC, estrategia de bloqueo), tut4_hacker (nmap, Nessus), tut6_combined (4 pasos con pentesting y OPSEC)
- **Glosario de términos** — 12 términos técnicos con [G], definiciones, ejemplos del juego y referencias reales
- **Tooltips contextuales** — Tooltips al pasar el mouse sobre botones (retardo 0.5s)
- **Índice de pasos** — Overlay con lista de pasos y actual resaltado [I]

## Controles de Navegación

| Tecla | Acción |
|-------|--------|
| ← / Backspace | Volver al paso anterior |
| Enter / Espacio | Avanzar al siguiente paso (en pasos de acción: confirmar acción completada) |
| ESC | Saltar tutorial |
| I | Mostrar / ocultar índice de pasos |
| H | Mostrar pista (en pasos con acción requerida) |
| G | Mostrar / ocultar glosario de términos |

## Glosario de Términos (12 conceptos)

El glosario es accesible en cualquier momento con la tecla [G]. Incluye:

| Término | Definición resumida |
|---------|---------------------|
| Grafo | Estructura matemática de nodos conectados por aristas |
| Dijkstra | Algoritmo de ruta más corta (base de OSPF) |
| Firewall | Sistema que controla tráfico según reglas |
| Min-Cut | Conjunto mínimo de aristas que desconectan dos nodos |
| Waypoint | Punto intermedio obligatorio en una ruta |
| Detección | Identificación de actividad sospechosa (IDS/IPS) |
| Perseguidor | Entidad que rastrea tras detección (CSIRT) |
| Exploit | Técnica para aprovechar vulnerabilidades |
| Ruido | Actividad sospechosa medible (logs/alertas) |
| Kill Chain | Fases secuenciales de un ataque (Lockheed Martin) |
| IDS | Sistema de Detección de Intrusiones |
| SIEM | Gestión centralizada de eventos de seguridad |

## Estadísticas

- **Total de pasos:** 42 (8+7+9+7+6+7+4)
- **Palabras de contenido pedagógico:** ~3,200 (incremento de ~55%)
- **Tutoriales con contexto real:** 7 (todos)
- **Idiomas soportados:** 3 (es, en, pt)
- **Pasos con hints contextuales:** 4 (tut1 try_move, tut2 try_move, tut3 try_it, tut4 try_scan + try_move)
- **Términos del glosario:** 12

## Notas para Testing

- Cada tutorial debe jugarse de principio a fin
- Verificar que los tiempos de auto-advance son adecuados para leer
- Verificar que los hints aparecen cuando es necesario (10s de inactividad o 3 intentos fallidos)
- Verificar que el hint manual funciona con tecla [H]
- Verificar que la navegación atrás/adelante funciona correctamente
- Verificar que el indicador de progreso muestra título del paso
- Verificar que el índice de pasos muestra todos los pasos [I]
- Verificar que el glosario se abre/cierra con [G] y muestra 12 términos
- Verificar que los tooltips aparecen al mantener el mouse sobre botones

## Verificación del Release

- ✅ Tutorial system test: 16/16 passed
- ✅ Main test suite (run_all.gd): 7/7 passed
- ✅ Zero script errors on startup
- ✅ All JSONs valid (8 archivos: 7 tutoriales + glosario)
- ✅ No TODOs/FIXMEs in tutorials
- ✅ Working tree clean
- ✅ Glosario funcional con 12 términos [G]
- ✅ Tooltips contextuales en botones
- ✅ Tiempos de auto-advance basados en longitud del texto
- ✅ Barra de progreso visual con porcentaje
- ✅ Overlay de ayuda de controles [H]
- ✅ Controles siempre visibles con barra inferior
- ✅ Reinicio de tutorial al resetear nivel
- ✅ Tutorial se completa correctamente al alcanzar el objetivo
- ✅ Todas las descripciones expandidas (>300 chars por paso en tut4-6)

## Pendiente para Post-Alfa

- Rutas de aprendizaje adaptativas
- Sistema de verificación de comprensión (mini-quizzes)
- Localización de textos de contenido pedagógico (actualmente solo UI está localizada)
- Internacionalización completa del glosario
