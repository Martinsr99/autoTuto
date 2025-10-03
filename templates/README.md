# Templates Directory

Esta carpeta contiene las plantillas y recursos necesarios para el pipeline de vídeos.

## 📁 Archivos requeridos

### 1. Vídeos de branding (intro/outro)

Debes crear y colocar aquí tus propios vídeos de intro y outro:

- **`intro.mp4`** - Vídeo de introducción (recomendado 3-5 segundos)
  - Formato: MP4
  - Resolución recomendada: 1920x1080
  - Debe incluir tu logo/branding

- **`outro.mp4`** - Vídeo de cierre (recomendado 3-5 segundos)
  - Formato: MP4
  - Resolución recomendada: 1920x1080
  - Puede incluir llamadas a la acción, enlaces, etc.

### 2. Miniatura (opcional)

- **`thumbnail.jpg`** - Miniatura personalizada para YouTube
  - Formato: JPG o PNG
  - Resolución recomendada: 1280x720
  - Tamaño máximo: 2MB

### 3. Metadatos

- **`metadata.json`** - Configuración de título, descripción y tags
  - Ya incluido como ejemplo
  - Personaliza según tus necesidades

## 🎨 Creando tus propios intro/outro

Puedes crear estos vídeos con:
- Adobe Premiere Pro / After Effects
- DaVinci Resolve
- Canva (plantillas de vídeo)
- CapCut
- Cualquier editor de vídeo

### Consejos:
- Mantén los vídeos cortos (3-5 segundos máximo)
- Usa resolución 1920x1080 para mejor compatibilidad
- Incluye tu marca/logo de forma clara
- Asegúrate de que el audio esté normalizado
- Exporta en formato MP4 con H.264

## 📝 Si no tienes intro/outro

Si no colocas estos archivos, el script de FFmpeg simplemente omitirá esa parte y procesará solo el vídeo principal.

## 🔄 Actualizar plantillas

Para cambiar las plantillas:

1. Reemplaza los archivos en esta carpeta
2. No es necesario reiniciar los contenedores
3. Los cambios se aplicarán en el siguiente procesamiento

## Ejemplo de estructura:

```
templates/
├── README.md           (este archivo)
├── metadata.json      (configuración de metadatos)
├── intro.mp4          (TU VÍDEO - debes crearlo)
├── outro.mp4          (TU VÍDEO - debes crearlo)
└── thumbnail.jpg      (TU IMAGEN - opcional)
