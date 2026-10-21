# Brief de sprites v1 (para el agente de gráficos)

> Actualización 2026-10-21: el montaje vigente usa mallas con mangas ancladas y una capa fija de cabeza/cuello/torso. Ver [pipeline v2](animation-pipeline-v2.md). Este documento conserva el diseño inicial; las rotaciones rígidas y el orden de capas descritos abajo ya no definen el rig actual.


Entrega del 2026-10-21 integrada; maestro, prompts y registro en `docs/art/2026-10-21-protagonist/`.

Estilo provisional, lo que no es negociable son los tamaños, la transparencia y las capas.
Los PNG que entregues sustituyen directamente a los placeholders de `game/assets/` con el
mismo nombre y tamaño.

## Reglas comunes

- PNG de 32 bits con canal alfa limpio (sin halo blanco ni semitransparencias sucias en los bordes).
- Sin texto, sin interfaz, sin marcos ni sombras proyectadas sobre el fondo.
- Resolución de referencia del juego: 1920x1080. Lo que se ve en un móvil 20:9 son 2400x1080.
- Un único archivo por pieza, nombres en minúscula exactamente como abajo.

## Protagonista: una ilustración maestra, entregada en capas

Lienzo **700x900 px** para todas las capas. Se dibuja UNA ilustración completa del personaje
y se entrega cada parte en su propio PNG **sobre ese mismo lienzo 700x900**, con el resto
transparente. Así las piezas encajan sin desplazamientos. Entrega también el compuesto
`master.png` para comprobar.

Pose: de pie, vista tres cuartos mirando ligeramente a la derecha de la pantalla, guitarra
colgada con el mástil hacia la derecha, mano izquierda en el mástil, mano derecha con púa
sobre el cuerpo de la guitarra. Pies en la base del lienzo (y = 900), cabeza empezando
alrededor de y = 60. Ancho total ocupado aproximado: 250 a 700 px.

Articulaciones que deben caer en estas coordenadas del lienzo (tolerancia ±15 px); si se
mueven, hay que ajustar la escena:

| articulación                      | x   | y   |
|-----------------------------------|-----|-----|
| caderas (pivote del torso)        | 355 | 560 |
| cuello (pivote de la cabeza)      | 358 | 266 |
| hombro del brazo que pisa trastes | 462 | 300 |
| codo del brazo que rasguea        | 258 | 404 |

Capas, de atrás hacia delante, con lo que debe contener cada una:

| archivo          | contenido                                                                  |
|------------------|----------------------------------------------------------------------------|
| `legs.png`       | pantalón y zapatillas desde la cadera (y≈500) hasta los pies               |
| `torso.png`      | camiseta y cuello, desde y≈235 hasta y≈545, con hombros                    |
| `guitar.png`     | guitarra completa con mástil y clavijero; sin manos                        |
| `arm_fret.png`   | brazo izquierdo completo desde el hombro (420,290) hasta la mano en (640,390) |
| `arm_strum.png`  | antebrazo y mano derecha con púa desde el codo (260,400) hasta (348,486)   |
| `head.png`       | cabeza, gorra, pelo y cuello hasta y≈290 (solapa con el torso)             |
| `arm_strum_up.png` | opcional: misma capa que `arm_strum` con la muñeca en recuperación (upstroke) |

Solapes: cada pieza se prolonga 20 a 30 px por debajo de la pieza que la tapa (el cuello
bajo la camiseta, la manga sobre el brazo, la cadera bajo el pantalón). Al rotar una pieza
no debe aparecer un hueco.

Rasgos del protagonista: joven, pelo negro saliendo bajo una gorra negra, camiseta oscura,
vaqueros, zapatillas claras, guitarra eléctrica blanca con golpeador rojo oscuro.

## Fondo: cuarto

`bedroom.png`, **2400x1080**, opaco. La franja central 1920x1080 (x de 240 a 2160) es lo
que ve un móvil 16:9; los 240 px de cada lado solo aparecen en móviles más anchos, así que
ahí no va nada importante. El personaje se coloca con los pies en y = 1000, x ≈ 760; deja
suelo visible ahí y el ampli a su derecha. Cama, escritorio y ventana en la mitad derecha.
Sin personaje dibujado en el fondo.

## Icono de nota

`note.png`, **96x96**, transparente, una corchea rellena del color de acento. Se usa en la
etiqueta flotante de cada tap.

## Prompt base en inglés

Las herramientas de imagen responden mejor en inglés. Rellena el estilo y conserva el
resto literal:

```text
Game asset for a 2D mobile game, PNG with fully transparent background, no text, no UI.
STYLE: <estilo elegido; p. ej. clean cartoon, bold dark outlines, flat colors, one shadow tone per material, no gradients, no textures>.
CANVAS: exactly 700 by 900 pixels. The figure stands with feet at the bottom edge and head starting around 60 px from the top.
SUBJECT: young adult man, shaggy black hair under a plain black baseball cap, dark charcoal T-shirt, loose blue jeans, off-white trainers, playing an ivory offset electric guitar with a dark red pickguard; three-quarter view facing slightly to the viewer's right; guitar neck pointing right; left hand on the neck, right hand holding a pick over the body.
DELIVERY: one composed image named master.png, then the same drawing split into six layers on the same 700x900 canvas (legs, torso, guitar, arm_fret, arm_strum, head), each layer alone with everything else transparent, with 20-30 px of overlap hidden under the layer in front so joints can rotate without gaps.
```

Si la herramienta no separa capas, pide solo `master.png` y recorta las capas a mano
(Figma, Krita o Photopea); ver `docs/animation-pipeline.md`.
