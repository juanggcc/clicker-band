# Clicker Band — dirección visual y producción, propuesta v2

Fecha: 18 de octubre de 2026.

## Cambio tras ver los primeros mocks

Juan quiere que los músicos de la escena se reconozcan y que el estilo pueda producirse y animarse durante el desarrollo del juego. Las primeras cuatro pantallas, conservadas en mockups/2026-10-18-v1, sirven como exploración de ambiente. Su renderizado detallado no se toma como objetivo obligatorio de producción.

La segunda exploración usa contornos claros, masas de color y menos textura. Incluye dos hojas de personajes y una revisión del garaje. Juan aprueba esta dirección gráfica y estos personajes. Rechaza los menús de v2 y encarga una serie para móvil horizontal con interfaz replanteada. Los PNG son imágenes compuestas; no contienen capas de brazos, instrumentos ni esqueletos de animación. Las hojas tienen canal alfa, pero necesitan limpieza, separación y normalización antes de convertirse en recursos de producción.

## Rasgos que deben conservarse

Según las instrucciones y fotografías de Juan:

- Cowboy: pelo rubio largo, gafas oscuras y sombrero rosa; chaqueta marrón en la referencia.
- Tupé: pelo elevado, barba y chaleco de cuero negro.
- Batería con gorra: gorra marrón, barba/bigote y sudadera clara.
- Batería de Carolina Durante: pelo rizado rojo/naranja.
- Bajista de Carolina Durante: muy alto, silueta alargada; jersey verde y burdeos en esta interpretación.
- Alcalá Norte: conservar las cinco siluetas de la foto aportada: abrigo largo y gafas con pelo claro; pelo largo oscuro, mangas claras y pantalón burdeos; gran pelo rizado y chaleco vaquero; pelo largo negro, gafas y camisa roja; polo de rayas azules y blancas.

No se han cerrado los nombres de todas las personas ni sus instrumentos. Los roles de los dos baterías y el bajista proceden de Juan; no asignar instrumentos a los demás como si estuvieran verificados. En el nuevo garaje, cowboy y tupé escuchan; tocan el protagonista, el batería con gorra y el bajista alto. El batería pelirrojo aparece en la hoja del reparto y puede ser una alternativa en la banda. Los rasgos visuales no implican personalidades ni comportamientos reales.

## Regla de producción

Crear una biblioteca de personajes y objetos reutilizables, y componer las escenas con esos mismos recursos. La generación de una pantalla completa sirve para explorar; no debe ser la forma de fabricar cada estado del juego. Usar prompts y referencias iguales ayuda, pero no garantiza identidad, escala ni geometría idénticas entre generaciones.

## Flujo propuesto

1. **Mantener la dirección aprobada de v2.** Fijar sus parámetros de producción: grosor de contorno, paleta, proporciones, vista del personaje y tamaño real en pantalla. La vista casi frontal en tres cuartos ayuda a limitar el número de ángulos necesarios. Reducir más pelo y pliegues si se pierden al tamaño de juego.
2. **Un modelo maestro por personaje.** Guardar la foto, una ficha de sus tres o cuatro rasgos imprescindibles y la ilustración seleccionada. Generar las variantes desde esa ilustración, con identificadores y versiones estables. Una imagen rechazada no sustituye al maestro.
3. **Separar personaje, instrumento y escenario.** Preparar un fondo vacío, objetos como ampli/sofá/batería, y personajes individuales. Dibujar el texto y la interfaz con código. No llevar la UI pintada de estos mocks al juego como una sola imagen.
4. **Preparar piezas para animar.** Separar cabeza/pelo, torso, brazos, antebrazos/manos y piernas; mantener instrumento aparte. Puede requerir recortar, limpiar y redibujar partes ocultas. La imagen generada no entrega automáticamente un personaje articulado correcto.
5. **Probar un personaje antes de producir todo el reparto.** Empezar por el guitarrista con reposo, tocar y una reacción breve. Mover cabeza, torso y brazo con pequeños ciclos; para el rasgueo bastan pocas poses de mano que se validarán visualmente. Evitar inicialmente caminar por todo el mapa, giros completos y sincronización detallada de dedos.
6. **Plantillas por instrumento.** Explorar una estructura compartida para guitarra/bajo y otra para batería; ajustar proporciones, manos, agarres y accesorios en cada personaje. El sombrero, los rizos y el chaleco permanecen ligados al mismo modelo. No prometer que un único esqueleto encaje sin ajustes con todos.
7. **Componer y verificar.** Usar posiciones predefinidas en cada cuarto/local, ordenar capas y sombras de apoyo, y comprobar a tamaño real: silueta reconocible, pies estables, manos sobre instrumento y ausencia de saltos al cambiar de estado. Las mejoras sustituyen objetos concretos, manteniendo el resto de la escena.

## Qué queda abierto

Motor del juego, herramienta de preparación de piezas, refinamientos del dibujo para producción, tamaño final de personajes, ángulos extra, nombres/roles pendientes y estructura musical. La dirección visual general de v2 ya está aprobada y la orientación de estos mocks es móvil horizontal. La elección de dibujo 2D no exige pixel art. La viabilidad de esta dirección debe comprobarse con un personaje preparado y animado, no solo con imágenes estáticas.

Godot es un ejemplo de motor que permite tanto animación de imágenes individuales/spritesheets como animación 2D con esqueletos; esto no constituye una elección de motor. Referencias técnicas consultadas:

- [Animación de sprites 2D](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)
- [Esqueletos 2D](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html) — la propia página avisa de que el tutorial está pendiente de actualizar para su versión estable actual; usarlo como orientación general, no receta de API cerrada.

## Entregables

- mockups/2026-10-18-v1: cuatro pantallas de la primera dirección.
- mockups/2026-10-18-v2: dos hojas de personajes, garaje simplificado y prompts completos.
- references/2026-10-18: las tres fotos aportadas por Juan, copiadas para que no dependan del portapapeles temporal.

Generación: herramienta integrada image_gen. No se ha usado la CLI ni se ha producido todavía una animación.


## Serie v3 — móvil horizontal

Juan solicita cinco pantallas para compartir la idea: cuarto, parque con incorporación de músico, garaje, Sala El Sol y estadio. El protagonista lleva gorra negra en todas y las formaciones cambian. Se usa v2 como referencia gráfica, el cuarto v3 como referencia común de protagonista e interfaz y la foto aportada para los rasgos arquitectónicos de El Sol.

La interfaz v3 explora controles táctiles grandes en los extremos, recursos compactos, diálogo de incorporación y acciones contextuales de ensayo/concierto. Se conserva cada prompt. El motor, las mecánicas finas y los números de balance no quedan fijados por las imágenes. Los recursos finales de UI se construirían con código.

Entregables: mockups/2026-10-18-v3-mobile, con cinco PNG, README, prompts y un ZIP para compartir. Generación mediante herramienta integrada image_gen.
