# Feature: Backup & Restore de Ranuras de Guardado (Save Slots)
Subsistema de copias de seguridad, snapshots preventivos automáticos e importación/exportación de archivos .bak para VERTEX (Godot 4.7.2).
Entrega formal académica y soporte para resiliencia ante pruebas destructivas.

## Specs
- S1: "Snapshots automáticos preventivos en user://slots/slot_X/backups/ con rotación automática (máximo 5 copias) y función de restauración del snapshot más reciente."
- S2: "Función export_slot_to_bak(slot_id, target_path) que serializa de forma atómica profile.cfg, progress.cfg y stats.cfg con cabecera mágica VERTEX_SAVE_BAK_v1 y suma de verificación sha256."
- S3: "Función import_bak_to_slot(bak_path, target_slot_id) que valida integridad de cabecera y checksum, crea un snapshot preventivo de contingencia del slot destino antes de escribir, e importa los datos invalidando la caché."
- S4: "Interfaz en StartScreen (start_screen.gd) que permite [E] Exportar partida, [I] Importar partida .bak y [R] Restaurar snapshot preventivo, con modal de confirmación de sobrescritura y feedback visual en pantalla."
- S5: "Suite de pruebas automatizadas tests/system/test_slot_backup_restore.gd que verifique el ciclo completo de backup, exportación, detección de archivos corruptos y restauración limpia en modo headless."
- S6: "Documentación formal del caso de uso CU-11 (Respaldar, Exportar e Importar Ranuras de Guardado) en documentacion/diagramas/especificacion_casos_de_uso.md bajo estándar UML 2.5."

## Tasks
- [x] T1 (S1, S2, S3) [worker]: Extender SlotManager con lógica de snapshots preventivos, rotación, exportación e importación .bak con checksum.
- [x] T2 (S5) [worker]: Crear suite de pruebas automatizadas tests/system/test_slot_backup_restore.gd y registrarla en el runner.
- [x] T3 (S4) [worker]: Implementar controles de Backup & Restore y diálogos de confirmación/notificación en StartScreen.
- [x] T4 (S6) [worker]: Agregar especificación formal del caso de uso CU-11 en especificacion_casos_de_uso.md.
- [x] T5 (S1-S6) [verify]: Ejecutar la suite global de tests automatizados de Godot headless garantizando cero regresiones.

## Log
- L1: "vamos con eso" (Usuario autoriza la ejecución del Pilar 1: Sistema de Backup & Restore de ranuras de guardado).
- L2: "que se me olvidaba, eres orquestador, delega a subagentes, crea un perfil con los agentes a usar. ya te paso los modelos disponibles" (Configurado perfil global con Sonnet 5.5, Opus 5.5 y Gemini 3.8 Flash).
