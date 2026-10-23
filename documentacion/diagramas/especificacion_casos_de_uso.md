# Especificación de Casos de Uso (UML 2.5) — Proyecto VERTEX

Documento formal de especificación de requerimientos funcionales y descomposición en Casos de Uso bajo estándares de ingeniería de software corporativa.

---

## 1. Identificación y Taxonomía de Actores

```
                 ┌────────────────────────────────┐
                 │       SISTEMA VERTEX           │
                 │                                │
  ┌───────────┐  │  ┌──────────────────────────┐  │  ┌───────────────┐
  │           │  │  │                          │  │  │               │
  │ Operador  ├──┼──┤  Límite del Sistema      ├──┼──┤  Adversario   │
  │ (Humano)  │  │  │                          │  │  │  (IA Hostil)  │
  │           │  │  └──────────────────────────┘  │  │               │
  └───────────┘  │                                │  └───────────────┘
                 │                                │
                 │                                │  ┌───────────────┐
                 │                                │  │               │
                 │                                ├──┤  Sistema I/O  │
                 │                                │  │ (Persistencia)│
                 └────────────────────────────────┘  └───────────────┘
```

### 1.1 Actores Primarios
- **Operador (Usuario / Alumno / Analista)**:
  - *Descripción*: Persona que interactúa con la terminal gráfica del sistema.
  - *Responsabilidades*: Iniciar sesión, seleccionar perfiles de operador, recorrer módulos de capacitación, ejecutar vectores de infiltración (Heist/Hacker), implementar contramedidas de red (Ciberdefensa) y consultar el expediente de méritos.

### 1.2 Actores Secundarios
- **Adversario (IA del Sistema / Motor Autónomo)**:
  - *Descripción*: Agente reactivo simulado que compite contra el operador.
  - *Responsabilidades*: En modos ofensivos actúa como red defensiva (bloqueo de aristas por `AIBlocker`, patrullas y persecución activa); en modo defensivo actúa como intruso hostil ejecutando movimiento lateral y exploits (`Bypass`).
- **Sistema I/O (Manejador de Persistencia / S.O.)**:
  - *Descripción*: Subsistema de bajo nivel encargado de la integridad del almacenamiento físico en disco.
  - *Responsabilidades*: Lectura, escritura y aislamiento transaccional de ranuras de guardado en `user://slots/slot_X/` (`profile.cfg`, `progress.cfg`, `stats.cfg`, `slots.cfg`).

---

## 2. Inventario de Casos de Uso por Paquete

| Paquete | Código | Nombre del Caso de Uso | Actores Asociados |
|---|---|---|---|
| **Gestión de Sesión** | `CU-01` | Administrar Ranuras de Guardado (Slots) | Operador, Sistema I/O |
| **Entrenamiento** | `CU-02` | Completar Módulos de Entrenamiento | Operador, Sistema I/O |
| **Infiltración Física** | `CU-03` | Ejecutar Modo Heist | Operador, Adversario, Sistema I/O |
| **Operaciones Red Team** | `CU-04` | Ejecutar Modo Hacker | Operador, Adversario, Sistema I/O |
| **Respuesta Blue Team**| `CU-05` | Ejecutar Modo Ciberdefensa | Operador, Adversario, Sistema I/O |
| **Contramedidas** | `CU-06` | Declarar Cuarentena de Host | Operador |
| **Telemetría Táctica** | `CU-07` | Revelar Ruta Oculta (Intercepción) | Operador |
| **Base de Conocimiento**| `CU-08` | Consultar Base de Datos (Codex) | Operador |
| **Expediente** | `CU-09` | Consultar Perfil y Condecoraciones | Operador, Sistema I/O |
| **Persistencia** | `CU-10` | Guardar Progreso y Calificación | Sistema I/O |

---

## 3. Especificación Formal de Casos de Uso (Plantillas de Proceso)

---

### Ficha Técnica: `CU-01` — Administrar Ranuras de Guardado (Slots)

- **Identificador:** `CU-01`
- **Nombre:** Administrar Ranuras de Guardado e Inicialización de Sesión
- **Actores:** Operador (Iniciador), Sistema I/O (Secundario).
- **Precondiciones:**
  1. La aplicación fue iniciada por el sistema operativo.
  2. El directorio de usuario `user://` cuenta con permisos de lectura y escritura.

#### Flujo Principal (Happy Path)
1. El sistema presenta la pantalla de título inicial (`StartScreen`) con el logotipo y el mensaje de espera de entrada.
2. El operador presiona `[ENTER]`, `[ESPACIO]` o hace clic izquierdo en pantalla.
3. El sistema invoca al `SlotManager` para consultar el caché en memoria de las ranuras de guardado.
4. El sistema renderiza las tres ranuras disponibles (`Slot 1`, `Slot 2`, `Slot 3`) mostrando: indicativo, misiones superadas, estrellas acumuladas y estado.
5. El operador navega con teclado (`[A]/[D]`) o ratón y selecciona una ranura disponible o preexistente.
6. El sistema fija el `active_slot` seleccionado en `user://slots.cfg`.
7. El sistema ejecuta una transición visual suave (`SceneTransition.fade_to_scene`) hacia el Hub Principal (`main_menu.tscn`).

#### Flujos Alternativos
- **FA-1: Migración Automática de Datos Heredados (`«extend»`)**:
  - En el paso 3, si `user://slots.cfg` no existe pero se detectan archivos heredados (`user://progress.cfg` o `user://profile.cfg` en la raíz):
    1. El sistema crea la estructura `user://slots/slot_1/`.
    2. El sistema copia los archivos existentes a la carpeta del Slot 1 sin eliminarlos de raíz.
    3. El sistema inicializa `user://slots.cfg` con el Slot 1 como activo y actualiza los metadatos.
    4. El flujo continúa en el paso 4 con el Slot 1 mostrando los datos preservados.
- **FA-2: Creación de Nueva Campaña en Ranura Vacía**:
  - En el paso 5, el operador selecciona una ranura vacía:
    1. El sistema inicializa los archivos de perfil y progreso en blanco para esa ranura.
    2. El flujo continúa normalmente al paso 6.

#### Postcondiciones
- El slot activo queda registrado y todos los módulos (`ProgressUtil`, `Profile`, `ProgressService`) resuelven dinámicamente sus rutas apuntando a la carpeta de dicho slot.

---

### Ficha Técnica: `CU-05` — Ejecutar Ciclo Reactivo de Ciberdefensa

- **Identificador:** `CU-05`
- **Nombre:** Ejecutar Ciclo Reactivo de Ciberdefensa (Blue Team)
- **Actores:** Operador (Iniciador), Adversario (IA Atacante), Sistema I/O (Secundario).
- **Precondiciones:**
  1. Existe un slot de guardado activo.
  2. El nivel de defensa está desbloqueado en el registro de progreso.
  3. El grafo de red y el runtime mutable (`NetworkRuntime`) están inicializados.

#### Flujo Principal (Happy Path)
1. El sistema despliega la topología de red con el nodo de origen `Internet` (posición del adversario) y el nodo `Database` (Núcleo crítico).
2. El sistema inicializa la barra de telemetría de **Rastreo Forense EDR** en `0%` y el contador de turnos en `0`.
3. El operador evalúa las aristas y realiza clic sobre una conexión activa para bloquearla.
4. El sistema aplica el bloqueo en la arista y dispara la resolución automática del turno (`«include» Resolver Turno`).
5. El sistema incrementa el turno en 1 unidad y calcula la ganancia de Rastreo Forense (`+20%` base).
6. La **IA Atacante** evalúa sus opciones: detecta la arista bloqueada y realiza **Movimiento Lateral** hacia un nodo vecino accesible.
7. El sistema actualiza la posición del atacante en pantalla y emite una alerta auditiva.
8. Se repiten los pasos 3 a 7 hasta que el Rastreo Forense EDR alcanza el **100%**.
9. El sistema declara la **Victoria Defensiva**, calcula la calificación de estrellas por conservación de infraestructura y persiste el resultado en el slot activo (`«include» CU-10`).

#### Flujos Alternativos
- **FA-1: El Adversario ejecuta Exploit Bypass (`«extend»`)**:
  - En el paso 6, si el atacante se encuentra totalmente cercado hacia el objetivo y posee stock de exploits:
    1. La IA quema un cargo de `Bypass`.
    2. El sistema remueve el bloqueo de la arista crítica y avanza al intruso a través de ella.
    3. El sistema muestra la notificación: `⚡ ¡ALERTA! Intruso usó BYPASS`.
    4. El flujo continúa en el paso 7.
- **FA-2: Sondeo Pasivo por Contención Total**:
  - En el paso 6, si el atacante está totalmente cercado y no tiene exploits:
    1. El intruso permanece en su posición sondeando puertos.
    2. El sistema otorga un **bonus acelerado de Trace EDR (+10% a +25%)**.
    3. Si el Trace llega al 100%, se emite la victoria inmediata.
- **FA-3: El Operador aplica Cuarentena de Host (`«extend» CU-06`)**:
  - En el paso 3, el operador presiona `[C]` y selecciona un nodo intermedio comprometido:
    1. El sistema corta de forma permanente todas las aristas conectadas al nodo (coste de tránsito `INF`).
    2. El nodo queda marcado como `[AISLADO]`.
    3. Se aplica una penalización de -0.15 en el cálculo de estrellas por sacrificio de disponibilidad.
    4. Se resuelve el turno automáticamente y el flujo salta al paso 5.
- **FA-4: El Operador revela la Ruta bajo Niebla de Guerra (`«extend» CU-07`)**:
  - En niveles con `fog_of_war = true`, el operador presiona `[P]`:
    1. El sistema dibuja la ruta proyectada del atacante en pantalla.
    2. Se activa una penalización irrevocable que **topa la calificación a un máximo de 2 estrellas**.
- **FA-5: Intrusión Crítica en el Núcleo (Derrota)**:
  - En el paso 6, si el adversario alcanza el nodo `Database`:
    1. El sistema declara la **Derrota**, cancela el asedio y muestra la pantalla de Game Over.

#### Postcondiciones
- **Victoria:** Amenaza neutralizada, integridad del Núcleo preservada, registro de estrellas almacenado en el slot.
- **Derrota:** Servidor maestro comprometido, registro de intento fallido contabilizado.

---

### Ficha Técnica: `CU-04` — Infiltración Cibernética (Modo Hacker)

- **Identificador:** `CU-04`
- **Nombre:** Ejecutar Infiltración Sigilosa y Gestión de Ruido (Red Team)
- **Actores:** Operador (Iniciador), Defensa SOC (IA Centinela), Sistema I/O (Secundario).
- **Precondiciones:**
  1. Slot activo configurado.
  2. Nivel de modo Hacker desbloqueado.

#### Flujo Principal (Happy Path)
1. El sistema sitúa al operador en el nodo de entrada `DMZ` y fija el objetivo final en `Core`.
2. El sistema inicializa la telemetría de **Ruido de Red en 0/100** y entrega los exploits iniciales (`Bypass`, `Escalate`, `Persist`, `Decoy`).
3. El operador presiona `[X]` para escanear un nodo vecino sin generar ruido excesivo.
4. El operador selecciona un exploit táctico (`[1] Infiltración`, `[2] Elevación`, `[3] Persistencia`, `[4] Señuelo`) o avanza hacia un vecino.
5. El sistema computa el costo de ruido de la acción y lo acumula en el indicador global (`«include»`).
6. El sistema evalúa el nivel de alerta perimetral: mientras el ruido se mantenga por debajo de los umbrales críticos, las patrullas no detectan la brecha.
7. Al completar cada turno de movimiento, el sistema aplica el enfriamiento natural de ruido (`-3` por turno).
8. Se repiten los pasos 3 a 7 hasta que el operador alcanza el nodo `Core` cumpliendo todos los waypoints obligatorios.
9. El sistema emite la victoria ofensiva y califica con **3 estrellas** si la operación mantuvo el sigilo (`«include» CU-10`).

#### Flujos Alternativos
- **FA-1: Saturación de Ruido y Despacho de Perseguidores (`«extend»`)**:
  - En el paso 5, si el ruido supera el umbral crítico (`>= 60` o `>= 85`):
    1. La Defensa SOC activa un centinela activo en el nodo alertado.
    2. El perseguidor recalcula la ruta más corta hacia la posición del operador.
    3. Si el perseguidor alcanza al operador en el mismo nodo, se declara **Captura / Derrota**.
- **FA-2: Absorción de Alertas mediante Señuelo (`Decoy`)**:
  - El operador despliega un señuelo en un nodo adyacente:
    1. Los bloqueos de la IA y los perseguidores desvían su curso hacia el señuelo durante 2 turnos, protegiendo al operador.

#### Postcondiciones
- Base de datos corporativa extraída sin detección, puntaje de sigilo persistido en el slot.

---

### Ficha Técnica: `CU-03` — Infiltración Física y Evasión (Modo Heist)

- **Identificador:** `CU-03`
- **Nombre:** Infiltración Física y Navegación con Presupuesto (Heist)
- **Actores:** Operador (Iniciador), Seguridad Física (IA Patrulla), Sistema I/O (Secundario).
- **Precondiciones:**
  1. Nivel de Heist seleccionado y habilitado.

#### Flujo Principal (Happy Path)
1. El sistema posiciona al operador en el nodo `Inicio` y fija la meta en `Bóveda`.
2. El sistema asigna el presupuesto de puntos de movimiento (`max_movement_points`).
3. El operador utiliza las flechas direccionales para seleccionar un nodo adyacente y presiona `[Enter]` para desplazarse.
4. El sistema deduce el coste de tránsito de la arista del presupuesto disponible (`«include»`).
5. El sistema evalúa el porcentaje de probabilidad de detección del nodo pisado: si no se activa la alarma, el operador continúa sin ser visto.
6. El operador alcanza los waypoints secuenciales requeridos (`Seguridad`, `Cajas`).
7. El operador alcanza la `Bóveda` antes de agotar los turnos máximos ni los puntos de movimiento.
8. El sistema valida la ruta óptima ejecutada y otorga la calificación de estrellas (`«include» CU-10`).

#### Flujos Alternativos
- **FA-1: Activación de Sensor Perimetral (Alarma)**:
  - En el paso 5, si el roll de detección supera el umbral del nodo:
    1. Se activa una alarma acústica y visual.
    2. Se genera un guardia de seguridad con retardo de 1 turno que persigue al operador.
- **FA-2: Recolección de Nodo Dorado (`Bonus`) (`«extend»`)**:
  - El operador se desvía deliberadamente para pisar un nodo con datos extras:
    1. El sistema registra el dato extra, requisito indispensable para el piso de 3 estrellas en el nivel.

#### Postcondiciones
- Bóveda asegurada, métricas de coste registradas en el archivo de progreso.
