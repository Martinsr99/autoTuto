# Automated Video Publishing Pipeline

Sistema automático de procesamiento y publicación de videotutoriales desde Google Drive a YouTube y TikTok.

## 📋 Características

- ✅ Detección automática de nuevos vídeos en Google Drive
- 🎬 Procesamiento con FFmpeg (normalización, múltiples formatos)
- 📺 Publicación automática en YouTube (16:9, 1920x1080)
- 📱 Publicación automática en TikTok (9:16, 1080x1920)
- 🎨 Intro/outro personalizables
- 📝 Soporte para subtítulos SRT
- 🔔 Notificaciones de estado
- 🐳 Docker multi-arch (AMD64/ARM64)

## 🚀 Inicio rápido

Ver [docs/runbook.md](docs/runbook.md) para instrucciones detalladas.

```bash
# 1. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# 2. Levantar los servicios
docker-compose up -d

# 3. Acceder a n8n
# http://localhost:5678
```

## 📁 Estructura del proyecto

```
.
├── docker-compose.yml          # Orquestación de contenedores
├── .env.example               # Plantilla de configuración
├── templates/                 # Plantillas de branding y metadatos
│   ├── intro.mp4
│   ├── outro.mp4
│   └── metadata.json
├── scripts/                   # Scripts de upload
│   ├── uploader-youtube.ts
│   ├── uploader-tiktok.ts
│   └── package.json
├── n8n/                      # Flujos de n8n
│   └── video-pipeline-flow.json
├── ffmpeg/                   # Scripts de procesamiento
│   └── process-video.sh
└── docs/                     # Documentación
    └── runbook.md
```

## 📖 Documentación

- [Runbook completo](docs/runbook.md)
- [Configuración de APIs](docs/runbook.md#configuración-de-apis)
- [Personalización de branding](docs/runbook.md#personalización-de-branding)
- [Despliegue en Raspberry Pi](docs/runbook.md#despliegue-en-raspberry-pi)

## 🔧 Tecnologías

- n8n - Orquestación de flujos
- FFmpeg - Procesamiento de vídeo
- Docker - Contenedorización
- TypeScript - Scripts de upload
- YouTube Data API v3
- TikTok Content Posting API

## ⚠️ Importante

Este sistema NO genera vídeos automáticamente. Los vídeos deben ser generados con NotebookLM y subidos manualmente a Google Drive.
