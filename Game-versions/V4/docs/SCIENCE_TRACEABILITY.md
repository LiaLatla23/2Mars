# Trazabilidad científica

> **Auditoría V4 · 15 de noviembre de 2026.** Este documento se contrastó directamente con `Game-versions/V4/scripts/data.gd` y `Game-versions/V4/scripts/screens/library.gd`. La tabla principal reproduce las seis filas de `Data.TRACE` que aparecen en la pestaña **Biblioteca → NASA → juego**. La lista completa de 11 enlaces que aparecen en **Fuentes y créditos** se encuentra en [NASA_RESOURCES_USED.md](../../../research/NASA_RESOURCES_USED.md).

## 1. Matriz que aparece en «NASA → juego»

La cadena mostrada en el juego es: **fuente NASA → información usada → mecánica → decisión del jugador → consecuencia**.

| Fuente (nombre de la biblioteca) | Información usada | Mecánica en 2Mars | Decisión del jugador | Consecuencia |
|---|---|---|---|---|
| Mars 2020 Perseverance · Science Objectives | Cuatro objetivos científicos: geología, astrobiología, almacenamiento de muestras y preparación para futuras misiones humanas. | Las cuatro zonas de campaña y sus objetivos requeridos. | Qué objetivo priorizar y qué instrumentos llevar. | Algunos objetivos quedan bloqueados si el instrumento necesario no viaja en el rover. |
| Mars 2020 Perseverance · Science Instruments | Qué mide cada uno de los siete instrumentos; PIXL y SHERLOC se montan en el brazo. | Cada instrumento produce el tipo de resultado que puede respaldar; hay una regla de compatibilidad con el brazo. | Elegir la carga útil dentro de los límites de masa, presupuesto y cubierta. | Cambian la evidencia disponible, el retorno científico y el volumen de datos. |
| Mars 2020 Perseverance · Rover Components | MMRTG y baterías recargables, suspensión rocker-bogie y antenas. | Compromisos entre fuente de energía, almacenamiento, suspensión y antenas. | Elegir solar o RTG, más batería o menor masa. | Cambian la supervivencia nocturna, el alcance de conducción y la aparición de eventos de modo seguro. |
| NASA Glenn · Mars Perseverance Communications (NTRS 20210010148) | Relevo UHF de hasta 2 Mbps; orbitadores visibles solo unos minutos al día; banda X directa de 160–500 bps. | Ventanas de paso de orbitadores, memoria limitada y panel de transmisión con estimaciones a tasa real. | Cuándo detenerse a transmitir y qué antena llevar. | Los datos que permanecen en Marte no cuentan como retorno; se refleja en el informe de misión. |
| Mars 2020 Perseverance · Mars Rock Samples | Las muestras reales tienen sitio, tipo de roca y contexto; Perseverance lleva 43 tubos. | Foto de contexto antes de perforar, tubos limitados y catálogo con enlaces a muestras reales análogas. | Qué rocas merecen un tubo. | Las muestras sin documentación obtienen menor puntuación. |
| NASA · Assessing Perseverance's First Sample Attempt | El primer intento de extracción, en Roubion en 2021, devolvió un tubo vacío porque la roca se desmoronó. | Evento de muestra fallida en una roca frágil. | Revisar las imágenes, buscar una roca más resistente, reintentar o usar el colector. | Se gastan energía y tiempo; el evento enseña una lección de muestreo. |

**Nota de alcance:** esta tabla contiene exactamente las seis entradas actuales de `Data.TRACE`. No se deben añadir filas aquí solo porque una fuente figure en la lista general de créditos.

## 2. Otras referencias visibles en la Science Library

La pestaña **Fuentes y créditos** muestra 11 enlaces NASA/JPL. Además de las seis fuentes trazadas arriba, las siguientes aparecen en fichas o historias específicas:

| Recurso | Dónde aparece | Alcance real de la conexión |
|---|---|---|
| NASA/JPL · Perseverance Mars Rover Gets Its Wheels and Air Brakes | Fuentes y créditos; historia de las ruedas de la Dra. Owen. | Informa la historia sobre el rediseño de las ruedas y el contexto del desgaste. El 25% de reducción de desgaste de una mejora es un valor de balance del juego, no un resultado NASA. |
| NASA/JPL · Oxygen-Generating Experiment MOXIE Completes Mars Mission | Fuentes y créditos; ficha MOXIE; historia de oxígeno de la Dra. Owen. | Aporta el contexto de la demostración tecnológica MOXIE. No se presenta como un sistema completo de soporte vital. |
| NASA · Record-Setting Opportunity Rover Mission on Mars Comes to End | Fuentes y créditos; historia de Opportunity y el polvo. | Aporta contexto histórico sobre la duración de Opportunity y su final durante una tormenta de polvo. |
| NASA · Mars 2020 mission blog (landing day, one-way light time) | Fuentes y créditos; historia sobre por qué el rover aterriza solo. | Explica el retardo de comunicación de 11 min 22 s en el día del aterrizaje de Perseverance; el retardo cambia con la distancia entre los planetas. |
| NASA/JPL · Mars 2020 Landing Press Kit · Telecommunications | Fuentes y créditos. | Referencia general de telecomunicaciones del crucero y aterrizaje. No constituye una fila separada en `Data.TRACE`. |

La historia **Spirit y la trampa de arena** también identifica a NASA/JPL como fuente en su texto, pero el registro actual de `Data.STORIES` no incluye un enlace URL para esa historia. Por tanto, no se debe describir como una historia con enlace NASA directo dentro del juego.

Otras conexiones directas de la biblioteca:

- **Instrumentos:** las fichas de los siete instrumentos enlazan a la fuente NASA de Science Instruments. El juego distingue lo que hace el instrumento real de lo que representa el modelo de 2Mars.
- **Muestras reales:** las fichas de Montdenier, Hazeltop, Sapphire Canyon y Green Gardens enlazan a la página NASA de muestras de Perseverance. Son registros reales usados como referencia; las rocas y muestras de la misión jugable son ficticias.
- **El rover real:** muestra datos de Perseverance como dimensiones, masa, MMRTG, ruedas, brazo, comunicaciones, tubos y la aclaración de que NASA no ha confirmado vida en Marte.

## 3. Datos reales y parámetros de juego

### Datos reales que la biblioteca presenta como tales

- Perseverance lleva siete instrumentos científicos: Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, MOXIE y RIMFAX.
- El rover mide aproximadamente 3 m de largo, 2,7 m de ancho y 2,2 m de alto; su masa es de unos 1.025 kg.
- Su MMRTG proporcionaba aproximadamente 110 W al inicio de la misión y carga baterías recargables.
- Las ruedas miden unos 52,6 cm de diámetro y tienen 48 relieves curvos; la suspensión es rocker-bogie.
- El brazo robótico mide unos 2,1 m y tiene cinco grados de libertad.
- El enlace UHF a través de orbitadores alcanza hasta unos 2 Mbps; el enlace directo en banda X es mucho más lento, de 160 a 500 bps. Los orbitadores solo están a la vista unos minutos al día.
- Perseverance lleva 43 tubos: 38 para muestras y cinco tubos testigo.
- NASA no ha confirmado vida en Marte.

### Parámetros y abstracciones de 2Mars

- Masa, potencia, créditos, ciencia, movilidad y fiabilidad de las 30 piezas del catálogo son parámetros del libro de ingeniería del equipo. La marca de inspiración NASA no certifica esas cifras.
- El RTG del juego entrega 300 W; el MMRTG real de Perseverance entregaba unos 110 W al inicio de la misión.
- `Data.MODEL` define, entre otros, 500 Wh de batería base, 600 Wh adicionales para la batería extendida, 80 MB de memoria base, 120 MB adicionales de almacenamiento, calentadores de 30 W y tasas de enlace aceleradas.
- El tiempo está comprimido: un segundo de juego representa diez minutos de misión.
- Límites de masa y presupuesto, ventanas de lanzamiento, sitios de aterrizaje, índices de preparación, desgaste y bonificaciones son abstracciones de juego.
- El aterrizaje está simplificado y no reproduce una misión real paso a paso.

## 4. Contenido ficticio

La Dra. Owen, el equipo del jugador, el rover jugable, la misión y las rocas y muestras que el jugador estudia son ficción. El globo de Marte es una representación artística, no un mapa de NASA. Los nombres de lugares pueden basarse en ubicaciones reales, pero eso no convierte el escenario ni sus puntuaciones en datos cartográficos o evaluaciones oficiales de NASA.

## 5. Límites de la simulación

2Mars es un juego educativo de diseño y gestión de misiones, no una herramienta profesional de ingeniería aeroespacial. No calcula trayectorias orbitales reales, Delta-V, ventanas de lanzamiento operativas ni una secuencia de aterrizaje de alta fidelidad. Las fuentes de planificación espacial adicionales están documentadas por separado en [SPACE_MISSION_PLANNING_SOURCES_EN.md](../../../research/SPACE_MISSION_PLANNING_SOURCES_EN.md).

## 6. Atribución y recursos

- Los textos y datos de NASA se presentan con enlaces en la biblioteca.
- El juego no incluye imágenes de NASA; el globo de Marte es una representación artística.
- El arte 3D de V4 se genera mediante geometría/código; el arte 2D es vectorial y generado por código, según la auditoría de recursos.
- El logotipo 2Mars es del equipo.
- El clip de lanzamiento se atribuye en pantalla según los créditos del juego.
- Música y efectos se sintetizaron mediante herramientas creadas para el proyecto.
- Las fuentes Fredoka y Nunito usan SIL Open Font License.
- Motor: Godot 4.7 (MIT).

Para el inventario completo de las 11 fuentes listadas en el juego, las fuentes de investigación adicionales y sus respectivos límites, consulta [NASA_RESOURCES_USED.md](../../../research/NASA_RESOURCES_USED.md). Para el estado general de atribución y verificación, consulta [RESOURCE_AUDIT.md](RESOURCE_AUDIT.md).

---

*2Mars · Team SpaceNuts · NASA Space Apps Challenge 2026*
