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

## Tutoriales Disponibles

### 1. Navegación y Conceptos Básicos (tut1_movimiento)
- **Duración:** ~5 minutos
- **Conceptos:** Grafos, aristas, costos, Dijkstra
- **Contexto real:** OSPF, BGP, nmap, traceroute
- **8 pasos** con analogías del mundo real
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
- **Objetivo:** Dominar waypoints, detección probabilística y perseguidores con defensa en profundidad.

### 4. Modo Hacker (tut4_hacker)
- **Duración:** ~7 minutos
- **Conceptos:** Cyber Kill Chain, exploits, ruido
- **Contexto real:** Metasploit, privilege escalation, pentesting ético
- **7 pasos** con nota ética sobre uso legal
- **Objetivo:** Aprender las fases de la Cyber Kill Chain y usar herramientas de infiltración.

### 5. Estrategias Avanzadas de Defensa (tut5_defense)
- **Duración:** ~6 minutos
- **Conceptos:** Min-cut, firewall de nodo, timing
- **7 pasos** con estrategias de defensa
- **Objetivo:** Dominar firewall de nodo, corte mínimo, timing de bloqueos y gestión de recursos.

### 6. Nivel Experto (tut6_combined)
- **Duración:** ~5 minutos
- **Conceptos:** Operaciones combinadas
- **4 pasos** con síntesis de conceptos
- **Objetivo:** Síntesis de todas las mecánicas: waypoints, IA, presupuesto y perseguidores combinados.

## Mejoras de UX (Día 3)

- **Indicador de progreso mejorado** — Muestra el título del paso actual y el objetivo general del tutorial bajo el indicador de puntos
- **Navegación mejorada** — Botón atrás (←), índice de pasos ([I]), skip ([ESC])
- **Hints contextuales** — Ayuda en pasos difíciles con auto-reveal a los 10 segundos o 3 intentos fallidos ([H] manual)
- **Localización completa** — Todos los textos de UI en 3 idiomas (es, en, pt)

## Controles de Navegación

| Tecla | Acción |
|-------|--------|
| ← / Backspace | Volver al paso anterior |
| Enter / Espacio | Avanzar al siguiente paso |
| ESC | Saltar tutorial |
| I | Mostrar / ocultar índice de pasos |
| H | Mostrar pista (en pasos con acción requerida) |

## Estadísticas

- **Total de pasos:** 42 (8+7+9+7+7+4)
- **Palabras de contenido pedagógico:** ~2,071
- **Tutoriales con contexto real:** 4 (tut1-4)
- **Idiomas soportados:** 3 (es, en, pt)
- **Pasos con hints contextuales:** 4 (tut1 try_move, tut2 try_move, tut3 try_it, tut4 try_scan + try_move)

## Notas para Testing

- Cada tutorial debe jugarse de principio a fin
- Verificar que los hints aparecen cuando es necesario (10s de inactividad o 3 intentos fallidos)
- Verificar que el hint manual funciona con tecla [H]
- Verificar que la navegación atrás/adelante funciona correctamente
- Verificar que el indicador de progreso muestra título del paso
- Verificar que el índice de pasos muestra todos los pasos

## Verificación del Release

- ✅ Tutorial system test: 15/15 passed
- ✅ Main test suite (run_all.gd): 7/7 passed
- ✅ Zero script errors on startup
- ✅ All JSONs valid
- ✅ No TODOs/FIXMEs in tutorials
- ✅ Working tree clean

## Pendiente para Post-Alfa

- Agregar glosario de términos
- Tooltips contextuales durante el juego
- Pantalla de referencia rápida [H] (complementar al hint actual)
- Rutas de aprendizaje adaptativas
- Sistema de verificación de comprensión (mini-quizzes)
- Localización de textos de contenido pedagógico (actualmente solo UI está localizada)
