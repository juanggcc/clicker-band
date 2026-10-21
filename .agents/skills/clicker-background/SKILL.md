---
name: clicker-background
description: "Crear o retocar fondos vacíos de Clicker Band con la paleta, referencias y cámara compartidas, preparados para colocar músicos y objetos por separado. Usar para habitaciones, garajes, parques y escenarios del juego."
---

# Fondos de Clicker Band

Trabaja desde la raíz del repo. Lee [la biblia visual](../../../art/bible.md), `art/style-v0.json` y [el contrato de fondo](../../../art/contracts/background-v1.json). La dirección es **muy provisional**; no convertir el acabado actual en una decisión definitiva. El mundo ilustrado y la UI pixel son familias diferentes.

1. Crea un brief siguiendo `art/briefs/garage-pilot.json`. Especifica local, iluminación, composición y suelo libre para músicos. Añade un boceto de distribución si importa la posición de objetos. Las referencias de arquitectura, estilo y layout tienen roles distintos; guárdalas en el repo con esos roles.
2. Ejecuta `python3 tools/art/pipeline.py prepare ruta-del-brief --job identificador-v01`. Usa el `prompt.txt` y sus entradas exactas. El comando no genera imágenes ni modifica el juego. No sobrescribir otro encargo.
3. Si existe una herramienta de imagen, inspecciona los PNG de referencia antes de adjuntarlos y sigue la skill de imágenes disponible en la sesión. Usa la referencia del dormitorio para acabado y escala; no copiar su mobiliario si se está creando otro local. La captura de HUD no es una referencia para pintar interfaz. Sin herramienta disponible, deja el paquete listo para producción manual y explica ese límite.
4. Producir el local vacío. Los personajes, instrumentos y objetos que se compran o mueven se componen por separado. Preservar el recorte 16:9 central y las zonas de UI. El PNG final es opaco y mide 2400×1080; si el generador devuelve otro tamaño, ajustar encuadre/extender en el editor y verificar el export. No afirmar que un prompt garantiza geometría exacta.
5. Distinguir coordenadas de imagen y mundo: en la escena actual imagen x=0 corresponde a mundo x=-240. Pies en mundo (760,1000) son imagen (1000,1000). Para otras posiciones, transformarlas usando el contrato y probarlas con el rig o siluetas en Godot. Evitar elementos imprescindibles en los 240 px laterales de expansión.
6. Retocar zonas concretas en un editable y conservar lo aceptado. Una selección y hasta dos correcciones locales son el límite inicial sugerido; si falla el espacio para músicos o la perspectiva, corregir el boceto en vez de acumular regeneraciones. Adaptar ese límite a instrucciones del usuario.

Comprueba el PNG con `python3 tools/art/pipeline.py check background ruta.png` usando el entorno con Pillow. Revisa además en Godot a 16:9 y pantalla ancha, con los músicos y el HUD a escala real: suelo, oclusiones, luz y legibilidad. La prueba técnica solo comprueba formato, dimensiones y opacidad.

Guarda original, editable, export y revisión en `workspace/art-jobs/<id>/`. Rellena modelo/proveedor realmente expuestos, parámetros, intentos, tiempos y entregables en el manifiesto; lo desconocido permanece `null`. Si el usuario ha pedido integrar, instala el fondo revisado y verifica la escena. Entrega una vista del resultado y comunica lo pendiente sin marcar como revisada una imagen que no hayas visto.
