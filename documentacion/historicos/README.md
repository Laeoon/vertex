# Simulador de Ciberseguridad Basado en Teoría de Grafos

> Godot 4.6 — GDScript con tipado estático — Filosofía: **Sandbox-First + Data-Driven**

## ¿Qué es esto?

Un simulador donde una red informática se modela como un grafo dirigido y ponderado $G=(V,E)$. Actualmente en **Hito 1**: cimientos del grafo estático con validación de unidireccionalidad.

## Estructura

```
nuevo-proyecto-de-juego/
├── core/                  # Código de producción
│   └── network/           # .tres + runtime del grafo
├── sandboxes/             # Pruebas aisladas
│   └── case_a_connectivity_unidirectional/
└── docs/                  # Documentación
    ├── INDICE.md
    └── historico/
```

## Cómo correr los sandboxes

```bash
PROJECT=/home/leonardo/nuevo-proyecto-de-juego

# Sandbox A — unidireccionalidad
godot --headless --path $PROJECT \
      res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn

# Sandbox B — pesos duales independientes
godot --headless --path $PROJECT \
      res://sandboxes/case_b_edge_dual_weights/case_b_sandbox.tscn
```

Si todo va bien, cada uno termina con `CASO X SUPERADO`.

## Hito actual

| Hito | Pieza principal | Sandbox | Doc |
|---|---|---|---|
| 1 | Cimientos del grafo estático | A, B | [`docs/historico/`](docs/historico/) |
