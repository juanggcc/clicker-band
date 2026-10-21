# Revisión del batería y propuesta de familia v2

21-10-2026. **Propuesta de construcción, pendiente de nuevo maestro y aprobación visual.** No cambia el personaje, sus PNG ni la animación actual. La familia v1 sigue siendo un piloto experimental.

La mejor siguiente prueba es dibujar **músico y batería juntos**, con los contactos ya resueltos, y separar después las piezas. El problema actual combina pose fuente, alcance y profundidad. Ajustar más el solver sobre los mismos recortes puede mantener el contacto matemático sin mejorar el dibujo.

## Hallazgos

### 1. La pose fuente no está resuelta sobre el kit

En [el rig actual](../../../game/assets/characters/drummer/rig.json), la punta derecha nace en `(626,545)` y debe golpear el hi-hat en `(535,500)`: **101,52 px de diferencia**. La izquierda está a 16,12 px de la caja. La composición del editable conserva esa pose fuente; la animación debe reconstruir la postura de ejecución.

La nueva [auditoría del runtime](current-rig-audit.json), ejecutada sobre la escena actual en Godot 4.7, muestra que en el golpe simultáneo del beat 1 la muñeca derecha pasa de `(406,489)` a aproximadamente `(310,467)` y el codo de `(306,478)` a `(210,468)`. No son pequeños retoques de contacto. El brazo superior cambia mucho respecto al dibujo y su manga tiene que soportar esa rotación.

La baqueta derecha permanece entre **4,74° y 11,29° respecto a la horizontal** en las 960 muestras de tres intensidades. La izquierda recorre 52,53°–72,36°. Esto concuerda con la lectura casi horizontal de la derecha en [los fotogramas existentes](../../../workspace/art-jobs/bateria-articulacion-v01/qa/contact-and-rebound.png). Son ángulos de imagen; no mediciones anatómicas en 3D.

**Cambio propuesto:** aprobar primero una pose de golpe con las puntas ya en sus superficies y otra de rebote. Medir las articulaciones sobre esos dibujos. La animación debe conservar la intención de esas poses y usar IK solo para correcciones pequeñas dentro del rango revisado.

### 2. Los dos agarres proceden de construcciones distintas

La distancia proyectada agarre–punta es **164,17 px en R y 57,20 px en L**, una relación de 2,87. El brazo izquierdo viene de una corrección posterior, registrada con escala 0,9 y traslación `(30,79)`, mientras el derecho conserva otro dibujo. El historial está en [prepare.cjs](../../../workspace/art-jobs/bateria-articulacion-v01/prepare.cjs).

El escorzo puede justificar longitudes proyectadas diferentes. Esa diferencia no demuestra por sí sola que las baquetas físicas tengan distinta longitud, pero necesita una construcción conjunta que la haga creíble. No conviene arreglarla igualando longitudes 2D o estirando el brazo.

Además, el runtime usa `tip - wrist` y mueve mano y baqueta como un bloque. El dato `grip` no interviene en un giro independiente de la baqueta. Esto mantiene el agarre rígido; por sí solo no es un fallo. Limita, sin embargo, cómo se puede dibujar un golpe de muñeca/dedos.

**Cambio propuesto:** registrar muñeca, agarre, extremo trasero y punta en cada pose. La mano gira alrededor de la muñeca; cualquier giro adicional de la baqueta ocurre alrededor del agarre y exige dedos/solapes dibujados para ese rango. Para el primer piloto bastan mano y baqueta rígidas por pose aprobada.

### 3. La profundidad se está resolviendo con grupos demasiado grandes

En [drummer.gd](../../../game/characters/drummer/drummer.gd), torso y brazos superiores quedan a profundidades efectivas 1 y 2, y **todo `kit_fixed` a 3**. Ese PNG agrupa cascos, bombo, soportes y restos del crash. El crash móvil está a 4. Eso obliga a todos esos píxeles a compartir relación con el cuerpo aunque representen distancias distintas.

No es incorrecto que el bombo o un tom tapen parte de las piernas/torso. El defecto es no poder decidir por pieza y por pose dónde debe pasar cada mano o baqueta. El crash está muy cerca del hombro en la proyección actual y cubre parte de la manga. Conviene revisar su posición/tamaño en el maestro conjunto, además del orden de dibujo.

Hay también un caso sutil: la prueba compara el **nodo** de mano izquierda (z efectivo 5) con el hi-hat (6), pero el **sprite** de esa mano suma otro nivel y acaba en **6**. La mano queda oculta por el orden del árbol, empatada con ambos platos. El resultado puede coincidir con lo deseado hoy, pero la prueba no detecta esa dependencia.

**Cambio propuesto:** separar herrajes traseros, cascos, platos y, solo donde haga falta, aros/bordes delanteros. Declarar relaciones locales como «brazo izquierdo detrás del hi-hat» o «punta sobre el parche y detrás del borde cercano». Un orden por pose debe cumplir esas relaciones; no se debe subir la batería entera para ocultar un codo.

Los nodos que solo transforman pueden tener z=0; los sprites reciben rangos explícitos y distintos desde los datos de la pose. La raíz del músico conserva su profundidad en el escenario. Comprobar los sprites efectivos, no solo sus contenedores.

### 4. La separación del crash deja píxeles en la capa fija

Inspeccionado [kit_fixed.png](../../../game/assets/instruments/compact-drums/kit_fixed.png): conserva tiras del contorno dorado del crash. La máscara que extrae el plato no abarca su silueta completa. En reposo la recomposición puede disimularlo; al girar el plato esos píxeles siguen quietos. El crash no se golpea en el groove actual, así que esto es un defecto latente para esa animación.

**Cambio propuesto:** extraer el disco completo, conservar el soporte fijo y reconstruir la zona que el disco ocultaba. Revisar cada capa aislada y el movimiento sobre fondo contrastado. Un recorte generativo o poligonal no garantiza una separación limpia.

### 5. La comprobación actual cubre geometría, no calidad de pose

Repetida la evaluación del solver: **960 muestras, cero fallos, error máximo de punta 0,000069 px y de segmento 0,000039 px**. Los 16 PNG de la plantilla coinciden byte a byte con los activos. Esto confirma que los problemas visibles pueden coexistir con los checks correctos.

Las pruebas existentes cubren alcance, longitudes, continuidad, talones y un orden parcial de capas. No validan por sí mismas silueta, mangas, lectura del agarre, recorrido de golpe o separación limpia de platos. Los fotogramas revisados son las capturas existentes; esta revisión repite la evaluación numérica, no una nueva captura gráfica.

## Coordenadas que conviene fijar ahora

Conservar estos valores evita otra migración innecesaria:

| Concepto | Convención propuesta |
| --- | --- |
| Lienzo de todas las piezas | 800×1000 RGBA; sin recortar transparencia |
| Origen del dibujo | `(0,0)`, esquina superior izquierda |
| Ejes de dibujo | `+X` derecha de pantalla, `+Y` abajo |
| Ángulos de autoría | Grados desde `+X`; positivos en sentido horario; runtime convierte a radianes |
| Origen de instancia/suelo | `O=(400,920)`; no es pelvis ni talón |
| De dibujo a local de instancia, pose sin transformar | `local = dibujo - O` |
| De local a mundo | Transformación global de la instancia; escala uniforme para el conjunto |
| Pivote `Q` de una pieza | Nodo en `Q-O`, sprite en `-Q`, `centered=false` |
| Rotación de una pieza plana | `local(P) = Q + R(θ)·(P-Q) - O`; componer los padres si los hay |
| L/R | Izquierda/derecha **anatómica del músico**; la cámara actual muestra hombro R a la izquierda de pantalla |
| Profundidad | Orden de dibujo separado de X/Y; no inferir delante/detrás a partir de Y |

En el rig con torso inclinado, hombros/brazos pertenecen a su espacio local; kit y objetivos permanecen en el espacio del lienzo. El cambio de espacio debe ser explícito. La conversión inversa del objetivo que hace v1 es una idea que conviene conservar.

Pelvis `(380,611)` y objetivos actuales sirven de **guía inicial de composición**. Si el nuevo maestro mueve el kit, se vuelven a medir objetivos y pivotes antes de congelar v2. Las coordenadas de codos, muñecas y agarres v1 son evidencia del piloto, no el estándar para nuevos baterías.

## Cómo construir v2

1. **Maestro conjunto.** Mantener identidad/acabado aceptados y rediseñar sobre una composición músico+kit. Revisar altura de caja, espacio entre manos, cruce, inclinación de baquetas, sitio de los codos y visibilidad de los pedales. Si el crash tapa demasiado el hombro, recolocarlo en el dibujo conjunto. Las coordenadas de la guía orientan; no deben forzar la anatomía.
2. **Golpe y rebote antes de recortar.** Aprobar ambas poses a tamaño de juego. El rebote debe leerse como una recuperación desde el golpe. Si cada mano se anima por separado, probar las cuatro combinaciones de extremos R/L. El escorzo que cambie la silueta necesita otra pose registrada.
3. **Separación sobre un único registro.** Mantener el maestro compuesto como referencia. Reconstruir solo las superficies ocultas que el movimiento vaya a revelar: camiseta, interior de mangas, codos/muñecas y zonas de instrumento. Conservar una composición de las capas separadas para compararla con el maestro.
4. **Datos de familia, kit y apariencia.** Una fuente canónica contiene convenciones, poses, contactos y relaciones de profundidad. Los JSON de motor, guía y validación se derivan de ella; no volver a escribir los mismos puntos en `prepare.cjs`, el contrato, la plantilla y el runtime. El kit aporta superficies/soportes; la skin aporta arte compatible con la construcción.
5. **Animación acotada.** Interpolar las poses aprobadas con anticipación, golpe y recuperación. La intensidad recorre un rango aprobado. El solver puede ajustar el contacto, pero un objetivo que requiere salir de ese rango exige otra pose o un kit compatible, no una solución libre en 360°.
6. **Segundo batería como prueba del sistema.** Cambiar cara, pelo/gorra, ropa y accesorios conservando asiento, registro, contactos y poses. Una manga larga requiere dibujar sus solapes. Un cuerpo con proporciones o escorzo distintos necesita una variante de construcción y una nueva revisión; no se promete compatibilidad universal.

La pieza de instrumento puede necesitar cascos y aros separados en caja/toms, platos completos con soporte aparte y pedales. Separar solo cuando haya movimiento o una relación de profundidad distinta. El bombo puede seguir siendo una sola pieza si no necesita otra división. Se conserva la idea de dieciséis capas como antecedente, no como límite u objetivo de v2.

## Qué debe pasar antes de llamar reutilizable a la familia

- Comparación maestro/compuesto separado en la pose de golpe; no debe cambiar la postura al entrar en ejecución.
- Grip, muñeca y baqueta consistentes en contacto y rebote; punta sobre la superficie visible en el golpe. Primera tolerancia propuesta: hasta 2 px en el lienzo para ese contacto, pendiente de ajustar con el dibujo. No aceptar más error por ocultarlo con un aro.
- Rango de codos y muñecas aprobado por pose; medir sobre los dibujos, sin inventar límites anatómicos a partir de píxeles.
- Sin salto de rama, costuras abiertas o dedos que pierdan la baqueta en combinaciones y extremos de intensidad.
- Cada sprite cumple el orden de oclusión de la pose sin empates accidentales. Sin restos del disco en herrajes fijos ni dobles contornos al moverse.
- Revisión de superficies ocultas, zapato/pedal y asiento con instrumento semitransparente en una vista de inspección.
- Vista normal y móvil 844×390 con HUD y cinco plazas, además de ampliaciones de las uniones.
- La segunda skin funciona sin desplazar piezas arbitrariamente ni copiar lógica de animación.

El [borrador de coordenadas v2](drummer-seated-v2-draft.json) distingue las convenciones ya propuestas de las medidas pendientes. No está registrado en el preparador ni lo consume el juego. El siguiente entregable útil sería **maestro conjunto de golpe + rebote para revisar**, seguido de la separación y una única prueba hi-hat/caja. Toms/crash se amplían después con sus propias poses.

## Reproducir la auditoría

Desde la raíz del repo, usando el ejecutable Godot de este Mac:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --log-file /private/tmp/clicker-band-drummer-review.log --path game --script "$PWD/docs/art/2026-10-21-drummer-review/audit.gd" -- --out "$PWD/docs/art/2026-10-21-drummer-review/current-rig-audit.json"
```

El script solo instancia el piloto, mide transformaciones y escribe el informe. En este entorno Godot emite un diagnóstico de certificados de macOS al arrancar; no hubo errores de script en la ejecución final. [evidence.json](evidence.json) registra hashes de las fuentes inspeccionadas para distinguir esta revisión de cambios posteriores.
