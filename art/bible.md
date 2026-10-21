# Biblia visual v0 — borrador de producción

Estado: referencia provisional extraída del juego el 21-10-2026. Validar en el piloto antes de declarar una dirección v1. Los números propuestos de trazo y detalle son guías de retoque, no mediciones ni promesas de precisión de una IA.

## Aspecto y lectura

El mundo y los músicos usan ilustración 2D de contorno oscuro, bordes suavizados y sombras de planos amplios. Mantener materiales y siluetas claros. Evitar añadir microtextura al producir recursos nuevos; si se busca simplificar, acordar la simplificación en un maestro antes de extenderla al resto.

El HUD usa pixel, paneles oscuros, Silkscreen, menta/ámbar/coral. Se conserva como familia de interfaz. No aplicar automáticamente ese acabado a personajes y fondos. Los textos, botones y cifras siguen siendo UI del motor.

Comparar cada candidato con `anchors/v0/protagonist.png` y `anchors/v0/bedroom.png`. La captura de HUD es solo una referencia de composición e integración: no se adjunta como estilo para pedir una imagen con interfaz pintada.

## Paleta

La fuente editable es [style-v0.json](style-v0.json). `palettes/*.gpl` se puede importar en Krita; el SVG permite ver las muestras. Los colores del mundo son una propuesta manual basada en el arte actual, no una extracción exacta ni una paleta indexada obligatoria. Permitir tonos intermedios por suavizado e iluminación. Corregir un material en el editable con máscaras; no cuantizar globalmente la imagen para «pasar» un test.

- Contorno: marrón casi negro, evitando negro puro dominante en el interior.
- Ropa oscura: carbón y sombra cálida; separar gorra, pelo y camiseta por masas y luces.
- Guitarra y zapatillas: marfil; acento burdeos del golpeador.
- Vaqueros: azul apagado con una familia coherente de sombra/luz.
- Entorno: sombras azul pizarra, madera cálida y luz ámbar; vegetación desaturada.
- UI: conservar los valores exactos ya presentes en `tools/art/build_shop_ui.py`. El JSON los documenta; no sustituye aún los tokens del runtime.

## Trazo, luz y cámara

Para un músico sobre 700×900, empezar con contorno exterior de unos 2–4 px e interior más fino al retocar; comparar con el maestro al 100 % y con el juego reducido. Si se cambia de resolución, conservar el peso aparente. No añadir detalles que solo se lean ampliando el archivo.

Usar una dirección de luz legible. La habitación actual tiene luz cálida desde la derecha; otro local puede cambiar ambiente y dirección, documentándolo en su brief. No hornear en el personaje una sombra del suelo o un decorado. Una sombra de contacto se compone por separado en el motor.

Músicos: tres cuartos, instrumento visible y manos legibles. Fijar la silueta y sus rasgos antes de animar. Para una identidad existente, editar el maestro aceptado; para otra persona, usarlo como guía de acabado, no copiar su cara o ropa.

Fondos: cámara estable, suelo transitable y escala compatible con músicos de altura similar al protagonista. Pintar el local vacío; instrumentos, ampli o decoración que se puedan comprar o mover serán objetos independientes. Si un objeto ya está pintado en un fondo legado, retirarlo una sola vez al modularizar ese fondo.

## Preparar personajes sin perseguir el prompt perfecto

Si ya existe una familia compatible, empezar desde sus piezas y editable registrados: seguir [el procedimiento de guitarra](templates/guitar-standing-v1/procedure.md) y retocar esas capas. Los pasos siguientes sirven para establecer un maestro y una familia cuando aún no existe. Reutilizar una plantilla evita volver a separar un cuerpo completo para cada músico.

La revisión v1 corrige el encaje del cuello de la camiseta. Mantener cabeza, cuello y prenda en `body_core`, y revisar la unión ampliada antes de producir otra identidad. El primer ejemplo nuevo con esa construcción es el músico del sombrero rosa.

1. Crear/seleccionar un maestro de cuerpo entero. Diseñar la pose para la animación: codos ocultos si ayuda, manos sobre el instrumento y silueta clara.
2. Abrirlo en Krita y guardarlo como editable. Recortar conservando el dibujo; rellenar solo las superficies ocultas que se revelarán durante el movimiento. Una IA puede ayudar en esa zona, pero se registra el parche sobre el mismo lienzo.
3. Separar las piezas que de verdad se muevan. Conservar zonas estáticas juntas reduce costuras. Una camiseta abierta bajo un brazo se completa a mano; una selección de píxeles no revela lo que faltaba.
4. Mantener lienzo y origen comunes. Si una herramienta generó otro tamaño, hacer **una transformación global uniforme** del maestro y registrar escala/traslación; no redimensionar cada extremidad por separado para forzar que encaje. No recortar el espacio transparente al exportar.
5. En el protagonista vigente, seguir [character-v2.json](contracts/character-v2.json). No recrear la lista antigua de seis piezas ni sustituir `body_core` por `head`/`torso` sin actualizar el rig.
6. Guardar `master.png`, el editable y exports. La herramienta de capas puede dar un punto de partida; verificar también su compuesto, porque una descomposición generativa puede redibujar detalles.

Movimiento inicial: pulso corporal discreto, rasgueo localizado, desplazamiento conjunto de brazo del mástil y dedos. Revisar intensidad mínima/máxima y tres agarres. Si una mano exige otra silueta, usar una pose dibujada y registrada en vez de estirar sus dedos con malla. No asumir que el gesto representa un acorde concreto del audio.

## Preparar fondos

Seguir [background-v1.json](contracts/background-v1.json). PNG 2400×1080, RGB/RGBA opaco, sin músicos, texto ni HUD. El recorte 16:9 usa x=240…2159 del PNG; los laterales son expansión para pantallas más anchas. No poner información imprescindible allí.

El origen del PNG es su esquina superior izquierda. En la escena vigente, imagen x=0 equivale a mundo x=-240. Los pies en mundo (760,1000) caen en imagen (1000,1000). Usar el boceto de colocación y la prueba en Godot para decidir qué suelo debe quedar libre. El HUD ocupa esquinas; el centro y las manos deben seguir leyendo con la UI visible.

## Revisión del equipo

Antes de integrar, ver al candidato junto a los dos maestros y una captura real con HUD. Revisar silueta, proporciones, color por material, contorno, escala, manos/instrumento, pies y solapes al moverse. En PNG transparentes, revisar sobre blanco, negro y color saturado para encontrar halos. Un borde suavizado correcto puede tener alfa intermedio; no exigir alfa binario a una ilustración suave.

El script verifica dimensiones, contenido, transparencia y hashes. La lectura, el estilo y el movimiento se revisan visualmente. Registrar quién hizo la revisión y los cambios concretos; no marcar automáticamente un recurso como aprobado porque se pudo abrir.

Límite propuesto del piloto: selección inicial y dos correcciones localizadas. Si persiste un defecto estructural, cambiar el boceto o retocar manualmente antes de generar otra vez todo el personaje. Ajustar ese límite con los tiempos medidos.
