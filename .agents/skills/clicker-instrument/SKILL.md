---
name: clicker-instrument
description: "Crear o retocar guitarras y bajos aislados para Clicker Band, con escala, registro y contacto con las manos compartidos. Usar para instrumentos nuevos o skins compatibles con el músico de pie."
---

# Instrumentos de Clicker Band

Lee [el sistema de instrumentos](../../../art/instruments/standing-v1/README.md), el perfil elegido y [la biblia visual](../../../art/bible.md). El estilo es provisional. Los perfiles `guitar` y `bass` fijan construcción; una foto define identidad, silueta y hardware. La simetría y el orden de piezas de la SG son propios de esa referencia, no de todos los bajos.

Para otra postura, proporciones distintas o instrumentos sin mástil, establece otro contrato de contacto. No forzar batería o teclado dentro de estos perfiles.

## Producir

- Copia un brief de `art/briefs/instrument-guitar.json` o `instrument-bass-sg.json`. Prepararlo con `node tools/art/instruments.cjs prepare BRIEF --job ID` congela prompt, referencias, fuente y guías. No llama a una IA y no produce arte final.
- Para una skin compatible, retoca las mismas piezas en Krita. Para otro diseño, usa la herramienta de imagen disponible siguiendo su skill, inspecciona los PNG reales y asigna a cada referencia su papel: identidad, acabado o construcción. Conserva una fuente completa del instrumento, sin manos ni músico; una vista vertical ayuda con una SG simétrica. Un cambio de posición se resuelve por registro, sin volver a generar el dibujo.
- Guarda la fuente en el encargo. Mide en ella el centro del puente y de la cejuela, más el centro del diapasón en la base y la mitad (`axis_samples`); completa `measurements.json` con `status: measured`. Los cuatro puntos deben seguir el mismo eje recto. Los puntos de la fuente de referencia solo se reutilizan si no se cambió su geometría. Ejecuta `node tools/art/instruments.cjs register workspace/art-jobs/ID`.
- Usa una transformación uniforme para todo el instrumento. Las variantes se ajustan a su perfil, no se encogen para caber en el lienzo antiguo. Los instrumentos exportan 900×900, ampliando solo a la derecha; el músico sigue en 700×900. Mismo origen, posición local `(0,0)`, `centered=false`.

## Revisar y entregar

Ejecuta `check PERFIL PNG` y `audit` con esa herramienta. Comprueba las seis poses con `tools/art/render_instrument.gd` según el manual. Los puntos verdes de la muñeca deben quedar descubiertos y los tres agarres deben seguir sobre el diapasón. Las cuatro secciones expuestas del mástil deben quedar centradas en la línea puente–cejuela; la comprobación de eje detecta el quiebro de la antigua referencia de Jaguar. El test técnico no verifica número de cuerdas, pastillas ni técnica musical: inspecciona la silueta, el orden de hardware, la correa y todas las manos. No estires partes por separado para superar una comprobación.

Conserva PNG, fuente editable, medidas, transformación, prompt y metadatos reales. Un proveedor/modelo/seed no expuesto queda en `null`. Comparte los PNG aceptados para que todos usen el mismo recurso. Integra en `game/` cuando el usuario incluya esa tarea; una entrega de sprite puede quedarse en `workspace/art-jobs/`.

Si cambian las manos o proporciones, revisa/versiona la construcción. No refresques hashes de referencias para ocultar un fallo de encaje de un instrumento nuevo.
