# HUD pixel · Clicker Band

Implementado directamente en `game/ui/hud.tscn`. Dirección propia, sin tomar las
referencias visuales de los briefs: una pequeña interfaz de equipo de ensayo,
con placas oscuras, esquinas escalonadas y medidor de amplificador.

![HUD en el juego](art/2026-10-21-hud/preview-mid.png)

## Diseño

- **Letras:** Silkscreen Regular, una fuente pixel de Jason Kottke. Una sola familia
  para títulos, información y feedback, con distintos tamaños y contraste.
- **Números:** grandes y en ámbar para el dinero, separador de miles y coma decimal.
  A partir de un millón se abrevia para mantener el contador en su esquina.
- **Barra:** velocímetro de 24 celdas hasta 10 toques por segundo, un tercio por loop:
  8 celdas menta de 0 a 2,75 toques/s, 8 ámbar hasta 5 y 8 coral hasta 10, lineal
  dentro de cada tercio. Las semicorcheas (nivel 3, 8 toques/s) quedan al 83 %. Los
  umbrales caen siempre en un cambio de celda, y las celdas apagadas se ven en tono
  oscuro, así que se ve dónde empieza cada loop. Sube a ritmo constante (la barra
  entera en 1 s, `RISE_PER_SEC` en `tempo_meter.gd`) y baja rápido.
- **Metrónomo:** LED rojo junto a VELOCIDAD (`ui/metronome_led.gd`), solo encendido o
  apagado. Se enciende 75 ms en cada corchea (`METRONOME_PER_BEAT` y `METRONOME_ON` en
  `hud.gd`; con 1 marca solo los pulsos).
- **Barra de tempo:** fina, bajo el velocímetro. Se carga tocando a tempo (corcheas en
  el loop 2, semicorcheas en el loop 3) y se vacía al fallar o saltarse una nota. Blanca
  mientras carga; llena se vuelve dorada y muestra el multiplicador (x2 o x4) hasta que
  se vacía del todo. Lógica en `game/core/tempo_bonus.gd`.
- **Niveles:** INDIE (LVL 1) en menta, ROCK (LVL 2) en ámbar y PUNK (LVL 3) en coral.
  Sin textos de ayuda: solo hay que tocar.
- **Feedback:** nota y cifra pixel que ascienden al tocar, con el color del nivel.
- **Legibilidad:** placas opacas para que las letras no dependan del fondo, sombra
  corta y filtros nearest para conservar los bordes del píxel.

## Coste y mantenimiento

La única descarga añadida al juego es la fuente de 32.220 bytes. Silkscreen se
distribuye bajo SIL Open Font License 1.1; el archivo original y su licencia están
incluidos en `game/assets/fonts/silkscreen/`. No requiere servicios ni assets de pago.

Fuente oficial: <https://github.com/googlefonts/silkscreen>.

Los paneles, iconos y segmentos son geometría 2D dibujada por Godot. No hacen falta
sprites de cada letra, imágenes grandes, shaders ni animaciones exportadas.
El texto se actualiza cuando cambia; el medidor se redibuja cuando cambia su valor
o tamaño. Los elementos decorativos dejan pasar los toques.

Para ajustar el diseño:

| Archivo | Controla |
| --- | --- |
| `game/ui/pixel_theme.tres` | Fuente, colores base, sombra y márgenes interiores |
| `game/ui/hud.tscn` | Distribución, tamaños y textos fijos |
| `game/ui/hud.gd` | Estados, formato de cifras y feedback al tocar |
| `game/ui/pixel_panel.gd` | Placa, borde, esquinas y pequeños remaches |
| `game/ui/pixel_icon.gd` | Iconos de casa, moneda, nota, menú, flecha y púa |
| `game/ui/tempo_meter.gd` | Segmentos y colores de la barra |
| `game/ui/metronome_led.gd` | LED del metrónomo |
| `game/ui/bonus_meter.gd` | Barra de tempo: blanca cargando, dorada con multiplicador |
| `game/ui/shop_menu.tscn`, `shop_row.tscn` | Tienda: una fila por objeto con nivel, ganancia y precio |
| `game/ui/options_menu.tscn` | Menú de pausa: continuar, sonido, ajustar ritmo y salir |
| `game/ui/main_menu.tscn` | Menú general (botón de la casa): casillas TIENDA y MAPA |
| `game/ui/map_menu.tscn`, `zone_card.tscn` | Mapa: una ficha por zona |
| `game/ui/join_dialog.tscn` | Diálogo del integrante que pide unirse |
| `game/ui/travel_fade.tscn` | Fundido a negro al cambiar de zona |
| `game/ui/calibration_menu.tscn` | Ajustar ritmo: cuenta atrás, resultado y botones |
| `game/core/tap_calibration.gd` | Toques de calentamiento, muestras y mediana del desfase |

Los umbrales de cada loop viven en `TempoTiers` (`mid_rate`, `fast_rate`) y el HUD
se los pasa al medidor al arrancar. El fondo de escala es `max_value` del nodo
`Progress` en `hud.tscn`.

## Menús

- **Esquina inferior derecha:** botón de pausa (tres rayas) y botón de casa (MENÚ), que
  abre una cuadrícula con TIENDA y MAPA. Un punto verde marca dónde se puede comprar.
- **Mapa:** una ficha por zona con miniatura (el fondo, si la zona no trae la suya),
  nombre, frase y estado: ESTÁS AQUÍ, IR, COMPRAR o FALTAN X €. Las zonas sin fondo
  salen como "???" con su frase de adelanto. Comprar lleva a la zona con un fundido;
  la música no se corta. Cada zona es un `.tres` en `game/world/zones/` (nombre, frase,
  precio, fondo, miniatura, icono y posiciones de los músicos); el orden del mapa es
  la lista `zones` del nodo Main.
- **Nuevos integrantes:** cada zona puede tener un `recruit` (un `.tres` de
  `game/band/members/`): Ren, el bajista, en el parque y Cham, el batería, en el garaje.
  Mientras se toca allí, cada toque tiene 1/700 de que aparezca, seguro a los 1500
  (`BandRecruit`). Quien se une toca en todas las zonas y cada músico en escena
  multiplica el toque: x2 con uno y x3 con los dos. Cada uno suma su pista
  (`bass_stems` y `drum_stems` del MusicPlayer). Cham se sienta detrás de los dos
  guitarristas.
- **Tienda:** ventana sobre el juego con el fondo oscurecido; se cierra con la X o
  tocando fuera. La música sigue, pero los toques no cuentan mientras está abierta.
  Cada objeto es un `.tres` en `game/shop/items/` (precio, crecimiento por nivel,
  ganancia por toque, requisito y dibujo); el orden es la lista `shop_items` de Main.
  Ahora: púa 25 € ×1,5 (+1 €/toque) y pedal 1 200 € ×1,35 (+5 €/toque, pide púa
  NV 10). El parque pide pedal NV 5 y cuesta 8 000 €; el garaje, pedal NV 8 y 30 000 €.
- **Pausa:** pausa todo el juego, música incluida. Sonido silencia el bus Master.
- **Partida guardada:** `user://save.cfg` (dinero, niveles, zonas, zona actual e
  integrantes). Se guarda al comprar, al cambiar de zona, al unirse alguien, cada 10 s y
  al pasar la app a segundo plano o salir. Borrar partida, en la pausa, pide un
  segundo toque y no toca la calibración (`settings.cfg`).
- **Atrás (Android):** cierra el menú abierto o abre la pausa; ya no cierra el juego.
- **Ajustar ritmo:** desde la pausa. El juego sigue parado y solo suena la música,
  siempre en el loop 1. Se toca en cada pulso (negras) en cualquier punto de la
  pantalla; la cifra grande cuenta los 24 toques que faltan. Los 4 primeros no se miden
  y la mediana de los 20 siguientes es el desfase: negativo si se toca antes del pulso.
  Guardar lo aplica a la barra de tempo y lo escribe en `user://settings.cfg`
  (`[rhythm] tap_offset_sec`, en segundos); sin calibrar vale 0. Repetir empieza de
  nuevo y Cancelar vuelve a la pausa sin cambiar nada.
- Los botones usan los estilos `Button` de `pixel_theme.tres`.

## Sustituir iconos por sprites

Cada icono es un nodo con `pixel_icon.gd`. Al arrastrar un PNG a su propiedad
`texture` en el inspector, se dibuja ese PNG estirado al tamaño del nodo en lugar
del patrón. PNG cuadrado con fondo transparente; si es pixel art, mejor a un
múltiplo exacto del tamaño del nodo.

| Sprite | Nodo | Tamaño del nodo |
| --- | --- | --- |
| Casa (tienda) | `hud.tscn` → `Margin/Corner/ShopButton/Icon` | 72x72 |
| Menú | `hud.tscn` → `Margin/Corner/OptionsButton/Icon` | 72x72 |
| Dibujo de cada objeto | campo `art` de su `.tres` (`pick_upgrade.png`, `pedal_upgrade.png`) | 1254x1254 |
