# Estado de la primera entrega del sistema

Registro de la primera entrega. Después se corrigió la unión del cuello y se produjo una segunda identidad: [músico del sombrero rosa](../workspace/art-jobs/cowboy-piloto-v01/README.md), con la revisión de construcción v1. Las limitaciones y pendientes que siguen describen el estado anterior a ese piloto.

21 de octubre de 2026. La dirección visual sigue siendo muy provisional. La familia de guitarra formaliza el montaje existente; aún no está validada produciendo una segunda identidad.

## Comprobado

- 16 comprobaciones del pipeline en una copia temporal: mismas entradas producen el mismo prompt, se conservan hashes, no se sobrescriben encargos, se rechazan tamaños/alfa incorrectos, se distinguen puntos copiados de mediciones y se detectan cambios en referencias. La composición y el editable OpenRaster se reconstruyen con los mismos bytes. Repetible con el entorno de arte: `python tools/art/test_pipeline.py`.
- Los PNG actuales del protagonista y el dormitorio cumplen las dimensiones y transparencia de sus contratos.
- Las dos skills pasan el validador de `skill-creator`. Se guardan en `.agents/skills/` del repo; su disponibilidad en otro equipo requiere compartir esos archivos y abrir el repo en Codex.
- Pruebas existentes del juego: **47 de lógica + 45 de integración de UI**, sin fallos.
- Una escena heredada temporal, con las siete texturas copiadas a un directorio distinto, pasa **153 comprobaciones**: cada recurso se toma del directorio de la variante, la malla usa su brazo propio, brazo/dedos comparten desplazamiento y la unión de rasgueo queda fija. Las copias y escena de prueba se retiran tras verificar; no se añade otro personaje al juego.
- Se renderizaron e inspeccionaron los tres agarres y los dos extremos del rasgueo con el rig real. [Lámina de las seis poses](../workspace/art-jobs/protagonista-piloto-v01/qa/six-poses.png). Se conserva la construcción, no se certifica un estilo final ni la correspondencia de los agarres con acordes reales.
- El editable `registered-parts.ora` contiene siete capas con sus PNG originales sin recortar ni hornear offsets. El compuesto neutral aplica los offsets del runtime; la vista inicial del editable conserva coordenadas de dibujo.

Los runners terminaron con código 0. El motor emitió mensajes del entorno de macOS/sandbox sobre certificados y guardado de ajustes del editor; no hubo fallos de comprobaciones ni errores de script. El render gráfico terminó correctamente con OpenGL en Apple M1.

## Pendiente del piloto artístico

Producir una segunda identidad con la plantilla, aprender/exportar desde el editor del equipo, medir tiempos y revisar a tamaño móvil. No se ejecutaron Qwen, Scenario, Layer ni PixelLab sobre vuestro arte: la investigación documenta capacidades y propone compararlas; no afirma resultados medidos ni superioridad de un modelo.

No se generó un nuevo fondo ni otro músico, no se entrenó un modelo, no se contrató software y no se verificó una nueva exportación Android. Los ejemplos de `../workspace/art-jobs/` son paquetes preparados, no entregas de arte terminadas. El único cambio en el comportamiento configurable del personaje es que la textura de su brazo de rasgueo se puede sustituir desde una escena heredada; su valor por defecto sigue siendo el original.
