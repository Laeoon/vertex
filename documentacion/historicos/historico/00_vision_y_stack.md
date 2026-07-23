# 00 · Visión y Stack

## La idea en una frase

Modelar una **red informática** como un **grafo dirigido y ponderado** como base para un simulador de ciberseguridad educativo.

## ¿Por qué teoría de grafos?

Porque una red es, literalmente, un grafo:

- **Vértices (V)** = activos: firewall, servidor, router, base de datos, internet, workstation…
- **Aristas (E)** = conexiones dirigidas con pesos (costos de tránsito, capacidades de mitigación).

## Stack técnico

| Pieza | Versión | Para qué |
|---|---|---|
| Godot Engine | 4.6.3 stable | Motor + editor |
| GDScript | Godot 4.6 | Lógica (tipado estático fuerte) |
| Custom Resources | `.tres` | Datos del grafo |
| SceneTree | headless | Validación de sandboxes sin abrir editor |

## Principios rectores

1. **Data-Driven**: cero datos de red hardcodeados en código. Todo en `.tres`.
2. **Sandbox-First**: nada entra al `core/` sin pasar antes por un sandbox.
3. **Inmutabilidad del .tres**: el archivo de recurso no se modifica nunca en tiempo de ejecución. Los cambios dinámicos van a un `NetworkRuntime` (objeto en memoria).
4. **Tipado estricto**: cada variable, parámetro y retorno lleva tipo explícito. Sin `Variant` salvo donde sea estrictamente necesario.

## ¿Qué NO es este proyecto (todavía)?

- No es un juego completo con UI. Es la **base de datos + cimiento algorítmico**.
- No tiene agentes enemigos ni lógica ofensiva. Solo la estructura que los alojará.
- No tiene persistencia en disco del estado de simulación. El runtime vive en memoria y se descarta al cerrar.

## Glosario mínimo

| Término | Significado |
|---|---|
| Grafo $G=(V,E)$ | Conjunto de nodos y aristas |
| Arista dirigida | Conexión con sentido único (de A a B, no de B a A) |
| `.tres` | Formato texto de Godot para recursos |
| Runtime | Capa mutable en memoria que envuelve un recurso inmutable |
