# Loops de guitarra integrados

Integración: 21 de octubre de 2026. Tempo confirmado por Juan: **120 BPM en los tres estados**.

| Original en `loop-exports/` | Archivo del juego en `game/audio/stems/` | Estado |
| --- | --- | --- |
| `guitar_loop_01.wav` | `slow.wav` | Reposo |
| `guitar_loop_02.wav` | `mid.wav` | Normal |
| `guitar_loop_03.wav` | `fast.wav` | Enérgico |

`guitar_loop_02.wav` se volvió a exportar corregido y sustituye a `mid.wav`.

| Original en `loop-exports/` | Archivo del juego en `game/audio/stems/` | Parte |
| --- | --- | --- |
| `bass_loop_01..03.wav` | `bandmate_slow/mid/fast.wav` | Bajo de Ren (`bass_stems`) |
| `drum_loop_01..03.wav` | `drums_slow/mid/fast.wav` | Batería de Cham (`drum_stems`) |

Bajo y batería tienen el mismo formato y duración que las guitarras. Suenan cuando su
músico se ha unido y siguen el mismo estado que la guitarra. Con las tres partes, el
pico de la suma es +5,8 dB en el loop 03; con los −6 dB del reproductor queda en
−0,2 dBFS.

Los WAV del juego son copias exactas de los originales. Los MP3 no se usan en Godot.
No se ha recortado, normalizado, convertido a mono ni modificado el audio exportado.

Los tres archivos son PCM de 16 bits, estéreo y 48.000 Hz; contienen exactamente
768.000 muestras por canal: 16 segundos, equivalentes a 8 compases de 4/4 a 120 BPM.
La inspección de energía y contenido armónico es compatible con el mismo origen
temporal; la calidad musical de las transiciones debe valorarse escuchando en juego.

En Godot, los tres `.wav.import` conservan QOA (`compress/mode=2`), Trim y Normalize
desactivados y Loop Forward desde el principio hasta el final. La escena principal
mantiene el `AudioStreamSynchronized` y el crossfade entre interpretaciones.
`MusicPlayer.BPM` permanece en 120. El nodo tiene `volume_db=-6.0` para dejar margen
de reproducción; las diferencias de intensidad entre los archivos se conservan.

Los picos de los originales son −2,61 dBFS, 0 dBFS y 0 dBFS respectivamente.
El 02 contiene 616 muestras individuales al límite de PCM16 (0,0401 %); el 03,
3.037 (0,1977 %), con tramos consecutivos de hasta 26 y 64 muestras por canal.
Esto es compatible con recorte digital en el audio exportado. El margen del
reproductor evita saturación adicional, pero no reconstruye esos picos. Si se desea
eliminarlos, hace falta corregir el nivel o procesado en Ableton antes del recorte
y volver a exportar. Puede ser parte de la saturación buscada para la guitarra.

Para sustituirlos más adelante, mantener tempo, duración exacta y cambios armónicos
alineados en las tres variantes. Conservar silencios y exportar el mismo rango.
`tools/gen_stems.py` sigue siendo el generador de placeholders de 8 segundos:
ejecutarlo sobrescribe los loops actuales y no reproduce estas guitarras.
