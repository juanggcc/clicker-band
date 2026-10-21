# Familia de guitarristas de pie v1

Esta revisión corrige el encaje del cuello y conserva la geometría del rig v0.

La guitarra activa es la Jaguar custom marfil/burdeos con el eje puente–diapasón corregido. Para producir otro instrumento, usar el [sistema de instrumentos](../../instruments/standing-v1/README.md); el tamaño del músico y sus puntos de contacto se mantienen.

Esta plantilla separa **estructura, identidad y estilo**. Es una formalización del rig que existe hoy, con sus limitaciones; todavía necesita un segundo guitarrista como prueba. El estilo visual sigue siendo muy provisional.

## Qué se hereda

La escena base, sus movimientos, 700×900, origen, pivote del torso, malla y anclaje de rasgueo, tres posiciones sobre el mástil, orden de capas y zonas de solape. [template.json](template.json) describe el reparto. [assembly.png](assembly.png) muestra una composición neutral del montaje, con el primer agarre y sin deformación. Puede diferir del maestro artístico histórico: el brazo del mástil se desplaza en el runtime.

Las fuentes están en `layers/`. Esas piezas ya están registradas. **Los PNG del brazo del mástil y dedos conservan sus coordenadas originales**: la escena les aplica el mismo desplazamiento. Si se exportan desde la composición con el desplazamiento horneado, el rig lo aplicará dos veces.

El [guide.svg](guide.svg) superpone pivotes y zona de malla. Los marcadores describen el rig; no son una detección automática de anatomía ni una ficha de todas las medidas del personaje.

## Procedimiento para otro guitarrista

1. Crear un brief `character` con `family: guitar-standing-v1`, describiendo la nueva identidad. Ejecutar `prepare`: copia piezas, compuesto, guía y puntos de la misma plantilla al encargo. Las copias iniciales todavía representan al protagonista, no al nuevo músico.
2. Abrir `source.ora` en Krita: contiene las siete piezas como capas en el mismo lienzo, sin hornear los desplazamientos del motor. Su vista inicial es de las coordenadas de dibujo; usar el compuesto neutral como referencia del resultado montado. Guardar el maestro de la variante como `.kra` u `.ora`. Comenzar por cambios de pelo, cara, colores y prendas conservando los puntos de unión. La generación libre de otro cuerpo no es el procedimiento de esta familia.
3. Editar o redibujar una pieza cada vez, con máscara y referencia de identidad. Para mover una manga, resolver su unión con el brazo y la cobertura en los extremos. Para un sombrero o pelo más grande, modificar la silueta estática sin desplazar el origen. Conservar o adaptar la guitarra por separado.
4. Exportar sin recortar el lienzo a `exports/`. Mantener los nombres exactos. Guardar también `master.png` compuesto en pose neutral; no añadir ese compuesto a la escena como una capa extra.
5. Medir en el editable los puntos de unión de `landmarks.json`, indicar `status: measured` y revisarlos con la guía. `check-landmarks` detecta desviaciones declaradas; no verifica que alguien haya marcado el punto correcto. La tolerancia inicial de 4 px es una propuesta para esta geometría, no una garantía de encaje.
6. Ejecutar la comprobación de PNG y renderizar la variante con el rig real. Revisar seis estados: tres agarres × dos extremos del rasgueo. Revisar también el pulso a intensidad baja/alta en el juego. Los dedos deben seguir sobre el mástil, la manga debe cubrir la unión y el cuerpo no debe descubrir huecos.
7. Tras la revisión, copiar los exports al directorio propio del músico y crear una escena heredada. Esa escena solo cambia texturas; comparte el movimiento del primero. Las correcciones de animación comunes llegan a todos por herencia.

```bash
python3 tools/art/pipeline.py prepare art/briefs/protagonist-pilot.json --job guitarra-piloto-v01
.venv-art/bin/python tools/art/pipeline.py check character workspace/art-jobs/guitarra-piloto-v01/exports
python3 tools/art/pipeline.py check-landmarks workspace/art-jobs/guitarra-piloto-v01/landmarks.json

# Render con ventana y backend gráfico; --headless no produce capturas útiles.
/Applications/Godot.app/Contents/MacOS/Godot --path game \
  -s ../tools/art/render_guitar.gd -- \
  --skin workspace/art-jobs/guitarra-piloto-v01/exports \
  --out workspace/art-jobs/guitarra-piloto-v01/qa

# Una vez copiados y revisados los PNG en el directorio del nuevo músico:
.venv-art/bin/python tools/art/pipeline.py guitar-scene \
  --assets game/assets/characters/nuevo-guitarrista \
  --out game/characters/nuevo-guitarrista/nuevo-guitarrista.tscn
```

Las rutas de `--skin` y `--out` del renderer son relativas a la raíz del repo o absolutas. La escena generada no se instancia automáticamente en el juego. Mantener `.import` junto a los nuevos recursos tras su importación en Godot.

## Hasta dónde reutilizar

Un guitarrista con las mismas proporciones y pose puede cambiar de cara, pelo, prendas y acabados. Un músico más grande puede empezar escalando uniformemente la instancia. Cambiar la longitud del brazo, altura relativa del torso o posición de la guitarra requiere adaptar las uniones y volver a probar; estirar por piezas no da anatomía consistente.

El bajo podría derivar de esta familia manteniendo el movimiento general, pero necesita validar el mástil, sujeción y posiciones de mano. El batería necesita su propia familia: asiento, brazos/baquetas, contactos de golpe y orden de oclusión. Puede necesitar más de una pose por mano. «Una familia bien resuelta por instrumento y postura» es una buena meta; «un solo rig sirve para cualquier cuerpo y ángulo» no es un supuesto de este sistema.

Cuando quede cerrada la construcción, cambiar el estilo significa redibujar las mismas piezas y conservar sus uniones. Si cambia la geometría o el movimiento, versionar la familia. Si solo cambia el aspecto, crear otro músico que herede de ella. Después del segundo personaje se puede extraer la escena a una carpeta genérica; por ahora la base sigue siendo el protagonista para reducir migraciones.

Un cambio incompatible de geometría debe crear también otra escena base, conservando la de la familia anterior. No basta con cambiar el número del JSON y modificar el rig que siguen heredando los personajes anteriores. Las mejoras compatibles del movimiento sí pueden compartirse, con revisión de los músicos existentes.
