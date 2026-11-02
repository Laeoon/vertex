# Diccionario de Datos del Sistema VERTEX
## Subsistema de Persistencia Transaccional y Aislamiento de Ranuras (user://)

**Proyecto:** VERTEX — Plataforma Educativa de Ciberseguridad basada en Teoría de Grafos  
**Subsistema:** Persistencia de Estado del Operador y Ranuras de Guardado (`SlotManager`)  
**Ubicación Base en Disco:** `user://` (`user://slots.cfg`, `user://slots/slot_1/`, `user://slots/slot_2/`, `user://slots/slot_3/`)  
**Estándar de Documentación:** ANSI/IEEE Std 1059 / Diccionario de Datos de Ingeniería de Software  

---

### Resumen de Arquitectura de Almacenamiento

El subsistema de persistencia de **VERTEX** implementa un modelo de datos jerárquico y transaccional desacoplado mediante el motor de serialización `ConfigFile` de Godot Engine. El almacenamiento se organiza en tres ranuras de guardado independientes (`slot_1`, `slot_2`, `slot_3`) aisladas en el sistema de archivos del usuario, con sincronización de metadatos centralizada en `slots.cfg` y un subsistema de copias de seguridad atómicas rotativas (`backups/`).

---

### Catálogo de Entidades y Archivos de Persistencia

| Entidad / Tabla Lógica | Archivo Físico | Ámbito | Descripción Funcional |
|---|---|---|---|
| **`SlotMeta`** | `user://slots.cfg` | Global | Meta-registro de puntero de ranura activa y banderas de migración heredada. |
| **`SaveSlot`** | `user://slots/slot_X/` | Ranura | Contenedor de ranura (1..3) con metadatos de integridad y caché de estrellas. |
| **`Profile`** | `.../profile.cfg` | Ranura | Datos de identidad del analista (alias, icono y color de interfaz). |
| **`LevelProgress`** | `.../progress.cfg` | Ranura | Registro de estrellas obtenidas y menor coste de camino por escenario. |
| **`GlobalStats`** | `.../stats.cfg` | Ranura | Métricas históricas agregadas (victorias, derrotas, racha y tiempo de juego). |
| **`LevelStats`** | `.../stats.cfg` | Ranura | Desglose discreto de victorias y derrotas por nivel táctico. |
| **`BadgeRecord`** | `BadgeRegistry` | Ranura / Memoria | Catálogo de méritos, condecoraciones y avance hacia metas operacionales. |
| **`SlotSnapshot`** | `.../backups/` | Ranura / Archivo | Instantáneas atómicas rotativas (máx. 5) previas a borrados o modificaciones críticas. |

---

### 1. Entidad: `SlotMeta` (Metadatos Globales de Ranuras)
* **Archivo Físico:** `user://slots.cfg`
* **Sección ConfigFile:** `[slots]`
* **Descripción:** Controla el estado global del sistema de ranuras y el puntero al perfil en uso.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `config_id` | String | 32 caracteres | NOT NULL | **PK** | `"meta_global"` | Identificador único del registro de configuración maestro. |
| `active_slot` | int | `1 .. 3` | NOT NULL | Atributo | `1` | Índice de la ranura actualmente seleccionada por el operador. Restringido estrictamente al rango `[1, 3]`. |
| `migrated_legacy` | bool | Boolean (`0/1`) | NOT NULL | Atributo | `false` | Indica si los archivos heredados de versiones alfa planas fueron migrados atómicamente a `slot_1`. |

---

### 2. Entidad: `SaveSlot` (Contenedor de Ranura de Guardado)
* **Ubicación Física:** `user://slots/slot_X/` (donde $X \in \{1, 2, 3\}$)
* **Descripción:** Representa la partición aislada de almacenamiento para un operador específico.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `slot_id` | int | `1 .. 3` | NOT NULL | **PK** | N/A | Número entero ordinal de la ranura de guardado. |
| `is_empty` | bool | Boolean (`0/1`) | NOT NULL | Atributo | `true` | Determina si la ranura no contiene registros de progreso ni perfil activo. |
| `updated_at` | int | Entero 64 bits | NOT NULL | Atributo | `0` | Marca de tiempo en segundos (Unix Epoch) de la última escritura exitosa en el slot. |
| `cached_stars` | int | `0 .. 45` | NOT NULL | Atributo | `0` | Suma acumulada de estrellas obtenidas en todos los sectores, almacenada para lectura rápida en menú sin abrir archivos pesados. |
| `slot_path` | String | 128 caracteres | NOT NULL | Atributo | `"user://slots/slot_X"` | Ruta absoluta normalizada dentro del sandbox de ejecución de Godot. |

---

### 3. Entidad: `Profile` (Identidad del Operador / Analista)
* **Archivo Físico:** `user://slots/slot_X/profile.cfg`
* **Sección ConfigFile:** `[profile]`
* **Descripción:** Almacena los parámetros de personalización y credenciales tácticas del operador en la ranura activa.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `profile_id` | String | 36 caracteres | NOT NULL | **PK** | UUID / Clave única | Identificador único de perfil asociado a la ranura. |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK** | N/A | Referencia estricta hacia la ranura contenedora `SaveSlot.slot_id`. |
| `player_name` | String | 1 a 32 caracteres | NOT NULL | Atributo | `"Operador"` | Alias visible en interfaces tácticas y registros de auditoría. Caracteres alfanuméricos seguros sin inyecciones de escape. |
| `avatar_icon` | String | 32 caracteres | NOT NULL | Atributo | `"agent_blue"` | Clave de recurso del avatar táctico en el selector de perfiles. |
| `theme_color` | String | 7 caracteres | NOT NULL | Atributo | `"#00E5FF"` | Código hexadecimal de color para acentos visuales y HUD del operador. |

---

### 4. Entidad: `LevelProgress` (Progresión de Niveles y Puntuación)
* **Archivo Físico:** `user://slots/slot_X/progress.cfg`
* **Sección ConfigFile:** `[estrellas]`
* **Descripción:** Registra las calificaciones por escenario táctico, costo de ruta optimizado y estado de desbloqueo.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `level_key` | String | 32 caracteres | NOT NULL | **PK (Compuesta)** | N/A | Clave canónica del escenario (ej. `"sector_0_1"`, `"sector_1_3"`, `"tutorial_hacker"`). |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK (Compuesta)** | N/A | Vinculación referencial hacia `SaveSlot.slot_id`. |
| `stars` | int | `0 .. 3` | NOT NULL | Atributo | `0` | Estrellas obtenidas según heurística de optimización (1: completado, 2: eficiente, 3: óptimo). |
| `mejor_coste` | float | Flotante 32 bits | NOT NULL | Atributo | `0.0` | Menor peso acumulado de aristas según el algoritmo de búsqueda de camino (Dijkstra). |
| `completed` | bool | Boolean (`0/1`) | NOT NULL | Atributo | `false` | Bandera booleana evaluada como `stars > 0`. Habilita el acceso al siguiente nodo del sector. |

---

### 5. Entidad: `GlobalStats` (Métricas Globales de Desempeño)
* **Archivo Físico:** `user://slots/slot_X/stats.cfg`
* **Sección ConfigFile:** `[stats]`
* **Descripción:** Métricas globales acumulativas para evaluación analítica y desbloqueo de insignias de carrera.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `stats_id` | String | 32 caracteres | NOT NULL | **PK** | `"stats_main"` | Identificador único del bloque de estadísticas. |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK** | N/A | Clave foránea asociada a la ranura `SaveSlot.slot_id`. |
| `total_wins` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Número total de misiones culminadas con éxito (mitigaciones Blue Team o extracciones Red Team). |
| `total_losses` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Número total de intentos fallidos (brechas de seguridad o capturas por Centinela). |
| `best_streak` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Máxima secuencia consecutiva de victorias ininterrumpidas sin fallos. |
| `total_attempts`| int | $\ge 0$ | NOT NULL | Atributo | `0` | Contador acumulativo de partidas iniciadas (permite calcular tasa de éxito $Wins / Attempts$). |
| `play_time` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Tiempo total transcurrido en simulación activo, contabilizado en segundos. |

---

### 6. Entidad: `LevelStats` (Métricas Específicas por Escenario)
* **Archivo Físico:** `user://slots/slot_X/stats.cfg`
* **Sección ConfigFile:** `[levels]`
* **Descripción:** Desglose analítico de rendimiento detallado a nivel de escenario táctico.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `level_key` | String | 32 caracteres | NOT NULL | **PK (Compuesta)** | N/A | Clave canónica del escenario (coincidente con `LevelProgress.level_key`). |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK (Compuesta)** | N/A | Clave foránea hacia `SaveSlot.slot_id`. |
| `wins` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Cantidad de victorias obtenidas específicamente en este escenario. |
| `losses` | int | $\ge 0$ | NOT NULL | Atributo | `0` | Cantidad de derrotas acumuladas en este escenario. |

---

### 7. Entidad: `BadgeRecord` (Registro de Méritos e Insignias)
* **Subsistema:** Evaluada dinámicamente en `BadgeRegistry` (persiste sincronizada en perfil)
* **Descripción:** Representa el estado de condecoraciones tácticas desbloqueadas por el analista.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `badge_id` | String | 32 caracteres | NOT NULL | **PK (Compuesta)** | N/A | Clave única de la insignia (ej. `"first_clear"`, `"speed_demon"`, `"master_defender"`). |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK (Compuesta)** | N/A | Referencia a la ranura `SaveSlot.slot_id`. |
| `unlocked` | bool | Boolean (`0/1`) | NOT NULL | Atributo | `false` | `true` cuando se alcanza la condición de desbloqueo establecida. |
| `current_metric`| int | $\ge 0$ | NOT NULL | Atributo | `0` | Valor actual acumulado hacia la condición de la condecoración. |
| `target_metric` | int | $> 0$ | NOT NULL | Atributo | `1` | Umbral requerido para disparar el evento de adjudicación. |

---

### 8. Entidad: `SlotSnapshot` (Respaldo Atómico e Instantáneas)
* **Ubicación Física:** `user://slots/slot_X/backups/snapshot_<timestamp>_<tag>/`
* **Descripción:** Política preventiva de snapshots rotativos para recuperación ante fallos o antes del vaciado de ranuras.

| Campo / Clave | Tipo Físico | Longitud / Rango | Nulidad | Tipo de Clave | Valor por Defecto | Descripción y Reglas de Negocio |
|---|---|---|---|---|---|---|
| `snapshot_name` | String | 64 caracteres | NOT NULL | **PK** | N/A | Nombre de la carpeta de snapshot (patrón: `snapshot_<timestamp>_<tag>`). |
| `slot_id` | int | `1 .. 3` | NOT NULL | **FK** | N/A | Referencia a la ranura que originó el respaldo. |
| `tag` | String | 16 caracteres | NOT NULL | Atributo | `"auto"` | Etiqueta funcional de contexto (`"auto"`, `"pre_delete"`, `"manual"`). |
| `timestamp` | int | Entero 64 bits | NOT NULL | Atributo | N/A | Marca de tiempo exacta del sistema al momento de la captura. |
| `files_archived`| Array[String] | 3 elementos | NOT NULL | Atributo | `["progress.cfg", "profile.cfg", "stats.cfg"]` | Colección atómica de archivos de configuración respaldados íntegramente. |
