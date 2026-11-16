# Auditoría de recursos, NASA y atribución · 2Mars V4

Equipo SpaceNuts · NASA Space Apps Challenge 2026 · *Space Mission Design Game*.
Auditoría inicial hecha el **15 de noviembre de 2026** sobre V4. **Actualización documental:** se incorporó la confirmación posterior del equipo sobre las herramientas de producción y el playtesting; esta actualización no implica que se hayan vuelto a inspeccionar los archivos binarios.

Estados usados: **Integrado** (está dentro del juego) · **Consultado** (se leyó y respalda un texto o una regla) · **Previsto** (aparece en planes; no está en el juego) · **No verificado** (no se pudo comprobar en esta sesión).
«Verificado hoy» significa que la fuente se abrió o se buscó el 15-11-2026 y el dato coincide. Lo que no se pudo abrir desde esta sesión se dice así; no se da por bueno.

---

## 1. Pendientes de atribución y licencia (lo primero que debe resolver el equipo)

| # | Asunto | Por qué importa | Acción concreta |
|---|---|---|---|
| 1 | **Hoja de iconos e imágenes de interfaz** (`assets/icons/`) | El equipo confirma que los visuales del juego se generaron con Claude, a partir de referencias de estilo y dirección visual preparadas en Canva. La guía de SI exige la identificación visible correspondiente en imágenes generadas. | La procedencia ya está confirmada; revisar la hoja original y cada exportación para comprobar que la marca «SI» sea visible donde corresponde. Declarar Claude y Canva en el formulario. |
| 2 | **Logotipos SpaceNuts y 2Mars** (`assets/brand/logo_2mars.png` y archivos de identidad) | El equipo confirma que ambos logotipos se generaron con ChatGPT. | La procedencia está confirmada; revisar los archivos finales para verificar la identificación visible de generación SI exigida por las reglas del evento y declararlo en el formulario. |
| 3 | **Animación de despegue y animaciones del rover** (`assets/video/launch.ogv` y animaciones integradas) | El equipo confirma que Higgsfield se utilizó para la animación de despegue y otras animaciones del rover. La inspección binaria original no permitió verificar metadatos de procedencia. | La herramienta ya está confirmada por el equipo; conservar la atribución y comprobar que los clips generados tengan la identificación visible SI exigida. |
| 4 | **Efectos de sonido heredados de V3** (`good, bad, data, link, done, bump, warn, launch`) | V3 los declara «sintetizados para el juego», pero el programa que los generó no venía en el ZIP. | Aceptar la declaración de V3 o regenerarlos con `tools/make_audio.py`. |
| 5 | **Páginas de la NASA no reabiertas en V4** (Science Objectives, Science Instruments, Rover Components, Mars Rock Samples, Landing Press Kit, First Sample Attempt) | Desde esta sesión `science.nasa.gov` no se pudo abrir. Sus datos vienen del Prompt Maestro y de la verificación de V3. | Abrir cada enlace y comprobar las cifras de la sección 4 antes de enviar. |
| 6 | **Tasas de 800/3000 bps con antenas de 70 m** | Solo constan en arXiv 2211.14245 (artículo de revisión; no es una fuente de la NASA). | Ya no se muestran como dato de la NASA: el juego usa 160-500 bps (NASA Glenn). Solo inspiran el texto de la mejora «Tiempo de antena grande». |
| 7 | **Coordenadas de los lugares del globo** (Jezero 18,4° N 77,5° E; Gale; Olympus Mons; Valles Marineris) | Valores públicos aproximados, no contrastados con una fuente primaria en esta sesión. | Comprobar en NASA Mars Trek si se van a citar como dato. |
| 8 | **Estado del trabajo de Higgsfield** `79a5cb52-7cea-4ebd-84e4-61f15bced98f` | Dato histórico de V3 («en cola, 0 créditos»). No se consultó en esta cuenta. | Consultarlo desde la cuenta que lo lanzó. |

---

## 2. Reglas oficiales de SI (IA) y de envío, comprobadas

| Regla | Texto pertinente | Fuente y fecha de consulta |
|---|---|---|
| El envío cierra el domingo 15 de noviembre a las 23:59, hora local | «Project submission … closes on Sunday, November 15 at 11:59 PM local time.» | https://www.spaceappschallenge.org/2026/ · 15-11-2026 |
| La SI está permitida y hay que declararla | «We require that you clearly indicate where and how SI tools were utilized in your project» | https://www.spaceappschallenge.org/resources/project-submission-guide/ · 15-11-2026 |
| Imágenes y vídeos generados | «Images and videos: Must include a visible watermark to indicate SI generation.» | Misma guía · 15-11-2026 |
| Audio generado | «Audio: Must acknowledge SI generation in descriptive text and metadata.» | Misma guía · 15-11-2026 |
| Sin marcas de la NASA en lo generado | «Generated content may not use, contain, or modify any NASA branding or design elements (such as the NASA logos, flags, or mission identifiers).» | https://github.com/nasa/spaceapps/discussions/2123 (equipo organizador, 14-11-2026) · 15-11-2026 |
| Al menos un recurso de la NASA para la evaluación global | «for your project to be eligible for Global Judging, your team must use at least one NASA resource» | Misma discusión · 15-11-2026 |
| Citar todo lo externo | Casilla de confirmación: todos los recursos externos (código, texto, imágenes) van en el campo *References* | https://www.spaceappschallenge.org/resources/judging-awards-guide/ · 15-11-2026 |
| Vídeos y documentos por enlace público | La página del proyecto admite imágenes (JPG, PNG, GIF hasta 10 MB); vídeos y documentos van por enlace sin inicio de sesión | Guía de envío · 15-11-2026 |

**No verificado:** el formato exacto de las tablas «Resources» y «NASA Data» (`Link Text | Link Url`) viene del encargo del equipo; no se vio en la guía. Comprobarlo en el formulario antes de llamarlo requisito.

**Cumplimiento actual, con su evidencia:**
- El juego no muestra logotipos, banderas ni identificadores de la NASA (revisadas las capturas de V4 y los cuatro fotogramas del vídeo).
- El vídeo integrado lleva marca visible. Las imágenes cuya procedencia no está confirmada **no** llevan marca: es el pendiente 1 y 2.
- La música lleva metadatos que describen cómo se hizo; no es audio generado por un modelo.
- No se afirma cumplimiento global: depende de los pendientes 1 a 3.

---

## 3. Inventario verificable

La lista consolidada de las 11 fuentes NASA/JPL que aparecen en la biblioteca del juego, las fuentes adicionales de planificación y las limitaciones de integración está en [NASA_RESOURCES_USED.md](../../../research/NASA_RESOURCES_USED.md). Esta auditoría conserva la evidencia detallada de V4.

### 3.1 Recursos científicos

| Nombre exacto | Organización | URL pública | Tipo | Contribución concreta | Dónde se usa | Estado | Licencia / atribución | Evidencia |
|---|---|---|---|---|---|---|---|---|
| Mars 2020 Perseverance · Science Objectives | NASA Science | https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/ | Documentación de misión | Cuatro objetivos → cuatro zonas de campaña | `Data.ZONES[*].nasa`, Panel de misiones, Biblioteca | Consultado (V3) · no reabierto en V4 | Texto citado con enlace | `Data.SOURCES[0]`, `Data.TRACE` |
| Mars 2020 Perseverance · Science Instruments | NASA Science | https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/ | Documentación de misión | Qué mide cada instrumento; PIXL y SHERLOC en el brazo; WATSON es cámara de SHERLOC | `Data.INSTRUMENTS[*].real`, reglas de compatibilidad, Biblioteca | Consultado (V3) · no reabierto en V4 | Texto citado con enlace | `Data.SOURCES[1]` |
| Mars 2020 Perseverance · Rover Components | NASA Science | https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/ | Documentación de misión | MMRTG ~110 W, rocker-bogie, brazo 2,1 m, 43 tubos | `Data.REAL_FACTS`, Biblioteca «El rover real» | Consultado (V3) · no reabierto en V4 | Texto citado con enlace | `Data.SOURCES[2]` |
| Mars 2020 Perseverance · Mars Rock Samples | NASA Science | https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/ | Catálogo (cambia) | Cuatro muestras reales de ejemplo; análogo real de cada roca ficticia | `Data.REAL_SAMPLES`, Biblioteca, Informe | Consultado (V3) · no reabierto en V4 | Texto citado con enlace; el juego avisa de que el catálogo cambia | `Data.SOURCES[3]` |
| Assessing Perseverance's First Sample Attempt | NASA | https://science.nasa.gov/blog/assessing-perseverances-first-sample-attempt/ | Blog de misión | Roubion: tubo vacío → evento de muestra fallida | `ops.gd` (`show_failed_sample`), historia «roubion» | Consultado (V3) · no reabierto en V4 | Citado con enlace | `Data.SOURCES[4]` |
| Mars Perseverance Communications (NTRS 20210010148) | NASA Glenn Research Center | https://ntrs.nasa.gov/api/citations/20210010148/downloads/Mars%20Perseverance%20Communications%202021%20revised.pdf | Presentación técnica | UHF a 2 Mbps a un orbitador; orbitadores visibles unos 8 min al día; banda X directa a 160-500 bps | Pasos de orbitador, memoria limitada, `Data.REAL_LINK`, panel de Datos | **Verificado hoy** | Citado con enlace | Texto de la presentación: «transmission speeds of 2 megabits per second», «viewable for around 8 minutes per day», «160-500 bits per second» |
| Mars 2020 Landing Press Kit · Telecommunications | NASA/JPL | https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/spacecraft/telecommunications | Dossier de prensa | Antenas en crucero; secuencia de entrada, descenso y aterrizaje | `transit.gd` (evento de comunicación, cinco avisos) | Consultado (V3) · no reabierto en V4 | Citado con enlace | `Data.SOURCES[6]` |
| NASA's Perseverance Mars Rover Gets Its Wheels and Air Brakes (3-4-2020) | NASA/JPL | https://www.jpl.nasa.gov/news/nasas-perseverance-mars-rover-gets-its-wheels-and-air-brakes/ | Nota de prensa | 48 relieves curvos frente a 24 en cheurón; 52,6 cm de diámetro | Historia «wheels», mejora «Ruedas con mejor huella», `REAL_FACTS` | **Verificado hoy** | Citado con enlace | Coincide: «twice as many treads», «20.7 inches (52.6 centimeters)» |
| NASA's Oxygen-Generating Experiment MOXIE Completes Mars Mission (6-9-2023) | NASA/JPL | https://www.jpl.nasa.gov/news/nasas-oxygen-generating-experiment-moxie-completes-mars-mission/ | Nota de prensa | 16 ejecuciones; 122 g de oxígeno en total | Historia «moxie» | **Verificado hoy** | Citado con enlace | «extracted oxygen … 16 times»; «a total of 122 grams» en el texto de la nota |
| NASA's Record-Setting Opportunity Rover Mission on Mars Comes to End (13-2-2019) | NASA | https://www.nasa.gov/press-release/nasas-record-setting-opportunity-rover-mission-on-mars-comes-to-end | Nota de prensa | Diseñado para 90 días marcianos; casi 15 años; última comunicación el 10 de junio de 2018 | Historia «dust» («más de 14 años») | **Verificado hoy** | Citado con enlace | «Designed to last just 90 Martian days», «almost 15 years» |
| Mars 2020 mission blog · día del aterrizaje | NASA | https://blogs.nasa.gov/mars2020/author/nhartono | Blog de misión | Tiempo de luz de ida: 11 min 22 s el 18-2-2021 | Historia «delay» | **Verificado hoy** | Citado con enlace | «the one-way light time … is 11 minutes, 22 seconds» |
| Communications for the Planet Mars: Past, Present, and Future (arXiv 2211.14245) | Autores académicos (**no es la NASA**) | https://arxiv.org/pdf/2211.14245 | Artículo de revisión (fuente secundaria) | 160/500 bps con antenas de 34 m; 800/3000 bps con las de 70 m | Solo el texto de la mejora «dsn» | Consultado · secundario | No se cita como NASA | Ver pendiente 6 |
| NASA Mars Trek, Mission Design Lab, Mission Visualization, CubeSat 101, webinar *Design and Develop Science Missions* | NASA | (enlaces en el Prompt Maestro) | Herramientas y guías | Ninguna en el juego | — | Previsto / consultado por el equipo; **no integrado** | — | No aparecen en `scripts/` |

**Datasets de la NASA integrados directamente: ninguno.** El juego no carga datos de PDS, MRO, Curiosity ni InSight, y no incluye imágenes de la NASA. Usa documentación de misión (Mars 2020 Perseverance) para fijar reglas y textos.

### 3.2 Herramientas de desarrollo

| Nombre | Creador | URL | Contribución | Estado | Licencia | Evidencia |
|---|---|---|---|---|---|---|
| Godot Engine 4.7.1-stable (compilación oficial `a13da4feb`), renderizador GL Compatibility | Godot Foundation y colaboradores | https://godotengine.org | Motor del juego; pruebas sin pantalla | Integrado | MIT | `project.godot`, registros de pruebas |
| GDScript | Godot | https://docs.godotengine.org | Lenguaje de todo el juego | Integrado | MIT | `scripts/` |
| Python 3 con NumPy, SciPy y Pillow | PSF y comunidades | https://www.python.org | Síntesis de audio, recorte de iconos, composición de medallas | Usado para producir recursos | PSF / BSD / HPND | `tools/make_audio.py`, `tools/mark_si_icons.py` |
| FFmpeg (libtheora, libvorbis) | Proyecto FFmpeg | https://ffmpeg.org | Conversión del vídeo a Ogg Theora y de la música a Ogg Vorbis | Usado para producir recursos | LGPL/GPL | Comandos en `HANDOFF.md` |
| Xvfb y Mesa llvmpipe | X.Org / Mesa | https://www.mesa3d.org | Render por software para capturas y vídeo de demostración | Usado en pruebas | MIT | Capturas de `entrega/` |
| Claude (Anthropic) | Anthropic | https://www.anthropic.com | Asistencia en programación, depuración e iteración; generación de visuales del juego siguiendo referencias de estilo y dirección visual preparadas en Canva | Usado (confirmación del equipo) | — | Declaración del equipo; referencias de estilo en Canva |
| Higgsfield | Higgsfield | https://higgsfield.ai | Animación de despegue y otras animaciones del rover, según confirmación del equipo | Usado (confirmación del equipo) | — | Declaración del equipo; revisar los archivos finales para comprobar metadatos y marca SI |
| OpenAI Codex | OpenAI | https://openai.com/codex/ | Asistencia en programación, depuración e iteración, confirmada por el equipo | Usado (confirmación del equipo) | — | Declaración del equipo; el historial de código no identifica por sí solo la contribución de cada herramienta |

Hardware: no consta el de los equipos del grupo. Las pruebas de V4 corrieron en un contenedor Linux en la nube, sin GPU.

### 3.3 Materiales audiovisuales

| Recurso | Origen | Archivo / pantalla | Estado | Licencia / atribución | Evidencia |
|---|---|---|---|---|---|
| Rover 3D, terreno 3D, globo de Marte, taller y paisaje | Geometría generada por código (V4) | `scripts/rover3d.gd`, `geo3d.gd`, `stage3d.gd`, `world3d.gd` | Integrado | Obra del proyecto | Código fuente |
| Miniaturas de las 30 piezas y de los 8 tipos de roca | Renders de esos modelos 3D | `assets/parts/*.png`, `assets/rocks/*.png` | Integrado | Obra del proyecto | `tools/thumbs.gd` las regenera |
| Arte 2D vectorial (Dra. Owen, cohete, cápsula, fondos 2D) | Dibujado por código (V1-V3) | `scripts/art.gd` | Integrado | Obra del proyecto | Código fuente |
| 61 iconos de interfaz e insignias de nota | Recortados de la hoja del equipo | `assets/icons/*.png` | Integrado | **Procedencia pendiente (1)** | Recorte automático; la hoja original no se incluye |
| 10 medallas compuestas | Marco de una medalla de la hoja + un icono de la hoja, por programa | `assets/icons/medal_{rover,signal,core,camera,angles,check,power,adapt,tinker,archive}.png` | Integrado | Hereda el pendiente 1 | — |
| Logotipo 2MARS | Equipo (según V3) | `assets/brand/logo_2mars.png` | Integrado | **Procedencia pendiente (2)** | — |
| Vídeo de lanzamiento (5,04 s, 1280×720, 24 fps, sin audio) | Entregado por el equipo | `assets/video/launch.ogv` · fase de ascenso | Integrado, con marca visible | **Procedencia pendiente (3)** | `ffprobe`; fotogramas revisados |
| Música: cuatro temas (base, exploración, tensión, resolución) | Sintetizada por programa | `assets/audio/music_*.ogg` | Integrado | Obra del proyecto; metadatos descriptivos en cada archivo | `tools/make_audio.py` |
| Efectos nuevos: hover, click, select, attach, detach, error, discover, reward | Sintetizados por programa | `assets/audio/*.wav` | Integrado | Obra del proyecto | `tools/make_audio.py` |
| Efectos heredados de V3 | «Sintetizados para el juego» (V3) | `assets/audio/{good,bad,data,link,done,bump,warn,launch}.wav` | Integrado | Pendiente 4 | Documentos de V3 |
| Fuentes Fredoka y Nunito | Sus autores (Google Fonts) | `assets/fonts/` | Integrado | SIL Open Font License; licencias incluidas | `OFL-Fredoka.txt`, `OFL-Nunito.txt` |
| 22 referencias visuales, capturas de V3, pegatina | Equipo | No están en el juego | Consultado (guía de diseño) | — | — |

---

## 4. Cifras que V3 dejó pendientes: resultado

| Cifra | Resultado | Qué se hizo en el juego |
|---|---|---|
| 48 relieves por rueda frente a 24 | Verificado (NASA/JPL, 2020) | Historia con enlace a la nota |
| 16 ejecuciones y 122 g de MOXIE | Verificado (NASA/JPL, 2023) | Historia con enlace |
| Opportunity: 90 días previstos y más de 14 años | Verificado (NASA, 2019: 90 días marcianos, casi 15 años) | Historia con enlace |
| Unos 11 minutos de retardo | Verificado y precisado: 11 min 22 s **el día del aterrizaje**; el retardo cambia con la distancia | El texto ahora da la cifra exacta y dice que varía |
| Diámetro de rueda 52,5 cm | La nota de la NASA dice 52,6 cm (20,7 pulgadas) | `REAL_FACTS` corregido a 52,6 cm |
| Banda X directa «160 a 3.000 bps» | La NASA (Glenn) da 160-500 bps; 3.000 bps solo consta en una fuente secundaria | `REAL_LINK`, panel de Datos y Biblioteca usan 160-500 bps |
| Spirit atrapado en 2009, último contacto en 2010 | **No verificado con la NASA en esta sesión** (solo fuentes secundarias) | Sin cambios; pendiente |
| «El viento limpiaba los paneles» de Opportunity | **No contrastado en esta sesión** | Sin cambios; pendiente |
| MMRTG ~110 W; 43 tubos; brazo 2,1 m | No reabierto (pendiente 5) | Sin cambios |

Simplificaciones que el juego declara donde corresponde (Biblioteca, taller, panel de Datos), no en el HUD:
- **Energía:** el RTG del juego da 300 W; el MMRTG real, unos 110 W.
- **Comunicaciones:** tasas de juego en MB/s, aceleradas; las reales se muestran al lado, con sus unidades.
- **Tiempo:** 1 s de juego = 10 min de misión.
- **Muestras:** rocas y muestras del juego son ficticias; cada una enlaza un análogo real.
- **MOXIE:** demostración tecnológica, no soporte vital.
- **Vida:** orgánicos y habitabilidad son indicios; la NASA no ha confirmado vida en Marte.

---

## 5. Mapa de contribución científica

| Problema | Recurso | Información | Mecánica | Decisión | Consecuencia observable | Estado |
|---|---|---|---|---|---|---|
| ¿Qué investigar? | Science Objectives | Cuatro objetivos de Mars 2020 | Cuatro zonas con objetivos requeridos | Qué zona volar | Objetivos fuera de alcance sin el instrumento | Implementado |
| ¿Qué instrumentos llevar? | Science Instruments | Qué mide cada uno; cuáles van en el brazo | Compatibilidad, cubierta de 4 u 8 cargas | Carga útil dentro de masa y presupuesto | Bloqueos en *Mission Readiness*; evidencia distinta | Implementado |
| ¿Cómo llega la ciencia a casa? | NASA Glenn (NTRS) | UHF 2 Mbps por orbitador; pocos minutos al día; directo 160-500 bps | Pasos de orbitador, memoria limitada, enlace rover → orbitador → Tierra | Cuándo detenerse a transmitir; qué antena llevar | Los datos que se quedan en Marte no puntúan | Implementado |
| ¿Solar o nuclear? | Rover Components | MMRTG y baterías | Generación y consumo separados; noche y polvo | Fuente de energía y batería | Modo seguro, autonomía nocturna | Implementado (valores de juego) |
| ¿Qué pasa si la muestra falla? | First Sample Attempt | Roubion: tubo vacío | Evento de muestra fallida | Revisar, cambiar de roca, reintentar | Energía y tiempo gastados | Implementado |
| ¿Por qué cuidar las ruedas? | Nota de ruedas (JPL) | Rediseño tras el daño en Curiosity | Zonas de roca afilada; mejora «Ruedas con mejor huella» | Ruta, tipo de rueda, invertir ciencia en la mejora | Desgaste 25 % menor con la mejora | Implementado en V4 |
| ¿Por qué aterriza solo? | Blog de aterrizaje | 11 min 22 s de retardo | Secuencia de aterrizaje no controlable | Diseño y sitio antes de lanzar | Daño y precisión según el diseño | Implementado (modelo simplificado) |
| ¿Qué muestra guardar? | Mars Rock Samples | Muestras reales y su contexto | Cuatro tubos; documentar antes de perforar | Qué rocas merecen un tubo | Las muestras sin contexto valen menos | Implementado |
| ¿Cómo se ve Jezero? | Mars Trek, HiRISE | — | — | — | — | **Previsto**: el terreno es arte, no datos |

---

## 6. Auditoría de SI (IA)

| Tipo | Qué hay | Cómo se sabe | Estado de la atribución |
|---|---|---|---|
| Código asistido por IA | Claude (Anthropic) y OpenAI Codex apoyaron programación, depuración e iteración | Confirmación del equipo; no se atribuye cada línea a una herramienta concreta | Declarado en `SUBMISSION_RESOURCES.md` |
| Arte dibujado por código | Arte 2D de `art.gd`; geometría 3D; miniaturas renderizadas | Código fuente | No es imagen generada por un modelo; se declara como código asistido |
| Imagen generada | Logotipos generados con ChatGPT; visuales del juego generados con Claude a partir de referencias de Canva | Confirmación del equipo; metadatos binarios no re-inspeccionados | Verificar marca SI visible en los archivos finales |
| Vídeo y animación | Higgsfield se utilizó para el despegue y otras animaciones del rover | Confirmación del equipo; metadatos binarios no re-inspeccionados | Verificar marca SI visible y créditos en los archivos finales |
| Audio sintetizado por programa | Música y efectos nuevos de V4 | `tools/make_audio.py` reproduce los archivos | Descrito en Créditos y en los metadatos de la música |
| Audio generado por un modelo | Ninguno | — | — |

Atribuciones en el juego y en el repositorio: Biblioteca → «Fuentes y créditos», enlaces a fuentes NASA/JPL, y créditos/documentación de producción. La confirmación de herramientas no sustituye la comprobación visual de las marcas SI en los archivos finales.

---

## 7. Cambios de documentación y créditos hechos en V4

- `Data.REAL_LINK`: banda X directa de 160-3000 a 160-500 bps; textos del panel de Datos y de la Biblioteca ajustados.
- `Data.REAL_FACTS`: rueda de 52,5 a 52,6 cm y 48 relieves; se añade que los orbitadores se ven pocos minutos al día.
- `Data.STORIES`: cuatro historias ganan enlace a su fuente; el retardo pasa de «unos once minutos» a «11 minutos y 22 segundos», con la aclaración de que varía.
- `Data.SOURCES`: cuatro fuentes nuevas de la NASA.
- Créditos del juego: reescritos para describir el arte 3D, los iconos, el vídeo, el audio y el uso de IA.
- No se añadió ningún recurso que no se use.
