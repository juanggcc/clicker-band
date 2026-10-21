# Batería sentada v1 — primer gesto articulado

Esta revisión añade piezas registradas y una escena de Godot a la propuesta v0. Admite el gesto cruzado de hi-hat/caja de la camiseta roja. Su estado es experimental; toms, crash y camisa necesitan otros dibujos de pose/capas y revisión de solapes.

## Coordenadas y piezas

Dieciséis PNG de **800×1000**, origen de dibujo `(0,0)` y de instancia `(400,920)`. Cada sprite conserva `centered=false`. Las piezas móviles se colocan en nodos con el pivote indicado en `rig.json`; su arte tiene posición negativa de ese pivote para mantener las coordenadas originales. La revisión `left-arm-tucked-v2` mantiene el codo izquierdo junto al torso y sitúa ese brazo debajo de `hi_hat_front` y `hi_hat_top`, con la mano derecha por encima de los platos.

`registered-parts.ora` y `assembly.png` muestran la pose fuente de los recortes. Godot la ajusta al contacto de hi-hat/caja mediante IK; el editable no hornea esas transformaciones. `template.json` enumera capas y pivotes. `sources.json` congela sus hashes y los del rig.

Los antebrazos de la pose de espera v0 tenían mucho escorzo y no sirven como estas piezas de ejecución. Se dibujó otra pose y se midieron sus articulaciones proyectadas. La diferencia de longitudes proyectadas entre brazos no es una regla de anatomía ni una autorización para estirar piezas: para otro ángulo debe dibujarse una nueva pose registrada.

## Movimiento comprobado

Hombro–codo–muñeca con longitudes fijas, mano y baqueta rígidas, objetivo en la punta. La muñeca se sitúa restando al objetivo el vector de punta rotado; después se resuelve el brazo. Los dos talones permanecen en su pivote, el asiento/pelvis no se trasladan y el torso se inclina ligeramente. La cara conserva los píxeles del maestro cartoon aceptado.

El patrón actual es hi-hat y caja a 120 BPM, con intensidad suave/media/fuerte y cámara lenta. No se ofrecen los objetivos de toms/crash como poses activas: la prueba inicial mostró codos forzados al extrapolar este mismo dibujo. La geometría de los pedales ocultos permanece pendiente.

## Usar y revisar

Abrir `game/art_lab/drummer_articulation.tscn` en Godot y pulsar **F6**. Espacio pausa, 1/2/3 intensidad, 4 pose de ejecución de origen, S cámara lenta y G guía. El personaje reusable está en `game/characters/drummer/drummer.tscn`; la escena principal no lo instancia.

La [entrega y comandos](../../../workspace/art-jobs/bateria-articulacion-v01/README.md) incluyen WebP normal/guía, render móvil real con HUD y cinco plazas, editable y scripts de exportación. Se comprueban 960 muestras a tres intensidades y el contacto de 80 fotogramas reales. Una comprobación numérica no aprueba las costuras del dibujo.

Para otra skin, editar las mismas capas y medir uniones. Para la camisa larga, reconstruir mangas y solapes alrededor de estos pivotes; no reutilizar automáticamente los recortes de manga corta. Conservar v0 para la propuesta inicial y crear una revisión/pose nueva si cambian escorzo o contactos. Este flujo usa `prepare.cjs` del encargo; el preparador genérico de guitarristas todavía no incorpora este contrato.
