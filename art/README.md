# Arte compartido de Clicker Band

Sistema inicial para tres personas. Presupuesto inicial: sin nuevas suscripciones. La [investigación y comparación de herramientas](../docs/art/2026-10-21-investigacion-pipeline.md) explica la recomendación.

La **dirección v0 es provisional** y deriva de los recursos que ya se ven en el juego. Congelar esta referencia permite comparar; no convierte automáticamente sus detalles en decisiones artísticas definitivas.

## Empezar

1. Usad Krita para los maestros de ilustración y Godot para comprobar el movimiento. Pixelorama es opcional para los recursos pixel de UI. Compartid la versión concreta del editor que uséis para el piloto; el motor del proyecto es Godot 4.7.
2. Leed [la biblia visual](bible.md). [style-v0.json](style-v0.json) contiene las paletas, reglas y referencias que consumen las recetas.
3. Copiad uno de los [briefs](briefs/) con otro nombre y describid el recurso. Preparad el encargo con Python 3.10 o posterior:

```bash
python3 tools/art/pipeline.py prepare art/briefs/protagonist-pilot.json --job mi-guitarrista-v01
python3 tools/art/pipeline.py prepare art/briefs/garage-pilot.json --job mi-garaje-v01
```

Cada comando crea `workspace/art-jobs/<job>/prompt.txt`, `manifest.json` y copias de sus entradas. **No llama a ninguna IA ni modifica el juego.** El prompt y las referencias se pueden usar manualmente en la herramienta disponible o mediante las skills. No sobrescribe un encargo existente: cambiad el identificador de versión.

Los documentos dentro de `inputs/` conservan exactamente su contenido de origen como evidencia. Sus enlaces relativos corresponden a la ruta `source` anotada en el manifiesto; para navegar el manual vigente, usad los documentos de `art/`.

Para guitarristas compatibles, `prepare` añade las siete piezas registradas, un editable `source.ora` y la guía de la [familia de construcción](templates/guitar-standing-v1/procedure.md). Así se cambia la apariencia sobre una estructura concreta. Las copias iniciales todavía son el protagonista; producir otro músico exige editarlas y revisar el resultado. Estilo, identidad y construcción evolucionan por separado.

Los paquetes iniciales están en `../workspace/art-jobs/protagonista-piloto-v01/` y `../workspace/art-jobs/garaje-piloto-v01/`. La primera variante real es [el músico del sombrero rosa](../workspace/art-jobs/cowboy-piloto-v01/README.md), con sprites, editable y una escena de comparación. Usa la revisión v1, que corrige la unión cabeza/camiseta sin cambiar los puntos del rig. La [corrección posterior del protagonista](../workspace/art-jobs/protagonist-arm-width-v01/README.md) mejora el solape de camiseta y brazo, tomando al músico del sombrero rosa como referencia y conservándolo intacto. El estilo permanece provisional; v0 se conserva como historial.

El [bajo SG burdeos corregido](../workspace/art-jobs/bajo-sg-v03/README.md) es un instrumento separado para integrar. Su posición se ha subido 12 px para dejar visible la base de la mano. El [sistema compartido de instrumentos](instruments/standing-v1/README.md) fija tamaño, puente, cejuela, agarres y zonas de muñeca para guitarras y bajos, con guías, registro uniforme y comprobaciones. Usa 900×900 ampliando solo a la derecha; las piezas del músico siguen en 700×900.

La referencia de guitarra es la [Jaguar custom marfil/burdeos corregida](../workspace/art-jobs/jaguar-custom-v01/README.md). Puente y diapasón siguen ahora el mismo eje; el sistema comprueba también esa alineación. Hay un encargo preparado con las referencias nuevas en `../workspace/art-jobs/instrument-guitar-starter-v02/`.

4. Conservad en esa carpeta el original generado, el archivo editable `.kra`/`.ora`/`.psd`, los exports PNG y la revisión. Rellenad en el manifiesto proveedor/modelo real, ajustes disponibles, intentos, retoques, tiempos y archivos entregados. Si el proveedor no revela un dato, dejadlo en `null`; no adivinarlo.
5. Preparad las piezas siguiendo el contrato correspondiente. Comprobad PNG finales:

```bash
python3 -m venv .venv-art
.venv-art/bin/python -m pip install -r tools/art/requirements.txt
.venv-art/bin/python tools/art/pipeline.py check character game/assets/characters/protagonist
.venv-art/bin/python tools/art/pipeline.py check background game/assets/backgrounds/bedroom.png
.venv-art/bin/python tools/art/pipeline.py audit
.venv-art/bin/python tools/art/test_pipeline.py
```

En Windows, el Python del entorno está en `.venv-art\Scripts\python.exe`. Preparar prompts y verificar hashes no requiere Pillow; comprobar píxeles sí. El entorno no entra en Git.

6. Revisad el dibujo a tamaño de juego, los extremos de la animación y la convivencia con el HUD. Solo entonces integrad los exports necesarios en `game/assets/`. Una validación técnica correcta no aprueba el estilo ni la animación.

## Skills del equipo

Las skills se guardan en `.agents/skills/` en este repo. Tras compartir los archivos por Git, abrid el repo en un chat nuevo si no aparecen en el selector. No se instala una copia distinta en la carpeta personal de cada amigo. Es el mecanismo de descubrimiento de [skills de repositorio de Codex](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills).

Ejemplos:

```text
Usa $clicker-character para preparar un bajista alto con jersey verde y burdeos,
en la misma dirección visual. Primero crea el brief y el maestro; después prepara
las piezas que necesite su movimiento. Guarda todo en workspace/art-jobs/bajista-v01.

Usa $clicker-background para crear un garaje vacío, con suelo libre para tres músicos,
usando art/briefs/garage-pilot.json. Conserva el espacio de UI y la cámara del juego.

Usa $clicker-instrument para crear un bajo a partir de esta foto, con el perfil bass.
Conserva su escala, registra puente y cejuela y revisa la base de la mano antes de entregar.
```

Las skills pueden guiar la generación si existe una herramienta de imagen en esa sesión. Sin ella, dejan un paquete de prompt y referencias listo para usar manualmente. No dependen de una cuenta compartida, de una suscripción nueva ni de un modelo de imagen cuyo nombre no se conozca.

## Qué se comparte y cómo se cambia

| Ruta | Propósito |
| --- | --- |
| `art/style-v0.json` y `art/bible.md` | Fuente común de estilo y reglas de producción |
| `art/palettes/` | Paletas importables y muestras visuales derivadas del JSON |
| `art/anchors/v0/` | Copias congeladas de las referencias actuales, con hashes; no fuentes de capas |
| `art/contracts/` | Tamaños, capas y coordenadas de integración |
| `art/instruments/standing-v1/` | Perfiles, fuentes, guías de guitarra/bajo y puntos de contacto comunes |
| `art/prompts/` y `art/briefs/` | Receta fija y contenido variable del encargo |
| `art/backend-lock.json` | Perfil de ejecución conocido; inicialmente manual y sin modelo fijado |
| `workspace/art-jobs/<id>/` | Entradas exactas, procedencia, editable, exports y revisión de cada encargo (local, fuera de Git) |

Todo `workspace/` es local y no entra en Git: encargos, referencias, fotos, capturas de revisión, zips y builds. Lo que el juego usa se copia a `game/assets/`; lo que hace falta para repetir o retocar un recurso (brief, plantilla con su editable, anclas de estilo) vive en `art/`. Las fotos de personas reales van siempre en `workspace/references/`, nunca en `art/`. Qué entra en el repo y qué no está en [AGENTS.md](../AGENTS.md).

Cada recurso tiene una persona responsable. Otra revisa estilo y una tercera integración; rotad por encargo. No editar simultáneamente el mismo `.kra` o `.tscn`. Si cambian estilo, paleta o referencias, crear `v1` y actualizar las recetas en un mismo cambio; conservar v0 para interpretar encargos anteriores. `palette` regenera únicamente los archivos derivados de la versión activa:

```bash
python3 tools/art/pipeline.py palette
```

Los archivos finales se comparten iguales. Las generaciones nuevas son variables incluso usando el mismo prompt. Si adoptáis un backend local, guardad además sus versiones, hashes de pesos, nodos, LoRAs y workflow; `backend-lock.json` tiene espacio para ello. No incluye claves ni pesos del modelo.

## Primer piloto

El brief de protagonista sirve para comparar preparación de capas sobre una identidad ya conocida; no sustituye el arte actual. El garaje comprueba consistencia en una composición nueva. Registrar minutos y correcciones antes de producir todo el reparto. Probar la separación automática sobre una copia del maestro puede hacerse como alternativa; no es un paso obligatorio.

El contrato de personaje documenta **el protagonista vigente**, no un esqueleto universal. Un bajista más alto o un batería pueden necesitar otro contrato. El contrato del fondo distingue píxeles del PNG y coordenadas de mundo; mantened esa distinción al ubicar músicos y objetos.

La [propuesta de batería sentada compacta](templates/drummer-seated-v0/procedure.md) tiene lienzo propio de 800×1000, dos outfits cartoon, batería separada, guía de articulaciones y una prueba de espacio móvil para cinco integrantes. Es un borrador de construcción y maestros para revisar; aún no incorpora piezas articuladas finales al preparador genérico ni al runtime.

La [prueba articulada v1](templates/drummer-seated-v1/procedure.md) añade dieciséis capas, editable y una escena aislada en Godot para el gesto de hi-hat/caja con camiseta roja. Incluye animación, articulaciones visibles y render móvil real con HUD y cinco plazas. La revisión del brazo izquierdo recoge el codo y lo sitúa detrás del hi-hat. Toms/crash, camisa y geometría de pedales siguen pendientes; la escena principal permanece sin cambios.
