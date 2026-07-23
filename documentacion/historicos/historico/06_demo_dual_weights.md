# 06 · Demo Visual — Pesos Duales Independientes

## Objetivo

Ventana interactiva que muestra visualmente que `transit_cost` y
`mitigation_capacity` son canales independientes: al mutar uno, el otro
queda intacto. También verifica que el `.tres` en disco no se modifica.

## Escenario

```
[ Firewall ]  ──tc=10, mc=1──▶  [ Servidor_Web ]  ──tc=5, mc=3──▶  [ Base_de_Datos ]
```

Misma topología que el Sandbox B, pero con renderizado 2D interactivo.

## Archivos

```
sandboxes/case_demo_dual_weights/
├── demo_dual_sandbox.tscn
├── demo_dual_test.gd
└── network_demo_dual.tres
```

## Cómo se construyó

### 1. Estructura base (Node2D + _draw())

Mismo patrón que la demo visual de Sandbox A: se cargan las posiciones
de los nodos desde el `.tres` y se dibujan círculos + líneas + flechas.

### 2. Pesos en tiempo real

En `_draw()`, cada arista muestra `tc=` y `mc=` obtenidos del runtime:

```gdscript
var tc_val := runtime.get_transit_cost(&"Firewall", &"Servidor_Web")
var mc_val := runtime.get_mitigation_capacity(&"Firewall", &"Servidor_Web")
draw_string(font, mid + Vector2(-40, -8), "tc=" + str(tc_val), ...)
draw_string(font, mid + Vector2(-40, 8),  "mc=" + str(mc_val), ...)
```

El `tc` se pinta de amarillo cuando está mutado, blanco en estado original.
El `mc` siempre se pinta verde para resaltar que nunca cambia.

### 3. Mutación controlada (tecla ESPACIO)

```gdscript
func _mutate_transit_cost() -> void:
    runtime.set_transit_cost(&"Firewall", &"Servidor_Web", 99.0)
    is_mutated = true

    var tc := runtime.get_transit_cost(&"Firewall", &"Servidor_Web")
    var mc := runtime.get_mitigation_capacity(&"Firewall", &"Servidor_Web")
    passed_independence = (tc == 99.0 and mc == 1.0)
```

Después de presionar ESPACIO:
- El panel derecho muestra `tc = 99.0 (MUTADO)` en amarillo
- `mc = 1.0 (INTACTO)` en verde
- Mensaje `=> INDEPENDENCIA OK`

### 4. Test de inmutabilidad (tecla I)

```gdscript
func _test_immutability() -> void:
    var fresh := load("res://.../network_demo_dual.tres") as NetworkGraphResource
    var edge := fresh.edges[0]
    passed_immutability = (edge.transit_cost == 10.0 and edge.mitigation_capacity == 1.0)
```

Carga el `.tres` directamente desde disco (sin pasar por runtime) y verifica
que los valores originales se conservan. La mutación del paso 3 solo afectó
al runtime en memoria.

### 5. Restauración (tecla R)

Vuelve `transit_cost` a 10.0 sin recargar la escena. Útil para repetir la
prueba cuantas veces se quiera.

## Controles

| Tecla | Acción |
|---|---|
| `ESPACIO` | Mutar transit_cost de Firewall→Servidor_Web a 99.0 |
| `R` | Restaurar transit_cost a 10.0 |
| `I` | Verificar que el .tres en disco está intacto |
| `Q` | Salir |

## Comando para ejecutar

```bash
godot --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_demo_dual_weights/demo_dual_sandbox.tscn
```

(Sin `--headless`, necesita ventana gráfica.)

## Por qué importa

- **Visualiza** la independencia de pesos: el estudiante ve que tc cambia
  de blanco a amarillo mientras mc se mantiene verde
- **Demuestra** inmutabilidad del `.tres` en un solo clic
- Prepara el terreno para cuando Dijkstra y Edmonds-Karp consuman cada
  peso por separado

## ✅ Criterio de aceptación

- [x] La ventana se abre y muestra los 3 nodos en cadena con flechas
- [x] Los pesos tc y mc se muestran en cada arista
- [x] Al presionar ESPACIO, tc cambia a 99.0 (amarillo) y mc sigue en 1.0 (verde)
- [x] Mensaje de independencia en el panel
- [x] Tecla I confirma que el .tres en disco no se modificó
- [x] Tecla R restaura el valor original
