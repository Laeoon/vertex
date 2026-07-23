MEMORY: Proyecto VERTEX — Snapshot y próximos pasos
=================================================

Resumen rápido
--------------
- Proyecto: Simulador de Ciberseguridad (VERTEX)
- Branch de trabajo actual (local): feat/main-menu-worlds
- Estado: Menú principal implementado (estilo _draw()), submenu de mundos, selector de idioma, placeholders para Options/Profile/Database, i18n (es/en/pt), LocaleManager añadido como autoload.
- Tests existentes (tutorials & ataque) siguen pasando localmente.

Objetivo inmediato
------------------
- Añadir .mimoignore para evitar subir assets binarios y caches.
- Añadir este fichero MEMORY.MD para documentar el estado del proyecto y permitir continuidad del desarrollo.

Antecedentes y forma de trabajo
------------------------------
- Motor: Godot 4.x, lenguaje: GDScript.
- Estilo de trabajo: cambios pequeños y verificables, commits atómicos con mensajes claros.
- Arquitectura: uso de autoload singletons (SceneParams, Events). Se añadió LocaleManager como autoload para i18n.
- UI: se usan Canvas drawing routines (_draw()) para mantener estética neon/cyberpunk; preferimos no mezclar demasiadas capas de abstracción innecesarias.
- Señales: la UI emite señales (ej. start_world(world_id)) y un GameManager central debe encargarse de las transiciones de escena.
- Tests: se ejecutan mediante lanzamiento headless de escenas con Godot.

Qué hay hasta ahora (archivos clave)
-------------------------------------
- Escenas / scripts:
  - res://escenas/main_menu.tscn
  - res://escenas/main_menu.gd         (nuevo menú con submenu y signal start_world)
  - res://escenas/main_menu/tutorials_menu.tscn
  - res://escenas/main_menu/tutorials_menu.gd
  - res://escenas/menu/options.tscn, options.gd
  - res://escenas/menu/profile.tscn, profile.gd
  - res://escenas/menu/database.tscn, database.gd
- i18n:
  - res://core/locale/es.json
  - res://core/locale/en.json
  - res://core/locale/pt.json
  - res://core/locale/locale_manager.gd (y .tscn) — ahora autoload
- Autoloads (project.godot):
  - Events (res://core/autoloads/events.gd)
  - SceneParams (res://core/autoloads/scene_params.gd)
  - LocaleManager (res://core/locale/locale_manager.tscn) — añadido durante la última iteración
- Gameplay params:
  - res://core/autoloads/scene_params.gd (API para parametrizar escenas de juego antes de cargar)

Mapeo recomendado de mundos
---------------------------
- "heist"         -> res://escenas/worlds/heist_placeholder.tscn
- "hacker"        -> res://escenas/worlds/hacker_placeholder.tscn
- "cybersecurity" -> res://escenas/worlds/cybersec_placeholder.tscn
- "tutorials"     -> res://escenas/main_menu/tutorials_menu.tscn  (o res://juego/tutorials/ si se prefiere)

Verificación local rápida
-------------------------
1. Cargar main menu (headless) para comprobar que no hay errores de carga:
   godot --headless --scene res://escenas/main_menu.tscn --quit

2. Ejecutar tests existentes (ejemplos):
   godot --headless --scene res://juego/tutorials/test_tutorial_system.tscn --quit
   godot --headless --scene res://juego/ataque/test_restart.tscn --quit

3. Probar cambio de idioma: ejecutar la escena y presionar LEFT/RIGHT (el menú implementa ciclo de idioma y persiste en user://settings.cfg).

Comandos sugeridos para crear/commitear (se ejecutaron localmente por el agente)
-----------------------------------------------------------------------
# crear archivos (ejemplo):
printf ".godot/\n.import/\n*.translation\n*.png\n*.jpg\n*.svg\n*.wav\n*.ogg\n*.mp3\n*.uid\n" > .mimoignore

# añadir y commitear localmente (ya se hizo en feat/main-menu-worlds):
git add .mimoignore MEMORY.MD
git commit -m "chore: add .mimoignore and MEMORY.MD (project memory file)"

Notas sobre commits y branches
-----------------------------
- Branch actual de trabajo (local): feat/main-menu-worlds
- Convención de commits: tipo(scope): descripción breve. Ej: feat(menu): add world select submenu
- Hacer commits pequeños y revertibles; subir (push) y abrir PR cuando la funcionalidad esté completa y revisada.

Próximos pasos recomendados
---------------------------
1. Implementar GameManager/Loader que escuche la señal start_world y haga la transición de escena, validando SceneParams.
2. Crear placeholders finales de escenas de mundos y conectar a GameManager.
3. Añadir tests unitarios específicos del menú: presencia de botones, emisión de start_world, persistencia de idioma y perfil.
4. Integrar música/animación en una iteración posterior (placeholders ya añadidos y no interfieren).
5. Revisar pipeline de assets y confirmar qué extensiones ignorar en .mimoignore.

Dónde hacer el commit / remoto
------------------------------
- Commit local: branch feat/main-menu-worlds (ya creado y usado por este agente).
- Remoto: no se especificó el remote URL; cuando indiques el remoto/permiso puedo preparar push y PR.

Contacto rápido: Si quieres que suba la rama al remoto o abra un PR, indícame el remote (por ejemplo "origin") y la rama de destino (por ejemplo "develop") y lo hago.
