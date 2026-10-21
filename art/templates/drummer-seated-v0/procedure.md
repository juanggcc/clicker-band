# Batería sentada compacta v0

Propuesta de construcción para revisar con el usuario, no rig animado terminado. Los maestros y el editable están en `workspace/art-jobs/bateria-piloto-v01/`. El acabado es el primer dibujo cartoon, con la barbilla ligeramente redondeada; se descartó el retoque de cara realista. El kit ancho también está descartado.

## Registro compartido

Músico e instrumento usan **800×1000 RGBA**, origen superior izquierdo `(0,0)`, posición de sprite `(0,0)` y `centered=false`. El origen de la instancia es `(400,920)`: el contenedor del dibujo lleva `(-400,-920)`. Este origen no es el centro de ninguno de los dos zapatos. La pelvis está cerca de `(380,611)`.

Los dos outfits heredan pose y coordenadas: gorra negra/camiseta roja ancha, y gorra roja/camisa cerrada/bolso verde. El lienzo se conserva incluso al separar piezas. Las fuentes se registran con una transformación uniforme de todo el maestro, documentada en `registration.json`. No se estiran extremidades ni se aplasta el kit para estrecharlo: el kit compacto se dibujó de nuevo.

El sistema `standing-v1` sigue atendiendo guitarra y bajo. Este borrador aún no se añade a `art/style-v0.json` ni al preparador genérico: allí una familia implica piezas articuladas realmente disponibles. Usar este JSON y el encargo como propuesta hasta cerrar los dibujos y las uniones.

## Kit y contactos

Cuatro cuerpos: bombo, un tom aéreo, tom de suelo y caja detrás del bombo. Hi-hat y crash/ride combinado. El solape en profundidad reduce la huella; el bombo tapa buena parte de la caja y del herraje. Los objetivos ámbar del JSON se han situado visualmente sobre los parches/platos del dibujo; requieren revisión en las poses de golpe. La posición de los pedales ocultos es **propuesta**, no medida.

La disposición de manos y pies parte de la [posición básica de Yamaha](https://www.yamaha.com/en/musical_instrument_guide/drums/play/): pie derecho al bombo, izquierdo al hi-hat, mano izquierda a caja y derecha al hi-hat. La familia compacta concreta, sus coordenadas y sus animaciones son una propuesta propia de este proyecto.

## Articulación prevista

1. Pelvis apoyada en taburete; giro suave de torso desde pelvis y de cabeza desde cuello. No animar todo el sprite rebotando verticalmente: se perdería el apoyo.
2. Dos segmentos por brazo: hombro–codo–muñeca. Mano con pivote propio, agarre fijo para la baqueta y punta como extremo de contacto. Resolver la posición de muñeca a partir de la punta y orientación deseadas antes del codo; no mover la muñeca directamente al parche. Mantener longitudes y lado de flexión del codo.
3. Preparar poses dibujadas de hi-hat cruzado, caja, tom, suelo y crash/ride, con ataque y rebote. La pose neutral abierta de esta entrega no representa ya el patrón cruzado. Si aparece escorzo, redibujar antebrazo/mano en esa pose en lugar de estirarlos.
4. Muslo–rodilla–espinilla–tobillo en cada pierna. Talón estable y pequeño giro de tobillo/punta para el pedal. Validar contactos con una vista de equipo transparente antes de cerrar la animación.
5. Mangas cubren solapes dibujados de hombro y codo. La camisa cambia el contorno, no los pivotes anatómicos. Bolso sujeto al torso/cadera y fuera del recorrido de manos. Separar baquetas, manos y antebrazos solo al preparar las zonas ocultas.

Orden de profundidad: herraje trasero/taburete, piernas, torso/brazos superiores, caja/toms, bombo frontal, antebrazos/manos y baquetas. Cambiar el orden de los brazos para el gesto cruzado. Los aros delanteros pueden tapar la punta al bajar; no adelantar un plato completo por encima de todas las manos. Los discos de platos giran sobre la fijación real, no sobre su borde.

## Producir la siguiente revisión

Abrir `source.ora`: contiene maestros completos y una máscara de antebrazos **solo para la pose visible**. No hay anatomía oculta reconstruida ni piezas finales de articulación. Tras elegir outfit, separar en el editable las piezas enumeradas en `template.json`, dibujar solapes ocultos y medir los puntos de cada pieza. La tolerancia inicial de 8 px es solo una guía de revisión, no una prueba de calidad.

Para repetir el registro y las láminas con Node + Sharp:

```bash
npm install --prefix tools/art
node workspace/art-jobs/bateria-piloto-v01/register.cjs
```

Revisar `qa/outfits.png`, `qa/assembled-outfits.png`, `qa/rig-guide.png` y `qa/mobile-five-members.png`. La vista móvil es una composición estática de espacio a 844×390 con dos siluetas reservadas; no prueba HUD ni animación y no introduce personajes nuevos en el juego. No ejecutar `check character` del guitarrista sobre estos PNG: exige otro contrato y otras piezas.

Antes de integrar: comprobar todas las poses de golpe/rebote, la ausencia de huecos al girar, los dos pies sobre pedales, la lectura con HUD y cinco integrantes a tamaño móvil. Versionar la familia si cambia la postura o geometría de contacto.
