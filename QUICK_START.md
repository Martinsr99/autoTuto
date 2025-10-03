# 🚀 Quick Start Guide

## Configuración inicial (10 minutos)

### 1️⃣ Requisitos previos
- Docker Desktop instalado y corriendo
- Git Bash (en Windows) o terminal (Linux/Mac)

### 2️⃣ Primera configuración

```bash
# 1. Clonar o navegar al proyecto
cd autoVideos

# 2. Configurar variables de entorno
cp .env.example .env

# 3. Editar el archivo .env con tus credenciales
# (Usa VSCode, nano, o cualquier editor de texto)
code .env  # o: nano .env

# 4. Ejecutar el script de inicio
bash start.sh
# Selecciona opción 2: "Construir imágenes y luego iniciar"
```

### 3️⃣ Obtener credenciales de API

#### YouTube:
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto nuevo
3. Habilita "YouTube Data API v3"
4. Crea credenciales OAuth 2.0
5. Usa [OAuth Playground](https://developers.google.com/oauthplayground/) para obtener el refresh token

#### TikTok:
1. Ve a [TikTok for Developers](https://developers.tiktok.com/)
2. Crea una aplicación
3. Solicita acceso a "Content Posting API"
4. Obtén Client Key y Client Secret

#### Google Drive:
1. Crea una carpeta en Drive: `NotebookLM/exports`
2. Copia el ID de la carpeta desde la URL
3. Usa las mismas credenciales OAuth de YouTube

### 4️⃣ Configurar n8n

```bash
# 1. Acceder a n8n
# Abre tu navegador en: http://localhost:5678

# 2. Crear cuenta (usa credenciales del archivo .env)
Usuario: admin (o el que configuraste)
Password: [tu password del .env]

# 3. Importar el flujo
- Workflows > Import from File
- Selecciona: n8n/video-pipeline-flow.json

# 4. Configurar credenciales
- Google Drive Trigger > Create New Credential
- Pega tus OAuth credentials
- Connect my account

# 5. Activar el workflow
- Toggle "Inactive/Active" (arriba a la derecha)
```

### 5️⃣ Crear plantillas de branding

```bash
# Crea tus vídeos de intro/outro (3-5 segundos, 1920x1080, H.264)
# Colócalos en la carpeta templates/

templates/
├── intro.mp4   # Tu vídeo de introducción
├── outro.mp4   # Tu vídeo de cierre
└── metadata.json  # Ya configurado (edítalo según necesites)
```

**Si no tienes intro/outro aún:** El sistema funcionará sin ellos, procesando solo el vídeo principal.

---

## 📝 Uso diario

### Publicar un vídeo:

1. **Genera tu vídeo en NotebookLM**
2. **Sube el .mp4 a Google Drive** → NotebookLM/exports/
3. **El sistema automáticamente:**
   - Detecta el nuevo archivo
   - Procesa con FFmpeg (intro + vídeo + outro)
   - Genera versión YouTube (16:9)
   - Genera versión TikTok (9:16)
   - Sube a ambas plataformas
   - Te notifica el resultado

### Comandos útiles:

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver solo logs de un servicio
docker-compose logs -f n8n
docker-compose logs -f ffmpeg-processor
docker-compose logs -f node-scripts

# Ver estado de servicios
docker-compose ps

# Reiniciar un servicio
docker-compose restart n8n

# Detener todo
docker-compose down

# Iniciar todo
docker-compose up -d
```

---

## 🔧 Troubleshooting rápido

### n8n no arranca
```bash
docker-compose logs n8n
# Verifica que el puerto 5678 no esté ocupado
```

### FFmpeg falla
```bash
# Verifica que intro.mp4 y outro.mp4 existan en templates/
ls -la templates/
# Si no los tienes, el script procesará sin ellos
```

### Upload falla
```bash
# Verifica tokens en .env
# YouTube Refresh Token y TikTok Access Token
# Revisa logs para error específico
docker-compose logs node-scripts
```

### En Raspberry Pi
```bash
# Cambiar platform en docker-compose.yml
platform: linux/arm64  # en lugar de linux/amd64

# Reducir calidad si necesario
# Editar .env:
VIDEO_BITRATE=3000k
```

---

## 📚 Documentación completa

Para información detallada, consulta:
- **[docs/runbook.md](docs/runbook.md)** - Guía completa
- **[templates/README.md](templates/README.md)** - Info sobre plantillas
- **[README.md](README.md)** - Visión general del proyecto

---

## ⚡ Comandos rápidos

```bash
# Inicio rápido (usa el script interactivo)
bash start.sh

# O manualmente:
docker-compose up -d                    # Iniciar
docker-compose down                     # Detener
docker-compose logs -f                  # Ver logs
docker-compose ps                       # Ver estado
docker-compose restart [servicio]       # Reiniciar servicio
docker-compose build --no-cache        # Reconstruir imágenes
```

---

## 🎯 Checklist de configuración

- [ ] Docker Desktop instalado y corriendo
- [ ] Archivo .env configurado con credenciales
- [ ] Credenciales de YouTube OAuth obtenidas
- [ ] Credenciales de TikTok obtenidas
- [ ] ID de carpeta de Google Drive configurado
- [ ] n8n iniciado y flujo importado
- [ ] Credenciales configuradas en n8n
- [ ] Workflow activado en n8n
- [ ] (Opcional) intro.mp4 y outro.mp4 creados
- [ ] (Opcional) Webhooks de Discord/Telegram configurados

---

## 🚨 Notas importantes

1. **YouTube cuota**: 10,000 unidades/día (~6 vídeos máximo)
2. **TikTok API**: Requiere aprobación. Sin ella, crea borradores
3. **Tokens expiran**: Renuévalos cuando sea necesario
4. **Raspberry Pi**: Construir imágenes tarda más la primera vez
5. **Espacio**: Limpia archivos procesados regularmente

---

## 🎉 ¡Listo!

Tu pipeline está configurado. Ahora solo:
1. Sube vídeos a Google Drive
2. Deja que el sistema haga el resto
3. Recibe notificaciones cuando termine

**¿Problemas?** Consulta [docs/runbook.md](docs/runbook.md) o revisa los logs.
