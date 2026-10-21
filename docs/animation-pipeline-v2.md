# Brazo del mástil recogido — 21 de octubre de 2026

Revisión posterior del mismo día: corregido el encaje de cabeza/cuello/camiseta en `body_core.png`, manteniendo los puntos del rig. La construcción actual está en `art/templates/guitar-standing-v1/`. La primera variante de aspecto es `game/characters/cowboy/cowboy.tscn`, comprobable junto al protagonista en `game/art_lab/guitar_comparison.tscn`. Fuentes y corrección: `art/jobs/protagonist-neck-v01/` y `art/jobs/cowboy-piloto-v01/`.

La manga derecha queda más pegada al costado. Un pequeño tramo de bíceps queda fijo bajo la manga, integrado en el torso. El codo permanece oculto detrás del torso y la guitarra; el antebrazo emerge hacia el mástil. No se utiliza la prueba descartada con el codo bajo.

## Montaje vigente

- `body_core.png`: cabeza, cuello y camiseta. Solo se retocó la zona de la manga derecha; se conservaron las demás partes de la imagen.
- `ArmFret`: `Sprite2D` detrás del torso y la guitarra. El brazo original se desplaza entero sin deformarse ni cambiar de escala.
- `Fingers`: `Sprite2D` delante del mástil; comparte exactamente el desplazamiento del brazo. La muñeca conserva el dibujo original.
- Se mantienen los tres agarres y su cambio cada cuatro pulsos, con desplazamiento suave.
- El brazo de rasgueo conserva la malla con la unión a la manga fija. Su código queda en `deformable_limb.gd`.

La superposición oculta la articulación que no necesita verse. El tramo visible del brazo del mástil se anima como una pieza rígida, evitando deformaciones de bíceps, codo y muñeca. Los tres agarres son poses visuales; aún no están asignados a acordes concretos del audio.

## Archivos

Integración: `game/characters/protagonist/` y `game/assets/characters/protagonist/`.

Entrega y copias: `output/art/2026-10-21-fret-tucked/`.

- `assets/torso.png`, `assets/body_core.png`, `assets/master.png`: capas modificadas y compuesto final de 700×900 con transparencia.
- `poses/pose-1.png` a `pose-3.png`: referencias de los tres agarres, exportadas desde Godot; no se intercambian como fotogramas durante el juego.
- `qa/three-grips.png`: revisión de los tres agarres y los dos extremos del rasgueo.
- `qa/motion.webp`: previsualización animada.
- `before/`: archivos anteriores a esta integración.
- `source/tucked-sleeve.png` y `prompts.json`: retoque con **image_gen integrado**, sin API/CLI; el registro y la composición de capas son deterministas.

Verificación: importación y seis renders de Godot, revisados visualmente. No se amplió la batería de pruebas del juego.


Último retoque: bíceps fijo en `torso.png` y `body_core.png`. Fuentes, prompt y comparativa en `output/art/2026-10-21-fixed-biceps/`. El antebrazo mantiene el montaje descrito arriba.
