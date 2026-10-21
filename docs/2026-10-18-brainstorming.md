# Juego de banda — notas de brainstorming

Actualizado: 18 de octubre de 2026.

Documento vivo de la conversación con Juan. Recoge la dirección compartida y las ideas pendientes de probar; no es una especificación cerrada.

## Punto de partida y tono

- Juan y su hermano, ambos músicos, están ideando un videojuego. Su hermano propuso un gestor de locales de ensayo; Juan quiere explorar una experiencia más personal centrada en vivir el crecimiento de una banda.
- Eres el líder de la banda. Juan confirma que empiezas solo, probablemente en tu cuarto, y vas mejorando el local, el equipo, el repertorio y los bolos.
- Tono satírico hacia la industria musical, con situaciones reconocibles para músicos.
- Dirección deseada: incremental/clicker o una mecánica sencilla muy bien resuelta. Evitar por ahora muchas estadísticas y sistemas.

## Inicio y progresión de los espacios

- El comienzo es en solitario; el primer escenario que imagina Juan es tu cuarto.
- Juan propone una primera actuación en el parque, tocando solo para algún colega. Alguien que te escucha podría unirse porque le gusta lo que haces.
- Después se incorporan colegas y tocáis en un garaje.
- La progresión propuesta continúa con un local pequeño, después un local con ventanas y otros espacios mejores por definir.
- Los espacios deben ayudar a imaginar y mostrar el crecimiento de la banda. Todavía no se han definido costes, desbloqueos ni efectos en el juego.

## Pantalla principal, personaje y estética

- Juan acepta que la pantalla principal muestre el espacio como una pequeña maqueta abierta: en el cuarto se ve al protagonista con su instrumento, la cama, el ordenador, cables y un ampli.
- El encuadre sirve como referencia para mostrar después el garaje y los locales. Los objetos, músicos e instrumentos van ocupando el espacio a medida que progresas.
- Personalización del protagonista muy limitada. Para la primera versión, Juan confirma que el protagonista empieza con **guitarra eléctrica y un ampli pequeño**. En los mocks de gameplay debe conservar pelo negro, **gorra negra**, camiseta oscura, vaqueros y guitarra blanca con golpeador rojizo.
- Idea futura de Juan: cada instrumento puede corresponder a una **«build» distinta**, con una forma de jugar y desarrollarse propia. La elección de instrumento y las diferencias entre builds se definirán más adelante; no forman parte del alcance inicial.
- Juan acepta la dirección de ilustración 2D con caricatura suave y detalles reconocibles de la vida de músicos. Ejemplos propuestos: soportes improvisados, cables y un vecino molesto.
- Juan confirma **móvil en horizontal** para las imágenes de gameplay. La exploración v3 usa una proporción panorámica aproximada de 20:9 y controles táctiles.

## Historia y caminos de progreso

- A largo plazo, Juan quiere muchas opciones y caminos que vayan marcando el destino de la banda: crecer por internet, ir a sitios a presentarse, salir de fiesta y hacer contactos, entre otros.
- Para la primera versión, desarrollar un solo camino de historia. No construir todavía un sistema completo de rutas o estadísticas sociales.
- Secuencia de referencia, todavía flexible: cuarto en solitario → primera actuación en el parque → alguien se une a la banda → colegas en un garaje → locales cada vez mejores.
- Las condiciones para conseguir los primeros ingresos y fans todavía no están cerradas. El encuentro del parque aporta una posible primera recompensa narrativa: encontrar un compañero.

## Dinero y visibilidad

- Dos ejes principales: dinero y fans/visibilidad.
- El dinero sirve para pagar equipo, local, grabaciones, transporte y músicos.
- Los fans y la reputación abren puertas a mejores salas, oportunidades y conciertos. Gusta la idea de que no sean necesariamente una moneda que se gasta.
- Los bolos pueden plantear dilemas entre ingresos y visibilidad. Ejemplos propuestos: tocar versiones para financiar temas propios, o aceptar un festival que ofrece exposición en lugar de dinero.
- No está decidido si fans, reputación y estatus serán una sola medida; no añadir contadores por defecto.

## Los músicos y el liderazgo

- Las relaciones y los conflictos con los músicos forman parte de la fantasía de ser líder.
- Banda de amigos: mayor participación e implicación personal, con posibles conflictos, falta de preparación o excesos como situaciones de comedia.
- Músicos contratados/«mercenarios»: pueden ofrecer más previsibilidad, pero exigen honorarios y condiciones; podrían negarse a tocar si no se cumple lo acordado.
- Explorar ventajas y problemas diferentes, sin fijar todavía una progresión donde los amigos sean simplemente peores músicos.
- Hipótesis propuesta: los músicos permiten automatizar la actuación, pero son personas con preferencias y condiciones. Un rasgo claro por músico podría bastar al principio; no está cerrado.

## Referencias que hay que conservar para futuros mocks

- Según cuenta Juan, toca en **Depresión Sonora**.
- Tiene amigos en otras bandas de la escena y hay algunos miembros compartidos; menciona **Alcalá Norte** y **Carolina Durante** como referencias cercanas.
- Idea de Juan: incluir músicos de la escena con sus instrumentos para poder formar bandas mezcladas, por ejemplo el batería de una banda y el guitarrista de otra.
- Esta mezcla de músicos es una referencia importante para futuros mocks y para la fantasía de formar tu propia banda.
- Juan ha aportado tres fotografías y ha indicado rasgos visuales que deben conservarse: cowboy rubio con gafas y sombrero rosa; tupé, barba y chaleco de cuero; batería con gorra y barba; batería de Carolina Durante con pelo rizado rojo; bajista de Carolina Durante muy alto; y las siluetas características de Alcalá Norte.
- Las fotos se conservan en workspace/references/2026-10-18. Los roles no indicados por Juan y los nombres completos siguen pendientes; no atribuir los comportamientos satíricos a personas reales como si fueran hechos.

## Interacción musical: hipótesis por probar

- Juan propone que al principio puedas tocar tú: **cada clic hace sonar una nota y puedes tocar a la velocidad que quieras**. Un clicker con música.
- Una propuesta anterior fue representar el avance de una canción y obtener dinero/fans al terminarla; aún no se ha validado como mecánica definitiva.
- Después se puede explorar qué ocurre al incorporar músicos y automatizar partes de la interpretación.
- Prueba sugerida durante el brainstorming: cada clic recorre la siguiente nota de un riff preparado, después otro músico acompaña y, más adelante, la banda puede sostener el tema sola con intervenciones del jugador. Es una hipótesis, no una mecánica cerrada.
- Juan quiere que el progreso también se escuche: el inicio con un solo instrumento suena vacío y algo mal; al sumarse gente y mejorar los instrumentos, la banda suena cada vez mejor. Los escenarios acompañan esa evolución.
- Ejemplo sugerido: incorporar un bajista añade el bajo a la canción. La forma exacta de implementar las capas, la calidad y las mejoras está pendiente.
- El grado de intervención durante los bolos se decidirá con pruebas y feedback. No está decidido que el concierto sea pasivo, que sea un juego de ritmo o que haya penalizaciones por fallar notas.
- No cerrar todavía la mecánica: interesa encontrar primero una interacción sencilla que resulte divertida y musical.
- Restricción expresada por Juan: evitar que cada ronda obligue a escuchar tres minutos de un tema. La duración de las acciones, la estructura musical y el motor de sonido se definirán después; no dar por hecho que cada ronda equivale a una canción completa.

## Música y alcance actual

- Idea secundaria para más adelante: música de bandas que les gustan o versiones de sus bandas hechas con IA en distintos estilos.
- La selección y producción musical no deben bloquear la exploración del juego.
- Se han generado cuatro primeros mocks de fases del juego y una segunda exploración con dos hojas de personajes y un garaje más sencillo. No hay implementación ni animación todavía.
- Juan aprueba la estética más sencilla y los personajes de la segunda dirección. Pide mantenerlos y rehacer los menús, que no le gustan. Se mantiene la necesidad de un flujo consistente de producción y animación.
- Conservar v1 y v2. La serie workspace/mockups/2026-10-18-v3-mobile contiene cinco pantallas solicitadas para enseñar la idea a los compañeros de Juan: cuarto en solitario, incorporación de un artista tras tocar en el parque, garaje con varios músicos, Sala El Sol de Madrid y estadio como endgame. Variar la formación manteniendo al protagonista.
- Para El Sol se utiliza la fotografía aportada por Juan: escenario bajo y curvo de madera, cortinas rojas, rótulo El Sol, altavoces negros, paredes ocres y puerta amarilla. La referencia se guarda en workspace/references/2026-10-18/foto-04-sala-el-sol.png.
- La interfaz v3 propone recursos compactos arriba, navegación a la izquierda y acción a la derecha; diálogo de incorporación, retratos para cambiar la formación y acciones específicas en los conciertos. Son propuestas visuales pendientes de feedback.
- La propuesta de producción está en art-direction.md: modelos maestros por personaje, recursos separados y reutilizados, y una prueba de animación de un guitarrista antes de producir el reparto completo.
- El motor de sonido, las duraciones de las rondas y el motor del juego siguen abiertos. Las cifras y acciones de las interfaces generadas son ejemplos, no decisiones de balance.
