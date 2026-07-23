# 05 · Sandbox B — Costos Duales Independientes

## Objetivo

Demostrar que la estructura soporta **dos pesos independientes** por arista
y que un algoritmo puede consultar uno sin alterar el otro. Base para que
Dijkstra y Edmonds-Karp corran sobre la misma red sin interferencias.

## Escenario

```
[ Firewall ] ──HTTPS──▶ [ Servidor_Web ] ──SQL──▶ [ Base_de_Datos ]
    (tc=10, mc=1)            (tc=5, mc=3)
```

- **3 nodos** en cadena: Firewall → Servidor_Web → Base_de_Datos
- **2 aristas** con pesos diferentes

## Archivos del sandbox

```
sandboxes/case_b_edge_dual_weights/
├── case_b_sandbox.tscn
├── case_b_test.gd
├── network_test_b.tres
└── README.md
```

## ¿Qué valida?

| # | Asserción | Resultado |
|---|---|---|
| 1 | `graph.validate()` vacío | ✅ |
| 2 | `get_transit_cost(FW, Web)` = 10.0 | ✅ |
| 3 | `get_mitigation_capacity(FW, Web)` = 1.0 | ✅ |
| 4 | `set_transit_cost(..., 99.0)` se refleja en `get_transit_cost` | ✅ |
| 5 | `get_mitigation_capacity` sigue en 1.0 tras la mutación | ✅ |
| 6 | `get_transit_cost(Web, DB)` = 5.0 | ✅ |
| 7 | `get_mitigation_capacity(Web, DB)` = 3.0 | ✅ |
| 8 | Recarga del `.tres`: `transit_cost` = 10.0 (no se modificó en disco) | ✅ |
| 9 | Recarga del `.tres`: `mitigation_capacity` = 1.0 (no se modificó en disco) | ✅ |

## Salida real de la ejecución

```
[ Caso B: Ruta Firewall → Servidor_Web ]
  transit_cost (Dijkstra)        = 10.0
  mitigation_capacity (Edmonds)  = 1.0
[ Test de independencia: mutamos transit_cost a 99.0 ]
  transit_cost (Dijkstra)        = 99.0
  mitigation_capacity (Edmonds)  = 1.0  ← INTACTO
✓ El archivo .tres permanece intacto tras las mutaciones
✅ CASO B SUPERADO
```

## Comando para reproducir

```bash
godot --headless --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_b_edge_dual_weights/case_b_sandbox.tscn
```

## Por qué importa

- **Dijkstra** usará `transit_cost` para rutas de intercepción
- **Edmonds-Karp** usará `mitigation_capacity` para cortes mínimos
- Ambos deben coexistir en la misma estructura sin corromperse

El assert #5 (mutar `transit_cost` no toca `mitigation_capacity`) es la
prueba contractual de que esto es seguro.

## ✅ Criterio de aceptación

- [x] El sandbox se ejecuta sin errores
- [x] Los 9 asserts pasan
- [x] El `.tres` permanece intacto tras mutaciones
