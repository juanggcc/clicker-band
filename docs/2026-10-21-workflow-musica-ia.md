# Música adaptable: IA → Ableton → Godot

Investigación: 21 de octubre de 2026. Propuesta de producción, pendiente de una prueba de escucha con las herramientas. No se han generado audios ni modificado el motor del juego.

**Recomendación.** Para controlar acordes, tempo y futuros instrumentos, usar Staccato como asistente de composición MIDI, un instrumento virtual de guitarra con strummer y Ableton para producir los loops definitivos. Para explorar rápidamente un sonido generado en audio, probar Stable Audio con una referencia propia y terminar igualmente en Ableton. La fiabilidad del resultado la da la sesión maestra: los prompts de audio no sustituyen la comprobación musical.

**Qué encaja con el prototipo actual.** `game/audio/music_player.gd` reproduce tres archivos dentro de un `AudioStreamSynchronized` y hace un crossfade inmediato de 0,25 s. Su BPM es 120; no cambia la velocidad de reproducción. `tools/gen_stems.py` genera cuatro compases de 8 s con intensidad creciente. Los nombres slow/mid/fast representan estados, no tres BPM diferentes. La escena referencia `slow.wav`, `mid.wav` y `fast.wav`.

La primera entrega compatible sería tres interpretaciones de guitarra con idénticos acordes, BPM, duración e inicio musical. No hace falta incluir aún bajo ni batería: cada músico futuro debe tener su propia capa.

**Herramientas que he contrastado.**

| Herramienta | Papel en este flujo | Límite práctico |
| --- | --- | --- |
| Staccato | Generar, reescribir y acompañar MIDI; importar una progresión propia y sacar partes editables hacia Ableton. | Produce MIDI: el realismo de guitarra lo aporta el instrumento y su programación. Hay que revisar las notas. |
| Ample Guitar con Strummer | Reproducir acordes y patrones con ataques arriba/abajo, apagados y variaciones de velocidad. | Es un instrumento virtual, no una IA de audio. Requiere configurar las teclas que disparan articulaciones. |
| Stable Audio 3 | Generar instrumentos aislados y transformar audio existente para buscar interpretaciones y timbres. | La duración solicitada no garantiza que acordes y ataques respeten la rejilla. Su flujo multitrack se anuncia como experimental. |
| Suno Studio | Bocetar una estética de banda y exportar WAV, pistas separadas o MIDI extraído. | Mi elección para una referencia sonora, antes que para fijar tres interpretaciones intercambiables con armonía exacta. |

Staccato documenta [reescritura de MIDI propio](https://staccato.ai/features/rewrite) y [acompañamientos a partir de una progresión](https://staccato.ai/features/accompany). Ample documenta [Strummer, detección de acordes, humanización y exportación MIDI](https://www.amplesound.net/en/tutorial.asp). La elección de esta combinación es una recomendación de producción, no una comparativa de escucha realizada aquí.

**Flujo principal: composición controlada con MIDI.**

1. Crear una sesión maestra de Ableton a 120 BPM y 4/4. Para la prueba, cuatro compases, un acorde por compás. Ejemplo nuevo: Am–F–C–G; no es una progresión aprobada para el juego. Guardar un clip de acordes como referencia de todas las partes.
2. Importar ese MIDI en Staccato. Generar o reescribir una parte de guitarra media y derivar las otras dos de la misma referencia. El idle también se puede preparar directamente con cuatro rasgueos: no necesita generación si ya están elegidos los acordes.
3. Comprobar en Ableton que las tres partes cambian de acorde exactamente en los mismos puntos. Corregir cualquier nota ajena a la progresión y recortar los clips al mismo rango. Mantener las mismas posiciones e inversiones de guitarra cuando sea posible para conservar la identidad.
4. Asignar el mismo instrumento y cadena de ampli a las tres variantes. En un strummer hay que introducir los acordes en su zona/modo de reconocimiento y convertir los ataques del patrón a sus teclas de rasgueo y articulación. El MIDI genérico de la IA no se convierte automáticamente en esas órdenes. Se pueden usar patrones del propio instrumento y la IA solo para proponer el ritmo.
5. Comparar en tres escenas de Session View: idle, normal y enérgica. Mantener la intención de volumen entre estados, sin que un gran salto de ganancia sea el único cambio perceptible.
6. Renderizar audio. Guardar el MIDI, presets y sesión de Ableton para poder rehacer la canción a otro tempo o añadir músicos sin reconstruirla de oído.

| Estado | Interpretación propuesta | Identidad compartida |
| --- | --- | --- |
| Idle | Un rasgueo descendente al inicio de cada compás, dejando sonar el acorde. | Misma guitarra, ampli, acordes e inversiones. |
| Normal | Patrón regular de corcheas, arriba/abajo y algunos silencios. | Misma vuelta armónica y posiciones de los cambios. |
| Enérgico | Corcheas más acentuadas, apagados y algún ataque de semicorchea. | Mismo BPM si se usa el sistema actual. |

Prompts de partida para MIDI, aportando siempre el clip maestro:

```text
Rewrite this MIDI as a rhythm-guitar part. 4 bars, 4/4, 120 BPM.
Keep the supplied chord progression and chord-change positions exactly:
bar 1 Am, bar 2 F, bar 3 C, bar 4 G.
One sustained chord attack on beat 1 of each bar. No extra harmony.
No pickup, intro, ending or additional instruments. Return editable MIDI.
```

```text
Create a medium-energy variation of the supplied rhythm-guitar MIDI.
Keep the exact chords, chord-change positions, 4-bar length and 120 BPM.
Use an eighth-note strumming rhythm with a few rests and natural accents.
Do not add melody, bass or drums. Return editable MIDI.
```

```text
Create a high-energy variation of the supplied rhythm-guitar MIDI.
Keep the exact chords, chord-change positions, 4-bar length and 120 BPM.
Use stronger rhythmic accents, short muted attacks and occasional
sixteenth-note pickups within each bar. No new chords or instruments.
Return editable MIDI.
```

Estos prompts expresan restricciones; no garantizan que la IA las cumpla. En esta ruta se pueden inspeccionar y corregir antes de generar el audio.

Staccato anuncia Pro a 14,99 USD/mes, con una promoción inicial de 4,99 USD, subida de material y uso comercial. Basic aparece sin subida ni uso comercial: para este flujo interesa Pro. Precio consultado en la [página oficial](https://staccato.ai/pricing); comprobar el importe del checkout. No es necesario comprar una guitarra virtual antes de probar con los instrumentos disponibles.

**Alternativa: audio generado con Stable Audio.**

La [guía oficial](https://stability.ai/guides/stable-audio-3-prompt-guide) documenta instrumentos aislados con `TrackType: Instrument` y audio-to-audio. Una intensidad de modificación menor conserva más del ritmo y melodía de la referencia, sin prometer identidad exacta de acordes.

Preparar tres guías propias de cuatro compases en Ableton, con los acordes y patrones de la tabla. Pueden sonar sencillas. Usarlas como referencia para buscar un timbre de guitarra más convincente; partir de una referencia común ayuda a comparar. Si el control de modificación está disponible, comenzar con un cambio conservador y aumentar solo lo necesario.

Prompt de ejemplo para la guía normal:

```text
TrackType: Instrument. Isolated clean electric rhythm guitar through
a small combo amp, dry close recording, indie/post-punk character.
120 BPM, 4/4, four-bar repeating phrase, 8 seconds.
Am | F | C | G, one chord per bar. Follow the supplied reference harmony
and timing. Medium-energy eighth-note down/up strumming.
No vocals, drums, bass, melody, intro, ending, fade or long reverb.
```

Para idle y enérgico cambiar la referencia y la frase del patrón, manteniendo el resto. Si la interfaz no permite pedir 8 s, generar más y seleccionar una vuelta completa en Ableton. Verificar armonía por oído y tempo contra metrónomo; corregir desviaciones con Warp o edición. Warp no arregla un acorde equivocado ni hace que dos timbres distintos se conviertan en el mismo instrumento.

La [web multitrack](https://stability.ai/guides/make-your-first-mix-with-stable-audio) permite añadir partes escuchando las existentes y exportarlas por separado. Puede servir para explorar bajo y batería; no lo tomaría como garantía de sincronía para entregar al juego.

Suno Studio también [exporta pistas, rangos y MIDI extraído](https://help.suno.com/en/articles/8128193). Ese MIDI procede del análisis del audio: revisarlo antes de usarlo como fuente de acordes o articulaciones.

**Si debe subir el BPM de verdad.**

El mismo proyecto MIDI permite renderizar, por ejemplo, idle a 90 BPM, normal a 120 y enérgico a 150. Cuatro compases de 4/4 durarían 10,6667 s, 8 s y 6,4 s respectivamente. Los instrumentos de cada estado deben compartir su BPM y duración.

Estas tres versiones no pueden reproducirse continuamente juntas y conservar el mismo acorde por posición temporal como hace el prototipo. Habría que cambiar de conjunto en un límite musical. Para la primera prueba usaría el final de la vuelta y el inicio de la siguiente. Si cuatro compases de espera se sienten lentos, exportar un compás por acorde y estado permite cambiar en el siguiente compás conservando el índice armónico. El feedback visual del clic puede seguir siendo inmediato.

`AudioStreamInteractive` ofrece [reglas de transición por pulso, compás o final](https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html). Es un candidato para esa ampliación; hay que validar metadatos y combinación con las capas de instrumentos. No basta con activar una casilla en el reproductor actual. `pitch_scale` modifica [tono y tempo conjuntamente](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html#class-audiostreamplayer-property-pitch-scale), por lo que no sirve por sí solo para acelerar conservando afinación.

**Preparación de los archivos en Ableton.**

Seleccionar exactamente los mismos cuatro compases en todas las pistas. Exportar cada interpretación/instrumento por separado y conservar silencios intencionados. Usar WAV a 48 kHz/24 bits como máster de producción; preparar una copia a 16 bits para el juego. Desactivar Normalize y MP3. Exportar con Render as Loop y escuchar la unión: Ableton [envuelve las colas de efectos sin alargar el archivo](https://www.ableton.com/en/manual/managing-files-and-sets/#rendering-options).

Para esta prueba, 120 BPM y cuatro compases a 48 kHz son exactamente 384.000 muestras por archivo. Evitar reverb larga y procesado no lineal común al conjunto: las capas deben sumar de forma predecible. Dejar margen de mezcla para los músicos que se añadan después.

**Entrega y reproducción en Godot.**

Para loops cortos y varias capas, empezaría con WAV de 16 bits/48 kHz, mono donde la toma lo permita. Comparar PCM con QOA en móvil. Para un repertorio grande, probar Ogg Vorbis por tamaño. Godot documenta el [intercambio entre compresión y coste de reproducción](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html). Es una elección inicial que hay que medir en el Android objetivo.

En la importación WAV: Trim y Normalize desactivados; Loop Forward sobre el rango completo. El silencio forma parte de la sincronización. Los tres WAV actuales ya tienen desactivados Trim y Normalize y usan compresión QOA (`compress/mode=2`).

Para BPM fijo, mantener `AudioStreamSynchronized`, que [inicia conjuntamente sus subpistas](https://docs.godotengine.org/en/stable/classes/class_audiostreamsynchronized.html). Los loops compatibles deben seguir el mismo mapa armónico. Cambiar intensidad por volumen; al entrar un músico, abrir su capa en la posición correspondiente de la vuelta. No arrancar su archivo desde cero a mitad de canción. Las variantes de un mismo instrumento se sustituyen mediante crossfade; los instrumentos diferentes se suman.

Propuesta de nombres para el catálogo futuro:

```text
song_01/guitar_idle_120.wav
song_01/guitar_normal_120.wav
song_01/guitar_hype_120.wav
song_01/bass_normal_120.wav
song_01/drums_normal_120.wav
```

No hacen falta tres variantes de cada instrumento desde el principio. Un bajo y una batería compartidos entre estados reducen trabajo; crear nuevas variantes cuando aporten una diferencia audible. Evitar mantener un repertorio entero reproduciéndose silenciado: cargar la canción activa y medir el coste de sus capas.

Guardar junto a los assets un manifiesto con ID de canción, BPM, compás, tonalidad, acordes y duración en pulsos, número de compases, frecuencia de muestreo, número de muestras y asignación de archivos a instrumento/estado. La duración y afinación comunes deben comprobarse al incorporar cada parte.

El reloj visual actual acumula `delta`; antes de cuantizar cambios con él conviene pasarlo a un reloj basado en audio, gestionando las vueltas y la latencia. Godot explica cómo [usar posición de reproducción y compensación del mezclador](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html).

**Primera prueba de aceptación.** Producir solo las tres guitarras y un bajo opcional. Escuchar cada loop durante diez vueltas, cambiar de estado en cada acorde, comprobar las transiciones con auriculares y altavoz del móvil y comparar PCM/QOA. La prueba decide si la ruta MIDI tiene suficiente realismo o si compensa trabajar más con audio generado. La siguiente ampliación sería una batería alineada con la misma sesión maestra.
