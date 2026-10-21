# Investigación del flujo de arte de Clicker Band

21 de octubre de 2026. Contexto: tres personas, empezar sin nuevas suscripciones y aprender a retocar. Revisión de documentación oficial, trabajos de autores y casos publicados; no es una prueba comparativa de los generadores en vuestro proyecto. Las recomendaciones son una valoración para este juego. Los resultados comerciales citados por proveedores no se toman como mediciones independientes.

## Recomendación

**Krita + recursos maestros compartidos + marioneta híbrida en Godot.** Usar la IA disponible para bocetos, bases y retoques acotados. Separar y completar las piezas en un archivo editable; conservar esas piezas en lugar de regenerarlas. Probar Qwen-Image-Layered como ayuda para la separación antes de montar infraestructura local. Para la interfaz pixel, usar Pixelorama o los generadores geométricos existentes.

No contrataría otro servicio ni entrenaría una LoRA todavía. Primero produciría un segundo músico y un fondo con este sistema, midiendo tiempo hasta su integración. Si preparar capas sigue siendo el cuello de botella, probaría una herramienta de descomposición. Si el problema pasa a ser mantener el estilo en muchos recursos nuevos, entonces evaluaría entrenamiento de estilo. Son problemas distintos.

El sistema inicial está en [art/README.md](../../art/README.md). Es un borrador operativo basado en los recursos actuales, no una nueva dirección artística aprobada.

La ampliación solicitada durante la investigación es una [familia de construcción por instrumento/postura](../../art/templates/guitar-standing-v0/procedure.md): piezas registradas, puntos del rig y escenas heredadas. El primer guitarrista proporciona la geometría que se reutiliza; las siguientes identidades se editan sobre esa plantilla. El estilo sigue siendo muy provisional y puede sustituirse conservando esas uniones. La primera familia aún necesita probarse produciendo un segundo músico.

## Qué está ocurriendo en este repo

La inspección incluye las ilustraciones actuales y el montaje real de `game/characters/protagonist/`:

- El protagonista y el dormitorio son ilustración de contorno suave. El HUD y la tienda tienen vocabulario pixel propio. «Hacerlo todo pixel art» sería un cambio de dirección, no una solución técnica neutra.
- El brief de sprites v1 pedía una ilustración y seis capas que encajaran sobre 700×900. Esa petición mezcla creación del diseño, anatomía, reconstrucción de zonas ocultas y registro de las piezas. Un buen resultado estático no demuestra que esas cuatro cosas estén resueltas.
- El rig vigente ya no coincide con ese brief: cabeza/cuello/camiseta unidos en `body_core`, brazo del mástil detrás, dedos delante de la guitarra y manga del rasgueo cubriendo la unión de una malla. `animation-pipeline-v2.md` y la escena son la referencia para el montaje existente.
- `registration.json` describe transformaciones de fuentes antiguas; no es un contrato del rig vigente. No debe copiarse como si lo fuera.
- Parte de las fuentes y verificaciones de retoques está documentada en `workspace/output/`, que no entra en Git. Tampoco se comparten las exploraciones de `workspace/references/` y `workspace/mockups/`. Los tres no pueden reconstruir el contexto solo con un clon.
- Hay una confusión de coordenadas en el fondo: pies del protagonista en **mundo (760,1000)** equivalen a **imagen (1000,1000)**. El PNG de 2400 px se centra en x=960; empieza en mundo x=-240.

## Cómo se está resolviendo en otros proyectos

### Un dibujo reutilizable y animación controlada

El recorte permite retocar una sola ilustración y reaprovecharla en los ciclos. La documentación de Godot contempla combinar recortes con fotogramas para manos o expresiones y deformaciones con Polygon2D. Esto respalda una solución híbrida; no obliga a cortar todas las articulaciones ni a construir un esqueleto completo. La página avisa de que su contenido aún no está actualizado para Godot 4.7: hay que comprobar los detalles contra el motor y la escena reales. [Godot: cutout animation](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html).

**Aplicación:** conservar identidad con el mismo dibujo; animar poco pero con buen ritmo. La marioneta no reduce por sí sola el trabajo de dibujar zonas que nunca existieron debajo del instrumento.

### Recetas versionadas y recursos finales congelados

Carlos Luna documenta en *Skaldborn* una producción con Stable Diffusion/ComfyUI y PixelLab. Guarda recetas con parámetros y anclajes, revisa los candidatos y publica archivos finales fijados por contenido. La idea útil para nosotros es conservar la receta y el recurso aceptado. Su cola, base de datos y telemetría son infraestructura de su proyecto, innecesaria para tres personas empezando. Es un caso concreto, no una demostración de que ese stack sea mayoritario. [Devlog del autor, mayo de 2026](https://www.skaldborn.com/devlog/04-art-content-pipeline/).

**Aplicación:** un JSON y una carpeta por encargo, referencias con hash y revisión de la integración. La imagen aprobada es la fuente estable; volver a ejecutar un prompt no es una copia de seguridad.

### Entrenar estilo, controlar estructura y retocar después

Scenario documenta una secuencia de preparar ejemplos, entrenar, probar, controlar la pose/composición mediante referencias y retocar zonas concretas. Esa secuencia es más informativa que la promesa de generar recursos «consistentes»: incluye selección y corrección. [Workflow oficial de Scenario](https://help.scenario.com/articles/7094354401-building-workflows-in-scenario).

Layer publica el caso *Foster: Leyfront Tactics*, que utiliza un modelo de estilo y workflows para producir familias de recursos. Es un caso presentado por el propio proveedor; no usaría sus cifras de ahorro para presupuestar nuestro juego. [Caso de Layer](https://layer.ai/games/foster).

**Aplicación:** separar la receta de estilo de la identidad del músico y del control de pose. Entrenar no proporciona automáticamente agarres correctos sobre una guitarra.

### Resolver animaciones desde una fuente 3D

Thomas Vasseur, artista de Motion Twin, explica cómo *Dead Cells* modela y anima en 3D y renderiza fotogramas 2D. El coste inicial del modelo compensa cuando se necesitan muchas poses y revisiones del movimiento. No es un flujo de IA y no hace falta copiar su estética pixel para entender la ventaja. [Artículo del propio artista, 2018](https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-).

**Aplicación:** si más adelante necesitáis caminar, girar y tocar desde muchos ángulos, reevaluar Blender y render a sprites. Para unos músicos casi fijos, introduce bastante aprendizaje antes de producir el primer resultado.

## Herramientas: qué aportan y qué queda por hacer

| Opción | Qué resuelve | Límite para Clicker Band | Decisión inicial |
| --- | --- | --- | --- |
| Krita | Dibujo, selección, máscaras, capas, archivo maestro editable y exportación | Aprender selección, rellenar zonas ocultas y limpiar bordes | Herramienta común de preparación |
| Godot nativo | Ritmo, transformaciones, mallas pequeñas y cambios de pose integrados | La geometría y el dibujo deben ser adecuados | Mantener el rig híbrido y simplificar donde sea posible |
| Pixelorama | Paletas, edición pixel y animación por fotogramas | No conserva por sí solo el trazo suave de la ilustración actual | HUD/iconos y pequeños efectos |
| Krita AI Diffusion | Retocar una selección con guía visual dentro del editor | Necesita backend, modelos compatibles y capacidad de cómputo o servicio cloud | Opcional después del piloto manual |
| ComfyUI | Guardar el grafo de generación, referencias, controles y parámetros | Configuración, dependencias y mantenimiento; no es un artista automático | Fase posterior si se justifica el uso repetido |
| Qwen-Image-Layered | Descomposición generativa a capas RGBA | No garantiza piezas anatómicas, reconstrucción fiel ni pivotes de animación | Primera prueba técnica opcional para ahorrar recorte |
| Scenario | Modelos de estilo/personaje, edición y workflows de equipo | Entrenamiento y colaboración dependen del plan; exige dataset y evaluación | Comparar más adelante, sin contratar ahora |
| Layer | Referencias compartidas, entrenamiento, workflows y separación a capas/PSD | Generación y separación consumen unidades; salida necesita revisión | Alternativa cloud para comparar si hace falta |
| PixelLab | Pixel art con referencias, paletas y animación guiada por poses | La ruta de esqueleto consultada trabaja en lienzos pequeños, no en nuestro músico de 700×900 | Candidato si elegís deliberadamente producción pixel |
| Spine | Editor especializado para preparar y animar rigs, mallas y skins | Compra, aprendizaje e integración; no fabrica un dibujo bien separado | Posponer hasta que animar sea el cuello de botella |
| Midjourney | Exploración visual y referencias de estilo/personaje | No entrega un rig registrado; pequeñas características pueden cambiar | No añadir otra suscripción para resolver este problema |
| Recraft | Estilos reutilizables, paletas y recursos gráficos/vectoriales | No es un sistema de animación anatómica | Interesante para iconografía; el repo ya resuelve buena parte de ella |
| Blender / Grease Pencil / render 3D | Fuente editable y reutilizable para muchos ángulos | Mayor coste inicial de modelado/rig/iluminación | Reabrir la decisión si crece el movimiento |

### La base gratuita

Krita es gratuito y de código abierto. Su **Batch Exporter**, incluido entre los plugins de Python, exporta capas; no es un separador anatómico. Su función **Split Layer** separa por color, que tampoco equivale a separar brazo, torso y guitarra. Hay que distinguir exportación, segmentación y reconstrucción. [Krita](https://krita.org/), [Batch Exporter](https://docs.krita.org/en/reference_manual/default_python_plugins.html), [Split Layer](https://docs.krita.org/en/reference_manual/split_layer.html).

Pixelorama es gratuito y ofrece capas, paletas y spritesheets. Lo usaría para la parte pixel existente. Aseprite también puede exportar capas y secuencias, pero no hace falta comprarlo para iniciar este sistema. [Pixelorama](https://pixelorama.org/), [exportación de Aseprite](https://www.aseprite.org/docs/exporting/).

Blender permite trabajar con dibujo 2D dentro de una escena 3D mediante Grease Pencil. Es una alternativa de producción, no una instalación necesaria para empezar. [Blender: Grease Pencil](https://www.blender.org/features/grease-pencil/).

### IA dentro del editor: control sin regenerarlo todo

Krita AI Diffusion distingue referencias de estilo y composición de controles de línea, profundidad o pose. Esto encaja mejor con «conserva este torso y corrige esta manga» que una conversación que vuelve a describir al personaje entero. No todos los controles están disponibles con todos los modelos. [Control Layers](https://docs.interstice.cloud/control-layers/).

El plugin necesita un backend. La documentación distingue servicio online, servidor local gestionado y servidor ComfyUI propio. El cómputo cloud puede costar dinero; software abierto no significa GPU gratuita. La instalación local depende del hardware y del modelo, por lo que no la impondría a los tres antes de probar un caso. [Instalación y requisitos](https://docs.interstice.cloud/installation/).

ComfyUI permite compartir workflows, incluso en los metadatos de imágenes de sus ejemplos. Eso ayuda a conservar el procedimiento; para repetirlo también importan las versiones de nodos, pesos, ajustes y entorno. Un JSON o una seed aislados no sustituyen al recurso final guardado. [Ejemplo oficial con workflow y seed](https://docs.comfy.org/tutorials/api-nodes/stability-ai/stable-image-ultra).

### Separación automática: la prueba más relevante

Qwen-Image-Layered produce capas RGBA y admite descomposición recursiva. Su repositorio enlaza demostraciones y ofrece exportaciones de capas. Es una ayuda que sí ataca una parte del trabajo actual. No he ejecutado el modelo sobre vuestro personaje: faltan medir fidelidad del compuesto, separación de manos/instrumento y tiempo de limpieza. [Repositorio oficial](https://github.com/QwenLM/Qwen-Image-Layered).

Layer ofrece separación a elementos editables y exportación PSD. Su guía indica que se cobran unidades por cada capa producida. Eso permite comparar una separación cloud con recortar a mano, pero no demuestra que entregue hombros o codos preparados para nuestro movimiento. [Función](https://layer.ai/features/split-into-layers), [guía de uso](https://help.layer.ai/articles/7123141592-split-an-image-into-layers).

**Prueba propuesta:** usar una copia del mismo maestro; pedir pocas piezas; recomponer sin animación; después probar los dos extremos del rasgueo. Si corregir la salida lleva más que recortar y completar en Krita, abandonar esa ruta para ese recurso. No encadenar nuevas generaciones intentando arreglar indefinidamente el resultado anterior.

### Plataformas de estilo y costes del equipo

Scenario diferencia entrenamiento de estilo y de personaje, y permite comparar checkpoints. Sus recomendaciones de cantidad de imágenes dependen del modelo; no son una garantía ni un requisito universal para cualquier LoRA. No entrenaría con muchas variantes incoherentes del mismo músico: el conjunto debe mostrar el estilo en sujetos y composiciones distintos. [Entrenamiento oficial](https://www.scenario.com/features/train).

La página de precios consultada muestra Starter como espacio de un usuario, Pro con entrenamiento y Max con colaboración para equipos. Ofrece créditos de prueba; eso no equivale a entrenamiento y producción ilimitados gratis. Los importes y la facturación deben verificarse al contratar. [Precios de Scenario](https://www.scenario.com/pricing).

Layer declara miembros sin coste adicional en una suscripción y cobro por uso. Su calculadora dinámica no permite deducir aquí un presupuesto cerrado para tres personas. La generación por lotes y los workflows guardados sí son capacidades documentadas. [Precios de Layer](https://layer.ai/pricing), [lotes y workflows](https://layer.ai/features/batch-generation).

**Nuestra elección:** cero nuevas suscripciones en esta fase. No prometer IA ilimitada gratis: se puede trabajar sin IA, usar los accesos ya disponibles o realizar pruebas limitadas. Mantener el contrato del recurso independiente del proveedor permite cambiar más tarde sin rehacer el juego.

### Generadores generalistas y consistencia

La documentación de OpenAI reconoce límites tanto para personajes recurrentes como para composición precisa. Más instrucciones pueden ayudar, pero no convierten el generador en un sistema de coordenadas ni en un editor de capas. Aquí no se identifica qué modelo de imagen utilizó cada conversación anterior con Astra: no se debe inventar a partir del nombre del asistente. [Limitaciones de generación de imágenes](https://developers.openai.com/api/docs/guides/image-generation#limitations).

Midjourney ofrece referencias de identidad y estilo; su documentación diferencia Omni Reference en V7 de Edit Model en V8.X y advierte de cambios posibles en detalles. Una receta debe guardar la versión real, no copiar parámetros de tutoriales de otra versión. [Documentación oficial](https://docs.midjourney.com/hc/en-us/articles/36285124473997-Omni-Reference).

Recraft documenta estilos compartidos y paletas guardadas. Es pertinente para familias gráficas, pero no demuestra consistencia de agarres ni animación de músicos. [Sistema de estilo y paleta](https://www.recraft.ai/blog/from-logo-to-full-brand-kit).

## Marioneta, fotogramas o 3D

| Necesidad | Primera opción | Motivo |
| --- | --- | --- |
| Respirar, marcar el pulso, inclinarse y rasguear sin girar | Recortes con solapes + deformación localizada | Reutiliza el dibujo y sincroniza intensidad sin nuevas imágenes |
| Manos, baquetas, parpadeo o gesto que rompe la silueta | Pocas poses dibujadas, alineadas al mismo maestro | Evita estirar anatomía que necesita otro dibujo |
| Caminar, cruzar brazos, girar el cuerpo o muchos ángulos | Evaluar animación por fotogramas o una fuente 3D | El dibujo original carece de superficies que se revelarán |
| Muchos personajes, skins y animadores dedicados | Comparar Godot con Spine mediante un piloto | El editor especializado podría compensar el coste de migración |

Spine tiene runtime oficial para Godot, con rutas de GDExtension y módulo del motor. Es una integración real que debe probarse en vuestra versión y en exportación Android; no basta con verlo en el editor. Essential no incorpora todas las funciones de Professional, incluidas mallas. No lo compraría esperando que arregle automáticamente el arte. [Runtime](https://us.esotericsoftware.com/spine-godot), [comparativa de ediciones y compra](https://us.esotericsoftware.com/spine-purchase).

Para Clicker Band elegiría **marioneta híbrida y movimiento limitado**. Es una recomendación a partir del juego observado. Si el piloto de dos músicos no convence, se revisa antes de extenderlo a todo el reparto.

## Cómo sostener el estilo a largo plazo

1. **Referencias visuales fijas:** maestro de personaje, fondo y comparación con HUD. Guardadas en el repo, con versión, procedencia y hash. No depender del historial de un chat.
2. **Paleta con función:** colores de UI exactos; familias de color orientativas para la ilustración, con sus sombras y luces. La imagen actual tiene suavizado y variaciones: no es una paleta indexada.
3. **Reglas observables:** proporciones, trazo, sombras, cámara, tamaño de lectura y detalle. Las referencias de identidad no sustituyen al estilo, ni una pose sustituye a la identidad.
4. **Receta compartida:** bloque de estilo + brief del recurso + referencias + contrato técnico. Mismo texto entre los tres, con registro de proveedor y parámetros realmente expuestos.
5. **Maestros editables y piezas estables:** las zonas ya resueltas se retocan o reutilizan. Los estados de gameplay no vuelven a generar el personaje entero.
6. **Prueba integrada:** revisar a tamaño móvil y en movimiento. Un validador puede detectar dimensiones o transparencia; no puede certificar buen gusto, anatomía ni agarres.

Ni un prompt, ni una seed, ni una LoRA garantizan que todas las generaciones futuras sean iguales. **Sí podemos compartir el mismo proceso y usar exactamente los mismos archivos finales.**

## Piloto y criterio de decisión

Hacer tres encargos pequeños: un segundo guitarrista compatible con la puesta en escena, un fondo de garaje sin personajes y una variante de objeto. Una persona produce, otra revisa el estilo y otra comprueba la integración; rotar los papeles en el siguiente encargo.

Registrar intentos, minutos de generación/selección, preparación, animación y corrección después de integrar. Una propuesta de límite para el piloto es una selección inicial y dos correcciones localizadas; si no funciona, cambiar el boceto o resolver a mano. Es un límite de trabajo acordable, no una propiedad del modelo.

Comparar el segundo encargo con el primero. Solo ampliar el pipeline si reduce el tiempo hasta un recurso aceptable y otra persona puede repetir los pasos desde el clon. No hay todavía cifras medidas ni un ganador demostrado sobre vuestro arte.

Orden de pruebas si queda fricción: **Krita manual → descomposición de capas → control visual en Krita → entrenamiento de estilo → editor de rigs especializado**, según el problema observado. No hace falta instalar toda esa cadena.
