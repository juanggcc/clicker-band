# Sprites de menú, mapa y parque · v1

Nueve PNG instalados en `game/assets/`, conservando las rutas solicitadas.
El parque sigue la familia de ilustración del dormitorio; los iconos prolongan
la UI pixel de la tienda con su paleta exacta. La dirección de arte sigue siendo provisional.

![Sprites y miniaturas](../../../workspace/reviews/2026-10-21-menu-map/preview-sprites.png)

| Recurso desde `game/` | Tamaño | Formato y uso |
| --- | --- | --- |
| `assets/backgrounds/park.png` | 2400×1080 | RGB opaco, fondo vacío |
| `assets/ui/menu/v1/icon_map.png` | 72×72 | RGBA transparente, mapa plegado |
| `assets/ui/menu/v1/icon_menu.png` | 72×72 | RGBA transparente, tres barras |
| `assets/ui/menu/v1/icon_settings.png` | 72×72 | RGBA transparente, engranaje |
| `assets/ui/map/v1/icon_pin.png` | 36×36 | RGBA transparente, pin menta |
| `assets/ui/map/v1/icon_place_park.png` | 36×36 | RGBA transparente, árbol menta |
| `assets/ui/map/v1/zone_bedroom.png` | 384×216 | RGB opaco, recorte del dormitorio actual |
| `assets/ui/map/v1/zone_park.png` | 384×216 | RGB opaco, recorte del parque entregado |
| `assets/ui/map/v1/zone_locked.png` | 384×216 | RGB opaco, lugar por descubrir |

`icon_menu` e `icon_settings` se entregan como opciones para las dos decisiones
de navegación que siguen abiertas. El icono de tienda existente puede seguir
identificando TIENDA; las tres barras identifican el acceso al menú general.
El engranaje queda listo si se incorpora la pausa a AJUSTES.

Las vistas [menú](../../../workspace/reviews/2026-10-21-menu-map/preview-menu.png) y [mapa](../../../workspace/reviews/2026-10-21-menu-map/preview-map.png) son propuestas
visuales renderizadas en Godot, con textos del motor y marcos reales. No son una
implementación de navegación: esta entrega solo añade recursos, recetas de arte
y capturas, sin editar los scripts ni escenas de juego. La escena del proyecto
ya puede usar estas rutas desde su propia implementación de zonas.

## Parque y posiciones

![Parque con el personaje y HUD reales](../../../workspace/reviews/2026-10-21-menu-map/preview-park-hud.png)

El PNG se coloca igual que el dormitorio: `Sprite2D.position=(960,540)` y
textura centrada. Su origen corresponde a mundo `(-240,0)`. Por tanto:

- El recorte 16:9 del PNG es `(240,0,1920,1080)`.
- Los pies en mundo `(760,1000)` corresponden a imagen `(1000,1000)`.
- La reserva para el batería en mundo `x=1150…1500` corresponde a imagen
  `x=1390…1740`; la franja de suelo permanece libre.
- Los bancos, farolas y parterres quedan al fondo o en los extremos. No hay
  músicos, instrumentos ni equipo comprable pintados en el fondo.

Se revisó en Godot con el protagonista y HUD reales a 1280×720 y 1600×720
(vistas lógicas de 1920×1080 y 2400×1080). Las capturas de pantalla ancha y de
la reserva del batería están en `workspace/art-jobs/parque-menu-v01/qa/`.

## Integración

Los iconos usan **Nearest**, sin mipmaps. Sus fuentes son 24×24 o 12×12,
escaladas exactamente ×3, con alfa binario, margen transparente y sin halos.
El crema es `#F6EFDB`; pin y árbol usan `#8ED8B1`, igual que la casa del HUD.
Para variantes de estado, modular desde Godot con la paleta ya existente.

El parque y las tres miniaturas ilustradas usan **Linear**. Las miniaturas del
cuarto y parque salen del recorte central 16:9 completo, reducido a 384×216.
No son ilustraciones nuevas ni contienen personajes o HUD.

`zone_locked.png` es una ilustración oscura independiente. Superponer el
`icon_lock.png` existente y un `Label` con `???`; como en la tienda, los textos
siguen siendo del motor. No hay letras ni candados horneados en los PNG.
En las vistas previas se muestra esa composición para comprobar su lectura.

Reutilizar `assets/ui/shop/v1/icon_lock.png`, `icon_coin.png`, `icon_arrow.png`,
`item_frame.png`, `item_slot.png` y los botones/placas existentes. Para los
marcos, conservar los márgenes nine-patch de 18 px. En las miniaturas mantener
la proporción 16:9 y evitar estirar la imagen.

## Fuentes, prompts y reproducción

Parque y lugar desconocido generados con la herramienta integrada
**image_gen.imagegen**, un intento por recurso, con el dormitorio como
referencia visual. No se usó el CLI/API de generación. El identificador de
modelo, semilla y versión no se exponen: figuran como `null` en los manifiestos.

- [Prompt final del parque](source/imagegen-park-prompt.txt).
- [Prompt final del lugar desconocido](source/imagegen-locked-prompt.txt).
- [Manifiesto completo y checksums](sprite-manifest.json).
- [Comprobaciones técnicas](validation.json).

Los iconos geométricos se dibujan con el mismo escritor PNG y paleta del
generador de la tienda. Fuentes nativas en `source/icon_*_native.png` y receta:

```sh
python3 tools/art/build_menu_map_ui.py
```

Los originales de generación se conservan en
`workspace/art-jobs/parque-menu-v01/source/park-generated.png` y
`workspace/reviews/2026-10-21-menu-map/source/zone-locked-generated.png`.
Hay editables OpenRaster de una capa raster en las mismas carpetas; no son
descomposiciones en objetos. El parque generado mide 1870×841: se exportó con
una escala uniforme y un recorte central mínimo, sin deformar sus proporciones,
a 2400×1080. La transformación está registrada en el encargo.

Para reconstruir el export y las miniaturas con `sharp` disponible:

```sh
node tools/art/finalize_menu_map_art.cjs \
  workspace/art-jobs/parque-menu-v01/source/park-generated.png \
  workspace/reviews/2026-10-21-menu-map/source/zone-locked-generated.png
```

Para volver a renderizar las vistas previas desde la raíz:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --path game --audio-driver Dummy \
  --log-file /tmp/clicker-menu-map-preview.log \
  -s ../docs/art/2026-10-21-menu-map/source/render_preview.gd
```

El ZIP de entrega conserva `assets/` como raíz de los recursos para copiarlo
dentro de `game/`. Incluye vistas previas, manifiestos, notas y prompts bajo
`documentation/`. Los originales de alta resolución y editables permanecen
en el repositorio.
