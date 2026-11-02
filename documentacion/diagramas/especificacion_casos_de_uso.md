# Especificación de Requerimientos y Casos de Uso (UML 2.5) — Proyecto VERTEX

Documento formal de especificación de ingeniería de software corporativa: catálogo de requerimientos del sistema, taxonomía de actores, matriz de trazabilidad y especificación detallada de Casos de Uso bajo el estándar UML 2.5.

---

## 1. Requerimientos del Sistema (Catálogo Formal)

### 1.1 Requerimientos Funcionales (RF)

| Código | Denominación del Requerimiento | Prioridad | Descripción Operativa y Criterios de Aceptación |
|---|---|:---:|---|
| **`RF-01`** | **Aislamiento Multi-Slot** | Alta | El sistema debe proveer tres ranuras independientes de guardado (`slot_1`, `slot_2`, `slot_3`) en `user://slots/`, garantizando que las modificaciones de un perfil no afecten el estado ni el historial de los demás. |
| **`RF-02`** | **Gestión de Identidad de Operador** | Media | Permitir la captura, edición y persistencia del expediente de usuario: alias táctico (1 a 32 caracteres alfanuméricos), icono de avatar y paleta de color de interfaz en `profile.cfg`. |
| **`RF-03`** | **Módulo de Capacitación y Academia** | Alta | Disponer de tutoriales interactivos que instruyan al analista en topología de redes, peso de aristas, cálculo de caminos mínimos y respuesta ante incidentes. |
| **`RF-04`** | **Simulación Táctica Modo Heist** | Alta | Ejecutar misiones de infiltración física donde el operador navega nodos de red evitando patrullas estocásticas y optimizando el coste de paso. |
| **`RF-05`** | **Simulación Ofensiva Modo Hacker** | Alta | Proveer un entorno de operaciones Red Team con consumo de exploits (`Bypass`, `Escalate`, `Persist`, `Decoy`) y balance en tiempo real del nivel de ruido acústico/digital perimetral. |
| **`RF-06`** | **Defensa Reactiva Blue Team** | Crítica | Modelar el ciclo defensivo donde el analista bloquea aristas mientras el adversario (IA con algoritmo Dijkstra) busca vulnerar el nodo Core, computando simultáneamente el avance forense Trace EDR. |
| **`RF-07`** | **Declaración de Cuarentena** | Media | Permitir aislar nodos de red sospechosos o infectados mediante comando táctico, anulando temporalmente su conectividad lógica. |
| **`RF-08`** | **Intercepción de Rutas Críticas** | Media | Analizar y revelar caminos óptimos del atacante mediante teoría de flujo máximo y corte mínimo (algoritmo Edmonds-Karp). |
| **`RF-09`** | **Códex Táctico de Ciberseguridad** | Baja | Ofrecer una base de datos de conocimiento consultable con definiciones formales de vectores de ataque, conceptos de grafos y glosario de ciberseguridad. |
| **`RF-10`** | **Analítica y Progresión por Estrellas** | Alta | Evaluar y registrar automáticamente el desempeño del operador (1 a 3 estrellas, menor coste de camino, victorias y derrotas) en `progress.cfg` y `stats.cfg`. |
| **`RF-11`** | **Registro de Méritos y Condecoraciones** | Media | Auditar métricas de partida contra el registro `BadgeRegistry` para adjudicar insignias operacionales al cumplir metas de carrera. |
| **`RF-12`** | **Respaldo Atómico y Recuperación** | Alta | Ejecutar snapshots preventivos automáticos (máximo 5 rotativos) antes de operaciones destructivas de ranura, con soporte de restauración íntegra. |

---

### 1.2 Requerimientos No Funcionales (RNF)

| Código | Atributo de Calidad | Categoría | Especificación Técnica y Métrica Verificable |
|---|---|:---:|---|
| **`RNF-01`** | **Rendimiento Algorítmico** | Eficiencia | Los algoritmos de búsqueda de caminos sobre el grafo (Dijkstra y Edmonds-Karp) deben resolver el turno de la IA en un tiempo inferior a **16 milisegundos** ($< 1$ cuadro a 60 FPS) para grafos de hasta 100 nodos. |
| **`RNF-02`** | **Persistencia Transaccional** | Confiabilidad | El guardado en disco mediante `ConfigFile` debe ser atómico y resistente a cortes de energía, implementando validación de cabeceras mágicas y respaldo previo a la mutación. |
| **`RNF-03`** | **Aislamiento en Sandboxing** | Seguridad | Todas las operaciones de I/O deben quedar confinadas estrictamente al directorio `user://` del sistema operativo, impidiendo cualquier acceso o lectura a directorios del sistema anfitrión. |
| **`RNF-04`** | **Integridad de Datos** | Robustez | Los valores de configuración numérica (estrellas, ranuras activas, volumen) deben estar acotados por aserciones y restricciones de dominio (`slot_id \in [1, 3]`, `stars \in [0, 3]`). |
| **`RNF-05`** | **Portabilidad del Sistema** | Portabilidad | La plataforma debe compilar y ejecutarse de manera homogénea en sistemas operativos GNU/Linux x86_64, Microsoft Windows 10/11 y exportación web HTML5/WebAssembly sin alterar la lógica central. |
| **`RNF-06`** | **Diseño Data-Driven** | Mantenibilidad | Las topologías de red, escenarios y especificaciones de nodos deben residir como recursos inmutables desacoplados (`.tres`), separando la definición de datos de la lógica ejecutable. |
| **`RNF-07`** | **Ergonomía y Accesibilidad** | Usabilidad | La interfaz de usuario debe implementar esquemas de control duales (ratón y atajos numéricos de teclado), soporte de internacionalización (i18n: ES/EN/PT) y temas de alto contraste. |
| **`RNF-08`** | **Observabilidad y Auditoría** | Soporte | El subsistema `GameLogger` debe registrar eventos operacionales clasificados por canal (`INFO`, `WARN`, `ERROR`, `FSM`) con marcas de tiempo en milisegundos para depuración técnica. |

---

### 1.3 Matriz de Trazabilidad (Requerimientos $\leftrightarrow$ Casos de Uso $\leftrightarrow$ Persistencia)

| Requerimiento Funcional | Requerimiento No Funcional | Caso de Uso UML | Entidad / Archivo de Persistencia |
|:---:|:---:|:---:|---|
| `RF-01` (Multi-Slot) | `RNF-02`, `RNF-03` | `CU-01` | `SlotMeta` (`slots.cfg`), `SaveSlot` (`slot_X/`) |
| `RF-02` (Perfil) | `RNF-04`, `RNF-07` | `CU-09` | `Profile` (`profile.cfg`) |
| `RF-03` (Academia) | `RNF-06`, `RNF-07` | `CU-02` | `LevelProgress` (`progress.cfg`) |
| `RF-04` (Modo Heist) | `RNF-01`, `RNF-06` | `CU-03` | `LevelProgress`, `GlobalStats` (`stats.cfg`) |
| `RF-05` (Modo Hacker) | `RNF-01`, `RNF-06` | `CU-04` | `LevelProgress`, `GlobalStats`, `LevelStats` |
| `RF-06` (Ciberdefensa) | `RNF-01`, `RNF-08` | `CU-05` | `LevelProgress`, `GlobalStats`, `LevelStats` |
| `RF-07` (Cuarentena) | `RNF-01`, `RNF-06` | `CU-06` | Estado volátil en memoria (`NetworkRuntime`) |
| `RF-08` (Rutas Críticas) | `RNF-01`, `RNF-06` | `CU-07` | Estado volátil en memoria (`StrategicAnalyzer`) |
| `RF-09` (Códex) | `RNF-06`, `RNF-07` | `CU-08` | Catálogo estático inmutable (`res://`) |
| `RF-10` (Analítica) | `RNF-02`, `RNF-04` | `CU-10` | `LevelProgress`, `GlobalStats`, `LevelStats` |
| `RF-11` (Insignias) | `RNF-04`, `RNF-07` | `CU-09` | `BadgeRecord` (`BadgeRegistry` / `profile.cfg`) |
| `RF-12` (Snapshots) | `RNF-02`, `RNF-08` | `CU-11` | `SlotSnapshot` (`user://backups/`) |

---

## 2. Identificación y Taxonomía de Actores

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

### 2.1 Actores Primarios
- **Operador (Usuario / Alumno / Analista)**:
  - *Descripción*: Persona que interactúa con la terminal gráfica del sistema.
  - *Responsabilidades*: Iniciar sesión, seleccionar perfiles de operador, recorrer módulos de capacitación, ejecutar vectores de infiltración (Heist/Hacker), implementar contramedidas de red (Ciberdefensa) y consultar el expediente de méritos.

### 2.2 Actores Secundarios
- **Adversario (IA del Sistema / Motor Autónomo)**:
  - *Descripción*: Agente reactivo simulado que compite contra el operador.
  - *Responsabilidades*: En modos ofensivos actúa como red defensiva (bloqueo de aristas por `AIBlocker`, patrullas y persecución activa); en modo defensivo actúa como intruso hostil ejecutando movimiento lateral y exploits (`Bypass`).
- **Sistema I/O (Manejador de Persistencia / S.O.)**:
  - *Descripción*: Subsistema de bajo nivel encargado de la integridad del almacenamiento físico en disco.
  - *Responsabilidades*: Lectura, escritura y aislamiento transaccional de ranuras de guardado en `user://slots/slot_X/` (`profile.cfg`, `progress.cfg`, `stats.cfg`, `slots.cfg`).

---

## 3. Inventario de Casos de Uso por Paquete

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
| **Gestión de Sesión** | `CU-11` | Respaldar, Exportar e Importar Ranuras de Guardado | Operador, Sistema I/O |

---

## 4. Especificación Formal de Casos de Uso (Plantillas de Proceso)

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

### Ficha Técnica: `CU-11` — Respaldar, Exportar e Importar Ranuras de Guardado

- **Identificador:** `CU-11`
- **Nombre:** Respaldar, Exportar e Importar Ranuras de Guardado (.bak)
- **Actores:** Operador (Iniciador), Sistema I/O (Secundario).
- **Precondiciones:**
  1. La pantalla de selección de ranuras (`StartScreen`) está activa.
  2. El sistema I/O cuenta con permisos de lectura y escritura en `user://slots/` y `user://backups/`.

#### Flujo Principal (Happy Path) — Exportación
1. El operador navega hacia una ranura ocupada y acciona `[E]` (o hace clic en `[E] Exportar`).
2. El sistema invoca `SlotManager.export_slot_to_bak()`.
3. El sistema valida los datos de la ranura y serializa `progress.cfg`, `profile.cfg` y `stats.cfg` en formato JSON atómico.
4. El sistema calcula la suma de verificación SHA-256 de la carga útil.
5. El sistema escribe en disco el archivo en `user://backups/` con cabecera `VERTEX_SAVE_BAK_v1`.
6. El sistema emite feedback auditivo y despliega un toast visual de confirmación (`[OK] EXPORTADO: ...`).

#### Flujos Alternativos
- **FA-1: Importación de Partida con Reemplazo Seguro (`«extend»`)**:
  1. El operador pulsa `[I]` sobre una ranura.
  2. El sistema lista los archivos `.bak` disponibles. Si la ranura no está vacía, despliega un modal de advertencia.
  3. El operador confirma la importación (`[Y]` / `[ENTER]`).
  4. El sistema genera de forma autónoma un snapshot preventivo de contingencia de la ranura (`tag: pre_import`) en `user://slots/slot_X/backups/`.
  5. El sistema valida la cabecera mágica y el checksum SHA-256 del archivo `.bak`.
  6. Si la verificación es exitosa, el sistema escribe los archivos, invalida la caché de resúmenes y emite una notificación verde.
- **FA-2: Rechazo por Corrupción o Alteración de Archivo**:
  - En el paso 5 de FA-1, si el hash computado no coincide con el checksum de la cabecera:
    1. El sistema aborta la escritura atómica.
    2. El sistema no modifica los archivos de la ranura destino.
    3. El sistema emite un toast de alerta de seguridad: `[ERROR] FALLO DE IMPORTACIÓN: CHECKSUM O ARCHIVO INVÁLIDO`.
- **FA-3: Restauración de Snapshot Preventivo Automático (`«extend»`)**:
  1. El operador pulsa `[R]` sobre una ranura.
  2. El sistema comprueba la existencia de snapshots previos en `user://slots/slot_X/backups/`.
  3. Si existen, el sistema muestra un modal de confirmación.
  4. Al confirmar, el sistema restaura los archivos del último snapshot e invalida la caché.
- **FA-4: Intento de Exportación en Ranura Vacía**:
  - Si el operador intenta exportar una ranura sin progreso:
    1. El sistema bloquea la operación.
    2. El sistema emite un toast de advertencia.

#### Postcondiciones
- El archivo `.bak` queda generado con integridad criptográfica verificable, o la ranura destino queda actualizada o restaurada con un snapshot de resguardo previo.

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
