---
title: "Backups y Referencias"
created: "2026-06-26"
tags:
  - backup
  - references
---

# Backups y Referencias

## Backup histórico

- **Estado:** Eliminado durante reestructuración del repo (commits 2589cb1 → 7aa523e)
- **Nota:** El snapshot del Hito 5 ya no está disponible como backup separado

## Repositorio de trabajo

- **Rama:** `main`
- **Último commit:** `7aa523e Archive old docs to documentacion/historicos (ignored) and import VERTEX docs from Obsidian Vault (source of truth)`
- **Remoto:** https://github.com/Laeoon/vertex.git

## Paper de referencia

**Shivakumar MD & Mamatha N (2022)**
"Applications of graph theory in cybersecurity: Network defense models"
World Journal of Advanced Research and Reviews, 14(02), 735–743
DOI: 10.30574/wjarr.2022.14.2.0467
PDF: `/home/leonardo/Documentos/Indormacion_mimo/WJARR-2022-0467.pdf`

### Mapping paper → implementación

| Sección del paper | Implementación en VERTEX |
|-------------------|--------------------------|
| §2 Network Topology Modeling | NetworkGraphResource + NetworkNodeResource + NetworkEdgeResource |
| §3 Attack Graph Generation | DefensivePathfinder (Dijkstra) |
| §3 Cut-Set Analysis | StrategicAnalyzer (Edmonds-Karp) |
| §4 Intrusion Detection | detection_chance + pursuers |
| §5 Vulnerability Assessment | Pesos duales (transit_cost + mitigation_capacity) |
| §6 Game-Theoretic Defense | Gameplay (jugador vs IA defensora) |
| §6 Moving Target Defense | IA bloquea/reconfigura aristas por turno |

## Documento de tesis

- **Ruta:** `/home/leonardo/Documentos/Indormacion_mimo/Informe Final 2 año Trimeste 1 Informática (1).docx`
- **Autores:** Leonardo Angulo + Juan Pablo Parilli
- **Tutor:** Ing. Miguel Mejias
- **Regla:** No tocar el .docx — solo contribuir en .md del proyecto

## Herramientas

| Herramienta | Uso | Tokens |
|-------------|-----|--------|
| MiMo Code | Análisis, arquitectura, documentación | Ilimitados |
| Ziva | Editor Godot, grafos, builds, visual | $3/mes |

## Enlaces

- [[00 - Inicio]]
- [[03 - Arquitectura]]
