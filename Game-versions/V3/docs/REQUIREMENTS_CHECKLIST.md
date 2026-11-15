# Lista de requisitos → implementación → evidencia

2Mars V3 · Equipo SpaceNuts · Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.

Estado: **Hecho** = implementado y comprobado por el bot de pruebas o por captura revisada · **Parcial** = funciona, con el alcance que se indica · **Pendiente** = no implementado.
"Bot" se refiere a `tests/bot.gd` (188 comprobaciones, en inglés y en español, con Godot 4.7 estable en modo headless a 60 fps fijos).

## Secciones 1-26 del brief

| § | Requisito | Dónde está | Evidencia | Estado |
|---|---|---|---|---|
| 1 | Trabajar sobre el proyecto existente, sin rehacerlo ni publicar | Copia de `to-mars-game.zip`; mismos `Main.tscn`, autoload `Game`, kit `UIK`, arte `Art` | El proyecto abre en Godot 4.7; nada se subió a GitHub | Hecho |
| 2 | Usar los materiales fuente | Excel, PDF de mejoras, guion de la Dra. Owen, rúbrica, 22 referencias, logo, hoja de iconos | Ver secciones 27-30 | Hecho. El DOCX `ToMars_Contexto_Maestro…` no está en el proyecto: no se usó |
| 3 | Identidad 2Mars, paleta, sistema de diseño, movimiento reducido | `project.godot`, `scripts/ui.gd`, `scripts/art.gd`, `scripts/screen.gd` | Capturas 01-53 | Hecho. Sin partículas ni parallax; un shader (globo) |
| 4 | Flujo de misión conectado en 10 pasos | `scripts/screens/*` | Bot «First mission, full flow» (80 comprobaciones) | Hecho |
| 5 | Dra. Owen, guion, «¡Espera!», ES/EN | `briefing.gd`, `design.gd`, `transit.gd`, `ops.gd`, `debrief.gd`, `Data.STORIES` | Bot: historia registrada y logro oculto | Hecho. Las líneas del «Dr. Vega» del guion las dice la Dra. Owen |
| 6 | Briefing, nombres, seis factores, planificación | `briefing.gd`, `plan.gd`, `Data.PROFILES/WINDOWS/SITES/PRIORITIES` | Bot: nombres guardados; la ventana cambia presupuesto y tiempo | Hecho |
| 7 | Ingeniería con consecuencias reales | `Data.COMPONENTS`, `Data.stats`, `design.gd`, `ops.gd` | Bot «Engineering data» y «Two contrasting rovers» | Hecho. Sin diagramas; comparativa antes/después y medidores animados |
| 8 | Mission Readiness en cuatro categorías | `Data.check`, `Data.readiness_index`, `design.gd` | Bot: bloqueo PIXL sin brazo y su arreglo | Hecho |
| 9 | Lanzamiento, crucero con dos eventos, aterrizaje | `transit.gd` | Bot: decisiones con efecto; saltar llega al estado correcto una vez | Hecho |
| 10 | Exploración: zonas, terreno, fotos multiángulo, muestra fallida | `ops.gd`, `Data.ZONES`, `Data.ROCKS` | Bot zonas: evento de muestra fallida en Margen del delta | Hecho |
| 11 | Energía, datos y comunicaciones conectados | `ops.gd` (`simulate`, `draw_link_panel`, `show_data`) | Bot: memoria llena, sin enlace, modo seguro | Hecho |
| 12 | Misión más corta; requeridos y opcionales | `ops.gd` (`show_required_done`), `Data.ZONES` | Bot: termina antes del límite al cumplir los requeridos | Hecho |
| 13 | Recomendaciones adaptativas | `Data.recommendations`, `hub.gd`, `progress.gd`, `debrief.gd` | Bot «Adaptive recommendations» | Hecho |
| 14 | Informe final estructurado | `debrief.gd` | Bot: seis dimensiones, causas, datos coherentes | Hecho. Imágenes: enlace a las fotos reales de la NASA, no imágenes incrustadas |
| 15 | Cooperativo local de dos jugadores | `screen.gd` (`coop_gate`), `plan.gd`, `design.gd`, `ops.gd`, `hub.gd` | Bot «Local co-op» (10 comprobaciones) | Hecho. Mando mapeado pero sin probar |
| 16 | Sandbox con guardado separado | `design.gd`, `game.gd` (`sandbox`), `ops.gd` | Bot «Sandbox» (10 comprobaciones) | Hecho |
| 17 | Progresión de empresa (alcance acotado) | Hangar de rovers guardados, inventario científico, desbloqueo de zonas | Capturas 42 y 09 | Parcial. Sin financiación, mejoras, flota ni desgaste |
| 18 | 3D interactivo donde aporte | `shaders/globe.gdshader`, `zones.gd`, visor en `design.gd` | Bot: el globo gira con la entrada | Parcial. Globo en tiempo real y visor rotable, ambos 2D; no es 3D |
| 19 | Modos de entrada y accesibilidad | `boot.gd`, `settings.gd`, `ui.gd`, `ops.gd` | Bot: confirmaciones por teclado; capturas en tres tamaños | Hecho. Escala uniforme con franjas en proporciones distintas de 16:9 |
| 20 | Higgsfield y assets visuales | Ver `CINEMATICS_HIGGSFIELD.md` | — | Ver ese documento |
| 21 | Sonido y controles de audio | `assets/audio/*.wav`, `game.gd` (`sfx`), `settings.gd` | 12 efectos distintos; tres volúmenes y silencio | Hecho |
| 22 | Integridad científica y trazabilidad | `Data.REAL_FACTS`, `Data.TRACE`, `library.gd` | `SCIENCE_TRACEABILITY.md` | Hecho |
| 23 | Prioridades P0 → P1 → P2 | — | P0 completo; P1 completo salvo cinemáticas de Higgsfield; P2 parcial | Hecho / Parcial |
| 24 | Pruebas del juego real | `tests/bot.gd`, `tests/compile.gd` | 188 de 188 en EN y en ES | Hecho |
| 25 | ZIP completo e informe | `2mars-game-V3.zip` | Extracción limpia probada (misión completa con el bot) | Hecho. Falta el informe final en el chat |
| 26 | Estándar final | — | Nadie ha jugado V3 a mano: lo comprobó un bot y se revisaron capturas | Parcial |

## Sección 27 · decisiones de consolidación

| Punto | Resultado |
|---|---|
| Fuente del juego | `to-mars-game.zip` (idéntico a `Game-versions/V1/V1-2Mars`). Godot 4.7 confirmado: la línea base pasó 111 de 112 comprobaciones de su bot |
| V2 de otra sesión | V3 parte de V1 e implementa por su cuenta lo que V2 añadió. El parche de V2 no se fusionó línea a línea |
| `Space Nuts.zip`, `Game Style References.zip` | Tableros de inspiración con imágenes de terceros: guía de estilo, no assets |
| `2MARS 1.xlsx` | Leído completo: 3 hojas, 30 componentes |
| PDF de mejoras (26 págs.) | Texto completo y capturas anotadas de las págs. 11-15 |
| Guion de la Dra. Owen (7 págs.) | Las cinco fases |
| Rol de Codex y Claude | Esta sesión solo implementó. No hubo traspaso automático a otro agente |

## Sección 28 · las 22 referencias visuales

| Ref. | Qué pide | Dónde | Estado |
|---|---|---|---|
| 1, 7 | Menú con marca; Continuar para quien vuelve | `menu.gd` | Hecho |
| 2 | Logros con detalle y progreso real | `achievements.gd` (17 logros reales) | Hecho |
| 3 | Archivos de guardado con resumen real | `profiles.gd` | Hecho |
| 4 | Nombre y emblema del equipo | `profiles.gd` (6 emblemas) | Hecho |
| 5 | Cómo se juega y objetivos | `briefing.gd`, paso 4 | Hecho |
| 6 | Introducción animada al taller y tutorial | Tutorial de 4 pasos en `design.gd` | Parcial: guiado, sin animación de entrada |
| 8, 9 | Carga y marca con porcentaje real | `boot.gd` | Hecho |
| 10 | Base terrestre | `hub.gd` | Hecho. Sin botón «Upgrade»: no hay mejoras |
| 11, 12 | Bienvenida al diseño; límites | Líneas de la Dra. Owen y medidores | Hecho. No se copiaron las cifras de ejemplo |
| 13, 14 | Rover nuevo o guardado; inspeccionar y girar | Hangar y visor en `design.gd` | Parcial: es un diálogo, no una pantalla propia |
| 15, 16 | Categorías y piezas; guardar diseño | 7 categorías, 12 grupos, 30 piezas | Hecho. Sin protección térmica ni antipolvo: no están en el libro |
| 17 | Inventario científico | `progress.gd` | Parcial |
| 18 | Mejoras con costo y efecto | — | Pendiente. No hay botones sin efecto |
| 19 | Preparación del despliegue | `transit.gd` | Hecho. El índice explica su cálculo; el 76 % del boceto no se copió |
| 20 | Base en Marte | — | Pendiente. Hay una sola base |
| 21 | Globo de Marte interactivo | `zones.gd` | Hecho (2D en tiempo real) |
| 22 | Misiones por región con opcionales | Panel de zona en `zones.gd` | Hecho |
| Hoja de iconos | Familias de iconos como assets individuales | 16 iconos vectoriales en `Art.icon`, insignias de nota y emblemas | Parcial. No se exportaron los iconos de la hoja. Minerales, materiales procesados, cajas y mejoras no tienen mecánica en el juego |

## Sección 29 · tutorial y comprensión

| Requisito | Dónde | Estado |
|---|---|---|
| Elegir idioma y entrada; nombres | `boot.gd`, `profiles.gd`, `briefing.gd` | Hecho |
| Taller: pieza real, vista previa, comparar, instalar; el paso se completa con el evento real | `design.gd` (`COACH`) | Hecho |
| Resolver un bloqueo real | Mission Readiness con arreglo en un clic | Hecho |
| Decisiones de crucero y aterrizaje con consecuencia | `transit.gd`, informe de aterrizaje | Hecho |
| Marte: conducir, acercarse, fotografiar, analizar, transmitir | `ops.gd` (6 pasos) | Hecho. La toma de muestras se enseña con el evento, no con un paso |
| Saltar, reanudar, no bloquear, no premiar dos veces | `end_coach`, `ops_step` guardado | Hecho |
| Repetir el tutorial | Ajustes → «Repetir tutoriales» | Hecho |
| El tutorial no gasta tiempo de misión | `tutorial_time` | Hecho |
| Preguntas claras: evidencia, término, una pregunta, por qué, reintento | `Data.QUIZ`, `ops.gd` (`ask`, `answer`) | Hecho |
| Ayuda de teclas con Esc y botón | Barra de acciones, pausa, «Controles» | Hecho |
| Lista de misión, minimapa, recursos | `draw_hud` | Hecho |
| Avisos de atribución fuera del pie de pantalla | Biblioteca → Fuentes y créditos | Hecho |

## Sección 30 · libro de ingeniería

| Corrección pedida | Cómo se aplicó |
|---|---|
| Totales del rover, no del catálogo | `Data.mass` y `Data.cost` suman solo lo instalado |
| Generación y consumo separados | `gen_w` para solar y RTG; `idle_w` y `drive_w` para cargas |
| W, Wh y tiempo coherentes | 1 s de juego = 10 min de misión; Wh = W × horas |
| Memoria aparte de la batería | `battery` en Wh, `memory` en MB |
| Capacidades que el libro no trae | `Data.MODEL`, marcado como modelo de juego |
| `NASA_Based` no certifica cifras | Texto en el taller y en la biblioteca; ejemplo del RTG |
| Compatibilidad real | PIXL, SHERLOC y taladro piden brazo; AutoNav pide computadora avanzada; cubierta de 4 u 8 cargas |
| Seis dimensiones y Retorno de datos | `ops.gd` (`finish`), `debrief.gd`; «no aplica» sin datos |

Las 30 piezas están en el taller y todas tienen efecto en el juego (`Data.EFFECTS`).

## Sección 31 · animación

| Movimiento pedido | Estado |
|---|---|
| Marte girando en menú y mapa | Hecho |
| Estados hover, foco y pulsado | Hecho |
| Selección de pieza: sonido, marca, medidores con diferencia | Hecho. Sin animación de ensamblaje |
| Cuenta atrás, lanzamiento, crucero, entrada, paracaídas, descenso, contacto | Hecho (nativo, saltable) |
| Ruedas y suspensión animadas | Pendiente (el brazo se balancea) |
| Instrumentos, muestreo, transmisión, hallazgo, informe | Hecho |
| Retrato de la Dra. Owen animado | Hecho |

## Sección 32 · evidencia

Este documento, `SCIENCE_TRACEABILITY.md`, `RUBRIC_MAPPING.md`, `HANDOFF.md`, el bot y las capturas.
