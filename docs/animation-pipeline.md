# Pipeline de animación v1

> Actualización 2026-10-21: el montaje vigente usa mallas con mangas ancladas y una capa fija de cabeza/cuello/torso. Ver [pipeline v2](animation-pipeline-v2.md). Este documento conserva el diseño inicial; las rotaciones rígidas y el orden de capas descritos abajo ya no definen el rig actual.


## Decisión: marioneta de recortes, no fotogramas

Un personaje es UNA ilustración cortada en piezas (cabeza, torso, brazos, guitarra, piernas)
y cada pieza gira o se desplaza sobre su articulación. Razones:

- Consistencia gratis: solo existe un dibujo por personaje. Generar fotogramas sueltos con
  IA da caras y proporciones distintas en cada imagen; con recortes ese problema desaparece.
- Se anima con código o con `AnimationPlayer`, y la intensidad se parametriza: el mismo
  bob del torso con 5 px o con 15 px es la diferencia entre "lento" y "rápido".
- Un rasgueo son dos o tres poses de mano; un paso completo sería mucho más trabajo y no
  hace falta en v1.
- No excluye pixel art ni fotogramas más adelante: si un gesto concreto lo pide, se
  sustituye una pieza por un `AnimatedSprite2D` con sus frames.

## Cómo está montado en Godot

`characters/protagonist/protagonist.tscn`:

```
Protagonist            origen en los pies; escala para el "squash" de cada tap
  Body                 desplaza el lienzo 700x900 para que (350,900) sea el origen
    Legs               Sprite2D estático
    Torso              Node2D en las caderas (355,560)  -> bob vertical
      Sprite           la capa torso.png
      Guitar           la capa guitar.png, pegada al torso
      ArmFret          Node2D en el hombro (462,300)     -> estático por ahora
      ArmStrum         Node2D en el codo (258,404)       -> rasgueo: bajada rápida, subida lenta, cambia a arm_strum_up en la recuperación
      Head             Node2D en el cuello (358,266)     -> cabeceo con retraso respecto al torso
```

Cada pivote está en la coordenada de la articulación y su `Sprite` hijo lleva la misma
coordenada en negativo, así todas las capas conservan las coordenadas del lienzo maestro.
El movimiento lo calcula `protagonist.gd` a partir de `beat_phase` (posición dentro del
pulso que da `MusicPlayer` leyendo el reloj de audio corregido por latencia) y de `intensity` (0.3 lento, 0.65 medio, 1.0 rápido). El
rasgueo hace 1 o 2 ciclos por pulso según el nivel: mismo tempo, más amplitud.

## Flujo para producir un personaje

1. Generar o dibujar la ilustración maestra en 700x900 (ver `docs/sprites-brief-v1.md`).
2. Cortar capas en una herramienta con capas (Figma, Krita, Photopea): una capa por pieza,
   exportar cada una con el lienzo completo. Redibujar lo que queda oculto bajo otra pieza
   para que rotar no deje huecos.
3. Copiar los PNG a `game/assets/characters/<nombre>/` con los nombres del brief.
4. Abrir Godot, pulsar F5, tocar. Si una articulación no cae donde el brief pedía, mover el
   pivote y su `Sprite` en la escena.
5. Afinar amplitudes en `protagonist.gd`. Cuando un gesto nuevo no salga con tres
   constantes, pasar ese gesto a un `AnimationPlayer` con claves en la escena.

## Consistencia con generación por IA

- Un maestro por personaje. Las variantes (otra pose, otra ropa) se generan con imagen de
  referencia a partir del maestro y se aceptan solo si la silueta y los rasgos coinciden.
- Nunca generar fotogramas de animación. Generar piezas o maestros.
- Un estilo cerrado por escrito (contorno, paleta, sombras) y pegado en todos los prompts.
- Validar a tamaño real en el móvil, no en la imagen a 4K.

## Plan B: Aseprite

Si el recorte de un dibujo pintado no da buen resultado, pixel art con Aseprite hace el
mismo esquema de capas (una capa por pieza, exportar por capa) y además permite fotogramas
de mano para el rasgueo. Godot importa `.aseprite` con un addon de la Asset Library o PNG
sueltos exportados desde Aseprite; para pixel art, en Import marcar filtro *Nearest*. El
MCP de Aseprite sirve para retoques dirigidos, pero el trabajo manual de cortar y limpiar
sigue siendo tuyo.
