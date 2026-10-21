# Clicker Band

Juego incremental para móvil horizontal: tocas, suena la música, y cuanto más rápido tocas
más intensa se vuelve la pista al mismo tempo. Godot 4.7, GDScript tipado. Android primero,
iOS después.

## Puesta en marcha

1. Instala **Godot 4.7** (misma versión para todo el equipo; el editor reescribe ficheros
   al abrir el proyecto). Mac: `brew install --cask godot` o descarga de godotengine.org.
2. Clona el repo y abre `game/project.godot` desde el gestor de proyectos de Godot.
3. Pulsa **F5** (o el botón play). Se abre una ventana 1280x720 con proporción de móvil
   horizontal; el ratón hace de dedo.
4. Opcional, para escribir código en VS Code: instala la extensión `godot-tools`
   (el repo la recomienda al abrirlo) y en Godot activa
   *Editor > Editor Settings > Text Editor > External > Use External Editor* con
   Exec Path `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`
   y Exec Flags `{project} --goto {file}:{line}:{col}`. Al hacer doble clic sobre un
   script en Godot se abre en VS Code, con autocompletado mientras el editor de Godot
   esté abierto.

## Tests

La lógica pura de `game/core/` (velocidad de toque, niveles de tempo, bonus por tocar a tempo, economía) se prueba
sin editor ni addons:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s res://tests/run_tests.gd
```

Sale con código 1 si falla alguna comprobación. Añade una función `test_*` en
`game/tests/run_tests.gd` y llámala desde `_init`.

La integración del HUD, la tienda y la economía se comprueba con eventos de ratón
y toque: compra, saldo insuficiente, confirmación, cierre, pausa y varios tamaños
de pantalla.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --log-file /tmp/clicker-ui-tests.log -s res://tests/run_ui_tests.gd
```

Para guardar capturas del juego durante esa comprobación, omite `--headless` y
añade `-- --capture` al final. Se guardan en `docs/art/2026-10-21-shop/integrated-*.png`.

## Probar en el iPhone (Safari)

Sin Xcode, el juego se prueba en iPhone como exportación web servida desde el Mac por la
red local. Godot web exige HTTPS fuera de `localhost`, así que cada Mac tiene su propia CA
de desarrollo, en la que el iPhone confía una sola vez.

1. `./scripts/dev_tls.sh`: crea la CA y el certificado del servidor en `~/.clicker-band-tls/`.
   Vuelve a ejecutarlo si cambia la IP del Mac. La CA se conserva y el iPhone no hay que
   tocarlo de nuevo. Las claves nunca entran en el repo.
2. Pasa `~/.clicker-band-tls/ca.crt` al iPhone por AirDrop. Luego, en Ajustes:
   *Perfil descargado → Instalar*, y después *General → Información → Ajustes de confianza
   de certificados*, donde activas la CA.
3. En Godot, *Editor > Editor Settings > Export > Web*: `Http Host` `0.0.0.0`,
   `Use TLS` activado, y `TLS Key` y `TLS Certificate` apuntando a `server.key` y `server.crt`.
4. Con el Mac y el iPhone en la misma Wi-Fi, pulsa el botón **Remote Deploy → Web** de Godot
   (arriba a la derecha). En Safari del iPhone abre la URL que imprime el script
   (`https://<nombre-del-mac>.local:8060/tmp_js_export.html`). Para cada cambio,
   vuelve a pulsar el botón y recarga.

La pestaña que Godot abre en el Mac da error de certificado: no importa. El interruptor de
silencio del iPhone silencia el audio web. Para ver la consola, activa *Ajustes → Safari →
Avanzado → Web Inspector*, conecta el cable y abre el menú *Desarrollo* de Safari en el Mac.
El audio web va sin hilos: un chasquido o un desfase del beat aquí no implica que pase en
la app nativa.

## Estructura

```
game/
  main/           escena raíz: cablea lógica, música, personaje y HUD
  core/           lógica pura (RefCounted, sin nodos): TapTracker, TempoTiers, Economy,
                  WorldMap (zonas compradas), BandRecruit (encuentro de cada nuevo integrante),
                  SaveGame (partida en user://save.cfg)
  world/          zonas: zone.gd y un .tres por zona en zones/ (orden del mapa en Main)
  band/           integrantes que se pueden unir: bandmate.gd y un .tres por músico en members/
  shop/           objetos de la tienda: shop_item.gd y un .tres por objeto en items/
  props/          objetos de escenario (el pedal comprado aparece junto al protagonista)
  audio/          MusicPlayer (stems de guitarra y del integrante en sincronía), stems/ y
                  sfx/ (buy.wav suena al comprar, más agudo si compras seguido)
  characters/     personajes como marionetas de recortes (una escena por personaje)
  ui/             HUD, menú general, tienda, mapa, diálogo de integrante y pausa
  assets/         PNG de arte (protagonista, cuarto e icono del 2026-10-21)
  tests/          runner de tests sin dependencias
tools/            generadores de placeholders (audio y sprites), Python sin dependencias
docs/             brief de sprites, pipeline de animación y exploración previa a v1
```

Conceptos de Godot que aparecen en el proyecto: **escenas** (`.tscn`, árboles de nodos
reutilizables), **nodos** (`Sprite2D`, `Label`, `AudioStreamPlayer`...), **señales**
(el HUD emite `tapped`, `main.gd` se suscribe), **@onready** (referencias a nodos hijos
resueltas al entrar en escena), **tweens** (animar una propiedad en el tiempo),
**Camera2D** (centra la vista para que los móviles anchos vean más escena) y
**anchors** (los controles del HUD se pegan a las esquinas).

El diseño pixel del HUD, su fuente y los puntos para ajustarlo están documentados
en [docs/hud-pixel.md](docs/hud-pixel.md).

La tienda usa los sprites de `game/assets/ui/shop/v1/`, con la púa, los marcos y
los estados de botón del [diseño de tienda](docs/art/2026-10-21-shop/README.md).
El precio inicial real es 10 €; cada nivel añade 1 a la ganancia base y el bonus
de intensidad se aplica después.

## Sustituir arte

El [sistema compartido de arte](art/README.md) reúne la investigación de herramientas,
la dirección visual provisional, las paletas, los contratos y las skills de personaje
y fondo. Para nuevas entregas, usar esos contratos y el montaje vigente; el brief v1
se conserva como documento histórico.

- **Sprites.** Cada PNG de `game/assets/` tiene el tamaño definitivo; sustituye el fichero
  manteniendo nombre y tamaño y la escena no cambia. Especificación en
  `docs/sprites-brief-v1.md`. Si una articulación cambia de sitio, ajusta la posición del
  nodo pivote en `characters/protagonist/protagonist.tscn` y la de su `Sprite` hijo
  (siempre el mismo vector en negativo).
- **Música.** Los tres loops de guitarra actuales comparten 120 BPM y duran 8 compases
  (16,0 s), en WAV estéreo de 16 bits/48 kHz. Los originales `guitar_loop_01/02/03.wav`
  de `loop-exports/` corresponden a `slow/mid/fast.wav` de `game/audio/stems/`.
  Se importan con Loop Forward, sin recortar ni normalizar, y compresión QOA.
  El reproductor tiene un margen de 6 dB. Detalles en [docs/audio-loops.md](docs/audio-loops.md).
  Cambia `BPM` en `game/audio/music_player.gd` si cambia el tempo. El generador
  `tools/gen_stems.py` es solo para placeholders: ejecutarlo sobrescribe estos loops.

## Trabajar en equipo

- `main` siempre arranca. Rama corta por cambio, pull request, y se borra la rama.
- Nunca dos personas editando la misma escena (`.tscn`) a la vez: las escenas son texto
  pero los conflictos se resuelven mal. Escenas pequeñas que se instancian unas en otras.
- Todo tipado en GDScript (`var x: int`, `-> void`); el proyecto marca como error las
  declaraciones sin tipo.
- Indentación con tabulador en `.gd` (es lo que inserta el editor de Godot).
- Los `.import` que aparecen junto a cada asset se commitean; `game/.godot/` no.
- `mockups/`, `references/` y `output/` son material de exploración anterior a v1 y no
  entran en el repo.
