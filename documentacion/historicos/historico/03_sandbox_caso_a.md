# 03 · Sandbox A — Conectividad Unidireccional

## Objetivo

Demostrar que la estructura del grafo **respeta la dirección** de las aristas: declarar `Internet → Firewall` no implica la existencia de `Firewall → Internet`. Esta es la base sobre la que el agente defensivo razonará ("¿puedo salir al exterior?").

## Escenario

```
   [ Internet ]  ──HTTPS──▶  [ Firewall ]
        ▲                         │
        │                         ▼
       (NO existe)              (sin salida)
   Firewall → Internet
```

- **2 nodos**: `Internet` (tipo `INTERNET`), `Firewall` (tipo `FIREWALL`).
- **1 arista**: `Internet → Firewall`, `transit_cost=1.0`, `mitigation_capacity=1.0`, `protocol="HTTPS"`.
- **0 aristas en dirección inversa**.

## Archivos del sandbox

```
sandboxes/case_a_connectivity_unidirectional/
├── case_a_sandbox.tscn
├── case_a_test.gd
├── network_test_a.tres
└── README.md
```

## ¿Qué valida?

| # | Asserción | Resultado |
|---|---|---|
| 1 | `graph.validate()` devuelve array vacío | ✅ |
| 2 | `get_neighbors(&"Internet")` tiene 1 elemento (Firewall) | ✅ |
| 3 | `get_neighbors(&"Firewall")` está **vacío** | ✅ |
| 4 | `has_edge(Internet, Firewall)` → `true` | ✅ |
| 5 | `has_edge(Firewall, Internet)` → `false` | ✅ |
| 6 | `get_transit_cost(Firewall, Internet)` → `INF` | ✅ |
| 7 | `get_mitigation_capacity(Firewall, Internet)` → `0.0` | ✅ |

## Salida real de la ejecución

```
===============================================
  SANDBOX A: Conectividad Unidireccional
===============================================
Grafo cargado: Graph(|V|=2, |E|=1, directed=true)
[Vecinos salientes de 'Internet']
  → {to_id: Firewall, transit_cost: 1.0, ...}
[Vecinos salientes de 'Firewall']
  (ninguno) ← El firewall NO puede salir a Internet ✓
...
✅ CASO A SUPERADO: la estructura respeta la unidireccionalidad
```

## Comando para reproducir

```bash
godot --headless --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn
```

## Por qué importa

El agente defensivo necesita **confiar** en que la red que ve es la red que es. Si la estructura invirtiera direcciones implícitamente, el agente podría:

- Mandar parches a la red pública pensando que está aislando.
- Calcular rutas de salida que no existen físicamente.
- Tomar decisiones de containment basadas en conectividad fantasma.

Este sandbox es la **puerta de entrada** antes de meter algoritmos reales.

## ✅ Criterio de aceptación

- [x] El sandbox se ejecuta sin errores.
- [x] Los 7 asserts pasan.
- [x] La salida es legible y reproducible.
- [x] El `.tres` no se modifica en ningún momento de la prueba.
