# Clicker Band · instrucciones para agentes

Léelo antes de tocar el repo. Es un proyecto colaborativo y el **repositorio es público**.

## El juego

Clicker Band es un juego incremental para móvil en horizontal, Android primero e iOS
después, hecho en Godot 4.7 con GDScript tipado.

- **Bucle.** Tocas la pantalla y la banda toca. Cuanto más rápido tocas, más intensa es
  la pista: tres loops (lento, medio y rápido) a 120 BPM que cambian sin perder el pulso.
  Tocar a tempo, en corcheas en el loop medio y en semicorcheas en el rápido, llena una
  barra que multiplica lo ganado (x2 y x4).
- **Progreso.** Cada toque da dinero. En la tienda se compran la púa y el pedal de
  distorsión, que suben lo que vale cada toque. En el mapa se compran zonas: tu cuarto
  (inicio), el parque (8 000 €, pedal NV 5) y el garaje (30 000 €, pedal NV 8). La Sala
  El Sol y el estadio aparecen como «???» hasta que tengan arte.
- **La banda.** Tocando en el parque puede aparecer Ren, el bajista; en el garaje, Cham,
  el batería. Quien se une toca en todas las zonas, suma su pista a la música y cada
  músico multiplica el toque: x2 con uno, x3 con los dos.
- **Tono.** Humor costumbrista de banda indie española que empieza ensayando en un
  cuarto: «tu público: tu madre pidiendo que bajes eso». Los personajes se inspiran en
  músicos de la escena; no les atribuyas rasgos ni comportamientos que no te hayan dado.
- **Aspecto.** Fondos y personajes en ilustración 2D de contorno oscuro; los personajes
  son marionetas de recortes animadas por código. La interfaz es pixel art (Silkscreen,
  menta, ámbar y coral). Biblia visual: [art/bible.md](art/bible.md).
- **Estado.** Prototipo jugable. `PLAYTEST` en `game/main/main.gd` está en `true`
  mientras probamos: empieza con 1 000 000 €, los integrantes aparecen en menos de 60
  toques y no se carga ni se guarda la partida. Hay que ponerlo a `false` antes de pasar
  una build a nadie.

## Estructura

| Carpeta | Qué es | ¿En Git? |
| --- | --- | --- |
| `game/` | Proyecto Godot: código, escenas, recursos `.tres` y los sprites y loops que usa el juego, con sus `.import` | Sí, salvo `game/.godot/` |
| `art/` | Receta del arte: biblia, estilo, briefs, contratos, prompts, paletas, plantillas de rigs con su editable `.ora`, sistema de instrumentos y anclas de estilo | Sí |
| `tools/` | Código auxiliar: pipeline de arte (`tools/art/`), generadores de placeholders y scripts de desarrollo (`tools/dev/`) | Sí |
| `docs/` | Documentación en texto; `docs/art/` guarda los informes de entregas de arte con sus manifiestos | Sí |
| `.agents/skills/` | Skills de arte: fondo, personaje e instrumento | Sí |
| `workspace/` | Local: encargos de arte (`art-jobs/`), referencias y fotos (`references/`), capturas de revisión (`reviews/`), exports de Ableton (`loops/`), builds (`builds/`), `mockups/` y `output/` | **No, nunca** |

## Qué se sube y qué no

Se sube:

- Código, escenas, `.tres`, `.import`, `project.godot` y `export_presets.cfg`.
- Cada sprite y cada loop que carga el juego, dentro de `game/`.
- Lo necesario para repetir o retocar un recurso: brief, plantilla con su editable,
  anclas de estilo y su documentación.

No se sube; va a `workspace/` o se queda fuera:

- QA, capturas, previsualizaciones y fotogramas de prueba.
- Imágenes generadas intermedias, entradas copiadas a un encargo y referencias.
- **Fotos de personas reales**, que solo pueden estar en `workspace/references/`.
- Zips de entrega, builds (APK, AAB, web) y los MP3 y `.asd` que exporta Ableton.
- Secretos: keystores, claves, tokens y contraseñas. Las credenciales de exportación de
  Godot van en `game/.godot/export_credentials.cfg`, que ya se ignora.
- Copias de un archivo que ya está en `game/`.

Si dudas, o un binario pasa de unos 5 MB, pregunta antes de añadirlo.

## Flujo de trabajo actual

### Código

- Abre `game/project.godot` con Godot 4.7. Todo va tipado y con tabuladores en `.gd`.
- Los datos que se ajustan sin código son recursos: zonas en `game/world/zones/`, tienda
  en `game/shop/items/` e integrantes en `game/band/members/`.
- Escenas pequeñas que se instancian unas en otras; nunca dos personas en la misma `.tscn`.
- Pasa los tests antes de dar algo por terminado (comandos completos en el
  [README](README.md#tests)):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s res://tests/run_tests.gd
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --log-file /tmp/clicker-ui-tests.log -s res://tests/run_ui_tests.gd
```

### Arte

1. Describe el recurso en un brief de `art/briefs/` y prepara el encargo:
   `python3 tools/art/pipeline.py prepare art/briefs/<brief>.json --job <id>`. Crea
   `workspace/art-jobs/<id>/` con prompt, manifiesto y entradas; no genera nada.
2. Genera o retoca con la skill que toque (`.agents/skills/`) o a mano (Krita). El
   original, el editable, los exports y la QA se quedan en el encargo.
3. Comprueba con `tools/art/pipeline.py check` y revisa el movimiento en Godot; las
   escenas de `game/art_lab/` aíslan los rigs.
4. Copia lo aceptado a `game/assets/` con el nombre y tamaño que espera la escena. Si
   cambia un rig, actualiza también su plantilla en `art/templates/`.
5. Antes de escribir en `game/assets/`, mira si el archivo ya existe: otra sesión puede
   estar entregando arte a la vez. No sobrescribas sin confirmarlo.
6. Integrar el recurso en el juego (escena, `.tres`, código) es trabajo de código.

Detalles en [art/README.md](art/README.md).

### Audio

- En Ableton: 120 BPM, 8 compases (16,0 s), WAV estéreo de 16 bits y 48 kHz, con el
  mismo inicio en las tres variantes de cada parte. Exporta a `workspace/loops/`.
- Copia exacta del WAV a `game/audio/stems/`: guitarra `slow/mid/fast.wav`, bajo
  `bandmate_slow/mid/fast.wav` y batería `drums_slow/mid/fast.wav`. Tabla y niveles en
  [docs/audio-loops.md](docs/audio-loops.md).

### Git

- `main` siempre arranca. Reglas de equipo en el README, sección «Trabajar en equipo».
- Un agente no hace commit ni push si la persona no se lo pide en ese mensaje.
- Commits como `tipo(ámbito): resumen`, en minúsculas e imperativo: `feat(ui): …`,
  `fix(audio): …`, `chore: …`.
- Remoto por SSH: `git@github.com:juanggcc/clicker-band.git`.
