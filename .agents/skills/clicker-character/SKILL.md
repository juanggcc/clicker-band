---
name: clicker-character
description: "Crear o retocar músicos para Clicker Band con referencias compartidas, piezas registradas y la plantilla de guitarristas de pie. Usar para nuevos guitarristas, skins o preparación de personajes; adaptar otra familia cuando cambien instrumento, postura o proporciones."
---

# Personajes de Clicker Band

Trabaja desde la raíz del repo. Lee [art/README.md](../../../art/README.md), [la biblia visual](../../../art/bible.md) y `art/style-v0.json`. El estilo es **muy provisional**: sus referencias sirven para comparar, no implican una dirección definitiva. Estructura de animación, identidad y estilo son decisiones independientes.

## Elegir la construcción

Para un guitarrista de pie compatible con las proporciones actuales, lee [la receta de la familia](../../../art/templates/guitar-standing-v1/procedure.md) y `template.json` a su lado. Usa `family: guitar-standing-v1` en el brief. La revisión v1 corrige el encaje de cuello/camiseta y conserva los puntos del rig anterior. La familia contiene siete piezas exactas, un editable OpenRaster, una composición neutral y marcadores del rig. Revisa ampliada la unión del cuello antes de usar un maestro para otra identidad. No sustituir ese procedimiento por generar un cuerpo parecido.

Para crear o retocar el instrumento aislado, usa también [clicker-instrument](../clicker-instrument/SKILL.md) y [su contrato de guitarra/bajo](../../../art/instruments/standing-v1/README.md). Las piezas del músico siguen en 700×900; los instrumentos nuevos usan 900×900 ampliando solo a la derecha y se validan con su herramienta propia. No aplicar `check character` a ese PNG aislado.

Para un personaje con otras proporciones, un bajo con otros contactos o un batería, identifica qué puede compartir y qué necesita un contrato propio. No forzar un cuerpo distinto estirando partes de manera independiente. Mantén el trabajo útil: maestro/brief/boceto y propuesta concreta de uniones antes de ampliar el rig.

## Preparar y producir

1. Crea un brief JSON siguiendo `art/briefs/protagonist-pilot.json`, con identidad, ropa, pose, luz y rasgos que preservar. Una foto identifica al nuevo músico; la plantilla determina construcción y las referencias de estilo determinan acabado. Añade referencias como objetos con `path` relativo al repo y `role` explícito. No deducir identidades o instrumentos de personas reales.
2. Ejecuta `python3 tools/art/pipeline.py prepare ruta-del-brief --job identificador-v01`. No sobrescribe encargos. Revisa su `prompt.txt` y las copias de `inputs/`; si faltan datos de identidad esenciales, acláralos mientras preparas lo independiente.
3. Para la familia de guitarra, abre el `source.ora` del encargo en Krita. Son capas en coordenadas originales: la vista del editable no incorpora los desplazamientos del brazo del mástil que aplica el motor. Los `exports/` iniciales todavía son el protagonista. Mantén uniones y lienzo; edita o redibuja sobre esas mismas capas. Usa `assembly.png` como referencia del resultado montado.
4. Si hay herramienta de imagen disponible, usa el prompt preparado y adjunta los PNG reales pertinentes, que debes inspeccionar primero. La guía SVG es para el editor; adjuntarla a una herramienta de imagen solo si esa herramienta admite SVG. Para edición, sigue la skill de generación de imágenes disponible en la sesión. Pide cambios acotados y compón el parche aceptado con máscaras para conservar el resto. Si la herramienta no está disponible, entrega el paquete para producción manual; no inventes una ejecución, modelo, seed o capas que no se produjeron.
5. La separación automática es opcional: compara su compuesto y corrige piezas/zonas ocultas antes de usarlo. Una imagen de piezas sueltas no es un archivo registrado. Mantén el lienzo completo de 700×900 y exporta nombres exactos según `art/contracts/character-v2.json`. Los offsets de brazo/dedos los aplica Godot; no hornearlos en sus PNG.
6. Como límite inicial de trabajo, intenta una selección y hasta dos correcciones locales. Si un defecto estructural persiste, cambia el boceto o resuélvelo en el editable; conserva el trabajo aceptado. Ajusta este límite si el usuario indica otra preferencia.

## Verificar e integrar

Con Pillow disponible, ejecuta `check character` sobre los exports. Mide y revisa `landmarks.json`; `check-landmarks` solo compara los puntos declarados. Renderiza seis poses con `tools/art/render_guitar.gd`, siguiendo el comando de la receta, y revisa dedos, contacto con mástil, costuras y silueta. Comprueba en el juego la intensidad baja/alta y el tamaño móvil con HUD. Un test de PNG no certifica la calidad visual.

Si el encargo incluye integrar, copia solo los recursos revisados al directorio propio de ese músico y usa `guitar-scene` para crear una escena heredada. No se necesita duplicar el código de animación. No modificar el personaje anterior para fabricar la variante. Si cambia la construcción, versiona la familia y prueba a quienes la compartan.

Registra en el manifiesto el proveedor/modelo realmente expuesto, parámetros, intentos, retoques, tiempos, editable, hashes de entregables y resultado de revisión. Un dato no expuesto queda en `null`. Entrega el recurso y una vista de revisión; indica qué queda pendiente. Guardar fuentes útiles en `workspace/art-jobs/`, no en las carpetas ignoradas `output/` o `references/`.
