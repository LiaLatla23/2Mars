# Trazabilidad científica

2Mars V3 · Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.

Cadena: **fuente NASA → información usada → mecánica → decisión del jugador → consecuencia**. La misma tabla está dentro del juego (Biblioteca → «NASA → juego»), con enlace a cada fuente.

| Fuente | Información usada | Mecánica | Decisión | Consecuencia | Verificación |
|---|---|---|---|---|---|
| Mars 2020 · Science Objectives | Cuatro objetivos: geología, astrobiología, muestras, preparación para humanos | Cuatro zonas de campaña con objetivos requeridos | Qué meta volar y qué instrumentos lleva | Objetivos fuera de alcance si falta el instrumento | Del Prompt Maestro; la página no se volvió a leer en esta sesión |
| Mars 2020 · Science Instruments | Qué mide cada uno de los siete instrumentos; PIXL y SHERLOC van en el brazo; WATSON es la cámara de SHERLOC | Cada instrumento da solo su tipo de resultado; regla de compatibilidad con el brazo | Carga útil dentro de masa, presupuesto y cubierta | Evidencia, retorno científico y volumen de datos distintos | Del Prompt Maestro |
| Mars 2020 · Rover Components | MMRTG de unos 110 W con baterías recargables; rocker-bogie; ruedas de 52,5 cm; brazo de 2,1 m; 43 tubos | Fuente de energía, almacenamiento, suspensión, antenas | Solar o RTG; más batería o menos masa | Supervivencia nocturna, alcance, modo seguro | Del Prompt Maestro. La página no se pudo leer con la herramienta web en esta sesión |
| NASA Glenn · Mars Perseverance Communications (NTRS 20210010148) | Relevo UHF de 2 Mbps a un orbitador; orbitadores visibles pocos minutos al día; banda X directa de 160 a 500 bps | Pasos de orbitador, memoria limitada, panel de transmisión con la estimación a tasa real | Cuándo detenerse a transmitir; qué antena llevar | Los datos que se quedan en Marte no cuentan | Verificado en esta sesión |
| arXiv 2211.14245 (resumen de las antenas de Perseverance) | Banda X de alta ganancia: de 160/500 bps a antenas de 34 m y de 800/3000 bps a las de 70 m | Cifra de 3.000 bps en la estimación «directo a la Tierra» | La misma | La misma | Verificado en esta sesión. No es una fuente de la NASA: conviene citar la página de la NASA antes de entregar |
| Mars 2020 · Mars Rock Samples | Cuatro muestras reales de ejemplo, con roca, tipo, número, sol y fecha | Catálogo de muestras del jugador con un análogo real del mismo tipo y enlace a las fotos | Qué rocas merecen un tubo; documentar antes de perforar | Las muestras sin contexto valen menos | Del Prompt Maestro. El catálogo de la NASA cambia: el juego lo avisa |
| NASA · Assessing Perseverance's First Sample Attempt | El primer intento (Roubion, sol 164, 6 de agosto de 2021) devolvió un tubo vacío: la roca se desmoronó | Evento de muestra fallida en roca frágil | Revisar imágenes, buscar una roca más dura, reintentar o usar el colector | Energía y tiempo gastados; no se pierde el tubo | Verificado en esta sesión |
| NASA/JPL · Mars 2020 Landing Press Kit | Antenas de baja y media ganancia en el crucero; secuencia de entrada, descenso y aterrizaje | Evento de comunicación interrumpida; secuencia de aterrizaje en cinco avisos | Revisar, esperar o leer el registro | Ninguna penalización: se enseña a esperar | Verificado en esta sesión (telecomunicaciones) |

## Datos reales que el juego muestra

Biblioteca → «El rover real» y «Muestras reales»: dimensiones y masa, MMRTG, ruedas, brazo, enlaces UHF y banda X, 43 tubos, cuatro muestras, y la frase «la NASA no ha confirmado vida en Marte».

Historias de la Dra. Owen (opcionales): ruedas de Curiosity, Spirit en la arena, Opportunity y el polvo, Roubion, MOXIE, y por qué el rover aterriza solo. **Pendiente de verificación con una página de la NASA antes de entregar**, porque salen de conocimiento general y no se contrastaron en esta sesión: 48 relieves por rueda frente a 24, 16 ejecuciones y 122 g de oxígeno de MOXIE, los 90 días previstos y más de 14 años de Opportunity, y los unos 11 minutos de retardo de la señal.

## Qué es modelo de juego

- Masa, potencia, créditos, ciencia, movilidad y fiabilidad de las 30 piezas: parámetros del libro del equipo. `NASA_Based` indica inspiración, no certificación. Ejemplo visible en el juego: RTG de 300 W en el juego, MMRTG real de unos 110 W.
- `Data.MODEL`: 500 Wh de batería base y 600 Wh de la extendida, 80 MB de memoria y 120 MB del almacenamiento grande, 30 W de calentadores, tasas de enlace del juego, 4 tubos.
- Tiempo: 1 s de juego = 10 min de misión. El enlace directo está acelerado frente al real, y el juego lo dice junto a la cifra real.
- Límites de masa y presupuesto, ventanas de lanzamiento, sitios de aterrizaje y el índice de preparación.
- Aterrizaje: modelo simplificado inspirado en Mars 2020. No reproduce una misión real paso a paso.

## Qué es ficción

La Dra. Owen, el equipo del jugador, el rover, la misión y todas las rocas y muestras del juego. El globo de Marte es una representación artística; solo las coordenadas de los lugares marcados son reales.

## Atribución y licencias

- Textos y cifras de la NASA: citados con enlace. El juego no incluye imágenes de la NASA.
- Logotipo 2MARS: del equipo.
- Arte: vectorial, dibujado por código en esta sesión y en V1.
- Audio: sintetizado para el juego.
- Fuentes Fredoka y Nunito: SIL Open Font License.
- Motor: Godot 4.7 (MIT).
