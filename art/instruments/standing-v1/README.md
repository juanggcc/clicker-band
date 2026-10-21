# Instrumentos de pie: guitarra y bajo

Sistema de dibujo y registro para la pose de `guitar-standing-v1`. Separa el aspecto del instrumento de su escala y sus contactos con el músico. El estilo sigue siendo provisional; esta guía fija cómo encajan los recursos actuales.

## Medidas y posición

Todos los instrumentos nuevos usan **900×900 RGBA**. Las piezas del músico conservan **700×900** y el mismo origen superior izquierdo: los 200 píxeles nuevos están a la derecha. En Godot, el instrumento va a posición local `(0,0)`, con `centered = false`, en `Body/Torso/Rig/Guitar`. No centrar por el rectángulo visible ni aplicar otro desplazamiento después del registro.

| Perfil | Huella visible de referencia | Puente | Cejuela | Anchura admitida de variantes |
| --- | --- | --- | --- | --- |
| `guitar` | **477×233 px** | (300,495) | (606,390) | 440–520 px |
| `bass` | **572×315 px** | (247,518) | ≈(685,358) | 540–640 px |

La huella es el rectángulo ocupado por el dibujo, con alfa >32; no es el tamaño del lienzo ni la longitud física del instrumento. Los intervalos de altura y grosor del mástil están en cada `profile.json`. El cuerpo de referencia ocupa aproximadamente `(222,374)…(441,586)` en la guitarra y `(195,378)…(470,614)` en el bajo; sirve de guía, no obliga a que todas las siluetas sean iguales.

La guitarra de referencia es una **Jaguar custom marfil/burdeos**. Se corrigió el eje puente–diapasón conservando el cuerpo offset, las pastillas crema/oscura y la placa personalizada de tres mandos. La fuente vertical y la corrección están en [jaguar-custom-v01](../../../workspace/art-jobs/jaguar-custom-v01/README.md).

El mástil sube unos 19–20° hacia la derecha. El bajo prolonga el mástil **más allá de la mano**, hacia su cejuela y pala propias; no se reduce al tamaño de la guitarra. Los valores exactos se mantienen en [system.json](system.json), [guitar/profile.json](guitar/profile.json) y [bass/profile.json](bass/profile.json), que consumen las herramientas.

| Contacto común, en píxeles de la plantilla | Coordenadas |
| --- | --- |
| Pies/origen del músico | (350,900) |
| Pivote del torso | (355,560) |
| Centro de agarre 0 / 1 / 2 | (565,405) / (545,412) / (525,419) |
| Zona de pulsación/rasgueo | Alrededor de (352,480) |
| Unión de correa a revisar | Rectángulo (425,380)…(452,415) |

Además de tocar el diapasón, la mano debe conservar su base visible. Hay tres puntos de control bajo cada agarre: el instrumento tiene que ser transparente en ellos. El bajo v02 tapaba los nueve; el v03, subido 12 px, los deja libres. Son muestras de este rig, no una detección universal de manos. Siempre se revisan las seis poses.

El centro del diapasón también debe seguir la recta **puente–cejuela**: se comprueban cuatro secciones del tramo expuesto, con desviación máxima de 2 px. La referencia anterior pasaba los contactos de mano, pero se desviaba 3,5 px en la sección cercana al cuerpo. Esta prueba detecta ese problema. Los puntos de control solo sirven para los perfiles actuales; no detectan automáticamente las pastillas ni todas las cuerdas.

[Comparación de ambas guías](overview.png) · [Guía de guitarra](guitar/guide.png) · [Guía de bajo](bass/guide.png). Cada carpeta contiene también SVG editable, composición con el músico, PNG registrado y fuente de dibujo. Las guías muestran el eje puente–cejuela, los agarres naranjas, los puntos verdes que deben quedar descubiertos y la zona rosa de la mano que toca.

## Crear otro instrumento

Instalar las dependencias compartidas una vez:

```bash
npm install --prefix tools/art
```

1. Copiar y editar `art/briefs/instrument-guitar.json` o `instrument-bass-sg.json`. Elegir perfil, identidad, detalles y foto. Guardar las referencias dentro del repo; las rutas y sus roles quedan registrados. El orden de pastillas/pegatina de la SG pertenece a esa referencia, no a todos los bajos.
2. Preparar un encargo con nombre nuevo:

```bash
node tools/art/instruments.cjs prepare art/briefs/instrument-bass-sg.json --job mi-bajo-v01
```

Esto guarda prompt, referencias, fuente editable de construcción y guías exactas en `inputs/`, con hashes. **No genera una imagen ni crea exports finales.** Dos compañeros con las mismas entradas obtienen el mismo prompt; las generaciones de IA pueden variar.

3. Para una skin del mismo instrumento, abrir la referencia registrada o la fuente nativa en Krita, cambiar el acabado y conservar la geometría. Guardar el maestro como `.kra`/`.ora`. Para otro diseño, usar su foto como identidad y las guías como construcción. Una fuente vertical facilita conservar la simetría de una SG; otros diseños pueden ser asimétricos. Generar o dibujar el instrumento completo, sin manos, músico ni fondo. No intentar arreglar su encaje estirando cuerpo y mástil por separado.
4. Guardar el PNG de producción dentro de `source/`. En `measurements.json`, indicar su ruta, marcar `status: measured` y medir en ese PNG los centros del **puente** y de la **cejuela**. Completar también `axis_samples.neck_base` y `axis_samples.neck_mid`: centro del diapasón en su base y mitad. Esos puntos deben caer sobre la misma recta del puente y la cejuela. No copiar coordenadas de destino ni medidas de otra generación. Si se retocó la fuente nativa sin cambiar su geometría, sus puntos originales están en `profile.json`.
5. Registrar el instrumento completo con una transformación uniforme:

```bash
node tools/art/instruments.cjs register workspace/art-jobs/mi-bajo-v01
node tools/art/instruments.cjs check bass workspace/art-jobs/mi-bajo-v01/exports/instrument.png
```

Se produce `exports/instrument.png`, `registration.json` y `qa/instrument-check.json`. El registro alinea puente y cejuela, conserva el origen y comprueba tamaño, grosor del mástil, contacto con los tres agarres y visibilidad de la muñeca. Rechaza contenido recortado. Un fallo de dibujo se corrige en la fuente; un fallo de medición se corrige en las medidas. `register … --force` reconstruye deliberadamente ese mismo encargo; no sobrescribe exports existentes sin esa opción.

6. Revisar con el rig real, sin integrar todavía el recurso:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game \
  -s ../tools/art/render_instrument.gd -- \
  --asset workspace/art-jobs/mi-bajo-v01/exports/instrument.png \
  --out workspace/art-jobs/mi-bajo-v01/qa/poses
```

El ejemplo de ruta del ejecutable es para macOS; en otros sistemas usar el ejecutable local de Godot. Requiere backend gráfico. Por defecto usa al músico del sombrero rosa; admite `--character res://characters/protagonist/protagonist.tscn`. Sustituye la textura solo en memoria. Comprobar dedos, base de la mano, correa, mangas, todas las cuerdas, pastillas y orden de hardware. La animación actual es la del guitarrista; no certifica la técnica de pulsación de un bajista.

7. Registrar en el manifiesto generación real, modelo/seed solo si se conocen, fuente editable, hashes y revisión. Compartir los PNG finales; no volver a generarlos en cada ordenador. Integrar en el juego cuando ese trabajo forme parte del encargo.

## Mantener el sistema

```bash
node tools/art/instruments.cjs audit
node tools/art/test_instruments.cjs
```

El test recrea el bajo 12 px demasiado bajo y comprueba que se detecta el corte de la mano. Conserva también la Jaguar anterior como caso de prueba de eje desalineado. Verifica ambos instrumentos, transparencia, tamaño, preparación reproducible, registro desde la fuente, alineación del diapasón y protección de archivos existentes.

Las referencias y el rig se congelan en `sources.json`. Un drift obliga a revisar el cambio; no actualizar hashes automáticamente para hacer pasar un recurso nuevo. Un cambio de proporciones, manos, instrumento sentado o contactos incompatibles requiere otra versión de contrato. Un teclado o una batería requieren otra construcción. Para variaciones compatibles, conservar este perfil y crear otro encargo.

Las guías se reconstruyen con `node tools/art/instruments.cjs guides` desde las referencias congeladas; no es un generador de arte. El contrato del personaje y su pipeline anterior siguen describiendo las piezas originales de 700×900. El PNG de instrumento aislado de 900×900 se valida con este sistema.
