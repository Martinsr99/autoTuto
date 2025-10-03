# 📂 Project Structure

```
autoVideos/
├── 📄 README.md                      # Visión general del proyecto
├── 📄 QUICK_START.md                 # Guía de inicio rápido
├── 📄 PROJECT_STRUCTURE.md           # Este archivo
├── 📄 docker-compose.yml             # Orquestación de servicios Docker
├── 📄 .env.example                   # Plantilla de variables de entorno
├── 📄 .gitignore                     # Archivos a ignorar en Git
├── 🔧 start.sh                       # Script interactivo de gestión
│
├── 📁 docs/                          # Documentación
│   └── 📄 runbook.md                 # Guía completa de configuración y uso
│
├── 📁 ffmpeg/                        # Procesamiento de vídeo
│   ├── 📄 Dockerfile                 # Imagen Docker de FFmpeg
│   └── 🔧 process-video.sh           # Script de procesamiento (normalización, formatos)
│
├── 📁 scripts/                       # Scripts de upload
│   ├── 📄 package.json               # Dependencias Node.js
│   ├── 📄 tsconfig.json              # Configuración TypeScript
│   ├── 📄 Dockerfile                 # Imagen Docker Node.js
│   ├── 📝 uploader-youtube.ts        # Upload a YouTube (OAuth2, API v3)
│   └── 📝 uploader-tiktok.ts         # Upload a TikTok (Content Posting API)
│
├── 📁 n8n/                           # Flujos de automatización
│   └── 📄 video-pipeline-flow.json   # Workflow completo de n8n
│
├── 📁 templates/                     # Plantillas y recursos
│   ├── 📄 README.md                  # Guía sobre plantillas
│   ├── 📄 metadata.json              # Metadatos de vídeo (título, tags, etc.)
│   ├── 🎬 intro.mp4                  # (Crear) Vídeo de introducción
│   ├── 🎬 outro.mp4                  # (Crear) Vídeo de cierre
│   └── 🖼️ thumbnail.jpg              # (Opcional) Miniatura personalizada
│
├── 📁 output/                        # Vídeos procesados (generados)
│   └── .gitkeep
│
└── 📁 temp/                          # Archivos temporales (generados)
    └── .gitkeep
```

## 🔍 Descripción de componentes

### Core del sistema

| Archivo/Carpeta | Descripción |
|-----------------|-------------|
| `docker-compose.yml` | Orquesta 3 servicios: n8n, ffmpeg-processor, node-scripts |
| `.env` | Configuración de credenciales API y parámetros |
| `start.sh` | Script interactivo para gestionar el pipeline |

### Procesamiento de vídeo (FFmpeg)

| Archivo | Función |
|---------|---------|
| `ffmpeg/process-video.sh` | • Normaliza audio/vídeo<br>• Añade intro/outro<br>• Genera versión YouTube (16:9)<br>• Genera versión TikTok (9:16 crop + blur)<br>• Inserta subtítulos SRT |
| `ffmpeg/Dockerfile` | Imagen Alpine con FFmpeg 6 |

### Scripts de upload (Node.js/TypeScript)

| Archivo | API | Funcionalidad |
|---------|-----|---------------|
| `uploader-youtube.ts` | YouTube Data API v3 | • Upload de vídeo HD<br>• Configuración de metadata<br>• Upload de miniatura<br>• Gestión OAuth2 |
| `uploader-tiktok.ts` | TikTok Content Posting API | • Upload de vídeo vertical<br>• Creación de drafts<br>• Configuración de privacidad |

### Orquestación (n8n)

| Nodo | Función |
|------|---------|
| Google Drive Trigger | Detecta nuevos .mp4 en carpeta específica |
| Download Video | Descarga archivo de Drive |
| Process Video | Ejecuta script FFmpeg |
| Upload to YouTube | Llama uploader-youtube.ts |
| Upload to TikTok | Llama uploader-tiktok.ts |
| Notifications | Envía resultado a Discord/Telegram |

### Plantillas y recursos

| Archivo | Propósito |
|---------|-----------|
| `templates/metadata.json` | Título, descripción, tags por defecto |
| `templates/intro.mp4` | Branding de apertura (crear manualmente) |
| `templates/outro.mp4` | Branding de cierre (crear manualmente) |
| `templates/thumbnail.jpg` | Miniatura YouTube (opcional) |

## 🔄 Flujo de datos

```
1. NotebookLM → Video generado
            ↓
2. Usuario → Sube .mp4 a Google Drive (NotebookLM/exports/)
            ↓
3. Google Drive → Trigger detecta nuevo archivo
            ↓
4. n8n → Descarga vídeo
            ↓
5. FFmpeg → Procesa vídeo
            ├─→ video_youtube.mp4 (16:9, 1920x1080)
            └─→ video_tiktok.mp4 (9:16, 1080x1920)
            ↓
6. Node Scripts → Upload a plataformas
            ├─→ YouTube Data API v3
            └─→ TikTok Content Posting API
            ↓
7. Notifications → Discord/Telegram
```

## 🐳 Servicios Docker

### n8n (Orquestador)
- **Puerto**: 5678
- **Función**: Coordina todo el pipeline
- **Volumen**: Persistencia de workflows y datos

### ffmpeg-processor
- **Función**: Procesa vídeos con FFmpeg
- **Volúmenes**: templates/, output/, temp/

### node-scripts
- **Función**: Ejecuta uploaders TypeScript
- **Volúmenes**: output/, templates/

## 📊 Estadísticas del proyecto

- **Servicios Docker**: 3
- **Scripts TypeScript**: 2
- **Scripts Bash**: 2
- **Workflows n8n**: 1
- **Formatos de salida**: 2 (YouTube + TikTok)
- **APIs integradas**: 3 (YouTube, TikTok, Google Drive)
- **Archivos de configuración**: 8
- **Líneas de documentación**: ~1,000+

## 🔐 Archivos sensibles (.gitignore)

- `.env` - Credenciales
- `temp/` - Archivos temporales
- `output/` - Vídeos procesados
- `node_modules/` - Dependencias
- `templates/intro.mp4` y `outro.mp4` - Personales del usuario

## 🚀 Comandos principales

```bash
# Gestión con script interactivo
bash start.sh

# O comandos directos
docker-compose up -d           # Iniciar
docker-compose down            # Detener
docker-compose logs -f         # Ver logs
docker-compose ps              # Estado
docker-compose build           # Construir imágenes
```

## 📚 Documentación

| Documento | Contenido |
|-----------|-----------|
| `README.md` | Visión general y características |
| `QUICK_START.md` | Guía rápida de 10 minutos |
| `docs/runbook.md` | Documentación completa y detallada |
| `templates/README.md` | Guía sobre plantillas de branding |
| `PROJECT_STRUCTURE.md` | Este archivo |

## ✨ Características implementadas

- ✅ Detección automática de nuevos vídeos
- ✅ Procesamiento FFmpeg con normalización
- ✅ Múltiples formatos de salida (16:9 y 9:16)
- ✅ Intro/outro personalizables
- ✅ Soporte para subtítulos SRT
- ✅ Upload automático a YouTube
- ✅ Upload automático a TikTok
- ✅ Notificaciones Discord/Telegram
- ✅ Multi-arquitectura (AMD64/ARM64)
- ✅ Listo para Raspberry Pi
- ✅ Documentación completa
- ✅ Scripts de gestión interactivos

---

**Última actualización**: 3 de enero de 2025
