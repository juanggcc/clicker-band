# Tienda y primera mejora de púa · v1

Diseño integrado en el juego: el HUD usa el icono de tienda y `ShopMenu` muestra
la púa, el saldo, los niveles, la ganancia base y los estados de compra reales.
Contiene 19 PNG con transparencia, un tema de Godot, maquetas y medidas. Los
recursos están en `game/assets/ui/shop/v1/`.

La economía existente se conserva: primer nivel de 10 €, coste que crece por
1,5 y un punto adicional de ganancia base por nivel, antes del bonus de intensidad.
Los importes de las maquetas originales de abajo siguen siendo ejemplos.

![Tienda integrada en el juego](../../../workspace/reviews/2026-10-21-shop/integrated-shop.png)

La compra muestra una confirmación breve y después el siguiente nivel. Comprar,
abrir y cerrar no generan toques de juego. Se puede cerrar con la X, tocando el
fondo o con Escape. El menú de pausa permanece disponible desde el HUD.

Validación de integración: `game/tests/run_ui_tests.gd`. Capturas reales:
[HUD](../../../workspace/reviews/2026-10-21-shop/integrated-hud.png), [sin saldo](../../../workspace/reviews/2026-10-21-shop/integrated-shop-empty.png),
[compra realizada](../../../workspace/reviews/2026-10-21-shop/integrated-shop-purchased.png) y [móvil](../../../workspace/reviews/2026-10-21-shop/integrated-shop-phone.png).

La documentación siguiente conserva la propuesta visual original.

## Dirección visual

La misma interfaz de amplificador del HUD: azul carbón `#202b35`, borde oscuro
`#111923`, remate gris `#52606b`, crema `#f6efdb`, menta `#8ed8b1` y ámbar
`#f4ca78`. Silkscreen es la fuente existente del proyecto.

El acceso es una silueta de tejado, toldo y puerta. La casa del lugar actual es
un contorno; la tienda tiene una silueta llena para distinguir ambas acciones.
Se propone en la esquina inferior derecha con una etiqueta «TIENDA». Un pequeño
punto menta indica que se puede comprar una mejora.

La tienda abre como un panel hacia la derecha con el juego oscurecido detrás.
Contiene una sola ficha, sin inventar categorías ni huecos para objetos futuros.
La púa ámbar es el centro visual; el menta queda para el beneficio y la compra.

## Archivos de integración

| Archivo o grupo | Uso |
| --- | --- |
| `icon_shop.png` | Icono crema de 72×72, diseñado en una cuadrícula de 24×24 |
| `icon_shop_active.png`, `icon_shop_disabled.png` | Variantes menta y gris |
| `icon_shop_24.png` | Fuente nativa de 24×24 para otros múltiplos enteros |
| `pick_upgrade.png` | Sprite ilustrado de la púa, con alfa real |
| `icon_pick_basic.png` | Púa básica como glifo monocromo de 48×48 |
| `panel_frame.png`, `item_frame.png`, `item_slot.png` | Placa exterior, ficha y alojamiento del objeto |
| `button_primary_*.png` | Normal, hover, pulsado y deshabilitado |
| `button_secondary.png` | Marco para cerrar y otras acciones secundarias |
| `icon_close.png`, `icon_arrow.png`, `icon_check.png`, `icon_lock.png`, `icon_coin.png` | Iconos auxiliares |
| `shop_theme.tres` | Tema listo para asignar al panel: fuente, placas y estados de Button |

Los PNG geométricos suman unos **3,6 KB**. El sprite ilustrado de la púa ocupa
unos **761 KiB**, con una fuente de 1254×1254. Todo el conjunto de PNG suma menos
de **0,8 MB**. No se añade ninguna dependencia externa al juego.

- Usar filtro **Nearest** en los controles de la tienda; mipmaps desactivados.
- No convertir el texto, las cifras ni los precios en imágenes: deben seguir
  siendo `Label`/`Button` con Silkscreen y actualizarse desde los datos del juego.
- Las placas son **nine-patch** de 72×72. Márgenes: 18 px a cada lado.
- Los botones usan 18 px arriba, izquierda y derecha, y **24 px abajo** para
  conservar la profundidad. No estirar el PNG completo como una imagen corriente.
- `shop_theme.tres` ya configura estos márgenes y los cinco estados, incluido foco.
  En pulsado desplaza el contenido 3 px hacia abajo. Reservar estos estilos de
  `Button` para la compra; el botón de cerrar usa `button_secondary.png` como
  `StyleBoxTexture` mediante overrides de estilo.
- Mostrar `pick_upgrade.png` con proporción conservada en una caja de unos
  **216×219 px** a la resolución lógica de 1920×1080. Su fuente ilustrada usa
  colores de la misma familia, pero no tiene la paleta exacta ni la cuadrícula
  estricta de los iconos geométricos.
- Mantener un marco táctil suficiente alrededor de la X, aunque su dibujo mida
  solo 36×36 px. La propuesta usa un control de 72×72 px lógicos.

Las medidas de la maqueta se encuentran en [shop-layout.json](shop-layout.json).
El inventario completo, las dimensiones y los checksums están en
[sprite-manifest.json](sprite-manifest.json).

## Primera mejora: púa de ensayo

La ficha muestra «PÚA DE ENSAYO», la ilustración, el nivel actual y el siguiente,
el beneficio y la ganancia base antes/después. El botón tiene un único verbo:
**MEJORAR**.

**Todos los valores de la maqueta son ejemplos de diseño**, no reglas nuevas
para la economía: nivel 0 → 1, coste de 50 €, ganancia base de 1 → 2 € y saldo de
12.450 €. Sustituirlos por los datos reales del sistema de mejoras. En particular,
si los bonus de intensidad multiplican la ganancia base, calcular el texto del
beneficio de forma coherente con esa regla.

| Estado | Presentación |
| --- | --- |
| Disponible | Precio ámbar; botón menta «MEJORAR»; compra habilitada |
| Sin saldo | Mismo objeto y beneficio; botón gris «FALTAN 38 €» en el ejemplo; compra deshabilitada |
| Pulsado | Botón más oscuro y contenido desplazado 3 px hacia abajo |
| Compra realizada | Check y «MEJORADA»; saldo y nivel actualizados; confirmación breve antes de mostrar la próxima mejora |

La confirmación es una propuesta visual. Si hay más niveles, no dejar la compra
bloqueada permanentemente después del primer éxito.

La capa de oscurecimiento y el panel abierto deben consumir los toques para que
comprar, cerrar o tocar el fondo no genere dinero del juego. El icono de tienda
también debe consumir su toque. Esto corresponde a la implementación del agente.

## Maquetas

- [Acceso dentro del HUD](../../../workspace/reviews/2026-10-21-shop/preview-shop-access.png).
- [Tienda disponible](../../../workspace/reviews/2026-10-21-shop/preview-shop-available.png).
- [Tienda sin saldo](../../../workspace/reviews/2026-10-21-shop/preview-shop-unaffordable.png).
- [Compra realizada](../../../workspace/reviews/2026-10-21-shop/preview-shop-purchased.png).
- [Sprites y estados de botón](../../../workspace/reviews/2026-10-21-shop/preview-sprites.png).

Las cinco imágenes son maquetas renderizadas con Godot a 1280×720, usando las
texturas entregadas. No son capturas de una tienda funcional.

## Fuentes y reproducción

La púa se creó con la herramienta integrada **image_gen.imagegen**, con fondo
transparente. Prompt final: [source/imagegen-pick-prompt.txt](source/imagegen-pick-prompt.txt).
No se usaron referencias visuales de los briefs ni el CLI/API de generación.

Los elementos geométricos prolongan el sistema de iconos ya existente. Se
exportan de forma determinista con el generador de PNG del proyecto:

```bash
python3 tools/art/build_shop_ui.py
```

Este generador no sustituye `pick_upgrade.png`. Si el sprite está presente, lo
incluye en el manifiesto junto con sus dimensiones y checksum actualizados.

Para volver a renderizar las maquetas desde la raíz del proyecto:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --path game --audio-driver Dummy \
  --log-file /tmp/clicker-shop-design-render.log \
  -s ../docs/art/2026-10-21-shop/source/render_shop_preview.gd
```

Validado en Godot 4.7: importación de los 19 PNG, transparencia en las esquinas,
carga del tema y de sus cinco estados de botón. Se han revisado visualmente el
acceso, la tienda, los estados de compra y la hoja de sprites.
