# 2Mars V5.1 — relevo breve (15-11-2026)

Continúa V5. Nada publicado ni desplegado.

## Cambios de esta entrega
- **Cooperativo Expedición**: dos rovers en la misma misión, pantalla dividida fija (izquierda J1, derecha J2). Posición, velocidad, energía, salud y tubos son de cada rover; reloj, memoria, datos, objetivos y recompensas son de la misión y existen una vez. Si un rover queda inutilizado el otro sigue; con los dos inutilizados, informe de fracaso.
- Logo original de SpaceNuts en Créditos.
- Se conservan: arreglo del `%` en `Data.recommendations()`, guardado seguro, Tripulación, subniveles, peligros arcade.

## Controles de Expedición
| | J1 | J2 |
|---|---|---|
| Mover | W A S D | Flechas |
| Estudiar / siguiente opción del panel | E | Punto `.` |
| Acción (elegir opción, minijuego) | Espacio | Intro |
| Transmitir | T | Coma `,` |
| Pausa | Esc | Esc |

En el panel de roca, el punto (o E) recorre las opciones y la acción la ejecuta; los números 1-6 también valen.

## Límites conocidos de Expedición
- Un solo panel de estudio o minijuego a la vez (el otro jugador sigue conduciendo mientras tanto).
- El HUD de recursos de arriba a la izquierda muestra el rover que interactuó por último; cada jugador tiene su barra propia de energía y salud.
- Remolinos, tormenta y peligros arcade afectan solo al rover en foco.
- Sin fusión de cámaras (pantalla dividida fija), sin mando, teclas no reasignables.
- Las marcas 2D del terreno (anillos de roca, flecha guía) solo salen en la vista izquierda.

## Pendiente
Intro cinemática, voz de Owen (cancelada), fusión de cámaras, build web probada, medición en GPU, prueba con personas, procedencia de iconos/logo 2MARS/vídeo.

## Pruebas
Ver `PROMPT-CONTINUAR-2Mars-V5.md` en la raíz del ZIP.
