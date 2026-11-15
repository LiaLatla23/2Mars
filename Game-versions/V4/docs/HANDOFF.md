# Traspaso de 2Mars V4

Para el equipo SpaceNuts. V4 continúa V3 sin rehacerla. Este documento es una **fotografía del estado de desarrollo del 15 de noviembre de 2026**, no un panel de estado actualizado automáticamente.
El relevo de V3 se conserva en `HANDOFF_V3.md`.

**Actualización posterior:** el repositorio se publicó en GitHub (`Savamg/2Mars`) y la página del proyecto está configurada en el dominio `2mars.com`. La frase «Nada se subió a GitHub, se publicó ni se desplegó» describía únicamente el momento original de redacción de esta nota.

## Cómo abrirlo y probarlo

1. Godot 4.7 estable → Importar → `Game-versions/V4/project.godot` (desde la raíz del repositorio) → F5.
2. Compilar todos los scripts: `godot --headless --path . res://tests/Compile.tscn`
3. Bot completo (unos minutos): `godot --headless --fixed-fps 60 --path . res://tests/Bot.tscn` · en español: `-- --es`
4. Una misión y las comprobaciones de V4: `-- --quick --v4`
5. Medidor de fotogramas dentro del juego: **F3**. Calidad 3D: Ajustes → Gráficos 3D (baja, media, alta; media por defecto; en baja los fondos 3D de los menús quedan fijos).

El bot usa su propio guardado (`user://2mars_bot_save.json`) y no toca partidas reales.

## Qué cambió respecto a V3

| Tema | V3 | V4 |
|---|---|---|
| Rover | Dibujo 2D (`Art.rover`) | Modelo 3D por piezas (`rover3d.gd`): cada pieza instalada tiene su malla; ruedas que giran y viran, suspensión, mástil, brazo, taladro, antena |
| Exploración | Campo 2D | Terreno 3D con relieve, rocas, sombras, polvo y cámara ortográfica inclinada (`world3d.gd`). Las reglas siguen en `ops.gd` |
| Globo de Marte | Shader 2D | Malla 3D con cámara ortográfica; marcadores 2D encima |
| Interfaz | Texto y paneles | Tarjetas ilustradas, iconos, medallas, barras y cifras animadas |
| Movimiento | Tweens sueltos | `motion.gd`: muelle por control, sin colas; imán leve, brillo, entradas escalonadas, movimiento reducido |
| Mejoras | No había | Ocho mejoras con efecto real, guardadas, pagadas con puntos de ciencia |
| Base en Marte | No había | Segunda base, abierta al primer aterrizaje |
| Inventario científico | Dos columnas de texto | Cuadrícula de rocas, instrumentos, zonas e historias con progreso medido |
| Informe | Texto denso | Medalla de nota, seis dimensiones animadas, hallazgos, tres consejos; el análisis completo en «Detalles y fórmulas» |
| Música | Un tema | Cuatro temas con fundido cruzado según el contexto |
| Vídeo | Ninguno | Clip de lanzamiento, con marca visible |
| Avisos | Tapaban títulos | Zona reservada por pantalla; uno a la vez |

Partidas: mismo archivo y misma carpeta de usuario (`ToMars`). Las de V3 cargan; los campos nuevos (`upgrades`, `discoveries`, `quality`) empiezan vacíos.

## Dónde está cada cosa (lo nuevo)

| Tema | Archivo |
|---|---|
| Rover 3D por piezas, animaciones, resaltar y ensamblar | `scripts/rover3d.gd` |
| Primitivas con contorno, rocas, terreno, globo | `scripts/geo3d.gd` |
| Escenarios: taller, paisaje de Marte, globo; órbita y zoom | `scripts/stage3d.gd` |
| Mundo 3D de la exploración (solo presentación) | `scripts/world3d.gd` |
| Sistema de movimiento | `scripts/motion.gd` |
| Tarjetas, iconos, cifras, barras | `scripts/ui.gd` (sección V4) |
| Mejoras: datos y reglas | `scripts/data.gd` (`UPGRADES`, `up`, `heater_w`, `pass_length`, `direct_rate`) |
| Mejoras, inventario, música, calidad | `scripts/game.gd` |
| Pantalla de mejoras | `scripts/screens/upgrades.gd` |
| Herramientas | `tools/` (abajo) |

Balance: `Data.MODEL`, `Data.COMPONENTS`, `Data.ZONES`, `Data.limits`, `Data.UPGRADES`.
Luz de las escenas 3D: `world3d.gd` (`SUN_DAY`, `AMBIENT_DAY`) y `stage3d.gd`. Se calibró midiendo el color renderizado del suelo contra el color de la paleta.

## Herramientas (`tools/`)

| Comando | Para qué |
|---|---|
| `godot --path . res://tools/Shots.tscn -- --screen=hub --out=CARPETA [--es] [--progress] [--steps=…]` | Capturas del juego real; con `--write-movie` graba vídeo. Pasos: `shot`, `wait:N`, `go:pantalla`, `call:método:arg`, `move:x:y`, `click`, `drive:N`, `perf:N` |
| `godot --path . res://tools/Thumbs.tscn` | Regenera `assets/parts` y `assets/rocks` desde el modelo 3D (necesita pantalla) |
| `godot --path . res://tools/Preview.tscn -- --scene=workshop|vista|full` | Render de un escenario |
| `python3 tools/make_audio.py SALIDA` | Sintetiza música y efectos; luego `ffmpeg -i x.wav -c:a libvorbis -q:a 4 x.ogg` |
| `python3 tools/mark_si_icons.py [--logo] [--undo]` | Marca «SI» visible en los iconos si el equipo confirma que son generados |

## Pruebas y rendimiento

- Compilación: 29 scripts, 0 fallos. Bot completo: 212 comprobaciones, 0 fallos, en inglés y en español (V3: 188). `--quick --v4`: 104, 0 fallos.
- Rendimiento medido **solo con render por software** (llvmpipe, 2 núcleos, sin GPU) a 1280×720: exploración 227,8 ms en alta, 210,0 ms en media y 48,3 ms en baja; base 209,4 ms en alta y 43,9 ms en baja; progreso 332,7 ms en alta y 55,0 ms en baja. No representa un equipo con tarjeta gráfica y no demuestra 60 FPS.
- Detalle y lista de pendientes: `PROMPT-CONTINUAR-2Mars-V4.md`, en la raíz del ZIP.

## Lo que falta, por orden de valor

1. **Confirmar la procedencia** del logotipo, la hoja de iconos y el vídeo, y aplicar la regla de marca visible (`RESOURCE_AUDIT.md`, sección 1).
2. **Playtesting y audio.** Integrantes del equipo ya jugaron manualmente partidas completas de V4. Esto valida el flujo interno, pero no sustituye pruebas externas con estudiantes ni una evaluación de aprendizaje. La música todavía debe escucharse y revisarse en condiciones normales.
3. **Medir el rendimiento en un equipo con GPU** (F3). Aquí solo hubo render por software.
4. **Probar con mando.** Está mapeado, no probado.
5. Tutorial: demostración animada por paso.
6. Clips de crucero y aterrizaje.
7. Pantalla de guardados con emblemas y progreso más visuales.
8. Verificar con la NASA las historias de Spirit y de la limpieza de paneles, y reabrir las páginas que no se pudieron consultar.
9. En los guiones de vídeo, corregir «datos de Curiosity e InSight»: el juego cita Mars 2020 Perseverance.

## Decisiones de V4 que el equipo puede revertir

- Las mejoras se pagan con puntos de ciencia (lo mejor recibido en la Tierra por zona, menos lo invertido). No hay moneda nueva ni producción pasiva.
- Las mejoras no se aplican en Sandbox.
- El tiempo de misión no corre mientras se elige un instrumento (igual que en el tutorial).
- La banda X directa real se muestra como 160-500 bps (NASA Glenn), no «hasta 3.000 bps».
- El vídeo de lanzamiento lleva la marca «SI» sin que su procedencia esté confirmada.
- La versión del proyecto pasa de `2.0.0` a `4.0.0`.
- Calidad 3D media por defecto.
- El relieve del terreno es solo visual; no cambia velocidad ni energía.
