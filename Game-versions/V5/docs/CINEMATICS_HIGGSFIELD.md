# Cinemáticas: estado y guiones para Higgsfield

## Estado en V4 (15 de noviembre de 2026)

- **Integrado:** `assets/video/launch.ogv`, convertido de `Stylized-low-poly-3D-animation-with-flat.mp4` (entregado por el equipo: 5,04 s, 1280×720, 24 fps, H.264, sin audio). Se ve en la fase de ascenso del lanzamiento.
- **Marca visible:** el clip lleva grabado «SI-generated video · vídeo generado con SI». La procedencia no se pudo verificar (sin metadatos; su nombre no coincide con los guiones de abajo), así que se marcó de forma prudente. Si el equipo confirma que no es generado, se regenera sin marca:
  `ffmpeg -i clip.mp4 -an -c:v libtheora -q:v 7 -vf scale=1280:720 assets/video/launch.ogv`
  Con marca:
  `ffmpeg -i clip.mp4 -an -c:v libtheora -q:v 7 -vf "scale=1280:720,drawbox=x=16:y=672:w=330:h=34:color=black@0.55:t=fill,drawtext=fontfile=assets/fonts/Nunito.ttf:text='SI-generated video · vídeo generado con SI':fontcolor=white:fontsize=15:x=26:y=680" assets/video/launch.ogv`
- **Probado con Godot 4.7.1 y render por software:** reproducción al empezar el ascenso, paso a crucero al terminar, salto con Esc y con el botón, y retorno a la animación nativa con movimiento reducido o sin archivo. El audio del lanzamiento es el efecto del juego (el clip no tiene sonido). No se probó en un equipo con GPU.
- **Sin clip:** crucero y aterrizaje siguen con la animación nativa. No hay `cruise.ogv` ni `landing.ogv`.
- **Higgsfield en V4:** el conector está disponible (plan «ultra», 10 créditos, consultado el 15-11-2026). No se lanzó ninguna generación. El trabajo `79a5cb52-…` de V3 no se consultó desde esta cuenta.

Lo que sigue es el texto de V3, conservado como registro.

2Mars V3 · Desarrollado en distintas sesiones durante el 14 y 15 de noviembre.

## Estado en esta entrega

**El juego no incluye ningún vídeo de Higgsfield.** Las tres secuencias (lanzamiento, crucero y aterrizaje) son animaciones nativas de Godot, dibujadas por código, saltables y con modo de movimiento reducido.

Qué se hizo con Higgsfield:

- Se envió **un** trabajo de prueba: modelo `seedance_2_5`, texto a vídeo, 5 s, 720p, 16:9, sin audio, con la asignación gratuita de la cuenta (`use_unlim`). Créditos de pago gastados: **0**.
- Al cerrar esta entrega el trabajo seguía en cola (`waiting`), sin resultado. Identificador: `79a5cb52-7cea-4ebd-84e4-61f15bced98f`.
- No se generó ninguna imagen ni ningún otro vídeo.

## El juego ya está preparado para recibir los vídeos

`scripts/screens/transit.gd` busca estos archivos y, si existen, los reproduce detrás de los textos; si no existen, usa la animación nativa:

| Archivo | Momento | Bucle |
|---|---|---|
| `assets/video/launch.ogv` | Despegue y ascenso | No |
| `assets/video/cruise.ogv` | Crucero | Sí |
| `assets/video/landing.ogv` | Entrada, descenso y aterrizaje | No |

Godot reproduce **Ogg Theora** (`.ogv`), no MP4. Para convertir:

```
ffmpeg -i clip.mp4 -an -c:v libtheora -q:v 7 -vf "scale=1280:720" launch.ogv
```

**Sin probar:** como no hubo ningún vídeo, la reproducción, el salto y el retorno a la animación nativa con un archivo real no se han comprobado. Lo comprobado es que sin archivos el juego usa la animación nativa.

## Reglas para cualquier clip

- Estilizado, vectorial o low-poly, con la paleta del juego: `#191922`, `#293746`, `#F5DB98`, `#91C6BB`, `#FFAD45`, `#AA5D40`.
- Sin texto, logotipos, insignias de la NASA ni personas reales.
- No presentarlo como metraje real. En los créditos: «Cinemática generada con IA (Higgsfield, modelo …)».
- 16:9, 720p, 5 a 8 s, sin audio (el juego pone el suyo).
- Las reglas de Space Apps piden declarar las herramientas de IA usadas: anotar modelo, prompt y fecha.

## Guion 1 · Lanzamiento (`launch.ogv`)

> Stylized flat vector animation, low-poly look. A cream and orange rocket lifts off from a launch pad at dusk, a column of warm orange exhaust and soft mint-colored smoke clouds billowing outward. Camera slowly tilts up following the rocket into a deep navy sky with a few stars. Limited palette: dark ink blue, navy, cream, mint green, orange, rust. Clean shapes, no text, no logos, no people. Smooth, calm motion.

## Guion 2 · Crucero (`cruise.ogv`, en bucle)

> Stylized flat vector animation, low-poly look. A small cruise-stage spacecraft with a round aeroshell drifts slowly from left to right through deep space, tiny stars sliding past in parallax, a small rust-red planet growing slightly in the distance. Limited palette: dark ink blue, navy, cream, mint green, orange, rust. Clean shapes, no text, no logos. Very slow, seamless, loopable motion.

## Guion 3 · Aterrizaje (`landing.ogv`)

> Stylized flat vector animation, low-poly look. A cream aeroshell glows orange as it enters a thin rust-colored atmosphere, then a large cream and orange parachute opens, the heat shield drops away, and a descent stage lowers a small six-wheeled rover on cables onto a faceted rust-red surface. Dust puffs on touchdown. Limited palette: dark ink blue, navy, cream, mint green, orange, rust. Clean shapes, no text, no logos, no people.

El aterrizaje del juego es un modelo simplificado inspirado en Mars 2020; el clip no debe presentarse como una reproducción exacta.
