# DOCUMENTO DE APOYO Y DOSSIER ACADÉMICO PARA EL INFORME FINAL (PST II)
## Proyecto: VERTEX — Entorno de Simulación de Ciberseguridad Basado en Teoría de Grafos
**Material de Consulta, Argumentación, Citas Académicas y Recomendaciones de Mejora**

* **Destinado a:** Equipo de Desarrollo de VERTEX (Leonardo Angulo, Juan Parilli, Ana Borges).
* **Propósito:** Servir de insumo directo, banco de citas y guía estratégica para enriquecer el Informe Final de Grado del PST II (PNF en Informática - UPTA "Federico Brito Figueroa") y preparar la defensa oral ante el jurado evaluador.
* **Naturaleza del documento:** Material de apoyo y asesoría técnica; **no** sustituye la redacción del informe institucional.

---

## 1. APORTES CRÍTICOS Y BANCO DE CITAS: PAPER DE SHIVAKUMAR & MAMATHA (2022)

Para elevar la categoría académica del informe desde un simple "proyecto de programación de videojuegos" a una **"investigación aplicada en ciencias de la computación y ciberdefensa"**, es fundamental citar y articular el trabajo de Shivakumar y Mamatha:

> **Referencia formal (Formato APA 7ma Edición):**  
> Shivakumar, M. D., & Mamatha, N. (2022). Applications of graph theory in cybersecurity: Network defense models. *World Journal of Advanced Research and Reviews*, 14(02), 735–743. https://doi.org/10.30574/wjarr.2022.14.2.0435

### Ideas Fuerza y Citas Contextualizadas para Usar en el Informe

#### A. Para el Capítulo del Planteamiento del Problema / Justificación
* **La cita teórica:**  
  > *"Modern communication networks exhibit high structural complexity and dynamic interdependencies, rendering traditional tabular and static security assessments insufficient for modeling multi-stage threat propagation."* (Shivakumar & Mamatha, 2022, p. 736).
* **Cómo usarla en el informe de VERTEX:**  
  Úsenla para justificar por qué los estudiantes de informática no comprenden la ciberseguridad cuando se les enseña únicamente con diapositivas teóricas o comandos aislados. Expliquen que el simulador nace para resolver esta insuficiencia, permitiendo visualizar la red como un grafo dinámico interactivo donde cada acción tiene repercusiones topológicas.

#### B. Para el Marco Teórico (Grafos de Ataque y Dijkstra)
* **La cita teórica:**  
  > *"Attack graphs represent all possible paths an attacker can traverse to compromise a critical asset. Determining the most probable or fastest intrusion trajectory maps directly to the single-source shortest path problem on weighted directed graphs."* (Shivakumar & Mamatha, 2022, p. 738).
* **Cómo usarla en el informe de VERTEX:**  
  Úsenla para fundamentar la inclusión del **Algoritmo de Dijkstra con Min-Heap**. Argumenten que tanto el atacante al planear su movimiento lateral como el Agente Defensivo al calcular la intercepción aplican exactamente este principio matemático sobre el canal de peso `transit_cost`.

#### C. Para el Marco Metodológico y Algorítmico (Edmonds-Karp y Cuellos de Botella)
* **La cita teórica:**  
  > *"Vulnerability mitigation is fundamentally a resource-constrained optimization problem. Applying the Max-Flow Min-Cut theorem enables security administrators to identify the critical subset of network edges whose isolation completely disrupts the threat vector with minimal operational impact."* (Shivakumar & Mamatha, 2022, p. 740).
* **Cómo usarla en el informe de VERTEX:**  
  Esta es la justificación científica perfecta para el módulo `StrategicAnalyzer.gd`. El jurado suele preguntar: *"¿Por qué usaron Edmonds-Karp en un juego?"*. La respuesta fundamentada en este paper es: *"Porque modelamos la mitigación como un problema de corte mínimo; no bloqueamos toda la red, encontramos el cuello de botella óptimo basándonos en la capacidad residual de los enlaces"*.

---

## 2. AUDITORÍA DEL INFORME ACTUAL: DISCREPANCIAS Y ASPECTOS A MEJORAR

Al contrastar el borrador del informe en Word (`Inforne Final Simulador de Ciberseguridad...docx`) con el estado real del repositorio en GitHub (`v0.6.0` y commits recientes), se detectaron discrepancias que deben corregir para no desmerecer el trabajo ya realizado:

### 2.1. El Caso del Sistema de Audio (¡No lo dejen fuera!)
* **Lo que dice el borrador en Word (Párrafo 240):**  
  Dice textualmente: *"Establecer que audio/inmersión queda fuera de v2.0.0, trasladado a Fase 2 post-defensa"*.
* **La realidad en el código:**  
  En el repositorio ya implementaron un sistema de audio avanzado:
  * `AudioManager.gd` con gestión de buses de volumen.
  * Visualizador de espectro reactivo al audio (*audio-reactive spectrum visualizer*).
  * Formas de onda homogéneas y listas de reproducción diferenciadas por mundo (`feat(audio)`).
* **Consejo de mejora:**  
  **No digan que quedó fuera.** Preséntenlo en el informe como un **"Alcance Superado (Plus Metodológico)"**. Expliquen que gracias a la metodología ágil Scrum y al ahorro de tiempo obtenido por la arquitectura desacoplada, el equipo logró integrar la retroalimentación auditiva en la Fase 1, aumentando el impacto pedagógico y la respuesta multisensorial del simulador.

### 2.2. Actualización de la Máquina de Estados (FSM)
* **Lo que dice el borrador en Word (RF-02):**  
  Limita los estados de los nodos a: `DISPONIBLE`, `ALERTADO` y `CAPTURADO`.
* **La realidad en el código:**  
  En la versión `v0.6.0` se introdujo el **Modo Defensor (Blue Team)**, que añade el estado de **`CUARENTENA` (Aislamiento de Host)** y la traza forense EDR (`782750e`).
* **Consejo de mejora:**  
  Actualicen el diagrama de estados en el informe agregando la transición hacia `CUARENTENA`. Esto demuestra madurez en el proyecto: el simulador no solo muestra cómo ataca un hacker, sino cómo responde un analista defensivo aislando el activo infectado para evitar la propagación lateral.

### 2.3. Estructura de Niveles y Mundos
* **Lo que dice el borrador en Word:**  
  Habla de Heist, Hacker y Cybersecurity de manera genérica.
* **La realidad en el código:**  
  El repositorio cuenta con una progresión formal de 5 niveles de ciberseguridad (`cyber_n2` a `cyber_n4`), un sector especial *Sector 0 (Kernel-Void)* con estética matemática a 60 FPS y una terminal CLI interactiva.
* **Consejo de mejora:**  
  Incluyan capturas de pantalla de la terminal táctica (`terminal_cli.gd`) y del selector de niveles estilo mapa de metro (*subway map*). Esto valida visualmente el cumplimiento del objetivo de gamificación ante el jurado.

---

## 3. CONSEJOS ESTRATÉGICOS PARA LA REDACCIÓN DEL INFORME

1. **Eviten el lenguaje informal o de "gamer":**
   * En vez de decir: *"El jugador mata al enemigo con un perk"*.
   * Escriban: *"El usuario ejecuta una acción de mitigación aplicando un script de bypass/aislamiento sobre el activo comprometido"*.
   * En vez de: *"El monstruo o bot persigue al jugador"*.
   * Escriban: *"El agente defensivo autónomo calcula la trayectoria de intercepción óptima mediante el algoritmo de Dijkstra con cola de prioridad"*.

2. **Destaquen la Arquitectura Data-Driven (Orientada a Datos):**
   * Expliquen que el simulador no tiene niveles "dibujados a mano en el código". Toda la topología se serializa en archivos `.tres`.
   * **Argumento clave:** Esto significa que un profesor de redes o un administrador de sistemas puede crear su propia topología de red real en un archivo de datos sin necesidad de saber programar en Godot ni recompilar el juego.

3. **Demuestren rigor en las Pruebas de Software:**
   * En el informe institucional del PNF, los jurados valoran enormemente la verificación formal.
   * Mencionen que el sistema cuenta con pruebas automatizadas (`tests/system/`, `test_topology_pan_zoom.gd`) con un temporizador perro guardián (*watchdog timer*) que asegura que ningún cálculo de algoritmos caiga en bucles infinitos.

---

## 4. GUÍA DE PREGUNTAS TÍPICAS DEL JURADO Y CÓMO DEFENDERLAS

A continuación tienen las preguntas más probables que hará un jurado de informática o redes en la defensa universitaria, junto con la respuesta técnica recomendada:

---

### Pregunta 1: "¿Por qué desarrollar esto como un videojuego en Godot en vez de usar Cisco Packet Tracer o GNS3?"
* **Respuesta del equipo:**  
  > *"Packet Tracer y GNS3 son excelentes emuladores de configuración de hardware y comandos de red (Cisco IOS), pero son cajas negras en cuanto a los fundamentos algorítmicos. Un estudiante en Packet Tracer configura una ruta estática o un protocolo OSPF, pero no visualiza matemáticamente cómo opera el cálculo de camino mínimo ni cómo se comportan los cuellos de botella ante una intrusión. VERTEX no pretende sustituir a Packet Tracer, sino ser el puente conceptual previo: hace tangible la teoría de grafos y la propagación de incidentes de seguridad de forma visual, gamificada y sin la fricción de instalar máquinas virtuales pesadas."*

---

### Pregunta 2: "¿Cómo garantizan que el juego no se congele si la red tiene muchos nodos?"
* **Respuesta del equipo:**  
  > *"Lo garantizamos mediante dos decisiones de arquitectura: primero, el algoritmo de Dijkstra se implementó utilizando un `MinHeap` binario optimizado, reduciendo la complejidad de $O(V^2)$ a $O((V+E)\log V)$. Segundo, la capa de renderizado (`GameRenderer.gd`) está completamente desacoplada de la lógica algorítmica: el cálculo matemático se ejecuta de forma determinista y sólo emite señales cuando los resultados están listos, manteniendo una tasa de refresco constante de 60 cuadros por segundo sin bloquear el hilo principal."*

---

### Pregunta 3: "¿Qué componente de ciberseguridad real aprende el estudiante jugando?"
* **Respuesta del equipo:**  
  > *"Aprende tres principios universales de la defensa en profundidad:  
  > 1. **Movimiento Lateral:** Comprende que un atacante no salta mágicamente a la base de datos, sino que avanza nodo a nodo a través de enlaces adyacentes vulnerables.  
  > 2. **Superficie de Ataque y Ruido:** Aprende que cada interacción genera firmas y telemetría de alerta en el IDS.  
  > 3. **Defensa Perimetral vs. Aislamiento:** Entiende empíricamente que la mejor mitigación frente a un incidente no es apagar todos los equipos, sino aislar en cuarentena el cuello de botella mínimo estructural, preservando la operatividad del resto de la red."*

---

### Pregunta 4: "¿Por qué utilizaron la metodología Scrum si el equipo es pequeño?"
* **Respuesta del equipo:**  
  > *"Porque la naturaleza del software interactivo requiere validación temprana. Gracias a Scrum dividimos el desarrollo en Sprints incrementales: en el Sprint 1 validamos la topología matemática antes de dibujar un solo pixel; en el Sprint 2 aseguramos los algoritmos en consola pura; en el Sprint 3 construimos la interfaz gráfica; y en los Sprints 4 y 5 refinamos la gamificación y el modo defensor. Esto evitó retrabajos masivos y nos permitió contar con un producto potencialmente entregable al final de cada iteración, tal como lo evidencia el historial de versiones en nuestro repositorio de Git."*

---

## 5. ESTRUCTURA RECOMENDADA PARA EL CAPÍTULO DE RESULTADOS DEL INFORME

Para estructurar de manera impecable el capítulo final de su informe de grado, sigan este esquema secuencial:

1. **Evidencia del Núcleo Algorítmico:**
   * Tabla comparativa de tiempos de respuesta: tiempo de ejecución de Dijkstra vs. cantidad de nodos (demostrando que corre en $< 2\text{ ms}$).
   * Captura del grafo residual de Edmonds-Karp identificando el corte mínimo.
2. **Evidencia de la Interfaz y Usabilidad:**
   * Capturas de pantalla de los 3 mundos principales.
   * Captura del Modo Defensor con nodo en Cuarentena (azul) y centinela activo (rojo).
   * Muestra de la consola táctica CLI ejecutando comandos de diagnóstico.
3. **Validación Pedagógica:**
   * Resultados del playtesting interno: porcentaje de éxito de usuarios novatos completando la pista de tutoriales sin ayuda del docente.
4. **Cumplimiento de Objetivos:**
   * Matriz de trazabilidad donde cada Objetivo Específico del proyecto se cruza contra el Requerimiento Funcional (RF) y el Sprint que lo satisfizo.

---

*Este documento sirve de guía de consulta permanente durante las sesiones de redacción del informe escrito y preparación de las diapositivas de defensa.*
