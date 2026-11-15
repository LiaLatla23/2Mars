# Traspaso de 2Mars V3

Para Codex y el equipo SpaceNuts. Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.

## Qué es esta carpeta

El proyecto completo de Godot 4.7 de 2Mars V3. Parte de `to-mars-game.zip` (V1) y conserva su estructura: `scenes/Main.tscn`, el autoload `Game`, el kit de interfaz `UIK`, el arte por código `Art`.

Nada se subió a GitHub ni se publicó. Decidir si V3 sustituye a V2 en `Game-versions/` es cosa del equipo.

## Cómo abrirlo y probarlo

1. Godot 4.7 estable → Importar → `project.godot` → F5.
2. Pruebas automáticas (188 comprobaciones, unos minutos):
   `godot --headless --path . --fixed-fps 60 res://tests/Bot.tscn`
   En español: añadir `-- --es`.
3. Solo compilar todos los scripts: `godot --headless --path . res://tests/Compile.tscn`

El bot usa su propio archivo de guardado (`user://2mars_bot_save.json`) y no toca las partidas reales.

## Partidas guardadas

- V3 guarda en `user://2mars_save.json`: tres archivos y el Sandbox aparte.
- `project.godot` fija la carpeta de usuario en `ToMars` para que, aunque el juego se llame 2Mars, siga leyendo la carpeta de V1.
- Una partida de V1 (`tomars_save.json`) se importa sola al archivo 1 y el rover antiguo se convierte al modelo nuevo de piezas.
- **V2** renombró el proyecto sin fijar la carpeta: sus partidas están en otra carpeta de usuario y V3 no las lee.

## Dónde está cada cosa

| Tema | Archivo |
|---|---|
| Las 30 piezas, zonas, instrumentos, preguntas, logros, fuentes | `scripts/data.gd` |
| Estado, guardado, idioma, entrada, audio | `scripts/game.gd` |
| Paleta y componentes de interfaz | `scripts/ui.gd` |
| Arte vectorial | `scripts/art.gd` |
| Base común de pantallas, Dra. Owen, confirmación cooperativa | `scripts/screen.gd` |
| Ajustes | `scripts/settings.gd` |
| Pantallas | `scripts/screens/*.gd` |
| Pruebas | `tests/bot.gd`, `tests/compile.gd` |

Para cambiar el balance: `Data.MODEL`, `Data.COMPONENTS`, `Data.ZONES` y `Data.limits`.

## Lo que falta, por orden de valor

1. **Que lo juegue una persona.** El balance y la duración se ajustaron con un bot, que es más rápido que un jugador nuevo.
2. **Verificar las cifras de las historias de la Dra. Owen** con páginas de la NASA (lista en `SCIENCE_TRACEABILITY.md`).
3. **Cinemáticas de Higgsfield**: guiones y nombres de archivo en `CINEMATICS_HIGGSFIELD.md`.
4. **Probar con mando.** Está mapeado, no probado.
5. Corregir en los guiones de vídeo la frase sobre datos «de Curiosity e InSight».
6. Fuera de alcance en V3: tienda de mejoras, flota y economía de empresa, base en Marte, 3D real, iconos exportados de la hoja, animación de ruedas, imágenes de la NASA dentro del juego.

## Decisiones tomadas en esta sesión que el equipo puede revertir

- Una sola guía: la Dra. Owen dice también las líneas que el guion daba al «Dr. Vega».
- El logro «Night shift» pasó a llamarse «Power under control».
- Los límites de masa y presupuesto son del modelo de juego; no se copiaron las cifras de los bocetos.
- La nota S o A exige todos los objetivos requeridos; con menos de la mitad, la nota máxima es C.
