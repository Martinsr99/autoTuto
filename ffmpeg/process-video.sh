#!/bin/bash
set -e

# Video Processing Script
# Procesa vídeos para YouTube y TikTok con intro/outro y subtítulos

INPUT_VIDEO="$1"
OUTPUT_DIR="${2:-/output}"
VIDEO_NAME="${3:-video}"
SUBTITLES="${4:-}"
INTRO="/templates/intro.mp4"
OUTRO="/templates/outro.mp4"

# Configuración
FPS="${FPS:-30}"
AUDIO_BITRATE="${AUDIO_BITRATE:-192k}"
VIDEO_BITRATE="${VIDEO_BITRATE:-5000k}"

echo "=== Iniciando procesamiento de vídeo ==="
echo "Input: $INPUT_VIDEO"
echo "Output dir: $OUTPUT_DIR"
echo "Video name: $VIDEO_NAME"

# Verificar que el archivo de entrada existe
if [ ! -f "$INPUT_VIDEO" ]; then
    echo "ERROR: El archivo de entrada no existe: $INPUT_VIDEO"
    exit 1
fi

# Crear directorio temporal
TEMP_DIR="/temp/$VIDEO_NAME"
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

# === PASO 1: Normalizar el vídeo original ===
echo "=== Paso 1: Normalizando vídeo original ==="
NORMALIZED="$TEMP_DIR/normalized.mp4"

ffmpeg -i "$INPUT_VIDEO" \
    -c:v libx264 -preset medium -crf 23 \
    -vf "fps=$FPS,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
    -c:a aac -b:a "$AUDIO_BITRATE" -ar 48000 \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
    -movflags +faststart \
    -y "$NORMALIZED"

echo "✓ Vídeo normalizado"

# === PASO 2: Preparar intro y outro ===
INTRO_PROCESSED="$TEMP_DIR/intro.mp4"
OUTRO_PROCESSED="$TEMP_DIR/outro.mp4"

if [ -f "$INTRO" ]; then
    echo "=== Preparando intro ==="
    ffmpeg -i "$INTRO" \
        -vf "fps=$FPS,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a "$AUDIO_BITRATE" -ar 48000 \
        -y "$INTRO_PROCESSED"
else
    echo "⚠ Intro no encontrado, omitiendo..."
    INTRO_PROCESSED=""
fi

if [ -f "$OUTRO" ]; then
    echo "=== Preparando outro ==="
    ffmpeg -i "$OUTRO" \
        -vf "fps=$FPS,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a "$AUDIO_BITRATE" -ar 48000 \
        -y "$OUTRO_PROCESSED"
else
    echo "⚠ Outro no encontrado, omitiendo..."
    OUTRO_PROCESSED=""
fi

# === PASO 3: Concatenar intro + vídeo + outro ===
echo "=== Paso 3: Concatenando segmentos ==="
CONCAT_LIST="$TEMP_DIR/concat_list.txt"
> "$CONCAT_LIST"

if [ -n "$INTRO_PROCESSED" ] && [ -f "$INTRO_PROCESSED" ]; then
    echo "file '$INTRO_PROCESSED'" >> "$CONCAT_LIST"
fi

echo "file '$NORMALIZED'" >> "$CONCAT_LIST"

if [ -n "$OUTRO_PROCESSED" ] && [ -f "$OUTRO_PROCESSED" ]; then
    echo "file '$OUTRO_PROCESSED'" >> "$CONCAT_LIST"
fi

CONCATENATED="$TEMP_DIR/concatenated.mp4"
ffmpeg -f concat -safe 0 -i "$CONCAT_LIST" \
    -c copy \
    -y "$CONCATENATED"

echo "✓ Segmentos concatenados"

# === PASO 4: Versión YouTube (16:9) ===
echo "=== Paso 4: Generando versión YouTube ==="
YOUTUBE_OUTPUT="$OUTPUT_DIR/${VIDEO_NAME}_youtube.mp4"

if [ -n "$SUBTITLES" ] && [ -f "$SUBTITLES" ]; then
    echo "Añadiendo subtítulos..."
    ffmpeg -i "$CONCATENATED" -vf "subtitles=$SUBTITLES" \
        -c:v libx264 -preset medium -crf 23 -b:v "$VIDEO_BITRATE" \
        -c:a aac -b:a "$AUDIO_BITRATE" \
        -movflags +faststart \
        -y "$YOUTUBE_OUTPUT"
else
    cp "$CONCATENATED" "$YOUTUBE_OUTPUT"
fi

echo "✓ Versión YouTube lista: $YOUTUBE_OUTPUT"

# === PASO 5: Versión TikTok (9:16) ===
echo "=== Paso 5: Generando versión TikTok ==="
TIKTOK_OUTPUT="$OUTPUT_DIR/${VIDEO_NAME}_tiktok.mp4"

# Detectar si el sujeto está centrado (simplificado: usar crop centrado)
# Para detección avanzada, se podría usar análisis de cara con OpenCV

# Opción 1: Crop centrado (si contenido está en el centro)
ffmpeg -i "$CONCATENATED" \
    -vf "crop=ih*9/16:ih,scale=1080:1920,fps=$FPS" \
    -c:v libx264 -preset medium -crf 23 -b:v "$VIDEO_BITRATE" \
    -c:a aac -b:a "$AUDIO_BITRATE" \
    -movflags +faststart \
    -y "$TIKTOK_OUTPUT"

echo "✓ Versión TikTok lista (crop centrado): $TIKTOK_OUTPUT"

# Opción 2: Blur background + overlay (alternativa)
TIKTOK_BLUR_OUTPUT="$OUTPUT_DIR/${VIDEO_NAME}_tiktok_blur.mp4"

ffmpeg -i "$CONCATENATED" \
    -filter_complex "\
        [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=20:5[bg]; \
        [0:v]scale=1080:-1:force_original_aspect_ratio=decrease[fg]; \
        [bg][fg]overlay=(W-w)/2:(H-h)/2" \
    -c:v libx264 -preset medium -crf 23 -b:v "$VIDEO_BITRATE" \
    -c:a aac -b:a "$AUDIO_BITRATE" \
    -movflags +faststart \
    -y "$TIKTOK_BLUR_OUTPUT"

echo "✓ Versión TikTok alternativa lista (blur bg): $TIKTOK_BLUR_OUTPUT"

# === PASO 6: Limpieza ===
echo "=== Paso 6: Limpiando archivos temporales ==="
rm -rf "$TEMP_DIR"

echo "=== Procesamiento completado ==="
echo "Archivos generados:"
echo "  - YouTube: $YOUTUBE_OUTPUT"
echo "  - TikTok (crop): $TIKTOK_OUTPUT"
echo "  - TikTok (blur): $TIKTOK_BLUR_OUTPUT"

# Generar archivo de metadatos con información del procesamiento
cat > "$OUTPUT_DIR/${VIDEO_NAME}_metadata.json" <<EOF
{
  "input": "$INPUT_VIDEO",
  "processed_at": "$(date -Iseconds)",
  "outputs": {
    "youtube": "${VIDEO_NAME}_youtube.mp4",
    "tiktok_crop": "${VIDEO_NAME}_tiktok.mp4",
    "tiktok_blur": "${VIDEO_NAME}_tiktok_blur.mp4"
  },
  "settings": {
    "fps": $FPS,
    "audio_bitrate": "$AUDIO_BITRATE",
    "video_bitrate": "$VIDEO_BITRATE"
  }
}
EOF

exit 0
